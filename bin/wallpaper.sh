#!/usr/bin/env bash
# ============================================
#  wallpaper.sh - Cambia el fondo de pantalla
#  Autor: Borja Candel
#
#  Uso:
#    wallpaper.sh              -> aleatorio
#    wallpaper.sh next         -> siguiente
#    wallpaper.sh prev         -> anterior
#    wallpaper.sh list         -> lista los fondos disponibles
#    wallpaper.sh <ruta>       -> usa una imagen concreta
# ============================================

set -uo pipefail

WALLPAPER_DIR="$HOME/.wallpapers"
FEH_BG_OPTS="--bg-fill"

# Recoge los fondos soportados, ordenados
get_wallpapers() {
    [[ -d "$WALLPAPER_DIR" ]] || return 0
    find "$WALLPAPER_DIR" -maxdepth 1 -type f \
        \( -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.webp" \) \
        2>/dev/null | sort
}

apply() {
    local img="$1"
    if ! command -v feh >/dev/null 2>&1; then
        # Sin feh: al menos ponemos un color de Rosé Pine
        command -v xsetroot >/dev/null 2>&1 && xsetroot -solid '#191724'
        echo "feh no está instalado; se usó color sólido" >&2
        return 0
    fi
    # shellcheck disable=SC2086
    feh $FEH_BG_OPTS "$img"
}

current_index() {
    local current
    current="$(feh --no-fehbg --list 2>/dev/null | awk '{print $1}' | head -n1)"
    [[ -n "$current" ]] || { echo -1; return; }
    get_wallpapers | grep -n -F "$current" | head -n1 | cut -d: -f1
}

case "${1:-random}" in
    list)
        get_wallpapers | while read -r f; do
            printf '  %s\n' "$(basename "$f")"
        done
        ;;
    next|prev)
        mapfile -t files < <(get_wallpapers)
        if [[ ${#files[@]} -eq 0 ]]; then
            echo "No hay fondos en $WALLPAPER_DIR" >&2
            exit 1
        fi
        idx="$(current_index)"
        if [[ "$idx" == "-1" || -z "$idx" ]]; then
            [[ "${1}" == "next" ]] && idx=0 || idx=$(( ${#files[@]} - 1 ))
        else
            if [[ "${1}" == "next" ]]; then
                idx=$(( (idx) % ${#files[@]} + 1 ))
            else
                idx=$(( (idx - 2 + ${#files[@]}) % ${#files[@]} + 1 ))
            fi
        fi
        apply "${files[$((idx-1))]}"
        echo "$(basename "${files[$((idx-1))]}")"
        ;;
    random)
        mapfile -t files < <(get_wallpapers)
        if [[ ${#files[@]} -eq 0 ]]; then
            echo "No hay fondos en $WALLPAPER_DIR" >&2
            exit 1
        fi
        pick="${files[RANDOM % ${#files[@]}]}"
        apply "$pick"
        echo "$(basename "$pick")"
        ;;
    -h|--help)
        sed -n '2,12p' "$0" | sed 's/^# \{0,1\}//'
        ;;
    *)
        if [[ -f "$1" ]]; then
            apply "$1"
            echo "$(basename "$1")"
        else
            echo "Uso: $(basename "$0") [next|prev|random|list|<imagen>]" >&2
            exit 1
        fi
        ;;
esac
