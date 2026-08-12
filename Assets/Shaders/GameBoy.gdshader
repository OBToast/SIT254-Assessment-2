shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

uniform vec4 shader_color : source_color = vec4(0.61, 0.74, 0.06, 1.0);
uniform int number_of_colors : hint_range(2, 32) = 4;

void fragment() {
	vec4 screen_color = texture(screen_texture, SCREEN_UV);

	float brightness = dot(
		screen_color.rgb,
		vec3(0.299, 0.587, 0.114)
	);

	float levels = float(number_of_colors);

	float level = floor(brightness * levels) / (levels - 1.0);

	level = min(level, 1.0);

	COLOR = vec4(shader_color.rgb * level, 1.0);
}