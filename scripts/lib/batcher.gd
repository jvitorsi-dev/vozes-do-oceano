class_name Batcher
extends RefCounted
## Aglutinador de geometria estática.
##
## O detalhamento industrial da estação criou dezenas de milhares de malhas
## soltas (flanges, anéis de isolamento, fios de cabo, ripas de grade, rebites,
## presilhas). Renderizadas uma a uma, viram dezenas de milhares de chamadas de
## desenho por quadro — inviável num PC modesto e pior ainda no navegador.
##
## Este utilitário varre um galho da árvore e funde as malhas que compartilham
## geometria e material em MultiMeshInstance3D. O resultado é visualmente
## idêntico (mesmas peças, mesmos lugares) e custa uma chamada de desenho por
## grupo em vez de uma por peça.
##
## Regras de segurança — o aglutinador só toca no que é puramente decorativo:
##   * apenas MeshInstance3D folha (sem filhos de colisão, luz ou script);
##   * apenas primitivas simples (caixa, cilindro, esfera, plano, prisma);
##   * nada que esteja dentro de um galho com script (consoles, portas,
##     terminais, elevadores — esses mudam de aparência durante o jogo);
##   * nada marcado com meta "no_batch".
## Se a peça não se encaixa, ela fica exatamente como estava.

const META_NO_BATCH := "no_batch"

static var _dummy_unused := 0


## Funde os descendentes decorativos de `galho`. Devolve quantas peças foram
## absorvidas por MultiMesh (ou seja, quantas chamadas de desenho a menos).
static func aglutinar(galho: Node3D, minimo := 5) -> int:
	var candidatos: Array[MeshInstance3D] = []
	_coletar(galho, candidatos)
	if candidatos.size() < minimo:
		return 0
	var lotes := {}
	for mi: MeshInstance3D in candidatos:
		var chave := _chave(mi)
		if chave == "":
			continue
		if not lotes.has(chave):
			lotes[chave] = []
		( lotes[chave] as Array ).append(mi)
	var absorvidas := 0
	var base := galho.global_transform
	for chave: String in lotes.keys():
		var lista: Array = lotes[chave]
		if lista.size() < minimo:
			continue
		absorvidas += _fundir(galho, base, chave, lista)
	return absorvidas


static func _coletar(no: Node, saida: Array[MeshInstance3D]) -> void:
	for c in no.get_children():
		if c is Node3D and c.get_script() != null:
			continue  # galho com comportamento: intocável
		if c is MeshInstance3D:
			var mi := c as MeshInstance3D
			if mi.get_child_count() == 0 and _serve(mi):
				saida.append(mi)
		elif c is Node3D and not (c is Light3D) and not (c is GPUParticles3D):
			if c.has_meta(META_NO_BATCH):
				continue
			_coletar(c, saida)


static func _serve(mi: MeshInstance3D) -> bool:
	if mi.has_meta(META_NO_BATCH) or not mi.visible:
		return false
	if mi.material_override == null or mi.mesh == null:
		return false
	if mi.layers != 1:
		return false
	return _descricao(mi.mesh) != ""


## Assinatura de geometria: só peças idênticas podem compartilhar um lote.
static func _chave(mi: MeshInstance3D) -> String:
	var d := _descricao(mi.mesh)
	if d == "":
		return ""
	return "%s|%d|%d" % [d, mi.material_override.get_instance_id(), mi.cast_shadow]


static func _descricao(mesh: Mesh) -> String:
	if mesh is BoxMesh:
		var b := mesh as BoxMesh
		return "box:%.3f:%.3f:%.3f" % [b.size.x, b.size.y, b.size.z]
	if mesh is CylinderMesh:
		var c := mesh as CylinderMesh
		if absf(c.top_radius - c.bottom_radius) > 0.0001:
			return ""  # cone: fica como está
		return "cyl:%.3f:%.3f:%d" % [c.top_radius, c.height, c.radial_segments]
	if mesh is SphereMesh:
		var s2 := mesh as SphereMesh
		if absf(s2.radius * 2.0 - s2.height) > 0.001:
			return ""
		return "sph:%.3f:%d" % [s2.radius, s2.radial_segments]
	if mesh is PlaneMesh:
		var p2 := mesh as PlaneMesh
		return "plane:%.3f:%.3f:%d" % [p2.size.x, p2.size.y, p2.subdivide_width]
	if mesh is PrismMesh:
		var pr := mesh as PrismMesh
		return "prism:%.3f:%.3f:%.3f" % [pr.size.x, pr.size.y, pr.size.z]
	return ""


## Malha unitária equivalente (raio/escala 1) — as dimensões vão na transformação.
static func _unitaria(desc: String) -> Mesh:
	var partes := desc.split(":")
	var tipo := partes[0]
	if tipo == "box":
		var b := BoxMesh.new()
		b.size = Vector3(1, 1, 1)
		return b
	if tipo == "cyl":
		var c := CylinderMesh.new()
		c.top_radius = 0.5
		c.bottom_radius = 0.5
		c.height = 1.0
		c.radial_segments = int(partes[3])
		c.rings = 1
		return c
	if tipo == "sph":
		var s := SphereMesh.new()
		s.radius = 0.5
		s.height = 1.0
		s.radial_segments = int(partes[2])
		return s
	if tipo == "plane":
		var p := PlaneMesh.new()
		p.size = Vector2(1, 1)
		p.subdivide_width = int(partes[3])
		p.subdivide_depth = int(partes[3])
		return p
	if tipo == "prism":
		var pr := PrismMesh.new()
		pr.size = Vector3(1, 1, 1)
		return pr
	return null


## Escala que leva a malha unitária ao tamanho original.
static func _escala(desc: String) -> Vector3:
	var partes := desc.split(":")
	var tipo := partes[0]
	if tipo.begins_with("box") or tipo.begins_with("prism"):
		return Vector3(float(partes[1]), float(partes[2]), float(partes[3]))
	if tipo == "cyl":
		var r := float(partes[1])
		var h := float(partes[2])
		return Vector3(r * 2.0, h, r * 2.0)
	if tipo == "sph":
		var rs := float(partes[1])
		return Vector3(rs * 2.0, rs * 2.0, rs * 2.0)
	if tipo == "plane":
		return Vector3(float(partes[1]), 1.0, float(partes[2]))
	return Vector3.ONE


static func _fundir(destino: Node3D, base: Transform3D, chave: String, lista: Array) -> int:
	var desc := chave.split("|")[0]
	var base_mesh := _unitaria(desc)
	if base_mesh == null:
		return 0
	var esc := _escala(desc)
	var primeiro: MeshInstance3D = lista[0]
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = base_mesh
	mm.instance_count = lista.size()
	var inv := base.affine_inverse()
	var caixa := AABB()
	var i := 0
	for mi_v: Variant in lista:
		var mi: MeshInstance3D = mi_v
		var t := mi.global_transform
		var tr := inv * t
		var b := tr.basis
		b = b.scaled(esc)
		tr = Transform3D(b, tr.origin)
		mm.set_instance_transform(i, tr)
		var centro := inv * mi.global_position
		var raio := esc.length() * 0.5
		var cx := AABB(centro - Vector3.ONE * raio, Vector3.ONE * raio * 2.0)
		caixa = cx if i == 0 else caixa.merge(cx)
		i += 1
	var mmi := MultiMeshInstance3D.new()
	mmi.name = "Lote_" + desc
	mmi.multimesh = mm
	mmi.material_override = primeiro.material_override
	mmi.cast_shadow = primeiro.cast_shadow
	mmi.gi_mode = primeiro.gi_mode
	mmi.custom_aabb = caixa
	destino.add_child(mmi)
	for mi_v2: Variant in lista:
		var m2: MeshInstance3D = mi_v2
		m2.get_parent().remove_child(m2)
		m2.queue_free()
	return lista.size()


## Relatório curto para o modo --peso.
static func contar(no: Node) -> Dictionary:
	var r := {"malhas": 0, "lotes": 0, "multi": 0}
	for n in no.find_children("*", "MeshInstance3D", true, false):
		r["malhas"] = int(r["malhas"]) + 1
	for n2 in no.find_children("*", "MultiMeshInstance3D", true, false):
		r["lotes"] = int(r["lotes"]) + 1
		r["multi"] = int(r["multi"]) + (n2 as MultiMeshInstance3D).multimesh.instance_count
	return r
