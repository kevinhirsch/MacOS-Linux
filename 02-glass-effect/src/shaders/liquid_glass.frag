// liquid_glass.frag  --  GLSL 1.10 variant (legacy / GLES2 profile)
// ---------------------------------------------------------------------------
// Tahoe "Liquid Glass" upsample+lens fragment shader for KWin 6 (Plasma 6).
//
// This shader is the FINAL upsample pass of a Kawase dual-filter blur, exactly
// like Better Blur's upsample.glsl. The dual-Kawase blur has already produced a
// half/quarter-res blurred copy of the region BEHIND the surface; here we do the
// last upsample tap AND bend the sample coordinates through a glass "lens" so the
// blurred backdrop refracts, picks up Fresnel edge brightening, a specular streak,
// restrained chromatic aberration, a material tint, and an adaptive dim for the
// Clear variant. The order that matters for Tahoe is: BLUR FIRST, THEN LENS.
//
// Design tokens this shader is tuned to (from tokens/ + the brief):
//   - RESTRAINED refraction: displacement is small and only near the edge band.
//   - Squircle / superellipse exponent n ~= 4 for the height/thickness profile.
//   - TINT the surface, not the text: tint is a translucent wash over the
//     refracted backdrop; foreground content is drawn by KWin on top later.
//   - Regular vs Clear variants: Regular carries more tint + a subtle inner
//     shade; Clear is nearly tint-free BUT must apply a ~35% dim over bright
//     content so white UI text stays legible on a busy/bright backdrop.
//   - "Materialize by modulating lensing, not opacity": the show/hide animation
//     should drive u_materialize (0..1) which scales refraction + specular +
//     Fresnel, so the panel appears to *form* out of glass rather than fade in.
//   - Adaptive ink: sample backdrop luminance; if relative luminance crosses the
//     ~0.36 threshold, signal (via the alpha we hand back is not enough) — we
//     expose u_inkFlip as an OUT-of-band value baked into a corner pixel is not
//     possible here, so instead we bias the tint light/dark. The actual text
//     recolor happens in the Plasma theme (03-theme) reading the same threshold.
//
// IMPORTANT KWin integration notes:
//   * KWin's ShaderManager binds the sampler for ShaderTrait::MapTexture as the
//     uniform named "sampler" bound to texture unit 0 in modern KWin, but this
//     blur lineage binds its own "texUnit" at unit 0 and manages MVP itself.
//     We keep Better Blur's convention (texUnit @ unit0) so we stay drop-in with
//     its C++ upsample dispatch.
//   * This is the .frag (GLSL 1.10) file. There is a byte-identical-logic
//     liquid_glass_core.frag for GLSL 1.40 (desktop core). KWin picks the right
//     one based on the GL context. Keep the two in sync.
//   * Everything here runs per-fragment over the SURFACE's bounding quad, in the
//     quad's normalized uv (0..1). blurSize is that quad's pixel size.
// ---------------------------------------------------------------------------

#include "roundedcorners.glsl"   // provides: uniform vec2 blurSize; uniform float opacity;
                                 // uniform float topCornerRadius/bottomCornerRadius/antialiasing;
                                 // and vec4 roundedRectangle(vec2 fragCoord, vec3 texture)

// ---- Inherited-from-blur uniforms (kept name-compatible with upsample.glsl) --
uniform sampler2D texUnit;       // the blurred backdrop, unit 0
uniform float     offset;        // Kawase upsample offset (in texels)
uniform vec2      halfpixel;     // 0.5 / textureSize, for the 8-tap kernel

uniform bool      noise;         // optional dither to kill banding on gradients
uniform sampler2D noiseTexture;  // unit 1
uniform vec2      noiseTextureSize;

// ---- Glass geometry uniforms -------------------------------------------------
uniform float edgeSizePixels;    // width (px) of the refracting edge band = "bezel"
uniform float ior;               // index of refraction (Tahoe ~2.4 gives firm bend)
uniform float superellipseN;     // squircle exponent for height profile (~4.0)
uniform float refractionStrength;// master gain on displacement (restrained: ~0.4)
uniform float rgbFringing;       // chromatic aberration amount (0..1, keep <=0.25)

// ---- Lighting uniforms -------------------------------------------------------
uniform vec2  lightDir;          // 2D direction of the key light in uv space
uniform float specStrength;      // Blinn specular gain (0..1)
uniform float specShininess;     // Blinn exponent (higher = tighter streak)
uniform float fresnelStrength;   // edge-brightening gain (0..1)

// ---- Material / variant uniforms --------------------------------------------
uniform vec4  tintColor;         // rgb tint + a = tint amount (premultiplied use below)
uniform int   variant;           // 0 = Regular, 1 = Clear
uniform float clearDim;          // Clear dim over bright content (~0.35)
uniform float inkThreshold;      // relative-luminance flip point (~0.36)

// ---- Animation uniform -------------------------------------------------------
uniform float materialize;       // 0..1 show/hide; scales lensing, NOT opacity

varying vec2 uv;                 // 0..1 across the surface quad (from vertex.vert)

// ===========================================================================
//  Signed distance to a rounded rectangle (Inigo Quilez). Negative = inside.
//  We reuse this both for the corner mask and to build the glass surface normal.
//  b = half-size, r = corner radius, p = point relative to center.
// ===========================================================================
float sdRoundRect(vec2 p, vec2 b, float r)
{
    vec2 q = abs(p) - b + r;
    return min(max(q.x, q.y), 0.0) + length(max(q, 0.0)) - r;
}

// ITU-R BT.709 relative luminance. Used for the adaptive-ink decision and for
// the Clear-variant "how bright is what's behind me" test.
float luma(vec3 c)
{
    return dot(c, vec3(0.2126, 0.7152, 0.0722));
}

// ===========================================================================
//  Build the glass height/thickness at this fragment from a SUPERELLIPSE
//  profile. `t` is 0 at the outer edge of the bezel band and 1 at the inner
//  flat. The brief's profile is y = (1 - (1 - x)^4)^(1/4): a squircle shoulder
//  that rises fast off the rim then flattens. n is generalized (superellipseN).
//  Returns height in 0..1 (1 = full thickness / flat interior).
// ===========================================================================
float superellipseHeight(float t)
{
    float x = clamp(t, 0.0, 1.0);
    float inner = 1.0 - pow(1.0 - x, superellipseN);   // (1 - (1-x)^n)
    return pow(max(inner, 0.0), 1.0 / superellipseN);  // ^(1/n)
}

void main(void)
{
    // ------------------------------------------------------------------
    // 0. Kawase upsample kernel (unchanged from Better Blur). This is the
    //    "blur" half of blur-then-lens. We keep the taps so the final image
    //    is a proper dual-Kawase upsample, not a raw texture read.
    // ------------------------------------------------------------------
    // NB: the vec2[](...) array-constructor syntax is not strictly GLSL 1.10, but
    // KWin's own stock blur upsample.glsl uses it in its non-core .frag and it
    // compiles on every backend KWin supports (desktop GL exposes the ARB array
    // behaviour; KWin's GLES path is 3.x). We deliberately mirror that convention
    // so this file stays drop-in with the Better Blur upsample dispatch.
    vec2 offsets[8] = vec2[](
        vec2(-halfpixel.x * 2.0, 0.0),
        vec2(-halfpixel.x,  halfpixel.y),
        vec2( 0.0,          halfpixel.y * 2.0),
        vec2( halfpixel.x,  halfpixel.y),
        vec2( halfpixel.x * 2.0, 0.0),
        vec2( halfpixel.x, -halfpixel.y),
        vec2( 0.0,         -halfpixel.y * 2.0),
        vec2(-halfpixel.x, -halfpixel.y)
    );
    float weights[8] = float[](1.0, 2.0, 1.0, 2.0, 1.0, 2.0, 1.0, 2.0);
    float weightSum  = 12.0;

    // ------------------------------------------------------------------
    // 1. GLASS GEOMETRY. Work in pixel space centered on the surface so the
    //    edge band width (edgeSizePixels) is honest regardless of aspect.
    // ------------------------------------------------------------------
    vec2  halfSize = 0.5 * blurSize;
    vec2  posPx    = uv * blurSize - halfSize;     // pixel position, centered
    float cornerR  = max(topCornerRadius, edgeSizePixels); // superellipse corner
    float dist     = sdRoundRect(posPx, halfSize, cornerR); // <0 inside

    // Normalized penetration into the bezel: 0 at the rim, 1 once we are
    // edgeSizePixels deep (i.e. on the flat interior). This is our profile param.
    float band = clamp(1.0 + dist / edgeSizePixels, 0.0, 1.0);

    // Superellipse thickness at this fragment (squircle shoulder).
    float height = superellipseHeight(band);

    // ------------------------------------------------------------------
    // 2. SURFACE NORMAL from the SDF gradient. The 2D gradient of the distance
    //    field points OUT of the shape; -grad points inward along the surface.
    //    We lift it into 3D using the superellipse height as the z component so
    //    the rim (low height) has a strongly tilted normal (big bend) and the
    //    interior (height->1) is flat (no bend). This is what makes refraction
    //    "restrained" and edge-localized instead of a global fisheye.
    // ------------------------------------------------------------------
    const float h = 1.0; // 1px finite-difference step
    vec2 grad = vec2(
        sdRoundRect(posPx + vec2(h, 0.0), halfSize, cornerR) - sdRoundRect(posPx - vec2(h, 0.0), halfSize, cornerR),
        sdRoundRect(posPx + vec2(0.0, h), halfSize, cornerR) - sdRoundRect(posPx - vec2(0.0, h), halfSize, cornerR)
    );
    vec2  n2d    = length(grad) > 1e-6 ? normalize(grad) : vec2(0.0, 0.0);
    // z grows with thickness: flat interior => normal ~ (0,0,1); rim => tilted.
    vec3  N      = normalize(vec3(n2d * (1.0 - height), max(height, 0.05)));

    // ------------------------------------------------------------------
    // 3. SNELL REFRACTION. View vector is straight-on (screen-space glass), so
    //    V = (0,0,1). refract() with eta = 1/ior bends V through the surface.
    //    We only use the XY of the refracted ray as a backdrop displacement,
    //    scaled by thickness so the flat interior contributes ~0 displacement.
    //    materialize scales the whole thing so the panel "lenses into being".
    // ------------------------------------------------------------------
    vec3  V         = vec3(0.0, 0.0, 1.0);
    float eta       = 1.0 / max(ior, 1.0001);
    vec3  R         = refract(-V, N, eta);          // refracted ray
    // Displacement in uv: convert the ray's XY back to texel-normalized space.
    // (1.0 - height) again biases displacement to the rim; refractionStrength is
    // the restrained master gain; materialize animates it.
    float bend      = refractionStrength * (1.0 - height) * materialize;
    vec2  dispG     = R.xy * bend;                  // green (reference) channel

    // ------------------------------------------------------------------
    // 4. CHROMATIC ABERRATION. Split the displacement per channel by a small
    //    fraction. Red bends most, blue least (matches real dispersion + the
    //    Better Blur convention). Keep it restrained per the tokens.
    // ------------------------------------------------------------------
    float fringe    = rgbFringing * 0.25;
    vec2  dispR     = dispG * (1.0 + fringe);
    vec2  dispB     = dispG * (1.0 - fringe);

    // Sample the blurred backdrop through the lens, running the full 8-tap
    // Kawase upsample at each channel's displaced coordinate. Clamp to keep the
    // lens from sampling outside the captured backdrop region.
    vec3 sum = vec3(0.0);
    for (int i = 0; i < 8; ++i) {
        vec2 off = offsets[i] * offset;
        sum.r += texture2D(texUnit, clamp(uv - dispR, 0.0, 1.0) + off).r * weights[i];
        sum.g += texture2D(texUnit, clamp(uv - dispG, 0.0, 1.0) + off).g * weights[i];
        sum.b += texture2D(texUnit, clamp(uv - dispB, 0.0, 1.0) + off).b * weights[i];
    }
    sum /= weightSum;

    // Backdrop luminance AFTER blur+refraction: this is what the user will read
    // text against, so it's the correct input for both Clear-dim and ink-flip.
    float bgLuma = luma(sum);

    // ------------------------------------------------------------------
    // 5. FRESNEL (Schlick). Grazing angles at the rim brighten. cosTheta is the
    //    view/normal alignment; interior (N~z) => high cos => low Fresnel; rim
    //    (tilted N) => low cos => high Fresnel. F0 ~ ((1-ior)/(1+ior))^2.
    // ------------------------------------------------------------------
    float cosTheta = clamp(dot(N, V), 0.0, 1.0);
    float f0       = pow((1.0 - ior) / (1.0 + ior), 2.0);
    float fresnel  = f0 + (1.0 - f0) * pow(1.0 - cosTheta, 5.0);
    fresnel       *= fresnelStrength * materialize;

    // ------------------------------------------------------------------
    // 6. BLINN specular streak. Half-vector between (3D) light and view; the
    //    rim catches a bright highlight along lightDir. Kept as an ADD so it
    //    reads as a glossy sheen on the glass, not a recolor of content.
    // ------------------------------------------------------------------
    vec3  L    = normalize(vec3(lightDir, 0.6));
    vec3  Hv   = normalize(L + V);
    float spec = pow(max(dot(N, Hv), 0.0), specShininess) * specStrength;
    // Concentrate specular in the bezel (where height<1) so the interior stays clean.
    spec      *= (1.0 - height) * materialize;

    // ------------------------------------------------------------------
    // 7. TINT THE SURFACE, NOT THE TEXT. tintColor.a is the wash amount. For
    //    Regular we lay a translucent tint over the refracted backdrop; for
    //    Clear we use almost none. This colors the *glass*; the app/text that
    //    KWin paints on top is untouched.
    // ------------------------------------------------------------------
    vec3 color = sum;

    // Adaptive tint bias: nudge the tint toward light over dark backdrops and
    // toward dark over light backdrops so the material keeps contrast with what
    // is behind it. The hard text ink-flip lives in the Plasma theme, but this
    // keeps the glass itself from disappearing. Cross-fade around inkThreshold.
    float inkMix   = smoothstep(inkThreshold - 0.08, inkThreshold + 0.08, bgLuma);
    // Over bright backdrop (inkMix->1): tint slightly darker. Over dark: lighter.
    vec3  tintRGB  = mix(tintColor.rgb, tintColor.rgb * 0.65, inkMix);
    float tintAmt  = tintColor.a;

    if (variant == 1) {
        // CLEAR: minimal tint, but enforce the ~35% dim once the backdrop is
        // bright enough that white foreground text would wash out. The dim is
        // gated by inkMix so dark backdrops keep Clear fully transparent.
        tintAmt = tintColor.a * 0.35;
        color   = mix(color, color * (1.0 - clearDim), inkMix);
    }

    // Apply the tint wash.
    color = mix(color, tintRGB, tintAmt);

    // Regular gets a faint inner shade toward the interior for depth; Clear does not.
    if (variant == 0) {
        color *= mix(0.94, 1.0, height); // subtle interior deepening
    }

    // ------------------------------------------------------------------
    // 8. Add the optical highlights on TOP of the tinted glass.
    //    Fresnel and specular are additive white light on the rim.
    // ------------------------------------------------------------------
    color += vec3(fresnel);
    color += vec3(spec);

    // ------------------------------------------------------------------
    // 9. Optional dither to break up banding on smooth gradients (common on
    //    heavily blurred backdrops at 8-bit). Same convention as Better Blur.
    // ------------------------------------------------------------------
    if (noise) {
        color += texture2D(noiseTexture, gl_FragCoord.xy / noiseTextureSize).rrr - 0.5 / 255.0;
    }

    // ------------------------------------------------------------------
    // 10. Corner mask + opacity. roundedRectangle() antialiases the squircle
    //     silhouette and multiplies in `opacity`. NOTE: per "materialize by
    //     modulating lensing not opacity", we deliberately do NOT fold
    //     materialize into alpha here -- the C++ side holds opacity ~constant
    //     during show/hide and animates `materialize` instead.
    // ------------------------------------------------------------------
    gl_FragColor = roundedRectangle(uv * blurSize, color);
}
