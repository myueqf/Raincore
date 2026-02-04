#version 330 compatibility

#include "/lib/distort.glsl"
#include /settings.glsl

uniform sampler2D colortex0;
uniform sampler2D depthtex0;

uniform float rainStrength;
uniform float far;
uniform int isEyeInWater;

uniform vec3 fogColor;

uniform mat4 gbufferProjectionInverse;

in vec2 texcoord;

vec3 projectAndDivide(mat4 projectionMatrix, vec3 position){
  vec4 homPos = projectionMatrix * vec4(position, 1.0);
  return homPos.xyz / homPos.w;
}

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

void main() {
  vec3 finalFogColor = vec3(0.2353, 0.3451, 0.4078);
  if (texcoord.x < 0.0 || texcoord.x > 1.0 || texcoord.y < 0.0 || texcoord.y > 1.0) {
    color = vec4(finalFogColor, 1.0);
    return;
  }

  color = texture(colortex0, texcoord);

  float depth = texture(depthtex0, texcoord).r;

  if (depth >= 1.0) {
    #if FOG_COVER_SKY != 0
    color.rgb = finalFogColor;
    #endif
    return;
  }

  vec3 NDCPos = vec3(texcoord.xy, depth) * 2.0 - 1.0;
  vec3 viewPos = projectAndDivide(gbufferProjectionInverse, NDCPos);
  float dist = length(viewPos) / far;
  // float fogFactor = exp(-10 * (0.3 - dist)); // 值越小雾越浓
  // color.rgb = mix(color.rgb, fogColor, clamp(fogFactor, 0.0, 1.0));

  // ===== 雨雾 =====
  float fogFactor = mix(
  exp(-10 * (FOG_SIZE - dist)),   // 普通雾
  exp(-10 * (0.2 - dist)),        // 雨雾
  smoothstep(0.0, 0.3, rainStrength)
  );
  // 水下雾
  if(isEyeInWater == 1) {
    fogFactor = fogFactor + 0.2;
  }
  fogFactor = clamp(fogFactor, 0.0, 1.0);
  color.rgb = mix(color.rgb, vec3(0.2353, 0.3451, 0.4078), fogFactor);
  // ==============
}
