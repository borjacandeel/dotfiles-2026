#!/usr/bin/env bash
# ============================================
#  launch.sh - Arranque de polybar
#  Dotfiles 2026 · BSPWM + Polybar + Rosé Pine
# ============================================
#
#  polybar se lanza con el nombre "bar" y lee la sección [bar/bar].
#  Este script es idempotente: se puede llamar tantas veces como haga
#  falta (bspwmrc lo llama al arrancar, Super+Q+Shift+Q para recargar).

set -uo pipefail

BAR_NAME="bar"
CONFIG="${HOME}/.config/polybar/config"
LOG="${XDG_CACHE_HOME:-${HOME}/.cache}/polybar-${BAR_NAME}.log"

# --- Sin polybar instalado: avisar y salir sin ruido -----------------
if ! command -v polybar >/dev/null 2>&1; then
    echo "launch.sh: polybar no está instalado" >&2
    exit 1
fi

if [[ ! -f "$CONFIG" ]]; then
    echo "launch.sh: no se encuentra $CONFIG" >&2
    exit 1
fi

# --- Preparar el log -------------------------------------------------
mkdir -p "$(dirname "$LOG")" 2>/dev/null

# --- Terminar instancias anteriores ---------------------------------
# pkill de procps; es más fiable que killall con procesos ya zombis.
pkill -x polybar >/dev/null 2>&1

# Esperar a que mueran del todo (máx. ~5s) para no solapar la barra
# antigua con la nueva y evitar "XCB: Invalid input" en el log.
for _ in {1..25}; do
    pgrep -x polybar >/dev/null 2>&1 || break
    sleep 0.2
done

# --- Lanzar ----------------------------------------------------------
polybar -c "$CONFIG" "$BAR_NAME" >>"$LOG" 2>&1

# Si polybar muere al instante el error está en el log: dejarlo claro.
sleep 0.3
if ! pgrep -x polybar >/dev/null 2>&1; then
    echo "launch.sh: polybar se cerró de inmediato, revisa $LOG" >&2
    tail -n 5 "$LOG" >&2 2>/dev/null
    exit 1
fi

echo "Polybar lanzado correctamente (log: $LOG)"
