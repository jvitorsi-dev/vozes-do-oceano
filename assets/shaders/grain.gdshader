shader_type canvas_item;
render_mode unshaded, blend_mix;

// Camada de estresse: granulação de filme + vinheta + leve pulsação.
// Ativada por anomalias, proximidade de manifestações e pelo final.

uniform float amount = 0.0;
uniform float vignette = 0.0;
uniform float pulse = 0.0;
uniform vec3 tint : source_color = vec3(0.55, 0.72, 0.85);
uniform float aberration = 0.0;

float hash21(vec2 p) {
	p = fract(p * vec2(443.897, 441.423));
	p += dot(p, p + 19.19);
	return fract(p.x * p.y);
}

void fragment() {
	vec2 uv = SCREEN_UV;
	float n = hash21(floor(uv * vec2(900.0, 520.0)) + vec2(floor(TIME * 24.0), floor(TIME * 17.0)));
	float band = hash21(vec2(floor(uv.y * 220.0), floor(TIME * 9.0)));
	float granules = (n - 0.5) * (0.55 + 0.45 * band);
	float d = length((uv - 0.5) * vec2(1.0, 0.92)) * 1.42;
	float vig = smoothstep(0.35, 1.05, d);
	float breathe = 0.85 + 0.15 * sin(TIME * 1.9) * pulse;
	float alpha = clamp(amount * (abs(granules) * 1.4 + vig * 1.6 * (0.35 + vignette)) * breathe, 0.0, 0.75);
	vec3 col = mix(vec3(0.0), tint, clamp(vig * vignette + 0.15, 0.0, 1.0));
	COLOR = vec4(col, alpha);
}
