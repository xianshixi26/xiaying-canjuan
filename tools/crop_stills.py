# -*- coding: utf-8 -*-
"""从角色抠图图集切出四人静帧（动画生成源）"""
import os

from PIL import Image

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
SRC = os.path.join(ROOT, "meowa_out", "chars_cut", "result_images_0_url", "output.png")
OUT = os.path.join(ROOT, "meowa_out", "stills")
os.makedirs(OUT, exist_ok=True)

img = Image.open(SRC).convert("RGBA")
w, h = img.size
mapping = [((0, 0), "hero"), ((1, 0), "brigand"), ((0, 1), "boss"), ((1, 1), "baiji")]
for (r, c), name in mapping:
    cell = img.crop((c * w // 2, r * h // 2, (c + 1) * w // 2, (r + 1) * h // 2))
    bbox = cell.getbbox()
    if bbox:
        cell = cell.crop(bbox)
    cell.save(os.path.join(OUT, name + ".png"))
    print("still", name)
print("OK")
