class_name ChoicePanel
extends Control

## evita que o mesmo [E]/[ESC] que abre o painel o feche no mesmo quadro
var _armed := false
## Painel de decisão. As escolhas mexem em duas variáveis invisíveis:
## a confiança do oceano e a ressonância do fenômeno.

var decision_id := ""
var decision: Dictionary = {}
var _buttons: Array[Button] = []


func setup(id: String, d: Dictionary) -> void:
	decision_id = id
	decision = d


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.82)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(760, 0)
	panel.position = Vector2(-380, -200)
	panel.add_theme_stylebox_override("panel", UIStyle.panel(Color(0.03, 0.035, 0.045, 0.97), Color(0.45, 0.62, 0.70, 0.7)))
	add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	panel.add_child(v)
	v.add_child(UIStyle.make_label("▌ DECISÃO", 14, Color(0.6, 0.85, 0.95)))
	v.add_child(UIStyle.divider())
	var trig := UIStyle.make_label(String(decision.get("trigger", "")), 17, UIStyle.TEXT)
	trig.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	trig.custom_minimum_size = Vector2(700, 0)
	v.add_child(trig)
	v.add_child(UIStyle.divider())
	var opts: Array = decision.get("options", [])
	for i in opts.size():
		var o: Dictionary = opts[i]
		var b := UIStyle.make_button("[%d] %s" % [i + 1, String(o.get("label", "?"))], 16)
		b.custom_minimum_size = Vector2(700, 0)
		b.pressed.connect(_choose.bind(String(o.get("id", ""))))
		v.add_child(b)
		var det := UIStyle.make_label("      " + String(o.get("detail", "")), 12, UIStyle.TEXT_DIM)
		det.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		det.custom_minimum_size = Vector2(690, 0)
		v.add_child(det)
		_buttons.append(b)
	AudioMan.play_2d("blip_low" if false else "blip", -10.0, 0.9, "Interface")
	Director.on_decision_open(decision_id)
	_arm()


func _choose(id: String) -> void:
	GameState.decide(decision_id, id)
	AudioMan.play_2d("beep_ok", -10.0, 1.0, "Interface")
	UI.close_panel()


func _unhandled_input(event: InputEvent) -> void:
	if not _armed:
		return
	if event is InputEventKey and event.is_pressed():
		var k := (event as InputEventKey).keycode
		if k >= KEY_1 and k <= KEY_9:
			var i := k - KEY_1
			var opts: Array = decision.get("options", [])
			if i < opts.size():
				_choose(String(opts[i].get("id", "")))

func _arm() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	_armed = true
