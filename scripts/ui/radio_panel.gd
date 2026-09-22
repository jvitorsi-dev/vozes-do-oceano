class_name RadioPanel
extends Control

## evita que o mesmo [E]/[ESC] que abre o painel o feche no mesmo quadro
var _armed := false
## Transceptor de bordo. Cada sinal tem frequência, ruído e uma voz —
## algumas vozes são da Terra, outras não têm origem registrada.

const VOICE_MAP := {
	"terra_1": "",
	"terra_2": "",
	"sal_1": "sal_01",
	"sal_2": "sal_02",
	"voz_extra": "voz_extra",
	"nadia_1": "nadia_01",
	"tomas_1": "tomas_01",
	"radio_1": "sal_02",
}

var signals: Array = []
var idx := 0
var _text: RichTextLabel
var _freq: Label
var _who: Label
var _wave: Control
var _list: VBoxContainer
var _t := 0.0
var _static_player: AudioStreamPlayer


func setup(sigs: Array) -> void:
	signals = sigs.duplicate()


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.78)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(880, 560)
	panel.position = Vector2(-440, -280)
	panel.add_theme_stylebox_override("panel", UIStyle.panel(Color(0.035, 0.028, 0.016, 0.97), Color(0.5, 0.4, 0.16, 0.75)))
	add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	panel.add_child(v)

	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 10)
	v.add_child(top)
	top.add_child(UIStyle.make_label("▌ TRANSCEPTOR ARGOS-4", 16, Color(0.95, 0.78, 0.42)))
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(sp)
	_freq = UIStyle.make_label("", 15, Color(0.95, 0.68, 0.3))
	top.add_child(_freq)
	v.add_child(UIStyle.divider())

	var mid := HBoxContainer.new()
	mid.add_theme_constant_override("separation", 12)
	mid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(mid)

	_list = VBoxContainer.new()
	_list.custom_minimum_size = Vector2(230, 0)
	_list.add_theme_constant_override("separation", 3)
	mid.add_child(_list)

	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 8)
	mid.add_child(right)

	_wave = Control.new()
	_wave.custom_minimum_size = Vector2(0, 90)
	_wave.draw.connect(_draw_wave)
	right.add_child(_wave)

	_who = UIStyle.make_label("", 14, Color(0.95, 0.72, 0.35))
	right.add_child(_who)
	_text = UIStyle.make_rich("", 15, Color(0.92, 0.86, 0.72))
	_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_child(_text)

	v.add_child(UIStyle.divider())
	v.add_child(UIStyle.make_label("[E] sintonizar    •    [← →] frequências    •    [ESC] sair", 12, UIStyle.TEXT_DIM))

	_build_list()
	_tune(0)
	_arm()


func _build_list() -> void:
	for c: Node in _list.get_children():
		c.queue_free()
	for i in signals.size():
		var s: Dictionary = Content.signals_data.get(String(signals[i]), {})
		var b := UIStyle.make_button(String(s.get("freq", signals[i])), 13)
		b.custom_minimum_size = Vector2(230, 32)
		b.pressed.connect(_tune.bind(i))
		_list.add_child(b)


func _tune(i: int) -> void:
	if signals.is_empty():
		return
	idx = wrapi(i, 0, signals.size())
	var id := String(signals[idx])
	var s: Dictionary = Content.signals_data.get(id, {})
	if _static_player != null and _static_player.playing:
		_static_player.stop()
	AudioMan.play_2d("static", -12.0, 1.0, "Radio")
	_static_player = AudioMan.play_2d("static", -20.0, 1.0, "Radio")
	_freq.text = String(s.get("freq", "—"))
	_who.text = String(s.get("who", ""))
	_text.text = "[wave]" + String(s.get("text", ""))
	# voz: se houver gravação, ela é reproduzida no barramento de rádio
	var key := String(VOICE_MAP.get(id, ""))
	if key != "":
		UI.play_voice_now(key, null, true)
		GameState.set_flag("ouviu_" + id)
	if id.begins_with("voz") or id == "sal_1":
		Director.on_signal_heard(id)


func _draw_wave() -> void:
	var w := _wave.size.x
	var h := _wave.size.y
	var mid := h * 0.5
	_wave.draw_line(Vector2(0, mid), Vector2(w, mid), Color(0.4, 0.32, 0.12, 0.6), 1.0)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(_t * 30.0) * 7919
	var pts := PackedVector2Array()
	for x in range(0, int(w), 3):
		var f := float(x) / maxf(w, 1.0)
		var carrier := sin(f * 120.0 + _t * 9.0) * 0.5 + sin(f * 43.0 - _t * 4.0) * 0.5
		var noise := rng.randf_range(-0.35, 0.35)
		var env := 0.35 + 0.65 * absf(sin(f * 6.0 + _t * 0.7))
		pts.append(Vector2(f * w, mid + (carrier * 0.6 + noise) * mid * 0.85 * env))
	_wave.draw_polyline(pts, Color(1.0, 0.72, 0.3), 1.4)


func _process(delta: float) -> void:
	_t += delta
	_wave.queue_redraw()


func _exit_tree() -> void:
	if _static_player != null:
		_static_player.stop()


func _unhandled_input(event: InputEvent) -> void:
	if not _armed:
		return
	if event.is_action_pressed("interact"):
		_tune(idx + 1)
		get_viewport().set_input_as_handled()
	if event is InputEventKey and event.is_pressed():
		var k := (event as InputEventKey).keycode
		if k == KEY_RIGHT or k == KEY_D:
			_tune(idx + 1)
		elif k == KEY_LEFT or k == KEY_A:
			_tune(idx - 1)

func _arm() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	_armed = true
