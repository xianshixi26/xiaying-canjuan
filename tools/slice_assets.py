# -*- coding: utf-8 -*-
"""
Meowa AI 素材切片与落位（D-034）：
角色(4x128帧带) / 地砖(4变体x64) / 道具(按契约尺寸) / UI(组件)
"""
import os

from PIL import Image, ImageEnhance

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
OUT = os.path.join(ROOT, "meowa_out")
PROPS = os.path.join(ROOT, "assets", "props")
TILES = os.path.join(ROOT, "assets", "tiles")
ACTORS = os.path.join(ROOT, "assets", "actors")
UI = os.path.join(ROOT, "assets", "ui")
os.makedirs(UI, exist_ok=True)


def cell(sheet, r, c):
    w, h = sheet.size
    return sheet.crop((c * w // 2, r * h // 2, (c + 1) * w // 2, (r + 1) * h // 2))


def fit(img, max_w, max_h):
    """裁内容边界后等比适配"""
    bbox = img.getbbox()
    if bbox:
        img = img.crop(bbox)
    scale = min(max_w / img.width, max_h / img.height)
    return img.resize((max(1, int(img.width * scale)), max(1, int(img.height * scale))), Image.LANCZOS)


def actor_sheet(src_cell, size=128):
    """角色 -> 4 帧行走帧带（轻微起伏伪行走）"""
    fig = fit(src_cell, size - 8, size - 8)
    sheet = Image.new("RGBA", (size * 4, size), (0, 0, 0, 0))
    for i in range(4):
        dy = [0, -2, 0, -2][i]
        dx = [0, 1, 0, -1][i]
        sheet.paste(fig, (i * size + (size - fig.width) // 2 + dx, size - fig.height + dy), fig)
    return sheet


def tile_sheet(src_cell, size=64):
    """地砖 -> 4 变体 x64（中心裁剪保持像素颗粒）"""
    w, h = src_cell.size
    crop = src_cell.crop(((w - 256) // 2, (h - 256) // 2, (w + 256) // 2, (h + 256) // 2))
    base = crop.resize((size, size), Image.NEAREST)
    sheet = Image.new("RGBA", (size * 4, size), (0, 0, 0, 0))
    for i in range(4):
        v = base.copy()
        if i % 2 == 1:
            v = ImageEnhance.Brightness(v).enhance(1.0 + (0.04 if i == 1 else -0.04))
        sheet.paste(v, (i * size, 0))
    return sheet


def prop(src_cell, max_w, max_h):
    return fit(src_cell, max_w, max_h)


def main():
    # ---- 角色 ----
    chars = Image.open(os.path.join(OUT, "chars_cut", "result_images_0_url", "output.png")).convert("RGBA")
    mapping = [((0, 0), "hero.png"), ((1, 0), "brigand.png"), ((0, 1), "boss.png"), ((1, 1), "baiji.png")]
    for (r, c), name in mapping:
        actor_sheet(cell(chars, r, c)).save(os.path.join(ACTORS, name))
        print("actor", name)
    # ---- 地砖 ----
    tiles = Image.open(os.path.join(OUT, "tiles_001", [d for d in os.listdir(os.path.join(OUT, "tiles_001")) if not d.endswith(".json")][0], "result_images_0_url.png")).convert("RGBA")
    tmapping = [((0, 0), "paper.png"), ((1, 0), "grass.png"), ((0, 1), "path.png"), ((1, 1), "water.png")]
    for (r, c), name in tmapping:
        tile_sheet(cell(tiles, r, c)).save(os.path.join(TILES, name))
        print("tile", name)
    # ---- 道具 ----
    props = Image.open(os.path.join(OUT, "props_cut", "result_images_0_url", "output.png")).convert("RGBA")
    pine = fit(cell(props, 0, 0), 300, 300)
    pine.save(os.path.join(PROPS, "pine.png"))
    willow = fit(cell(props, 0, 1), 300, 320)
    willow.save(os.path.join(PROPS, "tree.png"))
    willow2 = ImageEnhance.Brightness(willow).enhance(0.92)
    willow2.save(os.path.join(PROPS, "tree2.png"))
    hut = fit(cell(props, 1, 0), 380, 320)
    hut.save(os.path.join(PROPS, "hut.png"))
    hut2 = ImageEnhance.Color(hut).enhance(0.88)
    hut2.save(os.path.join(PROPS, "hut2.png"))
    rock = fit(cell(props, 1, 1), 200, 160)
    rock.save(os.path.join(PROPS, "rock.png"))
    print("props done")
    # ---- UI ----
    ui = Image.open(os.path.join(OUT, "ui_cut", "result_images_0_url", "output.png")).convert("RGBA")
    fit(cell(ui, 0, 0), 520, 360).save(os.path.join(UI, "panel.png"))
    fit(cell(ui, 1, 0), 300, 110).save(os.path.join(UI, "button.png"))
    fit(cell(ui, 0, 1), 320, 180).save(os.path.join(UI, "bars.png"))
    fit(cell(ui, 1, 1), 160, 160).save(os.path.join(UI, "seal.png"))
    print("ui done")
    print("ALL_SLICED")


if __name__ == "__main__":
    main()
