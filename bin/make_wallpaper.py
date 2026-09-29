#!/usr/bin/env python3
"""
Genera un fondo de pantalla con el degradado de Rosé Pine (main).
Sin dependencias externas: escribe el PNG a mano con zlib (stdlib).

Uso: python3 make_wallpaper.py [salida.png] [ancho] [alto]
"""

import struct
import sys
import zlib

# Paleta Rosé Pine
ROSE_PINE = (25, 23, 36)      # #191724 base
SURFACE_0 = (36, 35, 58)      # #26233a
CRANBERRY = (235, 111, 146)   # #eb6f92 love
IRIS = (196, 167, 231)        # #c4a7e7 iris
PINE = (49, 116, 143)         # #31748f pine
GOLD = (246, 193, 119)        # #f6c177 gold
FOAM = (224, 222, 244)       # #e0def4 text


def blend(c1, c2, t):
    """Mezcla lineal entre dos colores RGB."""
    return tuple(int(round(a + (b - a) * t)) for a, b in zip(c1, c2))


def build_pixels(w, h):
    """Devuelve los píxeles del degradado diagonal con-textura suave."""
    rows = []
    for y in range(h):
        row = bytearray()
        # t normalizado en el eje vertical
        ty = y / max(h - 1, 1)
        for x in range(w):
            tx = x / max(w - 1, 1)
            # Degradado diagonal principal
            t = (tx * 0.55 + ty * 0.45)
            color = blend(ROSE_PINE, SURFACE_0, t)
            # Halocranberry suave arriba a la derecha
            dx = (x - w * 0.78) / w
            dy = (y - h * 0.22) / h
            d = (dx * dx + dy * dy) ** 0.5
            if d < 0.55:
                glow = (1.0 - d / 0.55) ** 2.4
                color = blend(color, CRANBERRY, glow * 0.30)
            # Halo pine abajo a la izquierda
            dx2 = (x - w * 0.18) / w
            dy2 = (y - h * 0.85) / h
            d2 = (dx2 * dx2 + dy2 * dy2) ** 0.5
            if d2 < 0.5:
                glow2 = (1.0 - d2 / 0.5) ** 2.6
                color = blend(color, PINE, glow2 * 0.28)
            # Viñeta
            vx = (x / w - 0.5) * 2
            vy = (y / h - 0.5) * 2
            v = (vx * vx + vy * vy) ** 0.5
            if v > 0.7:
                color = blend(color, ROSE_PINE, (v - 0.7) * 0.55)
            row += bytes(color)
        rows.append(bytes(row))
    return rows


def write_png(path, w, h, rows):
    """Serializa los píxeles en un PNG (color truecolor de 8 bits)."""

    def chunk(tag, data):
        c = struct.pack(">I", len(data)) + tag + data
        return c + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)

    raw = b"".join(b"\x00" + r for r in rows)  # filtro 0 por línea
    png = b"\x89PNG\r\n\x1a\n"
    png += chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 2, 0, 0, 0))
    png += chunk(b"IDAT", zlib.compress(raw, 9))
    png += chunk(b"IEND", b"")
    with open(path, "wb") as f:
        f.write(png)


def main():
    out = sys.argv[1] if len(sys.argv) > 1 else "wallpaper.png"
    w = int(sys.argv[2]) if len(sys.argv) > 2 else 1920
    h = int(sys.argv[3]) if len(sys.argv) > 3 else 1080
    rows = build_pixels(w, h)
    write_png(out, w, h, rows)
    print(f"Wallpaper generado: {out} ({w}x{h}, {os_size(out)} bytes)")


def os_size(p):
    import os
    return os.path.getsize(p)


if __name__ == "__main__":
    main()
