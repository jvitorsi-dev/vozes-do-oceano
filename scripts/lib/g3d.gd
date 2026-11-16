class_name G3D
extends RefCounted
## G3D — utilidades de construção de geometria.
## Todas as paredes da estação passam por aqui: paredes com vãos (portas,
## janelas), pisos, tetos, tubulações, luminárias e vigas.

static var _id := 0


static func _name(prefix: String) -> String:
	_id += 1
	return "%s_%d" % [prefix, _id]


## Caixa com ou sem colisão.
## Prefixos que são estrutura (paredes, lajes, vidros, tampas falsas): ficam
## de aresta viva para emendarem sem fresta com a peça vizinha.
const SEM_CHANFRO := ["floor", "ceil", "wallseg", "vidro", "parede_falsa", "nucleo", "plataforma",
		"degrau", "faixa", "faixa_poco", "hazard", "portao", "chapa_soldada", "acesso"]

static func box(parent: Node3D, size: Vector3, pos: Vector3, mat: Material,
		solid: bool = true, rot: Vector3 = Vector3.ZERO, prefix: String = "box") -> Node3D:
	var n := MeshInstance3D.new()
	n.name = _name(prefix)
	n.mesh = _malha_caixa(size, prefix)
	n.material_override = mat
	n.position = pos
	n.rotation = rot
	parent.add_child(n)
	if solid:
		var body := StaticBody3D.new()
		var shape := CollisionShape3D.new()
		var bs := BoxShape3D.new()
		bs.size = size
		shape.shape = bs
		body.add_child(shape)
		n.add_child(body)
	return n


## Objetos (móveis, caixas, carcaças) ganham aresta chanfrada; tiras finas e
## estrutura continuam caixas simples — que o Batcher funde num lote só.
static func _malha_caixa(size: Vector3, prefix: String) -> Mesh:
	var menor := minf(size.x, minf(size.y, size.z))
	var maior := maxf(size.x, maxf(size.y, size.z))
	if menor >= 0.10 and maior <= 2.6 and not SEM_CHANFRO.has(prefix):
		# medidas arredondadas ao centímetro: peças quase iguais dividem a malha
		var q := Vector3(snappedf(size.x, 0.01), snappedf(size.y, 0.01), snappedf(size.z, 0.01))
		return MeshKit.caixa(q, clampf(menor * 0.09, 0.008, 0.028))
	var mesh := BoxMesh.new()
	mesh.size = size
	return mesh


## Colisor de caixa sem malha (para objetos cujo desenho é feito de várias peças).
static func colisor(parent: Node3D, size: Vector3, pos: Vector3, rot: Vector3 = Vector3.ZERO) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.position = pos
	body.rotation = rot
	var shape := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = size
	shape.shape = bs
	body.add_child(shape)
	parent.add_child(body)
	return body


## Instancia uma malha compartilhada do MeshKit.
static func peca(parent: Node3D, mesh: Mesh, pos: Vector3, mat: Material,
		rot: Vector3 = Vector3.ZERO, escala: Vector3 = Vector3.ONE, prefix: String = "peca") -> MeshInstance3D:
	var n := mesh_inst(parent, mesh, pos, mat, rot, prefix)
	n.scale = escala
	return n


static func mesh_inst(parent: Node3D, mesh: Mesh, pos: Vector3, mat: Material,
		rot: Vector3 = Vector3.ZERO, prefix: String = "mi") -> MeshInstance3D:
	var n := MeshInstance3D.new()
	n.name = _name(prefix)
	n.mesh = mesh
	n.material_override = mat
	n.position = pos
	n.rotation = rot
	parent.add_child(n)
	return n


static func cyl(parent: Node3D, radius: float, height: float, pos: Vector3, mat: Material,
		rot: Vector3 = Vector3.ZERO, solid: bool = false) -> Node3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	# peça grande não pode mostrar as facetas: mais lados conforme o raio
	mesh.radial_segments = 12 if radius < 0.4 else (24 if radius < 1.2 else 36)
	mesh.rings = 1
	var n := mesh_inst(parent, mesh, pos, mat, rot, "cyl")
	if solid:
		var body := StaticBody3D.new()
		var shape := CollisionShape3D.new()
		var cs := CylinderShape3D.new()
		cs.radius = radius
		cs.height = height
		shape.shape = cs
		body.add_child(shape)
		n.add_child(body)
	return n


static func sphere(parent: Node3D, radius: float, pos: Vector3, mat: Material,
		rings: int = 16, solid: bool = false) -> Node3D:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 24
	mesh.rings = rings
	var n := mesh_inst(parent, mesh, pos, mat, Vector3.ZERO, "sphere")
	if solid:
		var body := StaticBody3D.new()
		var shape := CollisionShape3D.new()
		var ss := SphereShape3D.new()
		ss.radius = radius
		shape.shape = ss
		body.add_child(shape)
		n.add_child(body)
	return n


## Piso retangular (eixo XZ) com colisão.
static func floor_slab(parent: Node3D, x1: float, z1: float, x2: float, z2: float,
		y: float, mat: Material, thick: float = 0.3) -> Node3D:
	var size := Vector3(absf(x2 - x1), thick, absf(z2 - z1))
	var pos := Vector3((x1 + x2) * 0.5, y - thick * 0.5, (z1 + z2) * 0.5)
	return box(parent, size, pos, mat, true, Vector3.ZERO, "floor")


static func ceiling_slab(parent: Node3D, x1: float, z1: float, x2: float, z2: float,
		y: float, mat: Material, thick: float = 0.25) -> Node3D:
	var size := Vector3(absf(x2 - x1), thick, absf(z2 - z1))
	var pos := Vector3((x1 + x2) * 0.5, y + thick * 0.5, (z1 + z2) * 0.5)
	return box(parent, size, pos, mat, true, Vector3.ZERO, "ceil")


## Parede ao longo de X (variação em Z fixa) ou de Z (X fixa).
## openings: [{ "at": float, "width": float, "height": float, "base": float }]
## "at" é medido a partir do início (x1 ou z1). Retorna o nó pai das partes.
static func wall(parent: Node3D, along_x: bool, a1: float, a2: float, fixed: float,
		y_base: float, height: float, mat: Material, thickness: float = 0.3,
		openings: Array = [], prefix: String = "wall") -> Node3D:
	var root := Node3D.new()
	root.name = _name(prefix)
	parent.add_child(root)
	var start := minf(a1, a2)
	var end := maxf(a1, a2)
	var segments: Array = []
	var cursor := start
	var ops := openings.duplicate()
	ops.sort_custom(func(p, q): return float(p["at"]) < float(q["at"]))
	for op: Dictionary in ops:
		var o_base: float = float(op.get("base", 0.0))
		var o_w: float = float(op["width"])
		var o_h: float = float(op["height"])
		var o_at: float = float(op["at"]) + start
		if o_at > cursor:
			segments.append({"from": cursor, "to": o_at, "y": y_base, "h": height})
		# peitoril (abaixo do vão)
		if o_base > 0.001:
			segments.append({"from": o_at, "to": o_at + o_w, "y": y_base, "h": o_base})
		# lintel (acima do vão)
		var top_of_hole := y_base + o_base + o_h
		var wall_top := y_base + height
		if wall_top - top_of_hole > 0.001:
			segments.append({"from": o_at, "to": o_at + o_w, "y": top_of_hole, "h": wall_top - top_of_hole})
		cursor = o_at + o_w
	if cursor < end:
		segments.append({"from": cursor, "to": end, "y": y_base, "h": height})
	for s: Dictionary in segments:
		var f: float = s["from"]
		var t: float = s["to"]
		var len_v: float = t - f
		if len_v < 0.02:
			continue
		var yb: float = s["y"]
		var hh: float = s["h"]
		var mid := (f + t) * 0.5
		var size := Vector3(len_v, hh, thickness) if along_x else Vector3(thickness, hh, len_v)
		var pos := Vector3(mid, yb + hh * 0.5, fixed) if along_x else Vector3(fixed, yb + hh * 0.5, mid)
		box(root, size, pos, mat, true, Vector3.ZERO, "wallseg")
	return root


## Moldura de porta + painéis deslizantes + colisão dinâmica.
static func door_frame(parent: Node3D, along_x: bool, center: Vector3, width: float,
		height: float, mat_frame: Material) -> Node3D:
	var g := Node3D.new()
	g.name = _name("doorframe")
	g.position = center
	parent.add_child(g)
	var t := 0.16
	var d := 0.42
	# batentes
	if along_x:
		box(g, Vector3(t, height + t, d), Vector3(-width * 0.5 - t * 0.5, (height + t) * 0.5, 0), mat_frame, true)
		box(g, Vector3(t, height + t, d), Vector3(width * 0.5 + t * 0.5, (height + t) * 0.5, 0), mat_frame, true)
		box(g, Vector3(width + t * 2.0, t, d), Vector3(0, height + t * 0.5, 0), mat_frame, true)
	else:
		box(g, Vector3(d, height + t, t), Vector3(0, (height + t) * 0.5, -width * 0.5 - t * 0.5), mat_frame, true)
		box(g, Vector3(d, height + t, t), Vector3(0, (height + t) * 0.5, width * 0.5 + t * 0.5), mat_frame, true)
		box(g, Vector3(d, t, width + t * 2.0), Vector3(0, height + t * 0.5, 0), mat_frame, true)
	return g


## Faixa de sinalização pintada (perigo) ao redor de um vão, estilo industrial.
static func hazard_stripe(parent: Node3D, along_x: bool, center: Vector3, width: float,
		height: float = 0.28) -> void:
	var size := Vector3(width + 0.5, height, 0.06) if along_x else Vector3(0.06, height, width + 0.5)
	box(parent, size, center + Vector3(0, height * 0.5 + 0.02, 0), Mats.get_mat("hazard"), false, Vector3.ZERO, "hazard")


## Luminária de teto: corpo metálico + tubo emissivo + luz real.
static func ceiling_lamp(parent: Node3D, pos: Vector3, along_x: bool, length: float = 1.6,
		light_energy: float = 0.7, color: Color = Color(0.72, 0.82, 0.98), emergency: bool = false) -> Dictionary:
	var g := Node3D.new()
	g.name = _name("lamp")
	g.position = pos
	parent.add_child(g)
	var body_size := Vector3(length, 0.12, 0.34) if along_x else Vector3(0.34, 0.12, length)
	box(g, body_size, Vector3.ZERO, Mats.get_mat("metal"), false, Vector3.ZERO, "lampbody")
	var tube_size := Vector3(length - 0.2, 0.06, 0.2) if along_x else Vector3(0.2, 0.06, length - 0.2)
	var tube_mat := Mats.get_mat("lamp_emergency") if emergency else Mats.get_mat("lamp_cold")
	var tube := box(g, tube_size, Vector3(0, -0.08, 0), tube_mat, false, Vector3.ZERO, "lamptube")
	var light := OmniLight3D.new()
	light.name = "Light"
	light.position = Vector3(0, -0.35, 0)
	light.light_energy = light_energy
	light.light_color = Color(1.0, 0.30, 0.20) if emergency else color
	# Alcance contido: com 14 m cada lâmpada banhava três salas e nada tinha
	# contraste (e cada parede somava dezenas de luzes). Com 10 m a luz cai
	# antes de chegar à sala vizinha: aparecem poças de luz e cantos escuros.
	light.omni_range = 10.0
	light.omni_attenuation = 1.25
	light.shadow_enabled = false
	light.light_specular = 0.6
	# longe da câmera a luz some aos poucos (só o desktop aproveita)
	light.distance_fade_enabled = true
	light.distance_fade_begin = 38.0
	light.distance_fade_length = 10.0
	light.distance_fade_shadow = 24.0
	g.add_child(light)
	return {"node": g, "light": light, "tube": tube}


## Tubulação aparente ao longo de um corredor (detalhe de chão/teto).
static func pipes(parent: Node3D, along_x: bool, from_v: float, to_v: float, fixed: float,
		y: float, count: int = 3, radius: float = 0.09, mat: Material = null) -> void:
	var m: Material = mat if mat != null else Mats.get_mat("pipe")
	for i in count:
		var off := float(i) * (radius * 2.6)
		var length := absf(to_v - from_v)
		var mid := (from_v + to_v) * 0.5
		if along_x:
			cyl(parent, radius, length, Vector3(mid, y - off, fixed), m, Vector3(0, 0, PI * 0.5), false)
		else:
			cyl(parent, radius, length, Vector3(fixed, y - off, mid), m, Vector3(PI * 0.5, 0, 0), false)


## Caixa de sinalização com texto (Label3D) — placas bilíngues PT/RUS falsas.
static func sign(parent: Node3D, text: String, pos: Vector3, rot_y: float,
		font_size: int = 48, color: Color = Color(0.82, 0.86, 0.88), width: float = 1.6) -> Label3D:
	var l := Label3D.new()
	l.name = _name("sign")
	l.text = text
	l.font_size = font_size
	l.pixel_size = 0.0022
	l.modulate = color
	l.outline_size = 6
	l.outline_modulate = Color(0.02, 0.02, 0.03, 0.8)
	l.position = pos
	l.rotation.y = rot_y
	l.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	l.no_depth_test = false
	l.shaded = true
	# verso espelhado: "LEITO 1" lido ao contrário por trás da cama.
	# Sem face traseira, o letreiro simplesmente some visto de trás.
	l.double_sided = false
	parent.add_child(l)
	return l


static func label3d(parent: Node3D, text: String, pos: Vector3, rot_y: float, size: float = 0.006,
		color: Color = Color(0.9, 0.75, 0.45)) -> Label3D:
	var l := Label3D.new()
	l.name = _name("label")
	l.text = text
	l.pixel_size = size
	l.font_size = 32
	l.modulate = color
	l.outline_size = 4
	l.outline_modulate = Color(0, 0, 0, 0.7)
	l.double_sided = false
	l.position = pos
	l.rotation.y = rot_y
	l.shaded = true
	parent.add_child(l)
	return l
