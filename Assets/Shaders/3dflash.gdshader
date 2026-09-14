shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_opaque, depth_prepass_alpha;

uniform sampler2D tex : source_color, filter_nearest;
uniform vec4 flash_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float elapsed = 1000.0; // seconds since last hit, updated from script
uniform float flash_time = 0.02;
uniform float fade_time = 0.35;
uniform bool y_billboard = false;

void vertex() {
	vec3 model_scale = vec3(
		length(MODEL_MATRIX[0].xyz),
		length(MODEL_MATRIX[1].xyz),
		length(MODEL_MATRIX[2].xyz)
	);

	if (y_billboard) {
		MODELVIEW_MATRIX = VIEW_MATRIX * mat4(
			vec4(normalize(cross(vec3(0.0, 1.0, 0.0), INV_VIEW_MATRIX[2].xyz)) * model_scale.x, 0.0),
			vec4(0.0, 1.0, 0.0, 0.0) * model_scale.y,
			vec4(normalize(cross(INV_VIEW_MATRIX[0].xyz, vec3(0.0, 1.0, 0.0))) * model_scale.z, 0.0),
			MODEL_MATRIX[3]
		);
	} else {
		MODELVIEW_MATRIX = VIEW_MATRIX * mat4(
			INV_VIEW_MATRIX[0] * model_scale.x,
			INV_VIEW_MATRIX[1] * model_scale.y,
			INV_VIEW_MATRIX[2] * model_scale.z,
			MODEL_MATRIX[3]
		);
	}
	MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
}

void fragment() {
	vec4 col = texture(tex, UV);

	float strength = 0.0;
	if (elapsed < flash_time) {
		strength = 1.0;
	} else if (elapsed < flash_time + fade_time) {
		strength = 1.0 - (elapsed - flash_time) / fade_time;
	}

	ALBEDO = mix(col.rgb, flash_color.rgb, clamp(strength, 0.0, 1.0));
	ALPHA = col.a;
}