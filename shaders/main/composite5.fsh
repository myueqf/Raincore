#version 330 compatibility
/* 像素化 */
uniform sampler2D gColor;
varying vec2 texCoord;
#include "/settings.glsl"
#define DITHER_MODE 1

#if PIXEL == 0
const vec2 gridRes = vec2(160.0, 120.0);
#elif PIXEL == 1
const vec2 gridRes = vec2(320.0, 240.0);
#elif PIXEL == 2
const vec2 gridRes = vec2(640.0, 480.0);
#else PIXEL == 3
const vec2 gridRes = vec2(1280.0, 960.0);
#endif

const float SHADE_STEPS = 64.0;

#if DITHER_MODE == 1
const float bayer4x4[16] = float[] (
0.0/16.0, 8.0/16.0, 2.0/16.0, 10.0/16.0,
12.0/16.0, 4.0/16.0, 14.0/16.0, 6.0/16.0,
3.0/16.0, 11.0/16.0, 1.0/16.0, 9.0/16.0,
15.0/16.0, 7.0/16.0, 13.0/16.0, 5.0/16.0
);
#endif

void main() {
    vec2 pixelCoord = floor(texCoord * gridRes) / gridRes;
    vec3 color = texture2D(gColor, pixelCoord).rgb;

    // Gamma
    color = pow(color, vec3(GAMMA));

    #if DITHER_MODE > 0
    float threshold = 0.0;
    #if DITHER_MODE == 1
    vec2 ditherPos = floor(gl_FragCoord.xy);
    int index = int(mod(ditherPos.x, 4.0)) + int(mod(ditherPos.y, 4.0)) * 4;
    threshold = bayer4x4[index];
    vec3 stepped = floor(color * SHADE_STEPS) / SHADE_STEPS;
    vec3 error = color - stepped;
    vec3 boost = step(vec3(threshold / SHADE_STEPS), error);
    color = stepped + (boost / SHADE_STEPS);
    #endif
    gl_FragData[0] = vec4(color, 1.0);
}