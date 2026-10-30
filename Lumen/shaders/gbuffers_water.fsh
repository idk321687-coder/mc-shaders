#version 120
#include "/lib/settings.glsl"
#include "/lib/water.glsl"
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
    // Different scales move together in world space; height derivatives make
    // the highlights follow the same surface rather than a repeating grid.
    vec2 p = worldpos.xz;
    float t = frameTimeCounter;
    float h = waterHeight(p, t);
    float epsilon = 0.08;
    vec2 wave = vec2(waterHeight(p+vec2(epsilon,0.0),t)-h,
                     waterHeight(p+vec2(0.0,epsilon),t)-h) / epsilon;
    vec3 worldNormal = normalize(mat3(gbufferModelViewInverse) * normal);
    float topSurface = smoothstep(0.4, 0.9, worldNormal.y);
    float distanceFade = mix(1.0, 0.5, smoothstep(70.0, 180.0, length(worldpos-cameraPosition)));
    wave *= 1.35 * WAVE_STRENGTH * isWater * topSurface * distanceFade;
    vec3 n = normalize(normal + mat3(gbufferModelView) * vec3(wave.x, 0.0, wave.y));
    gl_FragData[0] = albedo * texture2D(lightmap, lightcoord);
    gl_FragData[1] = vec4(n * 0.5 + 0.5, isWater);
}
