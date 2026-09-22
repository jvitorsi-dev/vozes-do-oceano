class_name EndingSequence
extends Control
## Desfechos. Quatro variações, decididas pela relação construída com o
## oceano ao longo da estação — e nenhuma delas explica o fenômeno.

var ending_id := "a"
var _label: RichTextLabel
var _full := ""
var _target := ""
var _t := 0.0
var _phase := 0
var _btn: Button


func setup(id: String) -> void:
	ending_id = id


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var bg := ColorRect.new()
	bg.color = Color(0.004, 0.010, 0.016, 1.0)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	_label = UIStyle.make_rich("", 18, Color(0.78, 0.88, 0.92))
	_label.position = Vector2(150, 120)
	_label.custom_minimum_size = Vector2(1120, 700)
	_label.add_theme_constant_override("line_separation", 12)
	add_child(_label)
	var body: Array = _texts().get(ending_id, _texts()["b"])
	_target = "\n".join(body)
	AudioMan.stop_all_music()
	AudioMan.set_layer("sub", 0.28)
	AudioMan.set_layer("water", 0.35)
	AudioMan.theme_ocean(0.6)
	if AudioMan.has_voice("sal_01") and ending_id == "b":
		pass
	UI.blocked = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _process(delta: float) -> void:
	_t += delta
	if _phase < 2 and _full.length() < _target.length():
		_full = _target.substr(0, int(_t * 46.0))
		_label.text = _full
	elif _phase == 0:
		_phase = 1
		Director.after(2.0, func() -> void:
			_phase = 2
			_show_button())
	if _phase == 2:
		_label.text = _target + "\n\n[i]VOZES DO OCEANO[/i]"
	if _btn != null:
		_btn.modulate.a = 0.55 + 0.45 * (0.5 + 0.5 * sin(_t * 1.6))


func _show_button() -> void:
	_btn = UIStyle.make_button("ENCERRAR EXPEDIÇÃO", 17)
	_btn.custom_minimum_size = Vector2(360, 46)
	_btn.position = Vector2(150, 640)
	_btn.pressed.connect(func() -> void:
		GameState.save_game()
		Director.return_to_menu())
	add_child(_btn)


func _texts() -> Dictionary:
	return {
		"a": [
			"FINAL — «CHAMADO»",
			"",
			"Você abriu todos os canais e falou com ele pelo tempo que tinha.",
			"Contou seu nome, seu medo, o nome de quem você perdeu.",
			"O mar ouviu. Não respondeu nada que você pudesse entender —",
			"mas, por 41 segundos, a superfície de ÍRIO ficou completamente lisa,",
			"como uma tela esperando.",
			"",
			"Depois disso, começou a ensaiar.",
		],
		"b": [
			"FINAL — «SILÊNCIO»",
			"",
			"Você não respondeu a nenhuma das vozes.",
			"Desligou o Protocolo Espelho, fechou os olhos para a janela sul",
			"e subiu sozinho para a órbita alta.",
			"",
			"Na descida final, o gravador de bordo registrou um som",
			"que ninguém conseguiu classificar: uma respiração",
			"no canal de voz, no ritmo exato da sua.",
		],
		"c": [
			"FINAL — «PARTIDA»",
			"",
			"Você virou as costas para ÍRIO.",
			"",
			"Os instrumentos registram, na manobra de escape, algo prendendo-se",
			"ao casco por 41 segundos: massa, temperatura e forma de um corpo humano.",
			"",
			"Depois, nada.",
			"",
			"A estação continua em órbita. Ela vai continuar esperando.",
			"Sempre haverá uma próxima cápsula — e alguém, dentro dela,",
			"que trouxe memórias demais.",
		],
		"d": [
			"FINAL — «REPETIÇÃO NOVA»",
			"",
			"Você entregou ao oceano um pensamento que ele ainda não tinha:",
			"não o que a tripulação lembrava, mas o que eles poderiam ter sido.",
			"",
			"ÍRIO aceitou. E fez a única coisa que sabe fazer: começou a ensaiar.",
			"",
			"Nas câmeras, Argos-4 aparece cheia de gente outra vez.",
			"Nas gravações, há risadas que nunca aconteceram.",
			"E alguém — que usa o seu rosto — está abrindo a escotilha do hangar",
			"para receber uma cápsula nova.",
		],
	}
