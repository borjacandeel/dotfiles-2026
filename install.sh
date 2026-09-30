#!/usr/bin/env bash
# ============================================
#  Dotfiles 2026 - Instalador completo
#  Arch Linux - BSPWM + Polybar + Rosé Pine
#  Autor: Borja Candel
# ============================================

# NO usamos 'set -e': el instalador nunca debe abortar por un paquete
# opcional. Pero sí registramos cualquier fallo para el informe final.
set -uo pipefail

# ----------------------------- Colores -----------------------------
if [[ -t 1 ]]; then
    RED='\033[0;31m';    GREEN='\033[0;32m';  YELLOW='\033[1;33m'
    BLUE='\033[0;34m';   PURPLE='\033[0;35m'; CYAN='\033[0;36m'
    BOLD='\033[1m';      NC='\033[0m'
else
    RED=''; GREEN=''; YELLOW=''; BLUE=''; PURPLE=''; CYAN=''; BOLD=''; NC=''
fi

# ----------------------------- Variables -----------------------------
USER_HOME="${HOME}"
USER_NAME="$(id -un)"
CONFIG_DIR="${USER_HOME}/.config"
WALLPAPERS_DIR="${USER_HOME}/.wallpapers"
SOUNDS_DIR="${USER_HOME}/.sounds"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_SUFFIX="$(date +%Y%m%d-%H%M%S)"

# ----------------------------- Logging -----------------------------
# Todo lo que imprime el script (stdout+stderr) acaba también en un
# fichero. Se registra con 'tee' para poder verlo en pantalla y
# conservarlo a la vez.
LOG_DIR="${USER_HOME}/.cache/dotfiles-2026"
LOG_FILE="${LOG_DIR}/install-${BACKUP_SUFFIX}.log"
LOG_ENABLED=1
TEE_PID=""

setup_logging() {
    [[ $LOG_ENABLED -eq 1 ]] || return 0
    mkdir -p "$LOG_DIR" 2>/dev/null || { LOG_ENABLED=0; return 0; }
    : > "$LOG_FILE" 2>/dev/null || { LOG_ENABLED=0; return 0; }

    # exec > >(tee ...) redirige todo lo que escriban el script y sus
    # hijos. '2>&1' fuera del subshell captura también stderr.
    #
    # OJO: bash no espera a los procesos de sustitución al salir, así que
    # el último bloque de salida puede quedarse en el pipe sin volcar,
    # y se pierde justo el resumen final, que es lo que más interesa.
    # Por eso se guarda el PID y finish_logging espera a tee.
    exec > >(tee -a "$LOG_FILE") 2>&1
    TEE_PID=$!

    printf '\n'
    printf '══════════════════════════════════════════════════════════\n'
    printf '  Log de instalación: %s\n' "$LOG_FILE"
    printf '══════════════════════════════════════════════════════════\n\n'
}

# Cierra el pipe y espera a que tee termine de escribir el log entero.
finish_logging() {
    [[ $LOG_ENABLED -eq 1 && -n "$TEE_PID" ]] || return 0
    exec 1>&- 2>&-          # cerrar avisa a tee de que no hay más que escribir
    wait "$TEE_PID" 2>/dev/null
    TEE_PID=""
    return 0
}

# Opciones (flags)
DO_UPDATE=1
DO_PACKAGES=1
DO_AUR=1
DO_SHELL=1
DO_CHECK=0
DO_DM=1
DO_WALLPAPER=1
DM_CHOICE="auto"

# Acumuladores para el informe final
declare -a WARNINGS=()
declare -a SKIPPED_PKGS=()
declare -a AUR_ONLY=()
declare -a ERRORS=()
declare -a NOTES=()

# ----------------------------- Utilidades -----------------------------
print_header() {
    printf '\n%s╔══════════════════════════════════════════════════════════╗%s\n' "$PURPLE" "$NC"
    printf '%s║  %-56s║%s\n' "$CYAN" "$1" "$NC"
    printf '%s╚══════════════════════════════════════════════════════════╝%s\n' "$PURPLE" "$NC"
}
step()  { printf '%s  ✔%s %s\n' "$GREEN" "$NC" "$1"; }
info()  { printf '%s  ›%s %s\n' "$BLUE" "$NC" "$1"; }
warn()  { printf '%s  !%s %s\n' "$YELLOW" "$NC" "$1"; WARNINGS+=("$1"); }
fail()  { printf '%s  x%s %s\n' "$RED" "$NC" "$1"; ERRORS+=("$1"); }
note()  { printf '%s  ·%s %s\n' "$CYAN" "$NC" "$1"; NOTES+=("$1"); }
plain() { printf '     %s\n' "$1"; }

have()  { command -v "$1" >/dev/null 2>&1; }

# Comprueba si un paquete existe en los repositorios de pacman.
# Con '-q' no descarga nada, así que es rápido incluso con 90 paquetes.
pkg_available() { pacman -Si "$1" >/dev/null 2>&1; }
pkg_installed() { pacman -Qq "$1" >/dev/null 2>&1; }

# ¿Está instalada la fuente que usan las configs?
# fc-list imprime "familia,alias:estilo" con comas, así que comparar
# la línea entera con grep no funciona: hay que mirar el campo familia.
# OJO: con 'set -o pipefail', un 'grep -q' al final del pipe provoca
# SIGPIPE (141) en cuanto encuentra coincidencia, así que se acumula
# la salida en una variable y se compara después.
font_installed() {
    have fc-list || return 1
    local families
    families="$(fc-list : family 2>/dev/null | tr ',' '\n' | sed 's/:.*//')"
    # Here-string y no tubería: con 'set -o pipefail', un 'grep -q' al
    # final de un pipe devuelve 141 (SIGPIPE) en cuanto encuentra la
    # coincidencia, y el resultado seenticatoría de forma intermitente.
    grep -qixF "CaskaydiaCove Nerd Font" <<< "$families"
}

# Detecta un helper de AUR (paru > yay > pikaur > trizen)
aur_helper() {
    local h
    for h in paru yay pikaur trizen; do
        if have "$h"; then printf '%s' "$h"; return 0; fi
    done
    return 1
}

# Muestra un comando con su código de salida en el log.
# Útil para dejar constancia de qué falló exactamente.
run_logged() {
    local desc="$1"; shift
    printf '\n--- %s\n' "$desc"
    printf -- '--- $ %s\n' "$*"
    "$@"
    local rc=$?
    printf -- '--- exit=%s\n' "$rc"
    return $rc
}

usage() {
    cat <<EOF
${BOLD}Dotfiles 2026 - Instalador${NC}

Uso: ./install.sh [opciones]

  --no-update      No actualizar el sistema (pacman -Syu)
  --skip-packages  No instalar paquetes, solo enlazar configuraciones
  --no-aur         No intentar instalar paquetes del AUR
  --no-shell       No cambiar la shell por defecto a fish
  --no-dm          No configurar display manager (arranca con xinit)
  --dm <nombre>    Display manager: lightdm, sddm, gdm o none
  --no-wallpaper   No generar un fondo de pantalla por defecto
  --check          Solo diagnóstico: no instala ni modifica nada
  --no-log         No escribir el fichero de log
  --log <fichero>  Guardar el log en la ruta indicada
  -h, --help       Mostrar esta ayuda

Ejemplo:
  ./install.sh                    # instalación completa
  ./install.sh --check            # comprobar qué falta
  ./install.sh --dm sddm          # forzar un display manager
  ./install.sh --skip-packages    # solo configs
EOF
}

# ----------------------------- Flags -----------------------------
while [[ $# -gt 0 ]]; do
    case "$1" in
        --no-update)     DO_UPDATE=0 ;;
        --skip-packages) DO_PACKAGES=0 ;;
        --no-aur)        DO_AUR=0 ;;
        --no-shell)      DO_SHELL=0 ;;
        --check)         DO_CHECK=1 ;;
        --no-dm)         DO_DM=0 ;;
        --no-wallpaper)  DO_WALLPAPER=0 ;;
        --no-log)        LOG_ENABLED=0 ;;
        --log)           LOG_FILE="${2:-}"; shift ;;
        --log=*)         LOG_FILE="${1#*=}" ;;
        --dm)            DM_CHOICE="${2:-auto}"; shift ;;
        --dm=*)          DM_CHOICE="${1#*=}" ;;
        -h|--help)       usage; exit 0 ;;
        *) printf 'Opción desconocida: %s\n' "$1"; usage; exit 1 ;;
    esac
    shift
done

# Si se pasa --log <fichero>, el directorio puede ser otro.
if [[ -n "${LOG_FILE:-}" && "$LOG_FILE" != "${LOG_DIR}/install-"* ]]; then
    mkdir -p "$(dirname "$LOG_FILE")" 2>/dev/null
fi

# ============================================================
# 0. Preflight
# ============================================================
preflight() {
    print_header "0/10 - Comprobaciones previas"

    if ! have pacman; then
        fail "Este instalador requiere Arch Linux (no se encontró pacman)."
        exit 1
    fi
    step "Arch Linux detectado: $(pacman -Q pacman 2>/dev/null | awk '{print $2}')"

    if ! have sudo; then
        fail "Se necesita 'sudo' para instalar paquetes."
        exit 1
    fi
    step "sudo disponible"

    # makepkg se niega a ejecutarse como root, y con 'sudo ./install.sh'
    # el resto del script dejaría de ser un usuario normal (XDG, home...).
    # Es mucho más seguro y correcto ejecutarlo sin privileges de más.
    if [[ $EUID -eq 0 ]]; then
        fail "No ejecutes el instalador con sudo."
        plain "El propio script ya pide la contraseña con 'sudo' cuando hace falta."
        plain "Ejecuta:  ./install.sh"
        exit 1
    fi

    if [[ ! -d "$SCRIPT_DIR/bspwm" ]]; then
        fail "No se encuentra la estructura de dotfiles en $SCRIPT_DIR"
        exit 1
    fi
    step "Estructura de dotfiles localizada en $SCRIPT_DIR"

    # Validar sudo ANTES de instalar nada, y de paso cachear la credencial
    # (sudo -v) para que el resto del script no tenga que pedirla otra vez.
    # Es importante hacerlo aquí: si el usuario escribe mal la contraseña o
    # cancela el prompt, es preferible fallar al principio y no haber
    # instalado ya media sesión.
    if ! sudo -v; then
        fail "No se pudo autenticar con sudo; la instalación se cancela."
        exit 1
    fi
    step "sudo autenticado"

    # Detectar si la base de datos de pacman está descargada. Sin esto,
    # 'pacman -Si' puede fallar para todo y se omitirían paquetes sin
    # motivo aparente.
    if ! pacman -Si bash >/dev/null 2>&1; then
        note "Base de datos de pacman vacía; se sincronizará (pacman -Sy)."
        if sudo pacman -Sy >/dev/null 2>&1; then
            step "Base de datos de pacman sincronizada"
        else
            warn "No se pudo sincronizar la base de datos de pacman"
        fi
    fi
}

# ============================================================
# 1. Actualizar el sistema
# ============================================================
update_system() {
    print_header "1/10 - Actualizando el sistema"

    if run_logged "pacman -Syu" sudo pacman -Syu --noconfirm; then
        step "Sistema actualizado"
    else
        warn "Falló la actualización del sistema (continuando igualmente)."
        note "Detalle en el log: $LOG_FILE"
    fi
}

# ============================================================
# 2. Paquetes
# ============================================================
declare -a PKGS_CORE=(
    # Window manager / sesión
    bspwm sxhkd
    xorg-xinit xorg-xsetroot xorg-xrandr xorg-xprop xorg-xwininfo
    xorg-xrdb xorg-setxkbmap xorg-xdpyinfo xorg-xhost xorg-xset
    xsel xclip xdotool wmname
    # Utilidades de procesos (pgrep/pkill) y de procesos (killall),
    # usadas por bspwmrc, launch.sh y sxhkdrc
    procps-ng psmisc
    # Display manager (sesión gráfica con login)
    lightdm lightdm-gtk-greeter
    # Barra, compositor, notificaciones, launcher
    polybar picom dunst rofi feh
    # Terminal y shell
    alacritty fish
    # Escritorio
    pcmanfm lxappearance
    gtk3 papirus-icon-theme adwaita-cursors
    # Audio
    playerctl pulseaudio pulseaudio-alsa pavucontrol alsa-utils sox
    # Bandeja del sistema
    volumeicon cbatticon udiskie network-manager-applet
    # Sensores y utilidades
    lm_sensors
    xdg-user-dirs xdg-utils
    python
    # Herramientas CLI
    jq htop fastfetch tree fd ripgrep fzf bat eza zoxide starship
    git wget curl unzip tar gzip bzip2 xz zstd
    # Necesario para compilar paquetes del AUR (yay / paru)
    base-devel
)

declare -a PKGS_FONTS=(
    # Fuente principal de todo el setup (familia "CaskaydiaCove Nerd Font")
    ttf-cascadia-code-nerd
    # Fuentes Nerd Font alternativas
    ttf-nerd-fonts-symbols ttf-nerd-fonts-symbols-mono ttf-nerd-fonts-symbols-common
    # Fuentes de sistema / emoji / CJK
    noto-fonts noto-fonts-emoji noto-fonts-extra
    ttf-dejavu ttf-liberation ttf-droid ttf-roboto ttf-ubuntu-font-family
    # Iconos de sistema (nombre real: otf-, no ttf-)
    otf-font-awesome
)

# Paquetes que SOLO existen fuera de los repos oficiales.
# Nota: polybar-contrib ya NO existe en el AUR; desde polybar 3.5 los
# módulos custom/text, custom/script y custom/menu vienen en el paquete
# oficial. Comprobado con 'strings /usr/bin/polybar'.
declare -a PKGS_AUR=(
    arc-gtk-theme     # tema GTK Arc-Dark usado en gtk-3.0/settings.ini
    arc-icon-theme    # iconos Arc (alternativa a Papirus)
)

# Dependencias de compilación por paquete. Se instalan con pacman antes de
# lanzar makepkg: 'makepkg -s' intenta resolverlas él mismo, pero su
# llamada interna a 'sudo pacman' falla si no hay terminal, y además no
# queda registrada en el log.
declare -A AUR_MAKEDEPS=(
    [arc-gtk-theme]="meson sassc glib2 gdk-pixbuf2"
    [arc-icon-theme]="imagemagick"
)

# nitrogen se queda fuera a propósito: su versión del AUR (1.6.1) depende
# de gtkmm y gtk+-2.0, y ambos se retiraron de los repos de Arch, así que
# no compila. No hace falta: bspwmrc + bin/wallpaper.sh (feh) ya cambian
# el fondo, y nitrogen solo añadiría una GUI.

install_repo_packages() {
    print_header "2/10 - Instalando paquetes de los repositorios"

    local -a to_install=()
    local pkg

    for pkg in "${PKGS_CORE[@]}" "${PKGS_FONTS[@]}"; do
        if ! pkg_available "$pkg"; then
            SKIPPED_PKGS+=("$pkg")
            continue
        fi
        pkg_installed "$pkg" && continue
        to_install+=("$pkg")
    done

    if [[ ${#to_install[@]} -eq 0 ]]; then
        step "Todos los paquetes oficiales ya están instalados"
    else
        info "Instalando ${#to_install[@]} paquetes..."
        if run_logged "pacman -S (oficiales)" \
             sudo pacman -S --needed --noconfirm "${to_install[@]}"; then
            step "Paquetes instalados correctamente"
        else
            warn "Algún paquete falló; se reintentan uno a uno."
            for pkg in "${to_install[@]}"; do
                if ! sudo pacman -S --needed --noconfirm "$pkg" >/dev/null 2>&1; then
                    warn "No se pudo instalar: $pkg"
                fi
            done
        fi
    fi

    if [[ ${#SKIPPED_PKGS[@]} -gt 0 ]]; then
        info "Paquetes omitidos por no estar en los repos oficiales:"
        printf '     %s\n' "${SKIPPED_PKGS[*]}"
    fi
}

# ============================================================
# 2a. Display manager (login gráfico)
# ============================================================
# Sin un DM no hay sesión gráfica: hay que entrar por consola
# con 'startx'. El script pregunta cuál usar y lo activa.
setup_display_manager() {
    print_header "3/10 - Display manager (login gráfico)"

    if [[ $DO_DM -eq 0 ]]; then
        info "Omitido por --no-dm (entrarás con 'xinit ~/.xinitrc')"
        return 0
    fi

    # Validar el valor de --dm antes de hacer nada: sin esto, un valor
    # mal escrito intentaría instalar un paquete con ese nombre.
    case "$DM_CHOICE" in
        auto|lightdm|sddm|gdm|none) ;;
        *)
            warn "Display manager desconocido: '$DM_CHOICE'"
            plain "Valores válidos: lightdm, sddm, gdm, none, auto"
            DM_CHOICE="auto"
            ;;
    esac

    # Detectar si ya hay alguno instalado y activo
    local current="" dm
    for dm in lightdm sddm gdm ly xfce4-display-manager; do
        if have "$dm" && systemctl is-enabled "${dm}.service" >/dev/null 2>&1; then
            current="$dm"; break
        fi
    done

    if [[ -n "$current" && $DM_CHOICE == "auto" ]]; then
        step "Ya tienes un display manager activo: $current"
        info "Para cambiarlo, usa: ./install.sh --dm sddm"
        return 0
    fi

    # Elección: flag explícito, variable de entorno o pregunta
    local choice="$DM_CHOICE"
    if [[ "$choice" == "auto" ]]; then
        if [[ -t 0 ]]; then
            echo
            printf '  %s%s%s\n' "$BOLD" "¿Qué display manager quieres usar?" "$NC"
            printf '     1) lightdm  (ligero, el que usa este setup)\n'
            printf '     2) sddm     (KDE, con temas plasma)\n'
            printf '     3) gdm      (GNOME)\n'
            printf '     4) ninguno  (solo consola, uso xinit)\n'
            printf '  %sOpción [1]:%s ' "$BLUE" "$NC"
            read -r reply
            case "${reply:-1}" in
                2) choice="sddm" ;;
                3) choice="gdm" ;;
                4) choice="none" ;;
                *) choice="lightdm" ;;
            esac
        else
            # Sin terminal interactiva: no se puede preguntar
            warn "No hay terminal para preguntar; se omite el display manager"
            plain "Elige uno explícitamente:  ./install.sh --dm lightdm"
            return 0
        fi
    fi

    if [[ "$choice" == "none" ]]; then
        info "Sin display manager: arranca con 'xinit ~/.xinitrc'"
        return 0
    fi

    # Desactivar el que hubiera antes. OJO: sólo 'disable', nunca '--now'.
    # Si el DM actual está en uso, '--now' cerraría la sesión de
    # inmediato y perderías todo lo que tengas abierto.
    local old
    for old in lightdm sddm gdm ly; do
        if have "$old" && [[ "$old" != "$choice" ]] \
           && systemctl is-enabled "${old}.service" >/dev/null 2>&1; then
            if sudo systemctl disable "${old}.service" >/dev/null 2>&1; then
                info "display manager anterior desactivado (al reiniciar): $old"
            else
                warn "No se pudo desactivar el display manager anterior: $old"
            fi
        fi
    done

    if sudo pacman -S --needed --noconfirm "$choice" >/dev/null 2>&1; then
        if sudo systemctl enable "${choice}.service" >/dev/null 2>&1; then
            step "Display manager activo: $choice"
            note "Se aplicará en el próximo reinicio (o: sudo systemctl reboot)."
        else
            warn "Se instaló $choice pero no se pudo activar"
            plain "Actívalo con: sudo systemctl enable ${choice}.service"
        fi
    else
        warn "No se pudo instalar $choice"
    fi
}

# ============================================================
# 2b. Paquetes del AUR
# ============================================================
# No se instala ningún helper (paru/yay) a propósito: los helpers
# actuales son binarios que hay que compilar, y eso duplica el tiempo
# de instalación y puede fallar. makepkg ya está en base-devel, así que
# es más rápido clonar el PKGBUILD y compilar el paquete directamente.
install_aur_packages() {
    print_header "3b/10 - Paquetes opcionales (AUR)"

    # Atajos: si ya hay un helper, delegar en él es lo más rápido.
    local helper
    helper="$(aur_helper)"

    if [[ -z "$helper" ]] && ! have git; then
        AUR_ONLY=("${PKGS_AUR[@]}")
        warn "Falta 'git'; no se pueden instalar los paquetes del AUR"
        printf '     %s\n' "${PKGS_AUR[*]}"
        return 0
    fi

    if [[ -n "$helper" ]]; then
        step "Helper de AUR detectado: $helper"
    else
        step "Compilando directamente con makepkg (sin helper)"
    fi

    local pkg tmp
    for pkg in "${PKGS_AUR[@]}"; do
        # Comprobar siempre por si el paquete ha llegado a los repos
        # oficiales: entonces no hay que compilar nada.
        if ! pkg_installed "$pkg" && pkg_available "$pkg"; then
            info "$pkg ya está en los repos oficiales; se instala con pacman"
            sudo pacman -S --needed --noconfirm "$pkg" >/dev/null 2>&1 \
                && step "$pkg instalado" || warn "No se pudo instalar: $pkg"
            continue
        fi

        if pkg_installed "$pkg" \
           || { [[ -n "$helper" ]] && "$helper" -Qi "$pkg" >/dev/null 2>&1; }; then
            info "$pkg ya instalado"
            continue
        fi

        # Dependencias de compilación primero, y de forma explícita: así
        # quedan en el log y no dependen de que makepkg pueda usar sudo.
        local makedeps="${AUR_MAKEDEPS[$pkg]:-}"
        if [[ -n "$makedeps" ]]; then
            local -a need=()
            local d
            for d in $makedeps; do
                pkg_installed "$d" || need+=("$d")
            done
            if [[ ${#need[@]} -gt 0 ]]; then
                info "Dependencias de compilación para $pkg: ${need[*]}"
                if sudo pacman -S --needed --noconfirm "${need[@]}" >/dev/null 2>&1; then
                    step "Dependencias de $pkg instaladas"
                else
                    warn "Faltan dependencias para compilar $pkg (${need[*]})"
                fi
            fi
        fi

        tmp="$(mktemp -d)"
        info "Compilando $pkg..."
        if ! run_logged "AUR: $pkg" install_aur_pkg "$pkg" "$tmp"; then
            warn "No se pudo instalar desde el AUR: $pkg"
        fi
        rm -rf "$tmp"
    done

    return 0
}

# Clona y compila un paquete del AUR, e instala el binario resultante.
# Se ejecuta en su propia función para poder loguear el makepkg entero.
install_aur_pkg() {
    local pkg="$1" dir="$2"

    if ! git clone --depth 1 "https://aur.archlinux.org/${pkg}.git" "$dir/$pkg"; then
        printf 'No se pudo descargar %s del AUR (¿conexión?)\n' "$pkg" >&2
        return 1
    fi

    apply_aur_patches "$pkg" "$dir/$pkg"

    # --nodeps: las dependencias ya las instaló el script con pacman, y
    # makepkg -s intentaría resolverlas con un sudo que puede fallar.
    # --skippgpcheck: la clave pública del mantenedor casi nunca está en
    # el keyring del usuario y la verificación falla siempre. Los
    # sha256/sha512 del PKGBUILD sí se comprueban igual, así que la
    # integridad del contenido descargado no se ve afectada.
    #
    # OJO: sin la 'i'. 'makepkg -si' llama a 'sudo -k pacman -U' al final,
    # y ese '-k' invalida la credencial cacheada, así que pide la contraseña
    # otra vez aunque el usuario ya la haya dado al principio del script.
    # Compilando aquí e instalando después con el sudo del propio script se
    # evita el segundo prompt.
    if ! (cd "$dir/$pkg" && makepkg --noconfirm --needed --nodeps --skippgpcheck); then
        printf 'makepkg falló con %s\n' "$pkg" >&2
        return 1
    fi

    # Instalar los paquetes generados. Un PKGBUILD puede producir varios
    # (arc-gtk-theme genera también arc-solid-gtk-theme), así que se
    # instala todo lo .pkg.tar.* que haya salido. La extensión varía según
    # PKGEXT en makepkg.conf (.pkg.tar.zst, .pkg.tar.xz, etc.).
    local -a built=()
    local f
    for f in "$dir/$pkg"/*.pkg.tar.*; do
        [[ -f "$f" ]] && built+=("$f")
    done
    if [[ ${#built[@]} -eq 0 ]]; then
        printf 'makepkg no generó ningún paquete para %s\n' "$pkg" >&2
        return 1
    fi
    printf 'Instalando: %s\n' "${built[*]##*/}" >&2
    if ! sudo pacman -U --needed --noconfirm "${built[@]}"; then
        printf 'pacman -U falló con %s\n' "$pkg" >&2
        return 1
    fi
    return 0
}

# Parches para PKGBUILDs del AUR que están rotos con las versiones
# actuales de sus herramientas de compilación.
#
# arc-gtk-theme: el PKGBUILD compila con -Dgnome_shell_gresource=true,
# pero la regla de meson de gnome-shell llama a run_command('find', ...)
# y meson >= 1.9 falla al resolverlo como fichero de entrada
# ("File .../gnome-shell/43/icons does not exist") aunque el directorio
# exista. El tema GTK/GTK3, que es lo único que usan estos dotfiles,
# se genera igual; lo que se pierde es el recurso extra para GNOME Shell.
declare -a AUR_PATCH_SED=(
    "arc-gtk-theme|s|gnome_shell_gresource=true|gnome_shell_gresource=false|g"
    "arc-gtk-theme|s|meson --prefix=/usr build |meson setup build --prefix=/usr |g"
    "arc-gtk-theme|s|meson --prefix=/usr build-solid |meson setup build-solid --prefix=/usr |g"
)

apply_aur_patches() {
    local pkg="$1" dir="$2" rule pkgname cmd

    [[ -f "$dir/PKGBUILD" ]] || return 0

    local -a applied=()
    for rule in "${AUR_PATCH_SED[@]}"; do
        pkgname="${rule%%|*}"
        [[ "$pkgname" == "$pkg" ]] || continue
        cmd="${rule#*|}"
        # sed devuelve 0 aunque no cambie nada, así que se compara el
        # fichero antes y después para solo informar de parches reales.
        local before after
        before="$(cksum "$dir/PKGBUILD" 2>/dev/null)"
        sed -i "$cmd" "$dir/PKGBUILD" 2>/dev/null
        after="$(cksum "$dir/PKGBUILD" 2>/dev/null)"
        [[ "$before" != "$after" ]] && applied+=("${cmd%%|*}")
    done
    if [[ ${#applied[@]} -gt 0 ]]; then
        note "Parches aplicados a $pkg: ${applied[*]}"
    fi
    return 0
}

# ============================================================
# 3. Directorios
# ============================================================
create_dirs() {
    print_header "4/10 - Creando directorios"

    local d
    for d in "$CONFIG_DIR" "$WALLPAPERS_DIR" "$SOUNDS_DIR" \
             "${USER_HOME}/.local/bin" "${USER_HOME}/.local/share" \
             "${USER_HOME}/.config/xprofile.d"; do
        if [[ ! -d "$d" ]]; then
            mkdir -p "$d" && step "creado $d" || warn "No se pudo crear $d"
        fi
    done

    # Fondos de pantalla: se copian desde el repo (no se enlazan, para
    # que puedas añadir o borrar los tuyos sin tocar el repo).
    local src_wall="${SCRIPT_DIR}/.wallpapers"
    if [[ -d "$src_wall" ]] && compgen -G "${src_wall}/*" >/dev/null 2>&1; then
        local n=0 f
        for f in "$src_wall"/*; do
            [[ -f "$f" ]] || continue
            case "$f" in
                *.png|*.jpg|*.jpeg|*.webp)
                    if [[ ! -f "${WALLPAPERS_DIR}/$(basename "$f")" ]]; then
                        cp "$f" "${WALLPAPERS_DIR}/" 2>/dev/null && n=$((n+1))
                    fi
                    ;;
            esac
        done
        if [[ $n -gt 0 ]]; then
            step "$n fondos de pantalla copiados a ~/.wallpapers"
        else
            info "~/.wallpapers ya tenía todos los fondos del repo"
        fi
    else
        info "El repo no incluye fondos; ~/.wallpapers queda vacío"
        plain "Añade imágenes ahí o cambia el fondo con Super+N."
    fi

    # Generar un fondo por defecto si la carpeta sigue vacía: bspwmrc
    # usa ~/.wallpapers/bosque.png y, si no existe, un color sólido.
    if [[ $DO_WALLPAPER -eq 1 ]] \
       && ! compgen -G "${WALLPAPERS_DIR}/*" >/dev/null 2>&1 \
       && [[ -f "${SCRIPT_DIR}/bin/make_wallpaper.py" ]]; then
        if have python; then
            if python "${SCRIPT_DIR}/bin/make_wallpaper.py" \
                     "${WALLPAPERS_DIR}/rosepine.png" 1920 1080 >/dev/null 2>&1; then
                step "Fondo Rosé Pine generado en ~/.wallpapers/rosepine.png"
            else
                warn "No se pudo generar el fondo por defecto"
            fi
        else
            note "Sin python no se genera el fondo; bspwmrc usará color sólido"
        fi
    fi

    # Directorios XDG en español
    if have xdg-user-dirs-update; then
        if xdg-user-dirs-update >/dev/null 2>&1 \
           || xdg-user-dirs-update --set-language es >/dev/null 2>&1; then
            step "Rutas XDG en español configuradas"
        else
            warn "No se pudieron configurar las rutas XDG"
        fi
    fi
}

# ============================================================
# 4. Enlazar dotfiles
# ============================================================
# backup_target: mueve a un lado lo que hubiera en el destino
backup_target() {
    local target="$1"
    [[ -e "$target" || -L "$target" ]] || return 0
    if [[ -L "$target" ]]; then
        local current
        current="$(readlink -f "$target" 2>/dev/null || true)"
        if [[ -n "$current" && "$current" == "$SCRIPT_DIR"* ]]; then
            return 0   # ya apunta a nuestros dotfiles
        fi
    fi
    local backup="${target}.bak-${BACKUP_SUFFIX}"
    if mv -T "$target" "$backup" 2>/dev/null; then
        info "respaldo: $target -> $backup"
    else
        warn "No se pudo respaldar $target (continuando)"
    fi
}

link_dir() {
    local name="$1"
    local src="${SCRIPT_DIR}/${name}"
    local dst="${CONFIG_DIR}/${name}"

    [[ -d "$src" ]] || { note "El repo no incluye ${name}/; nada que enlazar"; return 0; }
    backup_target "$dst"
    mkdir -p "$(dirname "$dst")"
    if ln -sfn "$src" "$dst"; then
        step "~/.config/${name}"
    else
        fail "No se pudo enlazar ~/.config/${name}"
    fi
}

link_file() {
    local name="$1"
    local src="${SCRIPT_DIR}/${name}"
    local dst="${USER_HOME}/${name}"

    [[ -f "$src" ]] || { note "El repo no incluye ${name}; nada que enlazar"; return 0; }
    backup_target "$dst"
    if ln -sfn "$src" "$dst"; then
        step "~/${name}"
    else
        fail "No se pudo enlazar ~/${name}"
    fi
}

link_dotfiles() {
    print_header "5/10 - Enlazando dotfiles"

    local d
    for d in alacritty bin bspwm dunst fish gtk-2.0 gtk-3.0 \
             nitrogen pcmanfm picom polybar rofi sxhkd; do
        link_dir "$d"
    done

    local f
    for f in .xinitrc .xprofile .Xresources; do
        link_file "$f"
    done

    # Sesión para el greeter: sin esto, lightdm no ofrece el escritorio
    # y solo se puede entrar por consola con 'xinit ~/.xinitrc'.
    install_session_entry

    # Permisos de ejecución
    chmod +x "${SCRIPT_DIR}/polybar/launch.sh"      2>/dev/null || true
    chmod +x "${SCRIPT_DIR}/bin/spotify_status.py"   2>/dev/null || true
    chmod +x "${SCRIPT_DIR}/bin/wallpaper.sh"        2>/dev/null || true
    chmod +x "${SCRIPT_DIR}/bin/make_wallpaper.py"   2>/dev/null || true
    chmod +x "${SCRIPT_DIR}/bspwm/bspwmrc"           2>/dev/null || true
    chmod +x "${SCRIPT_DIR}/install.sh"              2>/dev/null || true
    step "Permisos de ejecución aplicados"

    # Rutas absolutas de /home/borja grabadas en las configs: se ajustan
    # al usuario actual. Sin esto, nitrogen y pcmanfm apuntan a un
    # directorio inexistente y la sesión abre siempre en la nada.
    fix_hardcoded_paths
}

# Corrige rutas absolutas de /home/<otro-usuario> en las configs que se
# enlazan tal cual. Nitrogen y pcmanfm guardan ahí la ruta de la carpeta de
# wallpapers y la última carpeta abierta; si apuntan a un home que no existe,
# esas apps abren siempre en la nada.
# Se buscan todos los /home/<algo> y se sustituyen, no solo uno en concreto:
# así funciona tanto con el repo original como con uno ya adaptado.
fix_hardcoded_paths() {
    local f changed=0
    for f in "${SCRIPT_DIR}/nitrogen/nitrogen.cfg" \
             "${SCRIPT_DIR}/nitrogen/bg-saved.cfg" \
             "${SCRIPT_DIR}/pcmanfm/default/pcmanfm.conf"; do
        [[ -f "$f" ]] || continue
        grep -qE "^[^#]*=/home/" "$f" 2>/dev/null || continue
        # OJO con el delimitador: la alternancia de sed usa '|', así que el
        # comando s no puede usar '|' como separador (rompe el patrón).
        # Se usa '#' porque no aparece ni en las claves ni en las rutas.
        local before after
        before="$(cksum "$f" 2>/dev/null)"
        sed -i -E "s#^(dirs|file|home|last_path|wall_paper)=/home/[^/;]*#\1=${USER_HOME}#g" \
            "$f" 2>/dev/null
        after="$(cksum "$f" 2>/dev/null)"
        # sed sale con 0 aunque no cambie nada, así que se compara el
        # fichero: si no cambió es que ya estaba bien y no hay que avisar.
        if [[ "$before" != "$after" ]]; then
            info "Rutas ajustadas a $USER_NAME en $(basename "$f")"
            changed=1
        fi
    done
    [[ $changed -eq 1 ]] && step "Rutas de configuración adaptadas a ${USER_HOME}"
    return 0
}

# Crea ~/.local/share/xsessions/dotfiles.desktop para que el greeter
# ofrezca este escritorio.
install_session_entry() {
    local dir="${USER_HOME}/.local/share/xsessions"
    local file="${dir}/dotfiles.desktop"

    mkdir -p "$dir" 2>/dev/null || { warn "No se pudo crear $dir"; return 0; }

    cat > "$file" <<EOF
[Desktop Entry]
Name=Dotfiles 2026 (bspwm)
Comment=Escritorio BSPWM + Polybar de los dotfiles
Exec=xinit ${USER_HOME}/.xinitrc
TryExec=${USER_HOME}/.xinitrc
Type=Application
DesktopNames=bspwm
EOF
    step "Sesión 'Dotfiles 2026' disponible en el greeter"
}

# ============================================================
# 5. Fuentes
# ============================================================
setup_fonts() {
    print_header "6/10 - Configurando fuentes"

    if ! have fc-cache; then
        warn "fontconfig no está disponible; no se puede refrescar la caché de fuentes."
        return 0
    fi

    fc-cache -f >/dev/null 2>&1 && step "Caché de fuentes regenerada" \
        || warn "fc-cache devolvió un error (no es crítico)"

    if font_installed; then
        step "Fuente principal verificada: CaskaydiaCove Nerd Font"
        return 0
    fi

    # Respaldo: descargar Nerd Fonts directamente de su GitHub oficial.
    # Útil si el paquete de Arch no está disponible en tu repositorio.
    warn "No se encuentra 'CaskaydiaCove Nerd Font'"
    if have curl || have wget; then
        info "Descargando CascadiaCode Nerd Font desde GitHub (v3.5.1)..."
        local url="https://github.com/ryanoasis/nerd-fonts/releases/download/v3.5.1/CascadiaCode.tar.xz"
        local dest="${USER_HOME}/.local/share/fonts"
        local tmp; tmp="$(mktemp -d)"
        mkdir -p "$dest"
        if have curl; then
            curl -fsSL "$url" -o "$tmp/fonts.tar.xz" 2>/dev/null
        else
            wget -q "$url" -O "$tmp/fonts.tar.xz" 2>/dev/null
        fi
        if [[ -s "$tmp/fonts.tar.xz" ]]; then
            tar -xf "$tmp/fonts.tar.xz" -C "$tmp" 2>/dev/null
            local n=0
            while IFS= read -r f; do
                cp "$f" "$dest/" && n=$((n+1))
            done < <(find "$tmp" \( -name "*.ttf" -o -name "*.otf" \) 2>/dev/null)
            rm -rf "$tmp"
            fc-cache -f >/dev/null 2>&1
            if font_installed; then
                step "CaskaydiaCove Nerd Font instalada desde GitHub ($n archivos)"
                return 0
            fi
            step "Descargados $n archivos de fuente; ejecuta 'fc-cache -f' si no aparecen"
        else
            rm -rf "$tmp"
            warn "No se pudo descargar la fuente (sin conexión?)"
            plain "Descárgala manual: $url"
        fi
    else
        plain "Instálala con: sudo pacman -S ttf-cascadia-code-nerd"
    fi
}

# ============================================================
# 6. Temas GTK
# ============================================================
setup_gtk_theme() {
    print_header "7/10 - Verificando temas GTK"

    # Tema de cursores (lo necesita gtk-3.0/settings.ini)
    if [[ -d /usr/share/icons/Adwaita/cursor_theme ]] \
       || compgen -G "/usr/share/icons/Adwaita*" >/dev/null 2>&1; then
        step "Tema de cursores Adwaita disponible"
    else
        warn "Falta el tema de cursores Adwaita (adwaita-cursors)"
    fi

    # Tema Arc-Dark: solo AUR. GTK hace fallback solo si no está, sin errores.
    if [[ -d /usr/share/themes/Arc-Dark ]]; then
        step "Tema GTK Arc-Dark disponible"
    else
        note "El tema 'Arc-Dark' de gtk-3.0/settings.ini no está instalado"
        plain "Instalarlo con: makepkg -si en git clone aur.archlinux.org/arc-gtk-theme"
        plain "Mientras tanto GTK usa su tema por defecto (no da error)."
    fi

    # Tema de iconos
    if [[ -d /usr/share/icons/Papirus ]]; then
        step "Tema de iconos Papirus disponible"
    else
        warn "Falta el tema de iconos Papirus (papirus-icon-theme)"
    fi

    # Caché de iconos: sin esto, GTK no ve los temas recién instalados.
    if have gtk-update-icon-cache; then
        gtk-update-icon-cache -f -t /usr/share/icons/Papirus >/dev/null 2>&1
        step "Caché de iconos GTK actualizada"
    fi
}

# ============================================================
# 7. Shell por defecto y servicios
# ============================================================
setup_shell() {
    print_header "8/10 - Configurando la shell"

    [[ $DO_SHELL -eq 1 ]] || { info "Omitido por --no-shell"; return 0; }

    if ! have fish; then
        warn "fish no está instalado; la shell no se cambia"
        return 0
    fi

    local current
    current="$(getent passwd "$USER_NAME" 2>/dev/null | cut -d: -f7)"
    if [[ "$current" == "/usr/bin/fish" ]]; then
        step "fish ya es la shell por defecto"
        return 0
    fi

    info "Cambiando la shell por defecto a fish..."
    # OJO: 'chsh' es setuid root y pide la contraseña del usuario por
    # TTY. En una instalación no interactiva (o sin TTY) se queda
    # esperando indefinidamente y cuelga el script entero. 'usermod -s'
    # con sudo hace lo mismo sin preguntar nada, porque root puede
    # cambiar la shell de cualquier usuario.
    if sudo usermod -s /usr/bin/fish "$USER_NAME" 2>/dev/null; then
        step "fish es ahora la shell por defecto (vuelve a iniciar sesión)"
    else
        warn "No se pudo cambiar la shell automáticamente"
        plain "Ejecuta tú mismo:  chsh -s /usr/bin/fish"
    fi
}

setup_services() {
    info "Configurando servicios de usuario..."

    # pulseaudio: solo si el usuario usa systemd como gestor de sesión.
    if ! have systemctl; then
        info "Sin systemd: los servicios se configuran a mano"
        return 0
    fi

    if ! systemctl --user is-system-running >/dev/null 2>&1; then
        info "Sin systemd de usuario activo: no se habilitan servicios"
        return 0
    fi

    if systemctl --user list-unit-files 2>/dev/null | grep -q "^pulseaudio.service"; then
        if systemctl --user enable --now pulseaudio.service >/dev/null 2>&1; then
            step "Servicio de audio (pulseaudio) habilitado"
        else
            info "El servicio de audio no se habilitó (opcional)"
        fi
    fi

    # NetworkManager: sólo tiene sentido si está activo. En un sistema
    # sin NM (conexion por otra vía) intentar arrancarlo falla siempre.
    if systemctl is-enabled NetworkManager.service >/dev/null 2>&1; then
        if have nm-applet; then
            step "NetworkManager detectado: nm-applet se iniciará con la sesión"
        fi
    else
        info "NetworkManager no está habilitado en el sistema"
        plain "nm-applet no arrancará. Habilítalo con:"
        plain "  sudo systemctl enable --now NetworkManager"
    fi
}

# ============================================================
# 8. Validación
# ============================================================
validate_configs() {
    print_header "9/10 - Validando configuraciones"

    # Sintaxis de los scripts de shell. Se usa 'sh -n' porque bspwmrc
    # tiene shebang /bin/sh; 'bash -n' dejaría pasar bashismos que
    # luego rompen en dash.
    local f
    for f in "${SCRIPT_DIR}/polybar/launch.sh" \
             "${SCRIPT_DIR}/bin/wallpaper.sh" \
             "${SCRIPT_DIR}/.xinitrc" \
             "${SCRIPT_DIR}/.xprofile" \
             "${SCRIPT_DIR}/bspwm/bspwmrc"; do
        if [[ -f "$f" ]]; then
            if sh -n "$f" 2>&1; then
                step "sintaxis OK: ${f#$SCRIPT_DIR/}"
            else
                fail "Error de sintaxis en ${f#$SCRIPT_DIR/}"
                sh -n "$f" 2>&1 | head -n 3 | while read -r l; do plain "  $l"; done
            fi
        fi
    done

    # Bash puro: launch.sh y wallpaper.sh usan arrays de bash
    for f in "${SCRIPT_DIR}/polybar/launch.sh" \
             "${SCRIPT_DIR}/bin/wallpaper.sh"; do
        [[ -f "$f" ]] || continue
        if bash -n "$f" 2>&1; then
            step "sintaxis bash OK: ${f#$SCRIPT_DIR/}"
        else
            fail "Error de sintaxis bash en ${f#$SCRIPT_DIR/}"
        fi
    done

    # Script de Python. 'py_compile' deja un __pycache__ dentro del repo
    # (ensucia git), así que se usa compile() en memoria.
    if have python && [[ -f "${SCRIPT_DIR}/bin/spotify_status.py" ]]; then
        if python -c "compile(open('${SCRIPT_DIR}/bin/spotify_status.py').read(), 'spotify_status.py', 'exec')" 2>/dev/null; then
            step "sintaxis OK: spotify_status.py"
        else
            fail "Error de sintaxis en spotify_status.py"
        fi
    fi

    # Alacritty: se valida el formato que se vaya a usar de verdad.
    # A partir de 0.13 es TOML y el YAML está deprecado, así que parsear
    # solo el .yml daría una falsa sensación de que todo está bien.
    local toml="${SCRIPT_DIR}/alacritty/alacritty.toml"
    if have python && [[ -f "$toml" ]]; then
        # 'tomllib' es de la stdlib desde Python 3.11; antes hace falta tomli.
        if python -c 'import tomllib' >/dev/null 2>&1; then
            if python -c 'import sys, tomllib; tomllib.load(open(sys.argv[1], "rb"))' \
                     "$toml" >/dev/null 2>&1; then
                step "sintaxis TOML OK: alacritty.toml"
            else
                fail "TOML inválido en alacritty.toml (Alacritty no arrancará)"
            fi
        else
            note "Sin tomllib en Python: la validación TOML se omite"
        fi
    fi

    # YAML de Alacritty, solo si hay PyYAML (compatibilidad hacia atrás)
    local yml="${SCRIPT_DIR}/alacritty/alacritty.yml"
    if have python && [[ -f "$yml" ]] && python -c 'import yaml' >/dev/null 2>&1; then
        if python -c 'import sys, yaml; yaml.safe_load(open(sys.argv[1]))' "$yml" >/dev/null 2>&1; then
            step "sintaxis YAML OK: alacritty.yml"
        else
            fail "YAML inválido en alacritty.yml (Alacritty no arrancará)"
        fi
    fi

    autotest_configs
}

# ============================================================
# 8b. Autotest: ejecutar los programas con TUS configs
# ============================================================
# Valida de verdad lo que la validación de sintaxis no puede ver:
# que los binarios acepten la configuración. Solo actúa si el
# programa está instalado.
autotest_configs() {
    print_header "Autotest de configuraciones"
    local tested=0
    local out; out="$(mktemp)"

    # --- polybar ----------------------------------------------------
    # polybar 3.7+ necesita un servidor X incluso para --dump, así que
    # se valida la config parseando el fichero directamente con grep/awk.
    if have polybar && [[ -f "${SCRIPT_DIR}/polybar/config" ]]; then
        local cfg="${SCRIPT_DIR}/polybar/config"

        # Módulos definidos: secciones [module/<nombre>]
        local -a defined=()
        while IFS= read -r m; do defined+=("$m"); done < <(
            grep -oE '^\[module/[^]]+\]' "$cfg" | sed 's/\[module\///;s/\]//'
        )

        # Módulos usados en modules-left/center/right (dentro de [bar/...])
        local -a listed=()
        while IFS= read -r m; do
            [[ -n "$m" ]] && listed+=($m)
        done < <(
            awk '/^\[bar\// { in_bar=1 } /^\[/ && !/^\[bar\// { in_bar=0 }
                 in_bar && /^[[:space:]]*modules-(left|center|right)[[:space:]]*=/ {
                     sub(/.*=[[:space:]]*/,""); print }' "$cfg"
        )

        if [[ ${#defined[@]} -eq 0 ]]; then
            fail "polybar: no se encontraron módulos en la configuración"
        else
            local orphan="" m
            for m in "${listed[@]}"; do
                printf '%s\n' "${defined[@]}" | grep -qx -- "$m" \
                    || orphan="$orphan $m"
            done
            if [[ -n "$orphan" ]]; then
                fail "polybar: módulos usados sin definir:${orphan}"
                plain "Están en modules-* pero no hay [module/<nombre>] para ellos."
            else
                step "polybar acepta la configuración (${#listed[@]} módulos, ${#defined[@]} definidos)"
            fi
        fi
        tested=1
    fi

    # --- picom ------------------------------------------------------
    # Validar de verdad: picom lee la config y solo después intenta
    # abrir el display. Sin servidor X el error esperado es
    # "Can't open display"; cualquier otra cosa es un error real.
    if have picom; then
        picom --config "${SCRIPT_DIR}/picom/picom.conf" --log-file=/dev/null >/dev/null 2>"$out"
        if grep -qE "Failed to get configuration|Config error|unknown option" "$out"; then
            fail "picom rechaza la configuración:"
            grep -E "ERROR|WARN" "$out" | head -n 5 | while read -r l; do plain "  $l"; done
        elif grep -q "Can't open display" "$out"; then
            step "picom acepta la configuración (validado sin servidor X)"
        else
            step "picom arranca sin quejarse de la configuración"
        fi
        # Avisos de opciones deprecadas: no rompen, pero se anotan
        if grep -q "is deprecated" "$out"; then
            note "picom: hay opciones deprecadas en picom.conf (no rompen nada)"
            grep "is deprecated" "$out" | head -n 3 | while read -r l; do plain "  $l"; done
        fi
        tested=1
    fi

    # --- rofi -------------------------------------------------------
    if have rofi && [[ -f "${SCRIPT_DIR}/rofi/config.rasi" ]]; then
        rofi -no-config -theme "${SCRIPT_DIR}/rofi/config.rasi" -dump-config >/dev/null 2>"$out"
        if grep -qi "failed to open display\|connection has error" "$out"; then
            step "rofi acepta el tema rasi (validado sin servidor X)"
        elif grep -qi "parse error\|parse warning\|syntax" "$out"; then
            fail "El tema de rofi tiene errores de sintaxis"
            head -n 5 "$out" | while read -r l; do plain "  $l"; done
        else
            step "rofi acepta el tema rasi"
        fi
        tested=1
    fi

    # --- sxhkd ------------------------------------------------------
    # Necesita servidor X para arrancar, así que el fallo
    # "Can't open display" significa que la config se leyó correctamente.
    if have sxhkd && [[ -f "${SCRIPT_DIR}/sxhkd/sxhkdrc" ]]; then
        timeout 3 sxhkd -c "${SCRIPT_DIR}/sxhkd/sxhkdrc" >/dev/null 2>"$out"
        if grep -qi "can't open display" "$out" 2>/dev/null; then
            step "sxhkd acepta los atajos (sin X no se prueban en vivo)"
        elif grep -qiE "parse|error|invalid|bad" "$out" 2>/dev/null; then
            fail "sxhkd no pudo leer sxhkdrc:"
            head -n 3 "$out" | while read -r l; do plain "  $l"; done
        else
            step "sxhkd acepta los atajos"
        fi
        tested=1
    fi

    # --- fish -------------------------------------------------------
    if have fish; then
        if fish -c "source '${SCRIPT_DIR}/fish/config.fish'" >/dev/null 2>"$out"; then
            step "fish carga config.fish sin errores"
        else
            fail "fish reporta errores en config.fish"
            head -n 5 "$out" | while read -r l; do plain "  $l"; done
        fi
        tested=1
    fi

    # --- dunst ------------------------------------------------------
    # dunst valida la config al arrancar. Sin display notifica que no
    # puede abrirlo, lo cual implica que la config se leyó bien.
    if have dunst; then
        dunst -config "${SCRIPT_DIR}/dunst/dunstrc" -print >/dev/null 2>"$out"
        if grep -qE "doesn't exist|deprecated" "$out"; then
            note "dunst: la config usa claves obsoletas (ver log)"
            grep -E "doesn't exist|deprecated" "$out" | head -n 3 | while read -r l; do plain "  $l"; done
        else
            step "dunst acepta la configuración"
        fi
        tested=1
    fi

    # --- alacritty --------------------------------------------------
    # Alacritty valida la config al cargarla; sólo necesita X después.
    local alc_toml="${SCRIPT_DIR}/alacritty/alacritty.toml"
    local alc_yml="${SCRIPT_DIR}/alacritty/alacritty.yml"
    if have alacritty; then
        if [[ -f "$alc_toml" ]]; then
            alacritty --config-file "$alc_toml" -e true >/dev/null 2>"$out"
            if [[ $? -eq 0 ]]; then
                step "alacritty acepta alacritty.toml"
            elif grep -qi "DISPLAY\|WAYLAND\|display is not set\|display.*not.*set\|not.*set.*display" "$out"; then
                step "alacritty acepta alacritty.toml (sin display para probar)"
            else
                fail "alacritty rechaza alacritty.toml:"
                head -n 5 "$out" | while read -r l; do plain "  $l"; done
            fi
        elif [[ -f "$alc_yml" ]]; then
            alacritty --config-file "$alc_yml" -e true >/dev/null 2>"$out"
            if [[ $? -eq 0 ]]; then
                step "alacritty acepta alacritty.yml"
            elif grep -qi "DISPLAY\|WAYLAND\|display is not set" "$out"; then
                step "alacritty acepta alacritty.yml (sin display para probar)"
            else
                fail "alacritty rechaza alacritty.yml:"
                head -n 5 "$out" | while read -r l; do plain "  $l"; done
            fi
        fi
        tested=1
    fi

    # --- fuentes referenciadas por las configs ----------------------
    if have fc-list; then
        if font_installed; then
            step "la fuente de las configs (CaskaydiaCove Nerd Font) está instalada"
        else
            fail "Las configs piden 'CaskaydiaCove Nerd Font' y no está instalada"
            plain "Instálala con: sudo pacman -S ttf-cascadia-code-nerd"
        fi
        tested=1
    fi

    rm -f "$out"

    if [[ $tested -eq 0 ]]; then
        info "Sin programas instalados aún: el autotest se omitió"
        plain "Ejecuta './install.sh' de nuevo tras instalar para validar todo."
    fi
}

# ============================================================
# 9. Verificación final
# ============================================================
verify() {
    print_header "10/10 - Verificación final"

    # Duplicados eliminados a propósito (feh estaba dos veces).
    local -a required=(
        bspwm sxhkd polybar picom dunst rofi feh alacritty fish
        playerctl wmname xsetroot xrdb xrandr xdotool
        pavucontrol volumeicon cbatticon udiskie lxappearance pcmanfm
    )
    local missing=0 b
    for b in "${required[@]}"; do
        if have "$b"; then
            printf '  %s✔%s %-14s %s%s%s\n' "$GREEN" "$NC" "$b" "$BLUE" "$(command -v "$b")" "$NC"
        else
            printf '  %s✘%s %-14s %sNO ENCONTRADO%s\n' "$RED" "$NC" "$b" "$RED" "$NC"
            missing=$((missing+1))
        fi
    done

    echo
    # En modo --check los enlaces aún no existen: no es un error, así que
    # solo se informa de los que faltan sin contarlos como fallo.
    local -a links=(
        "${CONFIG_DIR}/bspwm" "${CONFIG_DIR}/polybar"
        "${CONFIG_DIR}/alacritty" "${CONFIG_DIR}/rofi"
        "${CONFIG_DIR}/dunst" "${CONFIG_DIR}/picom"
        "${CONFIG_DIR}/sxhkd" "${CONFIG_DIR}/bin"
        "${USER_HOME}/.xinitrc" "${USER_HOME}/.xprofile"
        "${USER_HOME}/.Xresources"
    )
    local link
    for link in "${links[@]}"; do
        if [[ -L "$link" && -e "$link" ]]; then
            printf '  %s✔%s %s\n' "$GREEN" "$NC" "$link"
        elif [[ $DO_CHECK -eq 1 ]]; then
            printf '  %s·%s %s %s(aún sin enlazar)%s\n' "$CYAN" "$NC" "$link" "$CYAN" "$NC"
        else
            printf '  %s✘%s %s %s(enlace roto)%s\n' "$RED" "$NC" "$link" "$RED" "$NC"
        fi
    done

    echo
    if [[ ${#ERRORS[@]} -gt 0 ]]; then
        printf '%s  Errores (%d):%s\n' "$RED" "${#ERRORS[@]}" "$NC"
        printf '     · %s\n' "${ERRORS[@]}"
    fi
    if [[ ${#WARNINGS[@]} -gt 0 ]]; then
        printf '%s  Resumen de avisos (%d):%s\n' "$YELLOW" "${#WARNINGS[@]}" "$NC"
        printf '     · %s\n' "${WARNINGS[@]}"
    fi
    if [[ ${#NOTES[@]} -gt 0 ]]; then
        printf '%s  Notas informativas (%d):%s\n' "$CYAN" "${#NOTES[@]}" "$NC"
        printf '     · %s\n' "${NOTES[@]}"
    fi

    echo
    printf '%s  ──────────────────────────────────────────%s\n' "$BLUE" "$NC"
    if [[ $missing -eq 0 && ${#ERRORS[@]} -eq 0 && ${#WARNINGS[@]} -eq 0 ]]; then
        printf '  %s✔ TODO LISTO%s  sin errores ni avisos\n' "$GREEN" "$NC"
    elif [[ $missing -eq 0 && ${#ERRORS[@]} -eq 0 ]]; then
        printf '  %s✔ LISTO CON AVISOS%s  (%d pendientes, no bloquean)\n' "$YELLOW" "$NC" "${#WARNINGS[@]}"
    else
        printf '  %s✘ HAY ERRORES QUE REVISAR%s  %d componentes no encontrados, %d errores\n' \
               "$RED" "$NC" "$missing" "${#ERRORS[@]}"
        printf '    %sConsulta el log:  %s%s\n' "$YELLOW" "$LOG_FILE" "$NC"
    fi
    if [[ $LOG_ENABLED -eq 1 ]]; then
        printf '  %sLog completo:  %s%s\n' "$BLUE" "$LOG_FILE" "$NC"
    fi
    printf '%s  ──────────────────────────────────────────%s\n' "$BLUE" "$NC"

    cat <<EOF

${BOLD}  Cómo arrancar el escritorio:${NC}
    ${BOLD}xinit ~/.xinitrc${NC}   (desde consola)
    o elegir "Dotfiles 2026" en el greeter del display manager

${BOLD}  Si algo falla, revisa:${NC}
    · ${BOLD}grep -iE 'error|warn' ${LOG_FILE}${NC}  (instalación)
    · tail -20 ~/.cache/polybar-bar.log             (barra)
    · ${BOLD}bspc wm -r${NC}                                 (reiniciar bspwm)
    · ${BOLD}pkill -USR1 -x sxhkd${NC}                        (recargar atajos)

EOF

    # Código de salida útil para scripts y para CI
    if [[ $missing -gt 0 || ${#ERRORS[@]} -gt 0 ]]; then
        return 1
    fi
    return 0
}

# ============================================================
# MAIN
# ============================================================
main() {
    setup_logging

    printf '%s' "$PURPLE"
    cat <<'BANNER'
   ____        _        _____         _
  / __ \      | |      |___ /        | |
 | |  | |_ __ | |_   ___| | __ _ _ __| |_ ___  _ __
 | |  | | '_ \| __| / __| |/ _` | '__| __/ _ \| '_ \
 | |__| | |_) | |_  \__ \ | (_| | |  | ||  __/ | | | |
  \____/| .__/ \__| |___/_|\__,_|_|  \__\___|_| |_|
       |_|            2026 · Rosé Pine
BANNER
    printf '%s' "$NC"
    printf '  %sDotfiles 2026%s · %s%s%s\n\n' "$BOLD" "$NC" "$BLUE" "$SCRIPT_DIR" "$NC"

    preflight

    # Modo --check: solo diagnóstico, no cambia nada del sistema
    if [[ $DO_CHECK -eq 1 ]]; then
        print_header "Modo comprobación (no modifica nada)"
        info "Validando dotfiles y programas ya instalados..."
        echo
        validate_configs
        verify
        return $?
    fi

    [[ $DO_UPDATE -eq 1 ]] && update_system
    if [[ $DO_PACKAGES -eq 1 ]]; then
        install_repo_packages
        setup_display_manager
        if [[ $DO_AUR -eq 1 ]]; then
            install_aur_packages
        else
            info "Omitida la instalación de AUR (--no-aur)"
        fi
    else
        info "Omitida la instalación de paquetes (--skip-packages)"
    fi
    create_dirs
    link_dotfiles
    setup_fonts
    setup_gtk_theme
    setup_shell
    setup_services
    validate_configs
    verify
}

main "$@"
rc=$?

# Volcar el log antes de salir: sin esto, bash abandona el proceso
# sustitución sin esperar y se pierde el final de la salida.
finish_logging

exit $rc
