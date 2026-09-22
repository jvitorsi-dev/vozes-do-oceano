class_name KeypadPanel
extends Control

## evita que o mesmo [E]/[ESC] que abre o painel o feche no mesmo quadro
var _armed := false
## Teclado numérico da estação — usado em cofres, travas e no reator.

var prompt := "CÓDIGO"
var code := "0000"
var on_ok: Callable = Callable()
var on_fail: Callable = Callable()
var typed := ""
var _display: Label
var _msg: Label


func setup(p: String, c: String, ok: Callable, fail: Callable) -> void:
	prompt = p
	code = c
	on_ok = ok
	on_fail = fail


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.8)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(380, 480)
	panel.position = Vector2(-190, -240)
	panel.add_theme_stylebox_override("panel", UIStyle.panel(Color(0.02, 0.03, 0.03, 0.97), Color(0.3, 0.55, 0.5, 0.7)))
	add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	panel.add_child(v)
	v.add_child(UIStyle.make_label("▌ " + prompt, 14, Color(0.6, 0.9, 0.8)))
	v.add_child(UIStyle.divider())
	_display = UIStyle.make_label("_ _ _ _", 30, Color(0.75, 0.95, 0.85))
	_display.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(_display)
	_msg = UIStyle.make_label("", 13, UIStyle.RED)
	_msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(_msg)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	v.add_child(grid)
	for i in 9:
		var b := UIStyle.make_button(str(i + 1), 20)
		b.custom_minimum_size = Vector2(100, 52)
		b.pressed.connect(_digit.bind(str(i + 1)))
		grid.add_child(b)
	var b0 := UIStyle.make_button("0", 20)
	b0.custom_minimum_size = Vector2(100, 52)
	b0.pressed.connect(_digit.bind("0"))
	grid.add_child(b0)
	var bc := UIStyle.make_button("LIMPAR", 14)
	bc.custom_minimum_size = Vector2(100, 52)
	bc.pressed.connect(func() -> void:
		typed = ""
		_update())
	grid.add_child(bc)
	var bok := UIStyle.make_button("OK", 16)
	bok.custom_minimum_size = Vector2(100, 52)
	bok.pressed.connect(_submit)
	grid.add_child(bok)
	v.add_child(UIStyle.divider())
	v.add_child(UIStyle.make_label("digite com o teclado ou clique    •    [ESC] sair", 11, UIStyle.TEXT_DIM))
	_update()
	_arm()


func _digit(d: String) -> void:
	if typed.length() >= 6:
		return
	typed += d
	AudioMan.play_2d("blip", -14.0, 1.0, "Interface")
	_update()


func _update() -> void:
	var s := ""
	for i in typed.length():
		s += typed[i] + " "
	while s.length() < 8:
		s += "_ "
	_display.text = s.strip_edges()
	_msg.text = ""


func _submit() -> void:
	if typed == code:
		AudioMan.play_2d("beep_ok", -8.0, 1.0, "Interface")
		_msg.text = "ACESSO CONCEDIDO"
		if on_ok.is_valid():
			on_ok.call()
		UI.close_panel()
	else:
		AudioMan.play_2d("deny", -8.0, 1.0, "Interface")
		_msg.text = "CÓDIGO INCORRETO"
		typed = ""
		_update()
		_msg.text = "CÓDIGO INCORRETO"
		if on_fail.is_valid():
			on_fail.call()


func _unhandled_input(event: InputEvent) -> void:
	if not _armed:
		return
	if event is InputEventKey and event.is_pressed():
		var k := (event as InputEventKey).keycode
		if k >= KEY_0 and k <= KEY_9:
			_digit(str(k - KEY_0))
		elif k >= KEY_KP_0 and k <= KEY_KP_9:
			_digit(str(k - KEY_KP_0))
		elif k == KEY_ENTER or k == KEY_KP_ENTER or k == KEY_E:
			_submit()
		elif k == KEY_BACKSPACE:
			typed = typed.substr(0, maxi(0, typed.length() - 1))
			_update()

func _arm() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	_armed = true
