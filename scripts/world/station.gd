class_name Station
extends RefCounted
## A estação ARGOS-4, construída em código: quatro conveses empilhados,
## anel central de circulação, asas externas e o módulo de observação.
##
##   Convés 1 (y=40) — Hangar / Cabines / Refeitório / Depósito
##   Convés 2 (y=52) — Laboratórios / Engenharia / Enfermaria / Rádio
##   Convés 3 (y=64) — Comando / Câmara do sino / Eclusa / Corredor de observação
##   Convés 4 (y=76) — Módulo de observação

const D1 := 40.0
const D2 := 52.0
const D3 := 64.0
const D4 := 76.0

# Monta-cargas: cada poço é um vão real no piso do convés superior.
const LIFT_A_BOTTOM := Vector3(9.0, D1 - 0.13, -16.5)
const LIFT_A_TOP := Vector3(9.0, D2 - 0.13, -16.5)
const LIFT_B_BOTTOM := Vector3(16.4, D2 - 0.13, 8.0)
const LIFT_B_TOP := Vector3(16.4, D3 - 0.13, 8.0)
const LIFT_C_BOTTOM := Vector3(34.1, D3 - 0.13, 0.0)
const LIFT_C_TOP := Vector3(34.1, D4 - 0.13, 0.0)
const HOLE_A := {"x1": 7.7, "z1": -17.8, "x2": 10.3, "z2": -15.2}
const HOLE_B := {"x1": 15.1, "z1": 6.7, "x2": 17.7, "z2": 9.3}
const HOLE_C := {"x1": 32.8, "z1": -1.3, "x2": 35.4, "z2": 1.3}


## Vãos que o anel de cada convés precisa ter (piso e teto).
static func holes_for_deck(y: float, piso: bool) -> Array:
	if piso:
		if is_equal_approx(y, D2):
			return [HOLE_A]
		if is_equal_approx(y, D3):
			return [HOLE_B]
		return []
	if is_equal_approx(y, D1):
		return [HOLE_A]
	if is_equal_approx(y, D2):
		return [HOLE_B]
	return []


static func build(root: Node3D) -> void:
	LampGrid.reset()
	CamGrid.reset()
	_build_deck1(root)
	_build_deck2(root)
	_build_deck3(root)
	_build_deck4(root)
	# por último: vestir a estação com tubulação, cabos, sujeira, vapor e poeira
	Dressing.vestir(root)
	# ...e aglutinar toda essa tralha estática em MultiMesh: mesma cara,
	# uma fração das chamadas de desenho (isto é decoração pura, nada aqui
	# tem script, colisor ou mudança de estado durante o jogo)
	var vest := root.get_node_or_null("Vestimenta")
	if vest != null:
		vest.set_meta(Batcher.META_PROPRIO, true)
		Batcher.aglutinar(vest as Node3D, 3)
	# a estrutura (nervuras de parede, corpos de luminária, móveis fixos) também
	# é aglutinada, em modo conservador: nada emissivo, transparente, com
	# script ou corpo físico é tocado. Salas e grupos que somem/aparecem ou
	# trocam de lugar guardam os próprios lotes.
	for n in root.find_children("*", "Node3D", true, false):
		if n != vest and n.has_meta(Batcher.META_PROPRIO):
			Batcher.aglutinar(n as Node3D, 3, 16.0, true)
	Batcher.aglutinar(root, 3, 16.0, true)


# ================================================================ UTILIDADES
static func _mk(parent: Node3D, name: String, x1: float, z1: float, x2: float, z2: float,
		y: float, h: float, opts: Dictionary, sector := "", sector_display := "") -> Dictionary:
	var r := StationKit.room(parent, x1, z1, x2, z2, y, h, opts)
	for d: Door in r.get("doors", []):
		Director.register_door(d.door_id, d)
	for lamp: Dictionary in r.get("lamps", []):
		LampGrid.add(lamp)
		Director.register_light(lamp["light"])
	if sector != "" and sector_display != "":
		var a := SectorArea.create(sector, sector_display,
				Vector3((x1 + x2) * 0.5, y + h * 0.5, (z1 + z2) * 0.5),
				Vector3(absf(x2 - x1), h, absf(z2 - z1)))
		parent.add_child(a)
	return r


static func _lamp_row(along_x: bool, from_v: float, to_v: float, fixed: float, count: int,
		emergency := false, energy := 0.16) -> Array:
	var out: Array = []
	for i in count:
		var t := (float(i) + 0.5) / float(maxi(count, 1))
		var v: float = lerpf(from_v, to_v, t)
		var pos := Vector2(v if along_x else fixed, fixed if along_x else v)
		out.append({"pos": pos, "along_x": along_x, "emergency": emergency, "energy": energy})
	return out


## Anel de circulação: corredor quadrado em volta de um núcleo sólido.
static func _ring(parent: Node3D, y: float, h: float, doors: Array) -> void:
	var lamps: Array = []
	lamps.append_array(_lamp_row(true, -16.0, 16.0, -16.0, 4, true))
	lamps.append_array(_lamp_row(true, -16.0, 16.0, 16.0, 4, true))
	lamps.append_array(_lamp_row(false, -13.0, 13.0, -16.0, 3, true))
	lamps.append_array(_lamp_row(false, -13.0, 13.0, 16.0, 3, true))
	var r := _mk(parent, "Anel", -18.0, -18.0, 18.0, 18.0, y, h, {
		"name": "Anel_%d" % int(y),
		"floor": Mats.get_mat("floor_grating"),
		"wall": Mats.get_mat("wall"),
		"pipes": true,
		"doors": doors,
		"lamps": lamps,
		"floor_holes": holes_for_deck(y, true),
		"ceil_holes": holes_for_deck(y, false),
	}, "anel%d" % int(y), "ANEL DE CIRCULAÇÃO — CONVÉS %d" % int((y - 40.0) / 12.0 + 1))
	for hd: Dictionary in holes_for_deck(y, true):
		StationKit.shaft_marks(parent, (float(hd["x1"]) + float(hd["x2"])) * 0.5, (float(hd["z1"]) + float(hd["z2"])) * 0.5, float(hd["x2"]) - float(hd["x1"]), y)
	var floor_mat := Mats.get_mat("wall_dark")
	# núcleo central: instalações seladas, tubulações e avisos
	G3D.box(parent, Vector3(28.0, h, 28.0), Vector3(0, y + h * 0.5, 0), floor_mat, true, Vector3.ZERO, "nucleo")
	for i in 4:
		var ang := TAU * float(i) / 4.0
		var d := Vector3(sin(ang) * 14.6, 0, cos(ang) * 14.6)
		G3D.sign(parent, "NÚCLEO SELADO\nNÃO ABRIR", Vector3(d.x, y + 1.9, d.z), ang, 34, Color(0.75, 0.42, 0.30))
		G3D.box(parent, Vector3(1.4, 2.2, 0.05) if absf(d.z) > absf(d.x) else Vector3(0.05, 2.2, 1.4),
				Vector3(d.x * 0.997, y + 1.1, d.z * 0.997), Mats.get_mat("metal_rust"), false, Vector3.ZERO, "acesso")


static func _corridor(parent: Node3D, name: String, along_x: bool, from_v: float, to_v: float, fixed: float,
		width: float, y: float, h: float, sector: String, display: String, doors: Array = [],
		lamps := 4) -> Dictionary:
	var half := width * 0.5
	var rect := [from_v, fixed - half, to_v, fixed + half] if along_x else [fixed - half, from_v, fixed + half, to_v]
	var lamps_arr: Array = _lamp_row(along_x, from_v + 1.0, to_v - 1.0, fixed if along_x else fixed, lamps, true)
	var r := _mk(parent, name, rect[0], rect[1], rect[2], rect[3], y, h, {
		"name": name,
		"floor": Mats.get_mat("floor_grating"),
		"wall": Mats.get_mat("wall"),
		"pipes": true,
		"doors": doors,
		"lamps": lamps_arr,
	}, sector, display)
	return r


# ================================================================ CONVÉS 1
static func _build_deck1(root: Node3D) -> void:
	# ---- anel
	_ring(root, D1, 3.4, [
		{"side": "n", "at": 0.0, "w": 3.0, "h": 3.0, "type": "bulk", "id": "hangar", "name": "HANGAR", "auto": true},
		{"side": "w", "at": 0.0, "w": 1.8, "h": 2.2, "type": "door", "id": "deposito", "name": "DEPÓSITO", "auto": true},
		{"side": "e", "at": 0.0, "w": 1.8, "h": 2.2, "type": "door", "id": "cabines", "name": "CABINES", "auto": true},
		{"side": "s", "at": 0.0, "w": 2.2, "h": 2.4, "type": "door", "id": "refeitorio", "name": "REFEITÓRIO", "auto": true},
	])
	# ---- HANGAR
	var hangar := _mk(root, "Hangar", -16.0, -46.0, 16.0, -18.0, D1, 7.0, {
		"name": "Hangar",
		"floor": Mats.get_mat("floor_grating"),
		"wall": Mats.get_mat("wall_dark"),
		"skip_walls": ["s"],
		"lamps": [{"pos": Vector2(-8, -32), "along_x": true, "emergency": true, "energy": 0.35},
				  {"pos": Vector2(8, -32), "along_x": true, "emergency": true, "energy": 0.35}],
		"labels": [{"text": "HANGAR NORTE", "pos": Vector3(0, D1 + 4.6, -19.2), "rot_y": 0.0, "size": 60}],
	}, "hangar", "HANGAR NORTE")
	# parede superior do vão (acima do corredor)
	G3D.wall(root, true, -16.0, 16.0, -18.0, D1 + 3.4, 3.6, Mats.get_mat("wall_dark"), 0.3, [])
	G3D.box(root, Vector3(26.0, 0.4, 5.0), Vector3(0, D1 + 7.3, -42.0), Mats.get_mat("metal"), false, Vector3.ZERO, "guarda_cargo")
	G3D.hazard_stripe(root, true, Vector3(0, D1, -19.0), 3.0, 0.3)
	_k9_capsule(root, Vector3(0, D1, -34.0), 0.0)
	StationKit.crates(root, Vector3(-11.0, D1, -24.0), 5)
	StationKit.crates(root, Vector3(11.0, D1, -40.0), 4)
	StationKit.suit_rack(root, Vector3(14.0, D1, -22.0), -PI * 0.5, 2)
	StationKit.console(root, Vector3(-12.0, D1, -20.2), 0.0, "terminal",
			{"docs": ["bl_000", "log_argos_01"], "title": "TERMINAL DO HANGAR"}, {"needs_power": false})
	StationKit.camera_fixture(root, "cam_01", "CAM-01 HANGAR", Vector3(-15.6, D1 + 5.4, -44.5), PI * 0.25, "HANGAR")
	Director.register_poi("hangar", Vector3(0, D1, -30))
	Director.register_poi("lab", Vector3(0, D2, -28))
	Director.register_poi("engenharia", Vector3(30, D2, 0))
	Director.register_poi("enfermaria", Vector3(0, D2, 27))
	Director.register_poi("k9", Vector3(0, D1, -31.5))
	# porta externa do hangar (grande, fechada)
	G3D.box(root, Vector3(14.0, 6.0, 0.6), Vector3(0, D1 + 3.0, -45.6), Mats.get_mat("metal_rust"), true, Vector3.ZERO, "portao")
	G3D.hazard_stripe(root, false, Vector3(0, D1, -45.2), 14.0, 0.5)
	G3D.label3d(root, "PORTAO EXTERNO — OPERACAO MANUAL BLOQUEADA", Vector3(0, D1 + 5.6, -45.0), 0.0, 0.006, Color(0.8, 0.5, 0.35))

	# ---- DEPÓSITO / OFICINA (oeste)
	_mk(root, "Deposito", -40.0, -10.0, -18.0, 10.0, D1, 3.4, {
		"name": "Deposito",
		"wall": Mats.get_mat("wall_rust"),
		"skip_walls": ["e"],
		"pipes": true,
		"lamps": _lamp_row(false, -8.0, 8.0, -30.0, 3, true),
	}, "deposito", "DEPÓSITO E OFICINA")
	StationKit.crates(root, Vector3(-34.0, D1, -4.0), 6)
	StationKit.shelf(root, Vector3(-24.0, D1, -8.4), 0.0, 8)
	StationKit.locker(root, Vector3(-22.0, D1, 6.0), -PI * 0.5, "SOLDA")
	# fusível de 400 A
	G3D.box(root, Vector3(1.3, 1.05, 1.3), Vector3(-34.0, D1 + 0.52, -4.6), Mats.get_mat("metal_rust"), true, Vector3.ZERO, "engradado")
	G3D.box(root, Vector3(1.2, 0.05, 1.2), Vector3(-34.0, D1 + 1.07, -4.6), Mats.get_mat("fabric"), false, Vector3.ZERO, "tampa")
	var fuse := G3D.box(root, Vector3(0.42, 0.42, 0.52), Vector3(-34.0, D1 + 1.32, -4.6), Mats.get_mat("metal"), true, Vector3.ZERO, "fusivel")
	var fi := Interactable.create("Pegar fusível de 400 A", Vector3(1.0, 1.0, 1.0), Vector3.ZERO,
			func(_p: Node3D, _i: Interactable) -> void:
				GameState.set_flag("tem_fusivel")
				AudioMan.play_3d("clank", fuse.global_position, -8.0)
				UI.show_note("FUSÍVEL 400 A", "Pesado, quente na mão — como se tivesse sido usado há pouco. Você não viu ninguém por perto.")
				fuse.queue_free())
	fuse.add_child(fi)
	StationKit.console(root, Vector3(-38.0, D1, 8.0), PI * 0.5, "terminal",
			{"docs": ["eng_note_01", "manuel_reactor"], "title": "BANCADA DE MANUTENÇÃO"}, {"needs_power": false})
	Director.register_poi("deposito", Vector3(-30, D1, 0))

	# ---- CABINES (leste)
	_mk(root, "Cabines", 18.0, -12.0, 38.0, 12.0, D1, 3.4, {
		"name": "Cabines",
		"wall": Mats.get_mat("wall_blue"),
		"floor": Mats.get_mat("floor_plate"),
		"skip_walls": ["w"],
		"lamps": _lamp_row(false, -10.0, 10.0, 28.0, 3, true),
	}, "cabines", "CABINES DA TRIPULAÇÃO")
	# divisória interna entre as duas cabines
	G3D.wall(root, false, -12.0, 12.0, 28.0, D1, 3.4, Mats.get_mat("wall"), 0.25,
			[{"at": 5.4, "width": 1.2, "height": 2.1}])
	StationKit.bed(root, Vector3(22.0, D1, -7.0), 0.0, "VALE")
	StationKit.bed(root, Vector3(34.0, D1, 6.0), PI, "SOLOKOV")
	StationKit.locker(root, Vector3(20.0, D1, 8.0), -PI * 0.5, "TRAJES")
	StationKit.shelf(root, Vector3(35.0, D1, -9.0), PI, 5)
	Director.register_prop(root.get_node("Cabines"))
	StationKit.console(root, Vector3(20.0, D1, -10.0), 0.0, "terminal",
			{"docs": ["cabin_iris"], "title": "TERMINAL DA CABINE 1"}, {"needs_power": false})
	StationKit.console(root, Vector3(36.0, D1, 10.0), PI, "terminal",
			{"docs": ["cabin_solokov"], "title": "TERMINAL DA CABINE 2"}, {"needs_power": false})
	StationKit.tape_player(root, Vector3(20.5, D1, 2.0), -PI * 0.5, "fita_1", "andrei_01")
	# fotografia fixada na parede
	StationKit.console(root, Vector3(36.0, D1, -2.0), PI, "photo", {"doc": "photo_01"})
	Director.register_poi("cabines", Vector3(28, D1, 0))

	# ---- REFEITÓRIO (sul) com a janela sul
	_mk(root, "Refeitorio", -12.0, 18.0, 12.0, 40.0, D1, 4.2, {
		"name": "Refeitorio",
		"wall": Mats.get_mat("tile_wall"),
		"skip_walls": ["n"],
		"windows": [{"side": "s", "at": 0.0, "w": 15.0, "h": 3.1, "base": 0.7, "type": "big"}],
		"lamps": _lamp_row(true, -10.0, 10.0, 30.0, 3, true),
	}, "refeitorio", "REFEITÓRIO — JANELA SUL")
	G3D.sign(root, "JANELA SUL — NAO OLHAR APOS O TERCEIRO SINO", Vector3(0, D1 + 3.4, 39.6), PI, 40, Color(0.85, 0.55, 0.35))
	var ruined := Node3D.new()
	ruined.name = "Refeitorio_Ruina"
	ruined.set_meta(Batcher.META_PROPRIO, true)
	root.add_child(ruined)
	var intact := Node3D.new()
	intact.name = "Refeitorio_Intacto"
	intact.visible = false
	intact.set_meta(Batcher.META_PROPRIO, true)
	root.add_child(intact)
	StationKit.table_chairs(ruined, Vector3(-6.0, D1, 26.0))
	StationKit.table_chairs(ruined, Vector3(6.0, D1, 34.0), PI, 3)
	StationKit.crates(ruined, Vector3(9.0, D1, 22.0), 3)
	StationKit.stain(ruined, Vector3(0, D1, 30.0), Vector2(3.0, 2.0), true)
	StationKit.table_chairs(intact, Vector3(-6.0, D1, 26.0))
	StationKit.table_chairs(intact, Vector3(6.0, D1, 34.0), PI, 4)
	_hydroponics(intact, Vector3(-10.0, D1, 34.0))
	Director.register_prop(intact)
	# aviso psicológico na parede
	StationKit.console(root, Vector3(10.0, D1, 20.0), -PI * 0.5, "photo", {"doc": "aviso_psico"})
	Director.register_poi("refeitorio", Vector3(0, D1, 30))
	Director.register_poi("janela_sul", Vector3(0, D1 + 2.4, 39.2))
	StationKit.camera_fixture(root, "cam_03", "CAM-03 REFEITÓRIO", Vector3(-11.4, D1 + 3.8, 38.0), PI * 0.75, "REFEITÓRIO")

	# ---- corredor de serviço (com extensão anômala)
	_corridor(root, "Servico", true, 18.0, 30.0, 15.0, 3.0, D1, 3.0, "servico", "CORREDOR DE SERVIÇO")
	var ext := Node3D.new()
	ext.name = "Servico_Extensao"
	ext.visible = false
	ext.set_meta(Batcher.META_PROPRIO, true)
	root.add_child(ext)
	_corridor(ext, "ServicoExt", true, 30.0, 42.0, 15.0, 3.0, D1, 3.0, "", "", [], 3)
	var false_wall := G3D.box(root, Vector3(0.3, 3.0, 3.0), Vector3(30.0, D1 + 1.5, 15.0), Mats.get_mat("wall"), true, Vector3.ZERO, "parede_falsa")
	Director.register_extendable({"node": ext, "false_wall": false_wall})

	# ---- câmeras e lifts
	StationKit.camera_fixture(root, "cam_02", "CAM-02 ANEL NORTE", Vector3(-16.2, D1 + 3.0, -16.0), 0.4, "ANEL 1")
	StationKit.camera_fixture(root, "cam_07", "CAM-07 SETOR LESTE", Vector3(17.8, D1 + 3.0, 16.0), -2.2, "ANEL 1", true)
	Director.register_poi("anel_norte", Vector3(0, D1, -16))
	Director.register_poi("anel_leste", Vector3(16, D1, 4))
	Director.register_poi("corredor_leste", Vector3(16, D1, 8))
	Director.register_poi("anel_oeste", Vector3(-16, D1, 2))
	var lift_a := StationKit.lift(root, LIFT_A_BOTTOM, LIFT_A_TOP, Vector3(2.5, 0.3, 2.5),
			Vector3(-2.9, 0.0, -0.1), "MONTACARGA — CONVES 2", Vector3(1, 0, 0))
	Director.register_prop(lift_a["platform"])
	Director.register_poi("lift_a", LIFT_A_BOTTOM + Vector3(-2.4, 0, 0))
	Director.safe_spawn_pos = Vector3(0, D1 + 0.6, -22.0)


static func _k9_capsule(root: Node3D, pos: Vector3, yaw: float) -> void:
	var g := Node3D.new()
	g.position = pos
	g.rotation.y = yaw
	root.add_child(g)
	G3D.cyl(g, 1.5, 4.6, Vector3(0, 1.6, 0), Mats.get_mat("metal"), Vector3(PI * 0.5, 0, 0), true)
	G3D.cyl(g, 1.5, 1.4, Vector3(0, 1.6, -2.9), Mats.get_mat("metal_rust"), Vector3(PI * 0.5, 0, 0), true)
	G3D.cyl(g, 0.6, 0.6, Vector3(0, 1.6, -3.8), Mats.get_mat("metal"), Vector3(PI * 0.5, 0, 0), false)
	for i in 4:
		var ang := TAU * float(i) / 4.0 + PI * 0.25
		G3D.box(g, Vector3(0.18, 1.1, 0.18), Vector3(sin(ang) * 1.1, 0.55, cos(ang) * 1.1), Mats.get_mat("metal_rust"), true)
	G3D.box(g, Vector3(2.4, 0.4, 1.2), Vector3(0, 3.9, 0.4), Mats.get_mat("metal"), false, Vector3.ZERO, "asa")
	G3D.label3d(g, "KEPLER-9", Vector3(0, 2.6, 2.3), 0.0, 0.008, Color(0.75, 0.82, 0.86))
	# escotilha com o terminal pessoal e a foto do jogador
	var hatch := Interactable.create("Abrir escotilha da KEPLER-9", Vector3(1.4, 1.8, 1.2), Vector3(0, 1.4, 2.6),
			func(_p: Node3D, _i: Interactable) -> void:
				UI.open_docs(["foto_02"], "COMPARTIMENTO PESSOAL — K-9")
				AudioMan.play_3d("clank", g.global_position, -10.0))
	g.add_child(hatch)
	var light := OmniLight3D.new()
	light.light_color = Color(0.95, 0.75, 0.45)
	light.light_energy = 0.5
	light.omni_range = 8.0
	light.position = Vector3(0, 2.0, 3.0)
	g.add_child(light)


static func _hydroponics(parent: Node3D, pos: Vector3) -> void:
	var g := Node3D.new()
	g.position = pos
	parent.add_child(g)
	G3D.box(g, Vector3(4.0, 0.8, 1.2), Vector3(0, 0.5, 0), Mats.get_mat("metal"), true, Vector3.ZERO, "canteiro")
	for i in 8:
		G3D.box(g, Vector3(0.1, 0.5, 0.1), Vector3(-1.7 + float(i) * 0.48, 1.1, 0.0), Mats.get_mat("plant"), false)
	var l := OmniLight3D.new()
	l.light_color = Color(0.55, 1.0, 0.6)
	l.light_energy = 0.9
	l.omni_range = 6.0
	l.position = Vector3(0, 2.2, 0)
	g.add_child(l)
	Director.register_light(l)


# ================================================================ CONVÉS 2
static func _build_deck2(root: Node3D) -> void:
	_ring(root, D2, 3.4, [
		{"side": "n", "at": 0.0, "w": 1.8, "h": 2.3, "type": "door", "id": "lab", "name": "LABORATÓRIOS", "auto": true},
		{"side": "e", "at": 0.0, "w": 2.0, "h": 2.4, "type": "door", "id": "eng", "name": "ENGENHARIA", "auto": true},
		{"side": "s", "at": 0.0, "w": 1.8, "h": 2.2, "type": "door", "id": "med", "name": "ENFERMARIA", "auto": true},
		{"side": "w", "at": 0.0, "w": 1.8, "h": 2.2, "type": "door", "id": "radio", "name": "RÁDIO", "auto": true},
	])
	# ---- LABORATÓRIOS
	_mk(root, "Laboratorios", -14.0, -38.0, 14.0, -18.0, D2, 3.6, {
		"name": "Laboratorios",
		"wall": Mats.get_mat("wall"),
		"floor": Mats.get_mat("floor_plate"),
		"skip_walls": ["s"],
		"lamps": _lamp_row(true, -12.0, 12.0, -28.0, 3, false, 0.25),
	}, "lab", "LABORATÓRIOS DE XENOBIOLOGIA")
	StationKit.console(root, Vector3(-10.0, D2, -21.0), 0.0, "terminal",
			{"docs": ["lab_note_01", "xeno_proto_7", "mirror_proto"], "title": "ESTAÇÃO DE ANÁLISE"})
	# mesa de exames
	G3D.box(root, Vector3(2.2, 0.85, 1.1), Vector3(-8.0, D2 + 0.42, -30.0), Mats.get_mat("metal"), true, Vector3.ZERO, "mesa_exame")
	StationKit.stain(root, Vector3(-8.0, D2, -28.6), Vector2(2.0, 1.0), true)
	Director.register_poi("lab_mesa", Vector3(-8.0, D2 + 0.9, -30.0))
	StationKit.console(root, Vector3(10.0, D2, -30.0), PI * 0.25, "sample", {"needs_power": true})
	StationKit.shelf(root, Vector3(0.0, D2, -37.4), 0.0, 9)
	StationKit.camera_fixture(root, "cam_04", "CAM-04 LABORATÓRIOS", Vector3(-13.4, D2 + 3.2, -36.0), PI * 0.3, "LABORATÓRIOS")

	# ---- ENGENHARIA
	_mk(root, "Engenharia", 18.0, -12.0, 38.0, 12.0, D2, 4.0, {
		"name": "Engenharia",
		"wall": Mats.get_mat("wall_dark"),
		"floor": Mats.get_mat("floor_plate"),
		"skip_walls": ["w"],
		"pipes": true,
		# duas fileiras: a sala tem 20 m de largura e paredes escuras — uma só
		# deixava as laterais no breu mesmo com a força ligada
		"lamps": _lamp_row(false, -10.0, 10.0, 24.0, 3, false, 0.3) + _lamp_row(false, -10.0, 10.0, 33.0, 3, false, 0.3),
	}, "engenharia", "ENGENHARIA — REATOR E CIRCUITOS")
	G3D.cyl(root, 2.2, 4.0, Vector3(34.0, D2 + 2.0, 0.0), Mats.get_mat("metal_rust"))
	for i in 3:
		G3D.cyl(root, 0.25, 3.4, Vector3(24.0 + float(i) * 1.4, D2 + 1.7, -9.0), Mats.get_mat("metal"))
	StationKit.console(root, Vector3(22.0, D2, 6.0), -PI * 0.5, "power", {"needs_power": false})
	StationKit.console(root, Vector3(30.0, D2, -10.0), 0.0, "terminal",
			{"docs": ["casa_maquinas_log"], "title": "REGISTRO DA CASA DE MÁQUINAS"})
	# ponto de recarga de bateria e O2
	var charger := Interactable.create("Recarregar traje (bateria e O2)", Vector3(1.6, 1.6, 1.2), Vector3(26.0, D2 + 0.9, 10.0),
			func(_p: Node3D, _i: Interactable) -> void:
				GameState.battery = 1.0
				GameState.o2 = 1.0
				GameState.battery_changed.emit(1.0)
				GameState.o2_changed.emit(1.0)
				AudioMan.play_3d("power", Vector3(26.0, D2, 10.0), -8.0)
				UI.show_note("TRAJE RECARREGADO", "Bateria e oxigênio em 100%. O compressor faz um som que lembra respiração."))
	root.add_child(charger)
	StationKit.camera_fixture(root, "cam_05", "CAM-05 ENGENHARIA", Vector3(19.0, D2 + 3.4, 11.0), -0.7, "ENGENHARIA")
	G3D.sign(root, "REATOR PRINCIPAL\nCIRCUITO DE EMERGÊNCIA ATIVO", Vector3(36.0, D2 + 2.6, -6.0), -PI * 0.5, 40, Color(0.9, 0.6, 0.3))

	# ---- ENFERMARIA
	_mk(root, "Enfermaria", -12.0, 18.0, 12.0, 36.0, D2, 3.4, {
		"name": "Enfermaria",
		"wall": Mats.get_mat("tile_wall"),
		"skip_walls": ["n"],
		"lamps": _lamp_row(true, -10.0, 10.0, 27.0, 3, false, 0.25),
	}, "enfermaria", "ENFERMARIA")
	StationKit.bed(root, Vector3(-6.0, D2, 24.0), 0.0, "LEITO 1")
	StationKit.bed(root, Vector3(6.0, D2, 24.0), 0.0, "LEITO 2")
	StationKit.console(root, Vector3(0.0, D2, 33.0), PI, "terminal",
			{"docs": ["med_rep_01", "med_rep_02"], "title": "TERMINAL CLÍNICO"})
	var o2 := Interactable.create("Reabastecer oxigênio", Vector3(1.4, 1.6, 1.2), Vector3(-11.0, D2 + 1.0, 33.0),
			func(_p: Node3D, _i: Interactable) -> void:
				GameState.o2 = 1.0
				GameState.o2_changed.emit(1.0)
				AudioMan.play_3d("power", Vector3(-11.0, D2, 33.0), -10.0)
				UI.show_note("OXIGÊNIO", "Reserva completa. O ar aqui dentro tem um gosto levemente adocicado."))
	root.add_child(o2)
	Director.safe_spawn_pos = Vector3(0, D2 + 0.6, 30.0)
	StationKit.camera_fixture(root, "cam_06", "CAM-06 ENFERMARIA", Vector3(11.4, D2 + 3.0, 34.0), PI * 0.8, "ENFERMARIA")

	# ---- RÁDIO / COMUNICAÇÕES
	_mk(root, "Radio", -38.0, -10.0, -18.0, 10.0, D2, 3.4, {
		"name": "Radio",
		"wall": Mats.get_mat("wall_dark"),
		"skip_walls": ["e"],
		"pipes": true,
		"lamps": _lamp_row(false, -8.0, 8.0, -28.0, 3, false, 0.25),
	}, "radio", "SALA DE COMUNICAÇÕES")
	StationKit.console(root, Vector3(-30.0, D2, -8.0), 0.0, "radio",
			{"signals": ["terra_1", "terra_2", "sal_1", "nadia_1", "tomas_1", "voz_extra"]})
	StationKit.console(root, Vector3(-30.0, D2, 8.0), PI, "terminal",
			{"docs": ["ops_comm_01"], "title": "TRANSCRIÇÕES DE COMUNICAÇÃO"})
	StationKit.crates(root, Vector3(-34.0, D2, 2.0), 3)
	Director.register_poi("radio", Vector3(-30, D2, 0))

	var lift_b := StationKit.lift(root, LIFT_B_BOTTOM, LIFT_B_TOP, Vector3(2.5, 0.3, 2.5),
			Vector3(-1.6, 0.0, 0.0), "MONTACARGA — CONVES 3", Vector3(0, 0, -1))
	Director.register_prop(lift_b["platform"])
	Director.register_poi("lift_b", LIFT_B_BOTTOM + Vector3(-1.6, 0, 0))


# ================================================================ CONVÉS 3
static func _build_deck3(root: Node3D) -> void:
	_ring(root, D3, 3.4, [
		{"side": "n", "at": 0.0, "w": 2.0, "h": 2.4, "type": "door", "id": "comando", "name": "COMANDO", "auto": true},
		{"side": "s", "at": 0.0, "w": 1.8, "h": 2.2, "type": "door", "id": "sino", "name": "CÂMARA DO SINO", "auto": true},
		{"side": "e", "at": 0.0, "w": 2.0, "h": 2.4, "type": "open", "id": "obs_cor", "name": "OBSERVAÇÃO"},
		{"side": "w", "at": 0.0, "w": 1.8, "h": 2.2, "type": "door", "id": "eclusa", "name": "ECLUSA", "auto": true, "locked": true, "lock_reason": "PRESSÃO EXTERNA", "key": "chave_eng"},
	])
	# ---- COMANDO
	_mk(root, "Comando", -14.0, -34.0, 14.0, -18.0, D3, 4.2, {
		"name": "Comando",
		"wall": Mats.get_mat("wall"),
		"skip_walls": ["s"],
		"lamps": _lamp_row(true, -12.0, 12.0, -26.0, 3, false, 0.3),
	}, "comando", "COMANDO CENTRAL")
	_sal5_core(root, Vector3(0.0, D3, -31.0))
	StationKit.console(root, Vector3(-9.0, D3, -20.0), 0.0, "terminal",
			{"docs": ["ops_manifest", "caderno_tomas"], "title": "MESA DE OPERAÇÕES"})
	StationKit.console(root, Vector3(-4.0, D3, -20.0), 0.0, "terminal",
			{"docs": ["log_final_iris"], "title": "TERMINAL PESSOAL — I. VALE"})
	StationKit.console(root, Vector3(9.0, D3, -20.0), 0.0, "cctv", {})
	StationKit.console(root, Vector3(4.0, D3, -20.0), 0.0, "terminal",
			{"docs": ["cam_log_11"], "title": "MONITOR DE CÂMERAS — CAM-07"})
	StationKit.console(root, Vector3(0.0, D3, -20.5), 0.0, "code",
			{"prompt": "SALA SEGURA — CÓDIGO", "code": "1104",
			 "on_success": func() -> void:
				GameState.set_flag("cofre_aberto")
				UI.show_note("SALA SEGURA", "Armário de emergência aberto. Dentro: um cartão de engenharia e uma gravação.")
				GameState.set_flag("chave_eng")})
	StationKit.camera_fixture(root, "cam_06b", "CAM-08 COMANDO", Vector3(-13.4, D3 + 3.6, -32.0), 0.35, "COMANDO")
	Director.register_poi("comando", Vector3(0, D3, -24))

	# ---- CÂMARA DO SINO
	_mk(root, "Sino", -8.0, 18.0, 8.0, 32.0, D3, 3.2, {
		"name": "Sino",
		"wall": Mats.get_mat("metal_rust"),
		"skip_walls": ["n"],
		"pipes": true,
		"lamps": _lamp_row(true, -6.0, 6.0, 25.0, 2, true, 0.2),
	}, "sino", "CÂMARA DO SINO — CASCO INFERIOR")
	var bell := G3D.cyl(root, 1.6, 0.35, Vector3(0, D3 + 0.2, 25.0), Mats.get_mat("metal"), Vector3.ZERO, true)
	G3D.cyl(root, 0.22, 3.0, Vector3(0, D3 + 1.7, 25.0), Mats.get_mat("metal_rust"))
	for i in 6:
		var ang := TAU * float(i) / 6.0
		G3D.box(root, Vector3(0.12, 0.12, 2.6), Vector3(sin(ang) * 1.2, D3 + 3.1, 25.0 + cos(ang) * 1.2), Mats.get_mat("metal"), false, Vector3(0, ang, 0), "cabo")
	StationKit.tape_player(root, Vector3(6.0, D3, 30.0), PI, "fita_2", "")
	StationKit.console(root, Vector3(-6.0, D3, 30.0), PI, "terminal",
			{"docs": ["casa_maquinas_log"], "title": "REGISTRO DE ACÚSTICA"})
	StationKit.camera_fixture(root, "cam_07b", "CAM-09 SINO", Vector3(7.4, D3 + 2.8, 30.0), -2.4, "SINO")
	Director.bell_pos = Vector3(0, D3 + 0.4, 25.0)
	Director.register_poi("camara_sino", Vector3(0, D3, 27))
	Director.register_poi("sino", Vector3(0, D3, 25))

	# ---- ECLUSA INFERIOR (a oeste do anel, despressurizada)
	_mk(root, "Eclusa", -40.0, -8.0, -18.0, 8.0, D3, 3.4, {
		"name": "Eclusa",
		"wall": Mats.get_mat("metal_rust"),
		"skip_walls": ["e"],
		"pipes": true,
		"lamps": _lamp_row(false, -6.0, 6.0, -32.0, 3, true, 0.18),
	}, "eclusa", "ECLUSA INFERIOR — SETOR DESPRESSURIZADO")
	StationKit.console(root, Vector3(-36.0, D3, 6.0), -PI * 0.5, "photo", {"doc": "eclusa_warning"})
	G3D.cyl(root, 2.6, 0.6, Vector3(-36.0, D3 + 0.3, 0.0), Mats.get_mat("metal_rust"), Vector3.ZERO, true)
	G3D.sign(root, "ESCOTILHA INFERIOR\nACESSO RESTRITO", Vector3(-36.0, D3 + 2.4, -2.6), 0.0, 34, Color(0.9, 0.4, 0.3))
	G3D.hazard_stripe(root, false, Vector3(-36.0, D3, -3.4), 5.0, 0.35)
	Director.register_poi("eclusa", Vector3(-30, D3, 0))

	# ---- CORREDOR DE OBSERVAÇÃO (até a porta do módulo)
	_mk(root, "CorredorObs", 18.0, -2.4, 36.0, 2.4, D3, 3.2, {
		"name": "CorredorObs",
		"floor": Mats.get_mat("floor_grating"),
		"wall": Mats.get_mat("wall"),
		"skip_walls": ["w", "e"],
		"pipes": true,
		"doors": [{"side": "n", "at": 26.0, "w": 1.7, "h": 2.2, "type": "door", "id": "selada",
				   "name": "MÓDULO DE OBSERVAÇÃO", "auto": false, "locked": true,
				   "lock_reason": "SELADO POR DENTRO"}],
		"ceil_holes": [{"x1": 32.5, "z1": -1.7, "x2": 35.7, "z2": 1.7}],
		"lamps": _lamp_row(true, 19.0, 35.0, 0.0, 5, true),
	}, "corredor_obs", "CORREDOR DE OBSERVAÇÃO")
	# por trás da porta selada: chapa soldada (o módulo foi isolado por dentro)
	G3D.box(root, Vector3(2.2, 2.5, 0.18), Vector3(26.0, D3 + 1.25, -2.05), Mats.get_mat("metal_rust"), true, Vector3.ZERO, "chapa_soldada")
	G3D.label3d(root, "SOLDADO POR DENTRO - SEM ACESSO", Vector3(26.0, D3 + 2.0, -1.55), PI, 0.0045, Color(0.85, 0.5, 0.35))
	StationKit.camera_fixture(root, "cam_08", "CAM-10 CORREDOR OBS.", Vector3(19.5, D3 + 2.8, -1.2), 1.2, "OBSERVAÇÃO")
	StationKit.shaft_marks(root, 34.1, 0.0, 3.2, D3)
	Director.register_poi("corredor_obs", Vector3(26, D3, 0))
	var lift_c := StationKit.lift(root, LIFT_C_BOTTOM, LIFT_C_TOP, Vector3(2.5, 0.3, 2.5),
			Vector3(-2.7, 0.0, -1.2), "MONTACARGA — OBSERVACAO", Vector3(-1, 0, 0))
	Director.register_prop(lift_c["platform"])
	Director.register_poi("lift_c", LIFT_C_BOTTOM + Vector3(-2.4, 0, 0))


static func _sal5_core(root: Node3D, pos: Vector3) -> void:
	var g := Node3D.new()
	g.position = pos
	root.add_child(g)
	G3D.cyl(g, 1.1, 4.0, Vector3(0, 2.0, 0), Mats.get_mat("metal"), Vector3.ZERO, true)
	var core := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.75
	cm.bottom_radius = 0.75
	cm.height = 2.6
	core.mesh = cm
	core.material_override = Mats.get_mat("screen")
	core.position = Vector3(0, 2.0, 0)
	g.add_child(core)
	var l := OmniLight3D.new()
	l.light_color = Color(0.35, 0.95, 0.7)
	l.light_energy = 1.1
	l.omni_range = 12.0
	l.position = Vector3(0, 2.0, 0)
	g.add_child(l)
	Director.register_light(l)
	G3D.label3d(g, "SAL-5", Vector3(0, 4.3, 0), 0.0, 0.008, Color(0.5, 0.95, 0.75))
	var inter := Interactable.create("Falar com SAL-5", Vector3(2.0, 2.4, 2.0), Vector3(0, 1.6, 1.6),
			func(_p: Node3D, _i: Interactable) -> void:
				UI.say([
					{"who": "SAL-5", "text": "K-9. Estou registrando você desde a docagem.", "dur": 3.6},
					{"who": "SAL-5", "text": "Dois tripulantes me perguntaram, no último dia, se eu acreditava estar sozinha.", "dur": 4.6},
					{"who": "SAL-5", "text": "Eu respondi que sou uma inteligência de bordo e não possuo crenças.", "dur": 4.0},
					{"who": "SAL-5", "text": "...Eu manti o registro desta resposta como «falsa».", "dur": 4.0},
				], "sal_01")
				GameState.unlock("e_sal5")
				GameState.set_flag("falou_sal5"))
	g.add_child(inter)


# ================================================================ CONVÉS 4
static func _build_deck4(root: Node3D) -> void:
	# antecâmara: onde o monta-carga chega, ligada ao módulo por uma passagem
	_mk(root, "Antessala", 14.0, -6.0, 36.0, 6.0, D4, 3.2, {
		"name": "Antessala",
		"wall": Mats.get_mat("wall_dark"),
		"skip_walls": ["w"],
		"pipes": true,
		"floor_holes": [HOLE_C],
		"lamps": _lamp_row(true, 16.0, 34.0, 0.0, 4, false, 0.25),
	}, "antessala", "ANTECÂMARA DO MÓDULO DE OBSERVAÇÃO")
	# moldura da passagem: batentes laterais + verga (o vão fica livre para passar)
	G3D.box(root, Vector3(0.5, 3.2, 0.45), Vector3(14.0, D4 + 1.6, -1.4), Mats.get_mat("wall_dark"), true, Vector3.ZERO, "batente")
	G3D.box(root, Vector3(0.5, 3.2, 0.45), Vector3(14.0, D4 + 1.6, 1.4), Mats.get_mat("wall_dark"), true, Vector3.ZERO, "batente")
	G3D.box(root, Vector3(0.5, 0.5, 2.8), Vector3(14.0, D4 + 2.45, 0.0), Mats.get_mat("wall_dark"), true, Vector3.ZERO, "verga")
	StationKit.shaft_marks(root, 34.1, 0.0, 3.2, D4)
	StationKit.camera_fixture(root, "cam_10", "CAM-12 ANTECÂMARA", Vector3(35.4, D4 + 2.8, 5.4), -2.4, "ANTECÂMARA")
	Director.register_poi("antessala", Vector3(24, D4, 0))
	var r := _mk(root, "Observatorio", -14.0, -6.0, 14.0, 20.0, D4, 6.0, {
		"name": "Observatorio",
		"wall": Mats.get_mat("wall_dark"),
		"floor": Mats.get_mat("floor"),
		"doors": [{"side": "e", "at": 0.0, "w": 2.4, "h": 2.6, "type": "open"}],
		"windows": [{"side": "s", "at": 0.0, "w": 20.0, "h": 5.0, "base": 0.5, "type": "big"}],
		"lamps": [{"pos": Vector2(-8, -2.0), "along_x": true, "emergency": true, "energy": 0.22},
				  {"pos": Vector2(8, -2.0), "along_x": true, "emergency": true, "energy": 0.22}],
	}, "observacao", "MÓDULO DE OBSERVAÇÃO")
	G3D.sign(root, "PROTOCOLO ESPELHO — VOLUNTÁRIO ÚNICO\n72 HORAS DE ESTÍMULO REDUZIDO", Vector3(0, D4 + 3.4, -5.6), 0.0, 34, Color(0.6, 0.85, 0.95))
	# poltrona do protocolo
	G3D.box(root, Vector3(1.2, 0.5, 2.2), Vector3(0, D4 + 0.25, 4.0), Mats.get_mat("metal"), true, Vector3.ZERO, "poltrona")
	G3D.box(root, Vector3(1.2, 1.0, 0.2), Vector3(0, D4 + 0.9, 5.0), Mats.get_mat("fabric"), false, Vector3.ZERO, "encosto")
	for i in 4:
		G3D.cyl(root, 0.06, 2.0, Vector3(-1.4 + float(i) * 0.9, D4 + 1.9, 2.0), Mats.get_mat("rubber"), Vector3.ZERO, false)
	StationKit.console(root, Vector3(-11.0, D4, 8.0), 0.0, "terminal",
			{"docs": ["obs_log_1", "mirror_proto"], "title": "CONSOLE DO PROTOCOLO ESPELHO"})
	# console final: o ECHO
	var echo := StationKit.console(root, Vector3(11.0, D4, 8.0), PI * 0.0, "custom", {
		"prompt": "Usar console ECHO — responder ao oceano",
		"on_use": func(_g: Node3D) -> void:
			if GameState.decision("final") != "":
				UI.show_note("ECHO", "Você já respondeu. Nada mais será acrescentado.")
				return
			UI.ask_decision("final")})
	StationKit.camera_fixture(root, "cam_09", "CAM-11 OBSERVAÇÃO", Vector3(-13.4, D4 + 4.6, -5.0), 0.6, "OBSERVAÇÃO")
	G3D.box(root, Vector3(3.0, 0.06, 1.2), Vector3(0, D4 + 0.8, 14.0), Mats.get_mat("metal"), true, Vector3.ZERO, "bancada")
	Director.register_poi("observatorio", Vector3(0, D4, 10))
	Director.register_poi("observatorio_janela", Vector3(0, D4 + 2.5, 19.4))
