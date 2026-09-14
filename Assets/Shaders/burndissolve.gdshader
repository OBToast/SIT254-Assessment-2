shader_type spatial;
render_mode blend_mix, cull_disabled, unshaded;

uniform sampler2D texture_albedo : source_color;
uniform sampler2D dissolve_texture;
uniform float dissolve_amount : hint_range(0.0, 1.0, 0.01) = 0.0;

group_uniforms layer_1;
uniform vec4 layer_1 : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float size_1 = 0.1;

void fragment() {
	vec4 albedo_tex = texture(texture_albedo, UV);

	vec3 base_color = albedo_tex.rgb;
	float base_alpha = albedo_tex.a;

	float noise = texture(dissolve_texture, UV).r * (1.0 - (size_1 + 0.01));

	// dissolve_amount of 0 = fully intact, 1 = fully gone
	float percentage = 1.0 - dissolve_amount;

	float dissolve = step(percentage, noise);

	base_alpha *= 1.0 - dissolve;

	base_color = mix(
		base_color,
		layer_1.rgb,
		step(percentage, noise + size_1)
	);

	ALBEDO = base_color;
	ALPHA = base_alpha;
}