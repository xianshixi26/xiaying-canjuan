# -*- coding: utf-8 -*-
"""
《侠影残卷》场景预览合成器：用生成的素材拼一张落雁村效果预览图（供美术拍板）。
输出：assets/preview_v2.png
"""
import os
import math
import random

from PIL import Image, ImageDraw, ImageFilter, ImageFont

random.seed(7)
ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
TILES = os.path.join(ROOT, "assets", "tiles")
PROPS = os.path.join(ROOT, "assets", "props")

W, H = 960, 640
T = 64


def load(name, folder=PROPS):
    return Image.open(os.path.join(folder, name)).convert("RGBA")


def main():
    canvas = Image.new("RGBA", (W, H), (232, 224, 204, 255))
    d = ImageDraw.Draw(canvas, "RGBA")

    # ---- 地面铺装 ----
    sheets = {k: load(k + ".png", TILES) for k in ("paper", "grass", "path", "water")}

    def tile_of(col, row):
        if col in (6, 7) or row in (4, 5):
            return "path"
        if col >= 11 and row >= 7 and ((col - 12.5) / 2.2) ** 2 + ((row - 8.2) / 1.5) ** 2 <= 1:
            return "water"
        v = math.sin(col * 0.9) * math.cos(row * 0.8) + math.sin((col + row) * 0.5) * 0.6
        return "grass" if v > 0.35 else "paper"

    for row in range(H // T + 1):
        for col in range(W // T + 1):
            kind = tile_of(col, row)
            sheet = sheets[kind]
            vx = random.randint(0, 3) * T
            canvas.paste(sheet.crop((vx, 0, vx + T, T)), (col * T, row * T), sheet.crop((vx, 0, vx + T, T)))

    # ---- 道具 ----
    def place(name, x, y, scale=1.0):
        img = load(name)
        if scale != 1.0:
            img = img.resize((int(img.width * scale), int(img.height * scale)), Image.LANCZOS)
        canvas.alpha_composite(img, (x, y))

    place("hut.png", 40, 20, 1.0)
    place("hut2.png", 580, 20, 1.0)
    place("hut.png", 150, 385, 0.9)
    place("tree.png", 415, 330, 0.9)
    place("tree.png", 790, 300, 0.85)
    place("pine.png", 420, 15, 0.8)
    place("pine.png", 40, 300, 0.75)
    place("pine.png", 620, 420, 0.75)
    place("rock.png", 500, 310, 1.0)
    place("rock.png", 240, 255, 1.0)
    place("bush.png", 380, 190, 1.0)
    place("bush.png", 760, 250, 1.0)
    place("bush.png", 560, 130, 1.0)
    place("bush.png", 120, 240, 1.0)
    place("bush.png", 700, 560, 1.0)
    for fx, fy in [(450, 250), (480, 275), (330, 300), (360, 325), (620, 300), (650, 325), (790, 190), (820, 225), (520, 600), (560, 585)]:
        place("flower.png", fx, fy, 1.0)
    for i in range(2):
        place("fence.png", 620 + i * 140, 385, 1.0)

    # 角色（像素小人）
    def place_actor(name, x, y, frame=0, flip=False):
        sheet = load(name, os.path.join(ROOT, "assets", "actors"))
        fr = sheet.crop((frame * 64, 0, frame * 64 + 64, 64))
        if flip:
            fr = fr.transpose(Image.FLIP_LEFT_RIGHT)
        canvas.alpha_composite(fr, (x, y))

    place_actor("hero.png", 470, 300, 1)
    place_actor("brigand.png", 640, 265, 1)
    place_actor("brigand.png", 330, 470, 3, flip=True)
    place_actor("brigand.png", 780, 210, 0)

    # ---- 画意收边：暗角 + 册页边框 + 朱印 ----
    vign = Image.new("L", (W, H), 0)
    dv = ImageDraw.Draw(vign)
    dv.ellipse([-W * 0.25, -H * 0.25, W * 1.25, H * 1.25], fill=255)
    vign = vign.filter(ImageFilter.GaussianBlur(80))
    dark = Image.new("RGBA", (W, H), (72, 62, 48, 255))
    canvas = Image.composite(canvas, Image.alpha_composite(canvas, dark), vign)
    d = ImageDraw.Draw(canvas, "RGBA")
    d.rectangle([0, 0, W - 1, H - 1], outline=(62, 54, 42, 255), width=8)
    d.rectangle([12, 12, W - 13, H - 13], outline=(62, 54, 42, 160), width=2)
    # 朱红印章
    d.rounded_rectangle([W - 108, H - 108, W - 36, H - 36], 8, fill=(180, 40, 31, 235))
    try:
        font = ImageFont.truetype("C:/Windows/Fonts/simhei.ttf", 30)
    except OSError:
        font = ImageFont.load_default()
    d.text((W - 92, H - 98), "侠\n影", font=font, fill=(242, 232, 216, 255), spacing=4)

    canvas.convert("RGB").save(os.path.join(ROOT, "assets", "preview_v2.png"))
    print("saved assets/preview_v2.png")


if __name__ == "__main__":
    main()
