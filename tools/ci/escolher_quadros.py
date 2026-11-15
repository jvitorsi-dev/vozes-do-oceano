#!/usr/bin/env python3
"""Escolhe, entre os quadros gravados por --write-movie, um quadro já assentado
de cada tomada do modo --shot e grava em JPEG (leve para versionar).

uso: escolher_quadros.py shot.log pasta_dos_quadros pasta_de_saida
"""
import glob
import os
import re
import sys

from PIL import Image

log, quadros_dir, saida = sys.argv[1:4]
os.makedirs(saida, exist_ok=True)
quadros = sorted(glob.glob(os.path.join(quadros_dir, "*.png")))
tomadas = []
for linha in open(log, errors="replace"):
    m = re.search(r"\[SHOT (\d+)\] (\S+)\s+frame=(\d+)", linha)
    if m:
        tomadas.append((int(m.group(1)), m.group(2), int(m.group(3))))
print("quadros gravados: %d, tomadas: %d" % (len(quadros), len(tomadas)))
if not quadros or not tomadas:
    sys.exit(0)
base = tomadas[0][2]
for f in glob.glob(os.path.join(saida, "*.jpg")):
    os.remove(f)
for i, (n, nome, frame) in enumerate(tomadas):
    prox = tomadas[i + 1][2] if i + 1 < len(tomadas) else frame + 12
    # três quadros antes da troca de câmera: a tomada já assentou
    idx = min(max(prox - 3 - base, 0), len(quadros) - 1)
    destino = os.path.join(saida, "%02d-%s.jpg" % (n, nome))
    Image.open(quadros[idx]).convert("RGB").save(destino, quality=88)
    print(destino, "<-", os.path.basename(quadros[idx]))
