// downsample.frag  --  GLSL 1.10. Plain dual-Kawase DOWNsample tap.
// No lensing here: downsampling must stay a clean blur so the lens (in the final
// upsample) has an artifact-free backdrop to bend. Verbatim-equivalent to Better
// Blur's downsample.frag. Pair with vertex.vert. A _core (1.40) twin exists.

uniform sampler2D texUnit;
uniform float     offset;
uniform vec2      halfpixel;

varying vec2 uv;

void main(void)
{
    vec4 sum = texture2D(texUnit, uv) * 4.0;
    sum += texture2D(texUnit, uv - halfpixel.xy * offset);
    sum += texture2D(texUnit, uv + halfpixel.xy * offset);
    sum += texture2D(texUnit, uv + vec2(halfpixel.x, -halfpixel.y) * offset);
    sum += texture2D(texUnit, uv - vec2(halfpixel.x, -halfpixel.y) * offset);
    gl_FragColor = sum / 8.0;
}
