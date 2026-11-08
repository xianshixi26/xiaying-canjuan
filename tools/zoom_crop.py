# -*- coding: utf-8 -*-
"""调试：放大预览图局部，识别地面纹理来源"""
import os

from PIL import Image

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
img = Image.open(os.path.join(ROOT, "assets", "preview_v2.png")).convert("RGB")
crop = img.crop((60, 400, 360, 600)).resize((900, 600), Image.NEAREST)
crop.save(os.path.join(ROOT, "assets", "debug_zoom.png"))
crop2 = img.crop((600, 60, 900, 260)).resize((900, 600), Image.NEAREST)
crop2.save(os.path.join(ROOT, "assets", "debug_zoom2.png"))
print("saved assets/debug_zoom.png / debug_zoom2.png")
