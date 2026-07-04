// vertex.vert  --  GLSL 1.10 vertex shader for the liquid_glass upsample pass.
// KWin's ShaderTrait::MapTexture generates a compatible attribute layout; we
// forward the texture coords as `uv` (0..1 across the surface quad) and apply
// the model-view-projection matrix KWin hands us. Matches Better Blur's
// vertex.vert so the C++ dispatch is drop-in.

uniform mat4 modelViewProjectionMatrix;

attribute vec4 vertex;    // position, provided by KWin
attribute vec4 texcoord;  // texture coords, provided by KWin

varying vec2 uv;

void main()
{
    uv          = texcoord.st;
    gl_Position = modelViewProjectionMatrix * vertex;
}
