extends Node
## Boot — primeiro autoload carregado.
## Cria o mapa de entrada em código (evita um project.godot gigante) e
## ajusta alguns padrões do motor antes de qualquer cena carregar.

const ACTIONS := {
	"move_forward": [KEY_W, KEY_UP],
	"move_back": [KEY_S, KEY_DOWN],
	"move_left": [KEY_A, KEY_LEFT],
	"move_right": [KEY_D, KEY_RIGHT],
	"sprint": [KEY_SHIFT],
	"interact": [KEY_E, KEY_ENTER],
	"torch": [KEY_F],
	"crouch": [KEY_CTRL],
	"pda": [KEY_TAB],
	"pause": [KEY_ESCAPE],
	"ui_cancel_alt": [KEY_BACKSPACE],
	"recenter": [KEY_F1],       # prende o cursor de novo
	"diag": [KEY_F3],           # diagnóstico do mouse na tela
}


func _ready() -> void:
	_ensure_actions()
	Engine.max_fps = 120
	process_mode = Node.PROCESS_MODE_ALWAYS


func _ensure_actions() -> void:
	for action: String in ACTIONS.keys():
		if not InputMap.has_action(action):
			InputMap.add_action(action, 0.25)
		for code: int in ACTIONS[action]:
			var ev := InputEventKey.new()
			ev.physical_keycode = code
			InputMap.action_add_event(action, ev)
	# Aceita também o botão esquerdo do mouse como "interagir" no minigame/console.
	if not InputMap.has_action("ui_click"):
		InputMap.add_action("ui_click")
		var mb := InputEventMouseButton.new()
		mb.button_index = MOUSE_BUTTON_LEFT
		InputMap.action_add_event("ui_click", mb)
