class_name Manifestation
extends Node3D
## Uma pessoa que o oceano construiu.
##
## Ela respira, esquenta o ar, olha para você quando você olha — e não tem
## batimentos. Ao se dissolver, deixa uma poça que ninguém explica.

const MANIFEST_SHADER := preload("res://assets/shaders/manifest.gdshader")

enum Kind { GENERICA, IRIS, ANDREI, NADIA, TOMAS, CORO, SOMBRA }

var kind: Kind = Kind.GENERICA
var who := ""
var lines: Array = []
var voice_key := ""
var decision_id := ""
var on_end: Callable = Callable()
var dissolvendo := false
var _mat: ShaderMaterial
var _t := 0.0
var _look_t := 0.0
var _player: Node3D
var _inter: Interactable
var _talked := false
var _breath_player: AudioStreamPlayer3D


func _ready() -> void:
	_mat = ShaderMaterial.new()
	_mat.shader = MANIFEST_SHADER
	_mat.set_shader_parameter("dissolve", 0.0)
	match kind:
		Kind.IRIS, Kind.NADIA, Kind.TOMAS:
			_mat.set_shader_parameter("body_color", Color(0.34, 0.58, 0.66))
			_mat.set_shader_parameter("translucency", 0.5)
		Kind.ANDREI:
			_mat.set_shader_parameter("body_color", Color(0.30, 0.48, 0.55))
			_mat.set_shader_parameter("translucency", 0.42)
		Kind.SOMBRA:
			_mat.set_shader_parameter("body_color", Color(0.06, 0.09, 0.12))
			_mat.set_shader_parameter("rim_color", Color(0.35, 0.55, 0.6))
			_mat.set_shader_parameter("translucency", 0.85)
		_:
			_mat.set_shader_parameter("body_color", Color(0.32, 0.55, 0.62))
	StationKit.figure(self, Vector3.ZERO, 0.0, _mat, 1.76)
	_inter = Interactable.create("Falar com %s" % who, Vector3(1.4, 2.0, 1.4), Vector3(0, 1.0, 0), _on_interact)
	_inter.data = {"manifest": true}
	add_child(_inter)
	_breath_player = AudioStreamPlayer3D.new()
	_breath_player.stream = AudioMan.sfx("breath")
	_breath_player.bus = "SFX"
	_breath_player.volume_db = -26.0
	_breath_player.max_distance = 8.0
	add_child(_breath_player)
	_breath_player.play()
	Director.register_figure(self)


func setup(w: String, k: Kind, speech: Array, voice := "", decision := "") -> Manifestation:
	who = w
	kind = k
	lines = speech
	voice_key = voice
	decision_id = decision
	return self


func _process(delta: float) -> void:
	_t += delta
	_mat.set_shader_parameter("age", _t)
	if _player == null:
		for n in get_tree().get_nodes_in_group("player"):
			_player = n
	if _player != null and not dissolvendo:
		_look_t += delta
		if _look_t > 0.4:
			_look_t = 0.0
			var p := (_player as Node3D).global_position
			var target_yaw := atan2(p.x - global_position.x, p.z - global_position.z)
			rotation.y = lerp_angle(rotation.y, target_yaw, 0.18)
		var d := (_player as Node3D).global_position.distance_to(global_position)
		# manifestações se dissolvem se você chega perto demais rápido demais
		if d < 1.15 and kind != Kind.CORO:
			dissolve()


func _on_interact(_p: Node3D, _i: Interactable) -> void:
	if _talked or dissolvendo:
		return
	_talked = true
	var pos_variant: Variant = global_position if voice_key != "" else null
	UI.say(lines, voice_key, pos_variant)
	UI.play_stress(0.45, 8.0)
	Director._manifest_seen += 1
	var wait := 3.0
	if voice_key != "" and AudioMan.has_voice(voice_key):
		wait = AudioMan.voice_duration(voice_key) + 1.5
	Director.after(wait, _talk_followup)


func _talk_followup() -> void:
	if decision_id != "":
		var d: Dictionary = Content.get_decision(decision_id)
		if not d.is_empty() and GameState.decision(decision_id) == "":
			UI.ask_decision(decision_id)
	Director.after(6.0, dissolve)


func dissolve() -> void:
	if dissolvendo:
		return
	dissolvendo = true
	_inter.enabled = false
	AudioMan.play_3d("drip", global_position, -6.0)
	AudioMan.play_3d("thud", global_position, -14.0)
	UI.subtitle("", "A figura desaba em si mesma, sem barulho de queda, e o chão fica molhado.", 4.0)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_method(func(v: float) -> void: _mat.set_shader_parameter("dissolve", v), 0.0, 1.0, 2.6)
	tw.tween_property(self, "scale", Vector3(1.0, 0.35, 1.0), 2.6)
	await tw.finished
	_breath_player.stop()
	# poça no chão — e nada mais
	StationKit.stain(get_parent(), global_position + Vector3(0, 0.02, 0), Vector2(1.5, 1.1), true)
	GameState.seen_anomaly("manifesto")
	if on_end.is_valid():
		on_end.call()
	Director.figures.erase(self)
	queue_free()


func body_temperature() -> float:
	return 36.4
