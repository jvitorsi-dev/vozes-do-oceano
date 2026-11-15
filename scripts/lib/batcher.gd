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
## Galho que precisa guardar as próprias peças (sala registrada como objeto
## móvel, grupo que aparece/some inteiro): é aglutinado à parte, nunca
## absorvido pelo galho de cima.
const META_PROPRIO := "lote_proprio"
## Malha compartilhada do MeshKit: várias peças apontam para o MESMO recurso,
## então podem dividir um MultiMesh sem malha unitária.
const META_COMPARTILHADA := "compartilhada"
## Caixa chanfrada do MeshKit (guarda as próprias medidas).
const META_CAIXA := "caixa_dim"
## Altura de um convés: nunca misturar conveses no mesmo lote.
const ALTURA_CONVES := 12.0


## Funde os descendentes decorativos de `galho`. Devolve quantas peças foram
## absorvidas por MultiMesh (ou seja, quantas chamadas de desenho a menos).
##
## * a chave do lote é (tipo de malha, material, sombra, célula do espaço):
##   as dimensões vão na transformação de cada instância, então caixas de
##   tamanhos diferentes dividem o mesmo lote;
## * `celula` (metros) reparte os lotes pelo espaço, para o recorte de câmera
##   poder descartar o que está em outra ala ou outro convés;
## * `conservador` deixa de fora tudo o que pode mudar durante o jogo
##   (emissivos, transparentes, shaders) — usado na estrutura da estação.
static func aglutinar(galho: Node3D, minimo := 3, celula := 16.0, conservador := false) -> int:
	var candidatos: Array[MeshInstance3D] = []
	_coletar(galho, candidatos, conservador)
	if candidatos.size() < minimo:
		return 0
	var lotes := {}
	for mi: MeshInstance3D in candidatos:
		var chave := _chave(mi, celula)
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


static func _coletar(no: Node, saida: Array[MeshInstance3D], conservador: bool) -> void:
	for c in no.get_children():
		if not (c is Node3D):
			continue
		var n3 := c as Node3D
		if n3.get_script() != null:
			continue  # galho com comportamento: intocável
		if n3.has_meta(META_NO_BATCH) or n3.has_meta(META_PROPRIO) or not n3.visible:
			continue
		if c is CollisionObject3D or c is Light3D or c is GPUParticles3D \
				or c is MultiMeshInstance3D or c is Decal or c is Label3D:
			continue  # corpo físico (pode se mover), luz, partícula: fora
		if c is MeshInstance3D:
			var mi := c as MeshInstance3D
			if mi.get_child_count() == 0 and _serve(mi, conservador):
				saida.append(mi)
		else:
			_coletar(c, saida, conservador)


static func _serve(mi: MeshInstance3D, conservador: bool) -> bool:
	if mi.material_override == null or mi.mesh == null:
		return false
	if mi.layers != 1:
		return false
	if conservador:
		var bm := mi.material_override as BaseMaterial3D
		if bm == null:
			return false  # shader próprio (telas, oceano): pode ser trocado em jogo
		if bm.emission_enabled or bm.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED:
			return false  # lâmpadas e LEDs mudam de estado; vidro precisa de ordenação
	return _descricao(mi.mesh) != ""


## Assinatura do lote: tipo de malha + material + sombra + célula do espaço.
static func _chave(mi: MeshInstance3D, celula: float) -> String:
	var d := _descricao(mi.mesh)
	if d == "":
		return ""
	var p := mi.global_position
	var cel := maxf(celula, 1.0)
	return "%s|%d|%d|%d,%d,%d" % [d, mi.material_override.get_instance_id(), mi.cast_shadow,
			int(floor(p.x / cel)), int(floor(p.y / ALTURA_CONVES)), int(floor(p.z / cel))]


## Tipo de malha. As dimensões NÃO entram: viram escala da instância.
static func _descricao(mesh: Mesh) -> String:
	if mesh.has_meta(META_CAIXA):
		return "boxc"
	if mesh.has_meta(META_COMPARTILHADA):
		return "res:%d" % mesh.get_instance_id()
	if mesh is BoxMesh:
		return "box"
	if mesh is CylinderMesh:
		var c := mesh as CylinderMesh
		if absf(c.top_radius - c.bottom_radius) > 0.0001 or not c.cap_top or not c.cap_bottom:
			return ""  # cone: fica como está
		return "cyl:%d" % c.radial_segments
	if mesh is SphereMesh:
		var s2 := mesh as SphereMesh
		if absf(s2.radius * 2.0 - s2.height) > 0.001 or s2.is_hemisphere:
			return ""
		return "sph:%d" % s2.radial_segments
	if mesh is PlaneMesh:
		var p2 := mesh as PlaneMesh
		if p2.orientation != PlaneMesh.FACE_Y or p2.center_offset != Vector3.ZERO:
			return ""
		return "plane:%d" % p2.subdivide_width
	if mesh is PrismMesh:
		var pr := mesh as PrismMesh
		return "prism:%.2f" % pr.left_to_right
	return ""


static var _unitarias: Dictionary = {}

## Malha unitária equivalente (lado/diâmetro 1) — as dimensões vão na transformação.
static func _unitaria(desc: String, original: Mesh) -> Mesh:
	if desc.begins_with("res:"):
		return original
	if _unitarias.has(desc):
		return _unitarias[desc]
	var partes := desc.split(":")
	var tipo := partes[0]
	var m: Mesh = null
	if tipo == "boxc":
		m = MeshKit.caixa(Vector3.ONE, 0.035)
	elif tipo == "box":
		var b := BoxMesh.new()
		b.size = Vector3(1, 1, 1)
		m = b
	elif tipo == "cyl":
		var c := CylinderMesh.new()
		c.top_radius = 0.5
		c.bottom_radius = 0.5
		c.height = 1.0
		c.radial_segments = int(partes[1])
		c.rings = 1
		m = c
	elif tipo == "sph":
		var s := SphereMesh.new()
		s.radius = 0.5
		s.height = 1.0
		s.radial_segments = int(partes[1])
		s.rings = maxi(4, int(partes[1]) / 2)
		m = s
	elif tipo == "plane":
		var p := PlaneMesh.new()
		p.size = Vector2(1, 1)
		p.subdivide_width = int(partes[1])
		p.subdivide_depth = int(partes[1])
		m = p
	elif tipo == "prism":
		var pr := PrismMesh.new()
		pr.size = Vector3(1, 1, 1)
		pr.left_to_right = float(partes[1])
		m = pr
	_unitarias[desc] = m
	return m


## Escala que leva a malha unitária ao tamanho da peça original.
static func _escala(mesh: Mesh) -> Vector3:
	if mesh.has_meta(META_CAIXA):
		var dim: Vector3 = mesh.get_meta(META_CAIXA)
		return dim
	if mesh.has_meta(META_COMPARTILHADA):
		return Vector3.ONE
	if mesh is BoxMesh:
		return (mesh as BoxMesh).size
	if mesh is PrismMesh:
		return (mesh as PrismMesh).size
	if mesh is CylinderMesh:
		var c := mesh as CylinderMesh
		return Vector3(c.top_radius * 2.0, c.height, c.top_radius * 2.0)
	if mesh is SphereMesh:
		var r := (mesh as SphereMesh).radius * 2.0
		return Vector3(r, r, r)
	if mesh is PlaneMesh:
		var p := mesh as PlaneMesh
		return Vector3(p.size.x, 1.0, p.size.y)
	return Vector3.ONE


static func _fundir(destino: Node3D, base: Transform3D, chave: String, lista: Array) -> int:
	var desc := chave.split("|")[0]
	var primeiro: MeshInstance3D = lista[0]
	var base_mesh := _unitaria(desc, primeiro.mesh)
	if base_mesh == null:
		return 0
	var caixa_unit := base_mesh.get_aabb()
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = base_mesh
	mm.instance_count = lista.size()
	var inv := base.affine_inverse()
	var caixa := AABB()
	var i := 0
	for mi_v: Variant in lista:
		var mi: MeshInstance3D = mi_v
		var tr := inv * mi.global_transform
		tr = Transform3D(tr.basis * Basis.from_scale(_escala(mi.mesh)), tr.origin)
		mm.set_instance_transform(i, tr)
		var cx := tr * caixa_unit
		caixa = cx if i == 0 else caixa.merge(cx)
		i += 1
	var mmi := MultiMeshInstance3D.new()
	mmi.name = "Lote_" + desc.replace(":", "_")
	mmi.multimesh = mm
	mmi.material_override = primeiro.material_override
	mmi.cast_shadow = primeiro.cast_shadow
	mmi.gi_mode = primeiro.gi_mode
	mmi.custom_aabb = caixa.grow(0.05)
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
