#include "/lib/settings.glsl"
#include "/lib/sky.glsl"
#include "/lib/water.glsl"
#ifdef LUMEN_OTHER_DIMENSION
#include "/lib/dimensions.glsl"
#endif
// OpenGL internal format value; the shader loader does not define this GLSL token.
#ifndef RGBA16F
#define RGBA16F 34842
#endif
const int colortex0Format = RGBA16F;
uniform sampler2D colortex0;
uniform sampler2D colortex7;
uniform sampler2D colortex8;
uniform sampler2D depthtex0;
uniform sampler2D depthtex1;
uniform sampler2D shadowtex0;
uniform mat4 shadowProjection;
uniform mat4 shadowModelView;
uniform int isEyeInWater;
uniform mat4 gbufferModelView;
uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform vec3 sunPosition;
uniform float rainStrength;
uniform float frameTimeCounter;
uniform float viewWidth;
uniform float viewHeight;
uniform vec3 cameraPosition;
varying vec2 uv;
/* DRAWBUFFERS:0 */
vec3 viewPos(vec2 p, float depth) {
    vec4 v = gbufferProjectionInverse * vec4(p*2.0-1.0, depth*2.0-1.0, 1.0);
    return v.xyz / max(abs(v.w), 0.00001) * sign(v.w);
}
float shadowAtViewPosition(vec3 p) {
    vec4 worldRelative = gbufferModelViewInverse * vec4(p, 1.0);
    vec4 clip = shadowProjection * shadowModelView * worldRelative;
    vec3 shadowUV = clip.xyz / max(abs(clip.w), 0.00001) * 0.5 + 0.5;
    if (shadowUV.x <= 0.0 || shadowUV.x >= 1.0 || shadowUV.y <= 0.0 || shadowUV.y >= 1.0 || shadowUV.z <= 0.0 || shadowUV.z >= 1.0) return 1.0;
    return step(shadowUV.z - 0.0015, texture2D(shadowtex0, shadowUV.xy).r);
}
void main() {
    vec3 scene = texture2D(colortex0, uv).rgb;
    float depth = texture2D(depthtex0, uv).r;
    vec3 viewRay = normalize(viewPos(uv, 1.0));
    vec3 worldRay = normalize(mat3(gbufferModelViewInverse) * viewRay);
    vec3 sunDir = normalize(mat3(gbufferModelViewInverse) * sunPosition);
#if defined(CUSTOM_SKY) && !defined(LUMEN_OTHER_DIMENSION)
    if (depth >= 0.999999) scene = skyColor(worldRay, sunDir, rainStrength, frameTimeCounter);
#elif defined(CUSTOM_SKY) && defined(LUMEN_OTHER_DIMENSION)
    if (depth >= 0.999999) scene = dimensionSky(worldRay, frameTimeCounter);
#endif
    vec4 data = texture2D(colortex7, uv);
    if (data.a > 0.9 && depth < 0.999999) {
        float opaqueDepth = texture2D(depthtex1, uv).r;
        vec3 pos = viewPos(uv, depth);
        vec3 waterWorld = (gbufferModelViewInverse * vec4(pos, 1.0)).xyz + cameraPosition;
        vec3 waterNormal = normalize(data.rgb * 2.0 - 1.0);
        float thickness = opaqueDepth < 0.999999 ? max(0.0, length(viewPos(uv,opaqueDepth))-length(pos)) : 20.0;
#ifdef REFRACTION
        // Sample the opaque snapshot only when the displaced background is behind the surface.
        vec3 flatNormal = normalize(mat3(gbufferModelView) * vec3(0.0, 1.0, 0.0));
        vec2 waveOffset = waterNormal.xy - flatNormal.xy;
        vec2 refractedUV = clamp(uv + waveOffset * 0.035 * smoothstep(0.0,2.0,thickness), vec2(0.001), vec2(0.999));
        float refractedDepth = texture2D(depthtex1, refractedUV).r;
        if (refractedDepth > depth + 0.00001)
            scene = mix(scene, texture2D(colortex8, refractedUV).rgb, 0.55);
#endif
#ifdef WATER_EFFECTS

        vec3 transmittance = exp(-vec3(0.065, 0.027, 0.018) * thickness);
        scene = scene * transmittance + vec3(0.015,0.13,0.16) * (1.0-transmittance);
        // Surface shading is visible even when looking straight down, where Fresnel
        // reflections are naturally weak. It uses the exact same animated wave field
        // as the normal map, and scales with scene color so it does not glow at night.
        vec3 flatUp = normalize(mat3(gbufferModelView) * vec3(0.0,1.0,0.0));
        float upward = smoothstep(0.35, 0.8, dot(waterNormal, flatUp));
        float topDown = smoothstep(0.15, 0.9, abs(dot(normalize(pos), flatUp)));
        float crest = clamp((waterHeight(waterWorld.xz, frameTimeCounter) - 0.08)*2.4, -0.6, 0.6);
        float detail = clamp(WAVE_STRENGTH, 0.0, 1.5) * upward * mix(0.20, 0.60, topDown);
        scene *= max(0.0, 1.0 + crest * detail);
        // Broken, animated foam follows world-space shoreline intersections.
        float foamNoise = waterNoise(waterWorld.xz*1.3 + vec2(frameTimeCounter*WAVE_SPEED*0.08,-frameTimeCounter*WAVE_SPEED*0.04));
        float foam = (1.0-smoothstep(0.08, 0.65, thickness)) * smoothstep(0.35,0.75,foamNoise) * float(opaqueDepth < 0.999999);
        scene = mix(scene, vec3(0.62,0.72,0.68), foam*0.25);
#ifdef CAUSTICS
        if (opaqueDepth < 0.999999) {
            vec3 bottom = (gbufferModelViewInverse * vec4(viewPos(uv,opaqueDepth),1.0)).xyz + cameraPosition;
            vec2 drift = vec2(frameTimeCounter*WAVE_SPEED*0.11, -frameTimeCounter*WAVE_SPEED*0.08);
            float c1 = waterNoise(bottom.xz*0.9 + drift);
            float c2 = waterNoise(bottom.xz*1.35 - drift + 4.7);
            float caustic = pow(max(0.0,1.0-abs(c1-c2)*4.0), 5.0) * exp(-thickness * 0.16);
#ifndef LUMEN_OTHER_DIMENSION
            caustic *= smoothstep(0.0, 0.2, sunDir.y) * (1.0-rainStrength) * shadowAtViewPosition(viewPos(uv, opaqueDepth));
#else
            caustic = 0.0;
#endif
            scene += vec3(0.12, 0.16, 0.12) * caustic;
        }
#endif
#endif
#ifdef WATER_REFLECTIONS
        vec3 n = waterNormal;
        vec3 reflected = normalize(reflect(normalize(pos), n));
        #ifdef LUMEN_OTHER_DIMENSION
        vec3 reflection = dimensionSky(normalize(mat3(gbufferModelViewInverse)*reflected), frameTimeCounter);
#else
        vec3 reflection = skyColor(normalize(mat3(gbufferModelViewInverse)*reflected), sunDir, rainStrength, frameTimeCounter);
#endif
#ifndef LUMEN_OTHER_DIMENSION
        // Replace the tiny HDR disk in the sky lookup with the continuous surface
        // specular lobe below; this avoids repeated white sun disks on every wave.
        vec3 reflectedWorld = normalize(mat3(gbufferModelViewInverse)*reflected);
        float disk = smoothstep(0.999988, 0.999991, max(dot(reflectedWorld,sunDir),0.0));
        float daylight = smoothstep(-0.12, 0.12, sunDir.y);
        reflection = max(reflection - vec3(3.5,2.8,2.0)*disk*daylight*(1.0-rainStrength), vec3(0.0));
#endif
        vec3 ray = pos + reflected * 0.15;
        for (int i = 0; i < SSR_STEPS; i++) {
            vec3 previousRay = ray;
            ray += reflected * (0.3 + float(i) * 0.12);
            vec4 clip = gbufferProjection * vec4(ray, 1.0);
            if (clip.w <= 0.0) break;
            vec2 p = clip.xy / clip.w * 0.5 + 0.5;
            if (p.x <= 0.0 || p.x >= 1.0 || p.y <= 0.0 || p.y >= 1.0) break;
            float d = texture2D(depthtex0, p).r;
            vec3 hit = viewPos(p, d);
            float diff = hit.z - ray.z;
            if (d < 0.999999 && diff > 0.0 && diff < 0.8 && texture2D(colortex7, p).a < 0.5) {
                // Refine the segment after a depth crossing to reduce marching artifacts.
                vec3 lo = previousRay;
                vec3 hi = ray;
                for (int j = 0; j < 4; j++) {
                    vec3 mid = (lo + hi) * 0.5;
                    vec4 midClip = gbufferProjection * vec4(mid, 1.0);
                    vec2 midUV = midClip.xy / max(midClip.w, 0.00001) * 0.5 + 0.5;
                    midUV = clamp(midUV, vec2(0.001), vec2(0.999));
                    float midDepth = texture2D(depthtex0, midUV).r;
                    if (midDepth < 0.999999 && viewPos(midUV, midDepth).z - mid.z > 0.0)
                        hi = mid;
                    else
                        lo = mid;
                }
                vec4 refinedClip = gbufferProjection * vec4(hi, 1.0);
                p = clamp(refinedClip.xy / max(refinedClip.w,0.00001) * 0.5 + 0.5, vec2(0.001), vec2(0.999));
                float edge = smoothstep(0.0, 0.12, min(min(p.x,p.y),min(1.0-p.x,1.0-p.y)));
                reflection = mix(reflection, texture2D(colortex0, p).rgb, edge * (1.0-float(i)/float(SSR_STEPS+6)));
                break;
            }
        }
        float grazing = pow(1.0-max(dot(-normalize(pos),n),0.0),5.0);
        // An artistic base reflection keeps water visibly reflective from above.
        float reflectionWeight = mix(0.20, 0.82, grazing) * REFLECTION_STRENGTH;
        scene = mix(scene, reflection, clamp(reflectionWeight, 0.0, 0.85));
#ifndef LUMEN_OTHER_DIMENSION
        vec3 sunView = normalize(sunPosition);
        vec3 halfway = normalize(sunView - normalize(pos));
        // Broad microfacet-like sunlight plus irregular moving sparkle; keep the
        // radiance bounded instead of placing multiple hard-edged sun disks.
        float nh = max(dot(n, halfway), 0.0);
        float roughness = 0.18;
        float a2 = roughness * roughness;
        float denom = max(nh*nh*(a2-1.0)+1.0, 0.001);
        float lobe = min(a2/(denom*denom)*0.045, 0.85);
        float sparkle = waterNoise(waterWorld.xz*1.7 + vec2(frameTimeCounter*WAVE_SPEED*0.19,-frameTimeCounter*WAVE_SPEED*0.14));
        float sunVisibility = smoothstep(0.0,0.15,sunDir.y) * (1.0-rainStrength) * shadowAtViewPosition(pos);
        scene += vec3(1.0,0.82,0.58) * lobe * mix(0.55,1.0,sparkle) * sunVisibility;
#endif
#endif
    }
#ifdef SSAO
    if (depth < 0.999999 && data.a < 0.5) {
        vec3 center = viewPos(uv, depth);
        vec2 pixel = vec2(1.0/max(viewWidth, 1.0), 1.0/max(viewHeight, 1.0));
        float occlusion = 0.0;
        for (int i=0; i<8; i++) {
            float angle = float(i)*0.78539816;
            vec2 sampleUV = clamp(uv + vec2(cos(angle),sin(angle))*pixel*5.0, vec2(0.001), vec2(0.999));
            float d = texture2D(depthtex0, sampleUV).r;
            vec3 samplePos = viewPos(sampleUV, d);
            float dz = samplePos.z-center.z;
            occlusion += step(0.03, dz) * (1.0-smoothstep(0.1, 1.2, dz)) * step(d, 0.999998);
        }
        scene *= 1.0 - occlusion * 0.035;
    }
#endif
#if defined(HEIGHT_FOG) && !defined(LUMEN_OTHER_DIMENSION)
    if (depth < 0.999999 && isEyeInWater == 0) {
        float distanceToSurface = length(viewPos(uv,depth));
        float fog = (1.0-exp(-distanceToSurface*0.0025)) * (0.5+0.5*rainStrength);
        vec3 fogColor = skyColor(normalize(vec3(worldRay.x, 0.05, worldRay.z)), sunDir, rainStrength, frameTimeCounter);
        scene = mix(scene, fogColor, clamp(fog, 0.0, 0.65));
    }
#endif
#if defined(GOD_RAYS) && !defined(LUMEN_OTHER_DIMENSION)
    // Integrate shadow-map visibility along the camera ray, capped at the shadow range.
    float rayLength = depth < 0.999999 ? min(length(viewPos(uv, depth)), 96.0) : 96.0;
    float scatter = 0.0;
    float jitter = fract(sin(dot(uv, vec2(12.9898,78.233))) * 43758.5453);
    for (int i = 0; i < VOLUMETRIC_STEPS; i++) {
        float t = (float(i) + jitter) / float(VOLUMETRIC_STEPS);
        vec3 sampleView = viewRay * (rayLength * t);
        vec4 sampleWorld = gbufferModelViewInverse * vec4(sampleView, 1.0);
        vec4 sc = shadowProjection * shadowModelView * sampleWorld;
        vec3 sp = sc.xyz / sc.w * 0.5 + 0.5;
        if (sp.x > 0.0 && sp.x < 1.0 && sp.y > 0.0 && sp.y < 1.0 && sp.z > 0.0 && sp.z < 1.0)
            scatter += step(sp.z - 0.001, texture2D(shadowtex0,sp.xy).r);
    }
    float towardSun = max(dot(viewRay, normalize(sunPosition)), 0.0);
    float phase = 0.05 + pow(towardSun, 8.0) * 0.95;
    float day = smoothstep(-0.04, 0.12, sunDir.y);
    float towardMoon = max(dot(viewRay, -normalize(sunPosition)), 0.0);
    float moonPhaseFn = 0.05 + pow(towardMoon, 8.0) * 0.95;
    vec3 shaftColor = vec3(1.0,0.73,0.48) * phase * day * 0.2
                    + vec3(0.18,0.25,0.42) * moonPhaseFn * (1.0-day) * 0.035;
    scene += shaftColor * scatter / float(VOLUMETRIC_STEPS) * (1.0-rainStrength*0.6) * min(rayLength/96.0,1.0);
#endif
    if (isEyeInWater == 1) {
        float distanceInWater = depth < 0.999999 ? min(length(viewPos(uv,depth)), 80.0) : 80.0;
        vec3 transmittance = exp(-vec3(0.10,0.045,0.025)*distanceInWater);
        scene = scene*transmittance + vec3(0.015,0.11,0.14)*(1.0-transmittance);
    }
    gl_FragData[0] = vec4(max(scene, vec3(0.0)), 1.0);
}
