class_name StationKit
extends RefCounted
## StationKit — construtor da estação: salas, corredores, consoles, portas,
## tubulações, janelas gigantes e câmeras. Tudo procedural.

const CRT := preload("res://assets/shaders/crt.gdshader")

# ================================================================ VÃOS NO PISO (POÇOS)
## Laje com vãos: usada para os poços dos monta-cargas atravessarem os conveses.
static func slab_with_holes(parent: Node3D, x1: float, z1: float, x2: float, z2: float, y: float,
		mat: Material, holes: Array, thick: float = 0.3, above := false) -> void:
	if holes.is_empty():
		if above:
			G3D.ceiling_slab(parent, x1, z1, x2, z2, y, mat, thick)
		else:
			G3D.floor_slab(parent, x1, z1, x2, z2, y, mat, thick)
		return
	var rects: Array = [Rect2(x1, z1, x2 - x1, z2 - z1)]
	for h: Dictionary in holes:
		var hole := Rect2(float(h["x1"]), float(h["z1"]), float(h["x2"]) - float(h["x1"]), float(h["z2"]) - float(h["z1"]))
		var next: Array = []
		for r: Rect2 in rects:
			next.append_array(_rect_subtract(r, hole))
		rects = next
	for r: Rect2 in rects:
		if r.size.x < 0.08 or r.size.y < 0.08:
			continue
		if above:
			G3D.ceiling_slab(parent, r.position.x, r.position.y, r.end.x, r.end.y, y, mat, thick)
		else:
			G3D.floor_slab(parent, r.position.x, r.position.y, r.end.x, r.end.y, y, mat, thick)


static func _rect_subtract(a: Rect2, b: Rect2) -> Array:
	var ix1 := maxf(a.position.x, b.position.x)
	var ix2 := minf(a.end.x, b.end.x)
	var iz1 := maxf(a.position.y, b.position.y)
	var iz2 := minf(a.end.y, b.end.y)
	if ix1 >= ix2 or iz1 >= iz2:
		return [a]
	var out: Array = []
	if iz1 > a.position.y:
		out.append(Rect2(a.position.x, a.position.y, a.size.x, iz1 - a.position.y))
	if iz2 < a.end.y:
		out.append(Rect2(a.position.x, iz2, a.size.x, a.end.y - iz2))
	if ix1 > a.position.x:
		out.append(Rect2(a.position.x, iz1, ix1 - a.position.x, iz2 - iz1))
	if ix2 < a.end.x:
		out.append(Rect2(ix2, iz1, a.end.x - ix2, iz2 - iz1))
	return out


## Sinalização do poço: faixas de perigo em volta do vão (sem colisão para
## não atrapalhar o jogador ao atravessar).
static func shaft_marks(parent: Node3D, cx: float, cz: float, size: float, y: float) -> void:
	var half := size * 0.5
	var hm := Mats.get_mat("hazard")
	G3D.box(parent, Vector3(size + 0.6, 0.04, 0.3), Vector3(cx, y + 0.03, cz - half - 0.2), hm, false, Vector3.ZERO, "faixa_poco")
	G3D.box(parent, Vector3(size + 0.6, 0.04, 0.3), Vector3(cx, y + 0.03, cz + half + 0.2), hm, false, Vector3.ZERO, "faixa_poco")
	G3D.box(parent, Vector3(0.3, 0.04, size + 0.6), Vector3(cx - half - 0.2, y + 0.03, cz), hm, false, Vector3.ZERO, "faixa_poco")
	G3D.box(parent, Vector3(0.3, 0.04, size + 0.6), Vector3(cx + half + 0.2, y + 0.03, cz), hm, false, Vector3.ZERO, "faixa_poco")
	G3D.label3d(parent, "POCO DE CARGA", Vector3(cx, y + 0.08, cz + half + 1.0), 0.0, 0.0055, Color(0.92, 0.72, 0.32))


# ================================================================ SALAS
static func room(parent: Node3D, x1: float, z1: float, x2: float, z2: float,
		y: float, h: float, opts: Dictionary = {}) -> Dictionary:
	var root := Node3D.new()
	root.name = String(opts.get("name", "Sala"))
	root.set_meta(Batcher.META_PROPRIO, true)
	parent.add_child(root)

	var floor_mat: Material = opts.get("floor", Mats.get_mat("floor"))
	var wall_mat: Material = opts.get("wall", Mats.get_mat("wall_dark"))
	var ceil_mat: Material = opts.get("ceil", Mats.get_mat("ceiling"))

	slab_with_holes(root, x1, z1, x2, z2, y, floor_mat, opts.get("floor_holes", []), 0.3, false)
	if not bool(opts.get("no_ceiling", false)):
		slab_with_holes(root, x1, z1, x2, z2, y + h, ceil_mat, opts.get("ceil_holes", []), 0.25, true)

	var doors: Array = opts.get("doors", [])
	var windows: Array = opts.get("windows", [])
	var door_nodes: Array = []

	var skip: Array = opts.get("skip_walls", [])
	for side: String in ["n", "s", "w", "e"]:
		if skip.has(side):
			continue
		var along_x := side == "n" or side == "s"
		var fixed := z1 if side == "n" else (z2 if side == "s" else (x1 if side == "w" else x2))
		var a1 := x1 if along_x else z1
		var a2 := x2 if along_x else z2
		var start := minf(a1, a2)
		var specs: Array = []
		for d: Dictionary in doors:
			if String(d.get("side", "")) == side:
				specs.append(d)
		for w: Dictionary in windows:
			if String(w.get("side", "")) == side:
				specs.append(w)

		var openings: Array = []
		for s: Dictionary in specs:
			var w: float = float(s.get("w", 1.7))
			var hh: float = float(s.get("h", 2.15))
			var base: float = float(s.get("base", 0.0))
			var at: float = float(s.get("at", start))
			openings.append({"at": (at - start) - w * 0.5, "width": w, "height": hh, "base": base})
		G3D.wall(root, along_x, a1, a2, fixed, y, h, wall_mat, 0.3, openings)

		# painéis de reforço (detalhe industrial)
		var n_panels := int(absf(a2 - a1) / 2.6)
		for i in n_panels:
			var pv := start + 1.3 + float(i) * 2.6
			var size := Vector3(0.16, h - 0.4, 0.06) if along_x else Vector3(0.06, h - 0.4, 0.16)
			var pos := Vector3(pv, y + h * 0.5, fixed + (0.17 if side == "n" else (-0.17 if side == "s" else 0.0))) if along_x \
					else Vector3(fixed + (0.17 if side == "w" else -0.17), y + h * 0.5, pv)
			G3D.box(root, size, pos, Mats.get_mat("metal"), false, Vector3.ZERO, "painel")

		# portas e janelas
		for s: Dictionary in specs:
			var at: float = float(s.get("at", start))
			var w: float = float(s.get("w", 1.7))
			var hh: float = float(s.get("h", 2.15))
			var base: float = float(s.get("base", 0.0))
			var kind := String(s.get("type", "door"))
			var center := Vector3(at, y + base, fixed) if along_x else Vector3(fixed, y + base, at)
			match kind:
				"door", "bulk":
					var door := Door.new()
					door.position = center
					root.add_child(door)
					door.setup(String(s.get("id", "porta")), String(s.get("name", "SETOR")), along_x,
							w, hh, bool(s.get("auto", true)), bool(s.get("locked", false)),
							String(s.get("lock_reason", "TRAVADA")), String(s.get("key", "")))
					if kind == "bulk":
						door.silent = false
						G3D.hazard_stripe(root, along_x, center, w, 0.3)
					door_nodes.append(door)
				"open":
					G3D.hazard_stripe(root, along_x, center + Vector3(0, -base, 0), w, 0.24)
					# moldura do vão
					var ft := 0.14
					if along_x:
						G3D.box(root, Vector3(ft, hh, 0.42), Vector3(at - w * 0.5, y + base + hh * 0.5, fixed), Mats.get_mat("metal"), false)
						G3D.box(root, Vector3(ft, hh, 0.42), Vector3(at + w * 0.5, y + base + hh * 0.5, fixed), Mats.get_mat("metal"), false)
						G3D.box(root, Vector3(w, ft, 0.42), Vector3(at, y + base + hh, fixed), Mats.get_mat("metal"), false)
					else:
						G3D.box(root, Vector3(0.42, hh, ft), Vector3(fixed, y + base + hh * 0.5, at - w * 0.5), Mats.get_mat("metal"), false)
						G3D.box(root, Vector3(0.42, hh, ft), Vector3(fixed, y + base + hh * 0.5, at + w * 0.5), Mats.get_mat("metal"), false)
						G3D.box(root, Vector3(0.42, ft, w), Vector3(fixed, y + base + hh, at), Mats.get_mat("metal"), false)
				"glass", "big":
					var glass_mat: Material = Mats.get_mat("glass_scratch") if kind == "big" else Mats.get_mat("glass")
					if along_x:
						G3D.box(root, Vector3(w, hh, 0.07), Vector3(at, y + base + hh * 0.5, fixed), glass_mat, true, Vector3.ZERO, "vidro")
						# caixilho
						for i in int(maxf(1.0, round(w / 1.6))):
							var mx := at - w * 0.5 + (float(i) + 0.5) * (w / maxf(1.0, round(w / 1.6)))
							G3D.box(root, Vector3(0.12, hh, 0.24), Vector3(mx, y + base + hh * 0.5, fixed), Mats.get_mat("metal"), true, Vector3.ZERO, "caixilho")
						G3D.box(root, Vector3(w, 0.14, 0.26), Vector3(at, y + base + 0.05, fixed), Mats.get_mat("metal"), true)
						G3D.box(root, Vector3(w, 0.16, 0.26), Vector3(at, y + base + hh - 0.06, fixed), Mats.get_mat("metal"), true)
					else:
						G3D.box(root, Vector3(0.07, hh, w), Vector3(fixed, y + base + hh * 0.5, at), glass_mat, true, Vector3.ZERO, "vidro")
						for i in int(maxf(1.0, round(w / 1.6))):
							var mz := at - w * 0.5 + (float(i) + 0.5) * (w / maxf(1.0, round(w / 1.6)))
							G3D.box(root, Vector3(0.24, hh, 0.12), Vector3(fixed, y + base + hh * 0.5, mz), Mats.get_mat("metal"), true, Vector3.ZERO, "caixilho")
						G3D.box(root, Vector3(0.26, 0.14, w), Vector3(fixed, y + base + 0.05, at), Mats.get_mat("metal"), true)
						G3D.box(root, Vector3(0.26, 0.16, w), Vector3(fixed, y + base + hh - 0.06, at), Mats.get_mat("metal"), true)

	# luminárias
	var lamp_nodes: Array = []
	for l: Dictionary in opts.get("lamps", []):
		var lp: Vector2 = l.get("pos", Vector2.ZERO)
		var lamp := G3D.ceiling_lamp(root, Vector3(lp.x, y + h - 0.12, lp.y), bool(l.get("along_x", true)),
				float(l.get("len", 1.7)), float(l.get("energy", 0.75)),
				l.get("color", Color(0.72, 0.82, 0.98)), bool(l.get("emergency", false)))
		lamp_nodes.append(lamp)
		var idx := lamp_nodes.size() - 1
		var luz := lamp["light"] as OmniLight3D
		# uma luz-chave por sala projeta sombra (só no desktop: no navegador
		# sombra de luz pontual custa caro demais)
		if idx == 0 and not OS.has_feature("web"):
			luz.shadow_enabled = true
			luz.shadow_bias = 0.06
			luz.shadow_normal_bias = 1.4
			luz.shadow_blur = 1.6
		# reator cansado: mais ou menos uma luminária em cada quatro falha
		var sorte := int(absf(lp.x) * 7.0 + absf(lp.y) * 13.0 + absf(y) * 3.0)
		if sorte % 4 == 1:
			var pisca := LampFlicker.new()
			pisca.luz = luz
			pisca.tubo = lamp["tube"] as Node3D
			pisca.semente = sorte + 17
			pisca.intervalo = 6.0 + float(sorte % 7)
			(lamp["node"] as Node3D).add_child(pisca)

	# tubulação aparente
	if bool(opts.get("pipes", false)):
		var along_x2 := (absf(x2 - x1) >= absf(z2 - z1))
		if along_x2:
			G3D.pipes(root, true, x1 + 0.6, x2 - 0.6, z1 + 0.45, y + h - 0.3, 3)
		else:
			G3D.pipes(root, false, z1 + 0.6, z2 - 0.6, x1 + 0.45, y + h - 0.3, 3)

	# placas
	for s: Dictionary in opts.get("labels", []):
		G3D.sign(root, String(s.get("text", "")), s.get("pos", Vector3.ZERO), float(s.get("rot_y", 0.0)),
				int(s.get("size", 44)), s.get("color", Color(0.80, 0.86, 0.88)))

	return {"root": root, "doors": door_nodes, "lamps": lamp_nodes}


# ================================================================ TELAS E CONSOLES
static func screen_material(color := Color(0.35, 0.92, 0.68), glitch := 0.0,
		alt := 0.0, off := 0.0, brightness := 1.15) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = CRT
	m.set_shader_parameter("screen_color", color)
	m.set_shader_parameter("mix_alt", alt)
	m.set_shader_parameter("glitch", glitch)
	m.set_shader_parameter("off", off)
	m.set_shader_parameter("brightness", brightness)
	m.set_shader_parameter("noise_amount", 0.10)
	return m


static func monitor(parent: Node3D, pos: Vector3, yaw: float, size := Vector2(0.5, 0.36),
		color := Color(0.35, 0.92, 0.68), off := false, tilt := -0.22) -> Dictionary:
	var g := Node3D.new()
	g.position = pos
	g.rotation.y = yaw
	parent.add_child(g)
	# gabinete de CRT: moldura frontal grossa + traseira afunilada do tubo.
	# Tudo num só nó inclinado junto com a tela (antes o corpo ficava torto
	# em relação ao vidro e a tela "descolava" do aparelho).
	var corpo := Node3D.new()
	corpo.rotation.x = tilt
	g.add_child(corpo)
	var casca := Mats.get_mat("plastic_old")
	var w := size.x + 0.10
	var h := size.y + 0.10
	var aro := 0.05
	# moldura: quatro réguas em volta do vidro, salientes 2 cm
	G3D.box(corpo, Vector3(w, aro, 0.10), Vector3(0, h * 0.5 - aro * 0.5, -0.03), casca, false, Vector3.ZERO, "aro")
	G3D.box(corpo, Vector3(w, aro, 0.10), Vector3(0, -h * 0.5 + aro * 0.5, -0.03), casca, false, Vector3.ZERO, "aro")
	G3D.box(corpo, Vector3(aro, h - aro * 2.0, 0.10), Vector3(-w * 0.5 + aro * 0.5, 0, -0.03), casca, false, Vector3.ZERO, "aro")
	G3D.box(corpo, Vector3(aro, h - aro * 2.0, 0.10), Vector3(w * 0.5 - aro * 0.5, 0, -0.03), casca, false, Vector3.ZERO, "aro")
	# fundo escuro atrás do vidro
	G3D.box(corpo, Vector3(w - aro, h - aro, 0.02), Vector3(0, 0, -0.012), Mats.get_mat("plastic_dark"), false, Vector3.ZERO, "fundo")
	# traseira do tubo (tronco deitado: base na moldura, afunila para trás)
	var prof := clampf(size.x * 0.55, 0.20, 0.42)
	G3D.peca(corpo, MeshKit.tronco(Vector2(w, h), Vector2(w * 0.52, h * 0.55), prof, Vector2(0, -h * 0.08)),
			Vector3(0, 0, -0.08 - prof * 0.5), casca, Vector3(-PI * 0.5, 0, 0), Vector3.ONE, "tubo")
	# botões e luz-piloto na régua de baixo
	for kb in 2:
		Detail._cil(corpo, 0.011, 0.02, Vector3(w * 0.5 - 0.05 - float(kb) * 0.045, -h * 0.5 + aro * 0.5, 0.025),
				Mats.get_mat("plastic_dark"), Vector3(PI * 0.5, 0, 0), 6)
	var scr := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = size
	scr.mesh = pm
	var mat := screen_material(color, 0.0, 0.0, 1.0 if off else 0.0)
	scr.material_override = mat
	scr.position = Vector3(0, 0, 0.005)
	scr.rotation.x = tilt
	g.add_child(scr)
	var glow := OmniLight3D.new()
	glow.light_color = color
	glow.light_energy = 0.0 if off else 0.22
	glow.omni_range = 2.2
	glow.position = Vector3(0, 0, 0.3)
	glow.shadow_enabled = false
	g.add_child(glow)
	return {"node": g, "screen": scr, "material": mat, "light": glow}


static func console(parent: Node3D, pos: Vector3, yaw: float, kind: String, payload: Dictionary,
		opts: Dictionary = {}) -> Node3D:
	var g := Node3D.new()
	g.name = "Console_" + kind
	g.position = pos
	g.rotation.y = yaw
	parent.add_child(g)

	var h := float(opts.get("h", 0.78))
	G3D.box(g, Vector3(1.15, 0.06, 0.62), Vector3(0, h, 0), Mats.get_mat("metal"), true, Vector3.ZERO, "tampo")
	G3D.box(g, Vector3(1.05, h, 0.5), Vector3(0, h * 0.5, 0), Mats.get_mat("wall_dark"), true, Vector3.ZERO, "corpo")
	G3D.box(g, Vector3(0.42, 0.05, 0.24), Vector3(0.28, h + 0.03, 0.12), Mats.get_mat("rubber"), false, Vector3.ZERO, "teclado")

	var color := Color(0.35, 0.92, 0.68)
	var off := false
	match kind:
		"terminal", "cctv": color = Color(0.35, 0.92, 0.68)
		"tape", "radio": color = Color(1.0, 0.66, 0.24)
		"photo", "sample": color = Color(0.72, 0.85, 0.95)
		"power", "valve": color = Color(0.95, 0.45, 0.30)
	var dead: bool = not GameState.has("energia_ok") and bool(opts.get("needs_power", true))
	if dead:
		off = true
		color = Color(0.3, 0.35, 0.35)
	var mon := monitor(g, Vector3(-0.12, h + 0.32, -0.06), 0.0, opts.get("size", Vector2(0.5, 0.36)), color, off)
	mon["node"].rotation.x = -0.28
	# o requisito de energia viaja junto com o console: terminais de emergência
	# (hangar, depósito, cabines, fita) funcionam antes de a energia voltar
	mon["needs_power"] = bool(opts.get("needs_power", true))

	# cabos e detalhe
	G3D.cyl(g, 0.03, 0.5, Vector3(0.35, h * 0.5, -0.3), Mats.get_mat("rubber"), Vector3(0.4, 0, 0.2), false)

	var prompt := String(payload.get("prompt", _default_prompt(kind)))
	var inter := Interactable.create(prompt, Vector3(1.25, 1.3, 0.9), Vector3(0, 0.75, 0), _use_console.bind(g, kind, payload, mon))
	inter.data = {"kind": kind}
	g.add_child(inter)
	return g


static func _default_prompt(kind: String) -> String:
	match kind:
		"terminal": return "Ler terminal"
		"cctv": return "Usar console de vigilância"
		"tape": return "Reproduzir fita"
		"radio": return "Sintonizar rádio"
		"photo": return "Examinar fotografia"
		"sample": return "Analisar amostra"
		"power": return "Acionar painel de energia"
		"valve": return "Operar válvula"
		"code": return "Teclado numérico"
	return "Usar"


static func _use_console(_player: Node3D, _it: Interactable, g: Node3D, kind: String,
		payload: Dictionary, mon: Dictionary) -> void:
	AudioMan.play_3d("blip", g.global_position, -6.0)
	var dead: bool = bool(mon.get("needs_power", false)) and not GameState.has("energia_ok") and kind != "code"
	match kind:
		"terminal":
			if dead:
				UI.show_note("SEM ENERGIA", "O terminal não responde. A estação precisa de energia no setor de engenharia.")
				return
			var ids: Array = payload.get("docs", [payload.get("doc", "bl_000")])
			UI.open_docs(ids, String(payload.get("title", "TERMINAL")))
		"tape":
			if dead:
				UI.show_note("SEM ENERGIA", "O reprodutor de fitas está morto.")
				return
			var doc: String = String(payload.get("doc", "fita_1"))
			UI.open_docs([doc], "REPRODUTOR DE FITAS")
			if payload.has("voice"):
				UI.play_voice_now(String(payload["voice"]), g.global_position)
		"photo":
			UI.open_docs([String(payload.get("doc", "photo_01"))], "ARQUIVO FOTOGRÁFICO")
		"radio":
			if dead:
				UI.show_note("SEM ENERGIA", "O transceptor não tem corrente. Um fusível de 400 A está faltando.")
				return
			UI.open_radio(payload.get("signals", ["terra_1"]))
		"cctv":
			if dead:
				UI.show_note("SEM ENERGIA", "O circuito de vigilância está sem corrente.")
				return
			UI.open_cctv()
		"power":
			Director.power_action(g, payload)
		"valve":
			Director.valve_action(g, payload)
		"sample":
			Director.sample_action(g, payload)
		"code":
			UI.open_keypad(String(payload.get("prompt", "CÓDIGO")), String(payload.get("code", "0000")),
					payload.get("on_success", Callable()), payload.get("on_fail", Callable()))
		"lift":
			Director.lift_action(g, payload)
		_:
			if typeof(payload.get("on_use", null)) == TYPE_CALLABLE:
				var cb: Callable = payload["on_use"]
				cb.call(g)


# ================================================================ PROPS
static func tape_player(parent: Node3D, pos: Vector3, yaw: float, doc_id: String, voice := "") -> Node3D:
	var g := Node3D.new()
	g.position = pos
	g.rotation.y = yaw
	parent.add_child(g)
	G3D.box(g, Vector3(0.62, 0.42, 0.26), Vector3(0, 1.15, 0), Mats.get_mat("metal_rust"), true, Vector3.ZERO, "gravador")
	G3D.cyl(g, 0.09, 0.03, Vector3(-0.14, 1.15, 0.15), Mats.get_mat("metal"), Vector3(PI * 0.5, 0, 0))
	G3D.cyl(g, 0.09, 0.03, Vector3(0.14, 1.15, 0.15), Mats.get_mat("metal"), Vector3(PI * 0.5, 0, 0))
	var led := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.07, 0.05, 0.02)
	led.mesh = bm
	led.material_override = Mats.emissive(Color(1.0, 0.62, 0.2), 2.0 if GameState.has("energia_ok") else 0.2)
	led.position = Vector3(0.24, 1.3, 0.14)
	g.add_child(led)
	var inter := Interactable.create("Reproduzir fita", Vector3(0.9, 1.0, 0.9), Vector3(0, 1.1, 0),
			func(_p: Node3D, _i: Interactable) -> void:
				UI.open_docs([doc_id], "REPRODUTOR DE FITA (BATERIA PRÓPRIA)")
				if voice != "":
					UI.play_voice_now(voice, g.global_position))
	g.add_child(inter)
	return g


static func crates(parent: Node3D, pos: Vector3, count := 3, yaw := 0.0) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(pos.x * 13.0 + pos.z * 7.0)
	for i in count:
		var p := pos + Vector3(rng.randf_range(-0.8, 0.8), 0.0, rng.randf_range(-0.8, 0.8))
		var s := Vector3(rng.randf_range(0.7, 1.1), rng.randf_range(0.6, 0.95), rng.randf_range(0.7, 1.1))
		G3D.box(parent, s, Vector3(p.x, pos.y + s.y * 0.5, p.z), Mats.get_mat("metal_rust") if i % 2 == 0 else Mats.get_mat("fabric"),
				true, Vector3(0, yaw + rng.randf_range(-0.4, 0.4), 0), "caixa")
		G3D.box(parent, Vector3(s.x * 0.9, 0.04, s.z * 0.9), Vector3(p.x, pos.y + s.y + 0.02, p.z), Mats.get_mat("hazard"), false, Vector3.ZERO, "faixa")


static func locker(parent: Node3D, pos: Vector3, yaw: float, tag := "") -> Node3D:
	var g := Node3D.new()
	g.position = pos
	g.rotation.y = yaw
	parent.add_child(g)
	G3D.box(g, Vector3(0.9, 1.9, 0.5), Vector3(0, 0.95, 0), Mats.get_mat("wall_dark"), true, Vector3.ZERO, "armario")
	G3D.box(g, Vector3(0.02, 1.6, 0.4), Vector3(0, 1.0, 0.26), Mats.get_mat("metal"), false, Vector3.ZERO, "porta")
	G3D.box(g, Vector3(0.06, 0.1, 0.06), Vector3(0.3, 1.0, 0.28), Mats.get_mat("metal_rust"), false, Vector3.ZERO, "maçaneta")
	if tag != "":
		G3D.label3d(g, tag, Vector3(0, 1.98, 0), 0.0, 0.004, Color(0.7, 0.78, 0.8))
	return g


static func bed(parent: Node3D, pos: Vector3, yaw: float, tag := "") -> Node3D:
	var g := Node3D.new()
	g.position = pos
	g.rotation.y = yaw
	parent.add_child(g)
	G3D.box(g, Vector3(1.0, 0.42, 2.0), Vector3(0, 0.28, 0), Mats.get_mat("metal"), true, Vector3.ZERO, "leito")
	G3D.box(g, Vector3(0.94, 0.14, 1.9), Vector3(0, 0.55, 0), Mats.get_mat("fabric"), true, Vector3.ZERO, "colchao")
	G3D.box(g, Vector3(0.6, 0.12, 0.4), Vector3(0, 0.66, -0.7), Mats.get_mat("fabric"), false, Vector3.ZERO, "travesseiro")
	if tag != "":
		G3D.label3d(g, tag, Vector3(0, 1.2, -0.95), PI, 0.006, Color(0.75, 0.8, 0.82))
	return g


static func table_chairs(parent: Node3D, pos: Vector3, yaw := 0.0, chairs := 4) -> void:
	var g := Node3D.new()
	g.position = pos
	g.rotation.y = yaw
	parent.add_child(g)
	G3D.box(g, Vector3(1.6, 0.06, 0.9), Vector3(0, 0.74, 0), Mats.get_mat("metal"), true, Vector3.ZERO, "mesa")
	Setores.mesa_posta(g, int(absf(pos.x) * 7.0 + absf(pos.z) * 3.0) + chairs)
	for i in 4:
		G3D.cyl(g, 0.03, 0.74, Vector3(-0.7 + (1.4 if i % 2 == 1 else 0.0), 0.37, -0.38 + (0.76 if i > 1 else 0.0)), Mats.get_mat("metal"), Vector3.ZERO, false)
	for i in chairs:
		var ang := TAU * float(i) / float(maxi(chairs, 1)) + PI * 0.25
		var cp := Vector3(cos(ang) * 1.15, 0, sin(ang) * 1.0)
		var c := Node3D.new()
		c.position = cp
		c.rotation.y = -ang + PI * 0.5
		g.add_child(c)
		G3D.box(c, Vector3(0.45, 0.05, 0.45), Vector3(0, 0.45, 0), Mats.get_mat("metal"), true, Vector3.ZERO, "assento")
		G3D.box(c, Vector3(0.45, 0.5, 0.05), Vector3(0, 0.7, -0.2), Mats.get_mat("metal"), true, Vector3.ZERO, "encosto")
		G3D.cyl(c, 0.025, 0.45, Vector3(0, 0.22, 0), Mats.get_mat("metal"), Vector3.ZERO, false)


static func shelf(parent: Node3D, pos: Vector3, yaw: float, folders := 6) -> void:
	var g := Node3D.new()
	g.position = pos
	g.rotation.y = yaw
	parent.add_child(g)
	G3D.box(g, Vector3(1.6, 2.0, 0.4), Vector3(0, 1.0, 0), Mats.get_mat("wall_dark"), true, Vector3.ZERO, "estante")
	var rng := RandomNumberGenerator.new()
	rng.seed = int(pos.x + pos.z * 3.0)
	for i in 5:
		var yv := 0.3 + float(i) * 0.4
		G3D.box(g, Vector3(1.5, 0.04, 0.36), Vector3(0, yv, 0.02), Mats.get_mat("metal"), false)
		for j in folders:
			if rng.randf() < 0.55:
				G3D.box(g, Vector3(0.05, 0.26, 0.28), Vector3(-0.6 + float(j) * 0.19, yv + 0.15, 0.04),
						Mats.get_mat("fabric"), false, Vector3(0, rng.randf_range(-0.1, 0.1), 0), "pasta")


static func vent(parent: Node3D, pos: Vector3, yaw: float) -> void:
	var g := Node3D.new()
	g.position = pos
	g.rotation.y = yaw
	parent.add_child(g)
	G3D.box(g, Vector3(0.7, 0.5, 0.08), Vector3(0, 0, 0), Mats.get_mat("metal"), false, Vector3.ZERO, "grade")
	for i in 4:
		G3D.box(g, Vector3(0.6, 0.04, 0.1), Vector3(0, -0.15 + float(i) * 0.1, 0.02), Mats.get_mat("metal_rust"), false)


static func suit_rack(parent: Node3D, pos: Vector3, yaw: float, suits := 2) -> void:
	var g := Node3D.new()
	g.position = pos
	g.rotation.y = yaw
	parent.add_child(g)
	G3D.cyl(g, 0.03, 2.0, Vector3(0, 1.0, 0), Mats.get_mat("metal"))
	G3D.box(g, Vector3(1.4, 0.06, 0.06), Vector3(0, 1.95, 0), Mats.get_mat("metal"), false)
	for i in suits:
		var sv := Node3D.new()
		sv.position = Vector3(-0.55 + float(i) * 1.1, 0, 0)
		g.add_child(sv)
		G3D.box(sv, Vector3(0.5, 1.0, 0.32), Vector3(0, 1.35, 0), Mats.get_mat("fabric"), true, Vector3.ZERO, "traje")
		G3D.sphere(sv, 0.16, Vector3(0, 1.95, 0), Mats.get_mat("metal"), 12)
		G3D.box(sv, Vector3(0.16, 0.7, 0.16), Vector3(-0.32, 1.35, 0), Mats.get_mat("fabric"), false)
		G3D.box(sv, Vector3(0.16, 0.7, 0.16), Vector3(0.32, 1.35, 0), Mats.get_mat("fabric"), false)


static func stairs(parent: Node3D, x: float, z1: float, z2: float, y_low: float, y_high: float, width := 1.8) -> void:
	var steps := maxi(4, int(absf(y_high - y_low) / 0.22))
	for i in steps:
		var k := float(i + 1) / float(steps)
		var yv: float = lerpf(y_low, y_high, k)
		var zv: float = lerpf(z1, z2, k)
		G3D.box(parent, Vector3(width, yv - y_low + 0.06, absf(z2 - z1) / float(steps) + 0.04),
				Vector3(x, y_low + (yv - y_low) * 0.5 - 0.03, zv), Mats.get_mat("floor_grating"), true, Vector3.ZERO, "degrau")


static func railing(parent: Node3D, from_p: Vector3, to_p: Vector3, height := 1.05) -> void:
	var mid := (from_p + to_p) * 0.5
	var length := from_p.distance_to(to_p)
	var along_x := absf(to_p.x - from_p.x) > absf(to_p.z - from_p.z)
	var size := Vector3(length, 0.06, 0.06) if along_x else Vector3(0.06, 0.06, length)
	G3D.box(parent, size, mid + Vector3(0, height, 0), Mats.get_mat("metal"), false, Vector3.ZERO, "corrimao")
	var n := int(length / 1.6) + 1
	for i in n:
		var t := float(i) / float(n - 1) if n > 1 else 0.0
		var p := from_p.lerp(to_p, t)
		G3D.box(parent, Vector3(0.06, height, 0.06), p + Vector3(0, height * 0.5, 0), Mats.get_mat("metal"), false, Vector3.ZERO, "montante")


static var _stain_tex: Texture2D = null


static func stain(parent: Node3D, pos: Vector3, size := Vector2(1.2, 0.9), dark := true) -> void:
	var m := StandardMaterial3D.new()
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = Color(0.03, 0.04, 0.05, 0.62) if dark else Color(0.10, 0.13, 0.15, 0.50)
	m.roughness = 0.35
	# sem textura a mancha era um retângulo preto chapado (visível no CI);
	# a máscara irregular dissolve a borda no piso
	if _stain_tex == null:
		_stain_tex = ImageTexture.create_from_image(Decals._blob(128, 77, 0.8, false))
	m.albedo_texture = _stain_tex
	var mi := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = size
	mi.mesh = pm
	mi.material_override = m
	mi.position = pos + Vector3(0, 0.012, 0)
	mi.rotation.x = -PI * 0.5
	parent.add_child(mi)


static func camera_fixture(parent: Node3D, id: String, display: String, pos: Vector3, yaw: float,
		sector: String, broken := false) -> void:
	var g := Node3D.new()
	g.position = pos
	g.rotation.y = yaw
	parent.add_child(g)
	G3D.cyl(g, 0.035, 0.3, Vector3(0, 0.2, 0), Mats.get_mat("metal"))
	G3D.box(g, Vector3(0.16, 0.14, 0.3), Vector3(0, -0.02, 0.1), Mats.get_mat("wall_dark"), false, Vector3(0.12, 0, 0), "camera")
	G3D.cyl(g, 0.05, 0.1, Vector3(0, -0.02, 0.26), Mats.get_mat("rubber"), Vector3(PI * 0.5, 0, 0))
	var led := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.03, 0.03, 0.01)
	led.mesh = bm
	led.material_override = Mats.emissive(Color(1.0, 0.2, 0.15), 2.0 if not broken else 0.2)
	led.position = Vector3(0.06, 0.05, 0.22)
	g.add_child(led)
	CamGrid.add(id, display, pos, yaw, sector, 62.0, broken)


static func big_window(parent: Node3D, along_x: bool, at: float, fixed: float, y: float, w: float, h: float,
		base := 0.35) -> void:
	# moldura estrutural pesada
	var fmat := Mats.get_mat("metal")
	var t := 0.34
	if along_x:
		G3D.box(parent, Vector3(w + 0.6, t, 0.5), Vector3(at, y + base + h + t * 0.5, fixed), fmat, true, Vector3.ZERO, "viga")
		G3D.box(parent, Vector3(w + 0.6, t, 0.5), Vector3(at, y + base - t * 0.5, fixed), fmat, true, Vector3.ZERO, "viga")
		G3D.box(parent, Vector3(t, h, 0.5), Vector3(at - w * 0.5 - t * 0.5, y + base + h * 0.5, fixed), fmat, true, Vector3.ZERO, "viga")
		G3D.box(parent, Vector3(t, h, 0.5), Vector3(at + w * 0.5 + t * 0.5, y + base + h * 0.5, fixed), fmat, true, Vector3.ZERO, "viga")
		for i in int(w / 2.2):
			G3D.box(parent, Vector3(0.2, h, 0.34), Vector3(at - w * 0.5 + (float(i) + 0.5) * (w / maxf(1.0, float(int(w / 2.2)))), y + base + h * 0.5, fixed), fmat, true, Vector3.ZERO, "montante")
	else:
		G3D.box(parent, Vector3(0.5, t, w + 0.6), Vector3(fixed, y + base + h + t * 0.5, at), fmat, true, Vector3.ZERO, "viga")
		G3D.box(parent, Vector3(0.5, t, w + 0.6), Vector3(fixed, y + base - t * 0.5, at), fmat, true, Vector3.ZERO, "viga")
		G3D.box(parent, Vector3(0.5, h, t), Vector3(fixed, y + base + h * 0.5, at - w * 0.5 - t * 0.5), fmat, true, Vector3.ZERO, "viga")
		G3D.box(parent, Vector3(0.5, h, t), Vector3(fixed, y + base + h * 0.5, at + w * 0.5 + t * 0.5), fmat, true, Vector3.ZERO, "viga")
		for i in int(w / 2.2):
			G3D.box(parent, Vector3(0.34, h, 0.2), Vector3(fixed, y + base + h * 0.5, at - w * 0.5 + (float(i) + 0.5) * (w / maxf(1.0, float(int(w / 2.2))))), fmat, true, Vector3.ZERO, "montante")
	var gm := Mats.get_mat("glass")
	if along_x:
		G3D.box(parent, Vector3(w, h, 0.08), Vector3(at, y + base + h * 0.5, fixed), gm, true, Vector3.ZERO, "vidro")
	else:
		G3D.box(parent, Vector3(0.08, h, w), Vector3(fixed, y + base + h * 0.5, at), gm, true, Vector3.ZERO, "vidro")


static func sign_panel(parent: Node3D, text: String, pos: Vector3, yaw: float, w := 1.4, h := 0.34) -> void:
	var g := Node3D.new()
	g.position = pos
	g.rotation.y = yaw
	parent.add_child(g)
	G3D.box(g, Vector3(w, h, 0.04), Vector3.ZERO, Mats.emissive(Color(0.10, 0.16, 0.20), 0.35), false, Vector3.ZERO, "placa")
	G3D.label3d(g, text, Vector3(0, 0, 0.05), 0.0, 0.0045, Color(0.55, 0.85, 0.95))


static func lift(parent: Node3D, bottom: Vector3, top: Vector3, size := Vector3(3.0, 0.3, 3.0),
		call_offset := Vector3(2.4, 0.0, 0.0), nome := "MONTACARGA",
		open_dir := Vector3(-1.0, 0.0, 0.0)) -> Dictionary:
	var platform := AnimatableBody3D.new()
	platform.name = "MontaCarga"
	platform.sync_to_physics = true
	platform.position = bottom
	parent.add_child(platform)
	G3D.box(platform, size, Vector3.ZERO, Mats.get_mat("floor_grating_local"), true, Vector3.ZERO, "plataforma")
	# sem guarda-corpo: o poço é perigoso de verdade (cair = descer um convés)
	G3D.box(platform, Vector3(size.x, 0.05, size.z), Vector3(0, 0.17, 0), Mats.get_mat("hazard_local"), false, Vector3.ZERO, "faixa")
	var o := open_dir.normalized()
	var lamp := OmniLight3D.new()
	lamp.position = Vector3(0, 2.2, 0)
	lamp.light_energy = 0.30
	lamp.omni_range = 7.0
	lamp.shadow_enabled = false
	platform.add_child(lamp)
	Director.register_light(lamp)

	var payload := {"bottom": bottom, "top": top}
	var lamp_pos := Vector3(-o.x * (size.x * 0.5 - 0.5), 1.35, -o.z * (size.z * 0.5 - 0.5))
	# a área cobre a plataforma toda: quem está em cima do monta-carga alcança o painel
	var on_platform := Interactable.create("Operar monta-carga", Vector3(2.0, 1.8, 2.0), Vector3(0, 0.9, 0),
			func(_p: Node3D, _i: Interactable) -> void: Director.lift_action(platform, payload))
	platform.add_child(on_platform)

	# painéis de chamada em cada nível: pedem a plataforma PARA AQUELE nível
	for wp: Vector3 in [bottom, top]:
		var nivel := "bottom" if wp == bottom else "top"
		var posto := Node3D.new()
		posto.position = wp + call_offset + Vector3(0.0, 0.13, 0.0)
		parent.add_child(posto)
		G3D.box(posto, Vector3(0.42, 0.55, 0.16), Vector3(0, 1.25, 0), Mats.get_mat("metal_rust"), false, Vector3.ZERO, "painel")
		G3D.box(posto, Vector3(0.34, 0.06, 0.05), Vector3(0, 1.42, 0.09), Mats.get_mat("screen_amber"), false, Vector3.ZERO, "visor")
		G3D.cyl(posto, 0.05, 1.0, Vector3(0, 0.5, 0), Mats.get_mat("metal"), Vector3.ZERO, false)
		G3D.label3d(posto, nome, Vector3(0, 1.60, 0), 0.0, 0.0045, Color(0.85, 0.78, 0.55))
		var cargo := {"bottom": bottom, "top": top, "call_to": nivel}
		var painel := Interactable.create("Chamar monta-carga", Vector3(1.2, 1.4, 1.2), Vector3(0, 1.2, 0),
				func(_p: Node3D, _i: Interactable) -> void: Director.lift_action(platform, cargo))
		posto.add_child(painel)

	# guias verticais
	var altura := absf(top.y - bottom.y)
	for sx: float in [size.x * 0.5 + 0.22, -size.x * 0.5 - 0.22]:
		G3D.cyl(parent, 0.11, altura + 1.2, Vector3(bottom.x + sx, (bottom.y + top.y) * 0.5, bottom.z),
				Mats.get_mat("metal_rust"))
	return {"platform": platform, "bottom": bottom, "top": top}


static func figure(parent: Node3D, pos: Vector3, yaw: float, mat: Material, height := 1.74) -> Node3D:
	var g := Node3D.new()
	g.name = "Figura"
	g.position = pos
	g.rotation.y = yaw
	parent.add_child(g)
	var s := height / 1.74
	var torso := Node3D.new()
	g.add_child(torso)
	G3D.box(torso, Vector3(0.42 * s, 0.62 * s, 0.24 * s), Vector3(0, 1.08 * s, 0), mat, true, Vector3.ZERO, "torso")
	G3D.sphere(torso, 0.115 * s, Vector3(0, 1.52 * s, 0), mat, 12, true)
	G3D.box(torso, Vector3(0.09 * s, 0.55 * s, 0.1 * s), Vector3(-0.27 * s, 1.02 * s, 0), mat, false, Vector3(0, 0, 0.06), "braco")
	G3D.box(torso, Vector3(0.09 * s, 0.55 * s, 0.1 * s), Vector3(0.27 * s, 1.02 * s, 0), mat, false, Vector3(0, 0, -0.06), "braco")
	G3D.box(torso, Vector3(0.15 * s, 0.78 * s, 0.16 * s), Vector3(-0.11 * s, 0.38 * s, 0), mat, true, Vector3.ZERO, "perna")
	G3D.box(torso, Vector3(0.15 * s, 0.78 * s, 0.16 * s), Vector3(0.11 * s, 0.38 * s, 0), mat, true, Vector3.ZERO, "perna")
	return g


static func corridor(parent: Node3D, along_x: bool, from_v: float, to_v: float, fixed: float, y: float,
		w := 3.0, h := 3.0, opts: Dictionary = {}) -> Dictionary:
	var half := w * 0.5
	var rect := [from_v, fixed - half, to_v, fixed + half] if along_x else [fixed - half, from_v, fixed + half, to_v]
	var o := opts.duplicate()
	o["name"] = opts.get("name", "Corredor")
	o["floor"] = opts.get("floor", Mats.get_mat("floor_grating"))
	o["wall"] = opts.get("wall", Mats.get_mat("wall"))
	o["pipes"] = true
	var r := room(parent, rect[0], rect[1], rect[2], rect[3], y, h, o)
	return r
