#version 120
attribute vec4 mc_Entity;
varying float isWater;
varying vec2 texcoord;
varying vec2 lightcoord;
varying vec4 color;
varying vec3 normal;
varying vec3 worldpos;
uniform mat4 gbufferModelViewInverse;
uniform vec3 cameraPosition;
void main() {
    isWater = float(mc_Entity.x > 102.5 && mc_Entity.x < 103.5);
    vec4 view = gl_ModelViewMatrix * gl_Vertex;
    worldpos = (gbufferModelViewInverse * view).xyz + cameraPosition;
    gl_Position = gl_ProjectionMatrix * view;
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    lightcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    color = gl_Color;
    normal = normalize(gl_NormalMatrix * gl_Normal);
}
