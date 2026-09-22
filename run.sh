#!/usr/bin/env bash
# Roda o projeto pelo editor Godot 4.4 (ou pelo binário local em tools/)
set -e
cd "$(dirname "$0")"
if command -v godot >/dev/null 2>&1; then GODOT=godot
elif command -v godot4 >/dev/null 2>&1; then GODOT=godot4
elif [ -x ../tools/Godot_v4.4-stable_linux.x86_64 ]; then GODOT=../tools/Godot_v4.4-stable_linux.x86_64
else echo "Godot 4.4 não encontrado. Baixe em https://godotengine.org/download"; exit 1; fi
exec "$GODOT" --path . "$@"
