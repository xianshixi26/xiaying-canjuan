# -*- coding: utf-8 -*-
"""
《侠影残卷》像素风素材生成器 v5
依 pixel-art-sprites 技能规范（patterns / sharp_edges / validations）：
- 统一光源：左上 45°（top-down 物件用顶光变体），暗部只在右下，禁止枕头式着色
- 色阶带色相偏移：暗部偏蓝紫、亮部偏暖黄
- 只用有序抖动（棋盘/四分之一），禁止随机噪点
- 选择性描边：仅外轮廓 1px #1A1A2E，内部不描
- 色数硬约束：小道具 4-6 色，建筑/树 10-14 色
- 纯不透明像素（alpha 255/0），PNG 无损，4x 整数放大（NEAREST）
输出：assets/tiles/*.png + assets/props/*.png（同名替换）
"""
import os
import math
import random

from PIL import Image, ImageDraw

random.seed(42)

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
TILES = os.path.join(ROOT, "assets", "tiles")
PROPS = os.path.join(ROOT, "assets", "props")
ACTORS = os.path.join(ROOT, "assets", "actors")
os.makedirs(TILES, exist_ok=True)
os.makedirs(PROPS, exist_ok=True)
os.makedirs(ACTORS, exist_ok=True)

K = 4  # 整数放大（sharp edge: integer scaling only）

# ================= 色板（带色相偏移的色阶） =================
OUTLINE = (26, 26, 46, 255)          # 共用描边 #1A1A2E

G_D = (140, 126, 100, 255)           # 石/纸地：暖阶
G_M = (176, 162, 132, 255)
G_L = (210, 198, 166, 255)
G_XL = (236, 226, 198, 255)

GR_D = (46, 74, 48, 255)             # 草绿：暗部偏蓝绿
GR_M = (70, 104, 47, 255)
GR_L = (100, 140, 62, 255)
GR_XL = (143, 178, 87, 255)          # 亮部偏暖黄

R_D = (46, 50, 72, 255)              # 瓦：冷灰蓝阶
R_M = (69, 75, 102, 255)
R_L = (95, 103, 136, 255)
R_XL = (124, 134, 172, 255)

RD_D = (126, 42, 36, 255)            # 朱红：亮部偏橙
RD_M = (168, 58, 46, 255)
RD_L = (204, 90, 66, 255)
RD_XL = (232, 134, 95, 255)

W_D = (84, 56, 42, 255)              # 木
W_M = (122, 82, 54, 255)
W_L = (162, 114, 74, 255)
W_XL = (194, 146, 104, 255)

WA_D = (46, 88, 114, 255)            # 水：暗部强偏蓝
WA_M = (62, 122, 150, 255)
WA_L = (92, 160, 184, 255)
WA_XL = (134, 194, 210, 255)

GOLD_D = (176, 120, 48, 255)
GOLD_L = (240, 208, 128, 255)

PK_D = (188, 92, 110, 255)           # 粉
PK_L = (232, 150, 162, 255)


# ================= 像素工具 =================

def new_px(w, h):
    return Image.new("RGBA", (w, h), (0, 0, 0, 0))


def dither_checker(d, x0, y0, x1, y1, c1, c2):
    """50% 有序抖动（棋盘）——技能指定的合法过渡"""
    for y in range(int(y0), int(y1) + 1):
        for x in range(int(x0), int(x1) + 1):
            d.point((x, y), fill=c1 if (x + y) % 2 == 0 else c2)


def dither_quarter(d, x0, y0, x1, y1, c1, c2):
    """25% 有序抖动"""
    for y in range(int(y0), int(y1) + 1):
        for x in range(int(x0), int(x1) + 1):
            d.point((x, y), fill=c1 if (x % 2 == 0 and y % 2 == 0) else c2)


def outline(img, color=OUTLINE):
    """选择性描边：仅外轮廓 1px（技能规范）"""
    src = img.load()
    w, h = img.size
    pts = []
    for y in range(h):
        for x in range(w):
            if src[x, y][3] == 0:
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    nx, ny = x + dx, y + dy
                    if 0 <= nx < w and 0 <= ny < h and src[nx, ny][3] > 0:
                        pts.append((x, y))
                        break
    for (x, y) in pts:
        img.putpixel((x, y), color)


def shade_box(d, x0, y0, x1, y1, base, light, dark):
    """方向性着色：左上受光、右下背光（禁止枕头式）"""
    d.rectangle([x0, y0, x1, y1], fill=base)
    d.line([(x0, y0), (x1, y0)], fill=light)          # 顶边受光
    d.line([(x0, y0), (x0, y1)], fill=light)          # 左边受光
    d.line([(x0, y1), (x1, y1)], fill=dark)           # 底边背光
    d.line([(x1, y0), (x1, y1)], fill=dark)           # 右边背光


def save(img, rel_dir, name):
    out = img.resize((img.width * K, img.height * K), Image.NEAREST)
    out.save(os.path.join(rel_dir, name))
    print("saved", name)


# ================= 地砖（16x16 逻辑px，顶光，3-4 变体防重复） =================

def tile_paper(i):
    img = new_px(16, 16)
    d = ImageDraw.Draw(img)
    d.rectangle([0, 0, 15, 15], fill=G_XL)
    # 有序抖动补丁（禁止随机噪点）
    if i % 2 == 0:
        dither_quarter(d, 2, 2, 7, 7, G_L, G_XL)
    else:
        dither_quarter(d, 8, 9, 13, 13, G_L, G_XL)
    if i == 2:
        d.line([(3, 12), (6, 11), (10, 12)], fill=G_L)
    return img


def tile_grass(i):
    """密草皮：绿底 + 亮/暗斑（有序抖动）+ 密草叶 + 花点缀"""
    img = new_px(16, 16)
    d = ImageDraw.Draw(img)
    d.rectangle([0, 0, 15, 15], fill=GR_M)
    dither_quarter(d, 1, 1, 6, 5, GR_L, GR_M)      # 左上受光斑
    dither_quarter(d, 9, 9, 14, 14, GR_D, GR_M)    # 右下背光斑
    rng = random.Random(20 + i)
    for _ in range(16):  # 密草叶
        x, y = rng.randint(1, 14), rng.randint(3, 15)
        col = [GR_XL, GR_L, GR_D][rng.randint(0, 2)]
        d.line([(x, y), (x, y - rng.randint(1, 3))], fill=col)
    for _ in range(4):   # 草根暗点（地面纹理）
        d.point((rng.randint(0, 15), rng.randint(0, 15)), fill=GR_D)
    if i % 2 == 0:
        d.point((rng.randint(2, 13), rng.randint(3, 13)), fill=PK_L)
        d.point((rng.randint(2, 13), rng.randint(3, 13)), fill=GOLD_L)
    return img


def tile_path(i):
    img = new_px(16, 16)
    d = ImageDraw.Draw(img)
    d.rectangle([0, 0, 15, 15], fill=G_D)  # 石缝
    rng = random.Random(30 + i)
    stones = [(1, 1, 7, 6), (9, 1, 14, 5), (1, 8, 6, 14), (8, 7, 15, 13)]
    for (x0, y0, x1, y1) in stones:
        jx, jy = rng.randint(-1, 1), rng.randint(-1, 1)
        bx0, by0, bx1, by1 = x0 + jx, y0 + jy, x1 + jx, y1 + jy
        d.rectangle([bx0, by0, bx1, by1], fill=G_M)
        d.line([(bx0, by0), (bx1, by0)], fill=G_L)     # 顶边受光
        d.line([(bx0, by0), (bx0, by1)], fill=G_L)     # 左边受光
        d.line([(bx0, by1), (bx1, by1)], fill=G_D)     # 底边背光
        d.line([(bx1, by0), (bx1, by1)], fill=G_D)     # 右边背光
    return img


def tile_water(i):
    img = new_px(16, 16)
    d = ImageDraw.Draw(img)
    d.rectangle([0, 0, 15, 15], fill=WA_M)
    rng = random.Random(40 + i)
    for k in range(2):
        y = 3 + k * 6 + rng.randint(0, 1)
        x0 = rng.randint(0, 3)
        x1 = rng.randint(9, 15)
        d.line([(x0, y), (x1, y)], fill=WA_L)          # 波峰受光
        d.line([(x0, y + 2), (x1, y + 2)], fill=WA_D)  # 波谷背光
    dither_checker(d, 0, 12, 6, 15, WA_M, WA_D)
    if i % 2 == 0:
        d.point((rng.randint(2, 13), rng.randint(2, 8)), fill=WA_XL)
    return img


def make_tile_sheet(name, fn):
    sheet = new_px(64, 16)
    for i in range(4):
        sheet.paste(fn(i), (i * 16, 0))
    save(sheet, TILES, name)


# ================= 道具 =================

def sprite_hut(red=True):
    """村屋 64x64：左上光源；瓦面左浅右深；墙体顶左受光底右背光"""
    img = new_px(64, 64)
    d = ImageDraw.Draw(img)

    # ---- 屋顶（左坡受光 R_L，右坡背光 R_D，中带 R_M） ----
    for y in range(10, 32):
        f = (y - 10) / 22.0
        xa = int(16 - 12 * f)
        xb = int(47 + 12 * f)
        xm = (xa + xb) // 2
        d.line([(xa, y), (xm, y)], fill=R_L)       # 左坡受光
        d.line([(xm, y), (xb, y)], fill=R_D)       # 右坡背光
        if y % 3 == 0:
            dither_checker(d, xm - 1, y, xm + 1, y, R_L, R_D)  # 坡面过渡
    # 瓦行（横向节律）
    for y in range(11, 32, 3):
        f = (y - 10) / 22.0
        xa = int(16 - 12 * f)
        xb = int(47 + 12 * f)
        d.line([(xa, y), (xb, y)], fill=R_M)
    # 亮部瓦当高光（仅左上区）
    for x in range(6, 28, 3):
        d.point((x, 14 + (x - 6) // 6), fill=R_XL)
    # 檐口
    for x in range(3, 60, 3):
        d.point((x, 32), fill=R_D)
        d.point((x + 1, 33), fill=R_M)
    # 脊 + 红饰
    shade_box(d, 14, 7, 49, 10, R_M, R_XL, R_D)
    d.point((13, 8), fill=RD_M)
    d.point((50, 8), fill=RD_M)
    d.line([(52, 7), (55, 4)], fill=RD_M)
    d.point((55, 3), fill=RD_L)

    # ---- 墙体（顶左受光、底右背光） ----
    if red:
        base, light, dark = RD_M, RD_L, RD_D
    else:
        base, light, dark = G_XL, (252, 246, 232, 255), G_L
    shade_box(d, 10, 33, 53, 56, base, light, dark)
    dither_checker(d, 10, 50, 53, 52, base, dark)   # 底部过渡

    # 木构
    d.rectangle([10, 33, 12, 56], fill=W_D)
    d.rectangle([51, 33, 53, 56], fill=W_D)
    shade_box(d, 10, 36, 53, 37, W_M, W_L, W_D)

    # 窗（暖光 + 格纹）
    for wx in (16, 38):
        shade_box(d, wx, 41, wx + 9, 49, W_D, W_L, W_D)
        d.rectangle([wx + 1, 42, wx + 8, 48], fill=GOLD_L)
        d.rectangle([wx + 1, 42, wx + 8, 43], fill=(252, 232, 168, 255))
        d.line([(wx + 4, 42), (wx + 4, 48)], fill=W_D)
        d.line([(wx + 1, 45), (wx + 8, 45)], fill=W_D)
    # 门（左受光）
    shade_box(d, 28, 43, 35, 56, W_M, W_L, W_D)
    d.point((33, 49), fill=GOLD_L)
    d.point((34, 49), fill=GOLD_D)

    # 石基
    shade_box(d, 8, 57, 55, 61, G_M, G_L, G_D)
    for x in range(12, 55, 7):
        d.line([(x, 58), (x, 61)], fill=G_D)

    # 灯笼
    for cx in (5, 58):
        shade_box(d, cx - 2, 34, cx + 1, 39, RD_M, RD_L, RD_D)
        d.line([(cx - 2, 36), (cx + 1, 36)], fill=GOLD_D)
        d.point((cx, 41), fill=GOLD_D)

    outline(img)
    return img


def sprite_willow():
    """柳树 48x64：剪影优先——圆顶 + 垂丝，左上受光"""
    img = new_px(48, 64)
    d = ImageDraw.Draw(img)
    # 干（左受光）
    d.rectangle([21, 30, 25, 60], fill=W_M)
    d.line([(21, 30), (21, 60)], fill=W_L)
    d.line([(25, 30), (25, 60)], fill=W_D)
    d.line([(22, 34), (14, 26)], fill=W_M)
    d.line([(24, 32), (33, 23)], fill=W_D)

    # 冠层剪影（非对称圆顶）
    canopy = []
    for (cx, cy, rx, ry) in [(23, 21, 17, 10), (17, 23, 11, 7), (30, 22, 11, 7), (23, 16, 13, 7)]:
        for y in range(cy - ry, cy + ry + 1):
            for x in range(cx - rx, cx + rx + 1):
                if ((x - cx) / rx) ** 2 + ((y - cy) / ry) ** 2 <= 1.0:
                    canopy.append((x, y))
    canopy = set(canopy)
    for (x, y) in canopy:
        # 左上受光判定
        if x + y <= 34:
            col = GR_L if (x + y) % 2 == 0 else GR_M
        elif x + y >= 50:
            col = GR_D if (x + y) % 2 == 0 else GR_M
        else:
            col = GR_M
        d.point((x, y), fill=col)
    # 顶部高光点（暖黄移）
    for (x, y) in [(18, 13), (22, 11), (26, 12), (15, 17), (30, 15)]:
        if (x, y) in canopy:
            d.point((x, y), fill=GR_XL)

    # 垂丝（长短错落、非对称）
    rng = random.Random(77)
    for i in range(9):
        sx = rng.randint(9, 38)
        sy = rng.randint(26, 30)
        ln = rng.randint(12, 26)
        col = GR_M
        for k in range(ln):
            x = sx + (1 if k > ln // 2 and i % 2 else 0)
            d.point((x, sy + k), fill=col)
            if k % 4 == 2:
                d.point((x - 1, sy + k), fill=GR_L)
                d.point((x + 1, sy + k + 1), fill=GR_D)
    # 红果（左上受光）
    for (x, y) in [(13, 18), (31, 19), (24, 12), (17, 25), (33, 14)]:
        d.point((x, y), fill=RD_L)
        d.point((x + 1, y + 1), fill=RD_D)
    outline(img)
    return img


def sprite_pine():
    """松树 48x64：三层伞形剪影，左上受光"""
    img = new_px(48, 64)
    d = ImageDraw.Draw(img)
    d.rectangle([21, 36, 25, 60], fill=W_M)
    d.line([(21, 36), (21, 60)], fill=W_L)
    d.line([(25, 36), (25, 60)], fill=W_D)
    tiers = [(31, 21), (21, 16), (12, 11)]
    for ti, (ty, half) in enumerate(tiers):
        rows = []
        for y in range(ty - 8, ty + 9):
            f = 1.0 - abs(y - ty) / 9.0
            w = int(half * f)
            rows.append((y, 24 - w, 24 + w))
        for (y, xa, xb) in rows:
            for x in range(xa, xb + 1):
                # 左上受光 / 右下背光
                if x - xa < (xb - xa) * 0.35 and y < ty + 2:
                    col = GR_L if (x + y) % 2 == 0 else GR_M
                elif x > xa + (xb - xa) * 0.7 and y > ty - 2:
                    col = GR_D if (x + y) % 2 == 0 else GR_M
                else:
                    col = GR_M
                d.point((x, y), fill=col)
        for x in range(24 - half + 1, 24 + half, 3):
            d.point((x, ty + 8), fill=GR_D)
    for (x, y) in [(15, 26), (31, 29), (24, 17)]:
        d.point((x, y), fill=RD_L)
        d.point((x + 1, y + 1), fill=RD_D)
    outline(img)
    return img


def sprite_rock():
    """岩石 24x16：左上受光斜面"""
    img = new_px(24, 16)
    d = ImageDraw.Draw(img)
    pts = [(3, 14), (2, 8), (6, 3), (13, 2), (20, 6), (21, 12), (16, 15), (8, 15)]
    d.polygon(pts, fill=G_M)
    d.polygon([(4, 8), (7, 4), (12, 3), (10, 8)], fill=G_L)    # 左上受光面
    d.polygon([(14, 4), (19, 7), (19, 11), (14, 9)], fill=G_D)  # 右下背光面
    d.line([(10, 9), (13, 12)], fill=G_D)
    d.point((6, 4), fill=GR_M)
    d.point((8, 3), fill=GR_L)
    outline(img)
    return img


def sprite_bush():
    """灌木 20x14：左上受光"""
    img = new_px(20, 14)
    d = ImageDraw.Draw(img)
    blob = set()
    for (cx, cy, rx, ry) in [(10, 8, 9, 5), (6, 8, 5, 4), (14, 8, 5, 4), (10, 5, 6, 3)]:
        for y in range(cy - ry, cy + ry + 1):
            for x in range(cx - rx, cx + rx + 1):
                if ((x - cx) / rx) ** 2 + ((y - cy) / ry) ** 2 <= 1.0:
                    blob.add((x, y))
    for (x, y) in blob:
        if x + y <= 13:
            col = GR_L if (x + y) % 2 == 0 else GR_M
        elif x + y >= 21:
            col = GR_D if (x + y) % 2 == 0 else GR_M
        else:
            col = GR_M
        d.point((x, y), fill=col)
    for (x, y) in [(5, 6), (13, 5), (10, 9), (15, 8)]:
        d.point((x, y), fill=RD_L)
        d.point((x + 1, y + 1), fill=RD_D)
    outline(img)
    return img


def sprite_fence():
    """竹篱 32x12：立柱与横杆左受光"""
    img = new_px(32, 12)
    d = ImageDraw.Draw(img)
    for px in (3, 12, 21, 29):
        shade_box(d, px - 1, 2, px + 1, 11, W_M, W_L, W_D)
        d.point((px, 6), fill=W_D)
    shade_box(d, 1, 4, 30, 5, W_M, W_L, W_D)
    shade_box(d, 1, 8, 30, 9, W_M, W_L, W_D)
    outline(img)
    return img


def sprite_flower():
    """花丛 8x8：4-6 色小道具"""
    img = new_px(8, 8)
    d = ImageDraw.Draw(img)
    d.line([(2, 7), (2, 4)], fill=GR_D)
    d.line([(5, 7), (5, 3)], fill=GR_D)
    d.point((1, 5), fill=GR_M)
    d.point((2, 2), fill=PK_L)   # 左上受光
    d.point((1, 3), fill=PK_L)
    d.point((3, 3), fill=PK_D)   # 右下背光
    d.point((5, 1), fill=RD_L)
    d.point((4, 2), fill=RD_L)
    d.point((6, 2), fill=RD_D)
    d.point((2, 3), fill=GOLD_L)
    outline(img)
    return img


# ================= 角色（16x16 逻辑px / 4帧行走，技能动画规范） =================
SK_D = (150, 96, 72, 255)            # 肤色阶（暖）
SK_M = (200, 140, 104, 255)
SK_L = (232, 180, 140, 255)
HAIR = (40, 38, 58, 255)
HAIR_L = (66, 62, 88, 255)
RB_D = (52, 72, 110, 255)            # 主角衣袍（蓝灰阶）
RB_M = (74, 100, 146, 255)
RB_L = (102, 132, 182, 255)
STEEL_D = (120, 128, 152, 255)
STEEL_L = (186, 194, 216, 255)


def sprite_actor(hero=True, frame=0):
    """16x16 侧视小人；frame 0-3 行走循环（技能：4 帧 > 12 平庸帧）"""
    img = new_px(16, 16)
    d = ImageDraw.Draw(img)
    bob = 1 if frame in (1, 3) else 0
    if hero:
        body, body_l, body_d = RB_M, RB_L, RB_D
        head_top = HAIR
    else:
        body, body_l, body_d = W_M, W_L, W_D
        head_top = RD_M  # 红头巾=敌对标识

    # 腿（帧间交替）
    if frame == 0 or frame == 2:
        d.rectangle([5, 12 - bob, 6, 15], fill=body_d)
        d.rectangle([8, 12 - bob, 9, 15], fill=body_d)
    elif frame == 1:
        d.rectangle([3, 12 - bob, 4, 15], fill=body_d)
        d.rectangle([10, 12 - bob, 11, 14], fill=body_d)
    else:
        d.rectangle([10, 12 - bob, 11, 15], fill=body_d)
        d.rectangle([3, 12 - bob, 4, 14], fill=body_d)
    # 身（左受光）
    d.rectangle([4, 7 - bob, 11, 12 - bob], fill=body)
    d.line([(4, 7 - bob), (4, 12 - bob)], fill=body_l)
    d.line([(11, 7 - bob), (11, 12 - bob)], fill=body_d)
    d.line([(4, 11 - bob), (11, 11 - bob)], fill=(RD_M if hero else RD_D))  # 腰带/红饰
    # 臂（随帧摆动）
    swing = 0 if frame in (0, 2) else (1 if frame == 1 else -1)
    d.rectangle([2, 8 - bob + swing, 3, 11 - bob + swing], fill=body_l if hero else body)
    d.rectangle([12, 8 - bob - swing, 13, 11 - bob - swing], fill=body_d)
    # 头
    d.rectangle([5, 3 - bob, 10, 7 - bob], fill=SK_M)
    d.line([(5, 3 - bob), (5, 7 - bob)], fill=SK_L)
    d.rectangle([5, 1 - bob, 10, 3 - bob], fill=head_top)   # 发/头巾
    if hero:
        d.line([(5, 1 - bob), (5, 2 - bob)], fill=HAIR_L)
        d.point((7, 5 - bob), fill=HAIR)                    # 眼
        d.point((9, 5 - bob), fill=HAIR)
        # 背剑
        d.line([(11, 4 - bob), (13, 1 - bob)], fill=STEEL_D)
        d.point((13, 1 - bob), fill=STEEL_L)
    else:
        d.point((10, 2 - bob), fill=RD_L)                   # 头巾结
        d.point((7, 5 - bob), fill=HAIR)                    # 怒目
        d.point((9, 5 - bob), fill=HAIR)
        d.point((6, 4 - bob), fill=HAIR)
        d.point((10, 4 - bob), fill=HAIR)
        # 短刀
        d.line([(13, 8 - bob), (14, 10 - bob)], fill=STEEL_L)
        d.point((13, 11 - bob), fill=W_D)
    outline(img)
    return img


def make_actor_sheet(name, hero):
    sheet = new_px(64, 16)
    for i in range(4):
        sheet.paste(sprite_actor(hero, i), (i * 16, 0))
    save(sheet, ACTORS, name)


# ================= 环境/室内/特效/武器（D-023） =================

def tile_wall(i):
    """室内墙：灰砖 + 木梁"""
    img = new_px(16, 16)
    d = ImageDraw.Draw(img)
    d.rectangle([0, 0, 15, 15], fill=G_M)
    for y in (0, 1, 14, 15):
        d.line([(0, y), (15, y)], fill=W_D)          # 木梁
    for x in range(0, 16, 5):
        d.line([(x, 2), (x, 13)], fill=G_D)          # 砖缝
    for y in (5, 9):
        d.line([(0, y), (15, y)], fill=G_D)
    if i % 2 == 0:
        d.point((3 + i, 3), fill=G_L)
        d.point((11 - i, 11), fill=G_D)
    return img


def sprite_chest(opened=False):
    """宝箱 16x16"""
    img = new_px(16, 16)
    d = ImageDraw.Draw(img)
    if not opened:
        shade_box(d, 2, 6, 13, 13, W_M, W_L, W_D)        # 箱体
        shade_box(d, 2, 3, 13, 6, W_L, W_XL, W_M)        # 箱盖
        d.rectangle([7, 5, 9, 10], fill=GOLD_D)          # 锁扣
        d.point((8, 7), fill=GOLD_L)
    else:
        shade_box(d, 2, 8, 13, 13, W_D, W_M, W_D)        # 箱体（暗）
        shade_box(d, 2, 1, 13, 4, W_L, W_XL, W_M)        # 开启的盖
        d.rectangle([3, 8, 12, 11], fill=(30, 26, 34, 255))
        d.point((6, 9), fill=GOLD_L)                     # 宝光
        d.point((9, 10), fill=GOLD_D)
        d.point((7, 2), fill=GOLD_L)
    outline(img)
    return img


def sprite_clue():
    """调查点 16x16：石碑竹简 + 微光"""
    img = new_px(16, 16)
    d = ImageDraw.Draw(img)
    shade_box(d, 4, 4, 11, 13, G_M, G_L, G_D)            # 石碑
    d.rectangle([6, 6, 9, 11], fill=G_XL)                # 竹简
    d.line([(6, 8), (9, 8)], fill=W_D)
    d.line([(6, 10), (9, 10)], fill=W_D)
    d.point((3, 3), fill=GOLD_L)                         # 微光
    d.point((12, 2), fill=GOLD_L)
    d.point((13, 6), fill=GOLD_D)
    d.point((2, 8), fill=GOLD_D)
    outline(img)
    return img


def sprite_bed():
    """床 32x24（横放）"""
    img = new_px(32, 24)
    d = ImageDraw.Draw(img)
    shade_box(d, 2, 6, 29, 20, W_M, W_L, W_D)            # 床架
    d.rectangle([4, 8, 27, 17], fill=RD_M)               # 被褥
    d.line([(4, 8), (27, 8)], fill=RD_L)
    d.line([(4, 16), (27, 16)], fill=RD_D)
    shade_box(d, 4, 8, 11, 14, G_XL, (252, 246, 232, 255), G_L)  # 枕
    d.line([(18, 8), (18, 17)], fill=RD_D)
    outline(img)
    return img


def sprite_table():
    """桌 24x16"""
    img = new_px(24, 16)
    d = ImageDraw.Draw(img)
    shade_box(d, 1, 3, 22, 7, W_M, W_L, W_D)             # 桌面
    d.rectangle([3, 8, 5, 14], fill=W_D)                 # 腿
    d.rectangle([18, 8, 20, 14], fill=W_D)
    d.point((9, 2), fill=GOLD_L)                         # 茶壶
    d.point((10, 1), fill=GOLD_D)
    outline(img)
    return img


def sprite_shelf():
    """书架 24x32"""
    img = new_px(24, 32)
    d = ImageDraw.Draw(img)
    shade_box(d, 2, 2, 21, 29, W_M, W_L, W_D)
    for y in (9, 17, 25):
        d.line([(3, y), (20, y)], fill=W_D)
    rng = random.Random(9)
    for row_y in (3, 11, 19):
        x = 4
        while x < 19:
            w = rng.randint(2, 3)
            col = [(188, 92, 110, 255), (74, 100, 146, 255), G_L, GOLD_D][rng.randint(0, 3)]
            d.rectangle([x, row_y, x + w, row_y + 5], fill=col)
            x += w + 1
    outline(img)
    return img


def sprite_well():
    """水井 32x32"""
    img = new_px(32, 32)
    d = ImageDraw.Draw(img)
    shade_box(d, 6, 18, 25, 28, G_M, G_L, G_D)           # 井台
    d.rectangle([8, 20, 23, 25], fill=(30, 42, 52, 255)) # 井口
    d.point((12, 22), fill=WA_L)
    d.rectangle([7, 6, 9, 22], fill=W_M)                 # 木架
    d.rectangle([22, 6, 24, 22], fill=W_M)
    shade_box(d, 5, 3, 26, 7, W_L, W_XL, W_D)            # 顶盖
    d.line([(9, 10), (22, 10)], fill=W_D)                # 辘轳
    d.rectangle([14, 10, 17, 15], fill=W_D)
    outline(img)
    return img


def sprite_signpost():
    """告示牌 16x24"""
    img = new_px(16, 24)
    d = ImageDraw.Draw(img)
    d.rectangle([7, 6, 8, 21], fill=W_M)                 # 柱
    d.line([(7, 6), (7, 21)], fill=W_L)
    shade_box(d, 2, 2, 13, 9, W_L, W_XL, W_M)            # 牌
    d.line([(4, 4), (11, 4)], fill=W_D)                  # 字迹
    d.line([(4, 6), (9, 6)], fill=W_D)
    d.point((11, 7), fill=RD_M)                          # 红印
    outline(img)
    return img


def sprite_lantern_post():
    """灯柱 16x32"""
    img = new_px(16, 32)
    d = ImageDraw.Draw(img)
    d.rectangle([7, 10, 8, 29], fill=W_M)                # 柱
    d.line([(7, 10), (7, 29)], fill=W_L)
    shade_box(d, 4, 2, 11, 10, RD_M, RD_L, RD_D)         # 灯笼
    d.line([(4, 5), (11, 5)], fill=GOLD_D)
    d.line([(4, 8), (11, 8)], fill=GOLD_D)
    d.point((7, 12), fill=GOLD_D)                        # 流苏
    d.rectangle([5, 29, 10, 30], fill=W_D)               # 座
    outline(img)
    return img


# ---- 攻击特效（4 帧序列，无描边——技能：特效不描边） ----

def fx_slash(heavy=False):
    img = new_px(64, 16)
    d = ImageDraw.Draw(img)
    core = (236, 226, 198, 255) if not heavy else (240, 208, 128, 255)
    edge = GOLD_L if not heavy else RD_L
    for f in range(4):
        ox = f * 16
        r = 3.5 + f * 1.1
        thick = 2 if f < 3 else 1
        for a10 in range(-70, 71, 4):
            ang = math.radians(a10 * (0.55 + f * 0.16))
            for t in range(thick):
                x = int(5 + math.cos(ang) * (r + t))
                y = int(8 + math.sin(ang) * (r + t) * 0.9)
                if 0 <= x < 16 and 0 <= y < 16:
                    d.point((ox + x, y), fill=edge if t else core)
    return img


def fx_burst():
    img = new_px(64, 16)
    d = ImageDraw.Draw(img)
    for f in range(4):
        ox = f * 16
        r = 2 + f * 1.6
        for a10 in range(0, 360, 6):
            ang = math.radians(a10)
            x = int(8 + math.cos(ang) * r)
            y = int(8 + math.sin(ang) * r * 0.85)
            if 0 <= x < 16 and 0 <= y < 16:
                col = GOLD_L if f < 2 else RD_L
                d.point((ox + x, y), fill=col)
        if f == 0:
            d.rectangle([6, 6, 10, 10], fill=(236, 226, 198, 255))
    return img


def fx_hit():
    img = new_px(64, 16)
    d = ImageDraw.Draw(img)
    for f in range(4):
        ox = f * 16
        r = max(1, 4 - f)
        for (dx, dy) in ((1, 0), (-1, 0), (0, 1), (0, -1), (1, 1), (-1, -1), (1, -1), (-1, 1)):
            x, y = 8 + dx * r, 8 + dy * r
            if 0 <= x < 16 and 0 <= y < 16:
                d.point((ox + x, y), fill=GOLD_L if f < 2 else RD_L)
        d.point((ox + 8, 8), fill=(236, 226, 198, 255))
    return img


def weapon_icons():
    """武器图标 5 帧 16x16：剑/刀/拳掌/暗器/棍"""
    img = new_px(80, 16)
    d = ImageDraw.Draw(img)
    # 0 剑
    d.line([(2, 13), (11, 4)], fill=STEEL_L, width=2)
    d.point((11, 3), fill=(252, 250, 240, 255))
    d.line([(2, 12), (4, 14)], fill=W_D, width=2)
    d.line([(5, 12), (7, 14)], fill=GOLD_D, width=1)
    # 1 刀
    d.line([(18, 13), (27, 5)], fill=STEEL_D, width=3)
    d.line([(19, 11), (26, 5)], fill=STEEL_L, width=1)
    d.line([(17, 12), (19, 14)], fill=W_D, width=2)
    # 2 拳掌
    d.rectangle([36, 6, 43, 12], fill=SK_M)
    d.line([(36, 6), (43, 6)], fill=SK_L)
    d.rectangle([37, 4, 42, 6], fill=SK_M)
    d.point((38, 9), fill=SK_D)
    # 3 暗器
    d.line([(52, 12), (60, 4)], fill=STEEL_L, width=1)
    d.point((60, 3), fill=(252, 250, 240, 255))
    d.point((52, 13), fill=RD_M)
    d.point((51, 12), fill=RD_L)
    # 4 棍
    d.line([(68, 14), (77, 3)], fill=W_M, width=2)
    d.point((68, 14), fill=W_D)
    d.point((77, 3), fill=W_XL)
    return img


def sprite_oracle():
    """卦摊 24x24：桌 + 签筒 + 帆布 + 红灯笼"""
    img = new_px(24, 24)
    d = ImageDraw.Draw(img)
    shade_box(d, 2, 12, 21, 20, W_M, W_L, W_D)            # 桌
    d.rectangle([4, 4, 7, 13], fill=W_D)                  # 竿
    d.rectangle([16, 4, 19, 13], fill=W_D)
    shade_box(d, 3, 2, 20, 6, RD_M, RD_L, RD_D)           # 帆布
    d.rectangle([9, 3, 14, 5], fill=G_XL)                 # "卦"布
    d.point((11, 4), fill=W_D)
    shade_box(d, 9, 8, 13, 13, W_L, W_XL, W_M)            # 签筒
    for x in (10, 11, 12):
        d.line([(x, 6), (x, 8)], fill=GOLD_D)             # 签
        d.point((x, 5), fill=GOLD_L)
    d.ellipse([2, 7, 5, 11], fill=RD_M)                   # 灯笼
    d.point((3, 8), fill=RD_L)
    outline(img)
    return img


def main():
    make_tile_sheet("paper.png", tile_paper)
    make_tile_sheet("grass.png", tile_grass)
    make_tile_sheet("path.png", tile_path)
    make_tile_sheet("water.png", tile_water)
    make_tile_sheet("wall.png", tile_wall)
    save(sprite_hut(True), PROPS, "hut.png")
    save(sprite_hut(False), PROPS, "hut2.png")
    save(sprite_willow(), PROPS, "tree.png")
    save(sprite_willow(), PROPS, "tree2.png")
    save(sprite_pine(), PROPS, "pine.png")
    save(sprite_rock(), PROPS, "rock.png")
    save(sprite_bush(), PROPS, "bush.png")
    save(sprite_fence(), PROPS, "fence.png")
    save(sprite_flower(), PROPS, "flower.png")
    make_actor_sheet("hero.png", True)
    make_actor_sheet("brigand.png", False)
    save(sprite_chest(False), PROPS, "chest.png")
    save(sprite_chest(True), PROPS, "chest_open.png")
    save(sprite_clue(), PROPS, "clue.png")
    save(sprite_bed(), PROPS, "bed.png")
    save(sprite_table(), PROPS, "table.png")
    save(sprite_shelf(), PROPS, "shelf.png")
    save(sprite_well(), PROPS, "well.png")
    save(sprite_signpost(), PROPS, "signpost.png")
    save(sprite_lantern_post(), PROPS, "lantern_post.png")
    save(sprite_oracle(), PROPS, "oracle.png")
    fx = os.path.join(ROOT, "assets", "fx")
    os.makedirs(fx, exist_ok=True)
    sheet = new_px(64, 16)
    for i in range(4):
        sheet.paste(fx_slash(False).crop((i * 16, 0, i * 16 + 16, 16)), (i * 16, 0))
    save(sheet, fx, "fx_slash.png")
    sheet = new_px(64, 16)
    for i in range(4):
        sheet.paste(fx_slash(True).crop((i * 16, 0, i * 16 + 16, 16)), (i * 16, 0))
    save(sheet, fx, "fx_slash_heavy.png")
    save(fx_burst(), fx, "fx_burst.png")
    save(fx_hit(), fx, "fx_hit.png")
    save(weapon_icons(), ACTORS, "weapons.png")
    print("done: assets/ regenerated (v6 pixel: world pack + fx + weapons).")


if __name__ == "__main__":
    main()
