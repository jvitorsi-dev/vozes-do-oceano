shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

// Oceano de ÍRIO — ondulação orgânica que, conforme a "ressonância" sobe,
// passa a formar interferências regulares: grades, favos e anéis impossíveis.

uniform vec3 deep_color : source_color = vec3(0.004, 0.018, 0.032);
uniform vec3 shallow_color : source_color = vec3(0.035, 0.135, 0.175);
uniform vec3 glow_color : source_color = vec3(0.32, 0.78, 0.92);
uniform float wave_scale = 0.010;
uniform float wave_speed = 0.20;
uniform float amplitude = 0.7;
uniform float geometric = 0.45;
uniform float grid_scale = 0.075;
uniform float resonance = 0.0;
uniform float ripple_strength = 0.0;
uniform float ripple_age = 99.0;
uniform vec2 ripple_center = vec2(0.0);
uniform float ripple_speed = 26.0;
uniform float foam = 0.15;
uniform float rise = 0.0;
uniform float sun_dir_power = 1.0;

varying vec3 wpos;
varying float vheight;

float hash31(vec3 p) {
	p = fract(p * 0.3183099 + vec3(0.71, 0.113, 0.419));
	p *= 17.0;
	return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}

float vnoise(vec3 x) {
	vec3 i = floor(x);
	vec3 f = fract(x);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(hash31(i + vec3(0.0, 0.0, 0.0)), hash31(i + vec3(1.0, 0.0, 0.0)), f.x),
				   mix(hash31(i + vec3(0.0, 1.0, 0.0)), hash31(i + vec3(1.0, 1.0, 0.0)), f.x), f.y),
			   mix(mix(hash31(i + vec3(0.0, 0.0, 1.0)), hash31(i + vec3(1.0, 0.0, 1.0)), f.x),
				   mix(hash31(i + vec3(0.0, 1.0, 1.0)), hash31(i + vec3(1.0, 1.0, 1.0)), f.x), f.y), f.z);
}

float sea_height(vec2 p, float t) {
	float h = 0.0;
	h += (vnoise(vec3(p * wave_scale, t * 0.5)) * 2.0 - 1.0);
	h += (vnoise(vec3(p * wave_scale * 2.9, t * 1.1)) * 2.0 - 1.0) * 0.45;
	h += (vnoise(vec3(p * wave_scale * 8.3, t * 2.3)) * 2.0 - 1.0) * 0.16;
	h *= amplitude;

	// Interferência regular: a assinatura do fenômeno.
	float inter = 0.0;
	float gx = sin(p.x * grid_scale + t * 0.25);
	float gz = sin(p.y * grid_scale * 1.7320 + t * 0.19);
	inter = (gx * gz);
	inter += (sin(dot(p, vec2(0.014, 0.011)) * 6.2831 + t * 0.11) * 0.6);
	// espirais logarítmicas ocasionais
	float ang = atan(p.y, p.x);
	float rad = length(p);
	float spiral = sin(ang * 7.0 - log(max(rad, 1.0)) * 4.2 + t * 0.12);
	inter += spiral * smoothstep(400.0, 120.0, rad) * 0.9;
	h += inter * geometric * amplitude * 1.4;

	// Anel de resposta a um evento dentro da estação
	float d = distance(p, ripple_center);
	float front = ripple_speed * ripple_age;
	float ring = sin((d - front) * 0.16) * exp(-d * 0.0065) * exp(-ripple_age * 0.35);
	h += ring * ripple_strength * 3.2;
	return h;
}

void vertex() {
	vec3 wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float t = TIME * wave_speed;
	float h = sea_height(wp.xz, t);
	VERTEX.y += h + rise;

	// normais por diferença finita
	float e = 2.0;
	float hx = sea_height(wp.xz + vec2(e, 0.0), t);
	float hz = sea_height(wp.xz + vec2(0.0, e), t);
	// Os planos de mar são sempre horizontais e sem rotação, então a normal
	// local coincide com a normal do mundo.
	vec3 n = normalize(vec3(-(hx - h) / e, 1.0, -(hz - h) / e));
	NORMAL = n;

	wpos = wp;
	vheight = h;
}

void fragment() {
	float up = clamp(NORMAL.y, 0.0, 1.0);
	vec3 col = mix(shallow_color, deep_color, up);
	col = mix(col, glow_color * 0.5, clamp(resonance * 0.35, 0.0, 0.4));

	// espuma nas cristas
	float crest = smoothstep(amplitude * 0.55, amplitude * 1.15, vheight);
	col = mix(col, vec3(0.55, 0.72, 0.78) * 0.8, crest * foam);

	// anel luminoso da resposta
	float d = distance(wpos.xz, ripple_center);
	float front = ripple_speed * ripple_age;
	float ring = exp(-abs(d - front) * 0.05) * exp(-ripple_age * 0.5) * ripple_strength;
	col += glow_color * ring * 1.4;

	// brilho do horizonte: o mar de ÍRIO reflete luz por centenas de km
	float fres = pow(1.0 - up, 3.0);
	col += vec3(0.10, 0.26, 0.35) * fres * 0.75;
	// bioluminescência difusa das cristas (sempre presente, discreta)
	float bio = smoothstep(amplitude * 0.75, amplitude * 1.5, vheight);
	col += glow_color * bio * (0.06 + resonance * 0.30);

	ALBEDO = col;
	ROUGHNESS = mix(0.04, 0.4, crest);
	METALLIC = 0.35;
	SPECULAR = 1.0;
	EMISSION = glow_color * (0.035 + resonance * 0.30 + ring * 1.8 + bio * 0.22 + crest * foam * 0.10);
	AO = 1.0;
	AO_LIGHT_AFFECT = 1.0;
}
