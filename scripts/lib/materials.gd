class_name Mats
extends RefCounted
## Biblioteca de materiais procedurais — nada de arquivos externos.
##
## Cada material é gerado em três mapas a partir de um campo de altura:
##   • albedo  — cor, sujeira, ferrugem, respingos, riscos
##   • normal  — relevo (painéis rebaixados, rebites, barras, azulejos)
##   • ORM     — oclusão (R), rugosidade (G) e metalicidade (B)
##
## As superfícies grandes usam mapeamento TRIPLANAR em coordenadas de mundo:
## assim a densidade da textura é a mesma em qualquer parede, piso ou caixa,
## sem o esticamento que denunciava a geometria simples.
##
## Estética: metal industrial soviético gasto, tinta descascada, plásticos
## amarelados, azulejo frio, avisos pintados à mão — tudo sob luz fria.

const SIZE := 256          # resolução base das texturas
const SIZE_BIG := 256      # cobertura maior por repetição (densidade igual)

static var _cache: Dictionary = {}


# ================================================================ API PÚBLICA
static func get_mat(key: String) -> StandardMaterial3D:
	if _cache.has(key):
		return _cache[key]
	# variante "_local": mesmos mapas, mas o triplanar acompanha a PEÇA em vez
	# do mundo — para o que se move (folhas de porta, monta-carga), senão a
	# textura "escorre" pela superfície durante o movimento
	if key.ends_with("_local"):
		var copia := get_mat(key.trim_suffix("_local")).duplicate() as StandardMaterial3D
		copia.uv1_world_triplanar = false
		copia.uv2_world_triplanar = false
		_cache[key] = copia
		return copia
	var m := StandardMaterial3D.new()
	_build(key, m)
	_cache[key] = m
	return m


## Emissivo COMPARTILHADO: para decoração que nunca muda de estado (mostradores,
## LEDs de enfeite). Um material por cor/energia — assim as peças se aglutinam.
## Quem precisa mudar a cor em jogo (porta, LED de estado) usa `emissive()`.
static func emissive_c(color: Color, energy: float = 2.0) -> StandardMaterial3D:
	var k := "emis:%s:%.2f" % [color.to_html(false), energy]
	if _cache.has(k):
		return _cache[k]
	var m := emissive(color, energy)
	_cache[k] = m
	return m


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


static func mresselize(m: StandardMaterial3D) -> void:
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC


# ================================================================ RUÍDO
static func _noise(seed_v: int, freq: float, octaves: int = 4, gain := 0.5) -> FastNoiseLite:
	var n := FastNoiseLite.new()
	n.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	n.seed = seed_v
	n.frequency = freq
	n.fractal_octaves = octaves
	n.fractal_gain = gain
	return n


## Quanto do "metálico" declarado vale de fato. Metal puro só reflete o que há
## em volta — e dentro da estação em volta é escuro: piso de chapa, teto e
## tubos sumiam em preto, com qualquer luz. Chapa velha, pintada e encardida
## se comporta mais como superfície fosca com brilho; este ganho traz o
## conjunto para esse meio-termo sem mexer material por material.
const METAL_GANHO := 0.45
## Expoente da curva que clareia os albedos gerados (ver _albedo_img).
const CLAREAR := 0.62

## Ruído ladrilhável: mistura quatro amostras deslocadas de um período, de modo
## que a borda direita continua na esquerda (e a de baixo na de cima). Sem isto
## cada repetição da textura mostrava um degrau de mancha na emenda.
static func _nt(n: FastNoiseLite, x: float, y: float, per: float) -> float:
	var fx := x / per
	var fy := y / per
	var a := n.get_noise_2d(x, y)
	var b := n.get_noise_2d(x - per, y)
	var c := n.get_noise_2d(x, y - per)
	var d := n.get_noise_2d(x - per, y - per)
	return lerpf(lerpf(a, b, fx), lerpf(c, d, fx), fy)


# ================================================================ CAMPOS DE ALTURA
## Painel de aço rebitado: chapas rebaixadas por frisos, rebites nas bordas.
static func _h_panel(size: int, step: int, thick: int, rivets: bool, seed_v: int) -> PackedFloat32Array:
	var h := PackedFloat32Array()
	h.resize(size * size)
	var fine := _noise(seed_v, 0.09, 3)
	for y in size:
		for x in size:
			var i := y * size + x
			var v := 0.62 + fine.get_noise_2d(float(x), float(y)) * 0.055
			# frisos (rebaixo)
			var sx := x % step
			var sy := y % step
			if sx < thick or sy < thick:
				v -= 0.22
			# rebites: nos cruzamentos dos frisos e no meio das chapas
			if rivets:
				var rx := sx - thick - 6
				var ry := sy - thick - 6
				var d := sqrt(float(rx * rx + ry * ry))
				if d < 3.4:
					v += 0.34 * (1.0 - d / 3.4)
				elif d < 5.0:
					v -= 0.10
			h[i] = clampf(v, 0.0, 1.0)
	return h


## Grade de piso (grating): barras portantes cruzadas com vãos vazios.
static func _h_grating(size: int, step: int, bar: int, seed_v: int) -> PackedFloat32Array:
	var h := PackedFloat32Array()
	h.resize(size * size)
	var fine := _noise(seed_v, 0.12, 3)
	for y in size:
		for x in size:
			var i := y * size + x
			var bx := (x % step) < bar
			var by := (y % step) < bar
			# barras principais a cada 2 células (direção longa) — como grade real
			var principal := (int(y / step) % 2) == 0
			var v := 0.14 + fine.get_noise_2d(float(x), float(y)) * 0.05
			if by and (principal or bx):
				v = 0.95
			elif bx and not by:
				v = 0.55
			elif principal and bx:
				v = 0.95
			h[i] = clampf(v, 0.0, 1.0)
	return h


## Metal escovado: riscos longos, amassados suaves, remaches.
static func _h_brushed(size: int, seed_v: int, dents := true) -> PackedFloat32Array:
	var h := PackedFloat32Array()
	h.resize(size * size)
	# ruído esticado: alta frequência no eixo Y, baixa no eixo X → escovado
	var streak := _noise(seed_v, 0.5, 2)
	var broad := _noise(seed_v + 11, 0.02, 3)
	for y in size:
		for x in size:
			var i := y * size + x
			var v := 0.6 + streak.get_noise_2d(float(x) * 0.12, float(y) * 3.0) * 0.07
			v += broad.get_noise_2d(float(x), float(y)) * 0.06
			if dents and broad.get_noise_2d(float(x) * 1.7 + 40.0, float(y) * 1.7) > 0.42:
				v -= 0.10
			h[i] = clampf(v, 0.0, 1.0)
	return h


## Ferrugem sobre metal: manchas em relevo, escorrimentos verticais por baixo
## dos remaches, metal limpo aparecendo onde a casca caiu.
static func _h_rust(size: int, seed_v: int, amount: float) -> PackedFloat32Array:
	var base := _h_brushed(size, seed_v + 3, true)
	var mask := _rust_mask(size, seed_v, amount)
	for i in size * size:
		var t := mask[i]
		base[i] = clampf(base[i] - 0.10 * t + 0.13 * t * t, 0.0, 1.0)
	return base


## Máscara da ferrugem (0..1), contínua nas bordas da textura.
static func _rust_mask(size: int, seed_v: int, amount: float) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(size * size)
	var patch := _noise(seed_v, 0.035, 4)
	var vein := _noise(seed_v + 21, 0.13, 3)
	var per := float(size)
	for y in size:
		for x in size:
			var px := float(x)
			var py := float(y)
			var m: float = _nt(patch, px, py, per) * 0.5 + 0.5
			m += _nt(vein, px, py, per) * 0.18
			# escorrimento: colunas que "descem" a partir de pontos altos
			var col: float = vein.get_noise_2d(px * 2.2, 0.0) * (1.0 - px / per) \
					+ vein.get_noise_2d((px - per) * 2.2, 0.0) * (px / per)
			m += (col * 0.5 + 0.5) * 0.14
			out[y * size + x] = clampf((clampf(m, 0.0, 1.0) - (1.0 - amount)) / maxf(amount, 0.001), 0.0, 1.0)
	return out


## Azulejo frio de refeitório/enfermaria: junta rebaixada, cantos lascados.
static func _h_tile(size: int, step: int, seed_v: int) -> PackedFloat32Array:
	var h := PackedFloat32Array()
	h.resize(size * size)
	var fine := _noise(seed_v, 0.2, 3)
	var chip := _noise(seed_v + 5, 0.06, 3)
	for y in size:
		for x in size:
			var i := y * size + x
			var v := 0.72 + fine.get_noise_2d(float(x), float(y)) * 0.04
			var sx := x % step
			var sy := y % step
			if sx < 2 or sy < 2:
				v -= 0.30
			elif sx < 4 or sy < 4:
				v -= 0.06
			# lascado nas quinas
			if (sx < 7 or sx > step - 7) and (sy < 7 or sy > step - 7):
				if chip.get_noise_2d(float(x), float(y)) > 0.30:
					v -= 0.16
			h[i] = clampf(v, 0.0, 1.0)
	return h


## Teto técnico perfurado: placas com forro e furos de ventilação.
static func _h_perf(size: int, step: int, seed_v: int) -> PackedFloat32Array:
	var h := PackedFloat32Array()
	h.resize(size * size)
	var fine := _noise(seed_v, 0.15, 3)
	for y in size:
		for x in size:
			var i := y * size + x
			var v := 0.70 + fine.get_noise_2d(float(x), float(y)) * 0.05
			var lx := float(x % step) - step * 0.5
			var ly := float(y % step) - step * 0.5
			if absf(x % step - 1) < 2.0 or absf(y % step - 1) < 2.0:
				v -= 0.18
			if sqrt(lx * lx + ly * ly) < 3.2:
				v -= 0.55
			h[i] = clampf(v, 0.0, 1.0)
	return h


## Tecido: trama trançada com desgaste nos cantos.
static func _h_fabric(size: int, seed_v: int) -> PackedFloat32Array:
	var h := PackedFloat32Array()
	h.resize(size * size)
	var fine := _noise(seed_v, 0.4, 3)
	for y in size:
		for x in size:
			var i := y * size + x
			var weave := 0.5 + 0.5 * sin(float(x) * 1.55) * sin(float(y) * 1.55)
			var v := 0.45 + weave * 0.22 + fine.get_noise_2d(float(x), float(y)) * 0.08
			h[i] = clampf(v, 0.0, 1.0)
	return h


## Listras de perigo, com tinta lascada e sujeira nas bordas.
static func _h_hazard(size: int, seed_v: int) -> PackedFloat32Array:
	var h := PackedFloat32Array()
	h.resize(size * size)
	var chip := _noise(seed_v, 0.07, 4)
	for y in size:
		for x in size:
			var i := y * size + x
			var d: float = fmod(float(x) + float(y), 64.0)
			var v := 0.85 if d < 32.0 else 0.45
			var wear: float = chip.get_noise_2d(float(x), float(y))
			if wear > 0.25:
				v -= 0.25
			h[i] = clampf(v + chip.get_noise_2d(float(x) * 3.0, float(y) * 3.0) * 0.05, 0.0, 1.0)
	return h


# ================================================================ MAPAS
## Normal map por diferenças centrais do campo de altura.
static func _normal_img(h: PackedFloat32Array, size: int, strength := 1.6) -> ImageTexture:
	var img := Image.create(size, size, false, Image.FORMAT_RGB8)
	for y in size:
		for x in size:
			var xl := (x - 1 + size) % size
			var xr := (x + 1) % size
			var yt := (y - 1 + size) % size
			var yb := (y + 1) % size
			var dx := (h[y * size + xr] - h[y * size + xl]) * strength
			var dy := (h[yb * size + x] - h[yt * size + x]) * strength
			var n := Vector3(-dx, -dy, 1.0).normalized()
			img.set_pixel(x, y, Color(n.x * 0.5 + 0.5, n.y * 0.5 + 0.5, n.z * 0.5 + 0.5))
	img.generate_mipmaps(true)
	return ImageTexture.create_from_image(img)


## ORM: oclusão (R), rugosidade (G), metalicidade (B) — o padrão que o Godot usa.
static func _orm_img(h: PackedFloat32Array, size: int, rough: float, metal: float,
		rust: PackedFloat32Array = PackedFloat32Array()) -> ImageTexture:
	var img := Image.create(size, size, false, Image.FORMAT_RGB8)
	var has_rust := rust.size() == size * size
	for y in size:
		for x in size:
			var i := y * size + x
			var hv := h[i]
			var ao := clampf(0.55 + hv * 0.45, 0.0, 1.0)
			var r := clampf(rough + (0.5 - hv) * 0.22, 0.0, 1.0)
			var mt := clampf(metal * (0.35 + hv * 0.65), 0.0, 1.0)
			if has_rust:
				var t := rust[i]
				r = clampf(r + t * 0.35, 0.0, 1.0)
				mt = clampf(mt - t * metal * 0.75, 0.0, 1.0)
			img.set_pixel(x, y, Color(ao, r, mt))
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


## Albedo: cor base + manchas, ferrugem, sujeira acumulada, riscos claros.
static func _albedo_img(h: PackedFloat32Array, size: int, base: Color, seed_v: int,
		opts: Dictionary = {}) -> ImageTexture:
	var img := Image.create(size, size, false, Image.FORMAT_RGB8)
	var rust_col: Color = opts.get("rust", Color(0.30, 0.15, 0.075))
	var seam_dark: float = float(opts.get("seam_dark", 0.35))
	var grime: float = float(opts.get("grime", 0.22))
	var wear: float = float(opts.get("wear", 0.14))
	var stain: Color = opts.get("stain", base.darkened(0.45))
	var rust := opts.get("rust_mask", PackedFloat32Array()) as PackedFloat32Array
	var has_rust := rust.size() == size * size
	var listras := bool(opts.get("listras", false))
	var fine := _noise(seed_v + 31, 0.22, 3)
	var blotch := _noise(seed_v + 47, 0.03, 4)
	# onde a altura é baixa (rebaixo/junta) escurece; onde é alta, clareia
	for y in size:
		for x in size:
			var i := y * size + x
			var hv := h[i]
			var zone := clampf((hv - 0.45) * 2.6, -1.0, 1.0)
			var c := base
			c = c.lerp(stain, maxf(0.0, -zone) * seam_dark)
			c = c.lightened(maxf(0.0, zone) * wear)
			# variação fina de tom (desbotado/encardido)
			c = c.lightened(maxf(0.0, _nt(fine, float(x), float(y), float(size))) * 0.06)
			# manchas grandes de encardido
			var b: float = _nt(blotch, float(x), float(y), float(size)) * 0.5 + 0.5
			c = c.lerp(stain, b * grime)
			if has_rust:
				c = c.lerp(rust_col, clampf(rust[i] * 1.15, 0.0, 1.0))
			if listras and fmod(float(x) + float(y), 64.0) >= 32.0:
				c = c.lerp(Color(0.035, 0.035, 0.04), 0.90 - b * 0.25)
			# As cores-base foram escolhidas "no olho" em sRGB e ficaram escuras
			# demais: 0,20 em sRGB reflete 3% da luz — mais preto que carvão.
			# Por isso nenhuma lâmpada clareava piso, teto ou parede escura.
			# A curva traz tudo para a faixa de tinta/aço envelhecidos (10–25%).
			c = Color(pow(c.r, CLAREAR), pow(c.g, CLAREAR), pow(c.b, CLAREAR))
			img.set_pixel(x, y, c)
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


# ================================================================ CONSTRUÇÃO
## Gera os três mapas de um material a partir da configuração.
static func _maps(cfg: Dictionary) -> Dictionary:
	var size: int = int(cfg.get("size", SIZE))
	var pattern: String = String(cfg.get("pattern", "plain"))
	var seed_v: int = int(cfg.get("seed", 7))
	var h: PackedFloat32Array
	var rust := PackedFloat32Array()
	match pattern:
		"panel":
			h = _h_panel(size, int(cfg.get("step", 64)), int(cfg.get("thick", 3)),
					bool(cfg.get("rivets", true)), seed_v)
		"grating":
			h = _h_grating(size, int(cfg.get("step", 32)), int(cfg.get("bar", 5)), seed_v)
		"rust":
			rust = _rust_mask(size, seed_v, float(cfg.get("rust_amount", 0.5)))
			h = _h_rust(size, seed_v, float(cfg.get("rust_amount", 0.5)))
		"tile":
			h = _h_tile(size, int(cfg.get("step", 64)), seed_v)
		"perf":
			h = _h_perf(size, int(cfg.get("step", 32)), seed_v)
		"fabric":
			h = _h_fabric(size, seed_v)
		"hazard":
			h = _h_hazard(size, seed_v)
		_:
			h = _h_brushed(size, seed_v, bool(cfg.get("dents", false)))
	var opts := {
		"rust": cfg.get("rust_color", Color(0.30, 0.15, 0.075)),
		"seam_dark": cfg.get("seam_dark", 0.35),
		"grime": cfg.get("grime", 0.22),
		"wear": cfg.get("wear", 0.14),
		"stain": cfg.get("stain", Color(0, 0, 0)),
		"rust_mask": rust,
		"listras": pattern == "hazard",
	}
	var base: Color = cfg.get("base", Color(0.4, 0.4, 0.4))
	if !cfg.has("stain"):
		opts["stain"] = base.darkened(0.45)
	return {
		"albedo": _albedo_img(h, size, base, seed_v, opts),
		"normal": _normal_img(h, size, float(cfg.get("bump", 1.6))),
		"orm": _orm_img(h, size, float(cfg.get("rough", 0.8)), float(cfg.get("metal", 0.0)) * METAL_GANHO, rust),
	}


## Configuração de cada material do jogo.
static func _build(key: String, m: StandardMaterial3D) -> void:
	m.roughness = 0.8
	m.metallic = 0.0
	mresselize(m)
	# padrão: material liso (será sobrescrito nos casos texturizados)
	match key:
		"wall":
			# chapa de aço pintada de verde-acinzentado, painéis rebitados
			var cfg := {
				"pattern": "panel", "size": 288, "step": 96, "thick": 4, "rivets": true,
				"base": Color(0.365, 0.385, 0.360), "seed": 7, "rough": 0.78, "metal": 0.10,
				"grime": 0.26, "wear": 0.10, "bump": 1.5,
				"rust_color": Color(0.29, 0.16, 0.09),
			}
			_apply(m, cfg, 2.25, true)
		"wall_dark":
			var cfg2 := {
				"pattern": "panel", "size": SIZE_BIG, "step": 128, "thick": 5, "rivets": true,
				"base": Color(0.165, 0.180, 0.195), "seed": 12, "rough": 0.68, "metal": 0.32,
				"grime": 0.30, "wear": 0.12, "bump": 1.7,
				"rust_color": Color(0.26, 0.15, 0.09),
			}
			_apply(m, cfg2, 2.4, true)
		"floor":
			var cfg3 := {
				"pattern": "tile", "size": SIZE_BIG, "step": 128,
				"base": Color(0.150, 0.160, 0.170), "seed": 19, "rough": 0.62, "metal": 0.28,
				"grime": 0.32, "wear": 0.10, "bump": 1.9,
				"stain": Color(0.07, 0.075, 0.08),
			}
			_apply(m, cfg3, 1.6, true)
		"floor_grating":
			var cfg4 := {
				"pattern": "grating", "size": 288, "step": 48, "bar": 7,
				"base": Color(0.185, 0.195, 0.205), "seed": 23, "rough": 0.55, "metal": 0.62,
				"grime": 0.30, "wear": 0.14, "bump": 2.4,
				"stain": Color(0.05, 0.055, 0.06),
			}
			_apply(m, cfg4, 1.35, true)
		"ceiling":
			var cfg5 := {
				"pattern": "perf", "size": SIZE, "step": 64,
				# albedo 0,16 com metal 0,30 não refletia nem a luz ambiente:
				# longe das lâmpadas o teto era um preto só. Cinza claro e
				# quase sem metal devolve o forro à sala.
				"base": Color(0.30, 0.31, 0.325), "seed": 29, "rough": 0.78, "metal": 0.12,
				"grime": 0.34, "wear": 0.08, "bump": 1.8,
				"stain": Color(0.06, 0.065, 0.07),
			}
			_apply(m, cfg5, 2.0, true)
		"metal":
			var cfg6 := {
				"pattern": "brushed", "size": SIZE, "dents": true,
				"base": Color(0.315, 0.330, 0.345), "seed": 37, "rough": 0.38, "metal": 0.88,
				"grime": 0.16, "wear": 0.20, "bump": 1.2,
				"stain": Color(0.14, 0.145, 0.15),
			}
			_apply(m, cfg6, 1.0, true)
		"metal_rust":
			var cfg7 := {
				"pattern": "rust", "rust_amount": 0.48, "size": SIZE,
				"base": Color(0.285, 0.235, 0.185), "seed": 41, "rough": 0.86, "metal": 0.55,
				"grime": 0.28, "wear": 0.10, "bump": 1.7,
				"rust_color": Color(0.34, 0.16, 0.07),
				"stain": Color(0.11, 0.08, 0.055),
			}
			_apply(m, cfg7, 1.4, true)
		"pipe":
			var cfg8 := {
				"pattern": "brushed", "size": SIZE, "dents": false,
				"base": Color(0.245, 0.255 , 0.265), "seed": 53, "rough": 0.48, "metal": 0.78,
				"grime": 0.26, "wear": 0.14, "bump": 1.1,
				"stain": Color(0.10, 0.10, 0.11),
			}
			_apply(m, cfg8, 1.0, true)
		"rubber":
			var cfg9 := {
				"pattern": "fabric", "size": SIZE,
				"base": Color(0.085, 0.085, 0.090), "seed": 59, "rough": 0.93, "metal": 0.0,
				"grime": 0.20, "wear": 0.06, "bump": 0.9,
				"stain": Color(0.03, 0.03, 0.032),
			}
			_apply(m, cfg9, 0.5, true)
		"fabric":
			var cfg10 := {
				"pattern": "fabric", "size": SIZE,
				"base": Color(0.205, 0.220, 0.255), "seed": 61, "rough": 0.95, "metal": 0.0,
				"grime": 0.26, "wear": 0.16, "bump": 1.1,
				"stain": Color(0.08, 0.085, 0.10),
			}
			_apply(m, cfg10, 0.6, true)
		"hazard":
			var cfg11 := {
				"pattern": "hazard", "size": SIZE,
				"base": Color(0.78, 0.62, 0.10), "seed": 67, "rough": 0.74, "metal": 0.05,
				"grime": 0.30, "wear": 0.18, "bump": 1.3,
				"stain": Color(0.10, 0.085, 0.03),
			}
			_apply(m, cfg11, 0.8, true)
		"shelf_wood":
			var cfg12 := {
				"pattern": "fabric", "size": SIZE,
				"base": Color(0.30, 0.22, 0.15), "seed": 71, "rough": 0.90, "metal": 0.0,
				"grime": 0.30, "wear": 0.12, "bump": 0.8,
			}
			_apply(m, cfg12, 1.0, true)
		"paper":
			var cfg13 := {
				"pattern": "plain", "size": SIZE,
				"base": Color(0.72, 0.70, 0.64), "seed": 73, "rough": 0.92, "metal": 0.0,
				"grime": 0.30, "wear": 0.10, "bump": 0.5,
				"stain": Color(0.45, 0.42, 0.36),
			}
			_apply(m, cfg13, 1.0, true)
		"wall_blue":
			# cabines da tripulação: pintura azul institucional, gasta nos cantos
			var cb := {
				"pattern": "panel", "size": 224, "step": 112, "thick": 4, "rivets": false,
				"base": Color(0.205, 0.250, 0.330), "seed": 83, "rough": 0.74, "metal": 0.12,
				"grime": 0.30, "wear": 0.14, "bump": 1.4,
				"stain": Color(0.09, 0.11, 0.15),
			}
			_apply(m, cb, 1.925, true)
		"wall_rust":
			# depósito: chapa muito castigada, ferrugem velha escorrida
			var cr := {
				"pattern": "rust", "rust_amount": 0.62, "size": SIZE,
				"base": Color(0.275, 0.250, 0.215), "seed": 89, "rough": 0.88, "metal": 0.35,
				"grime": 0.34, "wear": 0.10, "bump": 1.7,
				"rust_color": Color(0.32, 0.155, 0.065),
				"stain": Color(0.10, 0.085, 0.065),
			}
			_apply(m, cr, 1.8, true)
		"tile_wall":
			# refeitório / enfermaria: azulejo esmaltado, encardido nas juntas
			var ct := {
				"pattern": "tile", "size": SIZE, "step": 64,
				"base": Color(0.720, 0.740, 0.715), "seed": 97, "rough": 0.30, "metal": 0.02,
				"grime": 0.34, "wear": 0.08, "bump": 1.5,
				"stain": Color(0.40, 0.40, 0.36),
			}
			_apply(m, ct, 1.6, true)
		"floor_plate":
			# piso de chapa estampada do hangar e da engenharia
			var cp := {
				"pattern": "panel", "size": 240, "step": 40, "thick": 5, "rivets": true,
				"base": Color(0.205, 0.215, 0.225), "seed": 101, "rough": 0.46, "metal": 0.62,
				"grime": 0.30, "wear": 0.16, "bump": 2.0,
				"stain": Color(0.075, 0.08, 0.085),
			}
			_apply(m, cp, 1.3125, true)
		"panel_green":
			# armários e consoles: verde-oliva militar
			var cg := {
				"pattern": "panel", "size": 288, "step": 96, "thick": 3, "rivets": true,
				"base": Color(0.225, 0.255, 0.205), "seed": 103, "rough": 0.70, "metal": 0.18,
				"grime": 0.28, "wear": 0.14, "bump": 1.5,
				"stain": Color(0.10, 0.12, 0.09),
			}
			_apply(m, cg, 1.8, true)
		"concrete":
			# concreto técnico: bases de máquina, soleiras, contrapiso
			var cc := {
				"pattern": "plain", "size": SIZE, "dents": true,
				"base": Color(0.36, 0.355, 0.34), "seed": 107, "rough": 0.93, "metal": 0.0,
				"grime": 0.36, "wear": 0.10, "bump": 1.6,
				"stain": Color(0.16, 0.155, 0.14),
			}
			_apply(m, cc, 1.7, true)
		"plastic_old":
			# plástico bege de equipamento, amarelado pelo tempo
			var cpl := {
				"pattern": "plain", "size": SIZE, "dents": false,
				"base": Color(0.56, 0.52, 0.40), "seed": 109, "rough": 0.55, "metal": 0.0,
				"grime": 0.30, "wear": 0.08, "bump": 0.45,
				"stain": Color(0.30, 0.25, 0.14),
			}
			_apply(m, cpl, 0.7, true)
		"plastic_dark":
			var cpd := {
				"pattern": "plain", "size": SIZE, "dents": false,
				"base": Color(0.075, 0.078, 0.082), "seed": 113, "rough": 0.50, "metal": 0.0,
				"grime": 0.22, "wear": 0.14, "bump": 0.45,
				"stain": Color(0.03, 0.03, 0.03),
			}
			_apply(m, cpd, 0.7, true)
		"oily":
			# aço de máquina encharcado de óleo: escuro, liso em manchas
			var co := {
				"pattern": "brushed", "size": SIZE, "dents": true,
				"base": Color(0.105, 0.100, 0.092), "seed": 127, "rough": 0.26, "metal": 0.72,
				"grime": 0.42, "wear": 0.22, "bump": 1.3,
				"stain": Color(0.02, 0.018, 0.014),
			}
			_apply(m, co, 0.9, true)
		"steel":
			# inox escovado de cozinha/laboratório: claro, pouco encardido
			var cs := {
				"pattern": "brushed", "size": SIZE, "dents": false,
				"base": Color(0.52, 0.54, 0.55), "seed": 131, "rough": 0.30, "metal": 0.92,
				"grime": 0.14, "wear": 0.18, "bump": 0.9,
				"stain": Color(0.24, 0.24, 0.23),
			}
			_apply(m, cs, 0.8, true)
		"ceramic":
			# cerâmica industrial miúda (bancadas molhadas, pias)
			var cce := {
				"pattern": "tile", "size": SIZE, "step": 32,
				"base": Color(0.60, 0.63, 0.60), "seed": 137, "rough": 0.22, "metal": 0.0,
				"grime": 0.36, "wear": 0.06, "bump": 1.4,
				"stain": Color(0.30, 0.29, 0.24),
			}
			_apply(m, cce, 0.8, true)
		"canvas":
			# lona de equipamento (capas, bolsas, cintas)
			var cl := {
				"pattern": "fabric", "size": SIZE,
				"base": Color(0.27, 0.285, 0.215), "seed": 139, "rough": 0.96, "metal": 0.0,
				"grime": 0.32, "wear": 0.18, "bump": 1.2,
				"stain": Color(0.11, 0.11, 0.08),
			}
			_apply(m, cl, 0.45, true)
		"paint_red":
			_flat_painted(m, Color(0.42, 0.10, 0.08), 77)
		"paint_yellow":
			_flat_painted(m, Color(0.62, 0.47, 0.08), 149, 0.08, 0.60, 0.30)
		"paint_olive":
			_flat_painted(m, Color(0.20, 0.235, 0.165), 151, 0.10, 0.66, 0.28)
		"paint_grey":
			_flat_painted(m, Color(0.34, 0.36, 0.37), 157, 0.12, 0.60, 0.26)
		"paint_white":
			_flat_painted(m, Color(0.66, 0.67, 0.64), 163, 0.03, 0.42, 0.30)
		"copper":
			_flat_painted(m, Color(0.46, 0.25, 0.14), 167, 0.85, 0.42, 0.34)
		"glass_wire":
			# vidro aramado de divisória: malha de arame embutida, bordas sujas
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			m.albedo_texture = _tex_vidro_aramado()
			m.roughness = 0.12
			m.metallic = 0.0
			m.cull_mode = BaseMaterial3D.CULL_DISABLED
			m.uv1_triplanar = true
			m.uv1_world_triplanar = true
			m.uv1_scale = Vector3(1.6, 1.6, 1.6)
		"paint_blue":
			_flat_painted(m, Color(0.10, 0.18, 0.30), 79)
		"plant":
			m.albedo_color = Color(0.16, 0.30, 0.16)
			m.roughness = 0.85
			m.metallic = 0.0
		"bone":
			m.albedo_color = Color(0.55, 0.30, 0.28)
			m.roughness = 0.6
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
			m.albedo_color = Color(0.55, 0.68, 0.74, 0.20)
			m.roughness = 0.24
			m.cull_mode = BaseMaterial3D.CULL_DISABLED
			m.rim_enabled = true
			m.rim = 0.4
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
			m.roughness = 0.25
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
			m.roughness = 0.8


static func _tex_vidro_aramado() -> ImageTexture:
	var size := 128
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var suj := _noise(173, 0.03, 3)
	for y in size:
		for x in size:
			var dx := absf(fmod(float(x) + float(y), 16.0) - 8.0)
			var dy := absf(fmod(float(x) - float(y) + 256.0, 16.0) - 8.0)
			var arame := 1.0 - clampf(minf(dx, dy) / 0.9, 0.0, 1.0)
			var s2: float = clampf(_nt(suj, float(x), float(y), float(size)) * 0.5 + 0.5, 0.0, 1.0)
			var a := 0.10 + s2 * 0.16 + arame * 0.62
			var c := Color(0.50, 0.62, 0.64).lerp(Color(0.08, 0.09, 0.09), arame)
			img.set_pixel(x, y, Color(c.r, c.g, c.b, clampf(a, 0.0, 1.0)))
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


## Material "pintado" simples, mas com tinta descascada e sujeira.
static func _flat_painted(m: StandardMaterial3D, base: Color, seed_v: int, metal := 0.05,
		rough := 0.62, grime := 0.22) -> void:
	var cfg := {
		"pattern": "brushed", "size": SIZE, "dents": false,
		"base": base, "seed": seed_v, "rough": rough, "metal": metal,
		"grime": grime, "wear": 0.16, "bump": 0.9,
		"stain": base.darkened(0.5),
	}
	_apply(m, cfg, 1.0, true)


## Mapa de variação em escala de metros (ladrilhável): zonas mais encardidas,
## escorridos longos, respingos. É multiplicado sobre QUALQUER material por um
## segundo triplanar bem maior que o da textura — quebra a repetição que
## denunciava o ladrilho de 1–2 m em toda parede.
static var _macro: ImageTexture = null

static func _macro_tex() -> ImageTexture:
	if _macro != null:
		return _macro
	var size := 256
	var per := float(size)
	var nuvem := _noise(911, 0.012, 4)
	var mancha := _noise(923, 0.045, 3)
	var risco := _noise(937, 0.09, 2)
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	for y in size:
		for x in size:
			var fx := float(x)
			var fy := float(y)
			var v: float = _nt(nuvem, fx, fy, per) * 0.5 + 0.5
			v = smoothstep(0.25, 0.80, v)
			var m: float = _nt(mancha, fx, fy, per) * 0.5 + 0.5
			m = smoothstep(0.55, 0.85, m)
			# escorridos verticais (estreitos em x, longos em y)
			var e: float = risco.get_noise_2d(fx * 3.0, 0.0) * (1.0 - fx / per) \
					+ risco.get_noise_2d((fx - per) * 3.0, 0.0) * (fx / per)
			e = smoothstep(0.28, 0.6, e) * (0.5 + 0.5 * v)
			var k := clampf(1.0 - v * 0.34 - m * 0.26 - e * 0.30, 0.25, 1.0)
			# o escuro puxa para marrom-óleo, não para cinza
			var c := Color(k, k * (0.94 + 0.06 * k), k * (0.86 + 0.14 * k), 0.5)
			img.set_pixel(x, y, c)
	img.generate_mipmaps()
	_macro = ImageTexture.create_from_image(img)
	return _macro


## Aplica os mapas gerados a um material.
## `world_m` = lado, em metros, que a textura cobre quando em triplanar.
static func _apply(m: StandardMaterial3D, cfg: Dictionary, world_m: float, triplanar: bool) -> void:
	var maps := _maps(cfg)
	m.albedo_texture = maps["albedo"]
	m.normal_enabled = true
	m.normal_texture = maps["normal"]
	m.normal_scale = float(cfg.get("bump", 1.4)) * 0.45
	m.orm_texture = maps["orm"]
	m.ao_enabled = true
	m.ao_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_RED
	m.ao_light_affect = 0.35
	m.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_GREEN
	m.metallic_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_BLUE
	m.roughness = 1.0
	m.metallic = 1.0
	m.albedo_color = Color.WHITE
	if triplanar:
		m.uv1_triplanar = true
		m.uv1_world_triplanar = true
		m.uv1_triplanar_sharpness = 5.0
		var d := 1.0 / maxf(world_m, 0.05)
		m.uv1_scale = Vector3(d, d, d)
		# variação em escala grande (não no navegador: lá cada amostra pesa)
		if not OS.has_feature("web") and bool(cfg.get("macro", true)):
			m.detail_enabled = true
			m.detail_blend_mode = BaseMaterial3D.BLEND_MODE_MUL
			m.detail_uv_layer = BaseMaterial3D.DETAIL_UV_2
			m.detail_albedo = _macro_tex()
			m.uv2_triplanar = true
			m.uv2_world_triplanar = true
			m.uv2_triplanar_sharpness = 5.0
			# período que não é múltiplo do ladrilho: as duas repetições nunca casam
			var dm := 1.0 / 7.3
			m.uv2_scale = Vector3(dm, dm, dm)
			# o detalhe mistura o relevo com "liso" na mesma proporção (alfa 0,5):
			# dobrar a escala devolve o relevo original
			m.normal_scale *= 2.0
	else:
		m.uv1_scale = Vector3(1, 1, 1)
	m.uv1_offset = Vector3.ZERO
