class_name Setores
extends RefCounted
## Mobiliário e equipamento PRÓPRIOS de cada setor.
##
## Até aqui todos os ambientes usavam a mesma receita (bancada de oficina,
## tubos, painel de manômetros). Aqui ficam as peças que dizem "isto é uma
## cozinha", "isto é um laboratório", "isto é uma enfermaria", "isto é uma
## sala de comando" — cada uma com função reconhecível.
##
## Convenção de todas as peças: `pos` é o ponto no chão, no centro da peça;
## as costas ficam em -Z local (lado da parede) e a frente em +Z; o
## comprimento corre em X. Só o volume principal recebe colisor.


static func _grupo(parent: Node3D, nome: String, pos: Vector3, yaw: float) -> Node3D:
	var g := Node3D.new()
	g.name = nome
	g.position = pos
	g.rotation.y = yaw
	parent.add_child(g)
	return g


static func _b(g: Node3D, size: Vector3, pos: Vector3, mat: String, nome := "peca",
		rot := Vector3.ZERO) -> Node3D:
	return G3D.box(g, size, pos, Mats.get_mat(mat), false, rot, nome)


static func _c(g: Node3D, raio: float, altura: float, pos: Vector3, mat: String,
		rot := Vector3.ZERO, lados := 0) -> Node3D:
	return Detail._cil(g, raio, altura, pos, Mats.get_mat(mat), rot, lados)


# ================================================================ PEÇAS TORNEADAS
static func _panela() -> ArrayMesh:
	# panela de 1 m de diâmetro × 1 m de altura (as medidas vão na escala)
	return MeshKit.torno(PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(0.46, 0.0), Vector2(0.50, 0.04), Vector2(0.50, 0.94),
		Vector2(0.53, 0.97), Vector2(0.53, 1.0), Vector2(0.47, 1.0), Vector2(0.47, 0.08), Vector2(0.0, 0.08),
	]), 16, false, "panela")


static func _caneca() -> ArrayMesh:
	return MeshKit.torno(PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(0.036, 0.0), Vector2(0.040, 0.006), Vector2(0.040, 0.09),
		Vector2(0.034, 0.09), Vector2(0.034, 0.012), Vector2(0.0, 0.012),
	]), 10, false, "caneca")


static func _frasco() -> ArrayMesh:
	# balão de fundo chato (Erlenmeyer) de 1 de altura
	return MeshKit.torno(PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(0.34, 0.0), Vector2(0.36, 0.03), Vector2(0.11, 0.70),
		Vector2(0.11, 0.96), Vector2(0.14, 1.0), Vector2(0.0, 1.0),
	]), 12, false, "frasco")


static func _garrafa() -> ArrayMesh:
	# garrafa de reagente de 1 de altura
	return MeshKit.torno(PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(0.20, 0.0), Vector2(0.22, 0.02), Vector2(0.22, 0.62),
		Vector2(0.18, 0.74), Vector2(0.09, 0.80), Vector2(0.09, 0.93), Vector2(0.12, 0.94),
		Vector2(0.12, 1.0), Vector2(0.0, 1.0),
	]), 10, false, "garrafa")


static func _prato_luz() -> ArrayMesh:
	# refletor raso (foco cirúrgico, luminária de mesa), diâmetro 1
	return MeshKit.torno(PackedVector2Array([
		Vector2(0.0, 0.16), Vector2(0.14, 0.15), Vector2(0.34, 0.10), Vector2(0.48, 0.02),
		Vector2(0.50, 0.0), Vector2(0.50, -0.03), Vector2(0.46, -0.03), Vector2(0.32, 0.05),
		Vector2(0.12, 0.09), Vector2(0.0, 0.10),
	]), 18, false, "prato_luz")


# ================================================================ REFEITÓRIO
## Linha de cozinha encostada na parede: fogão com panelas e coifa, pia,
## balcão de servir com bandejas e o samovar.
static func cozinha(parent: Node3D, pos: Vector3, yaw: float, comp := 9.0) -> Node3D:
	var g := _grupo(parent, "Cozinha", pos, yaw)
	var h := 0.90
	var prof := 0.72
	# corpo em módulos de 1,5 m, com portas e rodapé recuado
	var n := int(round(comp / 1.5))
	var passo := comp / float(n)
	for i in n:
		var xm := -comp * 0.5 + passo * (float(i) + 0.5)
		_b(g, Vector3(passo - 0.02, h - 0.16, prof - 0.04), Vector3(xm, 0.10 + (h - 0.16) * 0.5, 0), "paint_olive", "modulo")
		for lado: float in [-1.0, 1.0]:
			_b(g, Vector3(passo * 0.46, h - 0.30, 0.02), Vector3(xm + lado * passo * 0.24, 0.10 + (h - 0.16) * 0.5, prof * 0.5 - 0.01), "paint_grey", "porta")
			_b(g, Vector3(0.025, 0.14, 0.03), Vector3(xm + lado * 0.06, 0.62, prof * 0.5 + 0.015), "steel", "puxador")
	_b(g, Vector3(comp, 0.10, prof - 0.12), Vector3(0, 0.05, -0.02), "rubber", "rodape")
	# tampo de inox com espelho na parede
	_b(g, Vector3(comp + 0.04, 0.05, prof + 0.04), Vector3(0, h, 0), "steel", "tampo")
	_b(g, Vector3(comp + 0.04, 0.42, 0.03), Vector3(0, h + 0.22, -prof * 0.5 + 0.005), "steel", "espelho")
	G3D.colisor(g, Vector3(comp, h, prof), Vector3(0, h * 0.5, 0))

	# --- fogão (ponta esquerda): chapa escura, quatro bocas, panelas
	var xf := -comp * 0.5 + 1.1
	_b(g, Vector3(1.7, 0.03, prof - 0.08), Vector3(xf, h + 0.04, 0), "oily", "chapa")
	var bocas := [Vector2(-0.45, -0.14), Vector2(0.45, -0.14), Vector2(-0.45, 0.16), Vector2(0.45, 0.16)]
	for i in bocas.size():
		var bp: Vector2 = bocas[i]
		_c(g, 0.13, 0.02, Vector3(xf + bp.x, h + 0.065, bp.y), "metal_rust")
	var panela := _panela()
	G3D.peca(g, panela, Vector3(xf - 0.45, h + 0.075, -0.14), Mats.get_mat("steel"), Vector3.ZERO, Vector3(0.40, 0.34, 0.40), "panelao")
	G3D.peca(g, panela, Vector3(xf + 0.45, h + 0.075, 0.16), Mats.get_mat("metal"), Vector3(0, 0.6, 0), Vector3(0.28, 0.16, 0.28), "panela")
	_b(g, Vector3(0.24, 0.02, 0.03), Vector3(xf + 0.68, h + 0.21, 0.16), "plastic_dark", "cabo")
	# coifa: tronco de pirâmide + duto que sobe até a tubulação
	G3D.peca(g, MeshKit.tronco(Vector2(1.9, prof + 0.1), Vector2(0.5, 0.4), 0.55, Vector2(0, -0.12)),
			Vector3(xf, 2.25, 0.0), Mats.get_mat("steel"), Vector3.ZERO, Vector3.ONE, "coifa")
	_b(g, Vector3(1.94, 0.10, prof + 0.14), Vector3(xf, 1.93, 0.0), "steel", "aba_coifa")
	_b(g, Vector3(0.46, 0.66, 0.36), Vector3(xf, 2.83, -0.12), "metal", "duto")

	# --- pia (meio): cuba rebaixada, torneira de cotovelo, escorredor
	var xp := -comp * 0.5 + 3.3
	_b(g, Vector3(0.80, 0.02, 0.46), Vector3(xp, h + 0.031, 0.02), "plastic_dark", "cuba")
	_b(g, Vector3(0.86, 0.035, 0.52), Vector3(xp, h + 0.02, 0.02), "steel", "aro_cuba")
	_c(g, 0.018, 0.26, Vector3(xp, h + 0.16, -0.26), "steel")
	G3D.peca(g, MeshKit.cotovelo(0.018, 0.10, PI, 8, 8), Vector3(xp, h + 0.29, -0.16), Mats.get_mat("steel"),
			Vector3(0, PI * 0.5, 0), Vector3.ONE, "bica")
	for lado: float in [-1.0, 1.0]:
		_c(g, 0.03, 0.05, Vector3(xp + lado * 0.14, h + 0.06, -0.27), "paint_red" if lado < 0.0 else "paint_blue", Vector3.ZERO, 6)
	for i in 5:
		_b(g, Vector3(0.02, 0.20, 0.30), Vector3(xp + 0.62 + float(i) * 0.07, h + 0.13, 0.0), "paint_white", "prato",
				Vector3(0, 0, 0.12))

	# --- balcão de servir (direita): pilha de bandejas, canecas, samovar
	var xs := comp * 0.5 - 2.6
	for i in 6:
		_b(g, Vector3(0.46, 0.022, 0.34), Vector3(xs + float(i % 2) * 0.015, h + 0.04 + float(i) * 0.024, 0.04),
				"plastic_old", "bandeja", Vector3(0, float(i) * 0.05 - 0.1, 0))
	var caneca := _caneca()
	for i in 8:
		var fila := 0.0 if i < 4 else 1.0
		G3D.peca(g, caneca, Vector3(xs + 0.55 + float(i % 4) * 0.105, h + 0.027, -0.12 + fila * 0.12),
				Mats.get_mat("paint_white"), Vector3.ZERO, Vector3.ONE, "caneca")
	# samovar: vaso de cobre com torneira e chaminé
	var xv := comp * 0.5 - 0.7
	G3D.peca(g, MeshKit.torno(MeshKit.perfil_vaso(0.19, 0.56, 0.5, 2), 16, false, "samovar"),
			Vector3(xv, h + 0.40, -0.04), Mats.get_mat("copper"), Vector3.ZERO, Vector3.ONE, "samovar")
	_c(g, 0.15, 0.10, Vector3(xv, h + 0.075, -0.04), "metal_rust")
	_c(g, 0.045, 0.22, Vector3(xv, h + 0.76, -0.04), "copper")
	_c(g, 0.016, 0.12, Vector3(xv, h + 0.26, 0.18), "steel", Vector3(PI * 0.5, 0, 0), 6)
	# trilho de bandejas na frente do balcão
	for k in 2:
		_c(g, 0.016, comp * 0.5, Vector3(comp * 0.25, h - 0.06, prof * 0.5 + 0.10 + float(k) * 0.10), "steel",
				Vector3(0, 0, PI * 0.5), 6)
	for k in 4:
		_b(g, Vector3(0.03, 0.03, 0.24), Vector3(0.3 + float(k) * (comp * 0.5 - 0.5) / 3.0, h - 0.08, prof * 0.5 + 0.12), "steel", "mao_francesa")

	# --- prateleira de parede com latas
	_b(g, Vector3(comp - 2.4, 0.04, 0.30), Vector3(1.2, 1.62, -prof * 0.5 + 0.16), "steel", "prateleira")
	var rng := RandomNumberGenerator.new()
	rng.seed = 4401
	var cores := ["paint_olive", "steel", "paint_red", "paint_white", "metal_rust"]
	var xl := -comp * 0.5 + 2.6
	while xl < comp * 0.5 - 0.3:
		var r := rng.randf_range(0.055, 0.085)
		var alt := rng.randf_range(0.13, 0.24)
		_c(g, r, alt, Vector3(xl, 1.64 + alt * 0.5, -prof * 0.5 + 0.16 + rng.randf_range(-0.05, 0.05)),
				cores[rng.randi() % cores.size()])
		xl += r * 2.0 + rng.randf_range(0.03, 0.30)
	return g


## O que ficou em cima de uma mesa do refeitório: bandejas, canecas, tigela.
static func mesa_posta(g: Node3D, semente := 1) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = semente
	var caneca := _caneca()
	var lugares := [Vector3(-0.42, 0.775, -0.18), Vector3(0.40, 0.775, 0.20), Vector3(0.05, 0.775, -0.22)]
	for i in lugares.size():
		if rng.randf() < 0.25:
			continue
		var p: Vector3 = lugares[i]
		var giro := rng.randf_range(-0.5, 0.5)
		_b(g, Vector3(0.40, 0.02, 0.28), p, "plastic_old", "bandeja", Vector3(0, giro, 0))
		G3D.peca(g, caneca, p + Vector3(0.12, 0.012, -0.06).rotated(Vector3.UP, giro), Mats.get_mat("paint_white"),
				Vector3.ZERO, Vector3.ONE, "caneca")
		G3D.peca(g, _panela(), p + Vector3(-0.07, 0.012, 0.02).rotated(Vector3.UP, giro), Mats.get_mat("paint_white"),
				Vector3.ZERO, Vector3(0.15, 0.05, 0.15), "tigela")
		_b(g, Vector3(0.15, 0.006, 0.018), p + Vector3(-0.07, 0.016, -0.10).rotated(Vector3.UP, giro), "steel", "talher",
				Vector3(0, giro + 0.2, 0))
	# uma caneca tombada
	G3D.peca(g, caneca, Vector3(0.62, 0.81, -0.30), Mats.get_mat("paint_white"), Vector3(PI * 0.5, 0.4, 0),
			Vector3.ONE, "caneca_tombada")


## Carrinho de recolher bandejas (três prateleiras, rodízios).
static func carrinho(parent: Node3D, pos: Vector3, yaw: float) -> Node3D:
	var g := _grupo(parent, "Carrinho", pos, yaw)
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			_c(g, 0.016, 0.86, Vector3(sx * 0.40, 0.51, sz * 0.24), "steel", Vector3.ZERO, 6)
			_c(g, 0.04, 0.03, Vector3(sx * 0.40, 0.045, sz * 0.24), "rubber", Vector3(0, 0, PI * 0.5), 8)
	for k in 3:
		_b(g, Vector3(0.86, 0.025, 0.54), Vector3(0, 0.16 + float(k) * 0.36, 0), "steel", "prateleira")
	for i in 4:
		_b(g, Vector3(0.44, 0.02, 0.32), Vector3(-0.16 + float(i % 2) * 0.02, 0.545 + float(i) * 0.022, 0.02), "plastic_old", "bandeja")
	G3D.peca(g, _panela(), Vector3(0.22, 0.175, 0.0), Mats.get_mat("steel"), Vector3.ZERO, Vector3(0.30, 0.22, 0.30), "balde")
	_c(g, 0.014, 0.54, Vector3(0.46, 0.96, 0), "steel", Vector3(PI * 0.5, 0, 0), 6)
	G3D.colisor(g, Vector3(0.9, 0.95, 0.56), Vector3(0, 0.475, 0))
	return g


# ================================================================ LABORATÓRIO
## Bancada de laboratório encostada na parede: tampo cerâmico, vidraria,
## microscópio, estante de reagentes.
static func bancada_lab(parent: Node3D, pos: Vector3, yaw: float, semente := 1, comp := 3.2) -> Node3D:
	var g := _grupo(parent, "BancadaLab", pos, yaw)
	var rng := RandomNumberGenerator.new()
	rng.seed = semente
	var h := 0.92
	var prof := 0.78
	_b(g, Vector3(comp, h - 0.14, prof - 0.06), Vector3(0, 0.10 + (h - 0.14) * 0.5, -0.02), "paint_white", "corpo")
	_b(g, Vector3(comp, 0.10, prof - 0.16), Vector3(0, 0.05, -0.04), "rubber", "rodape")
	_b(g, Vector3(comp + 0.04, 0.05, prof + 0.03), Vector3(0, h, 0), "ceramic", "tampo")
	var n := int(round(comp / 0.8))
	for i in n:
		var xg := -comp * 0.5 + comp / float(n) * (float(i) + 0.5)
		_b(g, Vector3(comp / float(n) - 0.05, 0.20, 0.02), Vector3(xg, 0.72, prof * 0.5 - 0.035), "paint_grey", "gaveta")
		_b(g, Vector3(comp / float(n) - 0.05, 0.50, 0.02), Vector3(xg, 0.36, prof * 0.5 - 0.035), "paint_grey", "porta")
		_b(g, Vector3(0.12, 0.02, 0.03), Vector3(xg, 0.74, prof * 0.5 - 0.015), "steel", "puxador")
	G3D.colisor(g, Vector3(comp, h, prof), Vector3(0, h * 0.5, 0))

	# estante de reagentes sobre a bancada
	_b(g, Vector3(comp - 0.3, 0.03, 0.22), Vector3(0, h + 0.42, -prof * 0.5 + 0.14), "paint_white", "prateleira")
	_b(g, Vector3(comp - 0.3, 0.03, 0.22), Vector3(0, h + 0.80, -prof * 0.5 + 0.14), "paint_white", "prateleira")
	for lado: float in [-1.0, 1.0]:
		_b(g, Vector3(0.03, 0.84, 0.22), Vector3(lado * (comp * 0.5 - 0.16), h + 0.42, -prof * 0.5 + 0.14), "paint_white", "montante")
	var garrafa := _garrafa()
	var vidros := ["glass", "paint_olive", "copper", "glass", "plastic_dark"]
	for nivel in 2:
		var xr := -comp * 0.5 + 0.32
		while xr < comp * 0.5 - 0.3:
			var alt := rng.randf_range(0.13, 0.26)
			var esc := Vector3(alt * 0.9, alt, alt * 0.9)
			G3D.peca(g, garrafa, Vector3(xr, h + 0.435 + float(nivel) * 0.38, -prof * 0.5 + 0.14 + rng.randf_range(-0.04, 0.04)),
					Mats.get_mat(vidros[rng.randi() % vidros.size()]), Vector3.ZERO, esc, "reagente")
			xr += alt * 0.42 + rng.randf_range(0.03, 0.34)

	# vidraria no tampo
	var frasco := _frasco()
	for i in 3 + rng.randi() % 3:
		var alt2 := rng.randf_range(0.12, 0.24)
		G3D.peca(g, frasco, Vector3(rng.randf_range(-comp * 0.42, -0.2), h + 0.026, rng.randf_range(-0.16, 0.22)),
				Mats.get_mat("glass"), Vector3.ZERO, Vector3(alt2, alt2, alt2), "frasco")
	# estante de tubos de ensaio
	var xt := comp * 0.5 - 1.25
	_b(g, Vector3(0.34, 0.02, 0.09), Vector3(xt, h + 0.035, 0.18), "plastic_old", "base_tubos")
	_b(g, Vector3(0.34, 0.015, 0.09), Vector3(xt, h + 0.115, 0.18), "plastic_old", "grade_tubos")
	for i in 6:
		_c(g, 0.011, 0.15, Vector3(xt - 0.135 + float(i) * 0.054, h + 0.105, 0.18), "glass", Vector3.ZERO, 6)
	# microscópio
	var xm := comp * 0.5 - 0.55
	_b(g, Vector3(0.20, 0.035, 0.26), Vector3(xm, h + 0.043, 0.05), "plastic_dark", "base_micro")
	_b(g, Vector3(0.05, 0.30, 0.06), Vector3(xm, h + 0.20, -0.05), "plastic_dark", "braco_micro")
	_b(g, Vector3(0.13, 0.015, 0.13), Vector3(xm, h + 0.15, 0.06), "steel", "platina")
	_c(g, 0.028, 0.20, Vector3(xm, h + 0.33, 0.035), "steel", Vector3(-0.5, 0, 0))
	_c(g, 0.018, 0.07, Vector3(xm, h + 0.215, 0.06), "steel", Vector3.ZERO, 6)
	# bico de gás
	_c(g, 0.035, 0.02, Vector3(0.05, h + 0.035, 0.12), "metal_rust")
	_c(g, 0.011, 0.14, Vector3(0.05, h + 0.105, 0.12), "copper", Vector3.ZERO, 6)
	return g


## Capela de exaustão: base, câmara com guilhotina de vidro e duto ao teto.
static func capela(parent: Node3D, pos: Vector3, yaw: float, teto := 3.6) -> Node3D:
	var g := _grupo(parent, "Capela", pos, yaw)
	var w := 1.8
	var prof := 1.0
	_b(g, Vector3(w, 0.86, prof), Vector3(0, 0.43, 0), "paint_white", "base")
	_b(g, Vector3(w + 0.04, 0.05, prof + 0.04), Vector3(0, 0.885, 0), "ceramic", "tampo")
	for lado: float in [-1.0, 1.0]:
		_b(g, Vector3(w * 0.46, 0.66, 0.02), Vector3(lado * w * 0.24, 0.45, prof * 0.5 + 0.005), "paint_grey", "porta")
		_b(g, Vector3(0.06, 1.25, prof), Vector3(lado * (w * 0.5 - 0.03), 1.535, 0), "paint_white", "lateral")
	_b(g, Vector3(w, 1.25, 0.05), Vector3(0, 1.535, -prof * 0.5 + 0.025), "paint_white", "fundo")
	_b(g, Vector3(w, 0.30, prof), Vector3(0, 2.31, 0), "paint_white", "testeira")
	# guilhotina de vidro meio levantada, com caixilho
	_b(g, Vector3(w - 0.14, 0.62, 0.02), Vector3(0, 1.80, prof * 0.5 - 0.03), "glass_scratch", "guilhotina")
	_b(g, Vector3(w - 0.12, 0.05, 0.04), Vector3(0, 1.49, prof * 0.5 - 0.03), "steel", "caixilho")
	# comando na testeira
	_b(g, Vector3(0.50, 0.14, 0.02), Vector3(w * 0.5 - 0.40, 2.31, prof * 0.5 + 0.01), "plastic_dark", "painel")
	_b(g, Vector3(0.05, 0.05, 0.02), Vector3(w * 0.5 - 0.55, 2.31, prof * 0.5 + 0.025), "paint_red", "botao")
	# dentro: suporte universal com balão
	_c(g, 0.010, 0.60, Vector3(-0.35, 1.21, -0.15), "steel", Vector3.ZERO, 6)
	_b(g, Vector3(0.20, 0.02, 0.14), Vector3(-0.35, 0.92, -0.12), "metal_rust", "base_suporte")
	G3D.peca(g, _frasco(), Vector3(-0.35, 1.02, 0.0), Mats.get_mat("glass"), Vector3.ZERO, Vector3(0.26, 0.26, 0.26), "balao")
	G3D.peca(g, _frasco(), Vector3(0.30, 0.912, 0.05), Mats.get_mat("glass"), Vector3.ZERO, Vector3(0.18, 0.18, 0.18), "frasco")
	# duto de exaustão até o teto
	var alt_duto := maxf(teto - 2.46, 0.2)
	_c(g, 0.22, alt_duto, Vector3(0, 2.46 + alt_duto * 0.5, -0.1), "metal", Vector3.ZERO, 14)
	_c(g, 0.25, 0.05, Vector3(0, 2.50, -0.1), "metal_rust", Vector3.ZERO, 14)
	G3D.colisor(g, Vector3(w, 2.4, prof), Vector3(0, 1.2, 0))
	return g


## Tanque de espécime: cilindro de vidro sobre base técnica, líquido turvo.
static func tanque_especime(parent: Node3D, pos: Vector3, semente := 1) -> Node3D:
	var g := _grupo(parent, "TanqueEspecime", pos, 0.0)
	var rng := RandomNumberGenerator.new()
	rng.seed = semente
	g.rotation.y = rng.randf() * TAU
	var r := 0.40
	_c(g, r + 0.08, 0.50, Vector3(0, 0.25, 0), "paint_grey", Vector3.ZERO, 18)
	_c(g, r + 0.11, 0.06, Vector3(0, 0.03, 0), "rubber", Vector3.ZERO, 18)
	_c(g, r + 0.10, 0.05, Vector3(0, 0.50, 0), "steel", Vector3.ZERO, 18)
	_b(g, Vector3(0.26, 0.18, 0.03), Vector3(0, 0.28, r + 0.075), "plastic_dark", "painel")
	_b(g, Vector3(0.03, 0.03, 0.02), Vector3(-0.08, 0.31, r + 0.095), "paint_red", "luz")
	# líquido (emissivo fraco) e vidro
	var nivel := rng.randf_range(0.75, 1.15)
	_c(g, r - 0.03, nivel, Vector3(0, 0.525 + nivel * 0.5, 0), "green_glow", Vector3.ZERO, 18)
	_c(g, r, 1.30, Vector3(0, 1.175, 0), "glass", Vector3.ZERO, 18)
	# tampa com passagem de cabos
	_c(g, r + 0.05, 0.10, Vector3(0, 1.875, 0), "steel", Vector3.ZERO, 18)
	_c(g, 0.07, 0.10, Vector3(0.12, 1.97, 0.0), "metal_rust", Vector3.ZERO, 8)
	_c(g, 0.022, 0.60, Vector3(-0.15, 2.22, 0.05), "rubber", Vector3(0.12, 0, 0.1), 6)
	# três cintas verticais
	for i in 3:
		var a := TAU * float(i) / 3.0
		_b(g, Vector3(0.04, 1.32, 0.02), Vector3(cos(a) * (r + 0.01), 1.175, sin(a) * (r + 0.01)), "steel", "cinta",
				Vector3(0, -a + PI * 0.5, 0))
	G3D.colisor(g, Vector3(0.9, 1.9, 0.9), Vector3(0, 0.95, 0))
	return g


## O que fica sobre a mesa de exames: correias, bandeja de instrumentos, foco.
## `pos` = centro do tampo (2,2 × 1,1 m, comprimento em X).
static func mesa_exame_acessorios(parent: Node3D, pos: Vector3, teto: float) -> Node3D:
	var g := _grupo(parent, "MesaExameAcessorios", pos, 0.0)
	_b(g, Vector3(2.24, 0.03, 0.04), Vector3(0, 0.0, 0.55), "steel", "calha")
	_b(g, Vector3(2.24, 0.03, 0.04), Vector3(0, 0.0, -0.55), "steel", "calha")
	for xc: float in [-0.7, 0.0, 0.7]:
		_b(g, Vector3(0.09, 0.012, 1.14), Vector3(xc, 0.012, 0), "canvas", "correia")
		_b(g, Vector3(0.11, 0.02, 0.05), Vector3(xc, 0.02, 0.50), "steel", "fivela")
	_b(g, Vector3(0.42, 0.02, 0.26), Vector3(0.78, 0.016, -0.30), "steel", "bandeja")
	for i in 5:
		_b(g, Vector3(0.012, 0.008, 0.18), Vector3(0.64 + float(i) * 0.065, 0.03, -0.30), "steel", "instrumento",
				Vector3(0, float(i) * 0.07 - 0.14, 0))
	# foco de teto: haste, braço e refletor
	var alt := teto - pos.y
	_c(g, 0.03, alt - 1.25, Vector3(-0.3, 1.25 + (alt - 1.25) * 0.5, 0.0), "steel")
	_c(g, 0.10, 0.05, Vector3(-0.3, alt - 0.03, 0.0), "steel")
	_b(g, Vector3(0.62, 0.04, 0.04), Vector3(0.0, 1.25, 0.0), "steel", "braco")
	G3D.peca(g, _prato_luz(), Vector3(0.3, 1.14, 0.0), Mats.get_mat("paint_white"), Vector3.ZERO,
			Vector3(0.62, 0.62, 0.62), "refletor")
	return g


# ================================================================ ENFERMARIA
## Suporte de soro com rodízios e bolsa pendurada.
static func suporte_soro(parent: Node3D, pos: Vector3, yaw := 0.0) -> Node3D:
	var g := _grupo(parent, "SuporteSoro", pos, yaw)
	for i in 5:
		var a := TAU * float(i) / 5.0
		_b(g, Vector3(0.26, 0.025, 0.03), Vector3(cos(a) * 0.13, 0.06, sin(a) * 0.13), "steel", "pe", Vector3(0, -a, 0))
		_c(g, 0.022, 0.03, Vector3(cos(a) * 0.25, 0.025, sin(a) * 0.25), "rubber", Vector3(0, 0, PI * 0.5), 6)
	_c(g, 0.014, 1.85, Vector3(0, 0.98, 0), "steel", Vector3.ZERO, 6)
	_b(g, Vector3(0.30, 0.012, 0.012), Vector3(0, 1.90, 0), "steel", "gancho")
	_b(g, Vector3(0.12, 0.20, 0.03), Vector3(0.11, 1.76, 0), "glass_scratch", "bolsa")
	_c(g, 0.004, 0.55, Vector3(0.11, 1.40, 0), "rubber", Vector3.ZERO, 6)
	return g


## Foco cirúrgico de teto sobre um leito.
static func foco_cirurgico(parent: Node3D, pos_teto: Vector3, yaw := 0.0) -> Node3D:
	var g := _grupo(parent, "FocoCirurgico", pos_teto, yaw)
	_c(g, 0.11, 0.06, Vector3(0, -0.03, 0), "steel")
	_c(g, 0.028, 0.75, Vector3(0, -0.40, 0), "steel")
	_b(g, Vector3(0.70, 0.045, 0.045), Vector3(0.33, -0.78, 0), "paint_white", "braco")
	_c(g, 0.04, 0.09, Vector3(0.0, -0.78, 0), "steel")
	_c(g, 0.022, 0.26, Vector3(0.66, -0.90, 0), "steel")
	G3D.peca(g, _prato_luz(), Vector3(0.66, -1.12, 0), Mats.get_mat("paint_white"), Vector3.ZERO,
			Vector3(0.74, 0.74, 0.74), "refletor")
	for i in 4:
		var a := TAU * float(i) / 4.0 + 0.4
		_c(g, 0.05, 0.015, Vector3(0.66 + cos(a) * 0.17, -1.115, sin(a) * 0.17), "glass_scratch", Vector3.ZERO, 8)
	return g


## Armário de medicamentos com portas de vidro + pia de assepsia ao lado.
static func posto_enfermagem(parent: Node3D, pos: Vector3, yaw: float, semente := 1) -> Node3D:
	var g := _grupo(parent, "PostoEnfermagem", pos, yaw)
	var rng := RandomNumberGenerator.new()
	rng.seed = semente
	var xa := -0.9
	_b(g, Vector3(1.2, 1.9, 0.44), Vector3(xa, 0.95, -0.02), "paint_white", "armario")
	_b(g, Vector3(1.24, 0.06, 0.48), Vector3(xa, 1.93, -0.02), "paint_grey", "cimalha")
	for lado: float in [-1.0, 1.0]:
		_b(g, Vector3(0.56, 0.95, 0.015), Vector3(xa + lado * 0.29, 1.36, 0.205), "glass_scratch", "porta_vidro")
		_b(g, Vector3(0.56, 0.78, 0.02), Vector3(xa + lado * 0.29, 0.46, 0.205), "paint_grey", "porta")
		_b(g, Vector3(0.02, 0.10, 0.02), Vector3(xa + lado * 0.04, 0.80, 0.225), "steel", "puxador")
	_b(g, Vector3(1.2, 0.07, 0.012), Vector3(xa, 0.90, 0.21), "paint_red", "faixa_id")
	var garrafa := _garrafa()
	for nivel in 3:
		_b(g, Vector3(1.10, 0.02, 0.34), Vector3(xa, 0.98 + float(nivel) * 0.30, 0.0), "steel", "prateleira")
		var xr := xa - 0.48
		while xr < xa + 0.48:
			var alt := rng.randf_range(0.09, 0.17)
			G3D.peca(g, garrafa, Vector3(xr, 0.99 + float(nivel) * 0.30, 0.05 + rng.randf_range(-0.06, 0.06)),
					Mats.get_mat("copper" if rng.randf() < 0.45 else "paint_white"), Vector3.ZERO,
					Vector3(alt * 0.9, alt, alt * 0.9), "remedio")
			xr += alt * 0.45 + rng.randf_range(0.03, 0.16)
	G3D.colisor(g, Vector3(1.2, 1.9, 0.46), Vector3(xa, 0.95, -0.02))

	# pia de louça em coluna, torneira e espelho
	var xp := 0.55
	_c(g, 0.10, 0.74, Vector3(xp, 0.37, -0.02), "paint_white", Vector3.ZERO, 12)
	G3D.peca(g, _panela(), Vector3(xp, 0.72, 0.0), Mats.get_mat("paint_white"), Vector3.ZERO, Vector3(0.52, 0.16, 0.42), "cuba")
	_c(g, 0.016, 0.16, Vector3(xp, 0.96, -0.17), "steel", Vector3.ZERO, 6)
	G3D.peca(g, MeshKit.cotovelo(0.016, 0.07, PI, 6, 8), Vector3(xp, 1.04, -0.10), Mats.get_mat("steel"),
			Vector3(0, PI * 0.5, 0), Vector3.ONE, "bica")
	_b(g, Vector3(0.46, 0.60, 0.02), Vector3(xp, 1.58, -0.23), "glass_scratch", "espelho")
	_b(g, Vector3(0.50, 0.64, 0.015), Vector3(xp, 1.58, -0.24), "steel", "moldura")
	# lixeira
	_c(g, 0.15, 0.42, Vector3(xp + 0.55, 0.21, 0.0), "paint_white", Vector3.ZERO, 12)
	_c(g, 0.155, 0.03, Vector3(xp + 0.55, 0.435, 0.0), "steel", Vector3.ZERO, 12)
	G3D.colisor(g, Vector3(0.5, 0.85, 0.42), Vector3(xp, 0.42, 0.0))
	return g


## Bateria de cilindros de oxigênio presos à parede.
static func bateria_o2(parent: Node3D, pos: Vector3, yaw: float, n := 4) -> Node3D:
	var g := _grupo(parent, "BateriaO2", pos, yaw)
	var passo := 0.34
	var larg := passo * float(n)
	_b(g, Vector3(larg + 0.1, 0.08, 0.36), Vector3(0, 0.04, 0), "metal_rust", "berco")
	_b(g, Vector3(larg + 0.1, 0.05, 0.03), Vector3(0, 0.95, -0.17), "steel", "barra")
	_c(g, 0.010, larg + 0.06, Vector3(0, 0.95, 0.165), "steel", Vector3(0, 0, PI * 0.5), 6)
	for i in n:
		Dressing.cylinder(g, Vector3(-larg * 0.5 + passo * (float(i) + 0.5), 0.08, 0.0), 0)
	_c(g, 0.012, larg, Vector3(0, 1.52, -0.10), "copper", Vector3(0, 0, PI * 0.5), 6)
	_b(g, Vector3(0.16, 0.16, 0.08), Vector3(larg * 0.5 + 0.02, 1.52, -0.12), "paint_grey", "regulador")
	_c(g, 0.045, 0.02, Vector3(larg * 0.5 + 0.02, 1.52, -0.07), "paint_white", Vector3(PI * 0.5, 0, 0), 10)
	return g


# ================================================================ COMANDO
## Gabinete de computador de fita: carretéis atrás do vidro, fileiras de luzes.
static func rack_fita(parent: Node3D, pos: Vector3, yaw: float, semente := 1) -> Node3D:
	var g := _grupo(parent, "RackFita", pos, yaw)
	var rng := RandomNumberGenerator.new()
	rng.seed = semente
	var w := 0.96
	var h := 1.95
	var prof := 0.70
	_b(g, Vector3(w, h - 0.10, prof), Vector3(0, 0.10 + (h - 0.10) * 0.5, 0), "paint_grey", "gabinete")
	_b(g, Vector3(w - 0.06, 0.10, prof - 0.08), Vector3(0, 0.05, 0), "rubber", "rodape")
	var zf := prof * 0.5
	_b(g, Vector3(w - 0.16, 0.62, 0.02), Vector3(0, 1.50, zf + 0.002), "plastic_dark", "fundo_fita")
	for lado: float in [-1.0, 1.0]:
		_c(g, 0.16, 0.025, Vector3(lado * 0.20, 1.58, zf + 0.025), "steel", Vector3(PI * 0.5, 0, rng.randf() * TAU), 14)
		_c(g, 0.05, 0.035, Vector3(lado * 0.20, 1.58, zf + 0.03), "plastic_old", Vector3(PI * 0.5, 0, 0), 8)
	_b(g, Vector3(0.18, 0.07, 0.03), Vector3(0, 1.30, zf + 0.022), "steel", "cabecote")
	_b(g, Vector3(w - 0.12, 0.66, 0.012), Vector3(0, 1.50, zf + 0.05), "glass", "vidro")
	for lado: float in [-1.0, 1.0]:
		_b(g, Vector3(0.03, 0.70, 0.07), Vector3(lado * (w * 0.5 - 0.06), 1.50, zf + 0.03), "steel", "caixilho")
	# painel de luzes (algumas acesas em âmbar/verde, o resto morto)
	_b(g, Vector3(w - 0.16, 0.30, 0.02), Vector3(0, 0.96, zf + 0.004), "plastic_dark", "painel")
	for linha in 3:
		for col in 10:
			var m: Material = Mats.get_mat("plastic_old")
			if rng.randf() < 0.22:
				m = Mats.emissive_c(Color(1.0, 0.62, 0.2) if rng.randf() < 0.6 else Color(0.35, 0.92, 0.68), 0.9)
			G3D.box(g, Vector3(0.035, 0.035, 0.012), Vector3(-0.315 + float(col) * 0.07, 1.04 - float(linha) * 0.08, zf + 0.018),
					m, false, Vector3.ZERO, "luz_painel")
	for col in 6:
		_b(g, Vector3(0.03, 0.06, 0.03), Vector3(-0.30 + float(col) * 0.12, 0.72, zf + 0.015), "steel", "chave",
				Vector3(rng.randf_range(-0.5, 0.5), 0, 0))
	for k in 6:
		_b(g, Vector3(w - 0.20, 0.022, 0.02), Vector3(0, 0.22 + float(k) * 0.065, zf + 0.006), "plastic_dark", "aleta")
	G3D.colisor(g, Vector3(w, h, prof), Vector3(0, h * 0.5, 0))
	return g


## Mesa de plotagem: tampo iluminado por baixo, carta e instrumentos.
static func mesa_plotagem(parent: Node3D, pos: Vector3, yaw: float) -> Node3D:
	var g := _grupo(parent, "MesaPlotagem", pos, yaw)
	var w := 2.4
	var d := 1.5
	_b(g, Vector3(w - 0.3, 0.80, d - 0.3), Vector3(0, 0.45, 0), "paint_olive", "pedestal")
	_b(g, Vector3(w - 0.2, 0.10, d - 0.2), Vector3(0, 0.05, 0), "rubber", "rodape")
	_b(g, Vector3(w, 0.12, d), Vector3(0, 0.90, 0), "paint_grey", "aro")
	G3D.box(g, Vector3(w - 0.16, 0.02, d - 0.16), Vector3(0, 0.962, 0),
			Mats.emissive_c(Color(0.30, 0.52, 0.48), 0.55), false, Vector3.ZERO, "tampo_luz")
	_b(g, Vector3(1.3, 0.004, 0.9), Vector3(-0.25, 0.975, 0.05), "paper", "carta", Vector3(0, 0.08, 0))
	_b(g, Vector3(1.5, 0.012, 0.05), Vector3(-0.1, 0.985, -0.18), "plastic_old", "regua", Vector3(0, -0.2, 0))
	for p: Vector3 in [Vector3(-0.85, 0.99, -0.35), Vector3(0.35, 0.99, 0.45)]:
		_c(g, 0.035, 0.03, p, "copper", Vector3.ZERO, 8)
	G3D.peca(g, _caneca(), Vector3(0.95, 0.972, -0.5), Mats.get_mat("paint_white"), Vector3.ZERO, Vector3.ONE, "caneca")
	# luminária de braço
	_c(g, 0.016, 0.55, Vector3(1.05, 1.24, 0.55), "steel", Vector3.ZERO, 6)
	_b(g, Vector3(0.50, 0.03, 0.03), Vector3(0.82, 1.50, 0.42), "steel", "braco", Vector3(0, -0.5, 0))
	G3D.peca(g, _prato_luz(), Vector3(0.60, 1.46, 0.30), Mats.get_mat("paint_olive"), Vector3.ZERO,
			Vector3(0.26, 0.4, 0.26), "cupula")
	G3D.colisor(g, Vector3(w, 0.96, d), Vector3(0, 0.48, 0))
	return g


## Poltrona de operador: base giratória, assento e encosto estofados, braços.
static func poltrona(parent: Node3D, pos: Vector3, yaw: float) -> Node3D:
	var g := _grupo(parent, "Poltrona", pos, yaw)
	_c(g, 0.26, 0.04, Vector3(0, 0.02, 0), "steel", Vector3.ZERO, 14)
	_c(g, 0.045, 0.40, Vector3(0, 0.24, 0), "steel")
	_b(g, Vector3(0.52, 0.11, 0.50), Vector3(0, 0.49, 0), "fabric", "assento")
	_b(g, Vector3(0.50, 0.66, 0.10), Vector3(0, 0.86, -0.24), "fabric", "encosto", Vector3(-0.10, 0, 0))
	_b(g, Vector3(0.30, 0.16, 0.09), Vector3(0, 1.26, -0.28), "fabric", "apoio_cabeca", Vector3(-0.10, 0, 0))
	for lado: float in [-1.0, 1.0]:
		_b(g, Vector3(0.06, 0.05, 0.36), Vector3(lado * 0.29, 0.70, -0.02), "plastic_dark", "braco")
		_b(g, Vector3(0.04, 0.18, 0.04), Vector3(lado * 0.29, 0.60, 0.08), "steel", "haste_braco")
	G3D.colisor(g, Vector3(0.55, 0.9, 0.55), Vector3(0, 0.45, 0))
	return g
