# -*- coding: utf-8 -*-
"""
《侠影残卷》水墨风占位素材生成器（D-019）
- 输出：assets/tiles/*.png（地砖图集）+ assets/props/*.png（装饰道具）
- 固定随机种子，可复现；后续可整体替换为手绘素材（同名同尺寸即可）。
运行：python tools/gen_assets.py
"""
import os
import math
import random

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

random.seed(42)
np.random.seed(42)

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
TILES = os.path.join(ROOT, "assets", "tiles")
PROPS = os.path.join(ROOT, "assets", "props")
os.makedirs(TILES, exist_ok=True)
os.makedirs(PROPS, exist_ok=True)

PAPER = (242, 237, 224)
INK = (28, 28, 34)
INK_SOFT = (74, 78, 88)
RED = (180, 40, 31)
SAGE = (108, 122, 90)
SAGE_DARK = (74, 86, 64)
WATER = (198, 208, 212)
WATER_LINE = (162, 180, 190)
PATH = (228, 217, 194)
WOOD = (96, 82, 68)


def paper_base(size, base=PAPER, noise=6):
    """宣纸底：底色 + 细微颗粒噪点"""
    w, h = size
    img = Image.new("RGBA", size, base + (255,))
    arr = np.array(img).astype(np.int16)
    n = np.random.randint(-noise, noise + 1, (h, w, 1))
    arr[..., :3] = np.clip(arr[..., :3] + n, 0, 255)
    return Image.fromarray(arr.astype(np.uint8))


def make_ground_sheet(fname, painter, variants=4, tile=64):
    sheet = Image.new("RGBA", (tile * variants, tile), (0, 0, 0, 0))
    for i in range(variants):
        t = paper_base((tile, tile))
        d = ImageDraw.Draw(t, "RGBA")
        painter(d, tile, i)
        t = t.filter(ImageFilter.GaussianBlur(0.4))
        sheet.paste(t, (i * tile, 0))
    sheet.save(os.path.join(TILES, fname))
    print("saved tiles/" + fname)


# ---------- 地砖绘制 ----------

def paint_paper(d, tile, i):
    if random.random() > 0.4:
        x, y = random.randint(0, tile - 20), random.randint(0, tile - 20)
        r = random.randint(16, 32)
        d.ellipse([x, y, x + r, y + r], fill=(185, 180, 166, 14))
    for _ in range(random.randint(2, 5)):
        x, y = random.randint(0, tile), random.randint(0, tile)
        d.point((x, y), fill=(150, 145, 130, 90))


def paint_grass(d, tile, i):
    for _ in range(random.randint(28, 42)):
        x, y = random.randint(2, tile - 2), random.randint(2, tile - 2)
        ln = random.randint(6, 15)
        ang = random.uniform(-2.0, -1.1)
        x2, y2 = x + math.cos(ang) * ln, y + math.sin(ang) * ln
        col = SAGE if random.random() > 0.4 else SAGE_DARK
        d.line([(x, y), (x2, y2)], fill=col + (random.randint(110, 190),), width=2)
    for _ in range(random.randint(0, 2)):
        x, y = random.randint(4, tile - 8), random.randint(4, tile - 8)
        d.ellipse([x, y, x + 6, y + 4], fill=(SAGE_DARK + (70,)))


def paint_path(d, tile, i):
    d.rectangle([0, 0, tile, tile], fill=PATH + (255,))
    for _ in range(64):
        x, y = random.randint(0, tile - 1), random.randint(0, tile - 1)
        r = random.randint(1, 3)
        c = random.choice([(201, 185, 152), (190, 175, 145), (212, 199, 172)])
        d.ellipse([x - r, y - r, x + r, y + r], fill=c + (150,))
    for _ in range(3):
        x, y = random.randint(4, tile - 12), random.randint(4, tile - 10)
        d.ellipse([x, y, x + 9, y + 6], fill=(183, 169, 140, 210), outline=(148, 136, 110, 220))


def paint_water(d, tile, i):
    d.rectangle([0, 0, tile, tile], fill=WATER + (255,))
    for _ in range(5):
        y = random.randint(4, tile - 4)
        x0 = random.randint(0, tile // 2)
        x1 = x0 + random.randint(tile // 3, tile - 6)
        d.line([(x0, y), (x1, y)], fill=WATER_LINE + (130,), width=2)
    for _ in range(3):
        x, y = random.randint(4, tile - 12), random.randint(4, tile - 6)
        d.line([(x, y), (x + 11, y)], fill=(238, 243, 245, 170), width=2)


# ---------- 道具绘制 ----------

def draw_tree(w=140, h=190):
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(img, "RGBA")
    cx, base_y = w // 2, h - 10
    top = int(h * 0.52)
    d.line([(cx, base_y), (cx + random.randint(-4, 4), top)], fill=(62, 54, 46, 255), width=11)
    for _ in range(6):  # 淡墨光晕
        rx, ry = random.randint(28, 42), random.randint(20, 30)
        x, y = cx + random.randint(-30, 30), int(h * 0.30) + random.randint(-18, 18)
        d.ellipse([x - rx, y - ry, x + rx, y + ry], fill=(INK_SOFT + (55,)))
    for _ in range(9):  # 浓墨树冠
        rx, ry = random.randint(20, 36), random.randint(15, 26)
        x, y = cx + random.randint(-28, 28), int(h * 0.30) + random.randint(-16, 16)
        d.ellipse([x - rx, y - ry, x + rx, y + ry], fill=(INK + (random.randint(165, 225),)))
    for _ in range(6):  # 印章红果
        x, y = cx + random.randint(-30, 30), int(h * 0.28) + random.randint(-16, 16)
        d.ellipse([x - 3, y - 3, x + 3, y + 3], fill=(RED + (225,)))
    return img


def draw_hut(w=230, h=210, roof_dark=True):
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(img, "RGBA")
    wall_top = int(h * 0.44)
    d.rectangle([w * 0.18, wall_top, w * 0.82, h - 10], fill=(238, 231, 215, 255), outline=(42, 42, 48, 255), width=4)
    roof = (38, 38, 44, 255) if roof_dark else (56, 54, 58, 255)
    d.polygon([(w * 0.05, wall_top + 8), (w * 0.5, int(h * 0.10)), (w * 0.95, wall_top + 8)], fill=roof)
    d.line([(w * 0.05, wall_top + 8), (w * 0.5, int(h * 0.10)), (w * 0.95, wall_top + 8)], fill=(24, 24, 28, 255), width=6)
    d.line([(w * 0.16, wall_top + 16), (w * 0.84, wall_top + 16)], fill=(RED + (210,)), width=4)  # 飞檐红饰
    d.rectangle([w / 2 - 18, h - 76, w / 2 + 18, h - 10], fill=(74, 64, 54, 255), outline=(32, 30, 28, 255), width=3)
    for wx in (w * 0.30, w * 0.70):
        d.rectangle([wx - 17, wall_top + 36, wx + 17, wall_top + 70], fill=(224, 216, 198, 255), outline=(42, 42, 48, 255), width=3)
        d.line([(wx - 17, wall_top + 53), (wx + 17, wall_top + 53)], fill=(42, 42, 48, 255), width=2)
        d.line([(wx, wall_top + 36), (wx, wall_top + 70)], fill=(42, 42, 48, 255), width=2)
    d.ellipse([w * 0.80, wall_top + 18, w * 0.80 + 17, wall_top + 35], fill=(RED + (240,)))  # 红灯笼
    return img


def draw_rock(w=110, h=86):
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(img, "RGBA")
    pts = [(w * 0.5, 6), (w * 0.88, h * 0.42), (w * 0.78, h - 8), (w * 0.2, h - 8), (w * 0.1, h * 0.4)]
    d.polygon(pts, fill=(150, 148, 140, 255), outline=(52, 52, 58, 255))
    d.line([(w * 0.3, h * 0.35), (w * 0.55, h * 0.6)], fill=(92, 92, 98, 220), width=3)
    d.line([(w * 0.55, h * 0.6), (w * 0.7, h * 0.5)], fill=(92, 92, 98, 200), width=2)
    d.ellipse([w * 0.18, h * 0.28, w * 0.5, h * 0.62], fill=(172, 170, 162, 90))
    return img


def draw_bush(w=96, h=70):
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(img, "RGBA")
    for _ in range(7):
        rx, ry = random.randint(14, 24), random.randint(10, 16)
        x, y = random.randint(20, w - 20), random.randint(22, h - 18)
        d.ellipse([x - rx, y - ry, x + rx, y + ry], fill=(SAGE_DARK + (random.randint(170, 225),)))
    for _ in range(4):
        x, y = random.randint(16, w - 16), random.randint(18, h - 16)
        d.ellipse([x - 3, y - 3, x + 3, y + 3], fill=(RED + (225,)))
    return img


def draw_fence(w=128, h=58):
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(img, "RGBA")
    for px in range(10, w - 4, 34):
        d.line([(px, 8), (px, h - 6)], fill=(WOOD + (255,)), width=7)
    for ly in (20, h - 16):
        d.line([(2, ly), (w - 2, ly)], fill=(WOOD + (255,)), width=5)
    return img


def draw_flower(size=30):
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(img, "RGBA")
    d.line([(size // 2, size - 2), (size // 2, size // 2 + 2)], fill=(SAGE_DARK + (255,)), width=2)
    d.ellipse([size // 2 - 7, size // 2 - 9, size // 2 + 7, size // 2 + 5], fill=(RED + (238,)))
    d.ellipse([size // 2 - 2, size // 2 - 4, size // 2 + 2, size // 2], fill=(242, 228, 208, 255))
    return img


def main():
    # 地砖图集（各 4 变体横向排列，每格 64px）
    make_ground_sheet("paper.png", paint_paper)
    make_ground_sheet("grass.png", paint_grass)
    make_ground_sheet("path.png", paint_path)
    make_ground_sheet("water.png", paint_water)
    # 道具
    draw_tree().save(os.path.join(PROPS, "tree.png"))
    draw_tree().save(os.path.join(PROPS, "tree2.png"))
    draw_hut(roof_dark=True).save(os.path.join(PROPS, "hut.png"))
    draw_hut(roof_dark=False).save(os.path.join(PROPS, "hut2.png"))
    draw_rock().save(os.path.join(PROPS, "rock.png"))
    draw_bush().save(os.path.join(PROPS, "bush.png"))
    draw_fence().save(os.path.join(PROPS, "fence.png"))
    draw_flower().save(os.path.join(PROPS, "flower.png"))
    print("saved props/ 全部道具")
    print("完成：assets/ 目录已生成。")


if __name__ == "__main__":
    main()
