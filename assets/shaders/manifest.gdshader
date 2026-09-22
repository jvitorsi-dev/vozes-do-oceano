shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled, diffuse_burley, specular_schlick_ggx;

// Manifestação: um corpo humano feito de água, luz e inconsistência.
// Nunca parece sólido de verdade — a superfície ondula, o interior é claro
// e as bordas brilham como oceano visto de perto.

uniform vec3 body_color : source_color = vec3(0.35, 0.62, 0.72);
uniform vec3 rim_color : source_color = vec3(0.55, 0.95, 1.0);
uniform float translucency = 0.55;
uniform float ripple = 1.0;
uniform float dissolve : hint_range(0.0, 1.0) = 0.0;
uniform float age = 0.0;

varying vec3 world_pos;
varying float inner;

float hash31(vec3 p) {
	p = fract(p * 0.3183099 + vec3(0.71, 0.113, 0.419));
	p *= 17.0;
	return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}

float vnoise(vec3 x) {
	vec3 i = floor(x);
	vec3 f = fract(x);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(hash31(i), hash31(i + vec3(1, 0, 0)), f.x),
				   mix(hash31(i + vec3(0, 1, 0)), hash31(i + vec3(1, 1, 0)), f.x), f.y),
			   mix(mix(hash31(i + vec3(0, 0, 1)), hash31(i + vec3(1, 0, 1)), f.x),
				   mix(hash31(i + vec3(0, 1, 1)), hash31(i + vec3(1, 1, 1)), f.x), f.y), f.z);
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float n = vnoise(world_pos * 7.0 + vec3(0.0, TIME * 0.6, 0.0));
	inner = n;
	// respiração e micro-ondulação da superfície
	float breathe = sin(TIME * 1.1) * 0.02;
	VERTEX += NORMAL * (n - 0.5) * 0.03 * ripple + vec3(0.0, breathe, 0.0);
}

void fragment() {
	float fres = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 2.2);
	float n2 = vnoise(world_pos * 14.0 + vec3(TIME * 0.9));
	vec3 col = mix(body_color, rim_color, fres);
	col += rim_color * (n2 - 0.5) * 0.25 * ripple;
	float alpha = clamp(translucency * (0.45 + fres * 1.2) + (n2 - 0.5) * 0.12, 0.0, 0.95);
	// dissolução: a água cai e o corpo perde a forma
	float dv = dissolve * 1.4;
	float mask = vnoise(world_pos * 5.0 + vec3(age * 3.0)) ;
	alpha *= smoothstep(dv - 0.25, dv + 0.35, mask + (1.0 - dissolve));
	ALBEDO = col * 0.35;
	EMISSION = col * (0.45 + fres * 0.7) * (1.0 - dissolve * 0.7);
	ROUGHNESS = 0.05;
	METALLIC = 0.0;
	ALPHA = alpha;
	ALPHA_SCISSOR_THRESHOLD = 0.05;
}
