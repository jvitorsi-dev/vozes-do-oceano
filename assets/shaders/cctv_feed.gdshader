shader_type canvas_item;
render_mode unshaded;

// Feed de CCTV analógica: recebe a imagem de um SubViewport e aplica
// ruído, varredura, instabilidade, descoloração e vinheta.

uniform sampler2D feed : filter_linear, repeat_disable;
uniform float noise_amount = 0.14;
uniform float scanline_amount = 0.30;
uniform float glitch = 0.0;
uniform float vignette = 0.85;
uniform float desaturate = 0.55;
uniform float exposure = 1.2;
uniform float brightness_flash = 0.0;
uniform vec3 tint : source_color = vec3(0.78, 0.90, 0.82);

float hash21(vec2 p) {
	p = fract(p * vec2(443.897, 441.423));
	p += dot(p, p + 19.19);
	return fract(p.x * p.y);
}

void fragment() {
	vec2 uv = UV;
	float g = glitch;
	if (g > 0.001) {
		uv.x += (hash21(vec2(floor(uv.y * 90.0), floor(TIME * 20.0))) - 0.5) * 0.06 * g;
		uv.y += (hash21(vec2(floor(TIME * 8.0), 3.0)) - 0.5) * 0.03 * g;
		if (hash21(vec2(floor(TIME * 6.0), 1.0)) > 0.85) {
			uv.x = 1.0 - uv.x;
		}
	}
	vec3 col = texture(feed, uv).rgb + brightness_flash;
	float lum = dot(col, vec3(0.299, 0.587, 0.114));
	col = mix(col, vec3(lum), desaturate) * tint * exposure;
	float scan = 0.5 + 0.5 * sin(uv.y / max(SCREEN_PIXEL_SIZE.y, 0.0001) * 3.14159);
	col *= 1.0 - scanline_amount * scan;
	col += (hash21(uv * 900.0 + vec2(TIME * 90.0, TIME * 47.0)) - 0.5) * noise_amount;
	col += (hash21(vec2(floor(TIME * 3.0), 7.0)) - 0.5) * 0.12;
	float d = length(uv - 0.5) * 1.42;
	col *= mix(1.0, smoothstep(1.0, 0.15, d), vignette);
	COLOR = vec4(clamp(col, vec3(0.0), vec3(1.5)), 1.0);
}
