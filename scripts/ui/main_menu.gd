class_name MainMenu
extends Control
## Tela inicial, exibida sobre a estação em panejamento cinematográfico.

signal new_game()
signal continue_game()

var _t := 0.0
var _title: Label
var _sub: Label
var _buttons: VBoxContainer
var _blink: ColorRect


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0.0, 0.008, 0.014, 0.62)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var grad := ColorRect.new()
	grad.color = Color(0, 0, 0, 0.55)
	grad.set_anchors_preset(Control.PRESET_FULL_RECT)
	grad.size = Vector2(900, 2000)
	grad.position = Vector2(0, 0)
	grad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(grad)

	var v := VBoxContainer.new()
	v.position = Vector2(90, 120)
	v.add_theme_constant_override("separation", 6)
	add_child(v)

	var tag := UIStyle.make_label("ESTAÇÃO ARGOS-4 // ÓRBITA DE ÍRIO // ANO 14 DA PESQUISA", 13, Color(0.45, 0.68, 0.75))
	v.add_child(tag)
	_title = UIStyle.make_label("VOZES DO OCEANO", 62, Color(0.86, 0.93, 0.96))
	v.add_child(_title)
	var line := ColorRect.new()
	line.color = Color(0.35, 0.55, 0.62, 0.8)
	line.custom_minimum_size = Vector2(620, 1)
	v.add_child(line)
	_sub = UIStyle.make_label("Uma história sobre a coisa que o mar aprendeu a fazer com o que existe dentro de nós.", 15, Color(0.6, 0.72, 0.78))
	_sub.custom_minimum_size = Vector2(700, 0)
	_sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(_sub)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 40)
	v.add_child(spacer)

	_buttons = VBoxContainer.new()
	_buttons.add_theme_constant_override("separation", 8)
	v.add_child(_buttons)

	var bn := UIStyle.make_button("NOVA EXPEDIÇÃO", 18)
	bn.custom_minimum_size = Vector2(340, 46)
	bn.pressed.connect(func() -> void:
		new_game.emit())
	_buttons.add_child(bn)

	if GameState.has_save():
		var bc := UIStyle.make_button("CONTINUAR", 18)
		bc.custom_minimum_size = Vector2(340, 46)
		bc.pressed.connect(func() -> void:
			GameState.load_game()
			continue_game.emit())
		_buttons.add_child(bc)

	var bl := UIStyle.make_button("COMO JOGAR", 18)
	bl.custom_minimum_size = Vector2(340, 46)
	bl.pressed.connect(func() -> void:
		UI.show_note("COMO JOGAR", "Explore em primeira pessoa. Interaja com [E]. Use [F] para a lanterna, [TAB] para o diário e [ESC] para pausa. Não há combate: o que existe aqui responde ao que você faz — e às vezes ao que você pensa."))
	_buttons.add_child(bl)

	var about := UIStyle.make_label("Inspirado nos temas de «Solaris», de Stanisław Lem.  Nada neste jogo será explicado até o fim.", 12, Color(0.42, 0.55, 0.6))
	about.custom_minimum_size = Vector2(700, 0)
	about.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(about)

	var spacer2 := Control.new()
	spacer2.custom_minimum_size = Vector2(0, 10)
	v.add_child(spacer2)

	_blink = ColorRect.new()
	_blink.color = Color(0.5, 0.9, 0.8, 0.0)
	_blink.custom_minimum_size = Vector2(10, 10)
	add_child(_blink)


func _process(delta: float) -> void:
	_t += delta
	_title.modulate = Color(1, 1, 1, 0.92 + 0.08 * sin(_t * 0.8))
	_sub.modulate.a = 0.55 + 0.45 * (0.5 + 0.5 * sin(_t * 0.35))
	_blink.color.a = 0.0
