shader_type canvas_item;

uniform sampler2D overlay_tex: repeat_enable,filter_nearest;
uniform float scale = .1111;
varying vec2 worldPosition;

void vertex() {
	// Get world position
	worldPosition = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	float mixAmount = floor(COLOR.r);
	vec4 overlayColor = texture(overlay_tex, worldPosition * scale);
	COLOR = mix(COLOR, overlayColor, mixAmount);
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
