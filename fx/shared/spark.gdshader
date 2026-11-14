// CC0 Hit & Impact sampler: velocity-stretched spark.
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled;
#include "res://fx/shared/common.gdshaderinc"
uniform vec4 hot : source_color = vec4(1.0, 0.95, 0.8, 1.0);
uniform vec4 cool : source_color = vec4(1.0, 0.45, 0.1, 1.0);
uniform float appear_at = 0.0;
varying float age;
void vertex() {
    FX_ALIGN_VELOCITY
    age = FX_AGE;
    VERTEX.y *= mix(1.0, 0.35, age);
}
void fragment() {
    vec2 p = UV * 2.0 - 1.0;
    float m = (1.0 - smoothstep(0.0, 1.0, abs(p.x))) * (1.0 - smoothstep(0.2, 1.0, abs(p.y)));
    ALBEDO = mix(hot.rgb, cool.rgb, smoothstep(0.0, 0.6, age));
    ALPHA = clamp(m * (1.0 - age) * 1.5, 0.0, 1.0) * step(appear_at, age) * FX_SOFT;
}
