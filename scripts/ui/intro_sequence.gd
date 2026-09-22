class_name IntroSequence
extends Control
## Abertura: a chegada. Sem cutscene em vídeo — texto sobre a janela,
## como se o computador de bordo estivesse imprimindo tudo para você.

var _label: RichTextLabel
var _lines: Array = [
	"KEPLER-9 — cápsula de recuperação monoplace",
	"órbita de ÍRIO // aproximação final a ARGOS-4",
	"",
	"Contato com a estação perdido há 47 dias.",
	"Nenhuma equipe enviada. Nenhuma equipe prevista.",
	"",
	"Motivo oficial: análise de risco.",
	"Motivo real: ninguém quis vir.",
	"",
	"> acoplamento manual autorizado",
	"> não há ninguém para receber você",
]
var _i := 0
var _t := 0.0
var _char_t := 0.0
var _full := ""
var _done := false


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var bg := ColorRect.new()
	bg.color = Color(0.0, 0.008, 0.012, 1.0)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	_label = UIStyle.make_rich("", 20, Color(0.62, 0.92, 0.78))
	_label.position = Vector2(140, 140)
	_label.custom_minimum_size = Vector2(1100, 600)
	_label.add_theme_constant_override("line_separation", 10)
	add_child(_label)
	AudioMan.set_layer("air", 0.10)
	AudioMan.set_layer("sub", 0.35)
	AudioMan.set_layer("whine", 0.35)
	UI.blocked = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _process(delta: float) -> void:
	_t += delta
	if _i < _lines.size():
		var target: String = String(_lines[_i])
		_char_t += delta * 42.0
		var n := int(_char_t)
		if n >= target.length():
			_full += target + "\n"
			_label.text = _full
			_i += 1
			_char_t = 0.0
			if target.begins_with(">"):
				AudioMan.play_2d("blip", -14.0, 1.0, "Interface")
			else:
				AudioMan.play_2d("click", -20.0, 1.0, "Interface")
		else:
			_label.text = _full + target.substr(0, n) + "▌"
	elif not _done:
		_done = true
		Director.after(2.2, _finish)


func _finish() -> void:
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 1.6)
	await tw.finished
	UI.blocked = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	GameState.set_flag("intro_done")
	Director.begin()
	queue_free()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") or event.is_action_pressed("pause"):
		if _i < _lines.size():
			while _i < _lines.size():
				_full += String(_lines[_i]) + "\n"
				_i += 1
			_label.text = _full
		elif not _done:
			_done = true
			_finish()
