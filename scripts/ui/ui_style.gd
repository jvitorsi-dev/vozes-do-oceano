class_name UIStyle
extends RefCounted
## Estilo visual da interface: fonte mono de sistema, paleta fria e
## caixas com moldura fina — tecnologia analógica, não flat design.

const BG := Color(0.031, 0.043, 0.055, 0.94)
const BG_SOLID := Color(0.026, 0.035, 0.045, 1.0)
const LINE := Color(0.33, 0.48, 0.55, 0.75)
const LINE_DIM := Color(0.22, 0.32, 0.38, 0.55)
const TEXT := Color(0.80, 0.87, 0.89)
const TEXT_DIM := Color(0.52, 0.61, 0.65)
const GREEN := Color(0.36, 0.92, 0.68)
const AMBER := Color(1.0, 0.68, 0.26)
const RED := Color(0.95, 0.36, 0.28)
const PAPER := Color(0.86, 0.83, 0.74)
const PAPER_BG := Color(0.10, 0.09, 0.07, 0.96)

static var _mono_font: SystemFont = null


## Uma única fonte mono para todo o jogo (o tamanho vem do tema do controle).
static func mono(_size := 15) -> Font:
	if _mono_font == null:
		var f := SystemFont.new()
		f.font_names = PackedStringArray([
			"DejaVu Sans Mono", "Consolas", "Courier New", "Menlo",
			"Liberation Mono", "Ubuntu Mono", "monospace",
		])
		f.antialiasing = TextServer.FONT_ANTIALIASING_GRAY
		f.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_AUTO
		_mono_font = f
	return _mono_font


static func panel(bg := BG, border := LINE, border_width := 1) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(border_width)
	sb.set_corner_radius_all(2)
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	return sb


## Aplica fonte e tamanho num controle de uma vez.
static func font_to(c: Control, size: int) -> void:
	c.add_theme_font_override("font", mono(size))
	c.add_theme_font_size_override("font_size", size)


static func make_label(text: String, size := 15, color := TEXT) -> Label:
	var l := Label.new()
	l.text = text
	font_to(l, size)
	l.add_theme_color_override("font_color", color)
	return l


static func make_rich(text := "", size := 15, color := TEXT) -> RichTextLabel:
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.text = text
	r.fit_content = true
	r.scroll_active = true
	r.add_theme_font_override("normal_font", mono(size))
	r.add_theme_font_override("bold_font", mono(size))
	r.add_theme_font_override("mono_font", mono(size))
	r.add_theme_font_size_override("normal_font_size", size)
	r.add_theme_font_size_override("bold_font_size", size)
	r.add_theme_font_size_override("mono_font_size", size)
	r.add_theme_color_override("default_color", color)
	r.add_theme_constant_override("line_separation", 5)
	return r


static func make_button(text: String, size := 15) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_override("font", mono(size))
	b.add_theme_font_size_override("font_size", size)
	var normal := panel(Color(0.05, 0.07, 0.085, 0.9), LINE_DIM, 1)
	normal.content_margin_left = 12
	normal.content_margin_right = 12
	normal.content_margin_top = 6
	normal.content_margin_bottom = 6
	b.add_theme_stylebox_override("normal", normal)
	var hover := panel(Color(0.10, 0.15, 0.18, 0.95), LINE, 1)
	hover.content_margin_left = 12
	hover.content_margin_right = 12
	hover.content_margin_top = 6
	hover.content_margin_bottom = 6
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", hover)
	b.add_theme_stylebox_override("focus", panel(Color(0, 0, 0, 0), Color(0, 0, 0, 0), 0))
	b.add_theme_stylebox_override("disabled", normal)
	b.add_theme_color_override("font_color", TEXT)
	b.add_theme_color_override("font_hover_color", Color(1, 1, 1))
	b.add_theme_color_override("font_disabled_color", TEXT_DIM)
	return b


## Barra horizontal estilo instrumento (retorna nós + dados para set_bar).
static func make_bar(label: String, color := GREEN, width := 140) -> Dictionary:
	var box := HBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	var l := make_label(label, 13, TEXT_DIM)
	l.custom_minimum_size.x = 36
	l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	box.add_child(l)
	var track := Panel.new()
	track.custom_minimum_size = Vector2(width, 8)
	track.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var ts := StyleBoxFlat.new()
	ts.bg_color = Color(0.06, 0.08, 0.09, 0.9)
	ts.border_color = LINE_DIM
	ts.set_border_width_all(1)
	track.add_theme_stylebox_override("panel", ts)
	box.add_child(track)
	var fill := ColorRect.new()
	fill.color = color
	fill.position = Vector2(1, 1)
	fill.size = Vector2(width - 2, 6)
	track.add_child(fill)
	var val := make_label("100%", 12, TEXT_DIM)
	val.custom_minimum_size.x = 44
	val.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	box.add_child(val)
	return {"root": box, "fill": fill, "value": val, "track": track, "width": width}


static func set_bar(bar: Dictionary, v: float, color := GREEN) -> void:
	var f: ColorRect = bar["fill"]
	var w: float = bar["width"]
	f.size = Vector2(maxf(0.0, (w - 2) * clampf(v, 0.0, 1.0)), 6)
	f.color = color
	var l: Label = bar["value"]
	l.text = "%d%%" % int(round(clampf(v, 0.0, 1.0) * 100.0))


static func divider() -> Control:
	var c := ColorRect.new()
	c.color = LINE_DIM
	c.custom_minimum_size = Vector2(0, 1)
	return c
