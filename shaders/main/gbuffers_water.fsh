#version 330 compatibility

uniform sampler2D lightmap;
uniform sampler2D gtexture;
uniform int isEyeInWater;

in vec2 lmcoord;
in vec2 texcoord;
in vec3 normal;
in vec4 glcolor;

/* RENDERTARGETS: 0,1,2 */
layout(location = 0) out vec4 color;
layout(location = 1) out vec4 lightmapData;
layout(location = 2) out vec4 normalData;

void main() {
    vec4 texColor = texture(gtexture, texcoord) * glcolor;
    vec3 light = texture(lightmap, lmcoord).rgb;
    color.rgb = texColor.rgb * light;
    if(isEyeInWater == 1) {
        color.a = 0.0;
    } else {
        color.a = texColor.a * 0.8;
    }
    lightmapData = vec4(lmcoord, 0.0, 1.0);
    normalData = vec4(normal * 0.5 + 0.5, 1.0);
}
