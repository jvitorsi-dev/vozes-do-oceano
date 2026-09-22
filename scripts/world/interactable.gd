class_name Interactable
extends Area3D
## Ponto de interação: detectado pelo raio do jogador (camada 2).
## Não bloqueia movimento — é uma área, não um corpo.

signal used(player: Node3D)

var prompt_text := "Examinar"
var enabled := true
var one_shot := false
var used_once := false
var data: Dictionary = {}
var on_use: Callable = Callable()
var on_look: Callable = Callable()


func _init() -> void:
	collision_layer = 2
	collision_mask = 0
	monitoring = false
	monitorable = true


static func create(prompt: String, box: Vector3, offset := Vector3.ZERO,
		cb: Callable = Callable(), d: Dictionary = {}) -> Interactable:
	var it := Interactable.new()
	it.prompt_text = prompt
	it.on_use = cb
	it.data = d
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = box
	cs.shape = shape
	cs.position = offset
	it.add_child(cs)
	return it


func _ready() -> void:
	add_to_group("interactables")


func prompt() -> String:
	if not enabled:
		return ""
	if one_shot and used_once:
		return ""
	if typeof(data.get("prompt_fn", null)) == TYPE_CALLABLE:
		var f: Callable = data["prompt_fn"]
		if f.is_valid():
			return String(f.call())
	return prompt_text


func use(player: Node3D) -> bool:
	if not enabled or (one_shot and used_once):
		return false
	used_once = true
	used.emit(player)
	if on_use.is_valid():
		on_use.call(player, self)
	return true


func looked_at() -> void:
	if on_look.is_valid():
		on_look.call(self)
