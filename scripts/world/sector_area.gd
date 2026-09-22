class_name SectorArea
extends Area3D
## Área de setor: avisa o jogador onde ele está e dispara gatilhos do Diretor.

var sector_id := ""
var display := ""


func _init() -> void:
	collision_layer = 8
	collision_mask = 1
	monitoring = true


static func create(id: String, nome: String, center: Vector3, size: Vector3) -> SectorArea:
	var a := SectorArea.new()
	a.sector_id = id
	a.display = nome
	a.position = center
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	cs.shape = shape
	a.add_child(cs)
	a.body_entered.connect(a._on_enter)
	return a


func _on_enter(body: Node3D) -> void:
	if not body.is_in_group("player"):
		return
	if body.has_method("set_sector"):
		body.set_sector(sector_id, display)
	Director.on_sector(sector_id, display)
