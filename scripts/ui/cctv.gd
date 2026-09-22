class_name CCTVScreen
extends Control

## evita que o mesmo [E]/[ESC] que abre o painel o feche no mesmo quadro
var _armed := false
## Terminal de vigilância. As imagens são o mundo de verdade, renderizado
## por um SubViewport em 12 quadros por segundo — o que aparece na tela
## está mesmo acontecendo na estação.

const FEED_SHADER := preload("res://assets/shaders/cctv_feed.gdshader")

var viewport: SubViewport
var cam: Camera3D
var feed_rect: TextureRect
var feed_mat: ShaderMaterial
var channel := 0
var ids: Array[String] = []
var _list: VBoxContainer
var _status: Label
var _rec_dot: ColorRect
var _update_accum := 0.0
var _glitch := 0.0
var _glitch_t := 0.0
var _noise_offset := 0.0
var _missing := false


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.8)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(1040, 620)
	panel.position = Vector2(-520, -310)
	panel.add_theme_stylebox_override("panel", UIStyle.panel(Color(0.012, 0.02, 0.022, 0.97), Color(0.25, 0.45, 0.42, 0.7)))
	add_child(panel)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	panel.add_child(v)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 10)
	v.add_child(top)
	top.add_child(UIStyle.make_label("▌ SISTEMA DE VIGILÂNCIA — ARGOS-4", 16, Color(0.62, 0.95, 0.78)))
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(sp)
	_rec_dot = ColorRect.new()
	_rec_dot.color = Color(0.95, 0.25, 0.2, 0.9)
	_rec_dot.custom_minimum_size = Vector2(10, 10)
	_rec_dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	top.add_child(_rec_dot)
	top.add_child(UIStyle.make_label("REC", 13, Color(0.95, 0.4, 0.35)))
	v.add_child(UIStyle.divider())

	var mid := HBoxContainer.new()
	mid.add_theme_constant_override("separation", 12)
	mid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(mid)

	_list = VBoxContainer.new()
	_list.custom_minimum_size = Vector2(250, 0)
	_list.add_theme_constant_override("separation", 3)
	mid.add_child(_list)

	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 6)
	mid.add_child(right)

	# SubViewport com a câmera de vigilância
	viewport = SubViewport.new()
	viewport.size = Vector2i(640, 360)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.world_3d = get_viewport().world_3d
	viewport.transparent_bg = false
	viewport.msaa_3d = Viewport.MSAA_DISABLED
	add_child(viewport)
	cam = Camera3D.new()
	cam.fov = 62.0
	cam.near = 0.08
	cam.far = 4000.0
	viewport.add_child(cam)

	feed_mat = ShaderMaterial.new()
	feed_mat.shader = FEED_SHADER
	feed_mat.set_shader_parameter("feed", viewport.get_texture())
	feed_rect = TextureRect.new()
	feed_rect.material = feed_mat
	feed_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	feed_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	feed_rect.custom_minimum_size = Vector2(0, 380)
	feed_rect.size_flags_vertical = Control.SIZE_EXPAND_FILL
	feed_rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	right.add_child(feed_rect)

	_status = UIStyle.make_label("", 13, Color(0.65, 0.9, 0.8))
	right.add_child(_status)
	v.add_child(UIStyle.divider())
	v.add_child(UIStyle.make_label("[← →] trocar canal    •    [E] / [ESC] sair    •    canais com falha mostram o último quadro conhecido", 12, UIStyle.TEXT_DIM))

	_refresh_channels()
	_select(0)
	# ruído de abertura
	AudioMan.play_2d("static", -10.0, 1.0, "Radio")
	_arm()


func _refresh_channels() -> void:
	for c: Node in _list.get_children():
		c.queue_free()
	ids = CamGrid.ids()
	for i in ids.size():
		var info := CamGrid.get_cam(ids[i])
		var broken: bool = bool(info.get("broken", false))
		var tag := "  ⚠" if broken else ""
		var b := UIStyle.make_button("%s%s" % [String(info.get("display", ids[i])), tag], 14)
		b.custom_minimum_size = Vector2(250, 34)
		b.pressed.connect(_select.bind(i))
		_list.add_child(b)
		if bool(info.get("broken", false)):
			b.add_theme_color_override("font_color", Color(0.85, 0.45, 0.35))


func _select(i: int) -> void:
	if ids.is_empty():
		return
	channel = wrapi(i, 0, ids.size())
	var id := ids[channel]
	var info := CamGrid.get_cam(id)
	_missing = bool(info.get("broken", false))
	var pos: Vector3 = info.get("pos", Vector3.ZERO)
	var yaw: float = float(info.get("yaw", 0.0))
	cam.global_position = pos
	cam.global_rotation = Vector3(-0.13, yaw, 0.0)
	var glitch_base: float = 1.0 if _missing else float(info.get("glitch", 0.0))
	feed_mat.set_shader_parameter("glitch", glitch_base)
	_status.text = "CANAL %02d — %s // %s" % [channel + 1, String(info.get("display", id)), String(info.get("sector", ""))]
	if _missing:
		_status.text += "   [SEM SINAL — último quadro conhecido]"
	AudioMan.play_2d("blip", -14.0, 1.0, "Interface")


func _process(delta: float) -> void:
	# 14 Hz: dá o "engasgo" analógico
	_update_accum += delta
	if _update_accum >= 1.0 / 14.0:
		_update_accum = 0.0
		var info := CamGrid.get_cam(ids[channel]) if not ids.is_empty() else {}
		var info_map: Dictionary = info if info != null else {}
		var pos: Vector3 = info_map.get("pos", Vector3.ZERO)
		cam.global_position = pos + Vector3(randf_range(-0.01, 0.01), randf_range(-0.008, 0.008), 0.0)
		rec_dot_blink()
	if _glitch > 0.0:
		_glitch_t -= delta
		if _glitch_t <= 0.0:
			_glitch = maxf(0.0, _glitch - 0.2)
			_glitch_t = randf_range(0.1, 0.5)
		var base := 1.0 if _missing else float(CamGrid.get_cam(ids[channel]).get("glitch", 0.0)) if not ids.is_empty() else 0.0
		feed_mat.set_shader_parameter("glitch", clampf(base + _glitch, 0.0, 1.5))
	if _missing:
		feed_mat.set_shader_parameter("noise_amount", 0.5)
	else:
		feed_mat.set_shader_parameter("noise_amount", 0.12)


func rec_dot_blink() -> void:
	_rec_dot.color.a = 0.25 + 0.75 * (1.0 if fmod(Time.get_ticks_msec() / 1000.0, 1.6) < 1.1 else 0.0)


func glitch_burst(amount := 0.9, seconds := 2.0) -> void:
	_glitch = amount
	_glitch_t = seconds


func _exit_tree() -> void:
	if viewport != null:
		viewport.queue_free()


func _unhandled_input(event: InputEvent) -> void:
	if not _armed:
		return
	if event.is_action_pressed("interact"):
		UI.close_panel()
		get_viewport().set_input_as_handled()
	if event is InputEventKey and event.is_pressed():
		var k := (event as InputEventKey).keycode
		if k == KEY_RIGHT or k == KEY_D:
			_select(channel + 1)
		elif k == KEY_LEFT or k == KEY_A:
			_select(channel - 1)
		elif k == KEY_G:
			AudioMan.play_2d("static", -8.0, 1.0, "Radio")
			glitch_burst(1.2, 3.0)

func _arm() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	_armed = true
