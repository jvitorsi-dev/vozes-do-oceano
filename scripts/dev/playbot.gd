class_name PlayBot
extends Node
## PlayBot — jogador-robô de QA.
##
## Joga a expedição inteira como um jogador iniciante: anda com as ações de
## movimento reais (testando colisão, portas, gravidade e monta-cargas), mira
## com a câmera e aperta [E] pelo raio de interação de verdade, digita os
## códigos nos teclados reais e vai até o final. Tudo o que dá errado vira
## linha de relatório.
##
## Uso:  godot --path . -- --play        (com --write-movie para vídeo)
##
## Screenshots de conferência são gravadas em /home/user/bot_shots/.

static func start(main: Node3D) -> void:
	var b := PlayBot.new()
	b.name = "PlayBot"
	b.main = main
	main.add_child(b)

var main: Node3D
var player: Player

var tasks := 0
var fails: Array[String] = []
var warns: Array[String] = []
var stucks := 0
var shots := 0
var shot_dir := "/home/user/bot_shots"
var _expected_voices := [
	"iris_01", "iris_02", "andrei_01", "andrei_02", "sal_01", "sal_02",
	"voz_extra", "nadia_01", "tomas_01",
]


func _ready() -> void:
	if not DirAccess.dir_exists_absolute(shot_dir):
		DirAccess.make_dir_recursive_absolute(shot_dir)
	_run()


# ================================================================ LOG
func _log(m: String) -> void:
	print("[BOT] ", m)


func _ok(m: String) -> void:
	tasks += 1
	print("[BOT] ✔ ", m)


func _warn(m: String) -> void:
	warns.append(m)
	print("[BOT] ! ", m)


func _fail(m: String) -> void:
	fails.append(m)
	print("[BOT] ✖ ", m)


func _check(cond: bool, ok_msg: String, fail_msg: String) -> bool:
	if cond:
		_ok(ok_msg)
	else:
		_fail(fail_msg)
	return cond


# ================================================================ FERRAMENTAS
func _wait(sec: float) -> void:
	await get_tree().create_timer(sec).timeout


func _frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


## Aperta de verdade: injeta um InputEventAction no pipeline (Input.action_press
## só muda o estado da ação e não gera evento — não serve para menus e leitores).
func _press(action: String, n := 2) -> void:
	var down := InputEventAction.new()
	down.action = action
	down.pressed = true
	Input.parse_input_event(down)
	await _frames(n)
	var up := InputEventAction.new()
	up.action = action
	up.pressed = false
	Input.parse_input_event(up)
	await _frames(2)


## Tecla crua, para telas que escutam keycode (menu, pausa, teclado do cofre).
func _press_key(code: Key, n := 2) -> void:
	var down := InputEventKey.new()
	down.keycode = code
	down.physical_keycode = code
	down.pressed = true
	Input.parse_input_event(down)
	await _frames(n)
	var up := InputEventKey.new()
	up.keycode = code
	up.physical_keycode = code
	up.pressed = false
	Input.parse_input_event(up)
	await _frames(2)


func _release_all() -> void:
	for a in ["move_forward", "move_back", "move_left", "move_right", "sprint", "crouch", "interact"]:
		Input.action_release(a)


func _shot(nome: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	var path := "%s/%02d-%s.png" % [shot_dir, shots, nome]
	img.save_png(path)
	shots += 1
	_log("screenshot: " + path)


func _floor_y() -> float:
	var y := player.global_position.y
	if y < 46.0:
		return 40.0
	if y < 58.0:
		return 52.0
	if y < 70.0:
		return 64.0
	return 76.0


func _look_at_point(p: Vector3) -> void:
	var eye := player.camera.global_position
	var to := p - eye
	player.rotation.y = atan2(-to.x, -to.z)
	player.camera.rotation.x = atan2(to.y, Vector2(to.x, to.z).length())


func walk_to(target: Vector3, tol := 1.2, timeout := 60.0) -> bool:
	# um jogador fecharia qualquer painel antes de sair andando
	if UI.blocked and UI._panel != null:
		await close_panel()
	# sanidade de rota: nunca caminhar para um alvo em outro convés
	# (um jogador de verdade também não tentaria atravessar o piso)
	if absf(target.y - player.global_position.y) > 2.0:
		_fail("rota inválida: alvo %s está em outro convés (jogador em %s)" % [_v(target), _v(player.global_position)])
		return false
	var t0 := Time.get_ticks_msec()
	var last_dist := 1.0e9
	var stuck_t := 0.0
	var dodge := 0.0
	var dodge_dir := 1.0
	var ciclos := 0
	while ciclos < 200000:
		ciclos += 1
		if UI.blocked:
			_release_all()
			await get_tree().physics_frame
			t0 = Time.get_ticks_msec()
			continue
		var pos := player.global_position
		var to := target - pos
		to.y = 0.0
		var dist := to.length()
		if dist <= tol:
			_release_all()
			return true
		var elapsed := float(Time.get_ticks_msec() - t0) / 1000.0
		if elapsed > timeout:
			_release_all()
			_fail("não cheguei em %s (parei em %s, a %.1f m)" % [_v(target), _v(pos), dist])
			player.global_position = target + Vector3(0.0, 0.45, 0.0)
			player.velocity = Vector3.ZERO
			return false
		var desired_yaw := atan2(-to.x, -to.z)
		player.rotation.y = lerp_angle(player.rotation.y, desired_yaw, 0.20)
		player.camera.rotation.x = lerpf(player.camera.rotation.x, 0.05, 0.12)
		if dist > last_dist - 0.02:
			stuck_t += 1.0 / 60.0
		else:
			stuck_t = 0.0
		last_dist = dist
		Input.action_press("move_forward")
		if dodge > 0.0:
			dodge -= 1.0 / 60.0
			Input.action_press("move_right" if dodge_dir > 0.0 else "move_left")
		else:
			Input.action_release("move_right")
			Input.action_release("move_left")
		if stuck_t > 1.2:
			stuck_t = 0.0
			dodge = randf_range(0.5, 1.1)
			dodge_dir = -dodge_dir
			stucks += 1
			_warn("preso perto de %s, tentando desviar (tentativa %d)" % [_v(pos), stucks])
			if stucks >= 6:
				_fail("travado em %s, alvo %s — possível bloqueador de geometria" % [_v(pos), _v(target)])
				var recuo := (pos - target).normalized() * 1.6
				player.global_position = pos + Vector3(recuo.x, 0.4, recuo.z)
				player.velocity = Vector3.ZERO
				stucks = 0
				_release_all()
				await _frames(8)
				t0 = Time.get_ticks_msec()
				last_dist = 1.0e9
		await get_tree().physics_frame
	_release_all()
	return false


func _v(p: Vector3) -> String:
	return "(%.1f, %.1f, %.1f)" % [p.x, p.y, p.z]


func _ray_target() -> Interactable:
	player.ray.force_raycast_update()
	if not player.ray.is_colliding():
		return null
	var c := player.ray.get_collider()
	if c is Interactable:
		return c
	if c is Node and c.get_parent() is Interactable:
		return c.get_parent()
	return null


## Interactable mais próximo de um ponto (opcionalmente com o prompt esperado).
func _nearest_interactable(pos: Vector3, raio := 6.0, expect := "") -> Interactable:
	var melhor: Interactable = null
	var melhor_d := 1.0e9
	var vistos: Array[String] = []
	for n in get_tree().get_nodes_in_group("interactables"):
		var it := n as Interactable
		if it == null or not it.enabled:
			continue
		var p := it.prompt()
		if p.is_empty():
			continue
		var d := it.global_position.distance_to(pos)
		if d > raio:
			continue
		vistos.append(p)
		if expect != "" and not p.to_lower().contains(expect.to_lower()):
			continue
		if d < melhor_d:
			melhor_d = d
			melhor = it
	if melhor == null and expect != "" and not vistos.is_empty():
		_warn("nenhum objeto com «%s» perto de %s; encontrei: %s" % [expect, _v(pos), str(vistos)])
	return melhor


## Centro da caixa de colisão do Interactable (é isso que o raio precisa acertar).
func _aim_point_for(it: Interactable) -> Vector3:
	for c in it.get_children():
		if c is CollisionShape3D:
			return (it as Node3D).global_transform * (c as CollisionShape3D).position
	return it.global_position


## Caminha até ficar dentro do alcance do raio, mira e aperta [E].
func use(target: Vector3, opts: Dictionary = {}) -> bool:
	var label := String(opts.get("label", _v(target)))
	var aim_y: float = float(opts.get("aim_y", 1.0))
	var stand: float = float(opts.get("stand", 1.55))
	var expect: String = String(opts.get("expect", ""))
	var floor_y := float(opts.get("floor_y", _floor_y()))
	var alvo := _nearest_interactable(target, 6.5, expect)
	var aim: Vector3 = target + Vector3(0, aim_y, 0)
	if alvo != null:
		aim = _aim_point_for(alvo)
	var away := player.global_position - (alvo.global_position if alvo != null else target)
	away.y = 0.0
	if away.length() < 0.2:
		away = Vector3(0, 0, 1)
	var spot: Vector3 = (alvo.global_position if alvo != null else target) + away.normalized() * stand
	spot.y = floor_y
	await walk_to(spot, 0.6, 30.0)
	_look_at_point(aim)
	await _frames(4)
	var it := _ray_target()
	if it == null:
		# ajuste fino: dois passos de cada lado, como um jogador tentando acertar
		for off in [Vector3(0.5, 0, 0), Vector3(-0.5, 0, 0), Vector3(0, 0, 0.5), Vector3(0, 0, -0.5)]:
			await walk_to(spot + off, 0.35, 8.0)
			_look_at_point(aim)
			await _frames(4)
			it = _ray_target()
			if it != null:
				break
	if it == null:
		_fail("nada no raio de interação em %s (%s) — objeto: %s" % [
			label, _v(target), ("sim" if alvo != null else "não localizado")])
		return false
	var prompt := it.prompt()
	if expect != "" and not prompt.to_lower().contains(expect.to_lower()):
		_fail("prompt inesperado em %s: \"%s\" (esperava conter \"%s\")" % [label, prompt, expect])
		return false
	await _press("interact", 3)
	await _frames(6)
	_ok("usei %s — prompt: \"%s\"" % [label, prompt])
	return true


## Usa o objeto interativo mais próximo cujo texto contenha `expect`.
## Painéis de monta-carga, itens e consoles: o jogador lê o texto na tela.
func use_prompt(expect: String, label: String, floor_y := -1.0, stand := 1.5) -> bool:
	var alvo := _find_prompt(expect, 40.0)
	if alvo == null:
		_fail("não achei nenhum objeto com o texto \"%s\" (%s)" % [expect, label])
		return false
	var fy := floor_y if floor_y > 0.0 else _floor_y()
	return await use(alvo.global_position + Vector3(0, 0.6, 0), {
		"label": label, "expect": expect, "stand": stand, "floor_y": fy,
	})


func _find_prompt(expect: String, raio: float) -> Interactable:
	var melhor: Interactable = null
	var melhor_d := raio
	for n in get_tree().get_nodes_in_group("interactables"):
		var it := n as Interactable
		if it == null or not it.enabled:
			continue
		if not it.prompt().to_lower().contains(expect.to_lower()):
			continue
		var d: float = it.global_position.distance_to(player.global_position)
		if d < melhor_d:
			melhor_d = d
			melhor = it
	return melhor


func _panel() -> Node:
	return UI._panel


func _wait_panel(timeout := 6.0) -> Node:
	var t := 0.0
	while t < timeout:
		if UI._panel != null:
			return UI._panel
		t += 1.0 / 60.0
		await get_tree().physics_frame
	return null


func close_panel() -> void:
	await _press_key(KEY_ESCAPE, 3)
	await _frames(6)
	if UI._panel != null:
		await _press_key(KEY_ESCAPE, 3)
		await _frames(6)


## Lê um terminal inteiro: percorre todos os registros e confirma cada um.
func read_terminal_full(target: Vector3, expect: String, label: String) -> void:
	var painel := await _wait_panel()
	var dr: DocReader = painel as DocReader
	if dr == null:
		_warn("nenhum leitor de documentos em %s (painel: %s)" % [label, painel])
		return
	await _frames(8)
	var n := dr.ids.size()
	for i in n:
		dr._show(i)
		await _frames(8)
		await read_doc()
		if i < n - 1:
			await use(target, {"label": label + " (reabrindo)", "expect": expect, "floor_y": _floor_y()})
			painel = await _wait_panel()
			dr = painel as DocReader
			if dr == null:
				return


## Lê um documento: avança a digitação, fecha e confirma que fechou.
func read_doc() -> void:
	await _frames(10)
	for i in 4:
		await _press("interact", 2)
		await _frames(6)
		if UI._panel == null:
			return
	_warn("o leitor de documentos não fechou com [E] (painel: %s)" % UI._panel)
	await _press_key(KEY_ESCAPE, 2)


func type_code(expected: String, label: String) -> bool:
	var kp := await _wait_panel()
	if kp == null:
		_fail("o teclado numérico não abriu (%s)" % label)
		return false
	if not (kp is KeypadPanel):
		_fail("painel errado ao abrir o teclado (%s): %s" % [label, kp.get_class()])
		return false
	if not _check(String(kp.code) == expected, "código do teclado confere com a pista (%s)" % label,
			"código do teclado NÃO confere: %s (esperava %s)" % [kp.code, expected]):
		await close_panel()
		return false
	for d in expected:
		kp._digit(d)
	await _frames(3)
	kp._submit()
	await _frames(6)
	if UI._panel != null:
		# código recusado: um jogador fecharia o teclado e seguiria
		_warn("teclado continuou aberto depois de digitar %s (%s)" % [expected, label])
		await close_panel()
	return true


# ================================================================ ROTEIRO
## Caminho do MENU: espera a tela inicial e clica no botão com o MOUSE, como
## faz qualquer jogador. Se o clique não funcionar, o jogo nem começa.
func _menu_flow() -> bool:
	if not main._play_menu:
		return false
	print("\n[BOT] ===== TESTE DO MENU (clique com o mouse) =====")
	_ok("menu aberto: %s" % (UI._menu != null))
	var botao := _find_button(UI._menu, "NOVA EXPEDIÇÃO")
	if botao == null:
		_fail("não achei o botão NOVA EXPEDIÇÃO no menu")
		_report()
		get_tree().quit()
		return true
	# a UI desenha em 1600x900 e a janela escala: o clique tem de ser em pixels
	# da janela, como o sistema operacional entrega
	var centro: Vector2 = get_viewport().get_final_transform() * botao.get_global_rect().get_center()
	# o cursor precisa chegar até o botão antes do clique (como o jogador faz)
	var mv := InputEventMouseMotion.new()
	mv.position = centro
	mv.global_position = centro
	Input.parse_input_event(mv)
	await _wait(0.3)
	var cl := InputEventMouseButton.new()
	cl.button_index = MOUSE_BUTTON_LEFT
	cl.pressed = true
	cl.position = centro
	cl.global_position = centro
	Input.parse_input_event(cl)
	await _frames(3)
	var solta := InputEventMouseButton.new()
	solta.button_index = MOUSE_BUTTON_LEFT
	solta.pressed = false
	solta.position = centro
	solta.global_position = centro
	Input.parse_input_event(solta)
	await _wait(1.0)
	_check(UI._menu == null, "o clique em NOVA EXPEDIÇÃO iniciou a expedição",
			"O CLIQUE DO MOUSE NO MENU NÃO FUNCIONOU (menu continua aberto)")
	_check(main.player != null, "o jogador entrou no mundo depois do clique",
			"o mundo não começou depois do clique no menu")
	return true


func _find_button(raiz: Node, texto: String) -> Button:
	if raiz == null:
		return null
	for c in raiz.find_children("*", "Button", true, false):
		var b := c as Button
		if b != null and b.text.to_upper().contains(texto.to_upper()):
			return b
	return null


func _run() -> void:
	await _wait(0.3)
	if await _menu_flow():
		return
	print("\n[BOT] ===== EXPEDIÇÃO AUTOMÁTICA — VOZES DO OCEANO =====")
	Engine.time_scale = 2.2
	await _wait(0.6)
	player = main.player
	if player == null:
		_fail("jogador não existe")
		get_tree().quit()
		return
	_check_audio()
	# pula a abertura como um jogador impaciente
	var guard := 0
	while UI.blocked and guard < 60:
		await _press("interact", 2)
		await _wait(0.4)
		guard += 1
	_check(not UI.blocked, "abertura concluída (texto avançado)", "a abertura não terminou")
	await _wait(0.6)
	await _check_mouse_look()
	await _check_mouse_recovery()
	await _measure_sens()
	_check(player.is_on_floor() and absf(player.global_position.y - 40.0) < 0.6,
			"jogador de pé no piso do hangar ao acordar (%s)" % _v(player.global_position),
			"jogador não está apoiado no piso no início: %s" % _v(player.global_position))
	_check(AudioMan.has_voice("iris_01") and AudioMan.has_voice("andrei_01"),
			"vozes da tripulação carregadas", "vozes não carregaram no AudioMan")
	await _shot("01-hangar")

	# ---------- abrir o briefing (deve funcionar sem energia) ----------
	await use(Vector3(-12.0, 40.0, -20.2), {"label": "terminal do hangar", "expect": "terminal"})
	await read_terminal_full(Vector3(-12.0, 40.0, -20.2), "terminal", "terminal do hangar")
	_check(GameState.is_read("bl_000"), "briefing lido (bl_000)", "briefing não foi registrado como lido")
	_check(GameState.is_read("log_argos_01"), "diário de Íris lido no mesmo terminal", "diário de Íris não foi lido")
	await _shot("02-briefing")

	# ---------- fusível no depósito ----------
	await walk_to(Vector3(-11.0, 40, -23.0), 1.2)
	await walk_to(Vector3(0.0, 40, -23.0), 1.0)
	await walk_to(Vector3(0.0, 40, -16.0), 1.0)
	await walk_to(Vector3(-14.0, 40, -8.0), 1.4)
	await use(Vector3(-38.0, 40.0, 8.0), {"label": "bancada de manutenção", "expect": "terminal", "floor_y": 40.0})
	await read_terminal_full(Vector3(-38.0, 40.0, 8.0), "terminal", "bancada de manutenção")
	_check(GameState.is_read("manuel_reactor"), "manual do reator lido", "manual do reator não foi lido")
	var doc: Dictionary = Content.get_doc("manuel_reactor")
	_check(String(doc.get("body", "")).contains("A2"),
			"o manual traz a pista da sequência (A2/B1/C3/D4)", "o manual NÃO contém a pista dos disjuntores")
	await use(Vector3(-34.0, 40.0, -4.6), {"label": "fusível de 400 A", "aim_y": 1.32, "expect": "fusível", "floor_y": 40.0})
	_check(GameState.has("tem_fusivel"), "fusível coletado", "fusível NÃO foi coletado")
	await _shot("03-deposito")

	# ---------- monta-carga A ----------
	await walk_to(Vector3(-16.5, 40, 0), 1.2)
	await walk_to(Vector3(-16.0, 40, -16.0), 1.2)
	await walk_to(Vector3(-6.0, 40, -16.5), 1.2)
	await use_prompt("chamar", "painel de chamada do monta-carga (convés 1)", 40.0)
	await _wait_lift_at(39.87, "chamada do monta-carga A")
	await walk_to(Vector3(9.0, 40, -16.5), 0.8)
	await use_prompt("operar", "painel da plataforma (subindo)", 40.0, 0.4)
	await _wait_ride_up(51.5, "monta-carga A → convés 2")
	await walk_to(Vector3(5.5, 52, -16.5), 1.0)
	await _shot("04-conves2")
	_release_all()

	# ---------- energia: painel + teclado ----------
	await walk_to(Vector3(12.0, 52, -16.5), 1.2)
	await walk_to(Vector3(16.0, 52, -14.0), 1.2)
	await walk_to(Vector3(16.0, 52, -2.0), 1.2)
	await walk_to(Vector3(21.0, 52, 2.0), 1.2)
	await use(Vector3(22.0, 52.0, 6.0), {"label": "painel de energia", "aim_y": 1.0, "expect": "painel de energia", "floor_y": 52.0})
	await type_code("2134", "disjuntores do reator")
	await _wait(1.2)
	_check(GameState.has("energia_ok"), "ENERGIA RESTAURADA (sequência A2-B1-C3-D4 aceita)",
			"a energia NÃO foi restaurada — puzzle do reator falhou")
	_check(Director.chapter >= 1, "capítulo 1 iniciou após a energia",
			"o capítulo não avançou após restaurar a energia (cap=%d)" % Director.chapter)
	await _shot("05-energia")

	# ---------- lanternas / recursos ----------
	var bat0 := GameState.battery
	await _press("torch", 3)
	await _wait(1.5)
	_check(GameState.battery < bat0, "a lanterna consome bateria", "a bateria não caiu com a lanterna ligada")
	_check(player.flashlight.visible, "lanterna acendeu visivelmente", "a lanterna não ficou visível")
	await _press("torch", 3)

	# ---------- laboratórios: Protocolo Espelho ----------
	await walk_to(Vector3(21.0, 52, 2.0), 1.2)
	await walk_to(Vector3(20.0, 52, 0.0), 1.0)
	await walk_to(Vector3(16.5, 52, 0.0), 1.0)
	await walk_to(Vector3(16.0, 52, -8.0), 1.2)
	await walk_to(Vector3(16.0, 52, -14.0), 1.2)
	await walk_to(Vector3(16.0, 52, -16.5), 1.2)
	await walk_to(Vector3(11.5, 52, -16.5), 1.2)
	await walk_to(Vector3(1.0, 52, -16.5), 1.2)
	await walk_to(Vector3(0.0, 52, -20.0), 1.2)
	await walk_to(Vector3(-5.0, 52, -20.5), 1.2)
	await use(Vector3(-10.0, 52.0, -21.0), {"label": "estação de análise (labs)", "expect": "terminal", "floor_y": 52.0})
	await read_terminal_full(Vector3(-10.0, 52.0, -21.0), "terminal", "estação de análise")
	_check(GameState.is_read("mirror_proto"), "Protocolo Espelho lido", "Protocolo Espelho NÃO foi lido")
	_check(Director.chapter >= 2, "capítulo 2 iniciou ao ler o Protocolo Espelho",
			"o capítulo não avançou para 2 (cap=%d)" % Director.chapter)
	await _shot("06-labs")

	# ---------- rádio: transcrição com o código do cofre ----------
	await walk_to(Vector3(-5.0, 52, -20.5), 1.2)
	await walk_to(Vector3(0.0, 52, -20.0), 1.2)
	await walk_to(Vector3(0.0, 52, -16.5), 1.2)
	await walk_to(Vector3(-11.5, 52, -16.5), 1.2)
	await walk_to(Vector3(-16.0, 52, -16.0), 1.2)
	await walk_to(Vector3(-16.0, 52, -4.0), 1.2)
	await walk_to(Vector3(-16.0, 52, -0.5), 1.0)
	await walk_to(Vector3(-23.0, 52, -0.5), 1.2)
	await use(Vector3(-30.0, 52.0, -8.0), {"label": "transceptor", "aim_y": 1.0, "expect": "rádio", "floor_y": 52.0})
	var panel := await _wait_panel()
	if panel != null and panel is RadioPanel:
		var rp := panel as RadioPanel
		_check(rp.signals.size() >= 5, "transceptor com %d frequências" % rp.signals.size(),
				"transceptor com poucas frequências (%d)" % rp.signals.size())
		for i in mini(4, rp.signals.size()):
			rp._tune(i)
			await _wait(1.4)
		await close_panel()
	else:
		_fail("o painel de rádio não abriu (painel: %s)" % panel)
	await walk_to(Vector3(-26.0, 52, 2.0), 1.2)
	await walk_to(Vector3(-29.0, 52, 5.0), 1.2)
	await use(Vector3(-30.0, 52.0, 8.0), {"label": "transcrições de comunicação", "aim_y": 1.0, "expect": "terminal", "floor_y": 52.0})
	panel = await _wait_panel()
	if panel != null and panel is DocReader:
		await read_doc()
	_check(GameState.is_read("ops_comm_01"), "transcrição de Nadia lida", "transcrição do cofre não foi lida")
	_check(String(Content.get_doc("ops_comm_01").get("body", "")).contains("Onze de abril"),
			"a pista do código do cofre está no texto (onze de abril)",
			"a pista do código NÃO está na transcrição — puzzle sem solução")
	await _shot("07-radio")

	# ---------- monta-carga B → convés 3 ----------
	await walk_to(Vector3(-26.0, 52, 1.0), 1.2)
	await walk_to(Vector3(-21.0, 52, -0.5), 1.2)
	await walk_to(Vector3(-16.5, 52, 0.5), 1.0)
	await walk_to(Vector3(-16.0, 52, 14.0), 1.2)
	await walk_to(Vector3(-8.0, 52, 16.0), 1.2)
	await walk_to(Vector3(6.0, 52, 16.0), 1.2)
	await walk_to(Vector3(14.6, 52, 12.0), 1.0)
	await use_prompt("chamar", "painel de chamada do monta-carga (convés 2)", 52.0)
	await _wait_lift_at(51.87, "chamada do monta-carga B")
	await walk_to(Vector3(16.4, 52, 10.5), 1.0)
	await walk_to(Vector3(16.4, 52, 8.0), 0.8)
	await use_prompt("operar", "painel da plataforma (convés 3)", 52.0, 0.4)
	await _wait_ride_up(63.5, "monta-carga B → convés 3")
	await walk_to(Vector3(14.6, 64, 8.0), 1.0)
	await _shot("08-conves3")

	# ---------- comando: cofre com o código da Nadia + CCTV ----------
	await walk_to(Vector3(16.0, 64, 2.0), 1.2)
	await walk_to(Vector3(16.0, 64, -14.0), 1.2)
	await walk_to(Vector3(8.0, 64, -16.5), 1.2)
	await walk_to(Vector3(1.0, 64, -16.5), 1.2)
	await walk_to(Vector3(0.0, 64, -22.5), 1.2)
	await use(Vector3(9.0, 64.0, -20.0), {"label": "console de vigilância", "aim_y": 1.0, "expect": "vigilância", "floor_y": 64.0})
	panel = await _wait_panel()
	if panel != null and panel is CCTVScreen:
		var cv := panel as CCTVScreen
		await _wait(1.6)
		_check(cv.ids.size() >= 8, "CCTV com %d canais registrados" % cv.ids.size(),
				"CCTV com poucos canais (%d)" % cv.ids.size())
		cv._select(6)
		await _wait(1.2)
		cv._select(1)
		await _wait(1.0)
		await close_panel()
	else:
		_fail("o terminal de câmeras não abriu (painel: %s)" % panel)
	await use(Vector3(-4.0, 64.0, -20.0), {"label": "terminal pessoal de Íris", "expect": "terminal", "floor_y": 64.0})
	panel = await _wait_panel()
	if panel != null and panel is DocReader:
		await read_doc()
	await use(Vector3(0.0, 64.0, -20.5), {"label": "cofre (sala segura)", "aim_y": 1.0, "expect": "código", "floor_y": 64.0})
	await type_code("1104", "cofre da sala segura")
	await _wait(0.8)
	_check(GameState.has("chave_eng"), "cartão de engenharia obtido (código 1104 = 11 de abril)",
			"o cofre não abriu com 1104 — pista x código quebrada")
	await _shot("09-comando")

	# ---------- sino ----------
	await walk_to(Vector3(0.0, 64, -16.5), 1.4)
	await walk_to(Vector3(14.0, 64, -16.0), 1.2)
	await walk_to(Vector3(16.0, 64, -10.0), 1.2)
	await walk_to(Vector3(16.0, 64, 4.0), 1.2)
	await walk_to(Vector3(16.0, 64, 14.0), 1.2)
	await walk_to(Vector3(8.0, 64, 16.0), 1.2)
	await walk_to(Vector3(0.5, 64, 16.2), 1.0)
	await walk_to(Vector3(0.5, 64, 18.4), 0.8)
	await walk_to(Vector3(0.5, 64, 22.0), 1.2)
	await walk_to(Vector3(0.5, 64, 25.0), 1.4)
	await use(Vector3(6.0, 64.0, 30.0), {"label": "gravador da câmara do sino", "aim_y": 1.2, "expect": "fita", "floor_y": 64.0})
	panel = await _wait_panel()
	if panel != null and panel is DocReader:
		await read_doc()
	_check(GameState.is_read("fita_2"), "fita do silêncio ouvida", "a fita do sino não foi lida")
	await _shot("10-sino")

	# ---------- corredor de observação: a porta selada ----------
	await walk_to(Vector3(0.5, 64, 22.0), 1.2)
	await walk_to(Vector3(0.5, 64, 18.4), 0.8)
	await walk_to(Vector3(0.5, 64, 16.2), 1.2)
	await walk_to(Vector3(14.0, 64, 16.0), 1.2)
	await walk_to(Vector3(16.0, 64, 8.0), 1.2)
	await walk_to(Vector3(16.0, 64, 0.0), 1.2)
	await walk_to(Vector3(22.0, 64, 0.0), 1.4)
	await walk_to(Vector3(29.0, 64, 0.0), 1.4)
	var selada: Door = Director.doors.get("selada", null)
	if selada != null:
		_check(selada.state == Door.State.OPEN or GameState.chapter >= 2,
				"porta selada do módulo: %s" % ("aberta por conta própria (anomalia confirmada)" if selada.state == Door.State.OPEN else "fechada"),
				"porta selada em estado impossível")
	await _shot("11-corredor-obs")

	# ---------- monta-carga C → módulo de observação ----------
	await use_prompt("chamar", "painel de chamada do monta-carga (observação)", 64.0)
	await _wait_lift_at(63.87, "chamada do monta-carga C")
	await walk_to(Vector3(34.1, 64, 0.0), 0.45)
	await use_prompt("operar", "painel da plataforma (módulo)", 64.0, 0.4)
	await _wait_ride_up(75.5, "monta-carga C → módulo de observação")
	await walk_to(Vector3(31.5, 76, 0.0), 1.0)
	await _shot("12-antessala")
	await walk_to(Vector3(24.0, 76, 0.0), 1.2)
	await walk_to(Vector3(16.0, 76, 0.0), 1.2)
	await walk_to(Vector3(8.0, 76, 0.0), 1.2)
	await _shot("13-modulo")
	await walk_to(Vector3(0.0, 76, 8.0), 1.6)

	# ---------- registros finais + a janela ----------
	await use(Vector3(-11.0, 76.0, 8.0), {"label": "console do Protocolo Espelho", "expect": "terminal", "floor_y": 76.0})
	panel = await _wait_panel()
	if panel != null and panel is DocReader:
		await read_doc()
	await walk_to(Vector3(0.0, 76, 15.0), 1.4)
	_look_at_point(Vector3(0.0, 77.0, 40.0))
	await _wait(1.0)
	await _shot("14-janela-do-modulo")

	# ---------- decisão final ----------
	await walk_to(Vector3(9.0, 76, 8.0), 1.4)
	await use(Vector3(11.0, 76.0, 8.0), {"label": "console ECHO", "aim_y": 1.0, "expect": "echo", "floor_y": 76.0})
	panel = await _wait_panel()
	if panel != null and panel is ChoicePanel:
		var cp := panel as ChoicePanel
		_check(cp.decision.has("options") and cp.decision["options"].size() >= 4,
				"a decisão final oferece %d respostas" % (cp.decision["options"].size() if cp.decision.has("options") else 0),
				"a decisão final não tem respostas")
		await _wait(1.2)
		cp._choose("chamado")
		_ok("respondi ao oceano: FALAR (chamado)")
	else:
		_fail("o console ECHO não abriu o painel de decisão final (painel: %s)" % panel)
	await _wait(4.0)
	_check(GameState.has("final_a"), "final registrado (final_a)", "nenhum final foi registrado")
	await _wait(3.0)
	_check(UI._ending != null, "a tela de desfecho apareceu", "a tela de desfecho NÃO apareceu")
	await _shot("15-final")
	await _wait(2.0)

	# ---------- exploração livre pós-final (só para pegar lixo de runtime) ----------
	_check(AudioServer.get_bus_index("Music") >= 0 and AudioServer.get_bus_index("Voice") >= 0,
			"barramentos de áudio íntegros", "barramento de áudio faltando")
	_report()
	get_tree().quit()


## Testa o OLHAR COM O MOUSE: confere o estado de captura e injeta movimento
## relativo como o sistema operacional faz — se a câmera não girar, o mouse
## está quebrado para quem joga.
func _check_mouse_look() -> void:
	_check(Input.mouse_mode == Input.MOUSE_MODE_CAPTURED or Input.mouse_mode == Input.MOUSE_MODE_CONFINED_HIDDEN,
			"mouse capturado durante o jogo (modo %d)" % Input.mouse_mode,
			"MOUSE NÃO CAPTURADO durante o jogo (modo %d) — o cursor fica solto e a câmera não gira" % Input.mouse_mode)
	var antes_y := player.rotation.y
	var antes_x := player.camera.rotation.x
	var centro := Vector2(get_viewport().get_visible_rect().size * 0.5)
	for i in 10:
		var ev := InputEventMouseMotion.new()
		ev.position = centro
		ev.global_position = centro
		ev.relative = Vector2(24.0, 0.0)
		Input.parse_input_event(ev)
		await get_tree().process_frame
	var girou := absf(player.rotation.y - antes_y) > 0.05
	for i in 10:
		var ev2 := InputEventMouseMotion.new()
		ev2.position = centro
		ev2.global_position = centro
		ev2.relative = Vector2(0.0, 18.0)
		Input.parse_input_event(ev2)
		await get_tree().process_frame
	var subiu := absf(player.camera.rotation.x - antes_x) > 0.03
	_check(girou, "o mouse gira a câmera na horizontal (%.3f rad)" % (player.rotation.y - antes_y),
			"MOUSE NÃO GIRA A CÂMERA: movimento relativo ignorado (dy=%.4f)" % (player.rotation.y - antes_y))
	_check(subiu, "o mouse inclina a câmera na vertical (%.3f rad)" % (player.camera.rotation.x - antes_x),
			"MOUSE NÃO INCLINA A CÂMERA (dx=%.4f)" % (player.camera.rotation.x - antes_x))


## Simula a perda de foco da janela (alt-tab, diálogo do sistema, launcher
## desfocado): o SO solta o cursor. O jogo tem de se recuperar sozinho — ou,
## no pior caso, ao primeiro clique dentro da janela.
func _check_mouse_recovery() -> void:
	# 1) o sistema solta o cursor no meio do jogo
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	await _wait(0.8)
	var sozinho := player.mouse_captured()
	if not sozinho:
		# 2) jogador clica dentro da janela para voltar a olhar
		var centro := Vector2(get_viewport().get_visible_rect().size * 0.5)
		var cl := InputEventMouseButton.new()
		cl.button_index = MOUSE_BUTTON_LEFT
		cl.pressed = true
		cl.position = centro
		cl.global_position = centro
		Input.parse_input_event(cl)
		await _wait(0.4)
	_check(sozinho or player.mouse_captured(),
			"o mouse se recupera depois de o sistema soltar o cursor (%s)" % ("sozinho" if sozinho else "com um clique"),
			"DEPOIS DE PERDER O FOCO O MOUSE NÃO VOLTA — o jogador fica sem olhar")
	# 3) e continua girando a câmera
	var antes := player.rotation.y
	var centro2 := Vector2(get_viewport().get_visible_rect().size * 0.5)
	for i in 8:
		var ev := InputEventMouseMotion.new()
		ev.position = centro2
		ev.global_position = centro2
		ev.relative = Vector2(20.0, 0.0)
		Input.parse_input_event(ev)
		await get_tree().process_frame
	_check(absf(player.rotation.y - antes) > 0.04, "o mouse volta a girar a câmera depois da recuperação",
			"o mouse não gira a câmera depois de recuperar a captura")
	# 4) sem captura, o olhar ainda funciona (rede de segurança)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	await _wait(0.1)
	var antes2 := player.rotation.y
	for i in 6:
		var ev2 := InputEventMouseMotion.new()
		ev2.position = centro2
		ev2.global_position = centro2
		ev2.relative = Vector2(20.0, 0.0)
		Input.parse_input_event(ev2)
		await get_tree().process_frame
	_check(absf(player.rotation.y - antes2) > 0.03, "mesmo com o cursor solto o olhar responde",
			"com o cursor solto a câmera não gira (jogo injogável)")
	# 5) OLHAR POR ARRASTO: o esquema que funciona quando o navegador nega a captura
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var centro3 := Vector2(get_viewport().get_visible_rect().size * 0.5)
	var baixo := InputEventMouseButton.new()
	baixo.button_index = MOUSE_BUTTON_LEFT
	baixo.pressed = true
	baixo.position = centro3
	baixo.global_position = centro3
	Input.parse_input_event(baixo)
	await get_tree().process_frame
	var antes3 := player.rotation.y
	for i in 8:
		var ev3 := InputEventMouseMotion.new()
		ev3.position = centro3
		ev3.global_position = centro3
		ev3.screen_relative = Vector2(20.0, 0.0)
		Input.parse_input_event(ev3)
		await get_tree().process_frame
	var subiu := InputEventMouseButton.new()
	subiu.button_index = MOUSE_BUTTON_LEFT
	subiu.pressed = false
	subiu.position = centro3
	subiu.global_position = centro3
	Input.parse_input_event(subiu)
	_check(absf(player.rotation.y - antes3) > 0.03, "arrastar com o botão esquerdo gira a câmera (esquema alternativo)",
			"O ARRASTO NÃO GIRA A CÂMERA — sem captura o jogo fica injogável")


## Mede a sensibilidade efetiva: um único movimento relativo de 100 px deve
## girar a câmera em 100 * mouse_sens radianos (fora isso, o mouse "voa").
func _measure_sens() -> void:
	var antes := player.rotation.y
	var centro := Vector2(get_viewport().get_visible_rect().size * 0.5)
	var ev := InputEventMouseMotion.new()
	ev.position = centro
	ev.global_position = centro
	# como o sistema operacional entrega: screen_relative em pixels de tela
	ev.screen_relative = Vector2(100.0, 0.0)
	ev.relative = get_viewport().get_final_transform().basis_xform(Vector2(100.0, 0.0))
	Input.parse_input_event(ev)
	await get_tree().process_frame
	await get_tree().process_frame
	var delta := absf(player.rotation.y - antes)
	var esperado := 100.0 * player.mouse_sens
	print("[BOT] diag sensibilidade: 100 px -> %.4f rad (esperado %.4f, fator %.2fx)" % [delta, esperado, delta / maxf(esperado, 0.0001)])
	_check(delta < esperado * 1.35 and delta > esperado * 0.65, "sensibilidade do mouse dentro do previsto (fator %.2fx)" % (delta / maxf(esperado, 0.0001)),
			"SENSIBILIDADE FORA DO PREVISTO: 100 px de tela giram %.3f rad (fator %.2fx) — a escala da janela está mexendo na câmera" % [delta, delta / maxf(esperado, 0.0001)])


func _check_audio() -> void:
	var ok_buses := true
	for b in ["Music", "SFX", "Voice", "Radio"]:
		if AudioServer.get_bus_index(b) < 0:
			ok_buses = false
			_fail("barramento de áudio ausente: %s" % b)
	if ok_buses:
		_ok("barramentos de áudio criados (Music/SFX/Voice/Radio)")
	var faltando: Array[String] = []
	for k in _expected_voices:
		if not AudioMan.has_voice(k):
			faltando.append(k)
	_check(faltando.is_empty(), "as %d vozes da tripulação estão carregadas" % _expected_voices.size(),
			"vozes ausentes: %s" % str(faltando))
	_check(AudioMan.get_layer("air") > 0.0 or AudioMan.get_layer("sub") > 0.0,
			"camadas de trilha ativas", "nenhuma camada de trilha ativa")
	# a voz precisa TOCAR de verdade no build que o jogador recebe (no editor a
	# lista de arquivos vinha do diretório; em build exportada isso não existe)
	var vp: Node = AudioMan.play_voice("iris_01", null, -6.0)
	var tocando := vp != null and (vp as AudioStreamPlayer).playing
	_check(tocando, "a voz da tripulação realmente toca (iris_01)",
			"A VOZ NÃO TOCA no build: play_voice devolveu %s" % vp)
	if vp != null:
		await _frames(4)
		_check((vp as AudioStreamPlayer).stream != null and (vp as AudioStreamPlayer).stream.get_length() > 0.2,
				"o áudio da voz tem conteúdo (%.1f s)" % (vp as AudioStreamPlayer).stream.get_length(),
				"o stream da voz está vazio")
		vp.queue_free()


## Espera a plataforma do monta-carga chegar ao nível pedido (y).
func _wait_lift_at(y_alvo: float, nome: String) -> void:
	var plat := _nearest_lift()
	if plat == null:
		_fail("%s: não encontrei a plataforma do monta-carga" % nome)
		return
	var t := 0.0
	while t < 30.0:
		if absf(plat.global_position.y - y_alvo) < 0.35:
			_ok("%s: plataforma no nível %.0f" % [nome, y_alvo])
			return
		t += 1.0 / 60.0
		await get_tree().physics_frame
	_fail("%s: a plataforma não chegou ao nível %.0f (está em %.1f)" % [nome, y_alvo, plat.global_position.y])


func _nearest_lift() -> AnimatableBody3D:
	for n in main.world_root.find_children("*", "AnimatableBody3D", true, false):
		var lp := n as Node3D
		if lp.global_position.distance_to(player.global_position) < 12.0:
			return n as AnimatableBody3D
	return null


func _wait_ride_up(y_alvo: float, nome: String) -> void:
	var t := 0.0
	while t < 30.0:
		if player.global_position.y >= y_alvo:
			_release_all()
			_ok("%s (jogador chegou em y=%.1f)" % [nome, player.global_position.y])
			return
		t += 1.0 / 60.0
		await get_tree().physics_frame
	var plat2 := _nearest_lift()
	if plat2 != null and absf(plat2.global_position.y - player.global_position.y) < 3.0:
		_warn("%s: o monta-carga subiu sem o jogador — tentando embarcar de novo" % nome)
	_fail("%s: o jogador não foi carregado pelo monta-carga (y=%.1f, esperava %.1f)" % [nome, player.global_position.y, y_alvo])


func _report() -> void:
	print("\n[BOT] ===== RELATÓRIO =====")
	print("[BOT] verificações ok: %d" % tasks)
	print("[BOT] avisos: %d" % warns.size())
	for w in warns:
		print("[BOT]   ! " + w)
	print("[BOT] falhas: %d" % fails.size())
	for f in fails:
		print("[BOT]   ✖ " + f)
	print("[BOT] screenshots: %d em %s" % [shots, shot_dir])
	print("[BOT] =====================\n")
