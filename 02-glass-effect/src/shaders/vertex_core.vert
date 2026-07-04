#version 140
// vertex_core.vert  --  GLSL 1.40 (desktop core) vertex shader.
// Logic-identical to vertex.vert; uses in/out instead of attribute/varying.

uniform mat4 modelViewProjectionMatrix;

in vec4 vertex;
in vec4 texcoord;

out vec2 uv;

void main()
{
    uv          = texcoord.st;
    gl_Position = modelViewProjectionMatrix * vertex;
}
