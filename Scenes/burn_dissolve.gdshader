shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled, unshaded;

uniform vec4 albedo : source_color = vec4(1.0);
uniform sampler2D texture_albedo : source_color;
uniform vec4 emission_color : source_color = vec4(1.0);
uniform float emission_amount : hint_range(0, 10) = 2.0;
uniform sampler2D dissolve_texture;
uniform float burn_size : hint_range(0, 2) = 0.1;
uniform float dissolve_amount : hint_range(0, 1) = 0.0;

void fragment() {
	vec4 albedo_tex = texture(texture_albedo, UV);
	ALBEDO = albedo.rgb * albedo_tex.rgb;

	float sample = texture(dissolve_texture, UV).r;

	// glowing edge at the dissolve boundary
	float emission_value = 1.0 - smoothstep(dissolve_amount, dissolve_amount + burn_size, sample);
	EMISSION = vec3(emission_value * emission_amount * emission_color.rgb);

	// dissolve cutout
	ALPHA = smoothstep(dissolve_amount, dissolve_amount + burn_size, sample) * albedo_tex.a;
}