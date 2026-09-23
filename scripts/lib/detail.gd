class_name Detail
extends RefCounted
## Kit de detalhamento industrial ("greebles").
##
## A estação era feita de caixas lisas: 4 paredes, um piso e uns móveis. Aqui
## entra a parafernália que faz o olho acreditar que aquilo foi construído e
## mantido por gente durante catorze anos: tubulações com flanges e válvulas,
## bandejas de cabo, caixas de junção, painéis de manômetros, grades de
## ventilação, armários, bancadas, escadas, vapor, poeira e infiltração.
##
## Referência: Dead Space (densidade industrial, vapor, sujeira) com
## acabamento soviético-utilitário (tinta gasta, estêncil, faixa de perigo).
##
## Tudo aqui é decorativo: praticamente nada recebe colisor, para não atrapalhar
## o caminhamento do jogador. O que precisa colidir usa `solid = true`.

static var _cache: Dictionary = {}
static var _halo: ImageTexture = null


static func _mat(key: String) -> Material:
	return Mats.get_mat(key)


## Cilindro do kit. Peça fina não precisa de doze lados: oito bastam e cortam
## um terço dos triângulos — com milhares de peças espalhadas, isso pesa.
static func _cil(parent: Node3D, radius: float, height: float, pos: Vector3, mat: Material,
		rot := Vector3.ZERO, seg := 0) -> Node3D:
	var lados := seg
	if lados == 0:
		lados = 10 if radius >= 0.12 else 8
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = lados
	mesh.rings = 1
	return G3D.mesh_inst(parent, mesh, pos, mat, rot, "cyl")


# ================================================================ TUBULAÇÃO
## Tubulação com flanges, curvas e válvulas. `count` tubos em paralelo.
static func pipe_run(parent: Node3D, a: Vector3, b: Vector3, count := 3, radius := 0.10,
		with_valves := true, seed_v := 1, insul := false) -> Node3D:
	var g := Node3D.new()
	g.name = "Tubulacao"
	parent.add_child(g)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_v
	var dir := (b - a)
	var comp := dir.length()
	if comp < 0.2:
		return g
	var along_x: bool = absf(dir.x) > absf(dir.z)
	var yaw := 0.0 if along_x else PI * 0.5
	var mid := (a + b) * 0.5
	var mat_pipe := _mat("pipe")
	for i in count:
		var off: float = (float(i) - float(count - 1) * 0.5) * (radius * 2.9)
		var p := mid + Vector3(0.0, 0.0, off) if along_x else mid + Vector3(off, 0.0, 0.0)
		var rot := Vector3(0, 0, PI * 0.5) if along_x else Vector3(PI * 0.5, 0, 0)
		_cil(g, radius, comp, p, mat_pipe, rot, false)
		# flanges a cada 2,4 m
		var nf := int(maxf(1.0, comp / 3.4))
		for k in nf + 1:
			var t := float(k) / float(maxf(nf, 1))
			var fp := a.lerp(b, t)
			var fpos := fp + Vector3(0.0, 0.0, off) if along_x else fp + Vector3(off, 0.0, 0.0)
			_cil(g, radius * 1.5, 0.07, fpos, _mat("metal_rust"), rot, false)
		# isolamento: anéis de amianto abraçando o tubo
		if insul and i % 2 == 0:
			var ns := int(maxf(1.0, comp / 1.9))
			for k in ns:
				var t2 := (float(k) + 0.5) / float(ns)
				var sp := a.lerp(b, t2)
				var spos := sp + Vector3(0.0, 0.0, off) if along_x else sp + Vector3(off, 0.0, 0.0)
				_cil(g, radius * 1.7, 0.9, spos, _mat("paper"), rot, false)
		# válvula de volante
		if with_valves and rng.randf() < 0.5:
			var t3 := rng.randf_range(0.2, 0.8)
			var vp := a.lerp(b, t3)
			var vpos := vp + Vector3(0.0, 0.0, off) if along_x else vp + Vector3(off, 0.0, 0.0)
			valve_wheel(g, vpos + Vector3(0, radius * 2.0, 0), yaw, radius * 1.9)
	return g


## Volante de válvula com raios, castelo e um pouco de ferrugem na haste.
static func valve_wheel(parent: Node3D, pos: Vector3, yaw: float, r: float = 0.22) -> Node3D:
	var g := Node3D.new()
	g.name = "Valvula"
	g.position = pos
	g.rotation.y = yaw
	parent.add_child(g)
	var m := _mat("metal_rust")
	_cil(g, 0.035, r * 2.2, Vector3(0, 0, 0), _mat("metal"), Vector3(PI * 0.5, 0, 0), false)
	# aro
	var seg := 8
	for i in seg:
		var ang := TAU * float(i) / float(seg)
		var p := Vector3(cos(ang) * r, sin(ang) * r, 0)
		_cil(g, 0.03, r * 0.55, p, m, Vector3(0, 0, ang + PI * 0.5), false)
	# raios
	for i in 3:
		var ang2 := TAU * float(i) / 3.0
		_cil(g, 0.024, r * 1.9, Vector3(0, 0, 0), m, Vector3(0, 0, ang2 + PI * 0.5), false)
	return g


# ================================================================ CABOS E CONDUÍTES
## Bandeja de cabos com fios soltos e presilhas, pendurada no teto.
static func cable_tray(parent: Node3D, a: Vector3, b: Vector3, seed_v := 1, n_cabos := 4) -> Node3D:
	var g := Node3D.new()
	g.name = "BandejaCabos"
	parent.add_child(g)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_v
	var dir := b - a
	var comp := dir.length()
	if comp < 0.3:
		return g
	var along_x: bool = absf(dir.x) > absf(dir.z)
	var mid := (a + b) * 0.5
	# bandeja: fundo perfurado + laterais
	var largura := 0.5
	var sz := Vector3(comp, 0.04, largura) if along_x else Vector3(largura, 0.04, comp)
	G3D.box(g, sz, mid, _mat("metal_rust"), false, Vector3.ZERO, "bandeja")
	for lado: float in [-1.0, 1.0]:
		var off := Vector3(0, 0.10, lado * largura * 0.5) if along_x else Vector3(lado * largura * 0.5, 0.10, 0)
		var sz2 := Vector3(comp, 0.20, 0.02) if along_x else Vector3(0.02, 0.20, comp)
		G3D.box(g, sz2, mid + off, _mat("metal_rust"), false, Vector3.ZERO, "lateral")
	# suportes ao teto
	var ns := int(maxf(1.0, comp / 2.4))
	for k in ns + 1:
		var t := float(k) / float(maxf(ns, 1))
		var p := a.lerp(b, t) + Vector3(0, 0.16, 0)
		_cil(g, 0.022, 0.34, p, _mat("metal"), Vector3.ZERO, false)
	# cabos: fios paralelos com leve caimento entre presilhas
	var cores := [_mat("rubber"), _mat("metal_rust"), _mat("pipe")]
	for c in n_cabos:
		var off_c: float = (float(c) - float(n_cabos - 1) * 0.5) * (largura / float(maxi(n_cabos, 2)))
		for k in ns:
			var t0 := float(k) / float(maxf(ns, 1))
			var t1 := float(k + 1) / float(maxf(ns, 1))
			var p0 := a.lerp(b, t0) + Vector3(0, 0.06, 0) + (Vector3(0, 0, off_c) if along_x else Vector3(off_c, 0, 0))
			var p1 := a.lerp(b, t1) + Vector3(0, 0.06, 0) + (Vector3(0, 0, off_c) if along_x else Vector3(off_c, 0, 0))
			# caimento no meio do vão
			for s in 2:
				var ta := float(s) / 2.0
				var tb := float(s + 1) / 2.0
				var qa := p0.lerp(p1, ta)
				var qb := p0.lerp(p1, tb)
				qa.y -= sin(ta * PI) * 0.055
				qb.y -= sin(tb * PI) * 0.055
				var qmid := (qa + qb) * 0.5
				var qdir := qb - qa
				var qlen := qdir.length()
				var rot := Vector3(0, 0, PI * 0.5) if along_x else Vector3(PI * 0.5, 0, 0)
				_cil(g, 0.016 + 0.004 * float(c % 3), qlen, qmid, cores[c % cores.size()], rot, false)
	return g


## Conduíte elétrico fino com caixas de passagem a cada trecho.
static func conduit(parent: Node3D, a: Vector3, b: Vector3, seed_v := 1) -> Node3D:
	var g := Node3D.new()
	g.name = "Conduite"
	parent.add_child(g)
	var comp := (b - a).length()
	if comp < 0.2:
		return g
	var along_x: bool = absf(b.x - a.x) > absf(b.z - a.z)
	var mid := (a + b) * 0.5
	var rot := Vector3(0, 0, PI * 0.5) if along_x else Vector3(PI * 0.5, 0, 0)
	_cil(g, 0.032, comp, mid, _mat("pipe"), rot, false)
	var nb := int(maxf(1.0, comp / 3.0))
	for k in nb:
		var t := (float(k) + 0.5) / float(nb)
		var p := a.lerp(b, t)
		G3D.box(g, Vector3(0.16, 0.20, 0.12), p, _mat("metal_rust"), false, Vector3.ZERO, "caixa_passagem")
		# presilhas
	return g


# ================================================================ EQUIPAMENTO DE PAREDE
## Caixa de junção com tampas, entradas de conduíte e etiqueta de aviso.
static func junction_box(parent: Node3D, pos: Vector3, yaw: float, big := false) -> Node3D:
	var g := Node3D.new()
	g.name = "CaixaJuncao"
	g.position = pos
	g.rotation.y = yaw
	parent.add_child(g)
	var w := 0.55 if big else 0.38
	var h := 0.72 if big else 0.50
	G3D.box(g, Vector3(w, h, 0.20), Vector3(0, 0, 0), _mat("metal_rust"), false, Vector3.ZERO, "carcaça")
	G3D.box(g, Vector3(w * 0.9, h * 0.42, 0.03), Vector3(0, h * 0.22, 0.11), _mat("metal"), false, Vector3.ZERO, "tampa")
	G3D.box(g, Vector3(w * 0.9, h * 0.42, 0.03), Vector3(0, -h * 0.22, 0.11), _mat("metal"), false, Vector3.ZERO, "tampa")
	# dobradiças e trinco
	_cil(g, 0.016, 0.10, Vector3(-w * 0.45, h * 0.30, 0.12), _mat("metal"), Vector3(PI * 0.5, 0, 0), false)
	_cil(g, 0.016, 0.10, Vector3(-w * 0.45, -h * 0.30, 0.12), _mat("metal"), Vector3(PI * 0.5, 0, 0), false)
	G3D.box(g, Vector3(0.05, 0.10, 0.05), Vector3(w * 0.38, 0, 0.12), _mat("metal"), false, Vector3.ZERO, "trinco")
	# conduítes entrando
	_cil(g, 0.03, 0.30, Vector3(-w * 0.5 - 0.14, h * 0.3, 0), _mat("pipe"), Vector3(0, 0, PI * 0.5), false)
	_cil(g, 0.03, 0.30, Vector3(-w * 0.5 - 0.14, -h * 0.2, 0), _mat("pipe"), Vector3(0, 0, PI * 0.5), false)
	# etiqueta de perigo gastada
	G3D.box(g, Vector3(0.16, 0.10, 0.01), Vector3(-w * 0.22, h * 0.40, 0.105), _mat("hazard"), false, Vector3.ZERO, "etiqueta")
	return g


## Painel de manômetros: leituras analógicas com vidro, mostradores âmbar.
static func gauge_panel(parent: Node3D, pos: Vector3, yaw: float, n := 3, seed_v := 1) -> Node3D:
	var g := Node3D.new()
	g.name = "PainelManometros"
	g.position = pos
	g.rotation.y = yaw
	parent.add_child(g)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_v
	var w := 0.22 * float(n) + 0.16
	G3D.box(g, Vector3(w, 0.54, 0.12), Vector3.ZERO, _mat("panel_green"), false, Vector3.ZERO, "painel")
	G3D.box(g, Vector3(w * 1.02, 0.05, 0.14), Vector3(0, 0.29, 0), _mat("metal"), false, Vector3.ZERO, "aba")
	for i in n:
		var x: float = (float(i) - float(n - 1) * 0.5) * 0.22
		# mostrador
		_cil(g, 0.085, 0.05, Vector3(x, 0.06, 0.07), _mat("panel_green"), Vector3(PI * 0.5, 0, 0), false)
		_cil(g, 0.072, 0.02, Vector3(x, 0.06, 0.10), Mats.emissive(Color(0.95, 0.72, 0.30), 0.9),
			Vector3(PI * 0.5, 0, 0), false)
		# ponteiro (posição diferente em cada relógio)
		var ang := rng.randf_range(-2.2, 1.4)
		G3D.box(g, Vector3(0.008, 0.055, 0.006), Vector3(x, 0.06, 0.115), Mats.emissive(Color(1, 0.35, 0.15), 1.2),
			false, Vector3(0, 0, ang), "ponteiro")
	# botões e alavanca
	for i in 3:
		var x2 := -w * 0.5 + 0.10 + float(i) * 0.10
		_cil(g, 0.022, 0.04, Vector3(x2, -0.16, 0.07), _mat("metal_rust"), Vector3(PI * 0.5, 0, 0), false)
	return g


## Armário elétrico aberto: quadro de disjuntores com fiação aparecendo.
static func breaker_panel(parent: Node3D, pos: Vector3, yaw: float, seed_v := 1) -> Node3D:
	var g := Node3D.new()
	g.name = "QuadroDisjuntores"
	g.position = pos
	g.rotation.y = yaw
	parent.add_child(g)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_v
	G3D.box(g, Vector3(0.9, 1.25, 0.22), Vector3(0, 0, 0), _mat("panel_green"), false, Vector3.ZERO, "armario")
	G3D.box(g, Vector3(0.86, 0.60, 0.03), Vector3(0, 0.26, 0.12), _mat("metal_rust"), false, Vector3.ZERO, "porta")
	for r in 3:
		for c in 5:
			var x := -0.30 + float(c) * 0.15
			var y := -0.06 - float(r) * 0.14
			G3D.box(g, Vector3(0.10, 0.09, 0.05), Vector3(x, y, 0.14), _mat("metal"), false, Vector3.ZERO, "disjuntor")
			# metade desligada, alguns queimados
			if rng.randf() < 0.35:
				G3D.box(g, Vector3(0.07, 0.02, 0.012), Vector3(x, y + 0.015, 0.17), Mats.emissive(Color(0.9, 0.2, 0.12), 1.0),
					false, Vector3.ZERO, "alavanca_off")
	# fiação solta na parte de baixo
	for i in 5:
		var x3 := rng.randf_range(-0.35, 0.35)
		_cil(g, 0.012, rng.randf_range(0.25, 0.55), Vector3(x3, -0.45, 0.14),
			[_mat("rubber"), _mat("metal_rust"), _mat("pipe")][i % 3], Vector3(rng.randf_range(-0.3, 0.3), 0, 0), false)
	return g


## Grade de ventilação com lâminas inclinadas (uso interno das paredes/tetos).
static func louver(parent: Node3D, pos: Vector3, yaw: float, w := 0.9, h := 0.55) -> Node3D:
	var g := Node3D.new()
	g.name = "Grade"
	g.position = pos
	g.rotation.y = yaw
	parent.add_child(g)
	var moldura := 0.06
	G3D.box(g, Vector3(w, h, 0.14), Vector3.ZERO, _mat("metal_rust"), false, Vector3.ZERO, "moldura")
	G3D.box(g, Vector3(w - moldura * 2.0, h - moldura * 2.0, 0.04), Vector3(0, 0, 0.06), Mats.emissive(Color(0.02, 0.03, 0.035), 0.2),
		false, Vector3.ZERO, "fundo")
	var n := int(h / 0.13)
	for i in n:
		var y: float = -h * 0.5 + moldura + 0.045 + float(i) * 0.09
		G3D.box(g, Vector3(w - moldura * 2.0, 0.055, 0.015), Vector3(0, y, 0.08), _mat("metal"),
			false, Vector3(-0.5, 0, 0), "lamina")
	# parafusos
	for sx: float in [-1.0, 1.0]:
		for sy: float in [-1.0, 1.0]:
			_cil(g, 0.014, 0.03, Vector3(sx * (w * 0.5 - 0.03), sy * (h * 0.5 - 0.03), 0.09), _mat("metal"),
				Vector3(PI * 0.5, 0, 0), false)
	return g


## Banco de monitores de manutenção, piscando leituras.
static func monitor_bank(parent: Node3D, pos: Vector3, yaw: float, cols := 3, rows := 2) -> Node3D:
	var g := Node3D.new()
	g.name = "BancoMonitores"
	g.position = pos
	g.rotation.y = yaw
	parent.add_child(g)
	var w := 0.30 * float(cols) + 0.14
	var h := 0.26 * float(rows) + 0.20
	G3D.box(g, Vector3(w, h, 0.16), Vector3(0, 0, 0), _mat("wall_dark"), false, Vector3.ZERO, "rack")
	for r in rows:
		for c in cols:
			var x: float = (float(c) - float(cols - 1) * 0.5) * 0.30
			var y: float = (float(r) - float(rows - 1) * 0.5) * 0.26
			var cor := Color(0.30, 0.90, 0.65) if (r + c) % 3 != 0 else Color(0.95, 0.65, 0.20)
			G3D.box(g, Vector3(0.24, 0.19, 0.02), Vector3(x, y, 0.09), Mats.emissive(cor, 0.85), false, Vector3.ZERO, "tela")
			G3D.box(g, Vector3(0.26, 0.21, 0.03), Vector3(x, y, 0.075), _mat("metal_rust"), false, Vector3.ZERO, "moldura")
	G3D.box(g, Vector3(w, 0.06, 0.30), Vector3(0, -h * 0.5 - 0.02, 0.06), _mat("metal"), false, Vector3.ZERO, "bandeja")
	return g


# ================================================================ MOBILIÁRIO PESADO
## Bancada de trabalho com morsa, ferramentas e gavetas.
static func workbench(parent: Node3D, pos: Vector3, yaw: float, seed_v := 1) -> Node3D:
	var g := Node3D.new()
	g.name = "Bancada"
	g.position = pos
	g.rotation.y = yaw
	parent.add_child(g)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_v
	G3D.box(g, Vector3(2.2, 0.08, 0.75), Vector3(0, 0.92, 0), _mat("shelf_wood"), true, Vector3.ZERO, "tampo")
	# estrutura
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			G3D.box(g, Vector3(0.07, 0.88, 0.07), Vector3(sx * 1.02, 0.44, sz * 0.30), _mat("metal_rust"), true, Vector3.ZERO, "perna")
	# gaveteiro
	G3D.box(g, Vector3(0.55, 0.70, 0.62), Vector3(0.72, 0.35, 0), _mat("panel_green"), true, Vector3.ZERO, "gaveteiro")
	for i in 3:
		G3D.box(g, Vector3(0.48, 0.16, 0.03), Vector3(0.72, 0.12 + float(i) * 0.22, 0.32), _mat("metal"), false, Vector3.ZERO, "gaveta")
		G3D.box(g, Vector3(0.14, 0.025, 0.03), Vector3(0.72, 0.12 + float(i) * 0.22, 0.345), _mat("metal_rust"), false, Vector3.ZERO, "puxador")
	# morsa
	G3D.box(g, Vector3(0.22, 0.14, 0.18), Vector3(-0.75, 1.03, 0.06), _mat("metal_rust"), false, Vector3.ZERO, "morsa")
	_cil(g, 0.02, 0.30, Vector3(-0.75, 1.03, 0.22), _mat("metal"), Vector3(PI * 0.5, 0, 0), false)
	# ferramentas espalhadas
	for i in 4:
		var x := rng.randf_range(-0.4, 0.4)
		var z := rng.randf_range(-0.2, 0.2)
		G3D.box(g, Vector3(rng.randf_range(0.12, 0.28), 0.03, 0.05), Vector3(x, 0.98, z),
			_mat("metal") if i % 2 == 0 else _mat("rubber"), false, Vector3(0, rng.randf() * PI, 0), "ferramenta")
	# quadro de ferramentas na parede (acima da bancada)
	G3D.box(g, Vector3(1.6, 0.9, 0.04), Vector3(0, 2.0, -0.34), _mat("metal_rust"), false, Vector3.ZERO, "quadro")
	for i in 7:
		var x2: float = -0.6 + float(i) * 0.2
		G3D.box(g, Vector3(0.05, rng.randf_range(0.25, 0.5), 0.03), Vector3(x2, 2.0, -0.30),
			_mat("metal"), false, Vector3.ZERO, "ferramenta_parede")
	return g


## Banco de armários: portas com veneziana, números e fechaduras.
static func locker_bank(parent: Node3D, pos: Vector3, yaw: float, n := 3, seed_v := 1) -> Node3D:
	var g := Node3D.new()
	g.name = "Armarios"
	g.position = pos
	g.rotation.y = yaw
	parent.add_child(g)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_v
	var w := 0.48 * float(n)
	G3D.box(g, Vector3(w, 2.05, 0.55), Vector3(0, 1.02, 0), _mat("panel_green"), true, Vector3.ZERO, "corpo")
	for i in n:
		var x: float = (float(i) - float(n - 1) * 0.5) * 0.48
		G3D.box(g, Vector3(0.44, 1.95, 0.04), Vector3(x, 1.02, 0.28), _mat("metal_rust") if i % 2 else _mat("metal"),
			false, Vector3.ZERO, "porta")
		# venezianas
		for k in 4:
			G3D.box(g, Vector3(0.30, 0.02, 0.02), Vector3(x, 1.62 + float(k) * 0.07, 0.31), _mat("metal_rust"), false, Vector3.ZERO, "veneziana")
		# fechadura e puxador
		G3D.box(g, Vector3(0.09, 0.10, 0.05), Vector3(x + 0.14, 1.05, 0.31), _mat("metal"), false, Vector3.ZERO, "fechadura")
		# etiqueta com número
		G3D.label3d(g, "%02d" % (seed_v * 7 + i), Vector3(x - 0.12, 1.20, 0.32), 0.0, 0.0035, Color(0.92, 0.90, 0.80))
	return g


## Escada de gato com gaiola de proteção (clássico de sala de máquinas).
static func ladder(parent: Node3D, pos: Vector3, yaw: float, height := 3.2, cage := true) -> Node3D:
	var g := Node3D.new()
	g.name = "Escada"
	g.position = pos
	g.rotation.y = yaw
	parent.add_child(g)
	for sx: float in [-1.0, 1.0]:
		_cil(g, 0.035, height, Vector3(sx * 0.24, height * 0.5, 0), _mat("metal_rust"), Vector3.ZERO, false)
	var nd := int(height / 0.32)
	for i in nd:
		_cil(g, 0.018, 0.48, Vector3(0, 0.32 + float(i) * 0.32, 0), _mat("metal"), Vector3(0, 0, PI * 0.5), false)
	if cage:
		var na := int(height / 0.7)
		for i in na:
			var y := 1.0 + float(i) * 0.7
			# arco traseiro da gaiola
			for k in 5:
				var ang := -PI * 0.55 + PI * 1.1 * float(k) / 4.0
				var p := Vector3(sin(ang) * 0.42, y, -0.36 - cos(ang) * 0.16)
				_cil(g, 0.02, 0.30, p, _mat("metal_rust"), Vector3(0, 0, ang + PI * 0.5), false)
	return g


## Viga em I aparente (estrutura do casco visível atravessando o teto).
static func i_beam(parent: Node3D, a: Vector3, b: Vector3, size := 0.26) -> Node3D:
	var g := Node3D.new()
	g.name = "Viga"
	parent.add_child(g)
	var comp := (b - a).length()
	if comp < 0.3:
		return g
	var along_x: bool = absf(b.x - a.x) > absf(b.z - a.z)
	var mid := (a + b) * 0.5
	var m := _mat("metal_rust")
	var L := Vector3(comp, size * 0.16, size * 0.42) if along_x else Vector3(size * 0.42, size * 0.16, comp)
	G3D.box(g, L, mid + Vector3(0, -size * 0.35, 0), m, false, Vector3.ZERO, "aba_inf")
	G3D.box(g, L, mid + Vector3(0, size * 0.35, 0), m, false, Vector3.ZERO, "aba_sup")
	var alma := Vector3(comp, size * 0.70, size * 0.10) if along_x else Vector3(size * 0.10, size * 0.70, comp)
	G3D.box(g, alma, mid, m, false, Vector3.ZERO, "alma")
	# reforços soldados
	var nr := int(maxf(1.0, comp / 2.2))
	for k in nr:
		var t := (float(k) + 0.5) / float(nr)
		var p := a.lerp(b, t)
		(G3D.box(g, Vector3(0.05, size * 1.1, size * 0.55), p, m, false, Vector3.ZERO, "reforco") if along_x
				else G3D.box(g, Vector3(size * 0.55, size * 1.1, 0.05), p, m, false, Vector3.ZERO, "reforco"))
	return g


# ================================================================ ATMOSFERA
## Jato de vapor (sala de máquinas, válvulas escapando).
static func steam_vent(parent: Node3D, pos: Vector3, yaw: float, strength := 1.0) -> Node3D:
	var g := Node3D.new()
	g.name = "Vapor"
	g.position = pos
	g.rotation.y = yaw
	parent.add_child(g)
	_cil(g, 0.05, 0.16, Vector3(0, 0, 0), _mat("metal_rust"), Vector3(PI * 0.5, 0, 0), false)
	G3D.box(g, Vector3(0.16, 0.16, 0.04), Vector3(0.10, 0, 0), _mat("metal"), false, Vector3.ZERO, "flange")
	var p := GPUParticles3D.new()
	p.amount = int((24 if OS.has_feature("web") else 48) * strength)
	p.lifetime = 2.6
	p.preprocess = 1.2
	p.emitting = true
	p.position = Vector3(0.16, 0, 0)
	p.rotation_degrees = Vector3(0, 0, -90.0)   # jato para cima
	var pm := ParticleProcessMaterial.new()
	pm.direction = Vector3(0, 1, 0)
	pm.spread = 14.0
	pm.initial_velocity_min = 1.6 * strength
	pm.initial_velocity_max = 3.1 * strength
	pm.gravity = Vector3(0, 0.35, 0)
	pm.scale_min = 0.35
	pm.scale_max = 0.95
	pm.damping_min = 0.6
	pm.damping_max = 1.4
	pm.color = Color(0.80, 0.86, 0.90, 0.30)
	var curve := CurveTexture.new()
	var c := Curve.new()
	c.add_point(Vector2(0.0, 0.0))
	c.add_point(Vector2(0.15, 0.55))
	c.add_point(Vector2(1.0, 0.0))
	curve.curve = c
	pm.alpha_curve = curve
	var curva_esc := CurveTexture.new()
	var c2 := Curve.new()
	c2.add_point(Vector2(0.0, 0.25))
	c2.add_point(Vector2(0.6, 1.0))
	c2.add_point(Vector2(1.0, 1.6))
	curva_esc.curve = c2
	pm.scale_curve = curva_esc
	p.process_material = pm
	p.draw_pass_1 = _soft_quad(Color(0.82, 0.88, 0.92, 0.22), 0.55)
	p.visibility_aabb = AABB(Vector3(-3, -1, -3), Vector3(6, 8, 6))
	g.add_child(p)
	# gloss: o vapor some no ambiente
	return g


## Poça de água com reflexo (SSR) e umidade em volta.
static func puddle(parent: Node3D, pos: Vector3, r := 1.4, seed_v := 1) -> void:
	var d := Decals.make("water", Vector2(r, r), Vector3(pos.x, pos.y + 0.025, pos.z), 0.0,
			false, Color(0.03, 0.045, 0.06, 0.85), false, seed_v)
	parent.add_child(d)
	# brilho especular: uma laje fina e lisa em cima da mancha
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.02, 0.03, 0.04, 0.55)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.roughness = 0.04
	m.metallic = 0.5
	var disc := _cil(parent, r * 0.55, 0.012, Vector3(pos.x, pos.y + 0.012, pos.z), m, Vector3.ZERO, false)
	disc.name = "Poca"


## Poeira suspensa: partículas finas que pegam a luz (dá corpo ao ar).
static func dust(parent: Node3D, centro: Vector3, raio := 8.0, altura := 3.2, quanto := 90) -> Node3D:
	if OS.has_feature("web"):
		return null   # no navegador as partículas custam mais do que rendem
	var g := Node3D.new()
	g.name = "Poeira"
	g.position = centro
	parent.add_child(g)
	var p := GPUParticles3D.new()
	p.amount = mini(quanto, 45)
	p.lifetime = 14.0
	p.preprocess = 6.0
	p.position = Vector3(0, altura * 0.5, 0)
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(raio, altura * 0.5, raio)
	pm.direction = Vector3(0.2, 1, 0.1)
	pm.spread = 40.0
	pm.initial_velocity_min = 0.02
	pm.initial_velocity_max = 0.12
	pm.gravity = Vector3(0.01, 0.004, 0)
	pm.scale_min = 0.012
	pm.scale_max = 0.045
	pm.color = Color(0.85, 0.90, 0.95, 0.28)
	p.process_material = pm
	p.draw_pass_1 = _soft_quad(Color(0.90, 0.94, 1.0, 0.13), 0.09)
	p.visibility_aabb = AABB(Vector3(-raio, 0, -raio), Vector3(raio * 2.0, altura * 2.0, raio * 2.0))
	g.add_child(p)
	return g


## Ponto de luz fraca "de trabalho" (lanterna de manutenção pendurada).
static func work_lamp(parent: Node3D, pos: Vector3, cor := Color(1.0, 0.72, 0.38), energia := 1.1,
		alcance := 7.0, cabo := 0.5, pisca := 0.0) -> Node3D:
	var g := Node3D.new()
	g.name = "LanternaTrabalho"
	g.position = pos
	parent.add_child(g)
	_cil(g, 0.012, cabo, Vector3(0, cabo * 0.5, 0), _mat("rubber"), Vector3.ZERO, false)
	_cil(g, 0.09, 0.16, Vector3(0, 0.0, 0), _mat("lamp_warm") if cor.r > cor.b else _mat("lamp_cold"), Vector3.ZERO, false)
	var lento := G3D.box(g, Vector3(0.28, 0.07, 0.20), Vector3(0, -0.10, 0), _mat("metal_rust"), false, Vector3.ZERO, "aba")
	var l := OmniLight3D.new()
	l.light_color = cor
	l.light_energy = energia
	l.omni_range = alcance
	l.shadow_enabled = false
	l.position = Vector3(0, -0.18, 0)
	g.add_child(l)
	Director.register_light(l)
	if pisca > 0.0:
		# luz defeituosa: pisca de vez em quando (nunca em ritmo previsível)
		l.set_meta("flicker", pisca)
		var t := Timer.new()
		t.wait_time = randf_range(2.5, 7.0)
		t.autostart = true
		t.timeout.connect(func() -> void:
			if not is_instance_valid(l):
				return
			var tw := l.create_tween()
			tw.tween_property(l, "light_energy", 0.05, 0.06)
			tw.tween_property(l, "light_energy", energia, 0.05)
			tw.tween_property(l, "light_energy", 0.08, 0.05)
			tw.tween_property(l, "light_energy", energia, 0.08)
			t.wait_time = randf_range(1.8, 8.0))
		g.add_child(t)
	if lento:
		var tw2 := g.create_tween()
		tw2.set_loops()
		tw2.tween_property(g, "scale", Vector3(1.0, 0.995, 1.0), 3.0)
		tw2.tween_property(g, "scale", Vector3(1.0, 1.0, 1.0), 3.0)
	return g


static func _soft_quad(cor: Color, tamanho := 0.45) -> QuadMesh:
	var q := QuadMesh.new()
	q.size = Vector2(tamanho, tamanho)
	var m := StandardMaterial3D.new()
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	m.albedo_texture = _tex_halo()
	m.albedo_color = cor
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.disable_receive_shadows = true
	q.material = m
	return q


## Halo radial gerado em código. Sem ele cada partícula vira um quadrado duro
## no ar da sala — a compatibilidade (navegador) não tem brilho HDR para
## disfarçar a borda. Com a máscara caindo ao cubo, a borda desaparece.
static func _tex_halo() -> ImageTexture:
	if _halo != null:
		return _halo
	var n := 32
	var img := Image.create_empty(n, n, false, Image.FORMAT_RGBA8)
	for y in n:
		for x in n:
			var u := (float(x) + 0.5) / float(n) * 2.0 - 1.0
			var v := (float(y) + 0.5) / float(n) * 2.0 - 1.0
			var d := sqrt(u * u + v * v)
			var a := clampf(1.0 - d, 0.0, 1.0)
			a = a * a * a
			img.set_pixel(x, y, Color(1.0, 1.0, 1.0, a))
	_halo = ImageTexture.create_from_image(img)
	return _halo
