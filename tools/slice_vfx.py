# -*- coding: utf-8 -*-
"""
Meowa 特效图集切片（D-033）：把 AI 生成的 3x4 特效图集切成三条帧带
输入：meowa_out/vfx_cutout/.../output.png（透明底）
输出：assets/fx/meowa_slash.png / meowa_ring.png / meowa_spark.png（各 4 帧 x 128px 横向帧带）
"""
import os

from PIL import Image

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
SRC = os.path.join(ROOT, "meowa_out", "vfx_cutout", "result_images_0_url", "output.png")
OUT = os.path.join(ROOT, "assets", "fx")
CELL = 128

img = Image.open(SRC).convert("RGBA")
w, h = img.size
row_h = h // 3
names = ["meowa_slash.png", "meowa_ring.png", "meowa_spark.png"]

for r, name in enumerate(names):
    strip = Image.new("RGBA", (CELL * 4, CELL), (0, 0, 0, 0))
    for c in range(4):
        cell = img.crop((c * w // 4, r * row_h, (c + 1) * w // 4, (r + 1) * row_h))
        bbox = cell.getbbox()  # alpha 内容边界
        if bbox:
            cell = cell.crop(bbox)
        # 整数倍缩小到 128 内，保持像素感
        scale = 1
        while cell.width > CELL or cell.height > CELL:
            scale += 1
            break
        if cell.width > CELL or cell.height > CELL:
            factor = max(2, (max(cell.width, cell.height) + CELL - 1) // CELL)
            cell = cell.resize((max(1, cell.width // factor), max(1, cell.height // factor)), Image.NEAREST)
        strip.paste(cell, (c * CELL + (CELL - cell.width) // 2, (CELL - cell.height) // 2), cell)
    strip.save(os.path.join(OUT, name))
    print("saved", name)
print("done")
