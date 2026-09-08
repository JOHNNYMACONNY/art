shader_type spatial;
render_mode blend_add, depth_draw_never, cull_back, unshaded;

uniform vec4 pool_color : source_color = vec4(1.0, 0.88, 0.55, 1.0);
uniform float intensity : hint_range(0.0, 3.0) = 1.4;
uniform float falloff_power : hint_range(0.5, 4.0) = 2.0;

void fragment() {
	vec2 center = UV - vec2(0.5);
	float dist = length(center * 2.0);
	if (dist > 1.0) {
		discard;
	}
	float alpha = pow(clamp(1.0 - dist, 0.0, 1.0), falloff_power) * intensity;
	ALBEDO = pool_color.rgb;
	ALPHA = alpha;
}
