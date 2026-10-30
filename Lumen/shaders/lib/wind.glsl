// Shared by terrain and shadow passes, so foliage and its shadow move together.
vec3 applyWind(vec3 world, float material, float top, float time, float rain) {
    if (material < 100.5 || (material > 102.5 && material < 103.5) || material > 106.5) return world;
    time *= WIND_SPEED;
    float leaf = 1.0 - step(0.5, abs(material - 102.0));
    float hanging = 1.0 - step(0.5, abs(material - 104.0));
    float aquatic = step(104.5, material);
    float anchor = mix(top, 0.65, leaf);
    anchor = mix(anchor, 1.0 - top, hanging);
    anchor = mix(anchor, max(top, 0.35), aquatic);
    float strength = anchor * WIND_STRENGTH * mix(1.0 + rain * 0.6, 0.65, aquatic);
    float phase = dot(floor(world.xz), vec2(0.73, 1.17));
    float wave = sin(time * 1.2 + phase) * 0.045 + sin(time * 0.47 + world.x * 0.31 + world.z * 0.22) * 0.065;
    vec2 direction = mix(vec2(1.0,0.48), vec2(0.45,1.0), aquatic);
    world.xz += direction * wave * strength;
    return world;
}
