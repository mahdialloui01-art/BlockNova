// CC0 Hit & Impact sampler: camera-facing energy flash.
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled;
#include "res://fx/shared/common.gdshaderinc"
uniform vec4 color : source_color = vec4(1.0, 0.8, 0.45, 1.0);
uniform float ray_count = 3.0;
uniform float core_size = 0.35;
varying float age;
void vertex() {
    age = FX_AGE;
    FX_BILLBOARD
}
void fragment() {
    vec2 p = UV * 2.0 - 1.0;
    float r = length(p);
    float a = atan(p.y, p.x);
    float size = mix(0.6, 1.0, sqrt(age));
    float fade = (1.0 - age) * (1.0 - age);
    float core = exp(-pow(r / (core_size * size), 2.0) * 2.0) * (1.0 - smoothstep(0.7, 1.0, r));
    float rays = pow(abs(cos(a * ray_count)), 40.0) * (1.0 - smoothstep(0.0, size, r)) * step(0.5, ray_count);
    ALBEDO = mix(color.rgb, vec3(1.0), core * 0.6);
    ALPHA = clamp((core + rays) * fade * color.a, 0.0, 1.0) * FX_SOFT;
}
