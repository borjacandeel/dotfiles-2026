#!/usr/bin/env bash
# Pista actual de cualquier reproductor MPRIS (playerctl) para polybar: « Artista: Título»
st="$(playerctl status 2>/dev/null)" || exit 0
case "$st" in Playing) icon="" ;; Paused) icon="" ;; *) exit 0 ;; esac
txt="$(playerctl metadata --format '{{artist}}: {{title}}' 2>/dev/null)"
[ -n "$txt" ] && printf '%s %s\n' "$icon" "$txt"
