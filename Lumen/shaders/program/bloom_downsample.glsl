#include "/lib/settings.glsl"
uniform sampler2D BLOOM_SOURCE;
uniform float viewWidth;
uniform float viewHeight;
varying vec2 uv;
// Each stage reads the previous level with a four-tap box filter.
void main() {
#ifdef BLOOM
    vec2 texel = BLOOM_SCALE / vec2(max(viewWidth,1.0), max(viewHeight,1.0));
    vec3 a = texture2D(BLOOM_SOURCE, uv + texel*vec2(-0.5,-0.5)).rgb;
    vec3 b = texture2D(BLOOM_SOURCE, uv + texel*vec2( 0.5,-0.5)).rgb;
    vec3 c = texture2D(BLOOM_SOURCE, uv + texel*vec2(-0.5, 0.5)).rgb;
    vec3 d = texture2D(BLOOM_SOURCE, uv + texel*vec2( 0.5, 0.5)).rgb;
#ifdef BLOOM_THRESHOLD
    a = max(a - vec3(1.0), vec3(0.0));
    b = max(b - vec3(1.0), vec3(0.0));
    c = max(c - vec3(1.0), vec3(0.0));
    d = max(d - vec3(1.0), vec3(0.0));
#endif
    gl_FragData[0] = vec4((a+b+c+d)*0.25, 1.0);
#else
    gl_FragData[0] = vec4(0.0);
#endif
}
