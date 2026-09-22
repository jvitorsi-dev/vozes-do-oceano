extends Node
## GameState — memória persistente da partida.
##
## Guarda o que o jogador descobriu, quanto o Oceano "confia" nele e quanto
## o fenômeno já ressoou. É o cérebro que o diretor de anomalias consulta
## para decidir COMO cada manifestação aparece.

signal flag_set(id: String)
signal trust_changed(value: int)
signal resonance_changed(value: int)
signal doc_read(id: String)
signal decision_made(id: String, choice: String)
signal power_changed(kw: float)
signal anomaly_seen(id: String)
signal objective_changed(text: String)
signal note_added(title: String, body: String)
signal stat_changed()
signal o2_changed(value: float)
signal battery_changed(value: float)

const SAVE_PATH := "user://vozes_do_oceano.save"

# ---------------------------------------------------------------- progresso
var flags: Dictionary = {}
var docs_read: Dictionary = {}
var decisions: Dictionary = {}
var anomalies: Dictionary = {}
var entries_unlocked: Dictionary = {}
var journal: Array[Dictionary] = []

var chapter: int = 0
var objective_text: String = "Chegar à Estação Argos-4"

# ---------------------------------------------------------------- variáveis do fenômeno
## Confiança: -5 (o Oceano recua, hostil/frio) .. +5 (o Oceano se aproxima, imita mais)
var trust: int = 0
## Ressonância: 0 (inerte) .. 10 (o mar inteiro responde). Muda o visual do oceano.
var resonance: int = 0

# ---------------------------------------------------------------- recursos
var o2: float = 1.0            # 0..1
var battery: float = 0.86      # 0..1 (lanterna / traje)
var power_total: float = 12.0  # kW disponíveis na estação
var power_demand: float = 12.0

# ---------------------------------------------------------------- relógio da estação
var mouse_sens_pref: float = 0.0026  # preferência do jogador (rad por pixel de tela)
var clock_minutes: int = 131    # 02:11 no relógio interno
var elapsed_real: float = 0.0

var _save_dirty := false
var _clock_accum := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _process(delta: float) -> void:
	elapsed_real += delta
	# O relógio da estação corre ~3x mais rápido que o do jogador.
	_clock_accum += delta * 3.0
	while _clock_accum >= 60.0:
		_clock_accum -= 60.0
		clock_minutes += 1


func clock_string() -> String:
	var total := clock_minutes
	var d := int(total / 1440.0)
	var h := int((total % 1440) / 60)
	var m := total % 60
	return "DIA %02d // %02d:%02d" % [d + 1, h, m]


# ================================================================ flags
func set_flag(id: String, value: bool = true) -> void:
	if value:
		if flags.get(id, false):
			return
		flags[id] = true
	else:
		flags.erase(id)
	_save_dirty = true
	flag_set.emit(id)


func has(id: String) -> bool:
	return flags.get(id, false)


func count(id: String) -> int:
	return int(flags.get(id, 0))


func add_count(id: String, n: int = 1) -> int:
	var v := count(id) + n
	flags[id] = v
	_save_dirty = true
	flag_set.emit(id)
	return v


# ================================================================ descobertas
func read_doc(id: String) -> void:
	if docs_read.has(id):
		return
	docs_read[id] = true
	_save_dirty = true
	doc_read.emit(id)
	var doc: Dictionary = Content.get_doc(id)
	if not doc.is_empty() and doc.has("entry"):
		unlock(String(doc["entry"]))
	if doc.has("on_read"):
		_apply_effects(doc["on_read"])
	if doc.has("objective"):
		set_objective(String(doc["objective"]))


func is_read(id: String) -> bool:
	return docs_read.has(id)


func unlock(entry_id: String) -> void:
	if entry_id.is_empty() or entries_unlocked.has(entry_id):
		return
	entries_unlocked[entry_id] = true
	_save_dirty = true
	var entry: Dictionary = Content.get_entry(entry_id)
	if not entry.is_empty():
		note_added.emit(String(entry.get("title", "?")), String(entry.get("body", "")))


func has_entry(entry_id: String) -> bool:
	return entries_unlocked.has(entry_id)


func seen_anomaly(id: String) -> void:
	if anomalies.has(id):
		return
	anomalies[id] = true
	_save_dirty = true
	anomaly_seen.emit(id)
	var a: Dictionary = Content.get_anomaly(id)
	if not a.is_empty() and a.has("entry"):
		unlock(String(a["entry"]))


# ================================================================ decisões
func decide(id: String, choice: String) -> void:
	decisions[id] = choice
	_save_dirty = true
	decision_made.emit(id, choice)
	var d: Dictionary = Content.get_decision(id)
	if d.has("effects") and d["effects"].has(choice):
		_apply_effects(d["effects"][choice])


func decision(id: String) -> String:
	return String(decisions.get(id, ""))


func _apply_effects(effects: Dictionary) -> void:
	if effects.has("trust"):
		add_trust(int(effects["trust"]))
	if effects.has("resonance"):
		add_resonance(int(effects["resonance"]))
	if effects.has("flag"):
		set_flag(String(effects["flag"]))
	if effects.has("objective"):
		set_objective(String(effects["objective"]))
	if effects.has("note"):
		var n: Array = effects["note"]
		add_note(String(n[0]), String(n[1]))


# ================================================================ Oceano
func add_trust(delta: int) -> void:
	var v := clampi(trust + delta, -5, 5)
	if v == trust:
		return
	trust = v
	_save_dirty = true
	trust_changed.emit(trust)


func add_resonance(delta: int) -> void:
	var v := clampi(resonance + delta, 0, 10)
	if v == resonance:
		return
	resonance = v
	_save_dirty = true
	resonance_changed.emit(resonance)
	Ocean.set_resonance(v)


func resonance_band() -> int:
	# 0..4 — usado por anomalias e pelo oceano para escolher intensidade.
	return int(floor(float(resonance) / 2.5))


func set_objective(text: String) -> void:
	if text == objective_text:
		return
	objective_text = text
	objective_changed.emit(text)


func set_power(kw: float) -> void:
	power_total = kw
	_save_dirty = true
	power_changed.emit(kw)


func add_note(title: String, body: String) -> void:
	journal.append({"t": clock_string(), "title": title, "body": body})
	_save_dirty = true
	note_added.emit(title, body)


func mark_anomaly_encounter(kind: String) -> void:
	add_count("enc_" + kind)


# ================================================================ save/load
func to_dict() -> Dictionary:
	return {
		"flags": flags, "docs": docs_read, "decisions": decisions,
		"anomalies": anomalies, "entries": entries_unlocked, "journal": journal,
		"chapter": chapter, "trust": trust, "resonance": resonance,
		"o2": o2, "battery": battery, "power": power_total, "clock": clock_minutes,
		"mouse_sens": mouse_sens_pref,
		"objective": objective_text, "elapsed": elapsed_real,
	}


func from_dict(d: Dictionary) -> void:
	flags = d.get("flags", {})
	docs_read = d.get("docs", {})
	decisions = d.get("decisions", {})
	anomalies = d.get("anomalies", {})
	entries_unlocked = d.get("entries", {})
	journal.clear()
	for j: Variant in d.get("journal", []):
		journal.append(j)
	chapter = int(d.get("chapter", 0))
	trust = int(d.get("trust", 0))
	resonance = int(d.get("resonance", 0))
	o2 = float(d.get("o2", 1.0))
	battery = float(d.get("battery", 0.86))
	power_total = float(d.get("power", 12.0))
	clock_minutes = int(d.get("clock", 131))
	mouse_sens_pref = clampf(float(d.get("mouse_sens", 0.0026)), 0.0004, 0.01)
	objective_text = String(d.get("objective", ""))
	elapsed_real = float(d.get("elapsed", 0.0))


## Preferência de sensibilidade do mouse (persistida junto do save).
func set_mouse_sens(v: float) -> void:
	mouse_sens_pref = clampf(v, 0.0004, 0.01)
	_save_dirty = true


func save_game() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify(to_dict()))
	f.close()
	_save_dirty = false


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func load_game() -> bool:
	if not has_save():
		return false
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return false
	var data: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(data) != TYPE_DICTIONARY:
		return false
	from_dict(data)
	return true


func reset() -> void:
	flags.clear(); docs_read.clear(); decisions.clear()
	anomalies.clear(); entries_unlocked.clear(); journal.clear()
	chapter = 0; trust = 0; resonance = 0
	o2 = 1.0; battery = 0.86; power_total = 12.0
	clock_minutes = 131; elapsed_real = 0.0
	objective_text = "Chegar à Estação Argos-4"
