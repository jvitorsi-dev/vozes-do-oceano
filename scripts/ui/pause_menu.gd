class_name PauseMenu
extends Control

## evita que o mesmo [E]/[ESC] que abre o painel o feche no mesmo quadro
var _armed := false
## Menu de pausa + diário de bordo. É aqui que o jogador relê o que
## descobriu — e percebe que alguns registros não estão mais iguais.

var journal_mode := false
var _content: VBoxContainer
var _tab := 0
var _tabs: HBoxContainer
var _slider_sens: HSlider
var _slider_fov: HSlider
var _slider_music: HSlider
var _slider_sfx: HSlider


func setup(is_journal: bool) -> void:
	journal_mode = is_journal
	_tab = 1 if is_journal else 0


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.72)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(940, 620)
	panel.position = Vector2(-470, -310)
	panel.add_theme_stylebox_override("panel", UIStyle.panel(Color(0.022, 0.028, 0.035, 0.97), UIStyle.LINE_DIM))
	add_child(panel)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 8)
	panel.add_child(root)

	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 10)
	root.add_child(top)
	top.add_child(UIStyle.make_label("▌ ARGOS-4 // TERMINAL PESSOAL K-9", 16, UIStyle.TEXT))
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(sp)
	var stat := UIStyle.make_label("ECO DO MAR: %d/10    •    %s" % [GameState.resonance, GameState.clock_string()], 13, Color(0.55, 0.75, 0.8))
	top.add_child(stat)
	root.add_child(UIStyle.divider())

	_tabs = HBoxContainer.new()
	_tabs.add_theme_constant_override("separation", 6)
	root.add_child(_tabs)
	var names := ["SISTEMA", "DIÁRIO", "REGISTROS", "CONTROLES"]
	for i in names.size():
		var b := UIStyle.make_button(names[i], 14)
		b.custom_minimum_size = Vector2(150, 34)
		b.pressed.connect(_set_tab.bind(i))
		_tabs.add_child(b)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(scroll)
	_content = VBoxContainer.new()
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.add_theme_constant_override("separation", 10)
	scroll.add_child(_content)

	root.add_child(UIStyle.divider())
	root.add_child(UIStyle.make_label("[ESC] continuar a exploração    •    [TAB] diário", 12, UIStyle.TEXT_DIM))
	_set_tab(_tab)
	_arm()


func _set_tab(i: int) -> void:
	_tab = i
	for c: Node in _content.get_children():
		c.queue_free()
	match i:
		0: _build_system()
		1: _build_journal()
		2: _build_records()
		3: _build_controls()


func _build_system() -> void:
	var v := _content
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 24)
	grid.add_theme_constant_override("v_separation", 8)
	v.add_child(grid)

	var p: Player = _player()
	grid.add_child(UIStyle.make_label("Sensibilidade do mouse", 14, UIStyle.TEXT))
	_slider_sens = _slider(0.0008, 0.0060, p.mouse_sens if p != null else 0.0026)
	_slider_sens.value_changed.connect(func(x: float) -> void:
		if _player() != null:
			_player().mouse_sens = x
		GameState.set_mouse_sens(x))

	grid.add_child(UIStyle.make_label("Campo de visão", 14, UIStyle.TEXT))
	_slider_fov = _slider(60.0, 100.0, p.fov if p != null else 78.0)
	_slider_fov.value_changed.connect(func(x: float) -> void:
		if _player() != null:
			_player().fov = x
			_player().camera.fov = x)
	grid.add_child(_slider_fov)

	grid.add_child(UIStyle.make_label("Volume — trilha", 14, UIStyle.TEXT))
	_slider_music = _slider(-30.0, 6.0, AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music")))
	_slider_music.value_changed.connect(func(x: float) -> void:
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), x))
	grid.add_child(_slider_music)

	grid.add_child(UIStyle.make_label("Volume — efeitos e vozes", 14, UIStyle.TEXT))
	_slider_sfx = _slider(-30.0, 6.0, AudioServer.get_bus_volume_db(AudioServer.get_bus_index("SFX")))
	_slider_sfx.value_changed.connect(func(x: float) -> void:
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), x)
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Voice"), x)
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Radio"), x))
	grid.add_child(_slider_sfx)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	v.add_child(row)
	var bs := UIStyle.make_button("SALVAR PROGRESSO", 14)
	bs.custom_minimum_size = Vector2(220, 40)
	bs.pressed.connect(func() -> void:
		GameState.save_game()
		UI.show_note("PROGRESSO SALVO", "O terminal registrou sua posição e suas descobertas."))
	row.add_child(bs)
	var bl := UIStyle.make_button("CARREGAR", 14)
	bl.custom_minimum_size = Vector2(160, 40)
	bl.pressed.connect(func() -> void:
		if GameState.load_game():
			UI.show_note("MEMÓRIA RESTAURADA", "O que estava registrado voltou. O que não estava, não.")
			Director.resync())
	row.add_child(bl)
	var bq := UIStyle.make_button("ABANDONAR A ESTAÇÃO", 14)
	bq.custom_minimum_size = Vector2(260, 40)
	bq.pressed.connect(func() -> void:
		UI.close_panel()
		Director.return_to_menu())
	row.add_child(bq)

	var info := UIStyle.make_label("KEPLER-9 • autonomia: %s • oxigênio: %d%% • bateria: %d%%" % [
		"%.1f dias" % maxf(0.0, 9.0 - GameState.elapsed_real / 540.0),
		int(GameState.o2 * 100.0), int(GameState.battery * 100.0)], 13, UIStyle.TEXT_DIM)
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(info)


func _slider(mn: float, mx: float, val: float) -> HSlider:
	var s := HSlider.new()
	s.min_value = mn
	s.max_value = mx
	s.step = (mx - mn) / 200.0
	s.value = val
	s.custom_minimum_size = Vector2(320, 24)
	return s


func _build_journal() -> void:
	var v := _content
	v.add_child(UIStyle.make_label("DIÁRIO DE BORDO — %d registros" % GameState.entries_unlocked.size(), 15, Color(0.6, 0.85, 0.9)))
	v.add_child(UIStyle.divider())
	if GameState.entries_unlocked.is_empty():
		v.add_child(UIStyle.make_label("Nada registrado ainda. Leia terminais, papéis e fitas para acumular compreensão.", 14, UIStyle.TEXT_DIM))
		return
	for id: String in GameState.entries_unlocked.keys():
		var e: Dictionary = Content.get_entry(id)
		var box := PanelContainer.new()
		box.add_theme_stylebox_override("panel", UIStyle.panel(Color(0.035, 0.045, 0.05, 0.9), UIStyle.LINE_DIM))
		var bv := VBoxContainer.new()
		bv.add_theme_constant_override("separation", 4)
		box.add_child(bv)
		bv.add_child(UIStyle.make_label("▌ " + String(e.get("title", id)), 15, Color(0.75, 0.92, 0.85)))
		var body := UIStyle.make_label(String(e.get("body", "")), 14, UIStyle.TEXT)
		body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		body.custom_minimum_size = Vector2(860, 0)
		bv.add_child(body)
		v.add_child(box)
	# notas rápidas
	if not GameState.journal.is_empty():
		v.add_child(UIStyle.divider())
		v.add_child(UIStyle.make_label("NOTAS DE CAMPO", 14, Color(0.75, 0.85, 0.9)))
		for n: Dictionary in GameState.journal:
			var l := UIStyle.make_label("%s  —  %s: %s" % [String(n.get("t", "")), String(n.get("title", "")), String(n.get("body", ""))], 13, UIStyle.TEXT_DIM)
			l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			l.custom_minimum_size = Vector2(860, 0)
			v.add_child(l)


func _build_records() -> void:
	var v := _content
	v.add_child(UIStyle.make_label("REGISTROS LIDOS — %d" % GameState.docs_read.size(), 15, Color(0.75, 0.85, 0.95)))
	v.add_child(UIStyle.divider())
	for id: String in GameState.docs_read.keys():
		var d: Dictionary = Content.get_doc(id)
		var l := UIStyle.make_label("• %s  [%s]" % [String(d.get("title", id)), String(d.get("kind", "?"))], 14, UIStyle.TEXT)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size = Vector2(860, 0)
		v.add_child(l)
	v.add_child(UIStyle.divider())
	v.add_child(UIStyle.make_label("DECISÕES REGISTRADAS", 14, Color(0.9, 0.8, 0.6)))
	for id: String in GameState.decisions.keys():
		v.add_child(UIStyle.make_label("• %s → %s" % [id, String(GameState.decisions[id])], 13, UIStyle.TEXT_DIM))
	v.add_child(UIStyle.divider())
	v.add_child(UIStyle.make_label("ANOMALIAS TESTEMUNHADAS — %d" % GameState.anomalies.size(), 14, Color(0.9, 0.7, 0.6)))
	for id: String in GameState.anomalies.keys():
		var a: Dictionary = Content.get_anomaly(id)
		var l := UIStyle.make_label("• %s" % String(a.get("hint", id)), 13, UIStyle.TEXT_DIM)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size = Vector2(860, 0)
		v.add_child(l)


func _build_controls() -> void:
	var v := _content
	var lines := [
		"W A S D — andar",
		"SHIFT — correr",
		"CTRL — agachar",
		"E — interagir / ler / confirmar",
		"F — lanterna de capacete",
		"TAB — diário de bordo",
		"ESC — pausa e opções",
		"← → — alternar entre registros e canais",
		"",
		"O oxigênio só cai em setores despressurizados.",
		"A lanterna é a sua única defesa — e ela não mata nada.",
		"Salve nos terminais para não perder descobertas.",
	]
	for l in lines:
		v.add_child(UIStyle.make_label(l, 14, UIStyle.TEXT))


func _player() -> Player:
	for n in get_tree().get_nodes_in_group("player"):
		if n is Player:
			return n
	return null

func _arm() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	_armed = true
