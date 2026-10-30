#version 120
#include "/lib/settings.glsl"
uniform sampler2D texture;
uniform sampler2D lightmap;
uniform float frameTimeCounter;
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform vec3 cameraPosition;
varying float isWater;
varying vec2 texcoord;
varying vec2 lightcoord;
varying vec4 color;
varying vec3 normal;
varying vec3 worldpos;
/* DRAWBUFFERS:07 */
void main() {
    vec4 albedo = texture2D(texture, texcoord) * color;
    if (albedo.a < 0.01) discard;
    // Low-amplitude, differently oriented waves avoid a repeating grid of bright spots.
    vec2 p = worldpos.xz;
    float t = frameTimeCounter;
    float a = dot(p, vec2(0.31, 0.18)) + t * 0.40;
    float b = dot(p, vec2(-0.21, 0.37)) - t * 0.31;
    float c = dot(p, vec2(0.49, -0.34)) + t * 0.53;
    vec2 wave = vec2(0.31,0.18)*cos(a)*0.055
              + vec2(-0.21,0.37)*cos(b)*0.035
              + vec2(0.49,-0.34)*cos(c)*0.012;
    vec3 worldNormal = normalize(mat3(gbufferModelViewInverse) * normal);
    float topSurface = smoothstep(0.4, 0.9, worldNormal.y);
    float distanceFade = 1.0 - smoothstep(30.0, 120.0, length(worldpos-cameraPosition));
    wave *= WAVE_STRENGTH * isWater * topSurface * distanceFade;
    vec3 n = normalize(normal + mat3(gbufferModelView) * vec3(wave.x, 0.0, wave.y));
    gl_FragData[0] = albedo * texture2D(lightmap, lightcoord);
    gl_FragData[1] = vec4(n * 0.5 + 0.5, isWater);
}
