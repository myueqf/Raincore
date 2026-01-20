#version 330 compatibility

uniform sampler2D lightmap;
uniform sampler2D gtexture;
uniform float alphaTestRef = 0.1;

in vec2 lmcoord;
in vec2 texcoord;
in vec4 glcolor;

layout(location = 0) out vec4 color;

void main() {
    vec4 texColor = texture(gtexture, texcoord) * glcolor;
    vec3 light = texture(lightmap, lmcoord).rgb;
    color.rgb = texColor.rgb * light;
    color.a = 1.0;
}
