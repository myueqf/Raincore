#version 330 compatibility

varying vec4 color;
varying vec2 texCoord;
varying vec2 lmCoord;
varying vec4 viewPos;

void main() {
    gl_Position = ftransform();

    viewPos = gl_ModelViewMatrix * gl_Vertex;

    color = gl_Color;
    texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    lmCoord  = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
}