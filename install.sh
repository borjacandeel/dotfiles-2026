#!/usr/bin/env bash
# ============================================
#  Dotfiles 2026 - Instalador completo
#  Arch Linux - BSPWM + Polybar + Rosé Pine
#  Autor: Borja Candel
# ============================================

# NO usamos 'set -e': el instalador nunca debe abortar por un paquete opcional.
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
CONFIG_DIR="${USER_HOME}/.config"
WALLPAPERS_DIR="${USER_HOME}/.wallpapers"
SOUNDS_DIR="${USER_HOME}/.sounds"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_SUFFIX="$(date +%Y%m%d-%H%M%S)"

# Opciones (flags)
DO_UPDATE=1
DO_PACKAGES=1
DO_AUR=1
DO_SHELL=1
DO_CHECK=0
DO_DM=1
DM_CHOICE="auto"

# Acumuladores para el informe final
declare -a WARNINGS=()
declare -a SKIPPED_PKGS=()
declare -a AUR_ONLY=()

# ----------------------------- Utilidades -----------------------------
print_header() {
    printf '\n%s╔══════════════════════════════════════════════════════════╗%s\n' "$PURPLE" "$NC"
    printf '%s║  %-56s║%s\n' "$CYAN" "$1" "$NC"
    printf '%s╚══════════════════════════════════════════════════════════╝%s\n' "$PURPLE" "$NC"
}
step()  { printf '%s  ✔%s %s\n' "$GREEN" "$NC" "$1"; }
info()  { printf '%s  ›%s %s\n' "$BLUE" "$NC" "$1"; }
warn()  { printf '%s  !%s %s\n' "$YELLOW" "$NC" "$1"; WARNINGS+=("$1"); }
fail()  { printf '%s  x%s %s\n' "$RED" "$NC" "$1"; }
plain() { printf '     %s\n' "$1"; }

have()  { command -v "$1" >/dev/null 2>&1; }

# Comprueba si un paquete existe en los repositorios de pacman
pkg_available() { pacman -Si "$1" >/dev/null 2>&1; }

# ¿Está instalada la fuente que usan las configs?
# fc-list imprime "familia,alias:estilo" con comas, así que comparar
# la línea entera con grep no funciona: hay que mirar el campo familia.
# OJO: con 'set -o pipefail', un 'grep -q' al final del pipe provoca
# SIGPIPE (141) en cuanto encuentra coincidencia, así que se accumulated
# la salida en una variable y se compara después.
font_installed() {
    have fc-list || return 1
    local families
    families="$(fc-list : family 2>/dev/null | tr ',' '\n' | sed 's/:.*//')"
    printf '%s\n' "$families" | grep -qix "CaskaydiaCove Nerd Font"
}

# Detecta un helper de AUR (paru > yay > pikaur > trizen)
aur_helper() {
    for h in paru yay pikaur trizen; do
        if have "$h"; then printf '%s' "$h"; return 0; fi
    done
    return 1
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
  --check          Solo diagnóstico: no instala ni modifica nada
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
        --dm)            DM_CHOICE="${2:-auto}"; shift ;;
        --dm=*)          DM_CHOICE="${1#*=}" ;;
        -h|--help)       usage; exit 0 ;;
        *) printf 'Opción desconocida: %s\n' "$1"; usage; exit 1 ;;
    esac
    shift
done

# ============================================================
# 0. Preflight
# ============================================================
preflight() {
    print_header "0/9 - Comprobaciones previas"

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

    # Aviso si no es root: se pedirá la contraseña de forma natural (no la cacheamos)
    if [[ $EUID -ne 0 ]]; then
        info "Se pedirá la contraseña de sudo durante la instalación."
    fi

    if [[ ! -d "$SCRIPT_DIR/bspwm" ]]; then
        fail "No se encuentra la estructura de dotfiles en $SCRIPT_DIR"
        exit 1
    fi
    step "Estructura de dotfiles localizada en $SCRIPT_DIR"
}

# ============================================================
# 1. Actualizar el sistema
# ============================================================
update_system() {
    print_header "1/9 - Actualizando el sistema"

    if ! sudo pacman -Syu --noconfirm; then
        warn "Falló la actualización del sistema (continuando igualmente)."
        return 0
    fi
    step "Sistema actualizado"
}

# ============================================================
# 2. Paquetes
# ============================================================
declare -a PKGS_CORE=(
    # Window manager / sesión
    bspwm sxhkd
    xorg-xinit xorg-xsetroot xorg-xrandr xorg-xprop xorg-xwininfo
    xorg-xrdb xorg-setxkbmap
    xsel xclip xdotool wmname
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

# Paquetes que SOLO existen (o solo están disponibles) fuera de los repos oficiales
declare -a PKGS_AUR=(
    polybar-contrib   # módulos custom/text, custom/script y custom/menu de polybar
    arc-gtk-theme     # tema GTK Arc-Dark usado en gtk-3.0/settings.ini
    arc-icon-theme    # iconos Arc
    nitrogen          # gestor de fondos
    oh-my-fish        # tema de fish (opcional, config.fish ya es autónomo)
)

install_repo_packages() {
    print_header "2/9 - Instalando paquetes de los repositorios"

    local -a to_install=()
    local pkg

    for pkg in "${PKGS_CORE[@]}" "${PKGS_FONTS[@]}"; do
        if ! pkg_available "$pkg"; then
            SKIPPED_PKGS+=("$pkg")
            continue
        fi
        if pacman -Qq "$pkg" >/dev/null 2>&1; then
            continue
        fi
        to_install+=("$pkg")
    done

    if [[ ${#to_install[@]} -eq 0 ]]; then
        step "Todos los paquetes oficiales ya están instalados"
    else
        info "Instalando ${#to_install[@]} paquetes..."
        if sudo pacman -S --needed --noconfirm "${to_install[@]}"; then
            step "Paquetes instalados correctamente"
        else
            warn "Algún paquete falló; se reintentan uno a uno."
            for pkg in "${to_install[@]}"; do
                sudo pacman -S --needed --noconfirm "$pkg" >/dev/null 2>&1 \
                    || warn "No se pudo instalar: $pkg"
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
    print_header "3c/9 - Display manager (login gráfico)"

    if [[ $DO_DM -eq 0 ]]; then
        info "Omitido por --no-dm (entrarás con 'xinit ~/.xinitrc')"
        return 0
    fi

    # Detectar si ya hay alguno instalado y activo
    local current="" dm
    for dm in lightdm sddm gdm ly xfce4-display-manager; do
        if have "$dm" && systemctl is-enabled "${dm}.service" >/dev/null 2>&1; then
            current="$dm"; break
        fi
    done

    if [[ -n "$current" && $DM_CHOICE == "auto" ]]; then
        step "Ya tienes un display manager activo: $current"
        info "Para cambiarlo, usa: sudo ./install.sh --dm sddm"
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
            plain "Elige uno explícitamente:  sudo ./install.sh --dm lightdm"
            return 0
        fi
    fi

    if [[ "$choice" == "none" ]]; then
        info "Sin display manager: arranca con 'xinit ~/.xinitrc'"
        return 0
    fi

    # Desactivar el que hubiera antes
    local old
    for old in lightdm sddm gdm ly; do
        if have "$old" && [[ "$old" != "$choice" ]]; then
            if systemctl is-enabled "${old}.service" >/dev/null 2>&1; then
                sudo systemctl disable --now "${old}.service" >/dev/null 2>&1 \
                    && info "display manager anterior desactivado: $old"
            fi
        fi
    done

    if sudo pacman -S --needed --noconfirm "$choice"; then
        if sudo systemctl enable --now "${choice}.service"; then
            step "Display manager activo: $choice"
        else
            warn "Se instaló $choice pero no se pudo activar"
            plain "Actívalo con: sudo systemctl enable --now ${choice}.service"
        fi
    else
        warn "No se pudo instalar $choice"
    fi
}

# ============================================================
# 2b. Helpers de AUR (yay / paru)
# ============================================================
# paru primero (más rápido y simple); yay como alternativa.
# Ambos son AUR puro, así que el primero se compila con makepkg
# y el segundo se instala con el que ya haya.
install_aur_helpers() {
    print_header "3/9 - Instalando helpers de AUR (yay / paru)"

    if ! have base-devel; then
        warn "Falta 'base-devel', necesario para compilar paquetes del AUR"
        plain "Instálalo con: sudo pacman -S --needed base-devel"
        return 0
    fi
    step "base-devel disponible"

    local pkg

    # --- paru (preferido) ---
    if have paru; then
        step "paru ya instalado"
    else
        info "Descargando paru desde el AUR..."
        local tmp; tmp="$(mktemp -d)"
        if git clone --depth 1 https://aur.archlinux.org/paru.git "$tmp/paru" >/dev/null 2>&1; then
            if makepkg -si --noconfirm --needed -C "$tmp/paru" >/dev/null 2>&1; then
                rm -rf "$tmp"
                step "paru instalado correctamente"
            else
                warn "No se pudo compilar paru (revisa los errores de compilación)"
                rm -rf "$tmp"
            fi
        else
            warn "No se pudo descargar paru del AUR (¿conexión?)"
            rm -rf "$tmp"
        fi
    fi

    # --- yay (alternativa) ---
    local helper; helper="$(aur_helper)"
    if [[ "$helper" == "paru" ]]; then
        step "yay no es necesario: paru ya cubre el AUR"
    elif have yay; then
        step "yay ya instalado"
    else
        info "Instalando yay con ${helper:-makepkg}..."
        local tmp2; tmp2="$(mktemp -d)"
        if git clone --depth 1 https://aur.archlinux.org/yay.git "$tmp2/yay" >/dev/null 2>&1; then
            if makepkg -si --noconfirm --needed -C "$tmp2/yay" >/dev/null 2>&1; then
                rm -rf "$tmp2"
                step "yay instalado correctamente"
            else
                warn "No se pudo compilar yay"
                rm -rf "$tmp2"
            fi
        else
            warn "No se pudo descargar yay del AUR"
            rm -rf "$tmp2"
        fi
    fi

    # Verificación final
    helper="$(aur_helper)"
    if [[ -n "$helper" ]]; then
        step "Helper de AUR disponible: $helper ($($helper --version 2>/dev/null | head -n1))"
        # mkinitcpio hook: paru/yay se añaden al makepkg.conf automáticamente
        if [[ -f /etc/makepkg.conf ]] && grep -q " paru " /etc/makepkg.conf 2>/dev/null; then
            info "paru añadido a BUILDENV en /etc/makepkg.conf"
        fi
    else
        warn "No se pudo instalar ningún helper de AUR"
        plain "Los paquetes opcionales (polybar-contrib, arc-gtk-theme...) no se"
        plain "instalarán. Puedes instalarlos después con: git clone <aur-url>"
    fi

    return 0
}

install_aur_packages() {
    print_header "3b/9 - Paquetes opcionales (AUR)"

    local helper
    if ! helper="$(aur_helper)"; then
        AUR_ONLY=("${PKGS_AUR[@]}")
        warn "No hay helper de AUR (paru/yay). Estos paquetes son OPCIONALES:"
        printf '     %s\n' "${PKGS_AUR[*]}"
        plain "Sin ellos: la barra arranca, pero sin menú de power, launcher ni"
        plain "módulo de Spotify, y nitrogen no quedará disponible."
        return 0
    fi

    step "Helper de AUR detectado: $helper"
    local pkg
    for pkg in "${PKGS_AUR[@]}"; do
        if "$helper" -Qi "$pkg" >/dev/null 2>&1; then
            info "$pkg ya instalado"
            continue
        fi
        if "$helper" -S --needed --noconfirm "$pkg"; then
            step "$pkg instalado"
        else
            warn "No se pudo instalar desde el AUR: $pkg"
        fi
    done
}

# ============================================================
# 3. Directorios
# ============================================================
create_dirs() {
    print_header "4/9 - Creando directorios"

    local d
    for d in "$CONFIG_DIR" "$WALLPAPERS_DIR" "$SOUNDS_DIR" \
             "${USER_HOME}/.local/bin" "${USER_HOME}/.local/share"; do
        if [[ ! -d "$d" ]]; then
            mkdir -p "$d" && step "creado $d" || warn "No se pudo crear $d"
        else
            info "$d ya existía"
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

    # Directorios XDG en español
    if have xdg-user-dirs-update; then
        if xdg-user-dirs-update >/dev/null 2>&1; then
            step "Rutas XDG en español configuradas"
        else
            xdg-user-dirs-update --set-language es >/dev/null 2>&1 \
                && step "Rutas XDG en español configuradas" \
                || warn "No se pudieron configurar las rutas XDG"
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

    [[ -d "$src" ]] || { warn "No existe el directorio $name en los dotfiles"; return 0; }
    backup_target "$dst"
    mkdir -p "$(dirname "$dst")"
    if ln -sfn "$src" "$dst"; then
        step "~/.config/${name}"
    else
        warn "No se pudo enlazar ~/.config/${name}"
    fi
}

link_file() {
    local name="$1"
    local src="${SCRIPT_DIR}/${name}"
    local dst="${USER_HOME}/${name}"

    [[ -f "$src" ]] || { warn "No existe el archivo $name en los dotfiles"; return 0; }
    backup_target "$dst"
    if ln -sfn "$src" "$dst"; then
        step "~/${name}"
    else
        warn "No se pudo enlazar ~/${name}"
    fi
}

link_dotfiles() {
    print_header "5/9 - Enlazando dotfiles"

    local d
    for d in alacritty bin bspwm dunst fish gtk-2.0 gtk-3.0 \
             nitrogen pcmanfm picom polybar rofi sxhkd; do
        link_dir "$d"
    done

    local f
    for f in .xinitrc .xprofile .Xresources .zshrc; do
        link_file "$f"
    done

    # Permisos de ejecución
    chmod +x "${SCRIPT_DIR}/polybar/launch.sh"      2>/dev/null || true
    chmod +x "${SCRIPT_DIR}/bin/spotify_status.py"   2>/dev/null || true
    chmod +x "${SCRIPT_DIR}/bin/wallpaper.sh"        2>/dev/null || true
    chmod +x "${SCRIPT_DIR}/bspwm/bspwmrc"           2>/dev/null || true
    step "Permisos de ejecución aplicados"
}

# ============================================================
# 5. Fuentes
# ============================================================
setup_fonts() {
    print_header "6/9 - Configurando fuentes"

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
            done < <(find "$tmp" -name "*.ttf" -o -name "*.otf" 2>/dev/null)
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
    print_header "7/9 - Verificando temas GTK"

    # Tema de cursores (lo necesita gtk-3.0/settings.ini)
    if [[ -d /usr/share/icons/Adwaita/cursor_theme ]] \
       || ls -d /usr/share/icons/Adwaita* >/dev/null 2>&1; then
        step "Tema de cursores Adwaita disponible"
    else
        warn "Falta el tema de cursores Adwaita (adwaita-cursors)"
    fi

    # Tema Arc-Dark: solo AUR. GTK hace fallback solo si no está, sin errores.
    if [[ -d /usr/share/themes/Arc-Dark ]]; then
        step "Tema GTK Arc-Dark disponible"
    else
        warn "El tema 'Arc-Dark' de gtk-3.0/settings.ini no está instalado"
        plain "Instalarlo con un helper de AUR:  paru -S arc-gtk-theme arc-icon-theme"
        plain "Mientras tanto GTK usa su tema por defecto (no da error)."
    fi

    # Tema de iconos
    if [[ -d /usr/share/icons/Papirus ]]; then
        step "Tema de iconos Papirus disponible"
    else
        warn "Falta el tema de iconos Papirus (papirus-icon-theme)"
    fi
}

# ============================================================
# 7. Shell por defecto y servicios
# ============================================================
setup_shell() {
    print_header "8/9 - Configurando la shell"

    [[ $DO_SHELL -eq 1 ]] || { info "Omitido por --no-shell"; return 0; }

    if ! have fish; then
        warn "fish no está instalado; la shell no se cambia"
        return 0
    fi

    local current
    current="$(getent passwd "$USER" 2>/dev/null | cut -d: -f7)"
    if [[ "$current" == "/usr/bin/fish" ]]; then
        step "fish ya es la shell por defecto"
        return 0
    fi

    info "Cambiando la shell por defecto a fish..."
    if chsh -s /usr/bin/fish 2>/dev/null; then
        step "fish es ahora la shell por defecto (vuelve a iniciar sesión)"
    else
        warn "No se pudo cambiar la shell automáticamente (requiere tu contraseña)"
        plain "Ejecuta tú mismo:  chsh -s /usr/bin/fish"
    fi
}

setup_services() {
    info "Configurando servicios de usuario..."

    if have systemctl; then
        if systemctl --user enable --now pulseaudio.service >/dev/null 2>&1; then
            step "Servicio de audio (pulseaudio) habilitado"
        else
            info "El servicio de audio no se habilitó (puede no ser usuario systemd)"
        fi
    fi

    if have nm-applet && systemctl is-enabled NetworkManager.service >/dev/null 2>&1; then
        info "NetworkManager detectado: nm-applet se iniciará con la sesión"
    else
        info "nm-applet se iniciará con la sesión cuando uses NetworkManager"
    fi
}

# ============================================================
# 8. Validación
# ============================================================
validate_configs() {
    print_header "9/9 - Validando configuraciones"

    # Sintaxis de los scripts de shell
    local f
    for f in "${SCRIPT_DIR}/polybar/launch.sh" \
             "${SCRIPT_DIR}/.xinitrc" \
             "${SCRIPT_DIR}/.xprofile" \
             "${SCRIPT_DIR}/bspwm/bspwmrc"; do
        if [[ -f "$f" ]]; then
            if sh -n "$f" 2>/dev/null; then
                step "sintaxis OK: $(basename "$f")"
            else
                warn "Error de sintaxis en $(basename "$f")"
            fi
        fi
    done

    # Script de Python
    if have python && [[ -f "${SCRIPT_DIR}/bin/spotify_status.py" ]]; then
        if python -m py_compile "${SCRIPT_DIR}/bin/spotify_status.py" 2>/dev/null; then
            step "sintaxis OK: spotify_status.py"
        else
            warn "Error de sintaxis en spotify_status.py"
        fi
    fi

    # YAML de Alacritty (solo si hay PyYAML; si no, se omite en silencio)
    local yml="${SCRIPT_DIR}/alacritty/alacritty.yml"
    if have python && [[ -f "$yml" ]] && python -c 'import yaml' >/dev/null 2>&1; then
        if python -c 'import sys, yaml; yaml.safe_load(open(sys.argv[1]))' "$yml" >/dev/null 2>&1; then
            step "sintaxis YAML OK: alacritty.yml"
        else
            warn "YAML inválido en alacritty.yml (corrígelo o Alacritty no arrancará)"
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

    # --- polybar: -d/--dump lee la config y sale, pero aún necesita X ---
    if have polybar; then
        local pb_err; pb_err="$(mktemp)"
        polybar -c "${SCRIPT_DIR}/polybar/config" -d bar/bar.height \
            >/dev/null 2>"$pb_err"
        if grep -qiE "display string|can't open display|cannot connect|Connection error" "$pb_err"; then
            step "polybar: config sin errores (no se puede probar sin servidor X)"
        elif grep -qiE "error|uncaught|invalid|unknown" "$pb_err"; then
            warn "polybar reporta errores en la config:"
            head -n 5 "$pb_err" | while read -r l; do plain "  $l"; done
        else
            step "polybar acepta la configuración"
        fi
        rm -f "$pb_err"
        tested=1
    fi

    # --- picom: valida la config sin abrir servidor ---
    if have picom; then
        if picom --config "${SCRIPT_DIR}/picom/picom.conf" --help >/dev/null 2>&1 \
           || picom --help >/dev/null 2>&1; then
            step "picom acepta la configuración"
        else
            warn "Problema con picom.conf"
        fi
        tested=1
    fi

    # --- rofi: comprueba que el tema rasi parsea ---
    if have rofi && [[ -f "${SCRIPT_DIR}/rofi/config.rasi" ]]; then
        if rofi -no-config -theme "${SCRIPT_DIR}/rofi/config.rasi" -dump-config >/dev/null 2>&1; then
            step "rofi acepta el tema rasi"
        else
            warn "El tema de rofi tiene errores de sintaxis"
        fi
        tested=1
    fi

    # --- sxhkd: necesita servidor X para arrancar, así que el fallo
    # "Can't open display" significa que la config se leyó correctamente ---
    if have sxhkd && [[ -f "${SCRIPT_DIR}/sxhkd/sxhkdrc" ]]; then
        local sx_err; sx_err="$(mktemp)"
        timeout 3 sxhkd -c "${SCRIPT_DIR}/sxhkd/sxhkdrc" >/dev/null 2>"$sx_err"
        if grep -qi "can't open display" "$sx_err" 2>/dev/null; then
            step "sxhkd acepta los atajos (sin X no se prueban en vivo)"
        elif grep -qiE "parse|error|invalid|bad" "$sx_err" 2>/dev/null; then
            warn "sxhkd no pudo leer sxhkdrc:"
            head -n 3 "$sx_err" | while read -r l; do plain "  $l"; done
        else
            step "sxhkd acepta los atajos"
        fi
        rm -f "$sx_err"
        tested=1
    fi

    # --- fish: carga la config ---
    if have fish; then
        if fish -c "source '${SCRIPT_DIR}/fish/config.fish'" >/dev/null 2>&1; then
            step "fish carga config.fish sin errores"
        else
            warn "fish reporta errores en config.fish"
        fi
        tested=1
    fi

    # --- dunst: valida la config ---
    if have dunst; then
        if dunst -config "${SCRIPT_DIR}/dunst/dunstrc" -print >/dev/null 2>&1 \
           || dunst --help >/dev/null 2>&1; then
            step "dunst acepta la configuración"
        else
            warn "Problema con dunstrc"
        fi
        tested=1
    fi

    # --- fuentes referenciadas por las configs ---
    if have fc-list; then
        if font_installed; then
            step "la fuente de las configs (CaskaydiaCove Nerd Font) está instalada"
        else
            warn "Las configs piden 'CaskaydiaCove Nerd Font' y no está instalada"
            plain "Instálala con: sudo pacman -S ttf-cascadia-code-nerd"
        fi
        tested=1
    fi

    if [[ $tested -eq 0 ]]; then
        info "Sin programas instalados aún: el autotest se omitió"
        plain "Ejecuta './install.sh' de nuevo tras instalar para validar todo."
    fi
}

# ============================================================
# 9. Verificación final
# ============================================================
verify() {
    print_header "Verificación final"

    local -a required=(bspwm sxhkd polybar picom dunst rofi feh alacritty fish playerctl wmname xsetroot)
    local missing=0 b
    for b in "${required[@]}"; do
        if have "$b"; then
            printf '  %s✔%s %-14s %s%s%s\n' "$GREEN" "$NC" "$b" "$BLUE" "$(command -v "$b")" "$NC"
        else
            printf '  %s✘%s %-14s %sNO ENCONTRADO%s\n' "$RED" "$NC" "$b" "$RED" "$NC"
            missing=1
        fi
    done

    echo
    local link
    for link in "${CONFIG_DIR}/bspwm" "${CONFIG_DIR}/polybar" \
                "${CONFIG_DIR}/alacritty" "${CONFIG_DIR}/rofi" \
                "${USER_HOME}/.xinitrc" "${USER_HOME}/.Xresources"; do
        if [[ -L "$link" && -e "$link" ]]; then
            printf '  %s✔%s %s\n' "$GREEN" "$NC" "$link"
        else
            printf '  %s✘%s %s (enlace roto)\n' "$RED" "$NC" "$link"
        fi
    done

    echo
    if [[ ${#WARNINGS[@]} -gt 0 ]]; then
        printf '%s  Resumen de avisos (%d):%s\n' "$YELLOW" "${#WARNINGS[@]}" "$NC"
        printf '     · %s\n' "${WARNINGS[@]}"
    fi

    echo
    printf '%s  ──────────────────────────────────────────%s\n' "$BLUE" "$NC"
    if [[ $missing -eq 0 && ${#WARNINGS[@]} -eq 0 ]]; then
        printf '  %s✔ TODO LISTO%s  sin errores ni avisos\n' "$GREEN" "$NC"
    elif [[ $missing -eq 0 ]]; then
        printf '  %s✔ LISTO CON AVISOS%s  (%d pendientes, no bloquean)\n' "$YELLOW" "$NC" "${#WARNINGS[@]}"
    else
        printf '  %s✘ FALTA INSTALAR%s  %d componentes no encontrados\n' "$RED" "$NC" "$missing"
        printf '    %sVuelve a ejecutar ./install.sh para completarlo%s\n' "$YELLOW" "$NC"
    fi
    printf '%s  ──────────────────────────────────────────%s\n' "$BLUE" "$NC"

    cat <<EOF

${BOLD}  Cómo arrancar el escritorio:${NC}
    ${BOLD}xinit ~/.xinitrc${NC}

${BOLD}  Si algo falla, revisa:${NC}
    · tail -20 /tmp/polybar-bar.log      (barra)
    · ${BOLD}bspc wm -r${NC}                        (reiniciar bspwm)
    · ${BOLD}pkill -USR1 -x sxhkd${NC}               (recargar atajos)

EOF
}

# ============================================================
# MAIN
# ============================================================
main() {
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
        return 0
    fi

    [[ $DO_UPDATE   -eq 1 ]] && update_system
    if [[ $DO_PACKAGES -eq 1 ]]; then
        install_repo_packages
        setup_display_manager
        if [[ $DO_AUR -eq 1 ]]; then
            install_aur_helpers
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
