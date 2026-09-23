class_name Decals
extends RefCounted
## Decalques procedurais aplicados como nós `Decal` (Forward+).
##
## Manchas de óleo no piso, escorridos de ferrugem nas paredes, água infiltrada,
## riscos de arrasto, tinta gasta em volta de portas e placas de piso pintadas.
## É o tipo de sujeira que faz o lugar parecer *usado* — o detalhe que separa
## "sala 3D" de "estação onde alguém trabalhou por catorze anos".

static var _cache: Dictionary = {}


# ================================================================ IMAGENS
static func _noise(seed_v: int, freq: float, oct: int = 4) -> FastNoiseLite:
	var n := FastNoiseLite.new()
	n.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	n.seed = seed_v
	n.frequency = freq
	n.fractal_octaves = oct
	return n


## Mancha irregular (óleo, água, fluido) com borda corroída.
static func _blob(size: int, seed_v: int, edge: float, hard: bool) -> Image:
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var n := _noise(seed_v, 0.022, 4)
	var fine := _noise(seed_v + 9, 0.09, 3)
	for y in size:
		for x in size:
			var u := float(x) / float(size)
			var v := float(y) / float(size)
			var d := Vector2(u - 0.5, v - 0.5).length() * 2.0
			var warp: float = n.get_noise_2d(float(x), float(y)) * edge
			var a: float = 1.0 - clampf((d + warp - (1.0 - edge)) / maxf(edge * 0.9, 0.001), 0.0, 1.0)
			if hard:
				a = 1.0 if a > 0.55 else 0.0
			# núcleo mais escuro, bordas mais finas
			a *= 0.75 + 0.25 * (fine.get_noise_2d(float(x) * 2.0, float(y) * 2.0) * 0.5 + 0.5)
			img.set_pixel(x, y, Color(1, 1, 1, clampf(a, 0.0, 1.0)))
	return img


## Escorrido vertical: gotas que descem a partir do topo, engrossando no fim.
static func _streak(size: int, seed_v: int) -> Image:
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var col := _noise(seed_v, 0.05, 3)
	var fine := _noise(seed_v + 17, 0.14, 3)
	for y in size:
		for x in size:
			var v := float(y) / float(size)
			# "dedos" verticais: cada coluna tem seu próprio comprimento
			var reach: float = col.get_noise_2d(float(x) * 0.6, 40.0) * 0.5 + 0.5
			reach = 0.28 + reach * 0.72
			var a: float = 1.0 - clampf((v - reach * 0.15) / maxf(reach * 0.85, 0.001), 0.0, 1.0)
			a *= 0.55 + 0.45 * (fine.get_noise_2d(float(x), float(y)) * 0.5 + 0.5)
			# topo sempre marcado (é de onde escorreu)
			if v < 0.06:
				a = 1.0
			img.set_pixel(x, y, Color(1, 1, 1, clampf(a, 0.0, 1.0)))
	return img


## Riscos: arranhões longos e finos em várias direções (arrasto de caixa, botas).
static func _scuffs(size: int, seed_v: int, count: int) -> Image:
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_v
	for i in count:
		var x0 := rng.randf() * size
		var y0 := rng.randf() * size
		var ang := rng.randf() * TAU
		var comp := rng.randf_range(0.25, 0.9) * size
		var w := rng.randf_range(0.6, 2.2)
		var steps := int(comp)
		for s in steps:
			var t := float(s) / float(maxf(steps - 1, 1))
			var px := x0 + cos(ang) * comp * t
			var py := y0 + sin(ang) * comp * t
			# leve curvatura
			px += sin(t * 6.0) * 3.0
			py += cos(t * 5.0) * 2.0
			for oy in range(-int(w), int(w) + 1):
				var ix := int(px)
				var iy := int(py) + oy
				if ix < 0 or iy < 0 or ix >= size or iy >= size:
					continue
				var fade: float = 1.0 - absf(float(oy)) / maxf(w, 0.6)
				var a: float = clampf(fade * (0.35 + 0.45 * (1.0 - t)), 0.0, 1.0)
				var cur := img.get_pixel(ix, iy)
				img.set_pixel(ix, iy, Color(1, 1, 1, maxf(cur.a, a)))
	return img


## Tinta gasta em volta de uma marca (o padrão de desgaste de quem anda por cima).
static func _walkwear(size: int, seed_v: int) -> Image:
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var n := _noise(seed_v, 0.035, 4)
	var fine := _noise(seed_v + 5, 0.16, 3)
	for y in size:
		for x in size:
			var u := float(x) / float(size)
			var v := float(y) / float(size)
			# duas faixas de pegadas na diagonal
			var d1 := absf((u - v) * 0.7)
			var d2 := absf((u + v - 1.0) * 0.7)
			var lane: float = minf(d1, d2)
			var a: float = clampf(1.0 - lane * 6.0, 0.0, 1.0)
			a *= 0.45 + 0.55 * (n.get_noise_2d(float(x), float(y)) * 0.5 + 0.5)
			a *= 0.6 + 0.4 * (fine.get_noise_2d(float(x) * 1.5, float(y) * 1.5) * 0.5 + 0.5)
			img.set_pixel(x, y, Color(1, 1, 1, clampf(a * 0.75, 0.0, 1.0)))
	return img


## Estêncil: seta de circulação / triângulo de perigo / número de setor.
static func _stencil(size: int, kind: String, seed_v: int) -> Image:
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_v
	var w := float(size)
	match kind:
		"arrow":
			# seta grossa apontando +x, com haste
			for y in size:
				for x in size:
					var u := float(x) / w
					var v := float(y) / w
					var a := 0.0
					# haste
					if u > 0.08 and u < 0.62 and absf(v - 0.5) < 0.13:
						a = 1.0
					# ponta
					if u >= 0.55 and u < 0.92:
						var t: float = (u - 0.55) / 0.37
						if absf(v - 0.5) < 0.30 * (1.0 - t) + 0.02:
							a = 1.0
					if a > 0.0:
						img.set_pixel(x, y, Color(1, 1, 1, a))
		"triangle":
			for y in size:
				for x in size:
					var u := float(x) / w
					var v := float(y) / w
					# triângulo de perigo com borda dupla
					var dentro := (v > 0.12) and (v < 0.88) and (absf(u - 0.5) < (v - 0.12) * 0.62)
					var interno := (v > 0.28) and (absf(u - 0.5) < (v - 0.28) * 0.52)
					if dentro and not interno:
						img.set_pixel(x, y, Color(1, 1, 1, 1.0))
					elif v > 0.42 and v < 0.62 and absf(u - 0.5) < 0.035:
						img.set_pixel(x, y, Color(1, 1, 1, 1.0))
					elif v > 0.66 and v < 0.76 and absf(u - 0.5) < 0.035:
						img.set_pixel(x, y, Color(1, 1, 1, 1.0))
		"stripes":
			for y in size:
				for x in size:
					var d: float = fmod(float(x) + float(y), 48.0)
					if d < 22.0:
						img.set_pixel(x, y, Color(1, 1, 1, 1.0))
		"hazard_frame":
			for y in size:
				for x in size:
					var edge: float = minf(minf(float(x), float(y)), minf(float(size - 1 - x), float(size - 1 - y)))
					if edge < 6.0:
						var d: float = fmod(float(x) + float(y), 24.0)
						if d < 11.0:
							img.set_pixel(x, y, Color(1, 1, 1, 0.95))
	return img


# ================================================================ DECAL NODE
## Cria um decal prateado (stains etc.) já pronto para pendurar no mundo.
static func make(kind: String, size_xz: Vector2, pos: Vector3, rot_y: float = 0.0,
		vertical := false, tint := Color.WHITE, emissive := false, seed_v := 3) -> Decal:
	if OS.has_feature("web"):
		return null   # Decal não existe no renderizador de compatibilidade
	var d := Decal.new()
	var img: Image
	var key := "%s_%d" % [kind, seed_v]
	if _cache.has(key):
		img = _cache[key]
	else:
		match kind:
			"oil":
				img = _blob(256, seed_v, 0.55, false)
			"water":
				img = _blob(256, seed_v + 3, 0.75, false)
			"residue":
				img = _blob(256, seed_v + 7, 0.85, false)
			"streak":
				img = _streak(256, seed_v)
			"scuff":
				img = _scuffs(256, seed_v + 11, 26)
			"wear":
				img = _walkwear(256, seed_v + 13)
			"arrow":
				img = _stencil(256, "arrow", seed_v)
			"triangle":
				img = _stencil(256, "triangle", seed_v)
			"stripes":
				img = _stencil(256, "stripes", seed_v)
			"frame":
				img = _stencil(256, "hazard_frame", seed_v)
			_:
				img = _blob(256, seed_v, 0.6, false)
		_cache[key] = img
	var tex := ImageTexture.create_from_image(img)
	d.texture_albedo = tex
	d.albedo_mix = 1.0
	d.modulate = tint
	if emissive:
		d.texture_emission = tex
		d.emission_energy = 0.8
	d.position = pos
	d.rotation.y = rot_y
	if vertical:
		# parede: o decal projetado precisa ficar perpendicular ao plano
		d.rotation_degrees.x = 90.0
		d.size = Vector3(size_xz.x, size_xz.y * 1.6, 1.2)
	else:
		d.size = Vector3(size_xz.x, 1.6, size_xz.y)
	d.upper_fade = 0.35
	d.lower_fade = 0.25
	d.distance_fade_enabled = true
	d.distance_fade_begin = 22.0
	d.distance_fade_length = 10.0
	return d


## Sujeira padrão de um piso: manchas, arrasto e desgaste de passagem.
static func dress_floor(parent: Node3D, x1: float, z1: float, x2: float, z2: float, y: float,
		amount := 6, seed_v := 1, walk_lane := true) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_v
	for i in amount:
		var px := rng.randf_range(x1 + 1.0, x2 - 1.0)
		var pz := rng.randf_range(z1 + 1.0, z2 - 1.0)
		var r := rng.randf_range(1.0, 2.6)
		var tipo := "oil" if rng.randf() < 0.45 else ("water" if rng.randf() < 0.5 else "residue")
		var escuro := rng.randf_range(0.45, 0.85)
		var d := make(tipo, Vector2(r, r), Vector3(px, y + 0.03, pz), rng.randf() * TAU,
				false, Color(0.02, 0.022, 0.025, escuro), false, seed_v + i)
		parent.add_child(d)
	if walk_lane:
		var cx := (x1 + x2) * 0.5
		var cz := (z1 + z2) * 0.5
		var w := make("wear", Vector2(3.2, 3.2), Vector3(cx, y + 0.035, cz), 0.0,
				false, Color(0.03, 0.03, 0.035, 0.5), false, seed_v + 31)
		parent.add_child(w)


## Sujeira padrão de uma parede: escorridos a partir dos cantos e riscos.
static func dress_wall(parent: Node3D, pos: Vector3, rot_y: float, width: float, height: float,
		seed_v := 2) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_v
	var b := Basis(Vector3.UP, rot_y)
	# escorridos: nascem no alto e descem
	var n := int(clampf(width / 3.5, 1.0, 4.0))
	for i in n:
		var off := (float(i) - float(n - 1) * 0.5) * (width / maxf(float(n), 1.0)) * 0.8
		var p: Vector3 = pos + b * Vector3(off, height * 0.5, 0.06)
		var h := rng.randf_range(1.4, minf(height * 0.95, 3.4))
		var d := make("streak", Vector2(1.1, h), p, rot_y, true,
				Color(0.20, 0.10, 0.05, rng.randf_range(0.35, 0.7)), false, seed_v + i * 7)
		parent.add_child(d)
	# riscos de arrasto na altura dos carrinhos
	if rng.randf() < 0.7:
		var pr: Vector3 = pos + b * Vector3(rng.randf_range(-width * 0.3, width * 0.3), -height * 0.25, 0.05)
		var s := make("scuff", Vector2(2.0, 1.4), pr, rot_y, true,
				Color(0.55, 0.55, 0.55, 0.30), false, seed_v + 41)
		parent.add_child(s)


## Marca de piso pintada (faixa de circulação, quadro de carga, seta).
static func floor_mark(parent: Node3D, kind: String, pos: Vector3, rot_y: float,
		size_v: Vector2, color := Color(0.85, 0.70, 0.15, 0.55)) -> void:
	var d := make(kind, size_v, pos, rot_y, false, color, false, 5)
	parent.add_child(d)
