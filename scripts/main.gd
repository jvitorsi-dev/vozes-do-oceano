extends Node3D
## Main — montagem do mundo: céu, oceano de ÍRIO, a estação ARGOS-4,
## o jogador, a câmera do menu e a ligação entre tudo.

const STARS := preload("res://assets/shaders/stars.gdshader")
const PLANET := preload("res://assets/shaders/planet.gdshader")

var world_root: Node3D
var player: Player
var menu_cam: Camera3D
var sky_sphere: MeshInstance3D
var sea: MeshInstance3D
var sea_far: MeshInstance3D
var imitations: Array[Node3D] = []
var started := false
var _menu_t := 0.0
var _sea_energies: Array[float] = []

# modos de inspeção: --autostart (pula o menu) / --shot (passeio de câmera)
var _autostart := false
var _shot := false
var _shot_i := -1
var _shot_only := ""
var _selftest := false
var _probe_mode := false
var _matsheet := false
var _peso := false
var _play_menu := false
var _play := false
var _shot_frames := 0
var _inspecao_feita := false
var _shot_real := false
var _shot_real_forca := false
## Tomadas repetidas no modo --real (uma por tipo de ambiente).
const SHOTS_REAIS := ["hangar", "anel", "refeitorio", "comando", "engenharia", "deposito",
		"cabines", "enfermaria", "corredorobs", "observatorio"]
## Quadros de acomodação antes de gravar cada tomada. Era 45, o que tornava
## cada captura Vulkan muito longa na máquina de build; 12 já estabiliza
## iluminação, névoa e TAA.
const SHOT_SETTLE := 12
const SHOTS := [
	{"pos": Vector3(-6.0, 42.4, -24.0), "look": Vector3(4.0, 42.0, -40.0), "nome": "hangar"},
	{"pos": Vector3(-10.0, 42.0, -15.5), "look": Vector3(14.0, 41.6, -12.0), "nome": "anel"},
	{"pos": Vector3(-3, 42.6, 24.0), "look": Vector3(0, 42.2, 39.5), "nome": "refeitorio"},
	{"pos": Vector3(0, 78.0, 0.0), "look": Vector3(0, 76.6, 19.5), "nome": "observatorio"},
	{"pos": Vector3(46, 78.0, 46.0), "look": Vector3(0, 62.0, 0.0), "nome": "exterior"},
	{"pos": Vector3(-30, 62.0, 120.0), "look": Vector3(0, 4.0, 420.0), "nome": "oceano"},
	{"pos": Vector3(0, 78.6, 6.0), "look": Vector3(0, 77.4, 19.4), "nome": "janela", "res": 6},
	{"pos": Vector3(-11.0, 65.9, -19.6), "look": Vector3(5, 64.7, -31.0), "nome": "comando", "res": 0},
	{"pos": Vector3(14, 40.8, -6.0), "look": Vector3(-2, 41.4, -14.0), "nome": "manifesto", "res": 4, "fig": Vector3(2, 40.0, -12.0)},
	{"pos": Vector3(0, 64.4, 21.0), "look": Vector3(0, 64.6, 25.0), "nome": "sino", "res": 3},
	{"pos": Vector3(-4, 42.4, 22.0), "look": Vector3(0, 42.0, 39.4), "nome": "refeitorio_luz", "res": 2},
	{"pos": Vector3(24.5, 53.0, 9.6), "look": Vector3(28.6, 53.6, 1.0), "nome": "engenharia"},
	{"pos": Vector3(-27.0, 42.4, 4.0), "look": Vector3(-37.0, 41.8, -6.0), "nome": "deposito"},
	{"pos": Vector3(21.5, 42.4, 4.0), "look": Vector3(34.0, 41.9, -9.0), "nome": "cabines"},
	{"pos": Vector3(21.0, 65.8, -0.6), "look": Vector3(34.0, 65.2, 1.4), "nome": "corredorobs"},
	{"pos": Vector3(-8.0, 54.4, 22.0), "look": Vector3(9.0, 53.8, 33.0), "nome": "enfermaria"},
	{"pos": Vector3(-28.0, 66.4, 5.0), "look": Vector3(-38.0, 65.8, -3.0), "nome": "eclusa"},
	{"pos": Vector3(-27.0, 54.4, 5.0), "look": Vector3(-36.5, 53.9, -5.0), "nome": "radio"},
	{"pos": Vector3(24.0, 78.4, 3.0), "look": Vector3(34.0, 77.9, -5.0), "nome": "antessala"},
	{"pos": Vector3(-2.0, 41.8, 22.5), "look": Vector3(-11.0, 40.9, 27.0), "nome": "cozinha"},
	{"pos": Vector3(-2.0, 53.8, -20.5), "look": Vector3(-12.0, 52.9, -29.0), "nome": "laboratorio"},
	{"pos": Vector3(2.0, 53.7, -29.0), "look": Vector3(8.0, 53.0, -37.0), "nome": "lab_tanques"},
	{"pos": Vector3(-3.0, 53.8, 28.5), "look": Vector3(-11.5, 52.9, 23.0), "nome": "enfermaria_posto"},
	{"pos": Vector3(-2.0, 65.7, -21.5), "look": Vector3(-13.0, 64.9, -28.0), "nome": "comando_racks"},
]


func _ready() -> void:
	randomize()
	_build_environment()
	_build_sea()

	world_root = Node3D.new()
	world_root.name = "Estacao"
	add_child(world_root)
	Station.build(world_root)

	_spawn_player()
	_build_menu_camera()

	Director.attach_world(world_root)
	UI.menu_start.connect(_on_menu_start)
	GameState.resonance_changed.connect(_on_resonance)

	# luz de emergência em toda a estação até a energia voltar
	UI.reset_for_new_run()
	if OS.has_feature("web"):
		# navegador: a captura do cursor costuma ser bloqueada — ensina o arrasto
		UI.hint_mouse(true)
	if GameState.has("energia_ok"):
		LampGrid.power_on()
	else:
		LampGrid.set_emergency_energy(0.45)
	AudioMan.music_intensity(0.12)
	AudioMan.set_ocean_energy(0.18)
	AudioMan.play_2d("sea", -30.0)

	for a: String in OS.get_cmdline_user_args():
		if a == "--autostart":
			_autostart = true
		elif a == "--shot":
			_shot = true
			_autostart = true
		elif a == "--real":
			# capturas com a luz REAL da partida (sem luz de inspeção)
			_shot_real = true
			_shot = true
			_autostart = true
		elif a == "--real-luz":
			# idem, mas com a energia da estação já restaurada
			_shot_real = true
			_shot_real_forca = true
			_shot = true
			_autostart = true
		elif a == "--play":
			_play = true
			_selftest = true
			_autostart = true
		elif a == "--play-menu":
			# teste do caminho mais importante de todos: o mouse no MENU
			_play = true
			_play_menu = true
			_selftest = true
		elif a == "--matsheet":
			_matsheet = true
		elif a == "--probe":
			_probe_mode = true
			_autostart = true
		elif a == "--selftest":
			_selftest = true
			_autostart = true
		elif a == "--peso":
			_peso = true
			_autostart = true
		elif a.begins_with("--only="):
			_shot_only = a.substr(7)
			_shot = true
			_autostart = true
	if _peso:
		_medir_peso()
		return
	if _matsheet:
		_dump_mats()
		get_tree().quit()
		return
	if _autostart:
		_on_menu_start()
		if _play:
			# carga dinâmica: o bot de QA não deve depender do cache de classes
			# globais do editor (assim o jogo também roda em build exportada)
			var pb: GDScript = load("res://scripts/dev/playbot.gd")
			pb.start(self)
		elif _probe_mode:
			Director.after(0.6, func() -> void: _probe(Vector3(7.4, 40.6, -16.3), 3.0))
		elif _selftest:
			_selftest_run()
	elif _play_menu:
		UI.open_menu()
		var pb2: GDScript = load("res://scripts/dev/playbot.gd")
		pb2.start(self)
	else:
		UI.open_menu()


# ================================================================ AMBIENTE
func _build_environment() -> void:
	var we := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.006, 0.010, 0.018)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.18, 0.245, 0.325)
	e.ambient_light_energy = 0.72
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	e.tonemap_white = 3.0
	e.glow_enabled = true
	e.glow_intensity = 0.9
	e.glow_bloom = 0.25
	e.glow_blend_mode = Environment.GLOW_BLEND_MODE_ADDITIVE
	e.glow_hdr_threshold = 0.85
	e.fog_enabled = true
	e.fog_light_color = Color(0.10, 0.20, 0.26)
	e.fog_light_energy = 1.2
	e.fog_density = 0.00035
	e.fog_sky_affect = 0.4
	e.fog_aerial_perspective = 0.4
	e.adjustment_enabled = true
	e.adjustment_contrast = 1.12
	e.adjustment_saturation = 0.88
	e.adjustment_brightness = 1.0
	# --- recursos de Forward+ (ignorados no renderizador de compatibilidade) ---
	# oclusão de ambiente: encaixa móveis, painéis e consoles no espaço
	e.ssao_enabled = true
	e.ssao_radius = 1.35
	e.ssao_intensity = 2.4
	e.ssao_power = 1.8
	e.ssao_detail = 0.6
	e.ssao_light_affect = 0.25
	# iluminação indireta em tela: cor "vaza" das superfícies claras
	e.ssil_enabled = true
	e.ssil_intensity = 1.1
	e.ssil_radius = 6.0
	# reflexos em tela: o piso encerado e o vidro passam a refletir o corredor
	e.ssr_enabled = true
	e.ssr_max_steps = 48
	e.ssr_fade_in = 0.25
	e.ssr_fade_out = 9.0
	e.ssr_depth_tolerance = 0.25
	# neblina volumétrica: dá corpo ao ar da estação e feixes de luz nas lâmpadas
	e.volumetric_fog_enabled = true
	e.volumetric_fog_density = 0.012
	e.volumetric_fog_albedo = Color(0.62, 0.72, 0.80)
	e.volumetric_fog_emission = Color(0.012, 0.020, 0.026)
	e.volumetric_fog_emission_energy = 0.7
	e.volumetric_fog_gi_inject = 0.7
	e.volumetric_fog_length = 64.0
	e.volumetric_fog_ambient_inject = 0.4
	# brilho mais fotográfico
	e.set_glow_level(1, 0.4)
	e.set_glow_level(3, 0.6)
	e.set_glow_level(5, 0.7)
	e.glow_map_strength = 0.45
	# Reflexo de ambiente. O fundo é preto (espaço), e era ele que os metais
	# refletiam: todo piso de chapa, tubo e painel metálico ficava preto por
	# mais luz que houvesse. Um céu neutro e fraco, usado SÓ como fonte de
	# reflexo (o fundo continua preto), devolve o brilho frio do aço.
	var ceu_mat := ProceduralSkyMaterial.new()
	ceu_mat.sky_top_color = Color(0.30, 0.37, 0.46)
	ceu_mat.sky_horizon_color = Color(0.34, 0.39, 0.44)
	ceu_mat.ground_bottom_color = Color(0.15, 0.17, 0.19)
	ceu_mat.ground_horizon_color = Color(0.30, 0.34, 0.38)
	ceu_mat.sun_angle_max = 0.0
	ceu_mat.sun_curve = 0.01
	var ceu := Sky.new()
	ceu.sky_material = ceu_mat
	ceu.radiance_size = Sky.RADIANCE_SIZE_32
	ceu.process_mode = Sky.PROCESS_MODE_QUALITY
	e.sky = ceu
	e.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	we.environment = e
	add_child(we)

	# luz "do planeta": o oceano iluminando a estação por baixo
	var dl := DirectionalLight3D.new()
	dl.rotation_degrees = Vector3(-64.0, 32.0, 0.0)
	dl.light_color = Color(0.42, 0.60, 0.78)
	dl.light_energy = 0.85
	dl.shadow_enabled = true
	dl.directional_shadow_max_distance = 120.0
	add_child(dl)

	# céu: esfera de estrelas (segue o jogador) + planeta gigante ao fundo
	sky_sphere = MeshInstance3D.new()
	sky_sphere.name = "Ceus"
	var sm := SphereMesh.new()
	sm.radius = 1800.0
	sm.height = 3600.0
	sm.radial_segments = 32
	sm.rings = 16
	sky_sphere.mesh = sm
	var sky_mat := ShaderMaterial.new()
	sky_mat.shader = STARS
	sky_sphere.material_override = sky_mat
	sky_sphere.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	sky_sphere.extra_cull_margin = 4000.0
	add_child(sky_sphere)

	var planet := MeshInstance3D.new()
	planet.name = "Irio"
	var pm := SphereMesh.new()
	pm.radius = 1400.0
	pm.height = 2800.0
	pm.radial_segments = 48
	pm.rings = 24
	planet.mesh = pm
	var planet_mat := ShaderMaterial.new()
	planet_mat.shader = PLANET
	planet.material_override = planet_mat
	planet.position = Vector3(5200.0, 1500.0, -6400.0)
	planet.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(planet)


func _build_sea() -> void:
	# o oceano de ÍRIO, 40 m abaixo da estação
	sea = Ocean.make_sea(2600.0, 0.0, 240)
	sea.name = "Mar"
	add_child(sea)
	sea_far = Ocean.make_sea(9000.0, -1.5, 40)
	sea_far.name = "MarDistante"
	add_child(sea_far)
	# estruturas de água que imitam construção humana (aparecem com a ressonância)
	var spots := [
		Vector3(-620.0, 0.0, -340.0), Vector3(880.0, 0.0, -520.0),
		Vector3(-400.0, 0.0, 900.0), Vector3(1200.0, 0.0, 700.0),
	]
	for i in spots.size():
		var im := Ocean.make_imitation(spots[i], Vector3(320.0 + float(i) * 60.0, 90.0, 260.0 + float(i) * 40.0))
		im.visible = false
		add_child(im)
		imitations.append(im)
		_sea_energies.append(0.0)


func _on_resonance(v: int) -> void:
	# quanto maior a ressonância, mais o mar se atreve a construir
	var band := int(floor(float(v) / 2.0))
	for i in imitations.size():
		imitations[i].visible = band >= i + 1
		if imitations[i].visible:
			var tw := imitations[i].create_tween()
			tw.tween_property(imitations[i], "scale", Vector3.ONE, 4.0).from(Vector3(1.0, 0.1, 1.0))
	AudioMan.theme_ocean(float(v) / 10.0)
	UI.play_stress(0.1 * float(v) / 10.0, 4.0)
	AudioMan.set_ocean_energy(float(v) / 10.0)


# ================================================================ JOGADOR
func _spawn_player() -> void:
	player = Player.new()
	player.name = "K9"
	player.position = Vector3(0, 40.6, -24.0)
	player.rotation.y = PI
	world_root.add_child(player)
	player.camera.make_current()
	player.controllado = false
	player.stepped.connect(func(pos: Vector3, sprinting: bool) -> void: Director.on_step(pos, sprinting))
	player.sector_changed.connect(func(s: String) -> void:
		if s == "eclusa":
			player.in_vacuum = true
		else:
			player.in_vacuum = false)
	# o céu acompanha o jogador
	if sky_sphere != null:
		sky_sphere.reparent(player.camera, false)
		sky_sphere.position = Vector3.ZERO
		sky_sphere.scale = Vector3.ONE


func _build_menu_camera() -> void:
	menu_cam = Camera3D.new()
	menu_cam.name = "CameraMenu"
	menu_cam.fov = 62.0
	menu_cam.far = 8000.0
	add_child(menu_cam)
	menu_cam.make_current()


func _process(delta: float) -> void:
	if _selftest:
		return
	if _shot:
		_shot_tick()
		return
	if not started:
		_menu_t += delta
		var r := 78.0
		var a := _menu_t * 0.045
		var cam_pos := Vector3(cos(a) * r, 66.0 + sin(_menu_t * 0.14) * 4.0, sin(a) * r)
		menu_cam.global_position = cam_pos
		menu_cam.look_at(Vector3(0.0, 58.0, 0.0), Vector3.UP)
	# o mar respira conforme a ressonância
	if sea != null:
		Ocean.set_resonance(GameState.resonance)


## Exercita todos os sistemas em sequência para caçar erros de execução.
## Modo de conferência das texturas: grava albedo, normal e ORM de cada
## material como PNG, para olhar o trabalho de material sem depender da cena.
func _dump_mats() -> void:
	var dir := "/home/user/tex_sheet"
	DirAccess.make_dir_recursive_absolute(dir)
	var chaves := ["wall", "wall_dark", "floor", "floor_grating", "ceiling", "metal",
			"metal_rust", "pipe", "rubber", "fabric", "hazard", "shelf_wood", "paper"]
	print("[MATS] gravando folha de materiais em ", dir)
	for k: String in chaves:
		var m: StandardMaterial3D = Mats.get_mat(k)
		var alb := m.albedo_texture as Texture2D
		var nrm := m.normal_texture as Texture2D
		var orm := m.orm_texture as Texture2D
		if alb != null:
			alb.get_image().save_png(dir + "/" + k + "_albedo.png")
		if nrm != null:
			nrm.get_image().save_png(dir + "/" + k + "_normal.png")
		if orm != null:
			orm.get_image().save_png(dir + "/" + k + "_orm.png")
		print("[MATS] ", k, " ok")
	print("[MATS] fim")


## Diagnóstico: lista corpos com colisão perto de um ponto (usado para achar
## bloqueadores invisíveis nos corredores).
func _probe(p: Vector3, raio := 3.0) -> void:
	print("[PROBE] procurando colisores a %.1f m de %s" % [raio, p])
	var achados := 0
	var pilha: Array[Node] = [world_root]
	while not pilha.is_empty():
		var n: Node = pilha.pop_back()
		for c in n.get_children():
			pilha.append(c)
		if n is CollisionObject3D:
			var co := n as CollisionObject3D
			var d := co.global_position.distance_to(p)
			if d < raio:
				achados += 1
				print("[PROBE] %-42s %s classe=%s d=%.2f" % [co.get_path(), co.global_position, co.get_class(), d])
	print("[PROBE] total: %d" % achados)
	get_tree().quit()


func _selftest_run() -> void:
	var t := 0.4
	var step := func(sec: float, cb: Callable) -> void:
		Director.after(sec, cb)
	print("[SELFTEST] iniciando")
	step.call(t, func() -> void: UI.open_docs(["bl_000", "log_argos_01", "photo_01", "fita_1"], "TESTE"))
	t += 1.2; step.call(t, func() -> void: UI.close_panel())
	t += 0.4; step.call(t, func() -> void: UI.open_cctv())
	t += 1.2; step.call(t, func() -> void: UI.close_panel())
	t += 0.4; step.call(t, func() -> void: UI.open_radio(["terra_1", "voz_extra", "sal_1"]))
	t += 1.4; step.call(t, func() -> void: UI.close_panel())
	t += 0.4; step.call(t, func() -> void: UI.open_keypad("TESTE", "1234", Callable(), Callable()))
	t += 1.0; step.call(t, func() -> void: UI.close_panel())
	t += 0.4; step.call(t, func() -> void: UI.ask_decision("orgao"))
	t += 1.6; step.call(t, func() -> void: UI.close_panel())
	t += 0.4; step.call(t, func() -> void: UI.open_journal())
	t += 1.0; step.call(t, func() -> void: UI.close_panel())
	t += 0.4; step.call(t, func() -> void: UI.open_pause())
	t += 1.0; step.call(t, func() -> void: UI.close_panel())
	# energia + mundo
	t += 0.4; step.call(t, func() -> void:
		GameState.set_flag("tem_fusivel")
		Director.power_action(world_root, {}))
	t += 2.0; step.call(t, func() -> void:
		Director.valve_action(world_root, {})
		Director.sample_action(world_root, {})
		Director.after(1.0, func() -> void: Director.lift_action(Director._find_lift(), {})))
	# anomalias
	var ids := ["porta_aberta", "objeto_movido", "corredor_estendido", "cam_fantasma", "foto_extra",
			"radio_voz", "eco_passos", "espelho_agua", "sino", "manifesto_iris", "manifesto_andrei",
			"coro", "terra_falsa", "mao_no_vidro", "trilha_molhada", "sala_reconstruida", "orgao"]
	for id: String in ids:
		t += 1.4
		var aid := id
		step.call(t, func() -> void:
			print("[SELFTEST] anomalia: ", aid)
			Anomalies.run(aid))
	# teleporte por setores
	for sector_poi: String in ["hangar", "refeitorio", "lab", "engenharia", "comando", "camara_sino", "eclusa", "corredor_obs", "observatorio"]:
		t += 0.8
		var poi_name := sector_poi
		step.call(t, func() -> void:
			var p := Director.poi_of(poi_name, Vector3(0, 40, 0))
			player.global_position = p + Vector3(0, 0.1, 0)
			print("[SELFTEST] teleporte: ", poi_name, " -> ", p))
	# decisões e finais
	t += 1.5; step.call(t, func() -> void: GameState.decide("espelho", "reativar"))
	t += 1.5; step.call(t, func() -> void:
		GameState.save_game()
		GameState.load_game()
		Director.resync()
		print("[SELFTEST] save/load ok"))
	# monta-carga: o jogador PRECISA ser carregado pela plataforma
	t += 1.0; step.call(t, func() -> void:
		var plat := Director._find_lift()
		player.global_position = plat.global_position + Vector3(0, 1.0, 0)
		print("[SELFTEST] carry: jogador %s | plataforma y=%.2f" % [player.global_position, plat.global_position.y if plat != null else -99.0]))
	t += 0.8; step.call(t, func() -> void:
		var plat := Director._find_lift()
		# exatamente como o jogador: pelo interativo do painel da plataforma
		for c in plat.get_children():
			var it := c as Interactable
			if it != null and it.prompt().to_lower().contains("operar"):
				it.on_use.call(player, it)
				print("[SELFTEST] carry: painel \"operar\" acionado (y=%.2f)" % plat.global_position.y)
				return
		print("[SELFTEST] carry: ERRO — painel da plataforma não encontrado"))
	t += 9.0; step.call(t, func() -> void:
		var plat := Director._find_lift()
		print("[SELFTEST] carry: FIM jogador y=%.2f | plataforma y=%.2f (esperado jogador ~52)" % [
			player.global_position.y, plat.global_position.y if plat != null else -99.0]))
	t += 1.5; step.call(t, func() -> void: Director._end_from_choice("chamado"))
	t += 8.0; step.call(t, func() -> void:
		print("[SELFTEST] FIM — encerrando")
		get_tree().quit())


func _shot_tick() -> void:
	# modo captura: luz de trabalho para conferir materiais e geometria
	if _shot_i < 0:
		if not _shot_real or _shot_real_forca:
			LampGrid.power_on()
		for c in UI.get_children():
			if c is IntroSequence:
				c.queue_free()
		UI.blocked = false
	if _shot_i >= SHOTS.size():
		get_tree().quit()
		return
	_shot_frames += 1
	if _shot_i < 0 or _shot_frames > SHOT_SETTLE:
		_shot_i += 1
		if _shot_i <= 0 and (not _shot_real or _shot_real_forca):
			LampGrid.power_on()
		_shot_frames = 0
		if _shot_i >= SHOTS.size():
			get_tree().quit()
			return
		var s: Dictionary = SHOTS[_shot_i]
		if _shot_only != "" and String(s["nome"]) != _shot_only:
			_shot_frames = SHOT_SETTLE + 1
			return
		if _shot_real and not SHOTS_REAIS.has(String(s["nome"])):
			_shot_frames = SHOT_SETTLE + 1
			return
		if s.has("res") and not _shot_real:
			GameState.add_resonance(int(s["res"]))
		if s.has("fig"):
			var m := Manifestation.new()
			m.kind = Manifestation.Kind.SOMBRA
			m.position = s["fig"]
			m.rotation.y = 0.35
			world_root.add_child(m)
			m.setup("", Manifestation.Kind.SOMBRA, [], "", "")
		if s.has("light"):
			LampGrid.power_on()
		menu_cam.global_position = s["pos"]
		menu_cam.look_at(s["look"], Vector3.UP)
		menu_cam.make_current()
		print("[SHOT %d] %s  frame=%d" % [_shot_i, String(s["nome"]), Engine.get_process_frames()])
	if not _shot_real:
		_luz_de_inspecao()


## Iluminação de inspeção — só nas capturas (--shot). O jogo é escuro de
## propósito; para fotografar e conferir geometria, material e sujeira é
## preciso levantar o ambiente. Não afeta a partida do jogador.
func _luz_de_inspecao() -> void:
	if _inspecao_feita:
		return
	_inspecao_feita = true
	LampGrid.power_on()
	# o ambiente do jogo mora num nó WorldEnvironment (world_3d.environment é
	# outro campo e fica vazio: por isso a luz de inspeção antiga não pegava)
	var e: Environment = null
	for n in get_tree().root.find_children("*", "WorldEnvironment", true, false):
		e = (n as WorldEnvironment).environment
	if e == null:
		e = get_viewport().world_3d.environment
	if e != null:
		e.ambient_light_energy = 1.5
		e.ambient_light_color = Color(0.42, 0.50, 0.66)
		e.volumetric_fog_enabled = false
	# farol preso à câmera, como o refletor de um fotógrafo. É direcional de
	# propósito: no renderizador de compatibilidade cada malha aceita poucas
	# luzes pontuais, e as paredes grandes descartavam o refletor antigo.
	var refletor := DirectionalLight3D.new()
	refletor.name = "LuzInspecao"
	refletor.light_color = Color(0.90, 0.93, 1.0)
	refletor.light_energy = 0.85
	refletor.shadow_enabled = false
	menu_cam.add_child(refletor)
	refletor.rotation = Vector3(-0.12, 0.25, 0)
	var conta := 0
	for n in get_tree().root.find_children("*", "Light3D", true, false):
		var lz := n as Light3D
		if lz is OmniLight3D:
			var ol := lz as OmniLight3D
			if ol.name != "LuzInspecao":
				ol.light_energy = maxf(ol.light_energy, 0.95)
				conta += 1
		elif lz is SpotLight3D:
			lz.light_energy = maxf(lz.light_energy, 1.25)
			conta += 1
	print("[SHOT] luz de inspecao: %d luzes reforcadas" % conta)


func _on_menu_start() -> void:
	if started:
		Director.resync()
		return
	started = true
	player.controllado = true
	player.camera.make_current()
	UI.play_intro()


# ================================================================ EVENTOS GLOBAIS
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and not started:
		return


## Mede o custo do cenário vestido (nós, malhas, luzes, draw calls, FPS).
## Existe para comparar versões depois de mudanças grandes de arte.
func _medir_peso() -> void:
	var contagem := {"nos": 0, "malhas": 0, "luzes": 0, "colisores": 0}
	var pilha: Array[Node] = [get_tree().root]
	while not pilha.is_empty():
		var n: Node = pilha.pop_back()
		contagem["nos"] += 1
		if n is MeshInstance3D:
			contagem["malhas"] += 1
		elif n is Light3D:
			contagem["luzes"] += 1
		elif n is CollisionShape3D:
			contagem["colisores"] += 1
		for c in n.get_children():
			pilha.append(c)
	await get_tree().create_timer(6.0).timeout
	var fps := Performance.get_monitor(Performance.TIME_FPS)
	var draws := Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
	var prim := Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)
	var mem := Performance.get_monitor(Performance.MEMORY_STATIC)
	print("=== PESO DO CENARIO ===")
	var por_dono := {}
	for n2 in get_tree().root.find_children("*", "MeshInstance3D", true, false):
		var raiz := n2
		for _i in 4:
			if raiz.get_parent() == null or raiz.get_parent() == world_root:
				break
			raiz = raiz.get_parent()
		var k := raiz.name
		por_dono[k] = int(por_dono.get(k, 0)) + 1
	var lista := por_dono.keys()
	lista.sort_custom(func(a, b): return int(por_dono[a]) > int(por_dono[b]))
	var txt := ""
	for k in lista.slice(0, 14):
		txt += "%s=%d  " % [k, por_dono[k]]
	print("malhas por grupo: " + txt)
	print("nos=%d malhas=%d luzes=%d colisores=%d" % [contagem["nos"], contagem["malhas"],
			contagem["luzes"], contagem["colisores"]])
	print("fps=%.1f draw_calls=%.0f primitivas=%.0f memoria=%.1f MB" % [fps, draws, prim,
			mem / 1048576.0])
	get_tree().quit()
