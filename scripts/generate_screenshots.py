#!/usr/bin/env python3
"""
Generate App Store screenshots for Födelsedagar (Birthday Reminder).
ASO-optimized: AIDA narrative, benefit-driven captions, festive design.

App Store required sizes:
- iPhone 6.7" (1290 x 2796) - iPhone 16 Pro Max  [REQUIRED]
- iPhone 6.5" (1284 x 2778) - iPhone 14 Plus
- iPad 13"   (2064 x 2752)                        [REQUIRED]
"""

from PIL import Image, ImageDraw, ImageFont
import os
import math
import random

# ── Color palette ──────────────────────────────────────────
VIOLET  = (124,  92, 252)
VIOLET2 = ( 99,  69, 228)
SKY     = (103, 195, 243)
MINT    = (110, 231, 183)
MINT2   = ( 52, 211, 153)
CORAL   = (255, 107, 138)
PEACH   = (255, 176, 136)
GOLD    = (251, 191,  36)
WHITE   = (255, 255, 255)
DARK    = ( 26,  26,  46)
GREY    = (107, 114, 128)
LIGHT_BG= (248, 247, 252)

def lerp_color(c1, c2, t):
    t = max(0, min(1, t))
    return tuple(int(c1[i] + (c2[i] - c1[i]) * t) for i in range(3))

def draw_gradient_bg(draw, w, h, c1, c2, c3=None):
    for y in range(h):
        t = y / h
        if c3:
            color = lerp_color(c1, c2, t * 2) if t < 0.5 else lerp_color(c2, c3, (t - 0.5) * 2)
        else:
            color = lerp_color(c1, c2, t)
        draw.line([(0, y), (w, y)], fill=color)

def get_fonts(h):
    sizes = [int(h * s) for s in (0.055, 0.038, 0.024, 0.018, 0.013)]
    fonts = []
    for s in sizes:
        try:
            fonts.append(ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", s))
        except:
            fonts.append(ImageFont.load_default())
    return fonts

def centered_text(draw, text, y, total_w, font, color):
    bbox = draw.textbbox((0, 0), text, font=font)
    tw = bbox[2] - bbox[0]
    draw.text(((total_w - tw) // 2, y), text, fill=color, font=font)

def draw_confetti(draw, w, h, seed=42):
    rng = random.Random(seed)
    colors = [CORAL, VIOLET, GOLD, MINT2, SKY, PEACH]
    for _ in range(90):
        x = rng.randint(0, w)
        y = rng.randint(0, int(h * 0.20))
        r = rng.randint(4, 14)
        c = rng.choice(colors)
        if rng.random() > 0.5:
            draw.ellipse([x - r, y - r, x + r, y + r], fill=c)
        else:
            draw.rectangle([x, y, x + r * 2, y + r], fill=c)
    for _ in range(50):
        x = rng.randint(0, w)
        y = rng.randint(int(h * 0.86), h)
        r = rng.randint(3, 10)
        draw.ellipse([x - r, y - r, x + r, y + r], fill=rng.choice(colors))

def draw_phone_frame(img, x, y, phone_w, phone_h, screen_func):
    draw = ImageDraw.Draw(img, 'RGBA')
    bezel = int(phone_w * 0.04)
    corner_r = int(phone_w * 0.13)
    draw.rounded_rectangle([x, y, x + phone_w, y + phone_h], radius=corner_r, fill=(18, 18, 28))
    sx, sy = x + bezel, y + bezel
    sw, sh = phone_w - bezel * 2, phone_h - bezel * 2
    screen_r = int(corner_r * 0.85)
    draw.rounded_rectangle([sx, sy, sx + sw, sy + sh], radius=screen_r, fill=LIGHT_BG)
    screen_func(draw, sx, sy, sw, sh)
    iw = int(phone_w * 0.28)
    ih = int(phone_h * 0.018)
    ix = x + (phone_w - iw) // 2
    iy = y + bezel + int(phone_h * 0.01)
    draw.rounded_rectangle([ix, iy, ix + iw, iy + ih], radius=ih // 2, fill=(18, 18, 28))

# ── 6 ASO-optimized screen content functions ───────────────

def screen_home(draw, sx, sy, sw, sh):
    """SS1 – Home list (Attention: core value)."""
    _, f_title, f_body, f_small, f_tiny = get_fonts(sh)
    bar_h = int(sh * 0.07)
    draw.text((sx+int(sw*0.06), sy+bar_h), "Fodelsedagar", fill=DARK, font=f_title)
    entries = [
        ("Mamma",           "Idag!",   "Fyller 60 ar",  CORAL,  True),
        ("Emma Andersson",  "7 dagar",  "Fyller 30 ar",  VIOLET, False),
        ("Oscar Lindqvist", "14 dagar", "Fyller 25 ar",  SKY,    False),
        ("Sofia Bergstrom", "23 dagar", "Fyller 28 ar",  MINT2,  False),
        ("Alexander Ek",    "34 dagar", "Fyller 35 ar",  PEACH,  False),
    ]
    cm = int(sw * 0.05); cw = sw - cm * 2; ch = int(sh * 0.1)
    gap = int(sh * 0.015); cr = int(sw * 0.05)
    card_y = sy + bar_h + int(sh * 0.08)
    for i, (name, days, age, color, highlight) in enumerate(entries):
        cy = card_y + i * (ch + gap)
        if cy + ch > sy + sh - int(sh * 0.1): break
        bg = (*color, 22) if highlight else (255, 255, 255, 220)
        draw.rounded_rectangle([sx+cm, cy, sx+cm+cw, cy+ch], radius=cr, fill=bg)
        if highlight:
            draw.rounded_rectangle([sx+cm, cy, sx+cm+cw, cy+ch], radius=cr, outline=(*color, 180), width=3)
        av_r = int(ch * 0.33); av_cx = sx+cm+int(cw*0.09); av_cy = cy+ch//2
        draw.ellipse([av_cx-av_r, av_cy-av_r, av_cx+av_r, av_cy+av_r], fill=color)
        draw.text((av_cx-int(av_r*0.45), av_cy-int(av_r*0.55)), name[0], fill=WHITE, font=f_small)
        tx = av_cx + av_r + int(cw*0.04)
        draw.text((tx, cy+int(ch*0.15)), name, fill=DARK, font=f_body)
        draw.text((tx, cy+int(ch*0.55)), age, fill=GREY, font=f_tiny)
        bw = int(cw*0.22); bh = int(ch*0.42)
        bx = sx+cm+cw-bw-int(cw*0.04); by_ = cy+(ch-bh)//2
        draw.rounded_rectangle([bx, by_, bx+bw, by_+bh], radius=bh//2, fill=color)
        bbox = draw.textbbox((0,0), days, font=f_tiny)
        tw = bbox[2]-bbox[0]
        draw.text((bx+(bw-tw)//2, by_+int(bh*0.2)), days, fill=WHITE, font=f_tiny)
    nav_y = sy+sh-int(sh*0.07)
    draw.rectangle([sx, nav_y, sx+sw, sy+sh], fill=(255,255,255,240))
    for i, ic in enumerate([VIOLET,(190,190,200),(190,190,200),(190,190,200)]):
        nx = sx+sw//8+i*(sw//4); ny = nav_y+int(sh*0.025); nr = int(sw*0.025)
        draw.ellipse([nx-nr, ny-nr, nx+nr, ny+nr], fill=ic)

def screen_countdown(draw, sx, sy, sw, sh):
    """SS2 – Big countdown card (Interest: key feature)."""
    _, f_title, f_body, f_small, f_tiny = get_fonts(sh)
    try:
        f_huge = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", int(sh*0.13))
        f_hero = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", int(sh*0.045))
    except:
        f_huge = f_hero = ImageFont.load_default()
    bar_h = int(sh*0.07)
    draw.text((sx+int(sw*0.05), sy+bar_h), "< Tillbaka", fill=VIOLET, font=f_tiny)
    av_r = int(sw*0.14); av_cx = sx+sw//2; av_cy = sy+bar_h+int(sh*0.12)
    draw.ellipse([av_cx-av_r, av_cy-av_r, av_cx+av_r, av_cy+av_r], fill=CORAL)
    draw.text((av_cx-int(av_r*0.45), av_cy-int(av_r*0.55)), "M", fill=WHITE, font=f_hero)
    centered_text(draw, "Mamma", av_cy+av_r+int(sh*0.02), sw+sx*2, f_hero, DARK)
    centered_text(draw, "Fyller 60 ar - 21 februari", av_cy+av_r+int(sh*0.065), sw+sx*2, f_small, GREY)
    card_y = av_cy+av_r+int(sh*0.12)
    cm = int(sw*0.06); cw = sw-cm*2; ch = int(sh*0.22); cr = int(sw*0.06)
    for row in range(ch):
        t = row/ch
        c = lerp_color(CORAL, PEACH, t)
        draw.rectangle([sx+cm, card_y+row, sx+cm+cw, card_y+row+1], fill=c)
    centered_text(draw, "3", card_y+int(ch*0.05), sw+sx*2, f_huge, WHITE)
    centered_text(draw, "DAGAR KVAR", card_y+int(ch*0.62), sw+sx*2, f_small, (255,255,255,200))
    centered_text(draw, "21 februari", card_y+int(ch*0.80), sw+sx*2, f_tiny, (255,255,255,180))
    btn_y = card_y+ch+int(sh*0.04); bh = int(sh*0.065); bm = int(sw*0.06); bw = sw-bm*2
    draw.rounded_rectangle([sx+bm, btn_y, sx+bm+bw, btn_y+bh], radius=bh//2, fill=VIOLET)
    centered_text(draw, "Skicka halsning", btn_y+int(bh*0.25), sw+sx*2, f_small, WHITE)
    btn2_y = btn_y+bh+int(sh*0.02)
    draw.rounded_rectangle([sx+bm, btn2_y, sx+bm+bw, btn2_y+bh], radius=bh//2, fill=(240,238,255))
    centered_text(draw, "Swisha present", btn2_y+int(bh*0.25), sw+sx*2, f_small, VIOLET)

def screen_reminders(draw, sx, sy, sw, sh):
    """SS3 – Reminder toggles (Desire: never miss)."""
    _, f_title, f_body, f_small, f_tiny = get_fonts(sh)
    bar_h = int(sh*0.07)
    draw.text((sx+int(sw*0.06), sy+bar_h), "Paminnelser", fill=DARK, font=f_title)
    draw.text((sx+int(sw*0.06), sy+bar_h+int(sh*0.055)), "Valj nar du vill bli pamind", fill=GREY, font=f_tiny)
    reminders = [
        ("Samma dag",     True,  CORAL),
        ("1 dag innan",   True,  VIOLET),
        ("1 vecka innan", True,  MINT2),
        ("2 veckor",      False, GREY),
        ("1 manad",       False, GREY),
    ]
    cm=int(sw*0.05); cw=sw-cm*2; ch=int(sh*0.085); gap=int(sh*0.012); cr=int(sw*0.04)
    card_y = sy+bar_h+int(sh*0.12)
    for i, (label, active, color) in enumerate(reminders):
        cy = card_y+i*(ch+gap)
        draw.rounded_rectangle([sx+cm, cy, sx+cm+cw, cy+ch], radius=cr, fill=(255,255,255,230))
        ic_r=int(ch*0.28); ic_cx=sx+cm+int(cw*0.1); ic_cy=cy+ch//2
        draw.ellipse([ic_cx-ic_r, ic_cy-ic_r, ic_cx+ic_r, ic_cy+ic_r], fill=(*color,40) if active else (230,230,235))
        draw.text((sx+cm+int(cw*0.22), cy+int(ch*0.3)), label, fill=DARK if active else GREY, font=f_body)
        tog_w=int(cw*0.14); tog_h=int(ch*0.38)
        tog_x=sx+cm+cw-tog_w-int(cw*0.05); tog_y=cy+(ch-tog_h)//2
        draw.rounded_rectangle([tog_x, tog_y, tog_x+tog_w, tog_y+tog_h], radius=tog_h//2, fill=color if active else (200,200,210))
        knob_r=int(tog_h*0.42)
        knob_x=(tog_x+tog_w-knob_r-2) if active else (tog_x+knob_r+2)
        draw.ellipse([knob_x-knob_r, tog_y+2, knob_x+knob_r, tog_y+tog_h-2], fill=WHITE)
    info_y = card_y+len(reminders)*(ch+gap)+int(sh*0.03); info_h=int(sh*0.1)
    draw.rounded_rectangle([sx+cm, info_y, sx+cm+cw, info_y+info_h], radius=cr, fill=(*VIOLET,15))
    draw.text((sx+cm+int(cw*0.06), info_y+int(info_h*0.15)), "Aldrig missa en fodelsedag!", fill=VIOLET, font=f_small)
    draw.text((sx+cm+int(cw*0.06), info_y+int(info_h*0.55)), "Automatiska notiser direkt till din telefon", fill=GREY, font=f_tiny)

def screen_import(draw, sx, sy, sw, sh):
    """SS4 – Import contacts (Action: easy onboarding)."""
    _, f_title, f_body, f_small, f_tiny = get_fonts(sh)
    bar_h = int(sh*0.07)
    draw.text((sx+int(sw*0.06), sy+bar_h), "Importera kontakter", fill=DARK, font=f_title)
    draw.text((sx+int(sw*0.06), sy+bar_h+int(sh*0.055)), "Lagg till fran din telefonbok", fill=GREY, font=f_tiny)
    contacts = [
        ("Anna Svensson",   "12 mar 1990", CORAL,  True),
        ("Bjorn Karlsson",  "5 jun 1985",  VIOLET, True),
        ("Cecilia Holm",    "28 aug 1995", MINT2,  False),
        ("David Lindberg",  "17 nov 1988", SKY,    True),
        ("Elsa Magnusson",  "3 jan 1992",  PEACH,  False),
        ("Filip Johansson", "22 okt 1997", GOLD,   True),
    ]
    cm=int(sw*0.05); cw=sw-cm*2; ch=int(sh*0.085); gap=int(sh*0.01); cr=int(sw*0.04)
    card_y = sy+bar_h+int(sh*0.12)
    for i, (name, bday, color, selected) in enumerate(contacts):
        cy = card_y+i*(ch+gap)
        if cy+ch > sy+sh-int(sh*0.18): break
        draw.rounded_rectangle([sx+cm, cy, sx+cm+cw, cy+ch], radius=cr, fill=(255,255,255,230))
        if selected:
            draw.rounded_rectangle([sx+cm, cy, sx+cm+cw, cy+ch], radius=cr, outline=(*color,120), width=2)
        av_r=int(ch*0.32); av_cx=sx+cm+int(cw*0.09); av_cy=cy+ch//2
        draw.ellipse([av_cx-av_r, av_cy-av_r, av_cx+av_r, av_cy+av_r], fill=color)
        draw.text((av_cx-int(av_r*0.4), av_cy-int(av_r*0.55)), name[0], fill=WHITE, font=f_small)
        tx = av_cx+av_r+int(cw*0.04)
        draw.text((tx, cy+int(ch*0.15)), name, fill=DARK, font=f_body)
        draw.text((tx, cy+int(ch*0.55)), bday, fill=GREY, font=f_tiny)
        cb_r=int(ch*0.22); cb_cx=sx+cm+cw-int(cw*0.08); cb_cy=cy+ch//2
        if selected:
            draw.ellipse([cb_cx-cb_r, cb_cy-cb_r, cb_cx+cb_r, cb_cy+cb_r], fill=color)
            draw.text((cb_cx-int(cb_r*0.5), cb_cy-int(cb_r*0.6)), "✓", fill=WHITE, font=f_tiny)
        else:
            draw.ellipse([cb_cx-cb_r, cb_cy-cb_r, cb_cx+cb_r, cb_cy+cb_r], outline=(200,200,210), width=2)
    btn_y=sy+sh-int(sh*0.14); bh=int(sh*0.065); bm=int(sw*0.06); bw=sw-bm*2
    draw.rounded_rectangle([sx+bm, btn_y, sx+bm+bw, btn_y+bh], radius=bh//2, fill=VIOLET)
    centered_text(draw, "Importera 4 kontakter", btn_y+int(bh*0.25), sw+sx*2, f_small, WHITE)

def screen_gifts(draw, sx, sy, sw, sh):
    """SS5 – Gift suggestions grid."""
    _, f_title, f_body, f_small, f_tiny = get_fonts(sh)
    bar_h = int(sh*0.07)
    draw.text((sx+int(sw*0.06), sy+bar_h), "Presenttips", fill=DARK, font=f_title)
    draw.text((sx+int(sw*0.06), sy+bar_h+int(sh*0.055)), "Emma - Fyller 30 ar - 7 dagar kvar", fill=GREY, font=f_tiny)
    cm=int(sw*0.04); cw2=(sw-cm*3)//2; ch2=int(sh*0.2); cr=int(sw*0.05)
    gifts = [
        ("Smycken",      "fran 299 kr", CORAL,  "Amazon"),
        ("Bocker",       "fran 149 kr", VIOLET, "Adlibris"),
        ("Hudvard",      "fran 249 kr", MINT2,  "Lyko"),
        ("Upplevelse",   "fran 499 kr", GOLD,   "Coolstuff"),
    ]
    gy = sy+bar_h+int(sh*0.12)
    for i, (name, price, color, shop) in enumerate(gifts):
        row, col = divmod(i, 2)
        gx = sx+cm+col*(cw2+cm); cy = gy+row*(ch2+int(sh*0.02))
        draw.rounded_rectangle([gx, cy, gx+cw2, cy+ch2], radius=cr, fill=(255,255,255,230))
        block_h = int(ch2*0.5)
        for rp in range(block_h):
            c = lerp_color(color, lerp_color(color, WHITE, 0.5), rp/block_h)
            draw.rectangle([gx+2, cy+rp, gx+cw2-2, cy+rp+1], fill=c)
        draw.text((gx+int(cw2*0.08), cy+int(ch2*0.55)), name, fill=DARK, font=f_small)
        draw.text((gx+int(cw2*0.08), cy+int(ch2*0.73)), price, fill=color, font=f_tiny)
        draw.text((gx+int(cw2*0.08), cy+int(ch2*0.87)), shop, fill=GREY, font=f_tiny)
    btn_y=sy+sh-int(sh*0.14); bh=int(sh*0.065); bm=int(sw*0.06); bw=sw-bm*2
    draw.rounded_rectangle([sx+bm, btn_y, sx+bm+bw, btn_y+bh], radius=bh//2, fill=MINT2)
    centered_text(draw, "Swisha Emma", btn_y+int(bh*0.25), sw+sx*2, f_small, WHITE)

def screen_relation_tree(draw, sx, sy, sw, sh):
    """SS6 – Relation tree."""
    _, f_title, f_body, f_small, f_tiny = get_fonts(sh)
    bar_h = int(sh*0.07)
    draw.text((sx+int(sw*0.06), sy+bar_h), "Relationskarta", fill=DARK, font=f_title)
    draw.text((sx+int(sw*0.06), sy+bar_h+int(sh*0.055)), "Visualisera dina relationer", fill=GREY, font=f_tiny)
    node_r = int(sw*0.09)
    cx = sx+sw//2; owner_y = sy+bar_h+int(sh*0.15)

    def draw_node(x, y, initial, color, label, is_owner=False):
        r = int(node_r*1.2) if is_owner else node_r
        draw.ellipse([x-r, y-r, x+r, y+r], fill=color)
        if is_owner:
            draw.ellipse([x-r, y-r, x+r, y+r], outline=GOLD, width=3)
        draw.text((x-int(r*0.4), y-int(r*0.55)), initial, fill=WHITE, font=f_body)
        if label:
            lbbox = draw.textbbox((0,0), label, font=f_tiny)
            lw = lbbox[2]-lbbox[0]+16; lh = int(sh*0.025)
            lx = x-lw//2; ly = y+r+4
            draw.rounded_rectangle([lx, ly, lx+lw, ly+lh], radius=lh//2, fill=color)
            draw.text((lx+8, ly+2), label, fill=WHITE, font=f_tiny)

    draw_node(cx, owner_y, "A", VIOLET, "JAG", is_owner=True)
    p_gap = int(sw*0.32); parent_y = owner_y+int(sh*0.18)
    parents = [(cx-p_gap, "K", CORAL, "Mamma"), (cx+p_gap, "D", SKY, "Pappa")]
    for px, init, col, lbl in parents:
        draw.line([(cx, owner_y+int(node_r*1.2)), (px, parent_y-node_r)], fill=(*col,120), width=3)
        draw_node(px, parent_y, init, col, lbl)
    draw.line([(parents[0][0]+node_r, parent_y), (parents[1][0]-node_r, parent_y)], fill=(*CORAL,80), width=2)
    child_y = parent_y+int(sh*0.18)
    children = [
        (cx-int(sw*0.38), "L", MINT2,  "Syster"),
        (cx-int(sw*0.10), "E", PEACH,  "Bror"),
        (cx+int(sw*0.16), "S", GOLD,   "Vän"),
        (cx+int(sw*0.38), "M", VIOLET, "Vän"),
    ]
    for chx, init, col, lbl in children:
        par_x = parents[0][0] if chx < cx else parents[1][0]
        draw.line([(par_x, parent_y+node_r), (chx, child_y-node_r)], fill=(*col,100), width=2)
        draw_node(chx, child_y, init, col, lbl)

# ── OLD screen functions kept for reference (unused) ───────

def draw_home_screen(draw, sx, sy, sw, sh):
    """Simulate the home screen with birthday list."""
    # Status bar area
    bar_h = int(sh * 0.06)
    
    # Header
    header_y = sy + bar_h + int(sh * 0.02)
    try:
        font_large = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", int(sh * 0.035))
        font_med = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", int(sh * 0.02))
        font_small = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", int(sh * 0.016))
    except:
        font_large = ImageFont.load_default()
        font_med = font_large
        font_small = font_large
    
    draw.text((sx + int(sw * 0.06), header_y), "Födelsedagar", fill=DARK, font=font_large)
    
    # Birthday cards
    card_y = header_y + int(sh * 0.07)
    card_margin = int(sw * 0.05)
    card_w = sw - card_margin * 2
    card_h = int(sh * 0.09)
    card_gap = int(sh * 0.015)
    card_r = int(sw * 0.04)
    
    birthdays = [
        ("Emma Andersson", "15 feb", "Fyller 30 år", CORAL),
        ("Oscar Lindqvist", "22 feb", "Fyller 25 år", VIOLET),
        ("Sofia Bergström", "3 mar", "Fyller 28 år", MINT),
        ("Alexander Ek", "14 mar", "Fyller 35 år", SKY),
        ("Maja Johansson", "1 apr", "Fyller 22 år", PEACH),
        ("Erik Nilsson", "18 apr", "Fyller 40 år", VIOLET),
    ]
    
    for i, (name, date, age, color) in enumerate(birthdays):
        cy = card_y + i * (card_h + card_gap)
        if cy + card_h > sy + sh - int(sh * 0.08):
            break
        
        # Glass card
        draw.rounded_rectangle(
            [sx + card_margin, cy, sx + card_margin + card_w, cy + card_h],
            radius=card_r,
            fill=(255, 255, 255, 200)
        )
        
        # Avatar circle
        av_r = int(card_h * 0.35)
        av_cx = sx + card_margin + int(card_w * 0.08)
        av_cy = cy + card_h // 2
        draw.ellipse(
            [av_cx - av_r, av_cy - av_r, av_cx + av_r, av_cy + av_r],
            fill=color
        )
        # Initial
        initial = name[0]
        draw.text((av_cx - int(av_r * 0.4), av_cy - int(av_r * 0.5)), initial, fill=WHITE, font=font_small)
        
        # Text
        text_x = av_cx + av_r + int(card_w * 0.04)
        draw.text((text_x, cy + int(card_h * 0.18)), name, fill=DARK, font=font_med)
        draw.text((text_x, cy + int(card_h * 0.52)), f"{date} · {age}", fill=(107, 114, 128), font=font_small)
        
        # Days badge
        days = [7, 14, 23, 34, 52, 71]
        badge_text = f"{days[i]}d"
        badge_x = sx + card_margin + card_w - int(card_w * 0.15)
        badge_y = cy + int(card_h * 0.25)
        badge_w = int(card_w * 0.12)
        badge_h = int(card_h * 0.5)
        draw.rounded_rectangle(
            [badge_x, badge_y, badge_x + badge_w, badge_y + badge_h],
            radius=badge_h // 2,
            fill=(*color, 40)
        )
        draw.text((badge_x + int(badge_w * 0.2), badge_y + int(badge_h * 0.15)), badge_text, fill=color, font=font_small)
    
    # Bottom nav bar
    nav_y = sy + sh - int(sh * 0.07)
    draw.rectangle([sx, nav_y, sx + sw, sy + sh], fill=(255, 255, 255, 230))
    
    # Nav icons (circles as placeholders)
    nav_items = 4
    nav_spacing = sw // (nav_items + 1)
    for i in range(nav_items):
        nx = sx + nav_spacing * (i + 1)
        ny = nav_y + int(sh * 0.025)
        nr = int(sw * 0.025)
        c = VIOLET if i == 0 else (180, 180, 190)
        draw.ellipse([nx - nr, ny - nr, nx + nr, ny + nr], fill=c)

def draw_calendar_screen(draw, sx, sy, sw, sh):
    """Simulate calendar view."""
    bar_h = int(sh * 0.06)
    
    try:
        font_large = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", int(sh * 0.035))
        font_med = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", int(sh * 0.02))
        font_small = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", int(sh * 0.014))
    except:
        font_large = ImageFont.load_default()
        font_med = font_large
        font_small = font_large
    
    header_y = sy + bar_h + int(sh * 0.02)
    draw.text((sx + int(sw * 0.06), header_y), "Februari 2026", fill=DARK, font=font_large)
    
    # Calendar grid
    grid_y = header_y + int(sh * 0.07)
    cell_w = sw // 7
    cell_h = int(sh * 0.065)
    grid_x = sx
    
    # Day headers
    days = ["Mån", "Tis", "Ons", "Tor", "Fre", "Lör", "Sön"]
    for i, d in enumerate(days):
        dx = grid_x + i * cell_w + cell_w // 4
        draw.text((dx, grid_y), d, fill=(150, 150, 160), font=font_small)
    
    grid_y += int(sh * 0.03)
    
    # Calendar days
    start_day = 6  # Feb 2026 starts on Sunday (index 6)
    birthday_days = {15: CORAL, 22: SKY}
    today = 8
    
    for day in range(1, 29):
        pos = start_day + day - 1
        row = pos // 7
        col = pos % 7
        
        cx = grid_x + col * cell_w + cell_w // 2
        cy = grid_y + row * cell_h + cell_h // 2
        r = int(cell_w * 0.35)
        
        if day == today:
            draw.ellipse([cx - r, cy - r, cx + r, cy + r], fill=VIOLET)
            draw.text((cx - int(r * 0.4), cy - int(r * 0.5)), str(day), fill=WHITE, font=font_small)
        elif day in birthday_days:
            draw.ellipse([cx - r, cy - r, cx + r, cy + r], fill=birthday_days[day])
            draw.text((cx - int(r * 0.4), cy - int(r * 0.5)), str(day), fill=WHITE, font=font_small)
        else:
            draw.text((cx - int(r * 0.4), cy - int(r * 0.5)), str(day), fill=DARK, font=font_small)

def draw_gift_screen(draw, sx, sy, sw, sh):
    """Simulate gift suggestions screen."""
    bar_h = int(sh * 0.06)
    
    try:
        font_large = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", int(sh * 0.03))
        font_med = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", int(sh * 0.02))
        font_small = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", int(sh * 0.015))
    except:
        font_large = ImageFont.load_default()
        font_med = font_large
        font_small = font_large
    
    header_y = sy + bar_h + int(sh * 0.02)
    draw.text((sx + int(sw * 0.06), header_y), "Presenttips för Emma", fill=DARK, font=font_large)
    draw.text((sx + int(sw * 0.06), header_y + int(sh * 0.04)), "Fyller 30 år · 15 februari", fill=(107, 114, 128), font=font_small)
    
    # Gift cards
    card_y = header_y + int(sh * 0.08)
    card_margin = int(sw * 0.05)
    card_w = (sw - card_margin * 3) // 2
    card_h = int(sh * 0.18)
    card_r = int(sw * 0.04)
    
    gifts = [
        ("Smycken", "299 kr", CORAL),
        ("Böcker", "199 kr", VIOLET),
        ("Hudvård", "349 kr", MINT),
        ("Upplevelse", "499 kr", SKY),
    ]
    
    for i, (name, price, color) in enumerate(gifts):
        row = i // 2
        col = i % 2
        cx = sx + card_margin + col * (card_w + card_margin)
        cy = card_y + row * (card_h + int(sh * 0.02))
        
        # Card background
        draw.rounded_rectangle(
            [cx, cy, cx + card_w, cy + card_h],
            radius=card_r,
            fill=(255, 255, 255, 220)
        )
        
        # Gift icon area
        icon_h = int(card_h * 0.55)
        draw.rounded_rectangle(
            [cx + int(card_w * 0.1), cy + int(card_h * 0.08),
             cx + card_w - int(card_w * 0.1), cy + icon_h],
            radius=int(card_r * 0.7),
            fill=(*color, 50)
        )
        
        # Gift emoji placeholder
        emoji_r = int(card_w * 0.1)
        emoji_cx = cx + card_w // 2
        emoji_cy = cy + icon_h // 2 + int(card_h * 0.04)
        draw.ellipse(
            [emoji_cx - emoji_r, emoji_cy - emoji_r, emoji_cx + emoji_r, emoji_cy + emoji_r],
            fill=color
        )
        
        # Text
        draw.text((cx + int(card_w * 0.1), cy + int(card_h * 0.62)), name, fill=DARK, font=font_med)
        draw.text((cx + int(card_w * 0.1), cy + int(card_h * 0.8)), price, fill=color, font=font_small)
    
    # Swish button
    swish_y = card_y + 2 * (card_h + int(sh * 0.02)) + int(sh * 0.02)
    swish_h = int(sh * 0.06)
    draw.rounded_rectangle(
        [sx + card_margin, swish_y, sx + sw - card_margin, swish_y + swish_h],
        radius=swish_h // 2,
        fill=MINT
    )
    draw.text(
        (sx + sw // 2 - int(sw * 0.12), swish_y + int(swish_h * 0.25)),
        "Swisha Emma",
        fill=WHITE,
        font=font_med
    )

def draw_premium_screen(draw, sx, sy, sw, sh):
    """Simulate premium/settings screen."""
    bar_h = int(sh * 0.06)
    
    try:
        font_large = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", int(sh * 0.03))
        font_med = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", int(sh * 0.02))
        font_small = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", int(sh * 0.015))
    except:
        font_large = ImageFont.load_default()
        font_med = font_large
        font_small = font_large
    
    header_y = sy + bar_h + int(sh * 0.02)
    
    # Premium banner with gradient
    banner_h = int(sh * 0.25)
    banner_y = header_y
    for by in range(banner_h):
        t = by / banner_h
        color = lerp_color(VIOLET, CORAL, t)
        draw.line([(sx, banner_y + by), (sx + sw, banner_y + by)], fill=color)
    
    # Crown
    crown_y = banner_y + int(banner_h * 0.15)
    crown_cx = sx + sw // 2
    cr = int(sw * 0.06)
    draw.ellipse([crown_cx - cr, crown_y - cr, crown_cx + cr, crown_y + cr], fill=(255, 215, 0))
    
    draw.text((sx + int(sw * 0.2), banner_y + int(banner_h * 0.45)), "Birthday Premium", fill=WHITE, font=font_large)
    draw.text((sx + int(sw * 0.15), banner_y + int(banner_h * 0.65)), "Obegränsat · Reklamfritt · Export", fill=(255, 255, 255, 200), font=font_small)
    
    # Price cards
    prices_y = banner_y + banner_h + int(sh * 0.03)
    price_h = int(sh * 0.08)
    price_margin = int(sw * 0.05)
    price_r = int(sw * 0.03)
    
    plans = [
        ("Månadsvis", "29 kr/mån", False),
        ("Årsvis", "199 kr/år", True),
        ("Livstid", "499 kr", False),
    ]
    
    for i, (plan, price, popular) in enumerate(plans):
        py = prices_y + i * (price_h + int(sh * 0.015))
        
        if popular:
            draw.rounded_rectangle(
                [sx + price_margin, py, sx + sw - price_margin, py + price_h],
                radius=price_r,
                fill=VIOLET
            )
            draw.text((sx + int(sw * 0.1), py + int(price_h * 0.15)), plan, fill=WHITE, font=font_med)
            draw.text((sx + sw - int(sw * 0.3), py + int(price_h * 0.15)), price, fill=WHITE, font=font_med)
            draw.text((sx + sw - int(sw * 0.25), py + int(price_h * 0.55)), "Populärast", fill=(200, 200, 255), font=font_small)
        else:
            draw.rounded_rectangle(
                [sx + price_margin, py, sx + sw - price_margin, py + price_h],
                radius=price_r,
                fill=(255, 255, 255, 220)
            )
            draw.text((sx + int(sw * 0.1), py + int(price_h * 0.3)), plan, fill=DARK, font=font_med)
            draw.text((sx + sw - int(sw * 0.3), py + int(price_h * 0.3)), price, fill=VIOLET, font=font_med)

def create_screenshot(width, height, headline, subline, screen_func, bg_c1, bg_c2, bg_c3, output_path):
    """Create one ASO-optimized promotional screenshot."""
    img = Image.new('RGB', (width, height))
    draw = ImageDraw.Draw(img, 'RGBA')

    # Background gradient
    draw_gradient_bg(draw, width, height, bg_c1, bg_c2, bg_c3)

    # Festive confetti
    draw_confetti(draw, width, height, seed=hash(output_path) % 9999)

    # ── Marketing text block (top ~14% of image) ──
    try:
        f_hero = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", int(height * 0.038))
        f_sub  = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", int(height * 0.020))
    except:
        f_hero = f_sub = ImageFont.load_default()

    # Clamp headline to fit within image width with padding
    margin = int(width * 0.05)
    max_text_w = width - margin * 2

    hbbox = draw.textbbox((0, 0), headline, font=f_hero)
    hw = hbbox[2] - hbbox[0]
    # Scale down font if headline too wide
    f_hero_use = f_hero
    if hw > max_text_w:
        try:
            scaled = int(height * 0.038 * max_text_w / hw)
            f_hero_use = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", max(scaled, int(height*0.022)))
        except:
            pass
        hbbox = draw.textbbox((0, 0), headline, font=f_hero_use)
        hw = hbbox[2] - hbbox[0]

    hy_center = int(height * 0.075)
    pad = int(width * 0.04)
    pill_x1 = max(0, (width - hw) // 2 - pad)
    pill_x2 = min(width, (width + hw) // 2 + pad)
    pill_y1 = hy_center - int(height * 0.025)
    pill_y2 = hy_center + int(height * 0.038)
    draw.rounded_rectangle([pill_x1, pill_y1, pill_x2, pill_y2],
                            radius=(pill_y2 - pill_y1) // 2,
                            fill=(0, 0, 0, 60))
    draw.text(((width - hw) // 2, hy_center), headline, fill=WHITE, font=f_hero_use)

    # Subline
    sbbox = draw.textbbox((0, 0), subline, font=f_sub)
    sw2 = sbbox[2] - sbbox[0]
    draw.text(((width - sw2) // 2, hy_center + int(height * 0.052)),
              subline, fill=(255, 255, 255, 210), font=f_sub)

    # ── Phone mockup (centered, fills ~78% of width) ──
    phone_w = int(width * 0.76)
    phone_h = int(phone_w * 2.16)
    phone_x = (width - phone_w) // 2
    phone_y = int(height * 0.155)
    max_ph = int(height * 0.82)
    if phone_h > max_ph:
        phone_h = max_ph

    draw_phone_frame(img, phone_x, phone_y, phone_w, phone_h, screen_func)

    img.save(output_path, 'PNG')
    print(f"  ✓ {width}×{height}  {os.path.basename(output_path)}")


def main():
    base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    ss_dir = os.path.join(base_dir, 'assets', 'screenshots')
    os.makedirs(ss_dir, exist_ok=True)

    # ── 6 screenshots in AIDA order ────────────────────────
    # (headline, subline, screen_func, bg_c1, bg_c2, bg_c3, filename)
    screens = [
        (
            "Aldrig missa en födelsedag!",
            "Automatiska påminnelser · Alltid i tid",
            screen_home,
            VIOLET, SKY, MINT,
            "01_home",
        ),
        (
            "3 dagar kvar till Mammas dag",
            "Nedräkning i realtid för varje person",
            screen_countdown,
            CORAL, PEACH, (255, 220, 180),
            "02_countdown",
        ),
        (
            "Påminnelser som passar dig",
            "Välj 1 dag, 1 vecka eller 1 månad innan",
            screen_reminders,
            VIOLET2, VIOLET, SKY,
            "03_reminders",
        ),
        (
            "Importera kontakter på sekunder",
            "Hämta namn & datum direkt från telefonboken",
            screen_import,
            MINT2, SKY, VIOLET,
            "04_import",
        ),
        (
            "Smarta presenttips & Swish",
            "Åldersbaserade förslag – Swisha direkt i appen",
            screen_gifts,
            CORAL, PEACH, GOLD,
            "05_gifts",
        ),
        (
            "Visualisera dina relationer",
            "Bygg ett familjeträd med ett tryck",
            screen_relation_tree,
            VIOLET, MINT2, SKY,
            "06_relations",
        ),
    ]

    # ── App Store required sizes ────────────────────────────
    sizes = {
        'iphone_67': (1290, 2796),   # iPhone 6.7" – REQUIRED
        'iphone_65': (1284, 2778),   # iPhone 6.5"
        'ipad_13':   (2064, 2752),   # iPad 13"    – REQUIRED
    }

    print("📸 Generating ASO-optimized App Store Screenshots\n")

    for size_name, (w, h) in sizes.items():
        print(f"\n📱 {size_name} ({w}×{h}):")
        size_dir = os.path.join(ss_dir, size_name)
        os.makedirs(size_dir, exist_ok=True)

        for headline, subline, func, c1, c2, c3, name in screens:
            out = os.path.join(size_dir, f"{name}.png")
            create_screenshot(w, h, headline, subline, func, c1, c2, c3, out)

    print(f"\n✅ Done! {len(screens) * len(sizes)} screenshots in: {ss_dir}")
    print("   Upload to App Store Connect → App Preview and Screenshots")

if __name__ == '__main__':
    main()
