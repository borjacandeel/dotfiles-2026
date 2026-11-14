#!/usr/bin/env bash
# Imprime cuántas actualizaciones hay (nada si no hay ninguna, para que polybar oculte el módulo).
n=0
if command -v checkupdates >/dev/null 2>&1; then n=$(checkupdates 2>/dev/null | wc -l)
elif command -v paru >/dev/null 2>&1; then n=$(paru -Qu 2>/dev/null | wc -l)
elif command -v yay >/dev/null 2>&1; then n=$(yay -Qu 2>/dev/null | wc -l)
fi
[ "$n" -gt 0 ] && echo "$n"
exit 0
