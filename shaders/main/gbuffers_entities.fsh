#version 330 compatibility

#include /settings.glsl

uniform sampler2D texture;
varying vec4 color;
varying vec2 texCoord;
varying vec2 lmCoord;
varying vec4 viewPos;

/* RENDERTARGETS: 0,1,2 */

void main() {
    vec4 texColor = texture2D(texture, texCoord) * color;

#if ENTITYHIDDEN >= 1
    float dist = length(viewPos.xyz);
    float hideDist = float(ENTITYHIDDEN);

    if (dist < hideDist) {
        ivec2 px = ivec2(gl_FragCoord.xy);
        if ((px.x ^ px.y) == 0) {
            discard;
        }
    }

    float fadeRange = 5.0;
    float visibility = smoothstep(hideDist, hideDist + fadeRange, dist);

    texColor.a *= visibility;
#endif

    if (texColor.a < 0.01) {
        discard;
    }

    gl_FragData[0] = texColor;
    gl_FragData[1] = vec4(lmCoord, 0.0, 1.0);
    gl_FragData[2] = vec4(0.0, 0.0, 0.0, 1.0);
}