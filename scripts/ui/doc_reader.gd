class_name DocReader
extends Control
## Leitor de documentos. Cada tipo de mídia tem seu visual:
## monitor (verde CRT), papel (bege gasto), fita (âmbar com onda),
## foto (imagem procedural — que muda conforme a estação muda) e manual.

const TAPE_ACCENT := Color(1.0, 0.68, 0.26)

var ids: Array = []
var title := "ARQUIVO"
var idx := 0
var _body: RichTextLabel
var _list: VBoxContainer
var _header: Label
var _kind_tag: Label
var _photo: TextureRect
var _tape_vis: Control
var _panel_box: PanelContainer
var _reveal := 0.0
var _full_text := ""
var _t := 0.0
var _wave := Control.new()
var _entered := false


func setup(doc_ids: Array, doc_title: String) -> void:
	ids = doc_ids.duplicate()
	title = doc_title


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.72)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	_panel_box = PanelContainer.new()
	_panel_box.set_anchors_preset(Control.PRESET_CENTER)
	_panel_box.custom_minimum_size = Vector2(920, 600)
	_panel_box.position = Vector2(-460, -300)
	add_child(_panel_box)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	_panel_box.add_child(v)

	# barra superior
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 12)
	v.add_child(top)
	var t := UIStyle.make_label("▌ " + title, 16, UIStyle.TEXT)
	_header = t
	top.add_child(t)
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(sp)
	_kind_tag = UIStyle.make_label("", 12, UIStyle.TEXT_DIM)
	top.add_child(_kind_tag)
	v.add_child(UIStyle.divider())

	var mid := HBoxContainer.new()
	mid.add_theme_constant_override("separation", 14)
	mid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(mid)

	_list = VBoxContainer.new()
	_list.custom_minimum_size = Vector2(230, 0)
	_list.add_theme_constant_override("separation", 4)
	mid.add_child(_list)

	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 10)
	mid.add_child(right)

	_photo = TextureRect.new()
	_photo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_photo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_photo.custom_minimum_size = Vector2(0, 300)
	_photo.visible = false
	right.add_child(_photo)

	_tape_vis = Control.new()
	_tape_vis.custom_minimum_size = Vector2(0, 64)
	_tape_vis.visible = false
	_tape_vis.draw.connect(_draw_tape)
	right.add_child(_tape_vis)

	_body = UIStyle.make_rich("", 15, UIStyle.TEXT)
	_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_child(_body)

	v.add_child(UIStyle.divider())
	var foot := UIStyle.make_label("[E] / [ESC] fechar    •    [← →] documentos    •    [N] próximo registro", 12, UIStyle.TEXT_DIM)
	v.add_child(foot)

	_build_list()
	_show(0)
	AudioMan.play_2d("blip", -12.0, 1.0, "Interface")


func _build_list() -> void:
	for c: Node in _list.get_children():
		c.queue_free()
	if ids.size() <= 1:
		_list.visible = false
		return
	_list.visible = true
	for i in ids.size():
		var doc: Dictionary = Content.get_doc(String(ids[i]))
		var b := UIStyle.make_button(String(doc.get("title", ids[i])), 13)
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.custom_minimum_size = Vector2(230, 0)
		b.pressed.connect(_show.bind(i))
		_list.add_child(b)
		if i == idx:
			b.add_theme_color_override("font_color", UIStyle.AMBER)


func _show(i: int) -> void:
	if ids.is_empty():
		return
	idx = wrapi(i, 0, ids.size())
	var id := String(ids[idx])
	var doc: Dictionary = Content.get_doc(id)
	if doc.is_empty():
		_body.text = "[i]Registro ausente ou corrompido.[/i]"
		return
	var kind := String(doc.get("kind", "paper"))
	_header.text = "▌ " + String(doc.get("title", "SEM TÍTULO"))
	_kind_tag.text = String(doc.get("header", ""))
	_photo.visible = false
	_tape_vis.visible = false
	var color := UIStyle.TEXT
	match kind:
		"monitor":
			color = Color(0.62, 0.95, 0.78)
			_panel_box.add_theme_stylebox_override("panel", UIStyle.panel(Color(0.014, 0.024, 0.020, 0.97), Color(0.25, 0.55, 0.42, 0.8)))
		"paper":
			color = Color(0.88, 0.85, 0.76)
			_panel_box.add_theme_stylebox_override("panel", UIStyle.panel(UIStyle.PAPER_BG, Color(0.35, 0.32, 0.24, 0.9)))
		"tape":
			color = Color(0.95, 0.85, 0.68)
			_panel_box.add_theme_stylebox_override("panel", UIStyle.panel(Color(0.07, 0.055, 0.035, 0.97), Color(0.45, 0.36, 0.16, 0.85)))
			_tape_vis.visible = true
		"photo":
			color = Color(0.85, 0.88, 0.9)
			_panel_box.add_theme_stylebox_override("panel", UIStyle.panel(Color(0.03, 0.035, 0.045, 0.97), UIStyle.LINE))
			_photo.visible = true
			_photo.texture = photo_texture(id)
		"manual":
			color = Color(0.85, 0.82, 0.7)
			_panel_box.add_theme_stylebox_override("panel", UIStyle.panel(Color(0.06, 0.06, 0.055, 0.97), Color(0.4, 0.42, 0.36, 0.8)))
	_body.add_theme_color_override("default_color", color)
	_full_text = String(doc.get("body", ""))
	_reveal = 0.0
	_body.text = ""
	GameState.read_doc(id)


func _draw_tape() -> void:
	var w := _tape_vis.size.x
	var h := _tape_vis.size.y
	var base := h * 0.5
	_tape_vis.draw_line(Vector2(0, base), Vector2(w, base), Color(0.3, 0.24, 0.12, 0.8), 1.0)
	var pts := PackedVector2Array()
	for x in range(0, int(w), 2):
		var f := float(x) / maxf(w, 1.0)
		var amp := (0.25 + 0.75 * absf(sin(f * 33.0 + _t * 2.0))) * (7.0 + 18.0 * absf(sin(f * 7.0 + _t)))
		amp *= 0.35 + 0.65 * clampf(_reveal * 2.0, 0.0, 1.0)
		pts.append(Vector2(f * w, base + sin(f * 90.0 + _t * 6.0) * amp))
	_tape_vis.draw_polyline(pts, TAPE_ACCENT, 1.6)


func _process(delta: float) -> void:
	_t += delta
	if _tape_vis.visible:
		_tape_vis.queue_redraw()
	if _reveal < 1.0 and not _full_text.is_empty():
		_reveal = minf(1.0, _reveal + delta * 1.6)
		var n := int(_full_text.length() * _reveal)
		_body.text = _full_text.substr(0, n)
	if not _entered:
		_entered = true


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		if _reveal < 1.0:
			_reveal = 1.0
			_body.text = _full_text
		else:
			UI.close_panel()
		get_viewport().set_input_as_handled()
	if event is InputEventKey and event.is_pressed():
		var k := (event as InputEventKey).keycode
		if k == KEY_RIGHT or k == KEY_D:
			_show(idx + 1)
		elif k == KEY_LEFT or k == KEY_A:
			_show(idx - 1)
		elif k == KEY_N:
			_show(idx + 1)
			UI.close_panel()


# ================================================================ FOTOS PROCEDURAIS
## As fotografias do jogo são desenhadas em código — e mudam quando a
## estação (ou o oceano) decide mudar.
func photo_texture(id: String) -> Texture2D:
	var img: Image
	match id:
		"photo_01":
			img = _draw_crew_photo()
		"foto_02":
			img = _draw_home_photo()
		_:
			img = _draw_crew_photo()
	return ImageTexture.create_from_image(img)


func _draw_crew_photo() -> Image:
	var w := 420
	var h := 280
	var img := Image.create(w, h, false, Image.FORMAT_RGB8)
	# céu do hangar / parede
	for y in h:
		var t := float(y) / float(h)
		img.fill_rect(Rect2i(0, y, w, 1), Color(0.06, 0.08, 0.10).lerp(Color(0.10, 0.13, 0.16), t))
	# piso
	img.fill_rect(Rect2i(0, int(h * 0.74), w, h), Color(0.13, 0.14, 0.15))
	# porta do hangar ao fundo
	img.fill_rect(Rect2i(int(w * 0.06), int(h * 0.16), int(w * 0.22), int(h * 0.58)), Color(0.16, 0.18, 0.20))
	img.fill_rect(Rect2i(int(w * 0.06), int(h * 0.16), 3, int(h * 0.58)), Color(0.30, 0.33, 0.36))
	# tripulação (5 silhuetas) + eventual sexto vulto
	var xs := [0.32, 0.44, 0.56, 0.68, 0.80]
	var heights := [0.40, 0.43, 0.41, 0.44, 0.42]
	if GameState.has("foto_extra") or GameState.has("viu_foto") and GameState.resonance_band() >= 2:
		# o sexto vulto: mais alto, mais escuro, fora de foco
		_draw_figure(img, int(w * 0.90), int(h * 0.74), 0.44, Color(0.055, 0.06, 0.07), 2)
	for i in xs.size():
		_draw_figure(img, int(w * float(xs[i])), int(h * 0.74), float(heights[i]), Color(0.09, 0.10, 0.11), 1)
	# brilho do flash
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	for i in 260:
		var x := rng.randi_range(0, w - 1)
		var y := rng.randi_range(0, h - 1)
		img.set_pixel(x, y, img.get_pixel(x, y).lightened(0.25))
	# legenda à mão
	img.fill_rect(Rect2i(int(w * 0.30), int(h * 0.86), int(w * 0.40), 2), Color(0.7, 0.68, 0.6))
	return img


func _draw_home_photo() -> Image:
	var w := 420
	var h := 280
	var img := Image.create(w, h, false, Image.FORMAT_RGB8)
	# céu de fim de tarde
	for y in h:
		var t := float(y) / float(h)
		img.fill_rect(Rect2i(0, y, w, 1), Color(0.24, 0.30, 0.42).lerp(Color(0.55, 0.44, 0.36), t * 0.9))
	# chão
	img.fill_rect(Rect2i(0, int(h * 0.72), w, h), Color(0.16, 0.18, 0.15))
	# casa
	var hx := int(w * 0.22)
	var hw := int(w * 0.42)
	var hy := int(h * 0.36)
	img.fill_rect(Rect2i(hx, hy, hw, int(h * 0.36)), Color(0.32, 0.28, 0.24))
	# telhado (triângulo)
	for i in 40:
		var t := float(i) / 40.0
		img.fill_rect(Rect2i(hx - int(t * 26.0), hy - 40 + i, hw + int(t * 52.0), 1), Color(0.20, 0.16, 0.15))
	# janelas acesas
	img.fill_rect(Rect2i(hx + 18, hy + 22, 34, 30), Color(0.95, 0.78, 0.42))
	img.fill_rect(Rect2i(hx + 74, hy + 22, 34, 30), Color(0.20, 0.22, 0.26))
	# porta
	img.fill_rect(Rect2i(hx + hw - 62, hy + 40, 30, int(h * 0.36) - 40), Color(0.12, 0.09, 0.08))
	if GameState.has("porta_extra") or GameState.has("viu_foto_2"):
		# a porta que não existia no dia da foto — aberta, com luz saindo
		img.fill_rect(Rect2i(hx + 12, hy + 40, 26, int(h * 0.36) - 40), Color(0.05, 0.04, 0.04))
		img.fill_rect(Rect2i(hx + 12, hy + 40, 26, 4), Color(0.92, 0.86, 0.72))
		for i in 8:
			img.fill_rect(Rect2i(hx + 14 + i, hy + 46, 1, int(h * 0.36) - 50), Color(0.75, 0.72, 0.6, 0.25))
	var rng := RandomNumberGenerator.new()
	rng.seed = 991
	for i in 200:
		var x := rng.randi_range(0, w - 1)
		var y := rng.randi_range(0, h - 1)
		img.set_pixel(x, y, img.get_pixel(x, y).darkened(0.12))
	return img


func _draw_figure(img: Image, cx: int, ground_y: int, rel_h: float, col: Color, blur := 0) -> void:
	var hh := int(float(img.get_height()) * rel_h)
	var bw := int(hh * 0.22)
	var top := ground_y - hh
	img.fill_rect(Rect2i(cx - bw / 2, top + int(hh * 0.18), bw, int(hh * 0.82)), col)
	img.fill_rect(Rect2i(cx - bw * 0.36, top, int(bw * 0.72), int(hh * 0.2)), col)
	if blur > 0:
		for i in blur:
			img.fill_rect(Rect2i(cx - bw / 2 - 2 - i, top - i, bw + 4 + i * 2, hh + i),
					Color(col.r, col.g, col.b, 0.18))
