#version 120
const int shadowMapResolution = 2048;
const float shadowDistance = 128.0;
#include "/lib/settings.glsl"
#include "/lib/wind.glsl"
attribute vec4 mc_Entity;
attribute vec4 mc_midTexCoord;
uniform mat4 shadowModelViewInverse;
uniform mat4 shadowModelView;
uniform vec3 cameraPosition;
uniform float frameTimeCounter;
uniform float rainStrength;
varying vec2 texcoord;
varying vec4 color;
void main() {
    vec4 view = gl_ModelViewMatrix * gl_Vertex;
    vec3 world = (shadowModelViewInverse * view).xyz + cameraPosition;
    float top = float(gl_MultiTexCoord0.t < mc_midTexCoord.t);
    world = applyWind(world, mc_Entity.x, top, frameTimeCounter, rainStrength);
    gl_Position = gl_ProjectionMatrix * shadowModelView * vec4(world-cameraPosition, 1.0);
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    color = gl_Color;
}
