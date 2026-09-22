shader_type spatial;
render_mode unshaded, cull_back, depth_draw_opaque, fog_disabled;

// Planeta gigante ao fundo — silhueta com faixas suaves e limbo luminoso.

uniform vec3 band_a : source_color = vec3(0.16, 0.13, 0.11);
uniform vec3 band_b : source_color = vec3(0.28, 0.22, 0.17);
uniform vec3 rim_color : source_color = vec3(0.45, 0.30, 0.22);
uniform float bands = 9.0;
uniform float rim_power = 2.4;

varying vec3 vnorm;
varying vec3 vpos;

void vertex() {
	vnorm = normalize(NORMAL);
	vpos = VERTEX;
}

void fragment() {
	float band = sin(vnorm.y * bands * 3.14159) * 0.5 + 0.5;
	vec3 col = mix(band_a, band_b, band);
	float u = clamp(vpos.y * 1.2 + 0.5, 0.0, 1.0);
	col *= 0.75 + 0.5 * u;
	float rim = pow(1.0 - abs(vnorm.z), rim_power);
	col += rim_color * rim * 0.55;
	ALBEDO = col;
	EMISSION = col * 0.6;
}
