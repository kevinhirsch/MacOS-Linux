#version 140
// downsample_core.frag  --  GLSL 1.40 twin of downsample.frag.

uniform sampler2D texUnit;
uniform float     offset;
uniform vec2      halfpixel;

in vec2 uv;
out vec4 fragColor;

void main(void)
{
    vec4 sum = texture(texUnit, uv) * 4.0;
    sum += texture(texUnit, uv - halfpixel.xy * offset);
    sum += texture(texUnit, uv + halfpixel.xy * offset);
    sum += texture(texUnit, uv + vec2(halfpixel.x, -halfpixel.y) * offset);
    sum += texture(texUnit, uv - vec2(halfpixel.x, -halfpixel.y) * offset);
    fragColor = sum / 8.0;
}
