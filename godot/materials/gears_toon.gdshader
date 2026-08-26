shader_type spatial;
render_mode diffuse_toon, specular_disabled;

uniform vec4 base_color : source_color = vec4(0.51, 0.50, 0.45, 1.0);
uniform float roughness_value : hint_range(0.0, 1.0) = 0.82;
uniform vec4 emission_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float emission_energy : hint_range(0.0, 4.0) = 0.0;

void fragment() {
	ALBEDO = base_color.rgb;
	ROUGHNESS = roughness_value;
	METALLIC = 0.0;
	EMISSION = emission_color.rgb * emission_energy;
}
