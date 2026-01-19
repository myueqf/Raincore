#version 120

varying vec4 color;
varying vec2 texCoord;
varying vec2 lmCoord;
varying vec4 viewPos;

void main() {
    gl_Position = ftransform();

    // 获取实体在视图空间的坐标 (相对于玩家摄像机)
    viewPos = gl_ModelViewMatrix * gl_Vertex;

    // 传递原有的属性
    color = gl_Color;
    texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    lmCoord  = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
}