#version 120
#include "/lib/settings.glsl"
#include "/lib/wind.glsl"
attribute vec4 mc_Entity;
attribute vec4 mc_midTexCoord;
#ifdef LAB_PBR
attribute vec4 at_tangent;
varying vec4 viewTangent;
#endif
varying vec3 viewPosition;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferModelView;
uniform vec3 cameraPosition;
uniform float frameTimeCounter;
uniform float rainStrength;
uniform mat4 shadowModelView;
uniform mat4 shadowProjection;
varying vec3 shadowPos;
varying vec3 worldPos;
varying vec2 texcoord;
varying vec2 lightcoord;
varying vec4 color;
varying vec3 normal;
void main() {
    vec4 view = gl_ModelViewMatrix * gl_Vertex;
    vec3 world = (gbufferModelViewInverse * view).xyz + cameraPosition;
    float top = float(gl_MultiTexCoord0.t < mc_midTexCoord.t);
    world = applyWind(world, mc_Entity.x, top, frameTimeCounter, rainStrength);
    worldPos = world;
    vec4 shadowClip = shadowProjection * shadowModelView * vec4(world - cameraPosition, 1.0);
    shadowPos = shadowClip.xyz / shadowClip.w * 0.5 + 0.5;
    view = gbufferModelView * vec4(world - cameraPosition, 1.0);
    viewPosition = view.xyz;
#ifdef LAB_PBR
    viewTangent = vec4(normalize(gl_NormalMatrix * at_tangent.xyz), at_tangent.w);
#endif
    gl_Position = gl_ProjectionMatrix * view;
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    lightcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    color = gl_Color;
    normal = normalize(gl_NormalMatrix * gl_Normal);
}
