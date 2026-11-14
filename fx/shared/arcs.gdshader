// CC0 Hit & Impact sampler: flickering electric arcs.
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled;
#include "res://fx/shared/common.gdshaderinc"
uniform vec4 color : source_color = vec4(0.3, 0.85, 1.0, 1.0);
uniform float count = 9.0;
uniform float width = 0.02;
uniform float flicker = 7.0;
uniform float inner_radius = 0.25;
varying float age;
varying float seed;
float jag(float x, float s) {
    return mix(fx_hash(vec2(floor(x), s)), fx_hash(vec2(floor(x) + 1.0, s)), fract(x)) - 0.5;
}
void vertex() {
    age = FX_AGE;
    seed = floor(INSTANCE_CUSTOM.x * 10.0);
    FX_BILLBOARD
}
void fragment() {
    vec2 p = UV * 2.0 - 1.0;
    float r = length(p);
    float tick = floor(age * flicker);
    float n = (atan(p.y, p.x) / TAU + 0.5) * count;
    float id = floor(n);
    float s = id * 13.0 + tick * 7.0 + seed;
    float h = fx_hash(vec2(s, 2.0));
    float len = mix(0.55, 1.0, fx_hash(vec2(s, 5.0))) * mix(0.75, 1.0, min(age * 6.0, 1.0));
    float along = (r - inner_radius) / max(len - inner_radius, 0.001);
    float bend = (jag(r * 9.0, s) * 0.5 + jag(r * 23.0, s + 3.0) * 0.2) * smoothstep(0.0, 0.25, along);
    float lateral = abs(fract(n) - 0.5 + bend) * TAU / count * r;
    float inside = step(0.0, along) * step(along, 1.0) * step(0.35, h);
    float w = width * (1.0 - 0.6 * along);
    float line = 1.0 - smoothstep(w * 0.5, w, lateral);
    float halo = (1.0 - smoothstep(w, w * 5.0, lateral)) * 0.45;
    ALBEDO = mix(color.rgb, vec3(1.0), line);
    ALPHA = clamp((line + halo) * inside * (1.0 - age * age) * color.a, 0.0, 1.0) * FX_SOFT;
}
