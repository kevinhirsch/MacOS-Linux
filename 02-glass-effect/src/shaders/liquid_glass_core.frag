#version 140
// liquid_glass_core.frag  --  GLSL 1.40 (desktop core) variant.
// LOGIC-IDENTICAL to liquid_glass.frag; only the GLSL dialect differs
// (in/out instead of varying, texture() instead of texture2D(), explicit
// out fragColor instead of gl_FragColor). Keep the two files in sync.
// See liquid_glass.frag for the full, heavily-commented explanation of the
// optics; comments here are trimmed to the deltas.

#include "roundedcorners.glsl"   // core version defines out vec4 fragColor + blurSize etc.

uniform sampler2D texUnit;
uniform float     offset;
uniform vec2      halfpixel;

uniform bool      noise;
uniform sampler2D noiseTexture;
uniform vec2      noiseTextureSize;

uniform float edgeSizePixels;
uniform float ior;
uniform float superellipseN;
uniform float refractionStrength;
uniform float rgbFringing;

uniform vec2  lightDir;
uniform float specStrength;
uniform float specShininess;
uniform float fresnelStrength;

uniform vec4  tintColor;
uniform int   variant;
uniform float clearDim;
uniform float inkThreshold;

uniform float materialize;

in vec2 uv;

float sdRoundRect(vec2 p, vec2 b, float r)
{
    vec2 q = abs(p) - b + r;
    return min(max(q.x, q.y), 0.0) + length(max(q, 0.0)) - r;
}

float luma(vec3 c) { return dot(c, vec3(0.2126, 0.7152, 0.0722)); }

float superellipseHeight(float t)
{
    float x = clamp(t, 0.0, 1.0);
    float inner = 1.0 - pow(1.0 - x, superellipseN);
    return pow(max(inner, 0.0), 1.0 / superellipseN);
}

void main(void)
{
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

    vec2  halfSize = 0.5 * blurSize;
    vec2  posPx    = uv * blurSize - halfSize;
    float cornerR  = max(topCornerRadius, edgeSizePixels);
    float dist     = sdRoundRect(posPx, halfSize, cornerR);

    float band   = clamp(1.0 + dist / edgeSizePixels, 0.0, 1.0);
    float height = superellipseHeight(band);

    const float h = 1.0;
    vec2 grad = vec2(
        sdRoundRect(posPx + vec2(h, 0.0), halfSize, cornerR) - sdRoundRect(posPx - vec2(h, 0.0), halfSize, cornerR),
        sdRoundRect(posPx + vec2(0.0, h), halfSize, cornerR) - sdRoundRect(posPx - vec2(0.0, h), halfSize, cornerR)
    );
    vec2  n2d = length(grad) > 1e-6 ? normalize(grad) : vec2(0.0, 0.0);
    vec3  N   = normalize(vec3(n2d * (1.0 - height), max(height, 0.05)));

    vec3  V    = vec3(0.0, 0.0, 1.0);
    float eta  = 1.0 / max(ior, 1.0001);
    vec3  R    = refract(-V, N, eta);
    float bend = refractionStrength * (1.0 - height) * materialize;
    vec2  dispG = R.xy * bend;

    float fringe = rgbFringing * 0.25;
    vec2  dispR  = dispG * (1.0 + fringe);
    vec2  dispB  = dispG * (1.0 - fringe);

    vec3 sum = vec3(0.0);
    for (int i = 0; i < 8; ++i) {
        vec2 off = offsets[i] * offset;
        sum.r += texture(texUnit, clamp(uv - dispR, 0.0, 1.0) + off).r * weights[i];
        sum.g += texture(texUnit, clamp(uv - dispG, 0.0, 1.0) + off).g * weights[i];
        sum.b += texture(texUnit, clamp(uv - dispB, 0.0, 1.0) + off).b * weights[i];
    }
    sum /= weightSum;

    float bgLuma = luma(sum);

    float cosTheta = clamp(dot(N, V), 0.0, 1.0);
    float f0       = pow((1.0 - ior) / (1.0 + ior), 2.0);
    float fresnel  = (f0 + (1.0 - f0) * pow(1.0 - cosTheta, 5.0)) * fresnelStrength * materialize;

    vec3  L    = normalize(vec3(lightDir, 0.6));
    vec3  Hv   = normalize(L + V);
    float spec = pow(max(dot(N, Hv), 0.0), specShininess) * specStrength * (1.0 - height) * materialize;

    vec3 color = sum;

    float inkMix  = smoothstep(inkThreshold - 0.08, inkThreshold + 0.08, bgLuma);
    vec3  tintRGB = mix(tintColor.rgb, tintColor.rgb * 0.65, inkMix);
    float tintAmt = tintColor.a;

    if (variant == 1) {
        tintAmt = tintColor.a * 0.35;
        color   = mix(color, color * (1.0 - clearDim), inkMix);
    }

    color = mix(color, tintRGB, tintAmt);

    if (variant == 0) {
        color *= mix(0.94, 1.0, height);
    }

    color += vec3(fresnel);
    color += vec3(spec);

    if (noise) {
        color += texture(noiseTexture, gl_FragCoord.xy / noiseTextureSize).rrr - 0.5 / 255.0;
    }

    fragColor = roundedRectangle(uv * blurSize, color);
}
