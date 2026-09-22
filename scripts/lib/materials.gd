class_name Mats
extends RefCounted
## Biblioteca de materiais procedurais — nada de arquivos externos.
## Estética: metal industrial soviético gasto, plásticos amarelados,
## avisos pintados à mão, tudo sob luz fria.

static var _cache: Dictionary = {}


static func _noise_tex(scale: float, rough: float = 0.5, seed_v: int = 1) -> NoiseTexture2D:
	var n := FastNoiseLite.new()
	n.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	n.seed = seed_v
	n.frequency = scale
	n.fractal_octaves = 4
	var t := NoiseTexture2D.new()
	t.noise = n
	t.width = 256
	t.height = 256
	t.seamless = true
	return t


static func _stripes_tex(color_a: Color, color_b: Color, diag: bool = true) -> ImageTexture:
	var img := Image.create(64, 64, false, Image.FORMAT_RGB8)
	for y in 64:
		for x in 64:
			var v := (x + y) if diag else x
			var on := (int(v / 8.0) % 2) == 0
			img.set_pixel(x, y, color_a if on else color_b)
	return ImageTexture.create_from_image(img)


static func _grid_tex(base: Color, line: Color, cell: int = 8, thickness: int = 1) -> ImageTexture:
	var img := Image.create(64, 64, false, Image.FORMAT_RGB8)
	for y in 64:
		for x in 64:
			var edge := (x % cell) < thickness or (y % cell) < thickness
			img.set_pixel(x, y, line if edge else base)
	return ImageTexture.create_from_image(img)


static func _patchy_tex(base: Color, stain: Color, seed_v: int, amount: float = 0.45) -> ImageTexture:
	var img := Image.create(128, 128, false, Image.FORMAT_RGB8)
	var n := FastNoiseLite.new()
	n.seed = seed_v
	n.frequency = 0.035
	n.fractal_octaves = 5
	for y in 128:
		for x in 128:
			var v: float = n.get_noise_2d(x, y) * 0.5 + 0.5
			var t: float = clampf((v - (1.0 - amount)) / maxf(amount, 0.001), 0.0, 1.0)
			img.set_pixel(x, y, base.lerp(stain, t))
	return ImageTexture.create_from_image(img)


static func get_mat(key: String) -> StandardMaterial3D:
	if _cache.has(key):
		return _cache[key]
	var m := _make(key)
	_cache[key] = m
	return m


static func _make(key: String) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.roughness = 0.75
	m.metallic = 0.0
	mresselize(m)
	match key:
		"floor":
			m.albedo_color = Color(0.115, 0.125, 0.135)
			m.albedo_texture = _grid_tex(Color(0.115, 0.125, 0.135), Color(0.075, 0.082, 0.09), 12, 1)
			m.roughness = 0.72
			m.metallic = 0.25
			m.uv1_scale = Vector3(6, 6, 6)
		"floor_grating":
			m.albedo_color = Color(0.16, 0.17, 0.18)
			m.albedo_texture = _grid_tex(Color(0.17, 0.18, 0.19), Color(0.05, 0.055, 0.06), 6, 2)
			m.metallic = 0.5
			m.roughness = 0.55
			m.uv1_scale = Vector3(10, 10, 10)
		"wall":
			m.albedo_color = Color(0.40, 0.41, 0.40)
			m.albedo_texture = _patchy_tex(Color(0.46, 0.46, 0.44), Color(0.30, 0.28, 0.25), 7, 0.5)
			m.uv1_scale = Vector3(1.4, 1.4, 1.4)
			m.roughness = 0.82
		"wall_dark":
			m.albedo_color = Color(0.16, 0.17, 0.185)
			m.albedo_texture = _patchy_tex(Color(0.20, 0.21, 0.22), Color(0.10, 0.10, 0.11), 12, 0.5)
			m.metallic = 0.35
			m.roughness = 0.62
		"ceiling":
			m.albedo_color = Color(0.13, 0.14, 0.15)
			m.albedo_texture = _grid_tex(Color(0.16, 0.17, 0.18), Color(0.09, 0.095, 0.10), 16, 1)
			m.metallic = 0.3
			m.roughness = 0.7
		"metal":
			m.albedo_color = Color(0.30, 0.315, 0.33)
			m.metallic = 0.75
			m.roughness = 0.42
		"metal_rust":
			m.albedo_color = Color(0.30, 0.22, 0.16)
			m.albedo_texture = _patchy_tex(Color(0.33, 0.24, 0.17), Color(0.16, 0.10, 0.07), 21, 0.6)
			m.metallic = 0.5
			m.roughness = 0.85
			m.uv1_scale = Vector3(2, 2, 2)
		"rubber":
			m.albedo_color = Color(0.07, 0.07, 0.075)
			m.roughness = 0.92
			m.metallic = 0.0
		"hazard":
			m.albedo_texture = _stripes_tex(Color(0.78, 0.62, 0.10), Color(0.06, 0.06, 0.06))
			m.roughness = 0.8
			m.uv1_scale = Vector3(4, 4, 4)
		"paint_red":
			m.albedo_color = Color(0.42, 0.10, 0.08)
			m.roughness = 0.7
		"paint_blue":
			m.albedo_color = Color(0.10, 0.18, 0.30)
			m.roughness = 0.7
		"screen":
			m.albedo_color = Color(0.02, 0.05, 0.05)
			m.emission_enabled = true
			m.emission = Color(0.18, 0.85, 0.62)
			m.emission_energy_multiplier = 1.1
			m.roughness = 0.2
		"screen_amber":
			m.albedo_color = Color(0.05, 0.04, 0.02)
			m.emission_enabled = true
			m.emission = Color(1.0, 0.62, 0.18)
			m.emission_energy_multiplier = 1.2
		"glass":
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			m.albedo_color = Color(0.62, 0.78, 0.86, 0.10)
			m.roughness = 0.03
			m.metallic = 0.0
			m.cull_mode = BaseMaterial3D.CULL_DISABLED
			m.rim_enabled = true
			m.rim = 0.6
		"glass_scratch":
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			m.albedo_color = Color(0.55, 0.68, 0.74, 0.16)
			m.albedo_texture = _patchy_tex(Color(0.8, 0.85, 0.9), Color(0.35, 0.38, 0.4), 33, 0.5)
			m.roughness = 0.22
			m.cull_mode = BaseMaterial3D.CULL_DISABLED
		"lamp_cold":
			m.albedo_color = Color(0.75, 0.82, 0.88)
			m.emission_enabled = true
			m.emission = Color(0.72, 0.82, 0.95)
			m.emission_energy_multiplier = 2.2
			m.roughness = 0.3
		"lamp_emergency":
			m.albedo_color = Color(0.9, 0.25, 0.15)
			m.emission_enabled = true
			m.emission = Color(1.0, 0.22, 0.10)
			m.emission_energy_multiplier = 3.0
		"lamp_warm":
			m.albedo_color = Color(0.95, 0.78, 0.5)
			m.emission_enabled = true
			m.emission = Color(1.0, 0.72, 0.38)
			m.emission_energy_multiplier = 1.6
		"fabric":
			m.albedo_color = Color(0.22, 0.24, 0.28)
			m.roughness = 0.95
		"plant":
			m.albedo_color = Color(0.16, 0.30, 0.16)
			m.roughness = 0.85
		"bone":
			m.albedo_color = Color(0.55, 0.30, 0.28)
			m.roughness = 0.6
		"green_glow":
			m.albedo_color = Color(0.05, 0.1, 0.06)
			m.emission_enabled = true
			m.emission = Color(0.25, 0.85, 0.45)
			m.emission_energy_multiplier = 1.4
		"ocean_dark":
			m.albedo_color = Color(0.01, 0.03, 0.05)
			m.roughness = 0.1
			m.metallic = 0.2
		_:
			m.albedo_color = Color(0.5, 0.5, 0.5)
	return m


static func mresselize(m: StandardMaterial3D) -> void:
	# pequeno truque: os materiais ficam com aspecto levemente sujo
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC


static func emissive(color: Color, energy: float = 2.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.emission_enabled = true
	m.emission = color
	m.emission_energy_multiplier = energy
	m.roughness = 0.4
	return m


static func tinted_color(base: Color, roughness: float = 0.7) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = base
	m.roughness = roughness
	return m
