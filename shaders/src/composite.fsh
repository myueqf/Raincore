#version 330 compatibility

#include /lib/distort.glsl
#include /settings.glsl

uniform sampler2D shadowtex0;
uniform sampler2D depthtex0;
uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D colortex2;

uniform vec3 shadowLightPosition;
uniform float rainStrength;
uniform int worldTime;
uniform ivec2 eyeBrightnessSmooth;

uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform mat4 shadowModelView;
uniform mat4 shadowProjection;

// 颜色
const vec3 blocklightColor = vec3(1.0, 1.0, 1.1);
const vec3 skylightColor = vec3(0.3725, 0.5608, 0.6392);
const vec3 sunlightColor = skylightColor;
const vec3 minLightColor = vec3(0.15);

in vec2 texcoord;

vec3 projectAndDivide(mat4 projectionMatrix, vec3 position){
  vec4 homPos = projectionMatrix * vec4(position, 1.0);
  return homPos.xyz / homPos.w;
}

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

void main() {
    // 昼夜（提前计算，天空也需要去饱和）
    float timeNormalized = fract(float(worldTime) / 24000.0);
    float dayFactor = clamp(0.5 + 0.5 * cos((timeNormalized - 0.25) * 6.2832), 0.0, 1.0);
    float dayNightStrength = dayFactor;
    float nightFactor = 1.0 - dayFactor;
    if (BRIGHTNESS_GAIN >= 0.1) dayNightStrength += BRIGHTNESS_GAIN;

    float desatAmount = clamp(nightFactor * NIGHT_DESAT, 0.0, 1.0);

    float depth = texture(depthtex0, texcoord).r;
    if (depth == 1.0) {
        color = texture(colortex0, texcoord);
        float skyLuma = dot(color.rgb, vec3(0.2126, 0.7152, 0.0722));
        color.rgb = mix(color.rgb, vec3(skyLuma), desatAmount);
        return;
    }

    vec2 lightmap = texture(colortex1, texcoord).rg;
    vec3 encodedNormal = texture(colortex2, texcoord).rgb;
    vec3 normal = (encodedNormal - 0.5) * 2.0;
    float normalLen = length(normal);
    bool flatNormal = normalLen <= 0.01 || dot(encodedNormal, vec3(1.0)) <= 0.01;
    normal = normalLen > 0.01 ? normal / normalLen : vec3(0.0, 1.0, 0.0);

    vec3 lightVector = normalize(shadowLightPosition);
    vec3 worldLightVector = mat3(gbufferModelViewInverse) * lightVector;

    // 阴影坐标转换
    vec3 NDCPos = vec3(texcoord.xy, depth) * 2.0 - 1.0;
    vec3 viewPos = projectAndDivide(gbufferProjectionInverse, NDCPos);
    vec3 feetPlayerPos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;
    vec3 shadowViewPos = (shadowModelView * vec4(feetPlayerPos, 1.0)).xyz;
    vec4 shadowClipPos = shadowProjection * vec4(shadowViewPos, 1.0);

    shadowClipPos.xyz = distortShadowClipPos(shadowClipPos.xyz);
    vec3 shadowNDCPos = shadowClipPos.xyz / shadowClipPos.w;
    vec3 shadowScreenPos = shadowNDCPos * 0.5 + 0.5;

    float NdotL = dot(normal, worldLightVector);
    float cosTheta = clamp(NdotL, 0.0, 1.0);
    float bias = 0.001 + 0.004 * (1.0 - cosTheta);
    shadowScreenPos.z -= bias;

#if SHADOW_SOFT == 0
    float shadow = step(shadowScreenPos.z, texture(shadowtex0, shadowScreenPos.xy).r);
#else
    float shadow = 0.0;
    float shadowRadius = 0.0008;

    shadow += step(shadowScreenPos.z, texture(shadowtex0, shadowScreenPos.xy + vec2( shadowRadius,  shadowRadius)).r);
    shadow += step(shadowScreenPos.z, texture(shadowtex0, shadowScreenPos.xy + vec2(-shadowRadius,  shadowRadius)).r);
    shadow += step(shadowScreenPos.z, texture(shadowtex0, shadowScreenPos.xy + vec2( shadowRadius, -shadowRadius)).r);
    shadow += step(shadowScreenPos.z, texture(shadowtex0, shadowScreenPos.xy + vec2(-shadowRadius, -shadowRadius)).r);
    shadow /= 4.0;
#endif

    // 光照计算
    float torchLut = clamp(16.0 - lightmap.r * 16.0, 0.5, 15.5) + 0.712;
    float torchmap = max(1.0 / (torchLut * torchLut) - 1.0 / (16.212 * 16.212), 0.0) * 8.0;
    vec3 torchlight = (torchmap * 0.35 + lightmap.r * lightmap.r * 0.6) * blocklightColor;

    // 方向性环境光（按法线六向混合）
    vec3 ambientUp = skylightColor * 1.15;
    vec3 ambientDown = skylightColor * 0.35;
    vec3 ambientSide = skylightColor * 0.7;
    vec3 ambientCoefs = normal / max(dot(abs(normal), vec3(1.0)), 1e-4);
    vec3 ambientLight = ambientUp * clamp(ambientCoefs.y, 0.0, 1.0)
                      + ambientDown * clamp(-ambientCoefs.y, 0.0, 1.0)
                      + ambientSide * (clamp(ambientCoefs.x, 0.0, 1.0) + clamp(-ambientCoefs.x, 0.0, 1.0)
                                     + clamp(ambientCoefs.z, 0.0, 1.0) + clamp(-ambientCoefs.z, 0.0, 1.0));
    if (flatNormal) ambientLight = skylightColor * 0.8;
    ambientLight *= dayNightStrength;
    if (SKYLIGHT_GAIN > 0.05) ambientLight += skylightColor * SKYLIGHT_GAIN * dayNightStrength;

    float skyCurve = pow(clamp(lightmap.g, 0.0, 1.0), 1.0);
    vec3 skylight = ambientLight * (skyCurve * 1.6 + 0.15);

    // 直射光：NdotL + 阴影 + 雨衰减 + 洞穴漏光修复
    float diffuseSun = flatNormal ? 1.0 : cosTheta;
    float sunShadow = shadow;
    sunShadow = mix(sunShadow, 1.0, clamp(1.0 - diffuseSun * 100.0, 0.0, 1.0));
    sunShadow *= clamp(eyeBrightnessSmooth.y / 255.0 + lightmap.g, 0.0, 1.0);
    vec3 sunlight = sunlightColor * diffuseSun * sunShadow * (1.0 - rainStrength * 0.85) * dayNightStrength;

    vec3 minLight = minLightColor * 0.15;

    color = texture(colortex0, texcoord);
    color.rgb *= torchlight + skylight + sunlight + minLight;

    // 夜间线性去饱和以区分昼夜
    float luma = dot(color.rgb, vec3(0.2126, 0.7152, 0.0722));
    color.rgb = mix(color.rgb, vec3(luma), desatAmount);

    // 动态曝光
    float sceneBright = (float(eyeBrightnessSmooth.y) * 0.75 + float(eyeBrightnessSmooth.x) * 0.25) / 255.0;
    float targetExp = mix(1.5, 0.55, clamp(sceneBright * (0.4 + dayNightStrength), 0.0, 1.0));
    // 高光压缩
    vec3 hdr = color.rgb * targetExp;
    color.rgb = hdr / (1.0 + hdr * 0.35);
    color.rgb = pow(color.rgb, vec3(2.2));

    float noise = fract(sin(dot(texcoord, vec2(12.9898, 78.233)) + float(worldTime) * 0.1) * 43758.5453);
    color.rgb += (noise - 0.5) * 0.008;
}
