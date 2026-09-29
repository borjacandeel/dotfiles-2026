<div align="center">

# 🪵 Dotfiles 2026

### BSPWM + Polybar + Rosé Pine para Arch Linux

[![Arch](https://img.shields.io/badge/Arch_Linux-1793D1?style=for-the-badge&logo=arch-linux&logoColor=white)](https://archlinux.org)
[![BSPWM](https://img.shields.io/badge/BSPWM-2D2D2D?style=for-the-badge&logo=linux&logoColor=white)](https://github.com/baskerville/bspwm)
[![Polybar](https://img.shields.io/badge/Polybar-FF6B6B?style=for-the-badge&logo=polybar&logoColor=white)](https://github.com/polybar/polybar)
[![Rocíe Pine](https://img.shields.io/badge/Ros%C3%A9_Pine-EBBCBA?style=for-the-badge&logo=rosepine&logoColor=black)](https://rosepinetheme.com)
[![Licencia](https://img.shields.io/badge/Licencia-MIT-3178C6?style=for-the-badge)](LICENSE)

**por [Borja Candel](https://borjacandeel.github.io)**

</div>

---

## 📸 Vista previa

<div align="center">

![Escritorio BSPWM con Polybar y tema Rosé Pine](https://i.ibb.co/dbRt8qC/2021-11-06-192234-1920x1080-scrot.png)

*BSPWM con Polybar, tema Rosé Pine y CaskaydiaCove Nerd Font*

</div>

---

## 📑 Índice

- [Características](#-características)
- [Instalación](#-instalación)
  - [Opciones del instalador](#opciones-del-instalador)
  - [Panel de ayuda](#panel-de-ayuda-)
  - [Qué hace paso a paso](#-qué-hace-paso-a-paso)
  - [Verificar la instalación](#verificar-la-instalación)
- [Desinstalación](#-desinstalación)
- [Estructura del repo](#-estructura-del-repo)
- [Atajos de teclado](#-atajos-de-teclado)
- [Dependencias](#-dependencias)
- [Wallpapers](#-wallpapers)
- [Personalización](#-personalización)
- [Solución de problemas](#-solución-de-problemas)
- [Licencia](#-licencia)

---

## ✨ Características

| Componente | Herramienta | Detalles |
|---|---|---|
| **Window manager** | `bspwm` | 10 escritorios, gaps, focus-follows-mouse, layouts tiled/monocle |
| **Atajos** | `sxhkd` | Recarga en caliente, window rules por app |
| **Barra** | `polybar` | Workspaces, reloj, volumen, temperatura, batería, menú power, Spotify |
| **Tema** | **Rosé Pine** | Colores unificados en barra, terminal, rofi, dunst, ventanas y GTK |
| **Terminal** | `alacritty` | Opacidad, fuente Nerd Font, atajos de copia/pegado |
| **Shell** | `fish` + `starship` | Alias, `zoxide`, autocompletado, prompt rápido |
| **Compositor** | `picom` | Blur, sombras suaves, esquinas redondeadas, opacidad |
| **Notificaciones** | `dunst` | Iconos Papirus, historial,-ops categories |
| **Launcher** | `rofi` | Apps, comandos y ventanas con estilo Rosé Pine |
| **Archivos** | `pcmanfm` | Terminal y fuente Nerd Font configurados |
| **Fondos** | `feh` | 7 wallpapers incluidos, rotación con atajos |
| **Fuentes** | CaskaydiaCove | Nerd Font + símbolos extras |

---

## 🚀 Instalación

### Requisitos

- **Arch Linux** (o derivado con `pacman`)
- `git`
- Privilegios de `sudo` (para instalar paquetes y activar el display manager)

### Instalación rápida

```bash
git clone https://github.com/borjacandeel/dotfiles-2026.git ~/.dotfiles
cd ~/.dotfiles
chmod +x install.sh
./install.sh
```

El instalador es **idempotente**: puedes ejecutarlo las veces que quieras. Los
archivos que ya tengas en `~/.config` se **resguardan** automáticamente como
`archivo.bak-YYYYMMDD-HHMMSS` antes de reemplazarse.

---

### Opciones del instalador

| Opción | Qué hace |
|---|---|
| *(sin opciones)* | Instalación completa: actualiza, instala, configura y verifica |
| `--no-update` | No ejecuta `pacman -Syu` |
| `--skip-packages` | No instala nada; solo enlaza las configuraciones |
| `--no-aur` | No instala `paru`/`yay` ni los paquetes del AUR |
| `--no-shell` | No cambia la shell por defecto a `fish` |
| `--no-dm` | No configura display manager (arrancarás con `xinit`) |
| `--dm <nombre>` | Fuerza un display manager: `lightdm`, `sddm`, `gdm` o `none` |
| `--check` | **Solo diagnóstico.** No instala ni modifica nada |
| `-h`, `--help` | Muestra el panel de ayuda |

### Panel de ayuda 🆘

El instalador incluye su propia ayuda. Para verla:

```bash
./install.sh -h
```

```
Dotfiles 2026 - Instalador

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
```

### 🖥️ Display manager: a elegir

Sin un display manager **no hay login gráfico**: tendrías que entrar por
consola y ejecutar `xinit ~/.xinitrc` a mano. Por eso el instalador te pregunta.

Al ejecutarlo verás:

```
  ¿Qué display manager quieres usar?
     1) lightdm  (ligero, el que usa este setup)
     2) sddm     (KDE, con temas plasma)
     3) gdm      (GNOME)
     4) ninguno  (solo consola, uso xinit)
  Opción [1]:
```

| Opción | Paquete | LightDM | SDDM | GDM |
|---|---|---|---|---|
| `1` | `lightdm` + `lightdm-gtk-greeter` | ✅ ligero, perfecto para bspwm | — | — |
| `2` | `sddm` | — | ✅ temas plasma, ideal con KDE | — |
| `3` | `gdm` | — | — | ✅ con GNOME |
| `4` | *ninguno* | arranca con `xinit ~/.xinitrc` | | |

También puedes decidirlo sin interacción:

```bash
sudo ./install.sh --dm lightdm    # forzarlo
sudo ./install.sh --dm sddm
sudo ./install.sh --no-dm         # no tocar nada
```

El instalador **desactiva automáticamente** el display manager anterior si
cambias de opción, para que no se peleen por el servidor gráfico.

### 🔧 Qué hace paso a paso

| Fase | Función | Qué hace |
|---|---|---|
| **0/9** | `preflight` | Comprueba Arch, `sudo` y la estructura del repo |
| **1/9** | `update_system` | `pacman -Syu` |
| **2/9** | `install_repo_packages` | Instala los paquetes **que existen** en los repos (filtra los que no) |
| **3c/9** | `setup_display_manager` | Pregunta y activa el display manager que elijas |
| **3/9** | `install_aur_helpers` | Instala `base-devel`, compila `paru` y `yay` |
| **3b/9** | `install_aur_packages` | Con el helper: `polybar-contrib`, `arc-gtk-theme`, `nitrogen`… |
| **4/9** | `create_dirs` | Crea `~/.wallpapers`, `~/.sounds`; **copia los 7 fondos**; rutas XDG en español |
| **5/9** | `link_dotfiles` | Enlaza 13 carpetas a `~/.config` y 4 archivos a `~`, **con respaldo** |
| **6/9** | `setup_fonts` | `fc-cache` y verifica CaskaydiaCove; si falta, la **descarga de GitHub** |
| **7/9** | `setup_gtk_theme` | Comprueba Arc-Dark, Papirus y Adwaita |
| **8/9** | `setup_shell` | Cambia la shell por defecto a `fish` |
| — | `setup_services` | Habilita el servicio de audio |
| **9/9** | `validate_configs` | `sh -n`, `py_compile` y parseo YAML |
| — | `autotest_configs` | **Ejecuta polybar, picom, rofi, sxhkd, fish y dunst con tus configs** |
| — | `verify` | Estado final con semáforo y resumen de avisos |

> Las fases de AUR y display manager se **omiten** si no tienes terminal
> interactiva o si usas `--no-aur` / `--no-dm`. El script nunca aborta por ello.

### Verificar la instalación

Después de instalar, puedes comprobar el estado en cualquier momento **sin
cambiar nada**:

```bash
./install.sh --check
```

Esto ejecuta de verdad cada programa con tu configuración y te dice qué falla:

```
╔══════════════════════════════════════════════════════════╗
║  Autotest de configuraciones                         ║
╚══════════════════════════════════════════════════════════╝
  ✔ polybar: config sin errores (no se puede probar sin servidor X)
  ✔ picom acepta la configuración
  ✔ rofi acepta el tema rasi
  ✔ sxhkd acepta los atajos (sin X no se prueban en vivo)
  ✔ fish carga config.fish sin errores
  ✔ dunst acepta la configuración
  ✔ la fuente de las configs (CaskaydiaCove Nerd Font) está instalada
```

> **Probado de verdad.** El autotest se validó con `bspwm`, `sxhkd`, `polybar`,
> `picom`, `dunst`, `rofi`, `feh`, `alacritty`, `fish` y `playerctl` realmente
> instalados en Arch, y así se encontraron 5 bugs reales que ya están corregidos
> (entre ellos un `SIGPIPE` por `pipefail` que hacía fallar la detección de la
> fuente, y un `unbound variable` que abortaba la instalación).

---

## 🧹 Desinstalación

Si quieres volver atrás sin borrar tu configuración:

```bash
# Quitar solo los enlaces
cd ~/.dotfiles
for d in alacritty bin bspwm dunst fish gtk-2.0 gtk-3.0 nitrogen \
         pcmanfm picom polybar rofi sxhkd; do
    [ -L ~/.config/$d ] && rm ~/.config/$d
done
for f in .xinitrc .xprofile .Xresources .zshrc; do
    [ -L ~/$f ] && rm ~/$f
done

# Restaurar los respaldos que hizo el instalador
ls ~/.config/*.bak-* ~/*.bak-* 2>/dev/null
```

Los respaldos tienen formato `archivo.bak-YYYYMMDD-HHMMSS`.

---

## 📁 Estructura del repo

```
dotfiles-2026/
├── .images/
│   └── screenshot.png          # Captura del escritorio
├── .wallpapers/                # 7 fondos de pantalla
│   ├── bosque.png · earth.png (4K) · fondo.png
│   ├── windows.png (4K) · macos.jpg · macos-bigsur.jpg · wallpaper.png
├── alacritty/
│   └── alacritty.yml           # Colores Rosé Pine, opacidad, atajos
├── bin/
│   ├── spotify_status.py       # Estado de Spotify para polybar
│   ├── wallpaper.sh            # next / prev / random / list
│   └── make_wallpaper.py       # Genera degradados PNG sin dependencias
├── bspwm/
│   └── bspwmrc                 # WM + arranque de toda la sesión
├── dunst/
│   └── dunstrc                 # Notificaciones con urgencias
├── fish/
│   ├── config.fish             # Alias, PATH, starship, colores
│   ├── conf.d/omf.fish
│   └── functions/
├── gtk-2.0/gtkfilechooser.ini
├── gtk-3.0/settings.ini        # Arc-Dark + Papirus + cursor Adwaita
├── nitrogen/                   # Fondos (interfaz gráfica)
├── pcmanfm/default/pcmanfm.conf
├── picom/picom.conf            # Blur, sombras, esquinas redondeadas
├── polybar/
│   ├── config                  # Barra
│   └── launch.sh               # Lanzador
├── rofi/config.rasi            # Launcher
├── sxhkd/sxhkdrc               # Atajos de teclado
├── .xinitrc                    # Arranque de X
├── .xprofile                   # Perfil para display managers
├── .Xresources                 # Colores de Xterm (256)
├── .zshrc                      # Config de zsh (alternativa)
├── install.sh                  # Instalador
└── README.md
```

### Dónde acaba cada cosa

| Origen | Destino |
|---|---|
| `alacritty/`, `bspwm/`, `polybar/`… | `~/.config/<carpeta>/` (symlink) |
| `bin/` | `~/.config/bin/` (lo necesita polybar) |
| `.xinitrc`, `.xprofile`, `.Xresources`, `.zshrc` | `~` (symlink) |
| `.wallpapers/*` | `~/.wallpapers/` (**copia**, puedes añadir los tuyos) |

---

## ⌨️ Atajos de teclado

### Aplicaciones

| Atajo | Acción |
|---|---|
| `Super + Enter` | Terminal (Alacritty) |
| `Super + Shift + Enter` | Terminal flotante |
| `Super + d` | Lanzador Rofi |
| `Super + e` | Gestor de archivos |
| `Super + b` | Navegador |

### Ventanas

| Atajo | Acción |
|---|---|
| `Super + q` | Cerrar ventana |
| `Super + {1-9,0}` | Ir al escritorio N |
| `Super + Shift + {1-9,0}` | Mover ventana al escritorio N |
| `Super + h/j/k/l` | Enfocar izquierda/abajo/arriba/derecha |
| `Super + Shift + h/j/k/l` | Mover ventana |
| `Super + Alt + h/j/k/l` | Redimensionar |
| `Super + m` | Cambiar layout (tiled ↔ monocle) |
| `Super + t` | Toggle flotante |
| `Super + s` | Toggle pseudo-flotante |
| `Super + f` | Pantalla completa |
| `Super + g` | Intercambiar con la ventana más grande |
| `Super + y` | Enviar a la ventana marcada |
| `Super + ctrl + m` | Marcar ventana |
| `Super + {Left,Down,Up,Right}` | Mover ventana flotante |

### Sistema

| Atajo | Acción |
|---|---|
| `Super + n` | Fondo siguiente |
| `Super + Shift + n` | Fondo anterior |
| `Super + Alt + n` | Fondo aleatorio |
| `Super + Escape` | Recargar sxhkd |
| `Super + Alt + r` | Reiniciar bspwm |
| `Super + Alt + q` | Cerrar sesión (bspwm) |

---

## 📦 Dependencias

### Repos oficiales (se instalan solas)

```bash
# Sesión y WM
bspwm sxhkd wmname
xorg-xinit xorg-xsetroot xorg-xrandr xorg-xprop xorg-xwininfo
xorg-xrdb xorg-setxkbmap xsel xclip xdotool
lightdm lightdm-gtk-greeter

# Escritorio
polybar picom dunst rofi feh
alacritty fish pcmanfm lxappearance
gtk3 papirus-icon-theme adwaita-cursors

# Audio y bandeja
playerctl pulseaudio pulseaudio-alsa pavucontrol alsa-utils sox
volumeicon cbatticon udiskie network-manager-applet

# Utilidades
lm_sensors xdg-user-dirs xdg-utils python jq htop fastfetch
tree fd ripgrep fzf bat eza zoxide starship
git wget curl unzip tar gzip bzip2 xz zstd base-devel

# Fuentes
ttf-cascadia-code-nerd ttf-nerd-fonts-symbols
ttf-nerd-fonts-symbols-mono ttf-font-awesome
noto-fonts noto-fonts-emoji
```

### Del AUR (los instala el propio script)

| Paquete | Para qué |
|---|---|
| `paru` · `yay` | Helpers de AUR (se compilan al vuelo) |
| `polybar-contrib` | **Imprescindible**: módulos `custom/*` de la barra |
| `arc-gtk-theme` | Tema GTK Arc-Dark |
| `arc-icon-theme` | Iconos Arc |
| `nitrogen` | Gestor de fondos gráfico |
| `oh-my-fish` | Tema extra de Fish (opcional) |

> **`polybar-contrib` es el más importante.** Sin él, la barra arranca pero los
> módulos launcher, powermenu, spotify-status y updates salen vacíos.
>
> Usa `--no-aur` si prefieres gestionarlos tú a mano.

---

## 🖼️ Wallpapers

El repo incluye **7 fondos** que el instalador copia a `~/.wallpapers/`:

| Archivo | Resolución | Tamaño |
|---|---|---|
| `bosque.png` | — | 337 KB |
| `earth.png` | 3840×2160 (4K) | 8.2 MB |
| `fondo.png` | 6024×3401 | 1.1 MB |
| `windows.png` | 3840×2160 (4K) | 3.8 MB |
| `macos.jpg` | — | 4.4 MB |
| `macos-bigsur.jpg` | — | 3.2 MB |
| `wallpaper.png` | — | 477 KB |

Añade los tuyos a `~/.wallpapers/` y se detectan solos. El orden de arranque es:

1. `~/.wallpapers/bosque.png`
2. La primera imagen que encuentre
3. Color sólido `#191724` (Rosé Pine base) si no hay ninguna

```bash
~/.config/bin/wallpaper.sh list      # ver los disponibles
~/.config/bin/wallpaper.sh next      # siguiente
~/.config/bin/wallpaper.sh prev      # anterior
~/.config/bin/wallpaper.sh random    # aleatorio
```

También puedes generar un degradado nuevo **sin instalar nada** (escribe el PNG
a mano con `zlib`, sin ImageMagick ni PIL):

```bash
python3 ~/.config/bin/make_wallpaper.py ~/Pictures/rose.png 2560 1440
```

---

## 🎨 Personalización

| Quiero cambiar… | Archivo |
|---|---|
| Colores de la barra | `polybar/config` → `[colors]` |
| Colores de la terminal | `alacritty/alacritty.yml` → `colors:` |
| Colores de rofi | `rofi/config.rasi` |
| Bordes de ventana | `bspwm/bspwmrc` → `# BSPWM config` |
| Atajos de teclado | `sxhkd/sxhkdrc` |
| Notificaciones | `dunst/dunstrc` |
| Efectos visuales | `picom/picom.conf` |
| Prompt de la shell | `fish/config.fish` |
| Tema GTK | `gtk-3.0/settings.ini` |
| Colores de Xterm | `.Xresources` |

### Cambiar el tema de Rosé Pine

Los colores están dispersos por diseño (cada componente tiene su archivo), pero
todos comparten la misma paleta. Si cambias de variante de Rosé Pine —main,
`moon`, `dawn`— busca y reemplaza estos valores:

| Color | Hex | Uso |
|---|---|---|
| Base | `#191724` | Fondos |
| Surface | `#26233A` | Bordes, surfaces |
| Text | `#E0DEF4` | Texto principal |
| Love | `#EB6F92` | Acento principal (Rosé Pine) |
| Gold | `#F6C177` | Acento secundario |
| Pine | `#31748F` | Acento terciario |
| Foam | `#EBBCBA` | Acento cuaternario |
| Muted | `#6E6A86` | Texto secundario |

> **Tip:** tras editar cualquier config, recarga sin cerrar sesión:
> `Super+Alt+r` (bspwm) · `pkill -USR1 -x sxhkd` (atajos) ·
> `~/.config/polybar/launch.sh` (barra).

---

## 🛠️ Solución de problemas

<details>
<summary><b>La barra no aparece</b></summary>

```bash
~/.config/polybar/launch.sh          # relance manual
tail -20 /tmp/polybar-bar.log        # ver el error
```

Causa más común: falta `polybar-contrib` para los módulos personalizados.

</details>

<details>
<summary><b>Los iconos salen como cuadraditos</b></summary>

Falta la fuente de símbolos:

```bash
sudo pacman -S ttf-nerd-fonts-symbols ttf-font-awesome
fc-cache -f
```

</details>

<details>
<summary><b>La terminal no abre</b></summary>

Comprueba la config:

```bash
./install.sh --check
```

Lo más común es un error de YAML en `alacritty.yml`. El autotest lo detecta y
te dice la línea exacta.

</details>

<details>
<summary><b>No hay login gráfico (pantalla negra al arrancar)</b></summary>

Comprueba qué display manager está activo:

```bash
systemctl status lightdm
```

Si no hay ninguno, actívalo:

```bash
sudo ./install.sh --dm lightdm
```

Si no quieres display manager, entra por consola con `xinit ~/.xinitrc`.

</details>

<details>
<summary><b>No arranca al hacer logout</b></summary>

```bash
chmod +x ~/.config/bspwm/bspwmrc
```

Además, revisa el log de bspwm:

```bash
cat /tmp/bspwm.log
```

</details>

<details>
<summary><b>Picom da error con <code>unknown option</code></b></summary>

`bspwmrc` ya detecta si tu versión de picom soporta
`--experimental-backends` (eliminado en picom 13), así que debería funcionar
solo. Si sigue fallando, revisa `~/.config/picom/picom.conf` contra:

```bash
picom --help
```

</details>

<details>
<summary><b>La temperatura o batería no aparecen en la barra</b></summary>

Depende del hardware. Comprueba que el sensor existe:

```bash
ls /sys/class/thermal/thermal_zone0/   # temperatura
ls /sys/class/power_supply/BAT0/       # batería
```

Si tu equipo no los tiene, quita los módulos `temperature` (y `battery`) de
`modules-right` en `polybar/config`.

</details>

<details>
<summary><b>nm-applet sobra o falla</b></summary>

Solo hace falta con NetworkManager. Si usas `systemd-networkd`, quítalo de
`bspwmrc`.

</details>

---

## 📄 Licencia

**MIT** — úsalos, modifícalos, compártelos.

Los wallpapers y la captura de pantalla pertenecen a sus autores originales y se
incluyen solo con fines demostrativos.

---

<div align="center">

### 🪵 Dotfiles 2026

**Hecho con ☕ por [Borja Candel](https://borjacandeel.github.io)**

[![Arch Linux](https://img.shields.io/badge/Arch_Linux-1793D1?style=flat-square&logo=arch-linux&logoColor=white)](https://archlinux.org)
[![BSPWM](https://img.shields.io/badge/BSPWM-2D2D2D?style=flat-square&logo=linux&logoColor=white)](https://github.com/baskerville/bspwm)
[![Rosé Pine](https://img.shields.io/badge/Ros%C3%A9_Pine-EBBCBA?style=flat-square&logo=rosepine&logoColor=black)](https://rosepinetheme.com)

</div>
