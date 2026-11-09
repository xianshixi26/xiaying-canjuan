# -*- coding: utf-8 -*-
"""整合 UI 素材：水墨标题背景 + AI 武器图标（D-035）"""
import glob
import os

from PIL import Image

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
OUT = os.path.join(ROOT, "meowa_out")

bg = glob.glob(os.path.join(OUT, "title_bg", "*", "result_images_0_url.png"))
if bg:
    Image.open(bg[0]).convert("RGBA").save(os.path.join(ROOT, "assets", "ui", "title_bg.png"))
    print("title_bg ok")

ws = glob.glob(os.path.join(OUT, "weapons_001", "*", "result_images_0_url.png"))
if ws:
    img = Image.open(ws[0]).convert("RGBA")
    w, h = img.size
    sheet = Image.new("RGBA", (320, 64), (0, 0, 0, 0))
    for i in range(5):
        cell = img.crop((i * w // 5, 0, (i + 1) * w // 5, h))
        bbox = cell.getbbox()
        if bbox:
            cell = cell.crop(bbox)
        cell.thumbnail((58, 58), Image.LANCZOS)
        sheet.paste(cell, (i * 64 + (64 - cell.width) // 2, (64 - cell.height) // 2), cell)
    sheet.save(os.path.join(ROOT, "assets", "actors", "weapons.png"))
    print("weapons ok")
print("UI_INTEGRATED")
