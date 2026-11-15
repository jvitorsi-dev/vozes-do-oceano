class_name MeshKit
extends RefCounted
## Malhas próprias da estação, geradas em código e COMPARTILHADAS.
##
## Até aqui tudo era caixa e cilindro de aresta viva. Este kit acrescenta as
## formas que faltavam para o cenário parecer fabricado: caixa de aresta
## chanfrada, peças torneadas (tanques, tambores, cúpulas, flanges, isoladores),
## toro (volantes, aros de escotilha), cotovelo de tubo, perfis extrudados
## (viga I, cantoneira, calha) e tronco de pirâmide (traseira de CRT, tremonha).
##
## Regras:
##   * cada forma+parâmetros é gerada UMA vez e guardada em cache; todas as
##     peças iguais apontam para o mesmo recurso — o Batcher as funde num
##     MultiMesh (meta "compartilhada");
##   * só posição e normal: os materiais do jogo são triplanares, então não há
##     UV para esticar nem tangente para errar;
##   * triângulos no sentido horário visto de fora (convenção do Godot).

static var _cache: Dictionary = {}


## Acumulador de triângulos com orientação automática.
class Malha:
	var v := PackedVector3Array()
	var n := PackedVector3Array()

	## Triângulo de face plana. `fora` = direção aproximada para o lado de fora.
	func tri(a: Vector3, b: Vector3, c: Vector3, fora: Vector3) -> void:
		var nn := (b - a).cross(c - a)
		if nn.length_squared() < 1e-14:
			return
		nn = nn.normalized()
		if nn.dot(fora) > 0.0:
			# produto vetorial para fora = anti-horário: inverte a ordem
			v.append(a); v.append(c); v.append(b)
			n.append(nn); n.append(nn); n.append(nn)
		else:
			v.append(a); v.append(b); v.append(c)
			n.append(-nn); n.append(-nn); n.append(-nn)

	func quad(a: Vector3, b: Vector3, c: Vector3, d: Vector3, fora: Vector3) -> void:
		tri(a, b, c, fora)
		tri(a, c, d, fora)

	## Triângulo de superfície curva: normais por vértice (apontando para fora).
	func tri_n(a: Vector3, b: Vector3, c: Vector3, na: Vector3, nb: Vector3, nc: Vector3) -> void:
		var nn := (b - a).cross(c - a)
		if nn.length_squared() < 1e-14:
			return
		if nn.dot(na + nb + nc) > 0.0:
			v.append(a); v.append(c); v.append(b)
			n.append(na); n.append(nc); n.append(nb)
		else:
			v.append(a); v.append(b); v.append(c)
			n.append(na); n.append(nb); n.append(nc)

	func quad_n(a: Vector3, b: Vector3, c: Vector3, d: Vector3,
			na: Vector3, nb: Vector3, nc: Vector3, nd: Vector3) -> void:
		tri_n(a, b, c, na, nb, nc)
		tri_n(a, c, d, na, nc, nd)

	func fechar() -> ArrayMesh:
		var arr := []
		arr.resize(Mesh.ARRAY_MAX)
		arr[Mesh.ARRAY_VERTEX] = v
		arr[Mesh.ARRAY_NORMAL] = n
		var m := ArrayMesh.new()
		if v.size() >= 3:
			m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
		m.set_meta("compartilhada", true)
		return m


# ================================================================ CAIXA CHANFRADA
## Caixa com as doze arestas chanfradas (a quina pega luz, como metal dobrado).
static func caixa(size: Vector3, chanfro := 0.02) -> ArrayMesh:
	var k := "cx:%.3f:%.3f:%.3f:%.3f" % [size.x, size.y, size.z, chanfro]
	if _cache.has(k):
		return _cache[k]
	var h := size * 0.5
	var c := minf(chanfro, minf(h.x, minf(h.y, h.z)) * 0.45)
	var mb := Malha.new()
	# seis faces recuadas
	for eixo in 3:
		var u := (eixo + 1) % 3
		var w := (eixo + 2) % 3
		for s: float in [-1.0, 1.0]:
			var p: Array[Vector3] = []
			for q: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]:
				var pt := Vector3.ZERO
				pt[eixo] = s * h[eixo]
				pt[u] = q.x * (h[u] - c)
				pt[w] = q.y * (h[w] - c)
				p.append(pt)
			var fora := Vector3.ZERO
			fora[eixo] = s
			mb.quad(p[0], p[1], p[2], p[3], fora)
	# doze chanfros de aresta
	for a in 3:
		var b := (a + 1) % 3
		var t := (a + 2) % 3
		for sa: float in [-1.0, 1.0]:
			for sb: float in [-1.0, 1.0]:
				var v1a := Vector3.ZERO
				var v1b := Vector3.ZERO
				var v2a := Vector3.ZERO
				var v2b := Vector3.ZERO
				v1a[a] = sa * h[a]; v1a[b] = sb * (h[b] - c); v1a[t] = -(h[t] - c)
				v1b[a] = sa * h[a]; v1b[b] = sb * (h[b] - c); v1b[t] = (h[t] - c)
				v2a[a] = sa * (h[a] - c); v2a[b] = sb * h[b]; v2a[t] = -(h[t] - c)
				v2b[a] = sa * (h[a] - c); v2b[b] = sb * h[b]; v2b[t] = (h[t] - c)
				var fora2 := Vector3.ZERO
				fora2[a] = sa
				fora2[b] = sb
				mb.quad(v1a, v1b, v2b, v2a, fora2)
	# oito cantos
	for sx: float in [-1.0, 1.0]:
		for sy: float in [-1.0, 1.0]:
			for sz: float in [-1.0, 1.0]:
				mb.tri(Vector3(sx * h.x, sy * (h.y - c), sz * (h.z - c)),
						Vector3(sx * (h.x - c), sy * h.y, sz * (h.z - c)),
						Vector3(sx * (h.x - c), sy * (h.y - c), sz * h.z),
						Vector3(sx, sy, sz))
	var m := mb.fechar()
	# para o Batcher: caixas chanfradas de qualquer medida dividem um lote
	# (cubo chanfrado unitário + escala), como as caixas simples
	m.remove_meta("compartilhada")
	m.set_meta("caixa_dim", size)
	_cache[k] = m
	return m


# ================================================================ PEÇA TORNEADA
## Revolução de um perfil (raio, altura) em torno do eixo Y.
## O perfil é percorrido de baixo para cima pelo lado de fora; perfis fechados
## (fundo → fora → topo → dentro) geram peças ocas. `tampas` fecha as pontas
## quando o perfil não começa/termina no eixo.
static func torno(perfil: PackedVector2Array, lados := 16, tampas := true, chave := "") -> ArrayMesh:
	var k := chave
	if k == "":
		k = "tn:%d:%d" % [lados, int(tampas)]
		for p: Vector2 in perfil:
			k += ":%.3f,%.3f" % [p.x, p.y]
	else:
		k = "tn:" + k
	if _cache.has(k):
		return _cache[k]
	var mb := Malha.new()
	for i in perfil.size() - 1:
		var p0 := perfil[i]
		var p1 := perfil[i + 1]
		var d := p1 - p0
		if d.length_squared() < 1e-10:
			continue
		var n2 := Vector2(d.y, -d.x).normalized()   # normal do segmento, para fora
		for j in lados:
			var a0 := TAU * float(j) / float(lados)
			var a1 := TAU * float(j + 1) / float(lados)
			var c0 := Vector3(cos(a0), 0, sin(a0))
			var c1 := Vector3(cos(a1), 0, sin(a1))
			var n0 := Vector3(c0.x * n2.x, n2.y, c0.z * n2.x)
			var n1 := Vector3(c1.x * n2.x, n2.y, c1.z * n2.x)
			var q00 := Vector3(c0.x * p0.x, p0.y, c0.z * p0.x)
			var q01 := Vector3(c1.x * p0.x, p0.y, c1.z * p0.x)
			var q10 := Vector3(c0.x * p1.x, p1.y, c0.z * p1.x)
			var q11 := Vector3(c1.x * p1.x, p1.y, c1.z * p1.x)
			mb.quad_n(q00, q01, q11, q10, n0, n1, n1, n0)
	if tampas and perfil.size() >= 2:
		for ponta in 2:
			var p := perfil[0] if ponta == 0 else perfil[perfil.size() - 1]
			if p.x < 0.0005:
				continue
			var ny := Vector3(0, -1.0 if ponta == 0 else 1.0, 0)
			var centro := Vector3(0, p.y, 0)
			for j in lados:
				var a0 := TAU * float(j) / float(lados)
				var a1 := TAU * float(j + 1) / float(lados)
				mb.tri_n(centro, Vector3(cos(a0) * p.x, p.y, sin(a0) * p.x),
						Vector3(cos(a1) * p.x, p.y, sin(a1) * p.x), ny, ny, ny)
	var m := mb.fechar()
	_cache[k] = m
	return m


## Perfil de vaso de pressão: corpo cilíndrico com tampos abaulados.
static func perfil_vaso(raio: float, altura: float, abaulado := 0.45, cintas := 0) -> PackedVector2Array:
	var p := PackedVector2Array()
	var hc := raio * abaulado          # altura de cada tampo
	var corpo := maxf(altura - hc * 2.0, 0.05)
	var y0 := -altura * 0.5
	var passos := 5
	for i in passos + 1:
		var t := float(i) / float(passos) * PI * 0.5
		p.append(Vector2(sin(t) * raio, y0 + hc - cos(t) * hc))
	# cintas de reforço (anéis soldados)
	for cinta in cintas:
		var yc := y0 + hc + corpo * (float(cinta) + 1.0) / float(cintas + 1)
		p.append(Vector2(raio, yc - 0.03))
		p.append(Vector2(raio * 1.035 + 0.006, yc - 0.03))
		p.append(Vector2(raio * 1.035 + 0.006, yc + 0.03))
		p.append(Vector2(raio, yc + 0.03))
	for i in passos + 1:
		var t2 := (1.0 - float(i) / float(passos)) * PI * 0.5
		p.append(Vector2(sin(t2) * raio, y0 + hc + corpo + cos(t2) * hc))
	return p


# ================================================================ TORO
## Toro deitado no plano XZ (eixo Y): volantes, aros, juntas.
static func toro(raio: float, raio_tubo: float, seg := 20, lados := 8) -> ArrayMesh:
	var k := "to:%.3f:%.3f:%d:%d" % [raio, raio_tubo, seg, lados]
	if _cache.has(k):
		return _cache[k]
	var mb := Malha.new()
	for i in seg:
		var a0 := TAU * float(i) / float(seg)
		var a1 := TAU * float(i + 1) / float(seg)
		var e0 := Vector3(cos(a0), 0, sin(a0))
		var e1 := Vector3(cos(a1), 0, sin(a1))
		for j in lados:
			var f0 := TAU * float(j) / float(lados)
			var f1 := TAU * float(j + 1) / float(lados)
			var n00 := e0 * cos(f0) + Vector3.UP * sin(f0)
			var n01 := e0 * cos(f1) + Vector3.UP * sin(f1)
			var n10 := e1 * cos(f0) + Vector3.UP * sin(f0)
			var n11 := e1 * cos(f1) + Vector3.UP * sin(f1)
			mb.quad_n(e0 * raio + n00 * raio_tubo, e0 * raio + n01 * raio_tubo,
					e1 * raio + n11 * raio_tubo, e1 * raio + n10 * raio_tubo, n00, n01, n11, n10)
	var m := mb.fechar()
	_cache[k] = m
	return m


# ================================================================ COTOVELO DE TUBO
## Curva de tubo no plano XY: começa em (raio_curva, 0, 0) subindo em +Y e
## gira `angulo` radianos em torno do eixo Z (90° termina em (0, raio_curva, 0)
## apontando para -X).
static func cotovelo(raio_tubo: float, raio_curva: float, angulo := PI * 0.5, seg := 6, lados := 10) -> ArrayMesh:
	var k := "ct:%.3f:%.3f:%.3f:%d:%d" % [raio_tubo, raio_curva, angulo, seg, lados]
	if _cache.has(k):
		return _cache[k]
	var mb := Malha.new()
	for i in seg:
		var t0 := angulo * float(i) / float(seg)
		var t1 := angulo * float(i + 1) / float(seg)
		var e0 := Vector3(cos(t0), sin(t0), 0)
		var e1 := Vector3(cos(t1), sin(t1), 0)
		for j in lados:
			var f0 := TAU * float(j) / float(lados)
			var f1 := TAU * float(j + 1) / float(lados)
			var n00 := e0 * cos(f0) + Vector3.BACK * sin(f0)
			var n01 := e0 * cos(f1) + Vector3.BACK * sin(f1)
			var n10 := e1 * cos(f0) + Vector3.BACK * sin(f0)
			var n11 := e1 * cos(f1) + Vector3.BACK * sin(f1)
			mb.quad_n(e0 * raio_curva + n00 * raio_tubo, e0 * raio_curva + n01 * raio_tubo,
					e1 * raio_curva + n11 * raio_tubo, e1 * raio_curva + n10 * raio_tubo, n00, n01, n11, n10)
	var m := mb.fechar()
	_cache[k] = m
	return m


# ================================================================ PERFIL EXTRUDADO
## Extrusão de um polígono (plano XY) ao longo de Z, centrada na origem.
static func extrusao(perfil: PackedVector2Array, comprimento: float, chave := "") -> ArrayMesh:
	var k := chave
	if k == "":
		k = "ex:%.3f" % comprimento
		for p: Vector2 in perfil:
			k += ":%.3f,%.3f" % [p.x, p.y]
	else:
		k = "ex:%s:%.3f" % [chave, comprimento]
	if _cache.has(k):
		return _cache[k]
	var mb := Malha.new()
	var hz := comprimento * 0.5
	var area := 0.0
	var np := perfil.size()
	for i in np:
		var a := perfil[i]
		var b := perfil[(i + 1) % np]
		area += a.x * b.y - b.x * a.y
	var sinal := 1.0 if area > 0.0 else -1.0
	for i in np:
		var a2 := perfil[i]
		var b2 := perfil[(i + 1) % np]
		var d := b2 - a2
		if d.length_squared() < 1e-10:
			continue
		var n2 := Vector2(d.y, -d.x).normalized() * sinal
		mb.quad(Vector3(a2.x, a2.y, -hz), Vector3(b2.x, b2.y, -hz), Vector3(b2.x, b2.y, hz),
				Vector3(a2.x, a2.y, hz), Vector3(n2.x, n2.y, 0))
	var idx := Geometry2D.triangulate_polygon(perfil)
	for i in range(0, idx.size() - 2, 3):
		var p0 := perfil[idx[i]]
		var p1 := perfil[idx[i + 1]]
		var p2 := perfil[idx[i + 2]]
		mb.tri(Vector3(p0.x, p0.y, hz), Vector3(p1.x, p1.y, hz), Vector3(p2.x, p2.y, hz), Vector3.BACK)
		mb.tri(Vector3(p0.x, p0.y, -hz), Vector3(p1.x, p1.y, -hz), Vector3(p2.x, p2.y, -hz), Vector3.FORWARD)
	var m := mb.fechar()
	_cache[k] = m
	return m


## Viga em I de 1×1×1 (largura × altura × comprimento): as medidas reais vão na
## escala da instância — todas as vigas da estação dividem esta malha.
static func viga_i() -> ArrayMesh:
	var a := 0.09    # espessura da aba
	var w := 0.07    # meia-espessura da alma
	var p := PackedVector2Array([
		Vector2(-0.5, -0.5), Vector2(0.5, -0.5), Vector2(0.5, -0.5 + a), Vector2(w, -0.5 + a * 1.5),
		Vector2(w, 0.5 - a * 1.5), Vector2(0.5, 0.5 - a), Vector2(0.5, 0.5), Vector2(-0.5, 0.5),
		Vector2(-0.5, 0.5 - a), Vector2(-w, 0.5 - a * 1.5), Vector2(-w, -0.5 + a * 1.5), Vector2(-0.5, -0.5 + a),
	])
	return extrusao(p, 1.0, "viga_i")


## Perfil em U (calha / bandeja de cabos) de 1×1×1, aberto para cima.
static func calha() -> ArrayMesh:
	var e := 0.08
	var p := PackedVector2Array([
		Vector2(-0.5, -0.5), Vector2(0.5, -0.5), Vector2(0.5, 0.5), Vector2(0.5 - e, 0.5),
		Vector2(0.5 - e, -0.5 + e * 2.0), Vector2(-0.5 + e, -0.5 + e * 2.0), Vector2(-0.5 + e, 0.5), Vector2(-0.5, 0.5),
	])
	return extrusao(p, 1.0, "calha")


## Cantoneira em L de 1×1×1.
static func cantoneira() -> ArrayMesh:
	var e := 0.16
	var p := PackedVector2Array([
		Vector2(-0.5, -0.5), Vector2(0.5, -0.5), Vector2(0.5, -0.5 + e), Vector2(-0.5 + e, -0.5 + e),
		Vector2(-0.5 + e, 0.5), Vector2(-0.5, 0.5),
	])
	return extrusao(p, 1.0, "cantoneira")


# ================================================================ TRONCO
## Tronco de pirâmide de base retangular: base (x, z) em y = -altura/2, topo
## em y = +altura/2, deslocado por `desvio` (x, z). Traseira de CRT, tremonha,
## mesa inclinada de console, coifa.
static func tronco(base: Vector2, topo: Vector2, altura: float, desvio := Vector2.ZERO) -> ArrayMesh:
	var k := "tr:%.3f:%.3f:%.3f:%.3f:%.3f:%.3f:%.3f" % [base.x, base.y, topo.x, topo.y, altura, desvio.x, desvio.y]
	if _cache.has(k):
		return _cache[k]
	var hy := altura * 0.5
	var b: Array[Vector3] = []
	var t: Array[Vector3] = []
	for q: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]:
		b.append(Vector3(q.x * base.x * 0.5, -hy, q.y * base.y * 0.5))
		t.append(Vector3(q.x * topo.x * 0.5 + desvio.x, hy, q.y * topo.y * 0.5 + desvio.y))
	var mb := Malha.new()
	mb.quad(b[0], b[1], b[2], b[3], Vector3.DOWN)
	mb.quad(t[0], t[1], t[2], t[3], Vector3.UP)
	for i in 4:
		var j := (i + 1) % 4
		var meio := (b[i] + b[j] + t[i] + t[j]) * 0.25
		var centro := Vector3(desvio.x * 0.5, 0, desvio.y * 0.5)
		mb.quad(b[i], b[j], t[j], t[i], (meio - centro) * Vector3(1, 0, 1))
	var m := mb.fechar()
	_cache[k] = m
	return m
