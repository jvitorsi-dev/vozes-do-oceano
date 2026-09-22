extends Node
## Ocean — o planeta como personagem.
## Todos os planos de água do jogo compartilham um único ShaderMaterial,
## que evolve com a Ressonância acumulada pelo jogador.

const OCEAN_SHADER := preload("res://assets/shaders/ocean.gdshader")

var material: ShaderMaterial
var resonance := 0.0

var _ripple_start := -99.0
var _ripple_strength := 0.0
var _t := 0.0
var _pending_pulse: Array = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	material = ShaderMaterial.new()
	material.shader = OCEAN_SHADER
	_apply(0)


func _process(delta: float) -> void:
	_t += delta
	for p: Dictionary in _pending_pulse:
		p["delay"] = float(p["delay"]) - delta
		if float(p["delay"]) <= 0.0:
			_pulse_now(p["pos"], float(p["strength"]))
	_pending_pulse = _pending_pulse.filter(func(p): return float(p["delay"]) > 0.0)

	if _ripple_strength > 0.001:
		var age := _t - _ripple_start
		material.set_shader_parameter("ripple_age", age)
		material.set_shader_parameter("ripple_strength", _ripple_strength)
		if age > 14.0:
			_ripple_strength = 0.0
			material.set_shader_parameter("ripple_strength", 0.0)
	# respiração lenta da luz do oceano
	var sea_pulse := 0.85 + 0.15 * sin(_t * 0.21) + 0.06 * sin(_t * 0.63)
	material.set_shader_parameter("sun_dir_power", sea_pulse)


## Chamado pelo GameState quando a ressonância muda.
func set_resonance(v: int) -> void:
	set_resonance_float(float(v) / 10.0)


func set_resonance_float(v: float) -> void:
	resonance = clampf(v, 0.0, 1.0)
	_apply(resonance)


func _apply(v: float) -> void:
	material.set_shader_parameter("resonance", v)
	material.set_shader_parameter("geometric", 0.45 + clampf(v, 0.0, 1.0) * 0.55)
	material.set_shader_parameter("wave_speed", 0.16 + v * 0.45)
	material.set_shader_parameter("amplitude", 0.45 + v * 1.9)
	material.set_shader_parameter("foam", 0.12 + v * 0.4)
	material.set_shader_parameter("grid_scale", 0.055 + v * 0.05)
	material.set_shader_parameter("glow_color", Color(0.32, 0.78, 0.92).lerp(Color(0.75, 0.95, 0.85), v))
	AudioMan.set_ocean_energy(v)


## Pulso de resposta: um anel de luz/onda atravessa o mar a partir de uma
## posição do mundo (normalmente a estação) — o oceano "notou" algo.
func pulse(world_pos: Vector3, strength := 0.8, delay := 0.0) -> void:
	if delay > 0.0:
		_pending_pulse.append({"pos": world_pos, "strength": strength, "delay": delay})
	else:
		_pulse_now(world_pos, strength)


func _pulse_now(world_pos: Vector3, strength: float) -> void:
	material.set_shader_parameter("ripple_center", Vector2(world_pos.x, world_pos.z))
	_ripple_start = _t
	_ripple_strength = clampf(strength, 0.0, 2.0)
	material.set_shader_parameter("ripple_age", 0.0)
	material.set_shader_parameter("ripple_strength", _ripple_strength)
	material.set_shader_parameter("ripple_speed", 22.0 + resonance * 40.0)
	AudioMan.set_layer("water", minf(0.9, AudioMan.get_layer("water") + 0.25 * strength))


## Cria um plano de mar pronto para uso (compartilha o material global).
func make_sea(radius: float, y: float, segments: int = 96, center := Vector3.ZERO) -> MeshInstance3D:
	var mesh := PlaneMesh.new()
	mesh.size = Vector2(radius * 2.0, radius * 2.0)
	mesh.subdivide_width = segments
	mesh.subdivide_depth = segments
	var mi := MeshInstance3D.new()
	mi.name = "Mar"
	mi.mesh = mesh
	mi.material_override = material
	mi.position = Vector3(center.x, y, center.z)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi


## "Objeto humano" imitado pelo oceano: uma estrutura de água em forma
## de construção reconhecível — o mar copiando arquitetura.
func make_imitation(pos: Vector3, size := Vector3(90.0, 26.0, 90.0)) -> Node3D:
	var root := Node3D.new()
	root.name = "Imitacao"
	root.position = pos
	var body := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	body.mesh = bm
	body.material_override = material
	root.add_child(body)
	for i in 6:
		var ring := MeshInstance3D.new()
		var rm := BoxMesh.new()
		rm.size = Vector3(size.x * 1.01, 2.2, size.z * 1.01)
		ring.mesh = rm
		ring.material_override = material
		ring.position.y = -size.y * 0.5 + 3.0 + float(i) * (size.y / 7.0)
		root.add_child(ring)
	return root
