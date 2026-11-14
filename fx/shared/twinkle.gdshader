// CC0 Hit & Impact sampler: four-point sparkle.
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled;
#include "res://fx/shared/common.gdshaderinc"
uniform vec4 color : source_color = vec4(1.0, 0.9, 0.5, 1.0);
varying float age;
void vertex() {
    age = FX_AGE;
    float s = sin(age * PI) * (0.65 + 0.35 * sin(age * 25.0 + INSTANCE_CUSTOM.x * 9.0));
    VERTEX.xy *= max(s, 0.0);
    FX_BILLBOARD
}
void fragment() {
    vec2 p = UV * 2.0 - 1.0;
    float glint = (1.0 - smoothstep(0.0, 0.035, abs(p.x * p.y))) * (1.0 - smoothstep(0.5, 1.0, length(p)));
    float dot_ = 1.0 - smoothstep(0.1, 0.3, length(p));
    ALBEDO = mix(color.rgb, vec3(1.0), dot_);
    ALPHA = clamp(glint + dot_, 0.0, 1.0) * FX_SOFT;
}
