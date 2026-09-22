shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

// Tela de monitor CRT: scanlines, vinheta, ruído, queima de fósforo,
// e suporte a "interferência" (o sinal que às vezes não é o que parece).

uniform vec3 screen_color : source_color = vec3(0.20, 0.95, 0.72);
uniform vec3 screen_color_alt : source_color = vec3(0.95, 0.62, 0.20);
uniform float mix_alt = 0.0;
uniform float noise_amount = 0.08;
uniform float scanlines = 0.55;
uniform float flicker = 0.06;
uniform float glitch = 0.0;
uniform float lines = 24.0;
uniform float brightness = 1.2;
uniform float off = 0.0;

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

void fragment() {
	vec2 uv = UV;
	// instabilidade horizontal
	float g = glitch;
	if (g > 0.001) {
		float band = step(0.5, hash21(vec2(floor(uv.y * 40.0), floor(TIME * 12.0))));
		uv.x += (hash21(vec2(floor(TIME * 24.0), floor(uv.y * 60.0))) - 0.5) * 0.12 * band * g;
	}
	float rows = sin(uv.y * lines * 6.2831);
	float lines_mask = smoothstep(0.35, 0.9, rows * 0.5 + 0.5);
	float nib = smoothstep(0.0, 0.02, uv.x) * smoothstep(1.0, 0.98, uv.x)
			  * smoothstep(0.0, 0.03, uv.y) * smoothstep(1.0, 0.97, uv.y);
	vec3 tint = mix(screen_color, screen_color_alt, mix_alt);
	float scan = mix(1.0, 0.35 + 0.65 * lines_mask, scanlines * nib);
	float n = (hash21(uv * 512.0 + vec2(TIME * 60.0, TIME * 31.0)) - 0.5) * noise_amount;
	float fl = 1.0 - flicker * abs(sin(TIME * 7.3) * 0.5 + 0.5) + flicker * 0.5;
	float vig = 0.6 + 0.4 * (1.0 - length(uv - 0.5) * 1.5);
	float lit = (0.25 + 0.75 * nib) * (1.0 - off);
	vec3 col = tint * ((scan + n) * brightness * fl * vig) * lit;
	col += tint * 0.05 * hash21(vec2(floor(TIME * 3.0), 1.0)) * lit;
	ALBEDO = col * 0.04;
	EMISSION = col * (1.6 * (1.0 - off * 0.9));
	ROUGHNESS = 0.25;
}
