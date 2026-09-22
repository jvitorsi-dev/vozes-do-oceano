shader_type spatial;
render_mode unshaded, cull_front, depth_draw_never, fog_disabled, specular_disabled;

// Céu de ÍRIO: campo de estrelas procedural, nebulosa muito discreta,
// e o planeta gigante ao fundo (desenhado por mesh separado).

uniform float star_threshold = 0.9982;
uniform vec3 star_color : source_color = vec3(0.75, 0.85, 1.0);
uniform vec3 nebula_a : source_color = vec3(0.05, 0.09, 0.16);
uniform vec3 nebula_b : source_color = vec3(0.12, 0.07, 0.14);
uniform float nebula_strength = 0.35;

float hash13(vec3 p) {
	p = fract(p * 0.1031);
	p += dot(p, p.yzx + 33.33);
	return fract((p.x + p.y) * p.z);
}

float vnoise3(vec3 x) {
	vec3 i = floor(x);
	vec3 f = fract(x);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(hash13(i + vec3(0, 0, 0)), hash13(i + vec3(1, 0, 0)), f.x),
				   mix(hash13(i + vec3(0, 1, 0)), hash13(i + vec3(1, 1, 0)), f.x), f.y),
			   mix(mix(hash13(i + vec3(0, 0, 1)), hash13(i + vec3(1, 0, 1)), f.x),
				   mix(hash13(i + vec3(0, 1, 1)), hash13(i + vec3(1, 1, 1)), f.x), f.y), f.z);
}

void fragment() {
	vec3 dir = normalize((INV_VIEW_MATRIX * vec4(VERTEX, 0.0)).xyz);
	// estrelas: célula esférica grossa
	vec3 cell = floor(dir * 420.0);
	float h = hash13(cell);
	float star = smoothstep(star_threshold, 1.0, h);
	float bright = 0.35 + 0.65 * hash13(cell + 7.0);
	float twinkle = 0.75 + 0.25 * sin(TIME * (1.0 + h * 3.0) + h * 40.0);

	// nebulosa: ruído suave (sem blocos), escura e discreta
	float n1 = vnoise3(dir * 2.4 + vec3(11.0));
	float n2 = vnoise3(dir * 5.3 - vec3(4.0));
	float neb_mask = clamp(n1 * 1.3 - 0.35, 0.0, 1.0);
	vec3 neb = mix(nebula_a, nebula_b, clamp(n2, 0.0, 1.0)) * neb_mask * nebula_strength;

	vec3 col = neb + star_color * star * bright * twinkle * 2.2;
	ALBEDO = col;
	EMISSION = col;
}
