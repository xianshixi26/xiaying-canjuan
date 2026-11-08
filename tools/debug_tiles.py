# -*- coding: utf-8 -*-
"""调试：按地块类型着色输出铺装图，定位预览地面异常"""
import math
import os

from PIL import Image, ImageDraw

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
W, H, T = 960, 640, 64


def tile_of(col, row):
    if col in (6, 7) or row in (4, 5):
        return "path"
    if col >= 11 and row >= 7 and ((col - 12.5) / 2.2) ** 2 + ((row - 8.2) / 1.5) ** 2 <= 1:
        return "water"
    v = math.sin(col * 0.9) * math.cos(row * 0.8) + math.sin((col + row) * 0.5) * 0.6
    return "grass" if v > 0.35 else "paper"


COLORS = {"paper": (220, 210, 190), "grass": (60, 140, 60), "path": (60, 90, 220), "water": (60, 200, 220)}

img = Image.new("RGB", (W, H), (0, 0, 0))
d = ImageDraw.Draw(img)
counts = {}
for row in range(H // T + 1):
    for col in range(W // T + 1):
        k = tile_of(col, row)
        counts[k] = counts.get(k, 0) + 1
        d.rectangle([col * T, row * T, col * T + T - 1, row * T + T - 1], fill=COLORS[k], outline=(20, 20, 20))
img.save(os.path.join(ROOT, "assets", "debug_tiles.png"))
print("counts:", counts)
print("saved assets/debug_tiles.png")
