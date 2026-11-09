# -*- coding: utf-8 -*-
"""特效变体：剑光帧带色相旋转 -> 敌方红色斩击（本地生成，零积分）"""
import os

import numpy as np
from PIL import Image

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
SRC = os.path.join(ROOT, "assets", "fx", "meowa_slash.png")
DST = os.path.join(ROOT, "assets", "fx", "meowa_slash_red.png")

img = Image.open(SRC).convert("RGBA")
hsv = np.asarray(img.convert("HSV")).copy()
hsv[..., 0] = 8  # 色相 -> 红橙
hsv[..., 1] = np.clip(hsv[..., 1].astype(np.int16) + 30, 0, 255)  # 提饱和
out = Image.fromarray(hsv, "HSV").convert("RGBA")
out.putalpha(img.getchannel("A"))
out.save(DST)
print("saved meowa_slash_red.png")
