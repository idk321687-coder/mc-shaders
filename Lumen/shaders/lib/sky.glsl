uniform int moonPhase;
float skyHash(vec3 p) { return fract(sin(dot(p, vec3(127.1, 311.7, 74.7))) * 43758.5453); }
// SUN_SIZE=1 corresponds to an approximately 0.53-degree solar diameter.
float sunDiskMask(float sunDot) {
    float radius = 0.00465 * SUN_SIZE;
    float center = 1.0 - 0.5 * radius * radius;
    float edge = max(0.0000003, radius * radius * 0.045);
    return smoothstep(center-edge, center+edge, sunDot);
}
vec3 skyColor(vec3 ray, vec3 sunDir, float rain, float time) {
    float day = smoothstep(-0.12, 0.12, sunDir.y);
    float horizon = pow(1.0 - abs(ray.y), 3.0);
    vec3 daySky = mix(vec3(0.20, 0.43, 0.78), vec3(0.62, 0.76, 0.88), horizon);
    float dusk = (1.0 - smoothstep(0.0, 0.28, abs(sunDir.y))) * day;
    daySky += vec3(0.6, 0.23, 0.07) * horizon * dusk * pow(max(dot(ray, sunDir), 0.0), 3.0);
    vec3 nightSky = mix(vec3(0.008, 0.015, 0.045), vec3(0.035, 0.055, 0.09), horizon);
    vec3 color = mix(nightSky, daySky, day);
    float sunDot = max(dot(ray, sunDir), 0.0);
    vec3 moonDir = -sunDir;
    float moonDot = max(dot(ray, moonDir), 0.0);
    float sunDisc = sunDiskMask(sunDot);
    color += vec3(3.5, 2.8, 2.0) * sunDisc * day * (1.0-rain);
    // Local disk coordinates; the eight vanilla phase indices control the terminator.
    vec3 right = normalize(cross(moonDir, vec3(0.0, 0.0, 1.0)) + vec3(0.00001, 0.0, 0.0));
    vec3 up = normalize(cross(right, moonDir));
    vec2 disk = vec2(dot(ray,right), dot(ray,up)) / 0.00465;
    float diskR = length(disk);
    float moonDisc = 1.0 - smoothstep(0.93, 1.02, diskR);
    float phase = float(moonPhase) * 0.78539816;
    float z = sqrt(max(0.0, 1.0-dot(disk,disk)));
    float illuminated = smoothstep(-0.08, 0.08, z*cos(phase) + disk.x*sin(phase));
    float surface = 0.78 + 0.22*skyHash(floor(disk.xyx*55.0));
    color += vec3(0.6, 0.7, 0.9) * moonDisc * (0.04+illuminated*surface) * (1.0-day) * (1.0-rain);
    vec3 cell = floor(ray * 650.0);
    float starSeed = skyHash(cell);
    float star = step(0.9975, starSeed) * pow(max(0.0, 1.0-length(fract(ray*650.0)-0.5)*2.0), 3.0);
    color += vec3(0.75, 0.82, 1.0) * star * (0.6+0.4*sin(time*1.7+starSeed*900.0)) * (1.0-day) * (1.0-moonDisc) * (1.0-rain);
    // A warm, broad atmospheric corona around the brighter solar disk.
    color += vec3(0.65, 0.35, 0.16) * pow(sunDot, 128.0) * day * (1.0-rain) * 0.35;
    color += vec3(0.8, 0.55, 0.3) * pow(sunDot, 1200.0 / SUN_SIZE) * day * (1.0-rain) * 0.18;
    return mix(color, vec3(dot(color, vec3(0.299,0.587,0.114))) * 0.65, rain * 0.7);
}
