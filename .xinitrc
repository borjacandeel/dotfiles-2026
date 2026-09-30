#!/bin/sh
# Arranque de la sesión X — se ejecuta por xinit/startx o el greeter

# Recursos X (fuentes, colores, cursor)
[ -f ~/.Xresources ] && xrdb -merge ~/.Xresources

# Layout de teclado español; fallback a US si no hay xkb
setxkbmap es 2>/dev/null || setxkbmap us 2>/dev/null

# Nombre del WM para apps Java/Swing (evita ventanas en blanco)
wmname LG3D 2>/dev/null

# Cursor por defecto mientras no haya WM
xsetroot -cursor_name left_ptr 2>/dev/null

# Atajos de teclado
sxhkd &

# Barra de estado
~/.config/polybar/launch.sh &

# Compositor (blur, sombras, esquinas redondeadas)
picom --daemon 2>/dev/null &

# Notificaciones
dunst &

# Fondo de pantalla
if [ -f "$HOME/.wallpapers/rosepine.png" ]; then
    feh --bg-scale "$HOME/.wallpapers/rosepine.png"
else
    wall="$(find "$HOME/.wallpapers" -maxdepth 1 \( -name '*.png' -o -name '*.jpg' -o -name '*.jpeg' \) 2>/dev/null | head -1)"
    if [ -n "$wall" ]; then
        feh --bg-scale "$wall"
    else
        xsetroot -solid '#191724'
    fi
fi

# Bandeja del sistema
udiskie --tray 2>/dev/null &
volumeicon 2>/dev/null &

# Applet de red solo si NetworkManager está activo
if systemctl is-active --quiet NetworkManager 2>/dev/null; then
    nm-applet 2>/dev/null &
fi

# Iniciar BSPWM (debe ser el último y sin '&')
exec bspwm
