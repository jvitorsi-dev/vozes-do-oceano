extends Node
## Director — o "narrador" do jogo.
##
## Guarda o mapa do que existe na estação, decide quando cada anomalia
## aparece, controla os capítulos e a relação entre o jogador e o oceano.
## Nada aqui é aleatório de verdade: tudo depende do que o jogador já viu.

var world: Node3D

# ---- registro do mundo
var poi: Dictionary = {}              # nome → Vector3
var doors: Dictionary = {}            # id → Door
var props: Array[Node3D] = []         # objetos que podem mudar de lugar
var extendables: Array[Dictionary] = []
var lights: Array[Light3D] = []
var figures: Array = []               # manifestações vivas
var puddles: Array[Node] = []

# ---- estado
var chapter := -1
var powered := false
var docs_seen := 0
var echo_steps := 0
var ambient := true
var ended := false
var safe_spawn_pos := Vector3(0.0, 40.5, -18.0)
var bell_pos := Vector3(0.0, 64.5, 12.0)

var _timers: Array = []
var _rng := RandomNumberGenerator.new()
var _ambient_t := 55.0
var _looked: Dictionary = {}
var _manifest_seen := 0
var _sealevel_target := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rng.seed = 20260920
	GameState.doc_read.connect(_on_doc_read)
	GameState.decision_made.connect(_on_decision)


func attach_world(w: Node3D) -> void:
	world = w


# ================================================================ REGISTRO
func register_poi(name: String, pos: Vector3) -> void:
	poi[name] = pos


func register_door(id: String, door: Door) -> void:
	doors[id] = door


func register_prop(n: Node3D) -> void:
	props.append(n)


func register_extendable(d: Dictionary) -> void:
	extendables.append(d)


func register_light(l: Light3D) -> void:
	lights.append(l)


func register_figure(f: Node) -> void:
	figures.append(f)


func poi_of(name: String, fallback := Vector3.ZERO) -> Vector3:
	return poi.get(name, fallback)


# ================================================================ TEMPORIZADORES
func after(seconds: float, cb: Callable, tag := "") -> void:
	_timers.append({"t": seconds, "cb": cb, "tag": tag, "repeat": 0.0})


func every(seconds: float, cb: Callable, tag := "") -> void:
	_timers.append({"t": seconds, "cb": cb, "tag": tag, "repeat": seconds})


func cancel_tag(tag: String) -> void:
	_timers = _timers.filter(func(d: Dictionary) -> bool: return String(d["tag"]) != tag)


func _process(delta: float) -> void:
	var i := 0
	while i < _timers.size():
		var t: Dictionary = _timers[i]
		t["t"] = float(t["t"]) - delta
		if float(t["t"]) <= 0.0:
			var cb: Callable = t["cb"]
			if float(t["repeat"]) > 0.0:
				t["t"] = float(t["repeat"])
			else:
				_timers.remove_at(i)
				if cb.is_valid():
					cb.call()
				continue
			if cb.is_valid():
				cb.call()
		i += 1
	if ambient and not ended and chapter >= 1:
		_ambient_t -= delta
		if _ambient_t <= 0.0:
			_ambient_t = _rng.randf_range(38.0, 85.0)
			_ambient_event()
	# figuras observam o jogador
	for f in figures.duplicate():
		if not is_instance_valid(f):
			figures.erase(f)


# ================================================================ CAPÍTULOS
func begin() -> void:
	if chapter >= 0:
		return
	set_chapter(0)
	# SAL-5 dá boas-vindas depois de um tempo
	after(28.0, func() -> void:
		UI.say([
			{"who": "SAL-5", "text": "Protocolo de continuidade ativo.", "dur": 2.6},
			{"who": "SAL-5", "text": "K-9, bem-vindo à Argos-4. Cinco tripulantes registrados, cinco ausentes.", "dur": 4.4},
			{"who": "SAL-5", "text": "Não sei se isso é lealdade ou hábito.", "dur": 3.2},
		], "sal_01")
		UI.show_note("SAL-5", "A inteligência de bordo falou com você pelo canal interno. Ela estava esperando.")
		GameState.set_flag("conheceu_sal5"))
	after(95.0, func() -> void:
		if chapter == 0:
			UI.subtitle("SAL-5", "Aviso: o setor de habitação está no escuro. A energia principal caiu há 47 dias.", 4.5))


func set_chapter(n: int) -> void:
	if n == chapter:
		return
	chapter = n
	match n:
		0:
			GameState.set_objective("Restaurar energia da estação")
			AudioMan.music_intensity(0.18)
			GameState.add_resonance(0)
		1:
			GameState.set_objective("Recuperar os registros científicos")
			AudioMan.music_intensity(0.30)
			ambient = true
			Ocean.pulse(Vector3.ZERO, 0.9)
			UI.show_note("ENERGIA RESTAURADA", "Os corredores acenderam. A estação voltou a respirar — e algo lá fora percebeu.")
			after(50.0, func() -> void: Anomalies.run("eco_passos"))
			after(140.0, func() -> void: Anomalies.run("porta_aberta"))
		2:
			GameState.set_objective("Encontrar o módulo de observação")
			AudioMan.music_intensity(0.42)
			GameState.add_resonance(1)
			after(20.0, func() -> void:
				if doors.has("selada"):
					var d: Door = doors["selada"]
					d.force_open()
					UI.play_stress(0.5, 5.0)
					UI.subtitle("", "A porta do módulo de observação — a que estava soldada por dentro — se abre sozinha, devagar, como se alguém tivesse esperado você chegar até ali. Atrás dela: chapa soldada. Só isso.", 8.0)
					GameState.seen_anomaly("porta_aberta"))
		3:
			GameState.set_objective("Descobrir o que o oceano está tentando fazer")
			AudioMan.music_intensity(0.55)
			GameState.add_resonance(2)
			after(12.0, func() -> void: _call_iris())
		4:
			GameState.set_objective("Decidir a resposta ao oceano")
			AudioMan.music_intensity(0.7)
			GameState.add_resonance(2)
			after(6.0, func() -> void: Anomalies.run("coro"))


func _on_doc_read(id: String) -> void:
	docs_seen += 1
	# marcos narrativos por documento
	match id:
		"mirror_proto":
			set_chapter(maxi(chapter, 2))
			UI.subtitle("", "Protocolo Espelho. Eles não estavam estudando o oceano: estavam oferecendo pensamentos a ele.", 5.5)
			after(3.0, func() -> void: Anomalies.run("sino"))
		"log_final_iris":
			set_chapter(4)
		"cam_log_11":
			after(2.0, func() -> void: Anomalies.run("cam_fantasma", {"linked": true}))
		"photo_01":
			after(45.0, func() -> void: Anomalies.run("foto_extra"))
		"xeno_proto_7":
			after(70.0, func() -> void: Anomalies.run("sala_reconstruida"))
	if docs_seen >= 6 and chapter == 2:
		after(30.0, func() -> void: Anomalies.run("manifesto_andrei"))
	if docs_seen >= 10 and chapter <= 3:
		set_chapter(3)


func _on_decision(id: String, choice: String) -> void:
	match id:
		"orgao":
			if choice == "deixar":
				after(18.0, func() -> void: Anomalies.run("manifesto_iris"))
			elif choice == "interromper":
				after(60.0, func() -> void: Anomalies.run("coro"))
		"gravacao":
			if choice == "reenviar":
				after(30.0, func() -> void: Anomalies.run("radio_voz"))
		"chamado":
			if choice == "responder":
				after(25.0, func() -> void: Anomalies.run("radio_voz"))
		"espelho":
			if choice == "reativar":
				set_chapter(4)
			else:
				GameState.add_resonance(-2)
		"final":
			_end_from_choice(choice)


# ================================================================ AÇÕES DO MUNDO
func power_action(g: Node3D, payload: Dictionary) -> void:
	if powered:
		UI.show_note("REATOR ONLINE", "A energia principal já está restaurada.")
		return
	if not GameState.has("tem_fusivel"):
		UI.show_note("FUSÍVEL AUSENTE", "O painel abre uma cavidade vazia. Falta um fusível de 400 A — deve haver um no hangar.")
		AudioMan.play_3d("deny", g.global_position)
		return
	UI.open_keypad("SEQUÊNCIA DE DISJUNTORES A2 B1 C3 D4", "2134",
		func() -> void: _power_on(), func() -> void:
			AudioMan.play_3d("deny", g.global_position))


func _power_on() -> void:
	powered = true
	GameState.set_flag("energia_ok")
	GameState.set_power(12.0)
	AudioMan.play_2d("power", -4.0)
	for id: String in doors.keys():
		(doors[id] as Door).set_powered(true)
	for l in lights:
		if is_instance_valid(l):
			l.light_energy = maxf(l.light_energy, 0.55)
	Ocean.pulse(Vector3.ZERO, 0.6)
	LampGrid.power_on()
	UI.flash(Color(0.6, 0.85, 1.0, 0.5), 1.2)
	set_chapter(1)


func valve_action(g: Node3D, payload: Dictionary) -> void:
	AudioMan.play_3d("clank", g.global_position)
	AudioMan.play_3d("creak", g.global_position, -6.0)
	UI.show_note("VÁLVULA", "O registro cede e o ar volta a circular. Em algum lugar do casco, algo responde ao barulho com o mesmo barulho.")
	GameState.seen_anomaly("eco_passos")
	after(6.0, func() -> void: AudioMan.play_3d("clank", g.global_position + Vector3(6, 0, 0), -6.0))


func sample_action(g: Node3D, payload: Dictionary) -> void:
	if GameState.has("tem_amostra"):
		UI.open_docs(["xeno_proto_7"], "ANÁLISE DE AMOSTRA")
		return
	UI.show_note("COLETA", "Não há amostra do oceano no frasco. A amostra foi coletada... e depois desapareceu do recipiente lacrado.")
	GameState.seen_anomaly("objeto_movido")


func lift_action(node: Node, payload: Dictionary) -> void:
	var platform: AnimatableBody3D = null
	if node is AnimatableBody3D:
		platform = node
	else:
		# procura o monta-carga a partir do ponto de interação
		var it := node as Node3D
		platform = Director._find_lift()
	if platform == null:
		return
	var bottom: Vector3 = payload.get("bottom", platform.position)
	var top: Vector3 = payload.get("top", platform.position)
	var target: Vector3
	if payload.has("call_to"):
		# painel de chamada: traz a plataforma para o nível de quem apertou
		target = bottom if String(payload["call_to"]) == "bottom" else top
		if platform.position.distance_to(target) < 0.6:
			UI.show_note("MONTACARGA", "A plataforma já está neste nível. Use o painel da plataforma para subir.")
			AudioMan.play_3d("blip", platform.global_position, -12.0)
			return
	else:
		# painel da plataforma: leva o jogador para o outro nível
		target = top if platform.position.y < (bottom.y + top.y) * 0.5 else bottom
	AudioMan.play_3d("power", platform.global_position, -12.0)
	if not payload.has("call_to"):
		# o painel fica na plataforma: se o jogador apertou de fora, ela não parte
		var jog := get_tree().get_first_node_in_group("player") as Node3D
		if jog != null:
			var plano := Vector2(jog.global_position.x - platform.global_position.x,
					jog.global_position.z - platform.global_position.z).length()
			if plano > 1.6 or absf(jog.global_position.y - platform.global_position.y) > 1.4:
				UI.show_note("MONTACARGA", "Suba na plataforma do monta-carga para operá-la. Do corredor, use o painel de chamada.")
				AudioMan.play_3d("blip", platform.global_position, -12.0)
				return
	var tw := platform.create_tween()
	tw.tween_property(platform, "position", target, 6.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	# quem viaja em cima não cai pela borda: a plataforma "segura" o passageiro
	tw.parallel().tween_method(func(_v: float) -> void: _keep_rider(platform), 0.0, 1.0, 6.0)
	# o elevador às vezes hesita no meio do caminho
	if not GameState.has("lift_hesitou") and chapter >= 1:
		GameState.set_flag("lift_hesitou")
		after(3.2, func() -> void:
			tw.pause()
			AudioMan.play_2d("glitch", -10.0)
			UI.play_stress(0.6, 6.0)
			UI.subtitle("", "O monta-carga para no meio do poço. Por três segundos, você ouve água correndo do outro lado do casco.", 5.5)
			after(3.5, func() -> void: tw.play()))


## Mantém o passageiro dentro do piso da plataforma durante a viagem.
func _keep_rider(platform: AnimatableBody3D) -> void:
	var jog := get_tree().get_first_node_in_group("player") as Node3D
	if jog == null or not is_instance_valid(platform):
		return
	var topo := platform.global_position.y + 0.17
	if absf(jog.global_position.y - topo) > 0.8:
		return
	var ax := platform.global_position.x
	var az := platform.global_position.z
	var cx := clampf(jog.global_position.x - ax, -0.85, 0.85)
	var cz := clampf(jog.global_position.z - az, -0.85, 0.85)
	# só reposiciona se estiver saindo do piso da plataforma (evita queda na viagem)
	if absf(cx - (jog.global_position.x - ax)) > 0.02 or absf(cz - (jog.global_position.z - az)) > 0.02:
		jog.global_position.x = ax + cx
		jog.global_position.z = az + cz


## Plataforma do monta-carga mais próxima do jogador (usada por testes e
## por chamadas sem referência explícita de plataforma).
func _find_lift() -> AnimatableBody3D:
	var candidatos: Array[AnimatableBody3D] = []
	for n in props:
		if is_instance_valid(n) and n is AnimatableBody3D:
			candidatos.append(n)
	if candidatos.is_empty() and world != null:
		for c in world.find_children("*", "AnimatableBody3D", true, false):
			candidatos.append(c as AnimatableBody3D)
	if candidatos.is_empty():
		return null
	var jog := get_tree().get_first_node_in_group("player") as Node3D
	var melhor := candidatos[0]
	if jog != null:
		var d := melhor.global_position.distance_to(jog.global_position)
		for c in candidatos:
			var dd := c.global_position.distance_to(jog.global_position)
			if dd < d:
				d = dd
				melhor = c
	return melhor


func on_flashlight(on: bool, pos: Vector3) -> void:
	if not on:
		return
	# a luz forte dissolve manifestações próximas
	for f in figures.duplicate():
		if not is_instance_valid(f):
			figures.erase(f)
			continue
		if f is Node3D and (f as Node3D).global_position.distance_to(pos) < 14.0:
			if f.has_method("dissolve"):
				f.dissolve()
			figures.erase(f)
			GameState.seen_anomaly("manifesto_interrompido")
			UI.subtitle("", "A figura se desfaz na luz como água derramada. Não houve som nenhum.", 4.5)


func on_look(target: Interactable, _dir: Vector3) -> void:
	if target == null:
		return
	var key := target.get_path()
	if _looked.has(key):
		return
	_looked[key] = true
	var d: Dictionary = target.data
	if d.has("on_look_flag"):
		GameState.set_flag(String(d["on_look_flag"]))


func on_step(pos: Vector3, sprinting: bool) -> void:
	if echo_steps > 0:
		echo_steps -= 1
		var off := Vector3(_rng.randf_range(-1.6, 1.6), 0, _rng.randf_range(-1.6, 1.6))
		after(_rng.randf_range(0.28, 0.55), func() -> void:
			AudioMan.play_3d("step", pos + off, -20.0, 0.88))
		if echo_steps == 0:
			GameState.seen_anomaly("eco_passos")


func on_sector(name: String, _display: String) -> void:
	match name:
		"observacao":
			if chapter < 3:
				set_chapter(3)
		"comando":
			if chapter == 1:
				after(4.0, func() -> void: Anomalies.run("cam_fantasma"))
		"refeitorio":
			if not GameState.has("viu_regras"):
				GameState.set_flag("viu_regras")
				after(2.0, func() -> void:
					UI.subtitle("", "Há um aviso fixado na parede, escrito à mão pela piloto. Regra 3: não olhar pela janela sul depois do terceiro sino.", 6.0))
		"sino":
			if not GameState.has("ouviu_sino"):
				after(3.0, func() -> void: Anomalies.run("sino"))


func on_signal_heard(id: String) -> void:
	if id == "voz_extra":
		GameState.seen_anomaly("radio_voz")
		set_chapter(maxi(chapter, 2))
		if GameState.decision("chamado") == "":
			after(6.0, func() -> void: UI.ask_decision("chamado"))
	elif id == "sal_1":
		GameState.set_flag("ouviu_sal5")
	elif id == "nadia_1":
		GameState.seen_anomaly("radio_voz")
		after(5.0, func() -> void: GameState.add_note("VOZ NO CANAL 4", "Nadia gravou um relato que ela nunca quis registrar. A voz dela falha exatamente na palavra irmão."))
	elif id == "tomas_1":
		GameState.seen_anomaly("terra_falsa")
		after(8.0, func() -> void: Anomalies.run("terra_falsa"))


func on_decision_open(id: String) -> void:
	AudioMan.theme_ocean(0.4)
	GameState.set_flag("decisao_vista_" + id)


func _call_iris() -> void:
	if _manifest_seen > 0:
		return
	Anomalies.run("manifesto_iris")


# ================================================================ AMBIENTE
func _ambient_event() -> void:
	var options: Array = ["objeto_movido", "eco_passos", "trilha_molhada", "porta_aberta", "espelho_agua"]
	if chapter >= 2:
		options.append("cam_fantasma")
		options.append("mao_no_vidro")
	if chapter >= 3:
		options.append("terra_falsa")
		options.append("coro")
	# evita repetir a última
	var pick := String(options[_rng.randi_range(0, options.size() - 1)])
	Anomalies.run(pick)


func flicker_lights(duration := 4.0, intensity := 0.25) -> void:
	var state := {"t": duration}
	var cb := func() -> void:
		state["t"] = float(state["t"]) - 0.08
		var on := _rng.randf() > 0.4
		for l in lights:
			if is_instance_valid(l):
				l.light_energy = (0.05 + _rng.randf() * 0.2) if not on else maxf(0.5, intensity)
		if float(state["t"]) <= 0.0:
			for l2 in lights:
				if is_instance_valid(l2):
					l2.light_energy = 0.7
			cancel_tag("flicker")
	every(0.08, cb, "flicker")


func blackout(duration := 6.0) -> void:
	for l in lights:
		if is_instance_valid(l):
			l.light_energy = 0.02
	UI.play_stress(0.8, duration)
	after(duration, func() -> void:
		for l2 in lights:
			if is_instance_valid(l2):
				l2.light_energy = 0.7)


func set_sea_rise(target: float, seconds := 20.0) -> void:
	var sea := world.get_node_or_null("Mar") if world != null else null
	if sea == null:
		return
	var tw := (sea as Node3D).create_tween()
	tw.tween_property(sea, "position:y", target, seconds).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


# ================================================================ FIM
func _end_from_choice(choice: String) -> void:
	if ended:
		return
	ended = true
	ambient = false
	var ending := "b"
	match choice:
		"chamado": ending = "a"
		"partida": ending = "c"
		"repeticao": ending = "d"
		_: ending = "b"
	GameState.set_flag("final_" + ending)
	UI.fade_out(3.0)
	after(3.2, func() -> void: UI.show_ending(ending))
	AudioMan.theme_ocean(1.0)
	Ocean.set_resonance_float(1.0)


func safe_spawn() -> Vector3:
	return safe_spawn_pos


func resync() -> void:
	# depois de carregar um save, o mundo volta ao estado registrado
	powered = GameState.has("energia_ok")
	for id: String in doors.keys():
		var d: Door = doors[id]
		d.set_powered(powered or GameState.has("energia_ok"))
		if id == "selada" and GameState.chapter >= 2:
			d.force_open()
	Ocean.set_resonance(GameState.resonance)
	set_chapter(GameState.chapter)


func return_to_menu() -> void:
	ending_cleanup()
	UI.fade_out(1.2)
	after(1.4, func() -> void:
		get_tree().reload_current_scene())


func ending_cleanup() -> void:
	ended = true
	ambient = false
	AudioMan.stop_all_music()
	Figures.clear_all()


# classe auxiliar para limpar figuras
class Figures:
	static func clear_all() -> void:
		for f in Director.figures.duplicate():
			if is_instance_valid(f):
				f.queue_free()
		Director.figures.clear()
