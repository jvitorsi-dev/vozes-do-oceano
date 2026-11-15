class_name Dressing
extends RefCounted
## Vestimenta da estação: distribui o kit de detalhes por cada setor.
##
## Chamado uma vez, depois que a geometria existe. Nada aqui tem colisor de
## caminho: é para o olho e para o ar da estação (tubulação, cabo, sujeira,
## vapor, poeira, luz de trabalho). Referência: Dead Space + manutenção
## soviética — tudo funcional, tudo remendado, nada decorativo de propósito.

const D1 := 40.0
const D2 := 52.0
const D3 := 64.0
const D4 := 76.0


static func vestir(raiz: Node3D) -> void:
	# tudo pendurado num galho só: fica fácil medir e aglutinar depois
	var root := Node3D.new()
	root.name = "Vestimenta"
	raiz.add_child(root)
	var rng := RandomNumberGenerator.new()
	rng.seed = 20240923
	_anel(root, D1, 3.4, 2024001)
	_anel(root, D2, 3.4, 2024002)
	_anel(root, D3, 3.4, 2024003)
	_hangar(root)
	_deposito(root)
	_cabines(root)
	_refeitorio(root)
	_laboratorios(root)
	_engenharia(root)
	_enfermaria(root)
	_radio(root)
	_comando(root)
	_sino(root)
	_eclusa(root)
	_corredor_obs(root)
	_antessala(root)
	_observatorio(root)


# ================================================================ ANEL (corredores)
## O anel é o que o jogador mais percorre: aqui a densidade é máxima —
## tubulação no teto acompanhando o corredor, bandeja de cabos, caixas de
## junção, grades, luminárias de trabalho e o piso marcado de passagem.
static func _anel(root: Node3D, y: float, h: float, seed_v: int) -> void:
	var yteto := y + h - 0.35
	# quatro lados do anel (corredor de 4 m entre o núcleo e a parede externa)
	var lados := [
		{"a": Vector3(-16.6, yteto, -13.5), "b": Vector3(-16.6, yteto, 13.5), "parede_yaw": PI * 0.5, "px": -17.6},
		{"a": Vector3(16.6, yteto, -13.5), "b": Vector3(16.6, yteto, 13.5), "parede_yaw": PI * 0.5, "px": 17.6},
		{"a": Vector3(-13.5, yteto, -16.6), "b": Vector3(13.5, yteto, -16.6), "parede_yaw": 0.0, "px": -17.6},
		{"a": Vector3(-13.5, yteto, 16.6), "b": Vector3(13.5, yteto, 16.6), "parede_yaw": 0.0, "px": 17.6},
	]
	var i := 0
	for lado: Dictionary in lados:
		var a: Vector3 = lado["a"]
		var b: Vector3 = lado["b"]
		# tubulação principal correndo o anel inteiro pelo teto
		Detail.pipe_run(root, a + Vector3(0, 0.30, 0), b + Vector3(0, 0.30, 0), 3, 0.095, true, seed_v + i * 13)
		Detail.pipe_run(root, a + Vector3(0, 0.62, 0), b + Vector3(0, 0.62, 0), 2, 0.055, false, seed_v + i * 17)
		# bandeja de cabos do outro lado do corredor
		var perp := Vector3(0, 0, 1) if absf(b.x - a.x) < 0.1 else Vector3(1, 0, 0)
		Detail.cable_tray(root, a - perp * 3.2 + Vector3(0, 0.45, 0), b - perp * 3.2 + Vector3(0, 0.45, 0), seed_v + i * 7, 5)
		# vigas em I atravessando o corredor
		Detail.i_beam(root, a - perp * 2.0 + Vector3(0, 0.2, 0), a + perp * 0.6 + Vector3(0, 0.2, 0), 0.24)
		var n := 5
		for k in n:
			var t := (float(k) + 0.5) / float(n)
			var p: Vector3 = a.lerp(b, t)
			var off := perp * rng_d(seed_v + k, 1.9, 2.6)
			var s := perp * rng_d(seed_v + k + 40, 2.2, 2.9)
			match (i + k) % 5:
				0:
					Detail.junction_box(root, p + s + Vector3(0, -0.9, 0), float(lado["parede_yaw"]), (k % 2 == 0))
				1:
					Detail.louver(root, p + s + Vector3(0, -0.55, 0), float(lado["parede_yaw"]), 0.85, 0.5)
				2:
					Detail.gauge_panel(root, p + s + Vector3(0, -0.95, 0), float(lado["parede_yaw"]), 3, seed_v + k)
				3:
					Detail.conduit(root, p + s + Vector3(0, 0.9, 0), p + s + Vector3(0, 0.9, 0) + (perp * 3.4),
						seed_v + k)
				4:
					Detail.breaker_panel(root, p + off + Vector3(0, -1.2, 0), float(lado["parede_yaw"]))
			# luminária de trabalho pendurada, uma piscando
			if (i * n + k) % 3 == 0:
				Detail.work_lamp(root, p + off + Vector3(0, -(h * 0.5) + 0.9, 0),
					Color(1.0, 0.74, 0.42) if (i + k) % 2 == 0 else Color(0.72, 0.84, 1.0),
					1.0, 7.5, 0.45, 1.0 if (k % 2 == 1) else 0.0)
			# sujeira no piso por onde todo mundo anda
			Decals.dress_floor(root, p.x - 1.6, p.z - 1.6, p.x + 1.6, p.z + 1.6, y, 2, seed_v + k * 3, k == 0)
		# escadas de gato em dois pontos do anel
		if i < 2:
			Detail.ladder(root, Vector3(a.x + (2.0 if i == 0 else -2.0), y, a.z - 2.0 * signf(a.z) - 1.2 * perp.z),
				float(lado["parede_yaw"]), h - 0.4, true)
		i += 1
	# marcas de piso: faixa de circulação em volta do núcleo
	for z: float in [-14.35, 14.35]:
		Decals.floor_mark(root, "stripes", Vector3(0, y + 0.04, z), 0.0, Vector2(24.0, 0.55),
			Color(0.80, 0.66, 0.14, 0.5))
	for x: float in [-14.35, 14.35]:
		Decals.floor_mark(root, "stripes", Vector3(x, y + 0.04, 0), PI * 0.5, Vector2(24.0, 0.55),
			Color(0.80, 0.66, 0.14, 0.5))


static func rng_d(seed_v: int, low: float, high: float) -> float:
	var r := RandomNumberGenerator.new()
	r.seed = seed_v
	return r.randf_range(low, high)


# ================================================================ HANGAR
static func _hangar(root: Node3D) -> void:
	var y := D1
	# vigas mestras atravessando o vão
	for i in 4:
		var z := -20.0 - float(i) * 7.0
		Detail.i_beam(root, Vector3(-15.4, y + 6.2, z), Vector3(15.4, y + 6.2, z), 0.42)
	# pórtico rolante acima da área de carga
	Detail.i_beam(root, Vector3(-15.4, y + 5.0, -34.0), Vector3(15.4, y + 5.0, -34.0), 0.5)
	G3D.box(root, Vector3(0.7, 0.7, 1.4), Vector3(-6.0, y + 4.6, -34.0), Mats.get_mat("metal_rust"), false, Vector3.ZERO, "carro_portico")
	Detail._cil(root, 0.05, 2.6, Vector3(-6.0, y + 3.2, -34.0), Mats.get_mat("metal"), Vector3.ZERO, false)
	G3D.box(root, Vector3(0.7, 0.6, 0.7), Vector3(-6.0, y + 1.9, -34.0), Mats.get_mat("hazard"), false, Vector3.ZERO, "gancho")
	# tubulação e bandejas pelas laterais
	Detail.pipe_run(root, Vector3(-15.2, y + 5.6, -44.0), Vector3(-15.2, y + 5.6, -19.0), 4, 0.13, true, 511, true)
	Detail.pipe_run(root, Vector3(15.2, y + 5.6, -44.0), Vector3(15.2, y + 5.6, -19.0), 3, 0.10, true, 517)
	Detail.cable_tray(root, Vector3(13.4, y + 5.2, -43.0), Vector3(13.4, y + 5.2, -20.0), 523, 7)
	Detail.cable_tray(root, Vector3(-13.4, y + 4.8, -43.0), Vector3(-13.4, y + 4.8, -20.0), 529, 5)
	# equipamento de parede: quadro de força, armários, extintores, bancada
	Detail.breaker_panel(root, Vector3(-15.5, y + 1.5, -28.0), PI * 0.5, 541)
	Detail.locker_bank(root, Vector3(-15.0, y, -24.4), PI * 0.5, 3, 547)
	Detail.locker_bank(root, Vector3(15.0, y, -30.0), -PI * 0.5, 2, 557)
	Detail.workbench(root, Vector3(12.0, y, -20.6), PI * 1.0, 563)
	Detail.louver(root, Vector3(-15.6, y + 3.4, -34.0), PI * 0.5, 1.1, 0.7)
	Detail.louver(root, Vector3(15.6, y + 3.4, -34.0), -PI * 0.5, 1.1, 0.7)
	Detail.gauge_panel(root, Vector3(-8.0, y + 1.6, -45.4), 0.0, 4, 571)
	# vapor escapando de uma tubulação e poeira no feixe de luz
	Detail.steam_vent(root, Vector3(-11.0, y + 0.3, -42.0), PI * 0.5, 0.8)
	Detail.steam_vent(root, Vector3(12.5, y + 0.3, -35.0), -PI * 0.5, 0.6)
	Detail.dust(root, Vector3(0, y, -30.0), 12.0, 5.0, 130)
	# poças grandes (o hangar tem condensação) e marcas de piso
	Detail.puddle(root, Vector3(-6.5, y, -27.0), 2.2, 601)
	Detail.puddle(root, Vector3(7.0, y, -37.0), 1.8, 607)
	Decals.dress_floor(root, -14.0, -44.0, 14.0, -20.0, y, 12, 613, false)
	Decals.floor_mark(root, "frame", Vector3(0, y + 0.04, -34.0), 0.0, Vector2(9.0, 7.0),
		Color(0.82, 0.68, 0.16, 0.45))
	Decals.floor_mark(root, "arrow", Vector3(-9.0, y + 0.04, -22.0), PI, Vector2(2.6, 2.6),
		Color(0.80, 0.66, 0.14, 0.5))
	Decals.dress_wall(root, Vector3(-15.9, y + 2.6, -38.0), PI * 0.5, 12.0, 4.0, 617)
	Decals.dress_wall(root, Vector3(15.9, y + 2.6, -30.0), -PI * 0.5, 12.0, 4.0, 619)


# ================================================================ DEPÓSITO
static func _deposito(root: Node3D) -> void:
	var y := D1
	# estantes altas e caixotes em pilha (o depósito é apertado de propósito)
	StationKit.shelf(root, Vector3(-37.0, y, -6.0), PI * 0.5, 7)
	StationKit.shelf(root, Vector3(-37.0, y, 2.0), PI * 0.5, 7)
	StationKit.crates(root, Vector3(-24.0, y, -7.0), 5)
	StationKit.crates(root, Vector3(-28.0, y, 6.0), 4)
	# tambores com argolas
	for i in 5:
		barrel(root, Vector3(-33.0 + float(i) * 0.9, y, -8.6), 531 + i)
	# tubulação no teto, bem castigada
	Detail.pipe_run(root, Vector3(-39.0, y + 2.95, -8.0), Vector3(-19.0, y + 2.95, -8.0), 4, 0.11, true, 701, true)
	Detail.pipe_run(root, Vector3(-39.0, y + 2.95, 8.0), Vector3(-19.0, y + 2.95, 8.0), 2, 0.08, false, 707)
	Detail.cable_tray(root, Vector3(-38.0, y + 2.6, 0.0), Vector3(-20.0, y + 2.6, 0.0), 709, 6)
	Detail.junction_box(root, Vector3(-19.4, y + 1.5, -6.0), -PI * 0.5, true)
	Detail.junction_box(root, Vector3(-19.4, y + 1.9, 5.0), -PI * 0.5, false)
	Detail.louver(root, Vector3(-19.6, y + 2.4, -3.0), -PI * 0.5, 0.9, 0.55)
	Detail.work_lamp(root, Vector3(-30.0, y + 2.5, -5.0), Color(1.0, 0.72, 0.40), 0.95, 7.0, 0.6, 1.0)
	Detail.work_lamp(root, Vector3(-26.0, y + 2.5, 6.0), Color(0.75, 0.85, 1.0), 0.85, 6.5, 0.6, 0.0)
	Detail.dust(root, Vector3(-29.0, y, 0.0), 8.0, 3.0, 70)
	Decals.dress_floor(root, -38.0, -9.0, -20.0, 9.0, y, 10, 711)
	Decals.dress_wall(root, Vector3(-19.1, y + 1.8, -2.0), -PI * 0.5, 14.0, 3.0, 713)
	# marcas de carga no chão
	Decals.floor_mark(root, "frame", Vector3(-30.0, y + 0.04, 0.0), 0.0, Vector2(6.0, 5.0),
		Color(0.78, 0.64, 0.16, 0.4))


static func barrel(parent: Node3D, pos: Vector3, seed_v := 1) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_v
	var g := Node3D.new()
	g.name = "Tambor"
	g.position = pos
	g.rotation.y = rng.randf() * TAU
	parent.add_child(g)
	var sorte := rng.randf()
	var m := Mats.get_mat("metal_rust")
	if sorte > 0.82:
		m = Mats.get_mat("paint_yellow")
	elif sorte > 0.55:
		m = Mats.get_mat("paint_blue")
	elif sorte > 0.38:
		m = Mats.get_mat("paint_olive")
	# tambor de 200 L: corpo com dois frisos rolados, rebordo e tampa rebaixada
	G3D.peca(g, MeshKit.torno(PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(0.275, 0.0), Vector2(0.292, 0.012), Vector2(0.292, 0.03),
		Vector2(0.283, 0.045), Vector2(0.283, 0.27), Vector2(0.297, 0.285), Vector2(0.297, 0.305),
		Vector2(0.283, 0.32), Vector2(0.283, 0.565), Vector2(0.297, 0.58), Vector2(0.297, 0.60),
		Vector2(0.283, 0.615), Vector2(0.283, 0.84), Vector2(0.292, 0.855), Vector2(0.292, 0.88),
		Vector2(0.272, 0.88), Vector2(0.268, 0.862), Vector2(0.0, 0.862),
	]), 18, false, "tambor200"), Vector3.ZERO, m, Vector3.ZERO, Vector3.ONE, "tambor")
	G3D.colisor(g, Vector3(0.5, 0.88, 0.5), Vector3(0, 0.44, 0))
	# bocais da tampa
	Detail._cil(g, 0.045, 0.035, Vector3(0.17, 0.875, 0.0), Mats.get_mat("metal"), Vector3.ZERO, false)
	Detail._cil(g, 0.022, 0.03, Vector3(-0.15, 0.872, 0.08), Mats.get_mat("metal"), Vector3.ZERO, false)
	# etiqueta de conteúdo (faixa de aviso gasta)
	G3D.box(g, Vector3(0.24, 0.12, 0.012), Vector3(0, 0.44, 0.281), Mats.get_mat("hazard"), false, Vector3.ZERO, "etiqueta")


# ================================================================ CABINES
static func _cabines(root: Node3D) -> void:
	var y := D1
	Detail.locker_bank(root, Vector3(19.2, y, -11.4), PI * 0.5, 3, 801)
	Detail.locker_bank(root, Vector3(19.2, y, 5.0), PI * 0.5, 2, 803)
	# tubulação de água e ar pelos cantos (cabines são apertadas)
	Detail.pipe_run(root, Vector3(19.0, y + 3.05, -11.0), Vector3(19.0, y + 3.05, 11.0), 3, 0.075, true, 805)
	Detail.pipe_run(root, Vector3(37.0, y + 3.05, -11.0), Vector3(37.0, y + 3.05, 11.0), 2, 0.06, false, 807)
	Detail.cable_tray(root, Vector3(23.0, y + 2.85, -11.5), Vector3(37.0, y + 2.85, -11.5), 809, 4)
	for i in 3:
		Detail.junction_box(root, Vector3(37.6, y + 1.6, -8.0 + float(i) * 8.0), -PI * 0.5, false)
	for i in 3:
		Detail.louver(root, Vector3(37.6, y + 2.5, -6.0 + float(i) * 6.0), -PI * 0.5, 0.8, 0.5)
	Detail.gauge_panel(root, Vector3(37.6, y + 1.5, 10.5), -PI * 0.5, 2, 811)
	Detail.work_lamp(root, Vector3(28.0, y + 2.6, -3.0), Color(0.78, 0.86, 1.0), 0.8, 6.0, 0.5, 1.0)
	Detail.dust(root, Vector3(28.0, y, 0.0), 9.0, 3.0, 60)
	Decals.dress_floor(root, 19.0, -11.0, 37.0, 11.0, y, 8, 813)
	Decals.dress_wall(root, Vector3(18.1, y + 1.7, 0.0), PI * 0.5, 20.0, 3.0, 815)


# ================================================================ REFEITÓRIO
static func _refeitorio(root: Node3D) -> void:
	var y := D1
	# cozinha de campo ao fundo: bancada longa, exaustão, panelas
	Detail.workbench(root, Vector3(-8.0, y, 37.6), 0.0, 901)
	Detail.workbench(root, Vector3(-2.0, y, 37.6), 0.0, 903)
	Detail.louver(root, Vector3(0.0, y + 3.2, 38.6), PI, 1.4, 0.9)
	Detail.pipe_run(root, Vector3(-11.0, y + 3.7, 36.4), Vector3(11.0, y + 3.7, 36.4), 3, 0.09, true, 905)
	Detail.cable_tray(root, Vector3(-10.0, y + 3.4, 20.0), Vector3(10.0, y + 3.4, 20.0), 907, 5)
	Detail.pipe_run(root, Vector3(-11.6, y + 3.3, 20.0), Vector3(-11.6, y + 3.3, 39.0), 2, 0.07, false, 909)
	Detail.pipe_run(root, Vector3(11.6, y + 3.3, 20.0), Vector3(11.6, y + 3.3, 39.0), 2, 0.07, false, 911)
	Detail.junction_box(root, Vector3(11.6, y + 1.7, 30.0), -PI * 0.5, false)
	Detail.breaker_panel(root, Vector3(-11.6, y + 1.7, 34.0), PI * 0.5, 913)
	Detail.gauge_panel(root, Vector3(11.6, y + 1.6, 24.0), -PI * 0.5, 2, 915)
	Detail.work_lamp(root, Vector3(4.0, y + 3.1, 30.0), Color(1.0, 0.76, 0.45), 0.9, 7.0, 0.6, 1.0)
	Detail.steam_vent(root, Vector3(6.0, y + 0.25, 37.0), -PI * 0.5, 0.5)
	Detail.dust(root, Vector3(0, y, 29.0), 10.0, 3.5, 80)
	# o refeitório é onde mais gente se sentou: piso castigado
	Decals.dress_floor(root, -11.0, 20.0, 11.0, 38.0, y, 12, 917)
	Decals.dress_wall(root, Vector3(-11.9, y + 1.6, 26.0), PI * 0.5, 12.0, 3.4, 919)
	Decals.dress_wall(root, Vector3(11.9, y + 1.6, 32.0), -PI * 0.5, 10.0, 3.4, 921)


# ================================================================ LABORATÓRIOS
static func _laboratorios(root: Node3D) -> void:
	var y := D2
	# bancadas de análise encostadas na parede, com vidraria e cilindros
	Detail.workbench(root, Vector3(-11.0, y, -22.0), PI * 0.5, 1001)
	Detail.workbench(root, Vector3(11.0, y, -22.0), -PI * 0.5, 1003)
	# cilindros de gás com cinta e manômetro
	for i in 3:
		cylinder(root, Vector3(-13.2, y, -34.0 + float(i) * 0.8), 1005 + i)
	# capela de exaustão (duto alto com grade)
	G3D.box(root, Vector3(1.8, 2.2, 1.1), Vector3(-12.4, y + 1.1, -28.0), Mats.get_mat("metal"), true, Vector3.ZERO, "capela")
	G3D.box(root, Vector3(1.6, 0.9, 0.05), Vector3(-12.4, y + 1.3, -27.45), Mats.get_mat("glass_scratch"), false, Vector3.ZERO, "vidro_capela")
	Detail.louver(root, Vector3(-12.4, y + 2.6, -28.0), PI * 0.5, 1.2, 0.6)
	Detail.pipe_run(root, Vector3(-14.0, y + 3.2, -36.0), Vector3(-14.0, y + 3.2, -19.0), 3, 0.08, true, 1007)
	Detail.cable_tray(root, Vector3(-12.0, y + 3.0, -37.0), Vector3(12.0, y + 3.0, -37.0), 1009, 6)
	Detail.monitor_bank(root, Vector3(0.0, y + 1.6, -37.4), 0.0, 3, 2)
	Detail.junction_box(root, Vector3(14.0 - 0.4, y + 1.6, -20.0), -PI * 0.5, true)
	Detail.work_lamp(root, Vector3(-6.0, y + 2.9, -28.0), Color(0.85, 0.92, 1.0), 1.0, 7.0, 0.5, 0.0)
	Detail.work_lamp(root, Vector3(6.0, y + 2.9, -24.0), Color(0.85, 0.92, 1.0), 0.9, 6.5, 0.5, 1.0)
	Detail.dust(root, Vector3(0, y, -28.0), 11.0, 3.2, 70)
	Decals.dress_floor(root, -13.0, -37.0, 13.0, -19.0, y, 9, 1011)
	Decals.dress_wall(root, Vector3(0.0, y + 1.7, -37.9), 0.0, 16.0, 3.0, 1013)


static func cylinder(parent: Node3D, pos: Vector3, seed_v := 1) -> void:
	var r := RandomNumberGenerator.new()
	r.seed = seed_v
	var g := Node3D.new()
	g.name = "CilindroGas"
	g.position = pos
	g.rotation.y = r.randf() * 0.6
	parent.add_child(g)
	var cores := ["paint_blue", "paint_olive", "paint_grey", "paint_red"]
	var m := Mats.get_mat(cores[seed_v % cores.size()])
	# garrafa de gás: pé rebaixado, corpo, ombro abaulado, gargalo
	G3D.peca(g, MeshKit.torno(PackedVector2Array([
		Vector2(0.0, 0.02), Vector2(0.10, 0.02), Vector2(0.125, 0.0), Vector2(0.14, 0.03),
		Vector2(0.14, 1.02), Vector2(0.132, 1.09), Vector2(0.108, 1.15), Vector2(0.07, 1.19),
		Vector2(0.045, 1.205), Vector2(0.045, 1.25), Vector2(0.0, 1.25),
	]), 14, false, "garrafa_gas"), Vector3.ZERO, m, Vector3.ZERO, Vector3.ONE, "garrafa")
	G3D.colisor(g, Vector3(0.26, 1.25, 0.26), Vector3(0, 0.625, 0))
	# capacete de proteção da válvula + faixa de identificação no ombro
	G3D.peca(g, MeshKit.torno(PackedVector2Array([
		Vector2(0.062, 0.0), Vector2(0.062, 0.10), Vector2(0.05, 0.135), Vector2(0.0, 0.145),
	]), 10, true, "capacete_gas"), Vector3(0, 1.23, 0), Mats.get_mat("metal_rust"), Vector3.ZERO, Vector3.ONE, "capacete")
	Detail._cil(g, 0.143, 0.07, Vector3(0, 0.93, 0), Mats.get_mat("paint_yellow"), Vector3.ZERO, 14)
	# cinta que prende a garrafa
	Detail._cil(g, 0.146, 0.025, Vector3(0, 0.62, 0), Mats.get_mat("metal"), Vector3.ZERO, 14)


# ================================================================ ENGENHARIA
## A sala de máquinas é o coração sujo da estação: aqui a densidade é brutal.
static func _engenharia(root: Node3D) -> void:
	var y := D2
	# malha de tubulação cruzando a sala em três alturas
	Detail.pipe_run(root, Vector3(19.0, y + 3.55, -11.0), Vector3(19.0, y + 3.55, 11.0), 4, 0.12, true, 1101, true)
	Detail.pipe_run(root, Vector3(37.0, y + 3.55, -11.0), Vector3(37.0, y + 3.55, 11.0), 3, 0.10, true, 1103)
	Detail.pipe_run(root, Vector3(19.0, y + 3.05, 4.0), Vector3(37.0, y + 3.05, 4.0), 3, 0.09, true, 1105)
	Detail.pipe_run(root, Vector3(19.0, y + 2.65, -4.0), Vector3(37.0, y + 2.65, -4.0), 2, 0.07, false, 1107)
	Detail.pipe_run(root, Vector3(30.0, y + 0.55, -11.0), Vector3(30.0, y + 0.55, -2.0), 2, 0.10, true, 1109)
	# bandejas e conduítes
	Detail.cable_tray(root, Vector3(20.0, y + 3.2, -10.5), Vector3(36.0, y + 3.2, -10.5), 1111, 8)
	Detail.cable_tray(root, Vector3(20.0, y + 3.2, 10.5), Vector3(36.0, y + 3.2, 10.5), 1113, 6)
	# quadros elétricos, manômetros e válvulas em parede
	Detail.breaker_panel(root, Vector3(19.6, y + 1.6, -9.0), PI * 0.5, 1115)
	Detail.breaker_panel(root, Vector3(19.6, y + 1.6, 0.0), PI * 0.5, 1117)
	Detail.gauge_panel(root, Vector3(19.6, y + 1.5, 8.0), PI * 0.5, 4, 1119)
	Detail.junction_box(root, Vector3(36.6, y + 1.7, -6.0), -PI * 0.5, true)
	Detail.junction_box(root, Vector3(36.6, y + 2.2, 6.0), -PI * 0.5, false)
	Detail.louver(root, Vector3(36.6, y + 3.0, 0.0), -PI * 0.5, 1.2, 0.7)
	# escadas e plataforma de acesso ao alto
	Detail.ladder(root, Vector3(34.0, y, -10.5), 0.0, 3.6, true)
	Detail.i_beam(root, Vector3(22.0, y + 3.7, -6.0), Vector3(22.0, y + 3.7, 6.0), 0.34)
	Detail.i_beam(root, Vector3(28.0, y + 3.7, -6.0), Vector3(28.0, y + 3.7, 6.0), 0.34)
	# vapor: dois jatos e uma poça de condensado quente
	Detail.steam_vent(root, Vector3(26.0, y + 0.3, -10.0), 0.0, 1.2)
	Detail.steam_vent(root, Vector3(35.0, y + 2.2, 3.0), PI, 0.7)
	Detail.puddle(root, Vector3(27.0, y, 5.0), 2.6, 1121)
	# poeira densa no ar (é salão de máquinas)
	Detail.dust(root, Vector3(28.0, y, 0.0), 9.5, 3.6, 120)
	Detail.dust(root, Vector3(34.0, y, -6.0), 5.0, 3.0, 50)
	# luzes de trabalho (uma piscando)
	Detail.work_lamp(root, Vector3(22.0, y + 3.0, 4.0), Color(1.0, 0.74, 0.40), 1.1, 7.5, 0.5, 1.0)
	Detail.work_lamp(root, Vector3(30.0, y + 3.0, -7.0), Color(0.80, 0.88, 1.0), 1.0, 7.0, 0.5, 0.0)
	Detail.work_lamp(root, Vector3(35.0, y + 3.0, 8.0), Color(1.0, 0.70, 0.36), 0.9, 6.5, 0.5, 0.0)
	_maquinas(root, y)
	# óleo e sujeira por todo lado
	Decals.dress_floor(root, 19.0, -11.0, 37.0, 11.0, y, 16, 1123)
	Decals.dress_wall(root, Vector3(19.1, y + 1.9, 4.0), PI * 0.5, 18.0, 3.6, 1125)
	Decals.dress_wall(root, Vector3(37.9, y + 1.9, -4.0), -PI * 0.5, 18.0, 3.6, 1127)




## Massa central de maquinário da Engenharia: bombas, motores, tanques e um
## passadiço. A sala de máquinas precisa ter tripas no meio — de longe ela
## parecia um galpão vazio.
static func _maquinas(root: Node3D, y: float) -> void:
	var m_metal := Mats.get_mat("metal")
	var m_rust := Mats.get_mat("metal_rust")
	var m_dark := Mats.get_mat("wall_dark")
	var m_grate := Mats.get_mat("floor_grating")
	# dois blocos de motor sobre pedestais
	for i in 2:
		var bx := 24.0 + float(i) * 8.0
		var bz := -3.5 + float(i) * 7.0
		G3D.box(root, Vector3(3.0, 0.45, 3.0), Vector3(bx, y + 0.22, bz), m_rust, true, Vector3.ZERO, "pedestal")
		G3D.box(root, Vector3(2.3, 1.5, 3.4), Vector3(bx, y + 1.2, bz), m_dark, true, Vector3.ZERO, "motor")
		# aletas de refrigeração
		for k in 6:
			G3D.box(root, Vector3(2.4, 0.06, 0.10), Vector3(bx, y + 0.62 + float(k) * 0.22, bz + 1.72),
				m_metal, false, Vector3.ZERO, "aleta")
		# eixo e volante na ponta
		Detail._cil(root, 0.22, 0.9, Vector3(bx, y + 1.2, bz - 2.0), m_metal, Vector3(PI * 0.5, 0, 0), false)
		Detail.valve_wheel(root, Vector3(bx, y + 1.2, bz - 2.45), 0.0, 0.30)
		# tubo de escape subindo
		Detail._cil(root, 0.14, 3.4, Vector3(bx + 0.7, y + 2.9, bz), m_rust, Vector3.ZERO, false)
		Detail._cil(root, 0.18, 0.12, Vector3(bx + 0.7, y + 4.6, bz), m_metal, Vector3.ZERO, false)
	# bombas verticais com volute e carcaça
	for i in 3:
		var px := 22.0 + float(i) * 5.5
		Detail._cil(root, 0.42, 0.5, Vector3(px, y + 0.25, 8.4), m_rust, Vector3.ZERO, false)
		Detail._cil(root, 0.30, 1.1, Vector3(px, y + 1.05, 8.4), m_metal, Vector3.ZERO, false)
		Detail._cil(root, 0.46, 0.34, Vector3(px, y + 1.35, 8.4), m_rust, Vector3.ZERO, false)
		Detail._cil(root, 0.10, 0.7, Vector3(px, y + 1.8, 8.4), m_metal, Vector3.ZERO, false)
		# motor elétrico deitado ao lado
		G3D.box(root, Vector3(0.7, 0.7, 0.7), Vector3(px + 0.9, y + 0.4, 8.4), m_dark, true, Vector3.ZERO, "motor_bomba")
	# coletor central: tubos verticais com flanges e manômetros
	for i in 4:
		var cx := 26.5 + float(i) * 1.1
		Detail._cil(root, 0.13, 4.2, Vector3(cx, y + 2.1, -0.6), m_rust, Vector3.ZERO, false)
		Detail._cil(root, 0.19, 0.10, Vector3(cx, y + 2.6, -0.6), m_metal, Vector3.ZERO, false)
		Detail._cil(root, 0.19, 0.10, Vector3(cx, y + 4.1, -0.6), m_metal, Vector3.ZERO, false)
	Detail.gauge_panel(root, Vector3(31.5, y + 2.2, -0.6), -PI * 0.5, 3, 2101)
	Detail.valve_wheel(root, Vector3(26.0, y + 3.2, -0.6), PI * 0.5, 0.26)
	Detail.valve_wheel(root, Vector3(31.6, y + 3.2, -0.6), PI * 0.5, 0.26)
	# tanques de ar comprimido encostados no fundo
	for i in 2:
		var tz := 1.5 + float(i) * 2.6
		Detail._cil(root, 0.62, 3.2, Vector3(21.6, y + 1.6, tz), m_rust, Vector3.ZERO, false)
		Detail._cil(root, 0.66, 0.16, Vector3(21.6, y + 0.5, tz), m_metal, Vector3.ZERO, false)
		Detail._cil(root, 0.66, 0.16, Vector3(21.6, y + 2.7, tz), m_metal, Vector3.ZERO, false)
		Detail._cil(root, 0.16, 0.5, Vector3(21.6, y + 3.4, tz), m_metal, Vector3.ZERO, false)
		G3D.box(root, Vector3(1.3, 0.9, 0.10), Vector3(21.6, y + 1.7, tz + 0.66), Mats.get_mat("hazard"),
			false, Vector3.ZERO, "faixa_tanque")
	# passadiço atravessando a sala no alto, com guarda-corpo
	var cat_y := y + 3.1
	G3D.box(root, Vector3(1.6, 0.10, 14.0), Vector3(28.0, cat_y, 0.0), m_grate, true, Vector3.ZERO, "passadico")
	for lado: float in [-1.0, 1.0]:
		for k in 9:
			var pz := -6.6 + float(k) * 1.65
			Detail._cil(root, 0.035, 1.0, Vector3(28.0 + lado * 0.76, cat_y + 0.55, pz), m_metal,
				Vector3.ZERO, false)
		Detail._cil(root, 0.035, 13.6, Vector3(28.0 + lado * 0.76, cat_y + 1.02, 0.0), m_metal,
			Vector3(PI * 0.5, 0, 0), false)
	# vapor quente subindo do coletor e óleo no piso
	Detail.steam_vent(root, Vector3(27.5, y + 0.4, 1.2), PI * 0.5, 1.4)
	Detail.puddle(root, Vector3(25.0, y, -1.6), 3.2, 2103)
	Detail.puddle(root, Vector3(31.0, y, 6.0), 2.0, 2105)
	# luz de emergência vermelha sobre o coletor
	Detail.work_lamp(root, Vector3(28.6, cat_y + 1.3, 0.0), Color(1.0, 0.30, 0.22), 0.9, 8.0, 0.4, 1.0)


# ================================================================ ENFERMARIA
static func _enfermaria(root: Node3D) -> void:
	var y := D2
	Detail.workbench(root, Vector3(-9.4, y, 22.0), PI * 0.5, 1201)
	Detail.louver(root, Vector3(0.0, y + 3.05, 18.6), 0.0, 1.0, 0.6)
	Detail.pipe_run(root, Vector3(-11.4, y + 3.05, 19.0), Vector3(-11.4, y + 3.05, 35.0), 2, 0.06, false, 1203)
	Detail.pipe_run(root, Vector3(11.4, y + 3.05, 19.0), Vector3(11.4, y + 3.05, 35.0), 3, 0.07, true, 1205)
	Detail.cable_tray(root, Vector3(-11.0, y + 2.85, 19.5), Vector3(11.0, y + 2.85, 19.5), 1207, 4)
	Detail.monitor_bank(root, Vector3(11.5, y + 1.5, 27.0), -PI * 0.5, 2, 2)
	Detail.junction_box(root, Vector3(-11.5, y + 1.6, 31.0), PI * 0.5, false)
	Detail.gauge_panel(root, Vector3(11.6, y + 1.6, 21.0), -PI * 0.5, 2, 1209)
	Detail.work_lamp(root, Vector3(0.0, y + 2.9, 26.0), Color(0.88, 0.94, 1.0), 0.95, 6.5, 0.5, 1.0)
	Detail.dust(root, Vector3(0, y, 27.0), 9.0, 3.0, 55)
	Decals.dress_floor(root, -11.0, 19.0, 11.0, 35.0, y, 8, 1211)
	Decals.dress_wall(root, Vector3(-11.9, y + 1.6, 24.0), PI * 0.5, 10.0, 3.2, 1213)


# ================================================================ RÁDIO
static func _radio(root: Node3D) -> void:
	var y := D2
	# sala de comunicações: racks, cabos por toda parte, antena descendo pelo teto
	for i in 3:
		G3D.box(root, Vector3(0.7, 2.0, 0.55), Vector3(-35.4, y + 1.0, -6.0 + float(i) * 1.6),
			Mats.get_mat("panel_green"), true, Vector3.ZERO, "rack%d" % i)
		for k in 4:
			G3D.box(root, Vector3(0.5, 0.12, 0.03), Vector3(-35.4, y + 0.35 + float(k) * 0.42, -5.72 + float(i) * 1.6),
				Mats.emissive_c(Color(0.35, 0.9, 0.65) if (i + k) % 3 else Color(0.95, 0.6, 0.2), 0.7),
				false, Vector3.ZERO, "led")
	Detail.cable_tray(root, Vector3(-36.0, y + 2.9, -8.0), Vector3(-20.0, y + 2.9, -8.0), 1301, 7)
	Detail.pipe_run(root, Vector3(-37.0, y + 3.1, 8.0), Vector3(-20.0, y + 3.1, 8.0), 2, 0.07, false, 1303)
	Detail.monitor_bank(root, Vector3(-26.0, y + 1.6, -9.4), 0.0, 4, 2)
	Detail.gauge_panel(root, Vector3(-21.0, y + 1.5, -9.5), 0.0, 3, 1305)
	Detail.junction_box(root, Vector3(-19.6, y + 1.7, 2.0), -PI * 0.5, true)
	Detail.work_lamp(root, Vector3(-28.0, y + 3.0, 0.0), Color(1.0, 0.74, 0.42), 0.95, 7.0, 0.5, 1.0)
	Detail.dust(root, Vector3(-28.0, y, 0.0), 9.0, 3.0, 60)
	Decals.dress_floor(root, -37.0, -9.0, -20.0, 9.0, y, 8, 1307)
	Decals.dress_wall(root, Vector3(-19.1, y + 1.8, -4.0), -PI * 0.5, 14.0, 3.0, 1309)


# ================================================================ COMANDO
static func _comando(root: Node3D) -> void:
	var y := D3
	# sala de controle: o lugar mais "vivo" que sobrou da estação
	Detail.monitor_bank(root, Vector3(-8.0, y + 1.8, -33.4), 0.0, 4, 2)
	Detail.monitor_bank(root, Vector3(4.0, y + 1.8, -33.4), 0.0, 4, 2)
	Detail.gauge_panel(root, Vector3(13.4, y + 1.6, -24.0), -PI * 0.5, 4, 1401)
	Detail.breaker_panel(root, Vector3(13.4, y + 1.6, -30.0), -PI * 0.5, 1403)
	Detail.cable_tray(root, Vector3(-13.0, y + 3.6, -32.0), Vector3(13.0, y + 3.6, -32.0), 1405, 8)
	Detail.pipe_run(root, Vector3(-13.0, y + 3.9, -20.0), Vector3(13.0, y + 3.9, -20.0), 2, 0.07, false, 1407)
	Detail.junction_box(root, Vector3(-13.4, y + 1.7, -22.0), PI * 0.5, false)
	Detail.louver(root, Vector3(-13.4, y + 3.0, -28.0), PI * 0.5, 1.0, 0.6)
	Detail.work_lamp(root, Vector3(0.0, y + 3.4, -26.0), Color(0.85, 0.92, 1.0), 1.0, 8.0, 0.5, 0.0)
	Detail.dust(root, Vector3(0, y, -26.0), 10.0, 3.6, 80)
	# marcas de piso do posto de comando
	Decals.floor_mark(root, "frame", Vector3(0, y + 0.04, -24.0), 0.0, Vector2(10.0, 6.0),
		Color(0.80, 0.66, 0.15, 0.42))
	Decals.dress_floor(root, -13.0, -33.0, 13.0, -19.0, y, 10, 1409)
	Decals.dress_wall(root, Vector3(-13.9, y + 1.8, -26.0), PI * 0.5, 12.0, 3.8, 1411)


# ================================================================ CÂMARA DO SINO
static func _sino(root: Node3D) -> void:
	var y := D3
	# câmara de eco: menos detalhe, mais ruído de estrutura
	Detail.pipe_run(root, Vector3(-7.4, y + 1.9, 19.0), Vector3(-7.4, y + 1.9, 31.0), 3, 0.09, true, 1501, true)
	Detail.pipe_run(root, Vector3(7.4, y + 2.4, 19.0), Vector3(7.4, y + 2.4, 31.0), 2, 0.07, false, 1503)
	Detail.cable_tray(root, Vector3(-7.0, y + 2.8, 20.0), Vector3(7.0, y + 2.8, 20.0), 1505, 5)
	Detail.i_beam(root, Vector3(-7.5, y + 2.9, 25.0), Vector3(7.5, y + 2.9, 25.0), 0.30)
	Detail.junction_box(root, Vector3(7.6, y + 1.5, 22.0), -PI * 0.5, false)
	Detail.gauge_panel(root, Vector3(7.6, y + 1.4, 29.0), -PI * 0.5, 2, 1507)
	Detail.work_lamp(root, Vector3(0.0, y + 2.6, 29.0), Color(1.0, 0.66, 0.32), 0.8, 6.0, 0.6, 1.0)
	Decals.dress_floor(root, -7.0, 19.0, 7.0, 31.0, y, 6, 1509)
	Decals.dress_wall(root, Vector3(-7.9, y + 1.5, 25.0), PI * 0.5, 10.0, 3.0, 1511)


# ================================================================ ECLUSA
static func _eclusa(root: Node3D) -> void:
	var y := D3
	# eclusa: tudo precisa ser funcional e pesado — cilindros, mangueiras, trajes
	Detail.pipe_run(root, Vector3(-39.0, y + 3.0, -7.0), Vector3(-19.0, y + 3.0, -7.0), 4, 0.12, true, 1601, true)
	Detail.pipe_run(root, Vector3(-39.0, y + 3.0, 7.0), Vector3(-19.0, y + 3.0, 7.0), 3, 0.10, true, 1603)
	Detail.cable_tray(root, Vector3(-38.0, y + 2.7, 0.0), Vector3(-20.0, y + 2.7, 0.0), 1605, 6)
	for i in 4:
		cylinder(root, Vector3(-38.0, y, -6.0 + float(i) * 1.0), 1607 + i)
	Detail.breaker_panel(root, Vector3(-19.6, y + 1.6, -4.0), -PI * 0.5, 1611)
	Detail.gauge_panel(root, Vector3(-19.6, y + 1.5, 3.0), -PI * 0.5, 3, 1613)
	Detail.louver(root, Vector3(-19.6, y + 3.0, 6.0), -PI * 0.5, 1.2, 0.7)
	Detail.junction_box(root, Vector3(-19.6, y + 1.7, 0.0), -PI * 0.5, true)
	Detail.work_lamp(root, Vector3(-30.0, y + 3.0, 0.0), Color(1.0, 0.72, 0.36), 1.0, 7.5, 0.5, 1.0)
	Detail.steam_vent(root, Vector3(-36.0, y + 0.3, 4.0), PI, 0.6)
	Detail.dust(root, Vector3(-29.0, y, 0.0), 8.0, 3.0, 55)
	Decals.dress_floor(root, -39.0, -7.0, -20.0, 7.0, y, 9, 1615)
	Decals.dress_wall(root, Vector3(-19.1, y + 1.8, 0.0), -PI * 0.5, 14.0, 3.2, 1617)
	# faixa de segurança diante da porta externa
	Decals.floor_mark(root, "stripes", Vector3(-30.0, y + 0.04, 0.0), PI * 0.5, Vector2(12.0, 0.6),
		Color(0.85, 0.15, 0.10, 0.5))


# ================================================================ CORREDOR DE OBSERVAÇÃO
static func _corredor_obs(root: Node3D) -> void:
	var y := D3
	# corredor com janelas: pouca tralha, muita tubulação passando por cima
	Detail.pipe_run(root, Vector3(19.0, y + 3.05, -2.1), Vector3(35.0, y + 3.05, -2.1), 3, 0.08, true, 1701)
	Detail.pipe_run(root, Vector3(19.0, y + 3.05, 2.1), Vector3(35.0, y + 3.05, 2.1), 2, 0.06, false, 1703)
	Detail.cable_tray(root, Vector3(19.5, y + 2.85, 0.0), Vector3(35.0, y + 2.85, 0.0), 1705, 5)
	for i in 3:
		Detail.junction_box(root, Vector3(21.0 + float(i) * 5.0, y + 1.5, -2.3), 0.0, i == 1)
	Detail.louver(root, Vector3(24.0, y + 2.6, 2.3), PI, 0.9, 0.55)
	Detail.gauge_panel(root, Vector3(30.0, y + 1.5, 2.3), PI, 2, 1707)
	Detail.work_lamp(root, Vector3(25.0, y + 2.7, 0.0), Color(0.80, 0.88, 1.0), 0.85, 6.5, 0.5, 1.0)
	Decals.dress_floor(root, 19.0, -2.2, 35.0, 2.2, y, 6, 1709)
	Decals.dress_wall(root, Vector3(26.0, y + 1.6, 2.4), PI, 6.0, 3.0, 1711)


# ================================================================ ANTESSALA
static func _antessala(root: Node3D) -> void:
	var y := D4
	Detail.workbench(root, Vector3(16.5, y, -4.0), PI * 0.5, 1801)
	Detail.locker_bank(root, Vector3(28.0, y, -5.4), 0.0, 3, 1803)
	Detail.pipe_run(root, Vector3(15.0, y + 3.0, 5.0), Vector3(35.0, y + 3.0, 5.0), 3, 0.08, true, 1805)
	Detail.cable_tray(root, Vector3(16.0, y + 2.8, -5.0), Vector3(34.0, y + 2.8, -5.0), 1807, 5)
	Detail.junction_box(root, Vector3(31.0, y + 1.6, -5.6), 0.0, true)
	Detail.breaker_panel(root, Vector3(20.0, y + 1.6, -5.6), 0.0, 1809)
	Detail.louver(root, Vector3(24.0, y + 2.6, 5.6), PI, 1.0, 0.6)
	Detail.work_lamp(root, Vector3(24.0, y + 2.7, 0.0), Color(0.85, 0.92, 1.0), 0.95, 7.0, 0.5, 1.0)
	Decals.dress_floor(root, 15.0, -5.0, 35.0, 5.0, y, 7, 1811)
	Decals.dress_wall(root, Vector3(24.0, y + 1.6, 5.9), PI, 16.0, 3.0, 1813)


# ================================================================ OBSERVATÓRIO
static func _observatorio(root: Node3D) -> void:
	var y := D4
	# aqui manda a vista: detalhe só nas bordas e no pé das janelas
	Detail.pipe_run(root, Vector3(-13.4, y + 5.4, -5.0), Vector3(-13.4, y + 5.4, 19.0), 3, 0.09, true, 1901)
	Detail.pipe_run(root, Vector3(13.4, y + 5.4, -5.0), Vector3(13.4, y + 5.4, 19.0), 2, 0.07, false, 1903)
	Detail.cable_tray(root, Vector3(-12.5, y + 5.6, 19.0), Vector3(12.5, y + 5.6, 19.0), 1905, 6)
	Detail.i_beam(root, Vector3(-14.0, y + 5.9, 2.0), Vector3(14.0, y + 5.9, 2.0), 0.40)
	Detail.i_beam(root, Vector3(-14.0, y + 5.9, 12.0), Vector3(14.0, y + 5.9, 12.0), 0.40)
	Detail.monitor_bank(root, Vector3(-12.0, y + 1.5, -4.6), 0.0, 3, 2)
	Detail.gauge_panel(root, Vector3(12.4, y + 1.5, -4.6), 0.0, 3, 1907)
	Detail.junction_box(root, Vector3(-13.4, y + 1.7, -2.0), PI * 0.5, false)
	Detail.louver(root, Vector3(13.4, y + 3.4, -2.0), -PI * 0.5, 1.1, 0.7)
	# luz baixa e âmbar: o jogador precisa ver o oceano, não a sala
	Detail.work_lamp(root, Vector3(-6.0, y + 4.6, 4.0), Color(0.55, 0.70, 0.95), 0.55, 9.0, 0.8, 0.0)
	Detail.work_lamp(root, Vector3(6.0, y + 4.6, 4.0), Color(0.55, 0.70, 0.95), 0.55, 9.0, 0.8, 0.0)
	Detail.dust(root, Vector3(0, y, 6.0), 11.0, 4.5, 90)
	Decals.dress_floor(root, -12.0, -5.0, 12.0, 18.0, y, 5, 1909)
