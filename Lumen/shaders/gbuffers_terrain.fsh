#version 120
#include "/lib/settings.glsl"
uniform sampler2D shadowtex0;
#ifdef LAB_PBR
uniform sampler2D normals;
uniform sampler2D specular;
varying vec4 viewTangent;
#endif
varying vec3 viewPosition;
uniform vec3 shadowLightPosition;
uniform float frameTimeCounter;
uniform float rainStrength;
uniform float wetness;
uniform mat4 gbufferModelViewInverse;
varying vec3 worldPos;
varying vec3 shadowPos;
const int shadowMapResolution = 2048;
const float shadowDistance = 128.0;
uniform sampler2D texture;
uniform sampler2D lightmap;
varying vec2 texcoord;
varying vec2 lightcoord;
varying vec4 color;
varying vec3 normal;
/* DRAWBUFFERS:07 */
void main() {
    vec4 albedo = texture2D(texture, texcoord) * color;
    if (albedo.a < 0.1) discard;
    vec4 lighting = texture2D(lightmap, lightcoord);
    vec3 surfaceNormal = normalize(normal);
    float smoothness = 0.0;
    float reflectance = 0.04;
    float materialAO = 1.0;
#ifdef LAB_PBR
    vec4 normalMap = texture2D(normals, texcoord);
    vec4 specMap = texture2D(specular, texcoord);
    vec2 xy = normalMap.rg * 2.0 - 1.0;
    // Clamp malformed maps before reconstructing the tangent-space Z component.
    xy *= min(1.0, 0.999 / max(length(xy), 0.0001));
    vec3 tangent = normalize(viewTangent.xyz - surfaceNormal * dot(surfaceNormal, viewTangent.xyz));
    vec3 bitangent = normalize(cross(surfaceNormal, tangent)) * viewTangent.w;
    surfaceNormal = normalize(mat3(tangent, bitangent, surfaceNormal) * vec3(xy, sqrt(max(1.0-dot(xy,xy), 0.0))));
    materialAO = normalMap.b;
    smoothness = specMap.r;
    // LabPBR green values 230-255 encode conductor IDs rather than dielectric F0.
    reflectance = specMap.g < 0.9 ? clamp(specMap.g, 0.02, 0.9) : 0.7;
#endif
    float shadowVisibility = 1.0;
#ifdef SHADOWS
    if (shadowPos.x > 0.002 && shadowPos.x < 0.998 && shadowPos.y > 0.002 && shadowPos.y < 0.998 && shadowPos.z > 0.0 && shadowPos.z < 1.0) {
        float visibility = 0.0;
        float bias = 0.0007 + 0.0015 * (1.0 - max(dot(normalize(normal), normalize(shadowLightPosition)), 0.0));
        // Small blocker search followed by a variable-radius PCF filter.
        float blockers = 0.0;
        float blockerDepth = 0.0;
        for (int i = 0; i < 8; i++) {
            float angle = float(i) * 2.399963;
            vec2 offset = vec2(cos(angle), sin(angle)) * (1.0 + float(i) * 0.35) / 2048.0;
            float d = texture2D(shadowtex0, shadowPos.xy + offset).r;
            float blocked = 1.0 - step(shadowPos.z - bias, d);
            blockers += blocked;
            blockerDepth += d * blocked;
        }
        float meanDepth = blockers > 0.0 ? blockerDepth / blockers : shadowPos.z;
        float radius = clamp(1.0 + (shadowPos.z - meanDepth) * 200.0, 1.0, 5.0);
        for (int i = 0; i < 12; i++) {
            float angle = float(i) * 2.399963;
            float r = sqrt((float(i) + 0.5) / 12.0);
            float d = texture2D(shadowtex0, shadowPos.xy + vec2(cos(angle), sin(angle)) * r * radius / 2048.0).r;
            visibility += step(shadowPos.z - bias, d);
        }
        shadowVisibility = visibility / 12.0;
        float skyLight = smoothstep(0.55, 0.95, lightcoord.y);
        lighting.rgb *= mix(1.0, mix(0.58, 1.0, shadowVisibility), skyLight);
    }
#endif
#ifdef CLOUD_SHADOWS
    // A low-frequency moving procedural cloud field, attenuated indoors by skylight.
    float cloud = sin(worldPos.x*0.012 + frameTimeCounter*0.025)
                + sin(worldPos.z*0.016 - frameTimeCounter*0.018)
                + sin((worldPos.x+worldPos.z)*0.008 + frameTimeCounter*0.013);
    float cloudCover = smoothstep(0.15, 1.7, cloud);
    lighting.rgb *= 1.0 - cloudCover * smoothstep(0.65, 0.95, lightcoord.y) * (0.12 + rainStrength*0.12);
#endif
    vec3 worldNormal = normalize(mat3(gbufferModelViewInverse) * normal);
    float exposed = smoothstep(0.65, 0.95, lightcoord.y) * smoothstep(0.25, 0.85, worldNormal.y);
#ifdef WET_SURFACES
    albedo.rgb *= 1.0 - wetness * exposed * 0.22;
#endif
#ifdef PUDDLES
    float puddleField = sin(worldPos.x * 0.38 + sin(worldPos.z * 0.17)) + cos(worldPos.z * 0.31);
    float puddle = smoothstep(0.55, 1.3, puddleField) * wetness * exposed;
    float ripple = sin(length(fract(worldPos.xz*0.7)-0.5)*25.0-frameTimeCounter*5.0);
    smoothness = max(smoothness, puddle * (0.85 + ripple*rainStrength*0.08));
    reflectance = max(reflectance, puddle * 0.08);
    albedo.rgb *= 1.0 - puddle*0.12;
#endif
    vec3 lightDir = normalize(shadowLightPosition);
    vec3 eyeDir = normalize(-viewPosition);
    vec3 halfDir = normalize(lightDir + eyeDir + vec3(0.00001));
    float specPower = mix(8.0, 256.0, smoothness * smoothness);
    float specularLight = pow(max(dot(surfaceNormal, halfDir), 0.0), specPower)
                        * reflectance * smoothness * shadowVisibility
                        * smoothstep(0.65, 0.95, lightcoord.y);
    lighting.rgb *= mix(1.0, materialAO, 0.5);
    albedo.rgb += vec3(specularLight);
    gl_FragData[0] = albedo * lighting;
    gl_FragData[1] = vec4(surfaceNormal * 0.5 + 0.5, 0.0);
}
