#version 120
#include "/lib/settings.glsl"
#include "/lib/tonemap.glsl"
#ifdef AUTO_EXPOSURE
const bool colortex0MipmapEnabled = true;
#endif
uniform sampler2D colortex0;
uniform sampler2D colortex2;
uniform sampler2D colortex3;
uniform sampler2D colortex4;
uniform sampler2D colortex5;
uniform sampler2D colortex6;
uniform float viewWidth;
uniform float viewHeight;
varying vec2 uv;
void main() {
    vec3 c = max(texture2D(colortex0, uv).rgb, vec3(0.0));
#ifdef BLOOM
    // Normalized multi-scale bloom. Hardware bilinear filtering performs the upsample.
    vec3 bloom = texture2D(colortex2,uv).rgb + texture2D(colortex3,uv).rgb
               + texture2D(colortex4,uv).rgb + texture2D(colortex5,uv).rgb
               + texture2D(colortex6,uv).rgb;
    c += bloom * 0.08;
#endif
    float exposure = EXPOSURE;
#ifdef AUTO_EXPOSURE
    // Global luminance estimate; no persistent history, so response is instantaneous.
    vec3 average = texture2D(colortex0, vec2(0.5), 10.0).rgb;
    float averageLuma = dot(max(average,vec3(0.0)), vec3(0.2126,0.7152,0.0722));
    exposure *= clamp(0.3 / max(averageLuma, 0.05), 0.5, 2.0);
#endif
    c *= exposure;
    float luma = dot(c, vec3(0.2126, 0.7152, 0.0722));
    c = max(mix(vec3(luma), c, COLOR_SATURATION), vec3(0.0));
#ifdef TONEMAP_AGX
    c = agxToneMap(c);
#elif defined(FILMIC)
    // ACES-inspired fitted curve (not a full ACES color transform).
    c = clamp((c*(2.51*c+0.03))/(c*(2.43*c+0.59)+0.14), 0.0, 1.0);
#else
    c = clamp(c, 0.0, 1.0);
#endif
#ifdef VIGNETTE
    vec2 centered = uv*2.0-1.0;
    c *= 1.0 - 0.12 * smoothstep(0.2, 1.6, dot(centered,centered));
#endif
    float dither = fract(sin(dot(gl_FragCoord.xy, vec2(12.9898,78.233))) * 43758.5453) - 0.5;
    gl_FragColor = vec4(clamp(c + dither / 255.0, 0.0, 1.0), 1.0);
}
