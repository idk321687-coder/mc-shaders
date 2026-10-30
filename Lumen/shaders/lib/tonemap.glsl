// Compact AgX-style display transform; inputs are treated as approximately linear.
vec3 agxToneMap(vec3 color) {
    const mat3 inset = mat3(
        0.842479, 0.042328, 0.042375,
        0.078433, 0.878468, 0.078433,
        0.079223, 0.079166, 0.879142);
    const mat3 outset = mat3(
        1.196879, -0.052896, -0.052971,
        -0.098020, 1.151903, -0.098043,
        -0.099029, -0.098961, 1.151073);
    vec3 x = inset * max(color, vec3(0.0));
    x = clamp((log2(max(x, vec3(1e-6))) + 12.47393) / 16.5, 0.0, 1.0);
    vec3 x2 = x*x;
    vec3 x4 = x2*x2;
    x = 15.5*x4*x2 - 40.14*x4*x + 31.96*x4 - 6.868*x2*x + 0.4298*x2 + 0.1191*x - 0.00232;
    return clamp(pow(max(outset * x, vec3(0.0)), vec3(2.2)), 0.0, 1.0);
}
