// roundedcorners.glsl  --  shared include for the liquid_glass shaders.
// Declares the geometry/opacity uniforms the fragment shader needs and provides
// an antialiased squircle-ish corner mask. Adapted from Better Blur's
// roundedcorners.glsl (GPL-2.0-or-later). #include'd by BOTH the 1.10 (.frag)
// and 1.40 (_core.frag) variants. In the core variant KWin's #include machinery
// pulls this in after the #version line, so we must not restate #version here
// and we must emit the `out vec4 fragColor` only for the core profile. KWin's
// shader preprocessor defines the same symbols in both profiles, so we keep this
// file dialect-neutral: `texture`/`gl_FragColor` are only used in the .frag/core
// files themselves, never here.

uniform float topCornerRadius;    // px; top-left/right corner radius
uniform float bottomCornerRadius; // px; bottom-left/right corner radius
uniform float antialiasing;       // px; edge softness of the silhouette
uniform vec2  blurSize;           // px size of the surface quad
uniform float opacity;            // overall surface opacity (held ~constant; see brief)

// Returns rgba: the given rgb, with alpha = coverage*opacity, where coverage is
// an antialiased inside-test of the rounded rectangle. fragCoord is in px within
// the quad (0..blurSize).
vec4 roundedRectangle(vec2 fragCoord, vec3 texture)
{
    if (topCornerRadius == 0.0 && bottomCornerRadius == 0.0) {
        return vec4(texture, opacity);
    }

    vec2  halfSize = blurSize * 0.5;
    vec2  p        = fragCoord - halfSize;
    float radius   = 0.0;

    if ((fragCoord.y <= bottomCornerRadius)
        && (fragCoord.x <= bottomCornerRadius || fragCoord.x >= blurSize.x - bottomCornerRadius)) {
        radius = bottomCornerRadius;
        p.y   -= radius;
    } else if ((fragCoord.y >= blurSize.y - topCornerRadius)
        && (fragCoord.x <= topCornerRadius || fragCoord.x >= blurSize.x - topCornerRadius)) {
        radius = topCornerRadius;
        p.y   += radius;
    }

    float d = length(max(abs(p) - (halfSize + vec2(0.0, radius)) + radius, 0.0)) - radius;
    float s = smoothstep(0.0, antialiasing, d);
    return vec4(texture, mix(1.0, 0.0, s) * opacity);
}
