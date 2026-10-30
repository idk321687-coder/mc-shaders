// Deterministic world-space water detail, shared across water-related passes.
float waterHash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}
float waterNoise(vec2 p) {
    vec2 cell = floor(p);
    vec2 f = fract(p);
    vec2 w = f*f*(3.0-2.0*f);
    return mix(mix(waterHash(cell), waterHash(cell+vec2(1.0,0.0)), w.x),
               mix(waterHash(cell+vec2(0.0,1.0)), waterHash(cell+vec2(1.0,1.0)), w.x), w.y);
}
// Smooth, moving multi-scale surface; gradients of this height shape the normal.
float waterHeight(vec2 p, float t) {
    vec2 warp = vec2(waterNoise(p*0.13+vec2(t*0.025,0.0)),
                     waterNoise(p*0.13+vec2(7.1,-t*0.021))) - 0.5;
    p += warp * 1.6;
    float swell = sin(dot(p, vec2(0.34,0.18)) + t*0.52)*0.17;
    swell += sin(dot(p, vec2(-0.22,0.41)) - t*0.37)*0.11;
    float ripples = waterNoise(p*0.75 + vec2(t*0.12,-t*0.08));
    ripples += waterNoise(p*1.17 + vec2(-t*0.08,t*0.11))*0.45;
    return swell + ripples*0.12;
}
