class_name LampFlicker
extends Node
## Reator de fluorescente velho: de tempos em tempos a lâmpada falha por uma
## fração de segundo, em rajadas curtas.
##
## Não mexe em `light_energy` (quem manda na energia são o Director e a
## LampGrid: apagões, anomalias, volta da força). Só liga/desliga a
## visibilidade da luz e do tubo — assim nada da lógica do jogo é disputado.

var luz: Light3D
var tubo: Node3D
var semente := 1
## Intervalo médio entre rajadas, em segundos.
var intervalo := 9.0

var _rng := RandomNumberGenerator.new()
var _espera := 0.0
var _rajada: Array[float] = []
var _aceso := true


func _ready() -> void:
	_rng.seed = semente
	_espera = _rng.randf_range(1.0, intervalo)


func _process(delta: float) -> void:
	if not is_instance_valid(luz):
		set_process(false)
		return
	_espera -= delta
	if _espera > 0.0:
		return
	if _rajada.is_empty():
		if not _aceso:
			_definir(true)
			_espera = _rng.randf_range(intervalo * 0.4, intervalo * 1.6)
			return
		# nova rajada: 2 a 6 trocas rápidas, começando por apagar
		for i in _rng.randi_range(2, 6):
			_rajada.append(_rng.randf_range(0.03, 0.14))
	_definir(not _aceso)
	_espera = _rajada.pop_back()
	if _rajada.is_empty() and _aceso:
		_espera = _rng.randf_range(intervalo * 0.4, intervalo * 1.6)


func _definir(aceso: bool) -> void:
	_aceso = aceso
	luz.visible = aceso
	if is_instance_valid(tubo):
		tubo.visible = aceso
