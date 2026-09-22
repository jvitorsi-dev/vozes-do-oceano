extends Node
## Content — acesso a todo o material narrativo do jogo.
## Os dados ficam em scripts/data/*.gd para manter este acessador enxuto.

var docs: Dictionary = {}
var entries: Dictionary = {}
var anomalies: Dictionary = {}
var decisions: Dictionary = {}
var dialogues: Dictionary = {}
var items: Dictionary = {}
var signals_data: Dictionary = {}


func _ready() -> void:
	docs = DataDocs.all()
	entries = DataLore.entries()
	anomalies = DataLore.anomalies()
	decisions = DataLore.decisions()
	dialogues = DataLore.dialogues()
	items = DataLore.items()
	signals_data = DataLore.radio_signals()


func get_doc(id: String) -> Dictionary:
	return docs.get(id, {})


func get_entry(id: String) -> Dictionary:
	return entries.get(id, {})


func get_anomaly(id: String) -> Dictionary:
	return anomalies.get(id, {})


func get_decision(id: String) -> Dictionary:
	return decisions.get(id, {})


func get_dialogue(id: String) -> Dictionary:
	return dialogues.get(id, {})


func get_item(id: String) -> Dictionary:
	return items.get(id, {})


func doc_ids_from(csv: String) -> Array[String]:
	var out: Array[String] = []
	for s: String in csv.split(",", false):
		var t := s.strip_edges()
		if not t.is_empty():
			out.append(t)
	return out
