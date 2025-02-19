#version 330 core

layout (location = 0) in vec4 vertex;
uniform mat4 projection;

out vec2 out_uv;

void main()
{
    gl_Position = projection * vec4(vertex.xy, 0.0, 1.0);
    out_uv = vertex.zw;
}
