// Shared helpers for every effect shader.
uniform sampler2D fx_depth : hint_depth_texture, filter_nearest, repeat_disable;
uniform float soft_distance = 0.4;
float fx_soft(float depth, vec2 screen_uv, mat4 inv_proj, float frag_view_z) {
#if CURRENT_RENDERER == RENDERER_COMPATIBILITY
    vec3 ndc = vec3(screen_uv, depth) * 2.0 - 1.0;
#else
    vec3 ndc = vec3(screen_uv * 2.0 - 1.0, depth);
#endif
    vec4 v = inv_proj * vec4(ndc, 1.0);
    return clamp((frag_view_z - v.z / v.w) / max(soft_distance, 0.001), 0.0, 1.0);
}
float fx_hash(vec2 p) {
    vec3 q = fract(vec3(p.xyx) * 0.1031);
    q += dot(q, q.yzx + 33.33);
    return fract((q.x + q.y) * q.z);
}
float fx_noise(vec2 p) {
    vec2 i = floor(p), f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    return mix(mix(fx_hash(i), fx_hash(i + vec2(1.0, 0.0)), f.x), mix(fx_hash(i + vec2(0.0, 1.0)), fx_hash(i + vec2(1.0, 1.0)), f.x), f.y);
}
float fx_fbm(vec2 p) {
    return fx_noise(p) * 0.5 + fx_noise(p * 2.03 + 17.0) * 0.3 + fx_noise(p * 4.1 + 43.0) * 0.2;
}
#define FX_AGE clamp(INSTANCE_CUSTOM.y / max(INSTANCE_CUSTOM.w, 0.001), 0.0, 1.0)
#define FX_SOFT fx_soft(texture(fx_depth, SCREEN_UV).r, SCREEN_UV, INV_PROJECTION_MATRIX, VERTEX.z)
#define FX_ALIGN_VELOCITY { \
    vec3 fx_cz = normalize(INV_VIEW_MATRIX[2].xyz); \
    vec3 fx_sv = MODEL_MATRIX[1].xyz - fx_cz * dot(fx_cz, MODEL_MATRIX[1].xyz); \
    vec3 fx_ay = length(fx_sv) > 1e-5 ? normalize(fx_sv) : normalize(INV_VIEW_MATRIX[1].xyz); \
    vec3 fx_ax = normalize(cross(fx_ay, fx_cz)); \
    mat4 fx_world = mat4(vec4(fx_ax * length(MODEL_MATRIX[0].xyz), 0.0), vec4(fx_ay * length(MODEL_MATRIX[1].xyz), 0.0), vec4(fx_cz * length(MODEL_MATRIX[2].xyz), 0.0), MODEL_MATRIX[3]); \
    MODELVIEW_MATRIX = VIEW_MATRIX * fx_world; \
    MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX); }
#define FX_BILLBOARD FX_BILLBOARD_ROT(INSTANCE_CUSTOM.x)
#define FX_BILLBOARD_ROT(fx_angle) { \
    float fx_c = cos(fx_angle), fx_s = sin(fx_angle); \
    vec3 fx_scale = vec3(length(MODEL_MATRIX[0].xyz), length(MODEL_MATRIX[1].xyz), length(MODEL_MATRIX[2].xyz)); \
    mat4 fx_world = mat4(normalize(INV_VIEW_MATRIX[0]), normalize(INV_VIEW_MATRIX[1]), normalize(INV_VIEW_MATRIX[2]), MODEL_MATRIX[3]); \
    fx_world = fx_world * mat4(vec4(fx_c, -fx_s, 0.0, 0.0), vec4(fx_s, fx_c, 0.0, 0.0), vec4(0.0, 0.0, 1.0, 0.0), vec4(0.0, 0.0, 0.0, 1.0)); \
    MODELVIEW_MATRIX = VIEW_MATRIX * fx_world * mat4(vec4(fx_scale.x, 0.0, 0.0, 0.0), vec4(0.0, fx_scale.y, 0.0, 0.0), vec4(0.0, 0.0, fx_scale.z, 0.0), vec4(0.0, 0.0, 0.0, 1.0)); \
    MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX); }
