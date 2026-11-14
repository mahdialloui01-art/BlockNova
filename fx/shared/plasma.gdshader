// CC0 Hit & Impact sampler: lumpy three-band plasma burst.
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;
#include "res://fx/shared/common.gdshaderinc"
uniform vec4 core : source_color = vec4(0.95, 1.0, 1.0, 1.0);
uniform vec4 body : source_color = vec4(0.2, 0.9, 1.0, 1.0);
uniform vec4 rim : source_color = vec4(0.1, 0.4, 1.0, 1.0);
uniform float lumpiness = 0.45;
varying float age;
varying float seed;
void vertex() {
    age = FX_AGE;
    seed = INSTANCE_CUSTOM.x * 5.0;
    FX_BILLBOARD_ROT(0.0)
}
void fragment() {
    vec2 p = UV * 2.0 - 1.0;
    float r = length(p);
    vec2 dir = p / max(r, 0.001);
    float pop = 1.0 - pow(1.0 - clamp(age * 8.0, 0.0, 1.0), 3.0);
    float size = mix(0.55, 1.0, pop) * (1.0 - 0.3 * smoothstep(0.3, 1.0, age));
    float lobes = fx_noise(dir * 2.3 + seed + age * 1.5) + 0.5 * fx_noise(dir * 5.0 - seed - age * 3.0);
    float radius = size * (0.92 - lumpiness + lumpiness * lobes / 1.5);
    float d = r / max(radius, 0.001);
    float holes = fx_fbm(p * 3.5 + seed * 3.0 + vec2(0.0, age));
    float alive = step(age * 1.25 - 0.2, holes * 0.7 + (1.0 - d) * 0.55);
    float aa = fwidth(d) * 1.5;
    vec3 col = mix(core.rgb, body.rgb, smoothstep(0.48 - aa, 0.48, d + (holes - 0.5) * 0.25));
    col = mix(col, rim.rgb, smoothstep(0.8 - aa, 0.8, d + (holes - 0.5) * 0.15));
    ALBEDO = mix(core.rgb, col, smoothstep(0.03, 0.1, age));
    ALPHA = (1.0 - smoothstep(1.0 - aa, 1.0, d)) * alive * FX_SOFT;
}
