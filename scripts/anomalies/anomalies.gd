class_name Anomalies
extends RefCounted
## Todas as manifestações do fenômeno. Cada uma é pequena, ambígua e
## nunca explica nada: o jogador vê, o jogo não comenta.

static var _rng := RandomNumberGenerator.new()
static var _screen_cache: Dictionary = {}


static func run(id: String, ctx: Dictionary = {}) -> void:
	if _rng.seed == 0:
		_rng.seed = 991177
	match id:
		"porta_aberta": _porta_aberta(ctx)
		"objeto_movido": _objeto_movido(ctx)
		"corredor_estendido": _corredor_estendido(ctx)
		"cam_fantasma": _cam_fantasma(ctx)
		"foto_extra": _foto_extra(ctx)
		"radio_voz": _radio_voz(ctx)
		"eco_passos": _eco_passos(ctx)
		"espelho_agua": _espelho_agua(ctx)
		"sino": _sino(ctx)
		"manifesto_iris": _manifesto_iris(ctx)
		"manifesto_andrei": _manifesto_andrei(ctx)
		"coro": _coro(ctx)
		"terra_falsa": _terra_falsa(ctx)
		"mao_no_vidro": _mao_no_vidro(ctx)
		"trilha_molhada": _trilha_molhada(ctx)
		"sala_reconstruida": _sala_reconstruida(ctx)
		"orgao": _orgao(ctx)
		_:
			return
	_mark(id)


static func _mark(id: String) -> void:
	var a: Dictionary = Content.get_anomaly(id)
	if a.has("resonance"):
		GameState.add_resonance(int(a["resonance"]))
	if a.has("trust"):
		GameState.add_trust(int(a["trust"]))
	GameState.seen_anomaly(id)
	UI.play_stress(0.15 + float(a.get("resonance", 1)) * 0.09, 7.0)


static func _host() -> Node3D:
	return Director.world


static func _fig(kind_s: String, pos: Vector3, yaw := 0.0) -> Manifestation:
	var m := Manifestation.new()
	match kind_s:
		"coro": m.kind = Manifestation.Kind.CORO
		"iris": m.kind = Manifestation.Kind.IRIS
		"andrei": m.kind = Manifestation.Kind.ANDREI
		"sombra": m.kind = Manifestation.Kind.SOMBRA
		"nadia": m.kind = Manifestation.Kind.NADIA
		"tomas": m.kind = Manifestation.Kind.TOMAS
		_: m.kind = Manifestation.Kind.GENERICA
	m.position = pos
	m.rotation.y = yaw
	_host().add_child(m)
	return m


# ================================================================ PEQUENAS
static func _porta_aberta(_ctx: Dictionary) -> void:
	var cands: Array = []
	var player := _player_pos()
	for id: String in Director.doors.keys():
		var d: Door = Director.doors[id]
		if is_instance_valid(d) and d.state == Door.State.CLOSED and d.powered and not d.locked:
			if player.distance_to(d.global_position) > 6.0 and player.distance_to(d.global_position) < 60.0:
				cands.append(d)
	if cands.is_empty():
		return
	var d2: Door = cands[_rng.randi_range(0, cands.size() - 1)]
	d2.force_open()
	UI.subtitle("", "Uma porta se abre ao longe. Você tinha fechado ela.", 4.5)
	AudioMan.play_3d("door", d2.global_position, -8.0, 0.9)


static func _objeto_movido(_ctx: Dictionary) -> void:
	if Director.props.size() < 2:
		return
	var a: Node3D = Director.props[_rng.randi_range(0, Director.props.size() - 1)]
	var b: Node3D = Director.props[_rng.randi_range(0, Director.props.size() - 1)]
	if not is_instance_valid(a) or not is_instance_valid(b) or a == b:
		return
	var pa := a.global_position
	var pb := b.global_position
	if pa.distance_to(pb) > 40.0:
		return
	var tw := a.create_tween()
	tw.set_parallel(true)
	tw.tween_property(a, "global_position", pb, 2.5).set_trans(Tween.TRANS_SINE)
	tw.tween_property(b, "global_position", pa, 2.5).set_trans(Tween.TRANS_SINE)
	AudioMan.play_3d("clank", pa, -14.0)
	UI.subtitle("", "Alguma coisa trocou de lugar. Você não viu quando.", 4.0)


static func _corredor_estendido(_ctx: Dictionary) -> void:
	for e: Dictionary in Director.extendables:
		var node: Node3D = e.get("node", null)
		if is_instance_valid(node) and not node.visible:
			node.visible = true
			var false_wall: Node3D = e.get("false_wall", null)
			if is_instance_valid(false_wall):
				false_wall.visible = false
				for c in false_wall.get_children():
					if c is StaticBody3D:
						(c as StaticBody3D).process_mode = Node.PROCESS_MODE_DISABLED
			AudioMan.play_3d("creak", node.global_position, -8.0)
			UI.play_stress(0.35, 8.0)
			UI.subtitle("", "O corredor de serviço é mais longo por dentro do que deveria ser. Você tem certeza de que já passou por aqui.", 6.0)
			return


static func _cam_fantasma(ctx: Dictionary) -> void:
	var pos: Vector3 = Director.poi_of("corredor_leste", Vector3(15, 40, 0))
	var player := _player_pos()
	# se o jogador estiver no corredor leste, aparece em outro lugar
	if player.distance_to(pos) < 18.0:
		pos = Director.poi_of("anel_norte", Vector3(0, 40, -16))
	var f := _fig("sombra", pos + Vector3(_rng.randf_range(-3, 3), 0, _rng.randf_range(-3, 3)), _rng.randf_range(0, TAU))
	CamGrid.set_glitch("cam_07", 0.7)
	CamGrid.set_glitch("cam_02", 0.35)
	if bool(ctx.get("linked", false)):
		UI.subtitle("", "Há alguém nas câmeras. Figura parada, de costas, no meio do corredor.", 5.0)
	AudioMan.play_2d("static", -16.0, 1.0, "Radio")
	Director.after(26.0, func() -> void:
		if is_instance_valid(f):
			if f.has_method("dissolve"):
				f.dissolve()
		CamGrid.set_glitch("cam_07", 0.0)
		CamGrid.set_glitch("cam_02", 0.0))


static func _foto_extra(_ctx: Dictionary) -> void:
	GameState.set_flag("foto_extra")
	GameState.add_note("FOTOGRAFIA", "A foto da tripulação tem seis pessoas. A legenda continua dizendo cinco.")
	UI.subtitle("", "Você reabre a fotografia da tripulação. Agora são seis.", 4.5)


static func _radio_voz(_ctx: Dictionary) -> void:
	AudioMan.play_2d("static", -6.0, 1.0, "Radio")
	Director.after(1.2, func() -> void:
		UI.say([
			{"who": "?", "text": "K-9. Você está demorando mais do que o normal.", "dur": 3.6},
			{"who": "?", "text": "Não tem problema. Eu não me importo de esperar.", "dur": 3.4},
			{"who": "?", "text": "Eu só queria saber se você também me vê do outro lado do vidro.", "dur": 4.6},
		], "voz_extra", null, true)
		AudioMan.play_2d("static", -10.0, 1.0, "Radio"))
	Director.after(10.0, func() -> void:
		UI.show_note("CANAL SEM ORIGEM", "O transceptor aceitou a transmissão sem registrar frequência de envio."))


static func _eco_passos(_ctx: Dictionary) -> void:
	Director.echo_steps = 16
	UI.subtitle("", "Alguém anda exatamente quando você anda. Meio segundo depois.", 4.5)
	AudioMan.play_3d("step", _player_pos() + Vector3(1.5, 0, 1.5), -14.0, 0.92)


static func _espelho_agua(_ctx: Dictionary) -> void:
	var pos: Vector3 = Director.poi_of("anel_oeste", Vector3(-16, 40, 0))
	pos += Vector3(_rng.randf_range(-1, 1), 0.03, _rng.randf_range(-1, 1))
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.03, 0.05, 0.06, 0.95)
	m.roughness = 0.02
	m.metallic = 0.6
	var mi := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(1.6, 1.2)
	mi.mesh = pm
	mi.material_override = m
	mi.position = pos
	mi.rotation.x = -PI * 0.5
	_host().add_child(mi)
	var refl := _fig("sombra", pos + Vector3(0, -1.2, 0), 0.0)
	refl.rotate_x(PI)
	refl.scale = Vector3(0.9, 0.9, 0.9)
	AudioMan.play_3d("drip", pos, -6.0)
	Director.after(40.0, func() -> void:
		if is_instance_valid(mi):
			mi.queue_free()
		if is_instance_valid(refl):
			refl.dissolve())


static func _sino(_ctx: Dictionary) -> void:
	GameState.set_flag("ouviu_sino")
	UI.play_stress(0.55, 10.0)
	Director.flicker_lights(5.0, 0.7)
	AudioMan.play_3d("bell", Director.bell_pos, -2.0, 1.0, 60.0)
	AudioMan.theme_ocean(0.5)
	UI.subtitle("", "O casco inteiro toca uma nota só. Longa demais. Como se algo embaixo do mar tivesse batido com a mão aberta.", 6.0)
	Director.after(4.0, func() -> void:
		if GameState.has("ouviu_sino") and not GameState.has("sino_respondeu"):
			GameState.set_flag("sino_respondeu")
			Ocean.pulse(Director.bell_pos, 1.2, 0.0)
			AudioMan.play_3d("bell", Director.bell_pos, -8.0, 0.6, 60.0))
	if _player_in_sector("sino"):
		Director.after(6.0, func() -> void: _manifesto_andrei({}))


# ================================================================ MANIFESTAÇÕES
static func _manifesto_iris(_ctx: Dictionary) -> void:
	if GameState.has("iris_apareceu") and GameState.count("manifesto_iris") > 0:
		return
	GameState.set_flag("iris_apareceu")
	var pos: Vector3 = Director.poi_of("observatorio", Vector3(0, 76.5, 8))
	var hostile := GameState.trust <= -2
	var lines: Array = Content.get_dialogue("iris_fria" if hostile else "iris_1")["lines"]
	var voice := "" if hostile else String(Content.get_dialogue("iris_1").get("voice", "iris_01"))
	var f := _fig("iris", pos, PI)
	f.setup("ÍRIS", Manifestation.Kind.IRIS, lines, voice, "" if hostile else "espelho")
	UI.play_stress(0.6, 12.0)
	UI.subtitle("", "Alguém está de pé diante da janela do módulo de observação. A luz do mar atravessa ela e some no chão.", 6.0)
	AudioMan.theme_ocean(0.8)
	GameState.add_count("manifesto_iris")


static func _manifesto_andrei(_ctx: Dictionary) -> void:
	if GameState.count("manifesto_andrei") > 0:
		return
	GameState.add_count("manifesto_andrei")
	var pos: Vector3 = Director.poi_of("camara_sino", Director.bell_pos) + Vector3(0, 0, 2.5)
	var lines: Array = Content.get_dialogue("andrei_1")["lines"]
	var f := _fig("andrei", pos, 0.0)
	f.setup("ANDREI", Manifestation.Kind.ANDREI, lines, String(Content.get_dialogue("andrei_1").get("voice", "andrei_02")))
	f.on_end = func() -> void:
		GameState.unlock("e_kolokol")
		GameState.add_note("PORTA-VOZES DO SINO", "Andrei decodificou 1 dos 47 padrões. O resultado que ele nunca escreveu no relatório está agora com você.")
	AudioMan.play_3d("bell", Director.bell_pos, -12.0, 0.5, 60.0)
	UI.subtitle("", "Andrei está sentado na câmara do sino, com a mão apoiada no metal, como quem escuta por um estetoscópio.", 6.0)


static func _coro(_ctx: Dictionary) -> void:
	if GameState.count("coro") > 0 and not GameState.has("final_"):
		pass
	GameState.add_count("coro")
	var base: Vector3 = Director.poi_of("refeitorio", Vector3(30, 40, 6))
	UI.play_stress(0.8, 16.0)
	Director.flicker_lights(8.0, 0.5)
	GameState.add_resonance(1)
	for i in 4:
		var ang := TAU * float(i) / 4.0
		var p := base + Vector3(cos(ang) * 2.4, 0, sin(ang) * 2.4)
		var f := _fig("coro", p, -ang + PI * 0.5)
		f.setup("HÓSPEDE", Manifestation.Kind.CORO, [
			{"who": "CORO", "text": "…por que vocês guardam uns aos outros?", "dur": 4.0},
		], "", "")
	AudioMan.theme_ocean(0.9)
	UI.subtitle("", "Quatro pessoas sentadas onde a tripulação costumava jantar. Nenhuma delas respira no ritmo certo.", 6.5)
	Director.after(30.0, func() -> void:
		for f in Director.figures.duplicate():
			if is_instance_valid(f) and f.has_method("dissolve"):
				f.dissolve())


static func _orgao(ctx: Dictionary) -> void:
	var pos: Vector3 = Director.poi_of("lab_mesa", Vector3(-30, 52.9, 0))
	var mat := Mats.tinted_color(Color(0.42, 0.14, 0.13), 0.55)
	var mass := Node3D.new()
	mass.position = pos
	_host().add_child(mass)
	for i in 5:
		G3D.sphere(mass, 0.16 + 0.05 * float(i % 3), Vector3(_rng.randf_range(-0.18, 0.18), 0.06 + 0.07 * float(i), _rng.randf_range(-0.18, 0.18)), mat, 12)
	var pulse := mass.create_tween().set_loops()
	pulse.tween_property(mass, "scale", Vector3(1.06, 1.12, 1.06), 0.9).set_trans(Tween.TRANS_SINE)
	pulse.tween_property(mass, "scale", Vector3.ONE, 0.9).set_trans(Tween.TRANS_SINE)
	var inter := Interactable.create("Examinar massa em formação", Vector3(1.2, 1.0, 1.2), Vector3(0, 0.5, 0),
		func(_p: Node3D, _i: Interactable) -> void:
			AudioMan.play_3d("drip", mass.global_position, -8.0)
			if GameState.decision("orgao") == "":
				UI.ask_decision("orgao"))
	inter.data = {"anomaly": "orgao"}
	mass.add_child(inter)
	UI.subtitle("", "Sobre a mesa de exames, algo está se formando: tecido, membrana, calor. Sem batimentos. Ainda.", 6.0)
	Director.after(90.0, func() -> void:
		if is_instance_valid(mass):
			mass.queue_free())


# ================================================================ OCEANO E JANELAS
static func _terra_falsa(_ctx: Dictionary) -> void:
	var anchor: Vector3 = Director.poi_of("janela_sul", Vector3(30, 42.5, 12.2))
	var img := _familiar_image()
	var tex := ImageTexture.create_from_image(img)
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = tex
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.emission_enabled = true
	mat.emission_texture = tex
	mat.emission_energy_multiplier = 0.75
	var mi := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(14.0, 5.4)
	mi.mesh = pm
	mi.material_override = mat
	mi.position = anchor + Vector3(0, 0, 3.0)
	mi.rotation.y = PI
	_host().add_child(mi)
	# reforço de luz vindo de fora
	var l := OmniLight3D.new()
	l.light_color = Color(0.95, 0.8, 0.6)
	l.light_energy = 1.6
	l.omni_range = 16.0
	l.position = anchor + Vector3(0, 0, 2.0)
	_host().add_child(l)
	AudioMan.set_layer("water", 0.05)
	UI.play_stress(0.5, 12.0)
	UI.subtitle("", "Pela janela sul não está o oceano. Está um lugar que você conhece — ruas, telhados, uma praça. Está vivo. Está quente.", 7.0)
	Director.after(16.0, func() -> void:
		if is_instance_valid(mi):
			mi.queue_free()
		if is_instance_valid(l):
			l.queue_free()
		AudioMan.set_ocean_energy(GameState.resonance / 10.0)
		UI.subtitle("", "Depois, é só o mar outra vez. E o mar finge que nunca foi outra coisa.", 5.0))


static func _familiar_image() -> Image:
	if _screen_cache.has("familiar"):
		return _screen_cache["familiar"]
	var w := 256
	var h := 100
	var img := Image.create(w, h, false, Image.FORMAT_RGB8)
	for y in h:
		var t := float(y) / float(h)
		img.fill_rect(Rect2i(0, y, w, 1), Color(0.10, 0.12, 0.20).lerp(Color(0.42, 0.30, 0.24), t))
	img.fill_rect(Rect2i(0, int(h * 0.62), w, h), Color(0.13, 0.13, 0.12))
	var rng := RandomNumberGenerator.new()
	rng.seed = 8899
	for i in 26:
		var bx := rng.randi_range(0, w - 18)
		var by := rng.randi_range(int(h * 0.30), int(h * 0.60))
		var bh := int(h * 0.62) - by
		img.fill_rect(Rect2i(bx, by, 14, bh), Color(0.10, 0.10, 0.11))
		if rng.randf() < 0.6:
			img.fill_rect(Rect2i(bx + 3, by + 4, 4, 4), Color(0.95, 0.78, 0.42))
	img.fill_rect(Rect2i(int(w * 0.44), int(h * 0.66), int(w * 0.14), int(h * 0.34)), Color(0.08, 0.09, 0.10))
	img.fill_rect(Rect2i(int(w * 0.48), int(h * 0.70), int(w * 0.06), int(h * 0.26)), Color(0.70, 0.78, 0.82))
	_screen_cache["familiar"] = img
	return img


static func _mao_no_vidro(_ctx: Dictionary) -> void:
	var anchor: Vector3 = Director.poi_of("janela_sul", Vector3(30, 42.5, 12.2))
	var img := _hand_image()
	var tex := ImageTexture.create_from_image(img)
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = tex
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(1, 1, 1, 0.75)
	mat.emission_enabled = true
	mat.emission_texture = tex
	mat.emission = Color(0.6, 0.85, 0.95)
	mat.emission_energy_multiplier = 0.5
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	var mi := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(0.9, 1.1)
	mi.mesh = pm
	mi.material_override = mat
	mi.position = anchor + Vector3(_rng.randf_range(-2.5, 2.5), 0.2, 0.12)
	mi.rotation.y = PI
	_host().add_child(mi)
	var pos := mi.position
	var inter := Interactable.create("Tocar no vidro", Vector3(1.0, 1.3, 0.6), Vector3.ZERO,
		func(_p: Node3D, _i: Interactable) -> void:
			AudioMan.play_2d("drip", -8.0)
			UI.play_stress(0.7, 10.0)
			UI.subtitle("", "O vidro está quente, e molhado do lado de dentro. A impressão da mão desaparece devagar, como se alguém a estivesse recolhendo.", 6.0)
			for c in Director.world.get_children():
				pass
			if is_instance_valid(mi):
				mi.queue_free())
	mi.add_child(inter)
	AudioMan.play_3d("drip", anchor, -6.0)
	UI.subtitle("", "Do lado de fora do vidro da janela sul: a marca de uma mão humana. Do lado de dentro.", 5.5)


static func _hand_image() -> Image:
	if _screen_cache.has("hand"):
		return _screen_cache["hand"]
	var w := 128
	var h := 160
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var c := Color(0.85, 0.95, 1.0, 0.55)
	img.fill_rect(Rect2i(36, 60, 56, 62), c)          # palma
	for i in 5:
		var fx := 36 + i * 11
		var fh := 46 if i == 0 else (62 if i == 2 else 54)
		img.fill_rect(Rect2i(fx, 60 - fh + 46, 9, fh), c)
	img.fill_rect(Rect2i(30, 92, 14, 34), c)          # polegar
	# borrar (halo)
	for y in h:
		for x in w:
			var col := img.get_pixel(x, y)
			if col.a > 0.0:
				for dx in range(-1, 2):
					for dy in range(-1, 2):
						var nx := clampi(x + dx, 0, w - 1)
						var ny := clampi(y + dy, 0, h - 1)
						var o := img.get_pixel(nx, ny)
						if o.a < col.a * 0.5:
							img.set_pixel(nx, ny, Color(col.r, col.g, col.b, col.a * 0.5))
	_screen_cache["hand"] = img
	return img


static func _trilha_molhada(_ctx: Dictionary) -> void:
	var start: Vector3 = Director.poi_of("anel_leste", Vector3(16, 40.02, 0))
	var wall_x := 18.0
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.03, 0.05, 0.06, 0.7)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.roughness = 0.15
	for i in 9:
		var t := float(i) / 8.0
		var mi := MeshInstance3D.new()
		var pm := PlaneMesh.new()
		pm.size = Vector2(0.3, 0.16)
		mi.mesh = pm
		mi.material_override = m
		mi.position = start.lerp(Vector3(wall_x - 0.4, start.y, start.z), t) + Vector3(0, 0, sin(t * 3.0) * 0.2)
		mi.rotation.x = -PI * 0.5
		mi.rotation.y = _rng.randf_range(-0.4, 0.4)
		_host().add_child(mi)
	AudioMan.play_3d("drip", start, -10.0)
	UI.subtitle("", "Pegadas molhadas atravessam o corredor. A última delas está virada para a parede — e para ali.", 5.5)


static func _sala_reconstruida(_ctx: Dictionary) -> void:
	if GameState.count("sala_reconstruida") > 0:
		return
	GameState.add_count("sala_reconstruida")
	var ruined := _host().get_node_or_null("Refeitorio_Ruina")
	var intact := _host().get_node_or_null("Refeitorio_Intacto")
	if ruined != null:
		ruined.visible = false
	if intact != null:
		intact.visible = true
	UI.play_stress(0.6, 14.0)
	AudioMan.play_2d("swell", -10.0)
	UI.subtitle("", "Você entra no refeitório e ele está intacto. As cadeiras no lugar, as mesas limpas, o café ainda quente. Ontem isto aqui era um amontoado de metal torcido.", 8.0)
	var base: Vector3 = Director.poi_of("refeitorio", Vector3(30, 40, 6))
	for i in 4:
		var ang := TAU * float(i) / 4.0
		var f := _fig("coro", base + Vector3(cos(ang) * 1.6, 0, sin(ang) * 1.6), -ang + PI * 0.5)
		f.setup("TRIPULANTE", Manifestation.Kind.CORO, [], "", "")
	Director.after(26.0, func() -> void:
		for f in Director.figures.duplicate():
			if is_instance_valid(f) and f.has_method("dissolve"):
				f.dissolve()
		AudioMan.play_3d("creak", base, -8.0))


# ================================================================ UTIL
static func _player_pos() -> Vector3:
	for n in Engine.get_main_loop().get_nodes_in_group("player"):
		return (n as Node3D).global_position
	return Vector3.ZERO


static func _player_in_sector(sector: String) -> bool:
	for n in Engine.get_main_loop().get_nodes_in_group("player"):
		if String(n.get("_sector")) == sector:
			return true
	return false
