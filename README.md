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

![Escritorio BSPWM con Polybar y tema Rosé Pine](.images/screenshot.png)

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
| **Fondos** | `feh` | Cambio de wallpaper con atajos y script propio |
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
| `--no-wallpaper` | No generar un fondo de pantalla por defecto |
| `--no-log` | No escribir el fichero de log |
| `--log <fichero>` | Guardar el log en la ruta indicada |
| `-h`, `--help` | Muestra el panel de ayuda |

> **No ejecutes el instalador con `sudo`.** `makepkg` se niega a correr como root y
> con root se pierden las variables de tu usuario (`HOME`, XDG…). El script ya pide
> la contraseña de sudo por ti cuando hace falta.

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
```

### 📄 Log de la instalación

Cada ejecución guarda **todo** lo que imprime el script y todos sus procesos
hijos (incluidos `pacman`, `makepkg` y `git clone`) en:

```
~/.cache/dotfiles-2026/install-AAAAMMDD-HHMMSS.log
```

La salida se ve en pantalla y se guarda a la vez, así que el log sirve para
auditar la instalación o para depurar algo que falló:

```bash
# Resumen de problemas de la última instalación
grep -iE 'error|warn|x \[' ~/.cache/dotfiles-2026/install-*.log | tail -40

# Guardarlo en otra ruta
./install.sh --log /tmp/mi-instalacion.log

# No generar log
./install.sh --no-log
```

El script devuelve **código de salida 1** si al terminar quedan errores o
componentes sin instalar, para poder encadenarlo en scripts o CI.

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
cambias de opción, para que no se peleen por el servidor gráfico. Solo usa
`systemctl disable`, nunca `--now`: si tu display manager actual está en uso,
`--now` te cerraría la sesión y perderías todo lo que tengas abierto. El
cambio se aplica al reiniciar.

### 🔧 Qué hace paso a paso

| Fase | Función | Qué hace |
|---|---|---|
| — | `setup_logging` | Redirige toda la salida a pantalla **y** a `~/.cache/dotfiles-2026/` |
| **0/10** | `preflight` | Comprueba Arch, `sudo`, que no se ejecute como root y sincroniza la BD de pacman |
| **1/10** | `update_system` | `pacman -Syu` |
| **2/10** | `install_repo_packages` | Instala los paquetes **que existen** en los repos (filtra los que no) |
| **3/10** | `setup_display_manager` | Pregunta y activa el display manager que elijas |
| **3b/10** | `install_aur_packages` | `arc-gtk-theme` y `arc-icon-theme` con `makepkg` |
| **4/10** | `create_dirs` | Crea `~/.wallpapers`, `~/.sounds`; copia los fondos; rutas XDG en español |
| **5/10** | `link_dotfiles` | Enlaza 12 carpetas a `~/.config` y 3 archivos a `~`, **con respaldo** |
| **6/10** | `setup_fonts` | `fc-cache` y verifica CaskaydiaCove; si falta, la **descarga de GitHub** |
| **7/10** | `setup_gtk_theme` | Comprueba Arc-Dark, Papirus y Adwaita |
| **8/10** | `setup_shell` | Cambia la shell por defecto a `fish` |
| — | `setup_services` | Habilita el servicio de audio si hay systemd de usuario |
| **9/10** | `validate_configs` | `sh -n`, `bash -n`, Python en memoria y parseo YAML |
| — | `autotest_configs` | **Ejecuta polybar, picom, rofi, sxhkd, fish, dunst y alacritty con tus configs** |
| **10/10** | `verify` | Estado final con semáforo y resumen de errores/avisos |

> Las fases de AUR y display manager se **omiten** si no tienes terminal
> interactiva o si usas `--no-aur` / `--no-dm`. El script nunca aborta por ello.

<details>
<summary><b>Por qué no se instalan <code>paru</code> ni <code>yay</code></b></summary>

Los helpers de AUR actuales son binarios que hay que **compilar** (paru en Rust,
yay en Go), lo que duplica el tiempo de instalación y añade un punto de fallo
más. Como `base-devel` ya trae `makepkg`, el instalador clona el PKGBUILD del
paquete y lo compila directamente: mismo resultado, la mitad de tiempo.

Si prefieres usar un helper y lo tienes instalado, el script lo detecta y lo usa.

</details>

<details>
<summary><b>Por qué no se instala <code>polybar-contrib</code> ni <code>nitrogen</code></b></summary>

- **`polybar-contrib` ya no existe en el AUR.** Además, desde polybar 3.5 los
  módulos `custom/text`, `custom/script` y `custom/menu` vienen en el paquete
  oficial, así que la barra de este repo funciona sin nada del AUR.
  Se puede comprobar con `strings /usr/bin/polybar | grep custom/`.
- **`nitrogen` no compila.** Su versión del AUR (1.6.1) depende de `gtkmm` y
  `gtk+-2.0`, y ambos se retiraron de los repos de Arch. No hace falta:
  `bspwmrc` y `bin/wallpaper.sh` (con `feh`) ya cambian el fondo, y nitrogen solo
  añadiría una GUI.

</details>

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
  ✔ polybar acepta la configuración (módulosLeft/derecha leídos)
  ✔ picom acepta la configuración (validado sin servidor X)
  ✔ rofi acepta el tema rasi
  ✔ sxhkd acepta los atajos
  ✔ fish carga config.fish sin errores
  ✔ dunst acepta la configuración
  ✔ alacritty acepta alacritty.toml
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
for f in .xinitrc .xprofile .Xresources; do
    [ -L ~/$f ] && rm ~/$f
done

# Quitar la sesión del greeter
rm -f ~/.local/share/xsessions/dotfiles.desktop

# Restaurar los respaldos que hizo el instalador
ls ~/.config/*.bak-* ~/*.bak-* 2>/dev/null
```

Los respaldos tienen formato `archivo.bak-YYYYMMDD-HHMMSS`.

---

## 📁 Estructura del repo

```
dotfiles-2026/
├── alacritty/
│   ├── alacritty.toml          # Config actual (Alacritty 0.13+)
│   └── alacritty.yml           # Versión antigua, por si usas Alacritty < 0.13
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
├── nitrogen/                   # Config de nitrogen (opcional)
├── pcmanfm/default/pcmanfm.conf
├── picom/picom.conf            # Blur, sombras, esquinas redondeadas
├── polybar/
│   ├── config                  # Barra
│   └── launch.sh               # Lanzador idempotente, con log propio
├── rofi/config.rasi            # Launcher
├── sxhkd/sxhkdrc               # Atajos de teclado
├── .xinitrc                    # Arranque de la sesión X
├── .xprofile                   # Variables de entorno de la sesión
├── .Xresources                 # Fuentes de X, cursor y colores
├── .gitignore
├── install.sh                  # Instalador
└── README.md
```

> Los fondos de pantalla **no** se guardan en el repo (evitar subir PNGs pesados).
> Si quieres añadir los tuyos, ponlos en `.wallpapers/` dentro del repo: el
> instalador los copiará a `~/.wallpapers/`. Si no hay ninguno, genera uno
> Rosé Pine automáticamente con `bin/make_wallpaper.py`.

### Dónde acaba cada cosa

| Origen | Destino |
|---|---|
| `alacritty/`, `bspwm/`, `polybar/`… | `~/.config/<carpeta>/` (symlink) |
| `bin/` | `~/.config/bin/` (lo necesita polybar) |
| `.xinitrc`, `.xprofile`, `.Xresources` | `~` (symlink) |
| (generado) | `~/.local/share/xsessions/dotfiles.desktop` (sesión del greeter) |
| `.wallpapers/*` | `~/.wallpapers/` (**copia**, puedes añadir los tuyos) |

---

## ⌨️ Atajos de teclado

### Aplicaciones

| Atajo | Acción |
|---|---|
| `Super + Enter` | Terminal (Alacritty) |
| `Super + d` | Lanzador Rofi |
| `Ctrl + Tab` | Cambio de ventana (Rofi) |
| `Super + e` | Gestor de archivos |
| `Super + Shift + r` | Reiniciar bspwm |

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

> `Ctrl + Tab` y no `Super + Tab`: el segundo entra en conflicto con el atajo de
> "ir a la última ventana" y sxhkd solo puede cumplir uno de los dos.

---

## 📦 Dependencias

### Repos oficiales (se instalan solas)

```bash
# Sesión y WM
bspwm sxhkd wmname
xorg-xinit xorg-xsetroot xorg-xrandr xorg-xprop xorg-xwininfo
xorg-xrdb xorg-setxkbmap xorg-xdpyinfo xorg-xhost xorg-xset
xsel xclip xdotool
procps-ng psmisc          # pgrep/pkill y killall, usados por bspwmrc y launch.sh
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
ttf-nerd-fonts-symbols-mono ttf-nerd-fonts-symbols-common
otf-font-awesome        # el nombre real empieza por otf-, no ttf-
noto-fonts noto-fonts-emoji noto-fonts-extra
```

### Del AUR (los instala el propio script con `makepkg`)

| Paquete | Para qué | Dependencias de compilación |
|---|---|---|
| `arc-gtk-theme` | Tema GTK Arc-Dark (el que pide `gtk-3.0/settings.ini`) | `meson sassc glib2 gdk-pixbuf2` |
| `arc-icon-theme` | Iconos Arc (alternativa a Papirus) | `imagemagick` |

> Usa `--no-aur` si prefieres gestionarlos tú a mano. Ninguno es imprescindible:
> sin Arc-Dark, GTK cae a su tema por defecto sin dar ningún error.

---

## 🖼️ Wallpapers

El instalador copia a `~/.wallpapers/` los fondos que encuentre en
`.wallpapers/` dentro del repo. Si el repo no trae ninguno (es lo normal, para no
subir PNGs pesados a git), **genera un degradado Rosé Pine** con
`bin/make_wallpaper.py`. Para desactivarlo: `--no-wallpaper`.

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
| Colores de la terminal | `alacritty/alacritty.toml` → `[colors]` |
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
~/.config/polybar/launch.sh                    # relance manual
tail -20 ~/.cache/polybar-bar.log              # ver el error
```

Si el log dice `Unknown module type: custom/...`, tu polybar es anterior a la
3.5 y no trae los módulos `custom/*`. Actualiza el paquete oficial:

```bash
sudo pacman -Syu polybar
```

</details>

<details>
<summary><b>Los iconos salen como cuadraditos</b></summary>

Falta la fuente de símbolos:

```bash
sudo pacman -S ttf-nerd-fonts-symbols otf-font-awesome
fc-cache -f
```

</details>

<details>
<summary><b>La terminal no abre</b></summary>

Comprueba la config:

```bash
./install.sh --check
```

Alacritty 0.13+ usa **TOML**, no YAML: si editas `alacritty.yml` no se te va a
aplicar nada. El archivo que se lee es `alacritty.toml`. Si vienes del YAML,
puedes migrarlo con `alacritty migrate`.

</details>

<details>
<summary><b>No hay login gráfico (pantalla negra al arrancar)</b></summary>

Comprueba qué display manager está activo:

```bash
systemctl status lightdm
```

Si no hay ninguno, actívalo:

```bash
./install.sh --dm lightdm
sudo systemctl enable lightdm
```

Si no quieres display manager, entra por consola con `xinit ~/.xinitrc`.
El instalador también crea `~/.local/share/xsessions/dotfiles.desktop`, que es
lo que hace que esta sesión aparezca en la lista del greeter.

</details>

<details>
<summary><b>No arranca al hacer logout</b></summary>

```bash
chmod +x ~/.config/bspwm/bspwmrc
```

Además, revisa el log de la instalación:

```bash
grep -iE 'error|warn' ~/.cache/dotfiles-2026/install-*.log | tail
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
