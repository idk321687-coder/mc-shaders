#version 120
uniform sampler2D texture;
uniform sampler2D lightmap;
uniform float frameTimeCounter;
uniform mat4 gbufferModelView;
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
    vec2 wave = vec2(cos(worldpos.x*1.3+frameTimeCounter*0.8), sin(worldpos.z*1.1-frameTimeCounter*0.6))*0.075;
    vec3 n = normalize(normal + mat3(gbufferModelView) * vec3(wave.x, 0.0, wave.y));
    gl_FragData[0] = albedo * texture2D(lightmap, lightcoord);
    gl_FragData[1] = vec4(n * 0.5 + 0.5, isWater);
}
