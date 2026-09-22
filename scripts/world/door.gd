class_name Door
extends Node3D
## Porta deslizante industrial. Pode ser automática (abre ao aproximar),
## manual, trancada por cartão ou "emperrada" por fenômenos.

enum State { CLOSED, OPEN }

var door_id := "porta"
var display_name := "SETOR"
var along_x := true
var width := 1.7
var height := 2.15
var auto := true
var locked := false
var lock_reason := "TRAVADA"
var key_item := ""
var state: State = State.CLOSED
var powered := true
var silent := false

var _panel_a: Node3D
var _panel_b: Node3D
var _light: OmniLight3D
var _status: MeshInstance3D
var _status_mat: StandardMaterial3D
var _trigger: Area3D
var _inter: Interactable
var _tween: Tween
var _busy := false
var _player_near := false


func _build() -> void:
	var frame_mat := Mats.get_mat("metal")
	if along_x:
		_panel_a = _panel(Vector3(width * 0.5, height, 0.12), "A")
		_panel_b = _panel(Vector3(width * 0.5, height, 0.12), "B")
		_panel_a.position = Vector3(-width * 0.25, height * 0.5, 0)
		_panel_b.position = Vector3(width * 0.25, height * 0.5, 0)
	else:
		_panel_a = _panel(Vector3(0.12, height, width * 0.5), "A")
		_panel_b = _panel(Vector3(0.12, height, width * 0.5), "B")
		_panel_a.position = Vector3(0, height * 0.5, -width * 0.25)
		_panel_b.position = Vector3(0, height * 0.5, width * 0.25)

	# trilho superior
	G3D.box(self, Vector3(width + 0.3, 0.18, 0.36) if along_x else Vector3(0.36, 0.18, width + 0.3),
			Vector3(0, height + 0.09, 0), frame_mat, false, Vector3.ZERO, "trilho")

	# luz de status
	_status = MeshInstance3D.new()
	var sm := BoxMesh.new()
	sm.size = Vector3(0.1, 0.1, 0.06)
	_status.mesh = sm
	_status_mat = Mats.emissive(Color(0.9, 0.25, 0.15), 2.5)
	_status.material_override = _status_mat
	_status.position = Vector3(width * 0.5 + 0.22, 1.45, 0.2)
	if not along_x:
		_status.position = Vector3(0.2, 1.45, -width * 0.5 - 0.22)
	_status.rotation.y = 0.0 if along_x else PI * 0.5
	add_child(_status)

	_light = OmniLight3D.new()
	_light.position = Vector3(0, height + 0.4, 0)
	_light.light_energy = 0.25
	_light.light_color = Color(1.0, 0.35, 0.25)
	_light.omni_range = 4.0
	_light.shadow_enabled = false
	add_child(_light)

	# gatilho de aproximação
	_trigger = Area3D.new()
	_trigger.collision_layer = 4
	_trigger.collision_mask = 1
	_trigger.monitoring = true
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(width + 2.6, 2.4, 3.0) if along_x else Vector3(3.0, 2.4, width + 2.6)
	cs.shape = shape
	cs.position = Vector3(0, 1.2, 0)
	_trigger.add_child(cs)
	add_child(_trigger)
	_trigger.body_entered.connect(_on_trigger.bind(true))
	_trigger.body_exited.connect(_on_trigger.bind(false))

	# ponto de interação (painel da porta)
	var sign_pos := Vector3(width * 0.5 + 0.35, 1.35, 0) if along_x else Vector3(0, 1.35, -width * 0.5 - 0.35)
	if not along_x:
		sign_pos = Vector3(-width * 0.5 - 0.35, 1.35, 0)
	_inter = Interactable.create("", Vector3(0.7, 1.2, 0.55), sign_pos)
	_inter.prompt_text = "Porta"
	_inter.data = {"prompt_fn": _prompt_text}
	_inter.on_use = _on_use
	add_child(_inter)

	G3D.label3d(self, display_name, Vector3(0, height + 0.42, 0.0) if along_x else Vector3(0.0, height + 0.42, 0),
		0.0, 0.005, Color(0.72, 0.80, 0.84))
	_apply_closed()
	_refresh_status()


func _panel(size: Vector3, tag: String) -> Node3D:
	var p := Node3D.new()
	p.name = "Painel" + tag
	add_child(p)
	var m := Mats.get_mat("metal")
	var body := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	body.mesh = bm
	body.material_override = m
	p.add_child(body)
	# reforço central + faixa de aviso
	var rib := MeshInstance3D.new()
	var rm := BoxMesh.new()
	rm.size = size * Vector3(1.02, 0.08, 1.3)
	rib.mesh = rm
	rib.material_override = Mats.get_mat("metal_rust")
	rib.position = Vector3(0, size.y * 0.1, 0)
	p.add_child(rib)
	var stripe := MeshInstance3D.new()
	var sm := BoxMesh.new()
	sm.size = size * Vector3(1.03, 0.12, 1.35)
	stripe.mesh = sm
	stripe.material_override = Mats.get_mat("hazard")
	stripe.position = Vector3(0, -size.y * 0.35, 0)
	p.add_child(stripe)
	var body_col := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = size
	cs.shape = bs
	body_col.add_child(cs)
	p.add_child(body_col)
	return p


func setup(id: String, name_txt: String, ax: bool, w: float, h: float, is_auto: bool,
		is_locked := false, reason := "TRAVADA", item := "") -> Door:
	door_id = id
	display_name = name_txt
	along_x = ax
	width = w
	height = h
	auto = is_auto
	locked = is_locked
	lock_reason = reason
	key_item = item
	_build()
	return self


func _prompt_text() -> String:
	if not powered:
		return "%s — SEM ENERGIA" % display_name
	if locked:
		if key_item != "" and GameState.has(key_item):
			return "[E] Destravar %s (cartão)" % display_name
		return "%s — %s" % [display_name, lock_reason]
	if state == State.OPEN:
		return "[E] Fechar %s" % display_name
	return "[E] Abrir %s" % display_name


func _on_use(_player: Node3D, _it: Interactable) -> void:
	if not powered:
		AudioMan.play_3d("deny", global_position)
		return
	if locked:
		if key_item != "" and GameState.has(key_item):
			locked = false
			AudioMan.play_3d("beep_ok", global_position)
			AudioMan.play_3d("clank", global_position)
			GameState.add_note("ACESSO LIBERADO", "%s destravada com %s." % [display_name, key_item])
			_refresh_status()
			set_open(true)
			return
		AudioMan.play_3d("deny", global_position)
		return
	if state == State.OPEN:
		set_open(false)
	else:
		set_open(true)


func _on_trigger(body: Node3D, entered: bool) -> void:
	if not body.is_in_group("player"):
		return
	_player_near = entered
	if auto and powered and not locked and not _busy:
		set_open(entered)


func set_open(open_now: bool, auto_silent := false) -> void:
	if _busy:
		return
	if (state == State.OPEN) == open_now:
		return
	state = State.OPEN if open_now else State.CLOSED
	_busy = true
	var target := width * 0.5 + 0.07
	var dir := 1.0 if open_now else -1.0
	var t := 1.0
	if auto_silent:
		t = 3.0
	if not silent:
		AudioMan.play_3d("door", global_position, -4.0, 1.0 if open_now else 0.85)
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	if along_x:
		_tween.tween_property(_panel_a, "position:x", -target - 0.7 if open_now else -width * 0.25, t)
		_tween.tween_property(_panel_b, "position:x", target + 0.7 if open_now else width * 0.25, t)
	else:
		_tween.tween_property(_panel_a, "position:z", -target - 0.7 if open_now else -width * 0.25, t)
		_tween.tween_property(_panel_b, "position:z", target + 0.7 if open_now else width * 0.25, t)
	_tween.chain().tween_callback(func() -> void:
		_busy = false
		_refresh_status())


func _apply_closed() -> void:
	# garante estado visual fechado ao montar
	state = State.CLOSED
	_busy = false


func _refresh_status() -> void:
	if _status_mat == null:
		return
	var col := Color(0.9, 0.25, 0.15)
	var energy := 2.5
	if not powered:
		col = Color(0.25, 0.05, 0.05)
		energy = 0.4
	elif locked:
		col = Color(1.0, 0.55, 0.12)
	elif state == State.OPEN:
		col = Color(0.35, 0.95, 0.55)
	_status_mat.emission = col
	_status_mat.albedo_color = col
	_status_mat.emission_energy_multiplier = energy
	if _light != null:
		_light.light_color = col
		_light.light_energy = 0.22 if powered else 0.06


func set_powered(p: bool) -> void:
	powered = p
	_refresh_status()
	if not p and state == State.OPEN:
		set_open(false, true)


func force_open() -> void:
	locked = false
	powered = true
	set_open(true, true)


func slam_list(pos: Vector3) -> void:
	AudioMan.play_3d("boom", pos, -6.0)
	set_open(false, true)
