class_name LampGrid
extends RefCounted
## Registro das luminárias da estação. Antes da energia ser restaurada,
## tudo vive na luz de emergência; depois, os tubos frios acendem.

static var lamps: Array = []          # {"light": Light3D, "tube": Node3D, "emergency": bool}
static var reds: Array = []


static func add(lamp: Dictionary) -> void:
	if lamp.has("light"):
		lamps.append(lamp)


static func add_red(light: Light3D) -> void:
	reds.append(light)


static func power_on() -> void:
	for l: Dictionary in lamps:
		var light: Light3D = l["light"]
		if is_instance_valid(light):
			light.light_energy = 1.15
			light.light_color = Color(0.86, 0.92, 1.0)
		var tube: Node3D = l.get("tube", null)
		if is_instance_valid(tube) and tube is MeshInstance3D:
			(tube as MeshInstance3D).material_override = Mats.get_mat("lamp_cold")


static func set_emergency_energy(e := 0.45) -> void:
	for l: Dictionary in lamps:
		var light: Light3D = l["light"]
		if is_instance_valid(light):
			light.light_energy = e


static func reset() -> void:
	lamps.clear()
	reds.clear()
