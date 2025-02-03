#version 330 core

uniform sampler2D image;
uniform vec3 out_color;

in vec2 out_uv;
out vec4 color;

float cubicPulse( float c, float w, float x )
{
    x = abs(x - c);
    if( x>w ) return 0.0;
    x /= w;
    return 1.0 - x*x*(3.0-2.0*x);
}

void main()
{
    float d = texture(image, out_uv).r;
    float aaf = fwidth(d);
    float alpha = smoothstep(0.5 - aaf, 0.5 + aaf, d);
//    float alpha = cubicPulse(0.5, aaf, d);
    color = vec4(out_color, alpha);
}
