extends CanvasLayer
## UI — HUD, legendas, avisos, painéis (documentos, CCTV, rádio, decisões)
## e sequências (intro, finais, menu). É também o "blocked": quando um painel
## está aberto, o jogador não se move e o mouse volta a aparecer.

signal panel_closed()
signal ui_ready()

const GRAIN := preload("res://assets/shaders/grain.gdshader")

var blocked := false
var stress := 0.0

var _hud: Control
var _crosshair: Control
var _prompt_box: PanelContainer
var _prompt_label: Label
var _objective_label: Label
var _objective_sub: Label
var _clock_label: Label
var _sector_label: Label
var _sector_t := 0.0
var _sub_box: PanelContainer
var _sub_who: Label
var _sub_text: Label
var _sub_t := 0.0
var _sub_queue: Array = []
var _toasts: VBoxContainer
var _fade: ColorRect
var _flash: ColorRect
var _grain: ColorRect
var _grain_mat: ShaderMaterial
var _hint: Label
var _hint_t := 0.0
var _vitals := {}
var _panel: Control = null
var _menu: Control = null
var _ending: Control = null

signal menu_start()
signal ending_done()


func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_hud()
	GameState.note_added.connect(func(title: String, body: String) -> void: show_note(title, body))
	GameState.objective_changed.connect(func(t: String) -> void: set_objective(t))
	GameState.o2_changed.connect(func(_v: float) -> void: pass)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	ui_ready.emit()


# ================================================================ CONSTRUÇÃO DO HUD
func _build_hud() -> void:
	_hud = Control.new()
	_hud.name = "HUD"
	_hud.set_anchors_preset(Control.PRESET_FULL_RECT)
	_hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_hud)

	# vinheta / grão
	_grain_mat = ShaderMaterial.new()
	_grain_mat.shader = GRAIN
	_grain = ColorRect.new()
	_grain.material = _grain_mat
	_grain.color = Color(1, 1, 1, 1)
	_grain.set_anchors_preset(Control.PRESET_FULL_RECT)
	_grain.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_grain)

	# crosshair
	_crosshair = Control.new()
	_crosshair.set_anchors_preset(Control.PRESET_CENTER)
	_crosshair.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var dot := ColorRect.new()
	dot.color = Color(0.85, 0.92, 0.95, 0.55)
	dot.size = Vector2(3, 3)
	dot.position = Vector2(-1.5, -1.5)
	_crosshair.add_child(dot)
	for i in 4:
		var tick := ColorRect.new()
		tick.color = Color(0.75, 0.85, 0.9, 0.35)
		var horiz := i < 2
		tick.size = Vector2(6, 1) if horiz else Vector2(1, 6)
		var sx := -1.0 if i % 2 == 0 else 1.0
		tick.position = (Vector2(sx * 8.0, -0.5) if horiz else Vector2(-0.5, sx * 8.0))
		_crosshair.add_child(tick)
	_hud.add_child(_crosshair)

	# prompt de interação
	_prompt_box = PanelContainer.new()
	_prompt_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_prompt_box.add_theme_stylebox_override("panel", UIStyle.panel(Color(0.03, 0.05, 0.06, 0.82), UIStyle.LINE_DIM))
	_prompt_box.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_prompt_box.position = Vector2(-140, -120)
	_prompt_box.custom_minimum_size = Vector2(280, 0)
	_prompt_box.visible = false
	_prompt_label = UIStyle.make_label("", 15, UIStyle.TEXT)
	_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_prompt_box.add_child(_prompt_label)
	_hud.add_child(_prompt_box)

	# objetivo (canto superior esquerdo)
	var obj_box := VBoxContainer.new()
	obj_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	obj_box.position = Vector2(28, 24)
	obj_box.add_theme_constant_override("separation", 2)
	_hud.add_child(obj_box)
	var tag := UIStyle.make_label("OBJETIVO ATUAL", 11, UIStyle.TEXT_DIM)
	obj_box.add_child(tag)
	_objective_label = UIStyle.make_label(GameState.objective_text, 16, Color(0.80, 0.90, 0.95))
	obj_box.add_child(_objective_label)
	_objective_sub = UIStyle.make_label("", 12, UIStyle.TEXT_DIM)
	obj_box.add_child(_objective_sub)

	# relógio / setor (canto superior direito)
	var clock_box := VBoxContainer.new()
	clock_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	clock_box.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	clock_box.position = Vector2(-330, 24)
	clock_box.custom_minimum_size = Vector2(300, 0)
	clock_box.alignment = BoxContainer.ALIGNMENT_END
	_hud.add_child(clock_box)
	_clock_label = UIStyle.make_label(GameState.clock_string(), 14, UIStyle.TEXT_DIM)
	_clock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	clock_box.add_child(_clock_label)
	var station_tag := UIStyle.make_label("ARGOS-4 // OPERAÇÃO K-9", 12, Color(0.45, 0.60, 0.66))
	station_tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	clock_box.add_child(station_tag)

	# setor (centro-topo, transitório)
	_sector_label = UIStyle.make_label("", 18, Color(0.75, 0.85, 0.9))
	_sector_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_sector_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_sector_label.position = Vector2(-200, 80)
	_sector_label.custom_minimum_size = Vector2(400, 0)
	_sector_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_sector_label.modulate.a = 0.0
	_hud.add_child(_sector_label)

	# legendas
	_sub_box = PanelContainer.new()
	_sub_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_sub_box.add_theme_stylebox_override("panel", UIStyle.panel(Color(0.02, 0.03, 0.04, 0.75), Color(0, 0, 0, 0)))
	_sub_box.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_sub_box.position = Vector2(-380, -190)
	_sub_box.custom_minimum_size = Vector2(760, 0)
	_sub_box.visible = false
	var sv := VBoxContainer.new()
	sv.add_theme_constant_override("separation", 4)
	_sub_box.add_child(sv)
	_sub_who = UIStyle.make_label("", 13, Color(0.55, 0.80, 0.88))
	_sub_text = UIStyle.make_label("", 17, Color(0.90, 0.93, 0.95))
	_sub_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sv.add_child(_sub_who)
	sv.add_child(_sub_text)
	_hud.add_child(_sub_box)

	# avisos (toasts)
	_toasts = VBoxContainer.new()
	_toasts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toasts.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_toasts.position = Vector2(-420, 90)
	_toasts.custom_minimum_size = Vector2(380, 0)
	_toasts.add_theme_constant_override("separation", 8)
	_toasts.alignment = BoxContainer.ALIGNMENT_END
	_hud.add_child(_toasts)

	# vitais (rodapé esquerdo)
	var vb := VBoxContainer.new()
	vb.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	vb.position = Vector2(28, -86)
	vb.add_theme_constant_override("separation", 4)
	_hud.add_child(vb)
	_vitals["o2"] = UIStyle.make_bar("O2", UIStyle.GREEN, 150)
	_vitals["bat"] = UIStyle.make_bar("BAT", UIStyle.AMBER, 150)
	vb.add_child(_vitals["o2"]["root"])
	vb.add_child(_vitals["bat"]["root"])

	# dica de controles
	_hint = UIStyle.make_label(_hint_default(), 12, Color(0.45, 0.58, 0.63))
	_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hint.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_hint.position = Vector2(-760, -34)
	_hint.custom_minimum_size = Vector2(740, 0)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_hint.modulate.a = 0.9
	_hud.add_child(_hint)

	# fade / flash
	_fade = ColorRect.new()
	_fade.color = Color(0, 0, 0, 0)
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fade)
	_flash = ColorRect.new()
	_flash.color = Color(0.8, 0.9, 1.0, 0.0)
	_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_flash)


# ================================================================ LOOP
func _process(delta: float) -> void:
	_clock_label.text = GameState.clock_string()
	UIStyle.set_bar(_vitals["o2"], GameState.o2, UIStyle.GREEN if GameState.o2 > 0.25 else UIStyle.RED)
	UIStyle.set_bar(_vitals["bat"], GameState.battery, UIStyle.AMBER if GameState.battery > 0.2 else UIStyle.RED)

	# estresse: granulação + vinheta + respiração visual
	stress = clampf(stress, 0.0, 1.0)
	_grain_mat.set_shader_parameter("amount", 0.02 + stress * 0.22)
	_grain_mat.set_shader_parameter("vignette", GameState.resonance * 0.045 + stress * 0.5)
	_grain_mat.set_shader_parameter("pulse", stress)
	var vignette_from_o2 := (1.0 - GameState.o2) * 0.5
	if vignette_from_o2 > 0.01:
		_grain_mat.set_shader_parameter("vignette", float(_grain_mat.get_shader_parameter("vignette")) + vignette_from_o2)

	# legendas
	if _sub_t > 0.0:
		_sub_t -= delta
		if _sub_t <= 0.0:
			_sub_box.visible = false
			_next_subtitle()
	elif not _sub_queue.is_empty():
		_next_subtitle()

	# setor
	if _sector_t > 0.0:
		_sector_t -= delta
		_sector_label.modulate.a = clampf(_sector_t, 0.0, 1.0) * 0.9
	elif _sector_label.modulate.a > 0.0:
		_sector_label.modulate.a = maxf(0.0, _sector_label.modulate.a - delta * 1.5)

	# dica inicial
	if _hint_t > 0.0:
		_hint_t -= delta
		if _hint_t <= 0.0:
			var tw := create_tween()
			tw.tween_property(_hint, "modulate:a", 0.0, 2.0)
	# avisos expiram
	for t: Node in _toasts.get_children():
		if t.has_meta("life"):
			var life: float = float(t.get_meta("life")) - delta
			t.set_meta("life", life)
			t.modulate.a = clampf(life, 0.0, 1.0)
			if life <= 0.0:
				t.queue_free()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if _ending != null:
			return
		if _panel != null:
			close_panel()
		elif _menu != null:
			pass
		else:
			open_pause()
		get_viewport().set_input_as_handled()
	if event.is_action_pressed("pda") and _panel == null and _ending == null and _menu == null:
		open_journal()
		get_viewport().set_input_as_handled()


# ================================================================ API BÁSICA
func show_prompt(text: String) -> void:
	_prompt_label.text = text
	_prompt_box.visible = true


func hide_prompt() -> void:
	_prompt_box.visible = false


func show_sector(name: String) -> void:
	_sector_label.text = name.to_upper()
	_sector_t = 4.0


func set_objective(text: String) -> void:
	_objective_label.text = text
	_objective_sub.text = "novo objetivo registrado"
	_flash.color = Color(0.35, 0.6, 0.7, 0.18)
	var tw := create_tween()
	tw.tween_property(_flash, "color:a", 0.0, 0.5)
	AudioMan.play_2d("blip_hi", -14.0, 1.0, "Interface")


func show_note(title: String, body: String) -> void:
	var box := PanelContainer.new()
	box.add_theme_stylebox_override("panel", UIStyle.panel(Color(0.03, 0.05, 0.07, 0.92), UIStyle.LINE))
	box.set_meta("life", 8.0)
	box.modulate.a = 0.0
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 3)
	box.add_child(v)
	var t := UIStyle.make_label("▌ " + title.to_upper(), 13, Color(0.55, 0.88, 0.72))
	v.add_child(t)
	var b := UIStyle.make_label(body, 13, UIStyle.TEXT)
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.custom_minimum_size = Vector2(340, 0)
	v.add_child(b)
	_toasts.add_child(box)
	var tw := create_tween()
	tw.tween_property(box, "modulate:a", 1.0, 0.4)
	while _toasts.get_child_count() > 4:
		_toasts.get_child(0).queue_free()
		await get_tree().process_frame
	AudioMan.play_2d("blip", -18.0, 1.0, "Interface")


func subtitle(who: String, text: String, duration := 3.4) -> void:
	_sub_queue.append({"who": who, "text": text, "dur": duration})


func _next_subtitle() -> void:
	if _sub_queue.is_empty():
		_sub_box.visible = false
		return
	var s: Dictionary = _sub_queue.pop_front()
	_sub_who.text = String(s["who"])
	_sub_text.text = String(s["text"])
	_sub_box.visible = true
	_sub_t = float(s["dur"])


## Fala com voz sintetizada: legenda sincronizada com a duração do clipe.
func say(lines: Array, voice_key := "", pos: Variant = null, radio := false) -> void:
	var offset := 0.0
	if voice_key != "" and AudioMan.has_voice(voice_key):
		AudioMan.play_voice(voice_key, pos, -2.0, 1.0, radio)
		var total := AudioMan.voice_duration(voice_key)
		var per: float = maxf(1.6, total / float(maxi(lines.size(), 1)))
		for l: Dictionary in lines:
			var d: float = per
			if l.has("dur"):
				d = float(l["dur"])
			subtitle(String(l.get("who", "")), String(l.get("text", "")), d)
			offset += d
		return
	for l: Dictionary in lines:
		subtitle(String(l.get("who", "")), String(l.get("text", "")), float(l.get("dur", 3.4)))


func play_voice_now(key: String, pos: Variant = null, radio := false) -> void:
	if AudioMan.has_voice(key):
		AudioMan.play_voice(key, pos, -1.0, 1.0, radio)
	else:
		AudioMan.play_2d("static", -14.0, 1.0, "Radio")


func fade_out(dur := 1.0) -> void:
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", 1.0, dur)
	await tw.finished


func fade_in(dur := 1.0) -> void:
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", 0.0, dur)
	await tw.finished


func set_fade_instant(a: float) -> void:
	_fade.color.a = a


func play_stress(level: float, seconds := 6.0) -> void:
	stress = maxf(stress, clampf(level, 0.0, 1.0))
	Director.after(seconds, func() -> void: stress = maxf(0.0, stress - level))


func flash(color := Color(0.8, 0.9, 1.0), dur := 0.25) -> void:
	_flash.color = Color(color.r, color.g, color.b, color.a)
	var tw := create_tween()
	tw.tween_property(_flash, "color:a", 0.0, dur)


# ================================================================ PAINÉIS
## Aviso no rodapé quando o cursor está solto (clique para voltar a olhar).
func hint_mouse(mostrar: bool) -> void:
	if _hint == null:
		return
	if mostrar:
		_hint.text = "ARRASTE COM O BOTÃO ESQUERDO PARA OLHAR  •  F1 PRENDE O CURSOR"
		_hint.modulate = Color(1.0, 0.85, 0.55, 1.0)
		_hint_t = 0.0
	elif _hint.text.begins_with("ARRASTE"):
		_hint.text = _hint_default()
		_hint.modulate = Color(1, 1, 1, 0.9)


func _hint_default() -> String:
	return "WASD mover  •  MOUSE/ARRASTAR olhar  •  SHIFT correr  •  CTRL agachar  •  E interagir  •  F lanterna  •  TAB diário  •  ESC opções"


## Recaptura o cursor quando a janela volta ao primeiro plano (alt-tab, diálogos
## do sistema, launcher). Sem isso o mouse ficava "morto" até reiniciar o jogo.
func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_IN or what == NOTIFICATION_WM_WINDOW_FOCUS_IN:
		if not blocked and _menu == null and _panel == null and _ending == null:
			var p := _player()
			if p != null:
				p._request_mouse_capture()
				hint_mouse(false)


func _player() -> Player:
	return get_tree().get_first_node_in_group("player") as Player


func _open_panel(node: Control) -> void:
	if _panel != null:
		_panel.queue_free()
	_panel = node
	blocked = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	add_child(node)
	AudioMan.play_2d("click", -10.0, 1.0, "Interface")


func close_panel() -> void:
	if _panel == null:
		return
	_panel.queue_free()
	_panel = null
	if _menu == null:
		blocked = false
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	AudioMan.play_2d("click", -14.0, 0.9, "Interface")
	panel_closed.emit()


func open_docs(ids: Array, title := "ARQUIVO") -> void:
	var r := DocReader.new()
	r.setup(ids, title)
	_open_panel(r)


func open_cctv() -> void:
	var c := CCTVScreen.new()
	_open_panel(c)


func open_radio(signals: Array) -> void:
	var r := RadioPanel.new()
	r.setup(signals)
	_open_panel(r)


func open_journal() -> void:
	var j := PauseMenu.new()
	j.setup(true)
	_open_panel(j)


func open_pause() -> void:
	var p := PauseMenu.new()
	p.setup(false)
	_open_panel(p)


func open_keypad(prompt: String, code: String, ok: Callable, fail: Callable) -> void:
	var k := KeypadPanel.new()
	k.setup(prompt, code, ok, fail)
	_open_panel(k)


func ask_decision(id: String) -> void:
	var d: Dictionary = Content.get_decision(id)
	if d.is_empty():
		return
	var c := ChoicePanel.new()
	c.setup(id, d)
	_open_panel(c)


# ================================================================ MENUS E SEQUÊNCIAS
func open_menu() -> void:
	if _menu != null:
		return
	var m := MainMenu.new()
	m.new_game.connect(func() -> void:
		m.queue_free()
		_menu = null
		GameState.reset()
		close_menu_and_start())
	m.continue_game.connect(func() -> void:
		m.queue_free()
		_menu = null
		close_menu_and_start())
	add_child(m)
	_menu = m
	blocked = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func close_menu_and_start() -> void:
	_menu = null
	blocked = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	menu_start.emit()


func play_intro() -> void:
	var iv := IntroSequence.new()
	add_child(iv)
	blocked = true


## Volta a interface ao estado de "jogo novo" (usado ao reiniciar a expedição).
func reset_for_new_run() -> void:
	if _panel != null:
		_panel.queue_free()
		_panel = null
	if _menu != null:
		_menu.queue_free()
		_menu = null
	if _ending != null:
		_ending.queue_free()
		_ending = null
	blocked = false
	stress = 0.0
	_sub_queue.clear()
	_sub_t = 0.0
	if _sub_box != null:
		_sub_box.visible = false
	if _fade != null:
		_fade.color.a = 0.0
	if _hint != null:
		_hint.modulate.a = 1.0
		_hint_t = 18.0
	for t: Node in _toasts.get_children():
		t.queue_free()
	set_objective(GameState.objective_text)


func show_ending(ending_id: String) -> void:
	var e := EndingSequence.new()
	e.setup(ending_id)
	add_child(e)
	_ending = e
	blocked = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
