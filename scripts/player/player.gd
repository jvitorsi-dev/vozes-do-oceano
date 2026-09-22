class_name Player
extends CharacterBody3D
## Jogador em primeira pessoa: andar, olhar, lanterna, oxigênio e interação.
## Sem combate. A única arma é a lanterna — e ela às vezes espanta coisas.

signal stepped(pos: Vector3, sprinting: bool)
signal sector_changed(sector: String)
signal blacked_out()
signal interacted(target: Node)

const EYE := 1.62
const CROUCH_EYE := 1.05

var walk_speed := 2.9
var sprint_speed := 4.7
var crouch_speed := 1.5
var accel := 12.0
var mouse_sens := 0.0026
var fov := 78.0

var camera: Camera3D
var ray: RayCast3D
var flashlight: SpotLight3D
var flashlight_on := false
var controllado := true
var in_vacuum := false
var stress := 0.0

var _bob := 0.0
var _step_dist := 0.0
var _crouching := false
var _step_cd := 0.0
var _capture_watch := 0.0
var _dragging := false
var _capture_negado := false
var _target_inter: Interactable = null
var _breath_player: AudioStreamPlayer
var _breath_t := 0.0
var _sector := ""
var pending_sector := ""
var _look_point := Vector3.ZERO
var _has_looked := false


func _ready() -> void:
	mouse_sens = GameState.mouse_sens_pref
	add_to_group("player")
	motion_mode = CharacterBody3D.MOTION_MODE_GROUNDED
	floor_snap_length = 0.4
	floor_max_angle = deg_to_rad(50)
	slide_on_ceiling = true
	collision_layer = 1
	collision_mask = 1

	var cs := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.34
	cap.height = 1.78
	cs.shape = cap
	cs.position = Vector3(0, 0.89, 0)
	add_child(cs)

	camera = Camera3D.new()
	camera.name = "Camera"
	camera.position = Vector3(0, EYE, 0)
	camera.fov = fov
	camera.near = 0.05
	camera.far = 8000.0
	add_child(camera)

	ray = RayCast3D.new()
	ray.name = "Ray"
	ray.target_position = Vector3(0, 0, -2.7)
	ray.collision_mask = 1 | 2
	ray.collide_with_areas = true
	ray.collide_with_bodies = true
	camera.add_child(ray)

	# lanterna de capacete
	flashlight = SpotLight3D.new()
	flashlight.name = "Lanterna"
	flashlight.light_energy = 3.4
	flashlight.light_color = Color(0.92, 0.95, 1.0)
	flashlight.spot_range = 26.0
	flashlight.spot_angle = 33.0
	flashlight.spot_angle_attenuation = 1.1
	flashlight.shadow_enabled = true
	flashlight.shadow_bias = 0.03
	flashlight.position = Vector3(0.12, -0.12, 0)
	flashlight.visible = false
	camera.add_child(flashlight)

	_breath_player = AudioStreamPlayer.new()
	_breath_player.stream = AudioMan.sfx("breath")
	_breath_player.bus = "SFX"
	_breath_player.volume_db = -22.0
	add_child(_breath_player)
	_breath_player.play()

	GameState.o2_changed.emit(GameState.o2)


func _unhandled_input(event: InputEvent) -> void:
	# (o olhar com o mouse fica em _input: ver _input() abaixo)
	if UI.blocked or not controllado:
		return
	if event.is_action_pressed("interact"):
		_try_interact()
	if event.is_action_pressed("torch"):
		toggle_flashlight()
	if event.is_action_pressed("recenter"):
		_request_mouse_capture()
		UI.show_note("MOUSE", "Cursor preso ao jogo (F1). Se o ponteiro voltar a aparecer, clique na janela ou aperte F1.")
	if event.is_action_pressed("diag"):
		_relatorio_mouse()


## Olhar e captura do mouse.
##
## Fica em _input (e não em _unhandled_input) de propósito: qualquer Control do
## HUD com mouse_filter STOP engoliria o movimento relativo antes do jogador —
## era assim que o mouse "morria" em algumas telas/plataformas.
func _input(event: InputEvent) -> void:
	var jogavel := controllado and not UI.blocked
	if event is InputEventMouseMotion:
		var mm := event as InputEventMouseMotion
		# screen_relative: movimento em pixels de TELA, imune à escala da janela.
		# (relative é multiplicado pela escala do viewport: em janela pequena a
		# câmera girava 2,5x mais rápido; em tela grande, mais devagar.)
		var rel := mm.screen_relative
		if rel == Vector2.ZERO:
			rel = mm.relative
		if jogavel and _dragging and rel != Vector2.ZERO:
			# olhar por arrasto: não depende de captura nenhuma
			look(rel * 1.15)
		elif jogavel and rel != Vector2.ZERO:
			# se o sistema ainda não capturou o cursor, pede a captura e olha do mesmo jeito
			if not mouse_captured():
				_request_mouse_capture()
			look(rel)
	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				if jogavel and not UI.blocked:
					# arrastar com o botão esquerdo gira a câmera mesmo quando o
					# navegador/sistema NÃO permite capturar o cursor (iframe,
					# Wayland, macOS sem permissão, janela sem foco)
					if not mouse_captured() and not _capture_negado:
						_request_mouse_capture()
					if not mouse_captured():
						_dragging = true
						UI.hint_mouse(true)
			else:
				_dragging = false


## Aplica um deslocamento relativo do mouse na câmera.
## Diagnóstico do mouse (F3): mostra na tela o que o motor está recebendo.
## Serve para o jogador (ou quem dá suporte) ver onde está o problema.
func _relatorio_mouse() -> void:
	var janela := get_window()
	UI.show_note("DIAGNÓSTICO DO MOUSE", "modo=%d (2 = capturado) · capturado=%s\njanela=%dx%d · tela interna=%dx%d · escala=%.2f\nsensibilidade=%.4f rad/px · F1 prende o cursor" % [
		Input.mouse_mode, str(mouse_captured()),
		int(janela.size.x), int(janela.size.y),
		int(get_viewport().get_visible_rect().size.x), int(get_viewport().get_visible_rect().size.y),
		get_viewport().get_final_transform().get_scale().x, mouse_sens])
	print("[MOUSE] modo=%d capturado=%s janela=%s tela=%s escala=%.2f sens=%.4f" % [
		Input.mouse_mode, str(mouse_captured()), janela.size,
		get_viewport().get_visible_rect().size, get_viewport().get_final_transform().get_scale().x, mouse_sens])


func look(rel: Vector2) -> void:
	rotate_y(-rel.x * mouse_sens)
	camera.rotation.x = clampf(camera.rotation.x - rel.y * mouse_sens, -1.45, 1.45)


## O cursor está preso ao jogo?
func mouse_captured() -> bool:
	return Input.mouse_mode == Input.MOUSE_MODE_CAPTURED \
			or Input.mouse_mode == Input.MOUSE_MODE_CONFINED_HIDDEN


## Prende o cursor ao jogo. Alguns sistemas (Wayland, janela sem foco, driver
## remoto) recusam MOUSE_MODE_CAPTURED: nesse caso usa CONFINED_HIDDEN, que
## ainda entrega movimento relativo — o jogo continua jogável de qualquer forma.
func _request_mouse_capture() -> void:
	if UI.blocked:
		return
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_CONFINED_HIDDEN


func _physics_process(delta: float) -> void:
	_watch_mouse(delta)
	var can := controllado and not UI.blocked
	if not can:
		velocity = velocity.lerp(Vector3.ZERO, clampf(delta * 8.0, 0.0, 1.0))
		move_and_slide()
		UI.hide_prompt()
		return

	var input_dir := Vector2.ZERO
	if Input.is_action_pressed("move_forward"):
		input_dir.y -= 1.0
	if Input.is_action_pressed("move_back"):
		input_dir.y += 1.0
	if Input.is_action_pressed("move_left"):
		input_dir.x -= 1.0
	if Input.is_action_pressed("move_right"):
		input_dir.x += 1.0
	input_dir = input_dir.normalized()

	_crouching = Input.is_action_pressed("crouch")
	var sprinting := Input.is_action_pressed("sprint") and not _crouching and input_dir.y < 0.1
	var speed := crouch_speed if _crouching else (sprint_speed if sprinting else walk_speed)
	if GameState.o2 < 0.15:
		speed *= 0.75

	var dir := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	var target := dir * speed
	velocity.x = lerpf(velocity.x, target.x, clampf(delta * accel, 0.0, 1.0))
	velocity.z = lerpf(velocity.z, target.z, clampf(delta * accel, 0.0, 1.0))
	if not is_on_floor():
		velocity.y -= 6.0 * delta
	else:
		velocity.y = -0.5

	# assistência de degrau: soleiras, tampas e a plataforma do monta-carga
	# (tampo nivelado com o piso) sobem sozinhas até ~0,32 m
	_step_cd = maxf(0.0, _step_cd - delta)
	var plano := Vector2(velocity.x, velocity.z).length()
	if is_on_floor() and _step_cd <= 0.0 and plano > 0.4:
		var passo := Vector3(velocity.x, 0.0, velocity.z) * delta
		if test_move(global_transform, passo) and not test_move(global_transform.translated(Vector3(0, 0.32, 0)), passo):
			velocity.y = 2.6
			_step_cd = 0.25

	move_and_slide()

	# passos
	var planar := Vector2(velocity.x, velocity.z).length()
	if is_on_floor() and planar > 0.6:
		_step_dist += planar * delta
		var stride := 1.55 if sprinting else (1.9 if _crouching else 1.35)
		if _step_dist >= stride:
			_step_dist = 0.0
			AudioMan.play_3d("step", global_position + Vector3(0, -0.9, 0), -16.0,
					randf_range(0.92, 1.08))
			stepped.emit(global_position, sprinting)

	# cabeça
	var target_eye := CROUCH_EYE if _crouching else EYE
	camera.position.y = lerpf(camera.position.y, target_eye, clampf(delta * 9.0, 0.0, 1.0))
	_bob += planar * delta * 3.4
	var bob_amt := 0.026 * clampf(planar / walk_speed, 0.0, 1.4) + stress * 0.01
	camera.position.y += sin(_bob * 2.0) * bob_amt
	camera.rotation.z = sin(_bob) * 0.006 * clampf(planar, 0.0, 4.0)
	camera.rotation.x += sin(_bob * 0.7) * 0.0012 * stress

	_update_flashlight(delta)
	_update_o2(delta)
	_update_ray()
	_update_breath(delta)


func _update_flashlight(delta: float) -> void:
	if flashlight_on:
		GameState.battery = maxf(0.0, GameState.battery - delta * 0.0018)
		var flick := 1.0
		if GameState.battery < 0.25:
			flick = 0.4 + 0.6 * absf(sin(Time.get_ticks_msec() * 0.004))
			if randf() < 0.01:
				flick *= 0.15
		flashlight.light_energy = 3.4 * flick
		if GameState.battery <= 0.0:
			flashlight_on = false
			flashlight.visible = false
			UI.show_note("BATERIA ESGOTADA", "A lanterna apagou. Há tomadas de recarga na engenharia.")
	GameState.battery_changed.emit(GameState.battery)


func toggle_flashlight() -> void:
	if GameState.battery <= 0.0:
		AudioMan.play_2d("deny", -10.0, 1.0, "Interface")
		return
	flashlight_on = not flashlight_on
	flashlight.visible = flashlight_on
	AudioMan.play_2d("click", -12.0, 1.0, "Interface")
	Director.on_flashlight(flashlight_on, global_position)


## Vigia o cursor: sempre que o jogo está jogável o mouse deve estar capturado.
## Cobre alt-tab, perda de foco, e plataformas que soltam o cursor sozinhas.
func _watch_mouse(delta: float) -> void:
	if not controllado or UI.blocked:
		_capture_watch = 0.0
		return
	if mouse_captured():
		_capture_watch = 0.0
		UI.hint_mouse(false)
		return
	_capture_watch += delta
	if _capture_watch > 0.35:
		_capture_watch = 0.0
		_request_mouse_capture()
		if not mouse_captured():
			# o navegador/sistema recusou a captura: avisa o esquema alternativo.
			# (o jogo continua 100% jogável: arrastar com o botão esquerdo olha)
			_capture_negado = true
			UI.hint_mouse(true)
		else:
			_capture_negado = false
			UI.hint_mouse(false)


func _update_o2(delta: float) -> void:
	if in_vacuum:
		GameState.o2 = maxf(0.0, GameState.o2 - delta * 0.009)
	else:
		GameState.o2 = minf(1.0, GameState.o2 + delta * 0.0016)
	if GameState.o2 <= 0.0:
		_blackout_sequence()


func _blackout_sequence() -> void:
	blacked_out.emit()
	GameState.o2 = 0.35
	UI.play_stress(1.0, 6.0)
	UI.fade_out(1.2)
	UI.show_note("PERDA DE CONSCIÊNCIA", "Você acorda no chão, com o traje recomposto e o capacete coberto de condensação. Algo trocou o seu filtro.")
	Director.after(1.4, func() -> void:
		global_position = Director.safe_spawn()
		UI.fade_in(1.6))


func _update_ray() -> void:
	if not controllado:
		return
	ray.force_raycast_update()
	var found: Interactable = null
	if ray.is_colliding():
		var col := ray.get_collider()
		if col is Interactable:
			found = col
		elif col is Node and col.get_parent() is Interactable:
			found = col.get_parent()
	if found != null and not found.prompt().is_empty():
		_target_inter = found
		UI.show_prompt(found.prompt())
		var look_dir := -camera.global_transform.basis.z
		_on_look(found, look_dir)
	else:
		_target_inter = null
		UI.hide_prompt()


func _on_look(target: Interactable, look_dir: Vector3) -> void:
	_look_point = target.global_position
	if not _has_looked:
		_has_looked = true
		target.looked_at()
		Director.on_look(target, look_dir)


func _try_interact() -> void:
	if _target_inter == null:
		AudioMan.play_2d("deny", -20.0, 1.4, "Interface")
		return
	var t := _target_inter
	if t.use(self):
		AudioMan.play_2d("click", -14.0, 1.0, "Interface")
		interacted.emit(t)
		# o mesmo [E] que abre um painel não pode chegar ao painel recém-criado
		get_viewport().set_input_as_handled()


func _update_breath(delta: float) -> void:
	_breath_t += delta
	if _breath_t > 4.0:
		_breath_t = 0.0
		var v := -26.0 + (1.0 - GameState.o2) * 10.0 + stress * 8.0
		AudioMan.play_2d("breath", v, randf_range(0.96, 1.05))


func set_sector(sector: String, display := "") -> void:
	if sector == _sector:
		return
	_sector = sector
	sector_changed.emit(sector)
	if display != "":
		UI.show_sector(display)


func head_position() -> Vector3:
	return camera.global_position if camera != null else global_position


func look_dir() -> Vector3:
	return -camera.global_transform.basis.z if camera != null else Vector3.FORWARD
