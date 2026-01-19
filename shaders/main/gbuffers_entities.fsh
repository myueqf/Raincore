#version 120

#include /settings.glsl

uniform sampler2D texture;
varying vec4 color;
varying vec2 texCoord;
varying vec2 lmCoord;
varying vec4 viewPos;

void main() {
    vec4 texColor = texture2D(texture, texCoord) * color;

#if ENTITYHIDDEN >= 1
    // 计算当前像素点与玩家的欧几里得距离
    float dist = length(viewPos.xyz);

    float hideDist = ENTITYHIDDEN;
    float fadeRange = 5.0;  // 淡出缓冲区

    // smoothstep(下限, 上限, 当前值)
    // 当 dist < 20 时返回 0.0，当 dist > 25 时返回 1.0
    float visibility = smoothstep(hideDist, hideDist + fadeRange, dist);

    texColor.a *= visibility;
#endif

    if (texColor.a < 0.01) {
        discard;
    }

    gl_FragData[0] = texColor;
}