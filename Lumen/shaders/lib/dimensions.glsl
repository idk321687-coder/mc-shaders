// Procedural dimension backgrounds; no external textures are required.
float dimensionHash(vec3 p) {
    return fract(sin(dot(p, vec3(37.1, 113.5, 57.7))) * 43758.5453);
}
vec3 dimensionSky(vec3 ray, float time) {
#ifdef LUMEN_NETHER
    float haze = pow(1.0 - abs(ray.y), 2.0);
    vec3 cell = floor(ray * 180.0 + vec3(0.0, -time * 0.08, 0.0));
    float ember = step(0.995, dimensionHash(cell)) * pow(max(0.0, 1.0-length(fract(ray*180.0+vec3(0.0,-time*0.08,0.0))-0.5)*2.0), 4.0);
    return vec3(0.07, 0.012, 0.008) + haze*vec3(0.12,0.025,0.009) + ember*vec3(0.6,0.12,0.02);
#else
    float band = pow(max(0.0, 1.0-abs(ray.y+0.18)), 6.0);
    float seed = dimensionHash(floor(ray*480.0));
    float stars = step(0.997, seed) * pow(max(0.0, 1.0-length(fract(ray*480.0)-0.5)*2.0), 3.0);
    return vec3(0.014,0.006,0.035) + band*vec3(0.025,0.009,0.052) + stars*vec3(0.45,0.32,0.65);
#endif
}
