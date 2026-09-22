class_name CamGrid
extends RefCounted
## Registro global das câmeras de vigilância da estação.
## A estação as registra ao ser construída; o console de CCTV as lista.

static var cams: Dictionary = {}
static var order: Array[String] = []


static func add(id: String, display: String, pos: Vector3, yaw: float, sector: String,
		fov := 62.0, broken := false) -> void:
	cams[id] = {
		"id": id, "display": display, "pos": pos, "yaw": yaw,
		"sector": sector, "fov": fov, "broken": broken, "glitch": 0.0,
	}
	if not order.has(id):
		order.append(id)


static func get_cam(id: String) -> Dictionary:
	return cams.get(id, {})


static func ids() -> Array[String]:
	return order


static func set_broken(id: String, broken := true) -> void:
	if cams.has(id):
		cams[id]["broken"] = broken


static func set_glitch(id: String, amount: float) -> void:
	if cams.has(id):
		cams[id]["glitch"] = clampf(amount, 0.0, 1.0)


static func reset() -> void:
	cams.clear()
	order.clear()
