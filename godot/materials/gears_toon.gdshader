shader_type spatial;
render_mode diffuse_toon, specular_disabled, cull_disabled;

uniform vec4 base_color : source_color = vec4(0.51, 0.50, 0.45, 1.0);
uniform float roughness_value : hint_range(0.0, 1.0) = 0.82;
uniform vec4 emission_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float emission_energy : hint_range(0.0, 4.0) = 0.0;
uniform sampler2D albedo_texture : source_color, filter_linear_mipmap, hint_default_white;
uniform float surface_noise_strength : hint_range(0.0, 1.0) = 0.22;
uniform bool use_world_uv = false;
uniform vec2 uv_scale = vec2(1.0, 1.0);
uniform bool is_brick = false;
uniform bool is_pavement_tiles = false;
uniform bool is_cardboard = false;
uniform bool emission_use_albedo = false;

float hash(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float noise2d(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

void fragment() {
	vec3 world_pos = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec2 uv_coords = UV * uv_scale;
	
	if (use_world_uv) {
		vec3 world_norm = normalize((INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
		if (abs(world_norm.y) > 0.5) {
			uv_coords = world_pos.xz * uv_scale;
		} else if (abs(world_norm.x) > 0.5) {
			uv_coords = world_pos.zy * uv_scale;
		} else {
			uv_coords = world_pos.xy * uv_scale;
		}
	}
	
	vec4 tex = texture(albedo_texture, uv_coords);
	vec3 col = base_color.rgb * tex.rgb;
	
	// Micro-grit (asphalt grain / concrete aggregate)
	float n = noise2d(world_pos.xz * 14.0) * 0.7 + noise2d(world_pos.xz * 56.0) * 0.3;
	col *= (1.0 - (n - 0.5) * surface_noise_strength);
	
	// Procedural brick pattern for vertical masonry walls
	if (is_brick) {
		vec2 bpos = vec2(world_pos.z * 3.0, world_pos.y * 6.0);
		if (mod(floor(bpos.y), 2.0) > 0.5) {
			bpos.x += 0.5;
		}
		vec2 b_grid = abs(fract(bpos) - 0.5);
		float mortar = smoothstep(0.40, 0.48, max(b_grid.x, b_grid.y));
		col = mix(col, vec3(0.12, 0.11, 0.10), mortar * 0.65);
		float b_var = hash(floor(bpos));
		col *= 0.82 + 0.35 * b_var;
	}
	
	// Procedural pavement flagstone tile joints for sidewalks
	if (is_pavement_tiles) {
		vec2 tpos = world_pos.xz * 1.8;
		vec2 t_grid = abs(fract(tpos) - 0.5);
		float joint = smoothstep(0.42, 0.48, max(t_grid.x, t_grid.y));
		col = mix(col, col * 0.4, joint * 0.8);
		float tile_var = hash(floor(tpos));
		col *= 0.88 + 0.24 * tile_var;
	}
	
	// Cardboard corrugated weathering & edge wear
	if (is_cardboard) {
		float crg = sin(UV.y * 120.0) * 0.06;
		float c_edge = smoothstep(0.0, 0.08, UV.x) * smoothstep(1.0, 0.92, UV.x) *
		               smoothstep(0.0, 0.08, UV.y) * smoothstep(1.0, 0.92, UV.y);
		col = (col + crg) * (0.82 + 0.22 * c_edge);
	}

	ALBEDO = col;
	ROUGHNESS = roughness_value;
	METALLIC = 0.0;
	if (emission_use_albedo) {
		EMISSION = emission_color.rgb * emission_energy * tex.rgb;
	} else {
		EMISSION = emission_color.rgb * emission_energy;
	}
}
