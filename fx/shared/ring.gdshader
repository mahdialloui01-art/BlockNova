// CC0 Hit & Impact sampler: expanding shockwave ring.
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled;
#include "res://fx/shared/common.gdshaderinc"
uniform vec4 color : source_color = vec4(1.0, 0.6, 0.25, 1.0);
uniform float thickness = 0.12;
uniform float start_radius = 0.15;
varying float age;
void vertex() {
    age = FX_AGE;
    FX_BILLBOARD
}
void fragment() {
    float r = length(UV * 2.0 - 1.0);
    float grow = 1.0 - pow(1.0 - age, 3.0);
    float radius = mix(start_radius, 0.95, grow);
    float w = thickness * (1.0 - age) + 0.01;
    float ring = 1.0 - smoothstep(0.0, w, abs(r - radius));
    ALBEDO = color.rgb;
    ALPHA = clamp(ring * (1.0 - age) * color.a, 0.0, 1.0) * FX_SOFT;
}
