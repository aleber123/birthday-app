#!/usr/bin/env python3
"""
Generate App Store screenshots for Birthday Reminder.
Creates promotional screenshots with device frames and marketing text.

App Store required sizes:
- iPhone 6.7" (1290 x 2796) - iPhone 15 Pro Max
- iPhone 6.5" (1284 x 2778) - iPhone 14 Plus  
- iPhone 5.5" (1242 x 2208) - iPhone 8 Plus
- iPad 12.9" (2048 x 2732) - iPad Pro
"""

from PIL import Image, ImageDraw, ImageFont
import os
import math

# App's color palette
VIOLET = (124, 92, 252)
SKY = (103, 195, 243)
MINT = (110, 231, 183)
CORAL = (255, 107, 138)
PEACH = (255, 176, 136)
WHITE = (255, 255, 255)
DARK = (26, 26, 46)

def lerp_color(c1, c2, t):
    t = max(0, min(1, t))
    return tuple(int(c1[i] + (c2[i] - c1[i]) * t) for i in range(3))

def draw_gradient_bg(draw, w, h, c1, c2, c3=None):
    """Draw a vertical gradient background."""
    for y in range(h):
        t = y / h
        if c3:
            if t < 0.5:
                color = lerp_color(c1, c2, t * 2)
            else:
                color = lerp_color(c2, c3, (t - 0.5) * 2)
        else:
            color = lerp_color(c1, c2, t)
        draw.line([(0, y), (w, y)], fill=color)

def draw_phone_frame(img, x, y, phone_w, phone_h, screen_content_func):
    """Draw a simplified iPhone frame with screen content."""
    draw = ImageDraw.Draw(img)
    
    # Phone bezel
    bezel = int(phone_w * 0.04)
    corner_r = int(phone_w * 0.12)
    
    # Phone body (dark)
    draw.rounded_rectangle(
        [x, y, x + phone_w, y + phone_h],
        radius=corner_r,
        fill=(20, 20, 30)
    )
    
    # Screen area
    sx = x + bezel
    sy = y + bezel
    sw = phone_w - bezel * 2
    sh = phone_h - bezel * 2
    screen_r = int(corner_r * 0.85)
    
    # Screen background
    draw.rounded_rectangle(
        [sx, sy, sx + sw, sy + sh],
        radius=screen_r,
        fill=(245, 243, 255)
    )
    
    # Draw screen content
    screen_content_func(draw, sx, sy, sw, sh)
    
    # Dynamic island
    island_w = int(phone_w * 0.28)
    island_h = int(phone_h * 0.018)
    island_x = x + (phone_w - island_w) // 2
    island_y = y + bezel + int(phone_h * 0.012)
    draw.rounded_rectangle(
        [island_x, island_y, island_x + island_w, island_y + island_h],
        radius=island_h // 2,
        fill=(20, 20, 30)
    )

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

def create_screenshot(width, height, title, subtitle, screen_func, bg_colors, output_path):
    """Create a full promotional screenshot."""
    img = Image.new('RGB', (width, height), (0, 0, 0))
    draw = ImageDraw.Draw(img, 'RGBA')
    
    # Background gradient
    draw_gradient_bg(draw, width, height, *bg_colors)
    
    # Marketing text at top
    try:
        font_title = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", int(height * 0.032))
        font_sub = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", int(height * 0.018))
    except:
        font_title = ImageFont.load_default()
        font_sub = font_title
    
    text_y = int(height * 0.06)
    
    # Title
    bbox = draw.textbbox((0, 0), title, font=font_title)
    tw = bbox[2] - bbox[0]
    draw.text(((width - tw) // 2, text_y), title, fill=WHITE, font=font_title)
    
    # Subtitle
    bbox2 = draw.textbbox((0, 0), subtitle, font=font_sub)
    sw2 = bbox2[2] - bbox2[0]
    draw.text(((width - sw2) // 2, text_y + int(height * 0.045)), subtitle, fill=(255, 255, 255, 200), font=font_sub)
    
    # Phone mockup
    phone_w = int(width * 0.72)
    phone_h = int(phone_w * 2.16)  # iPhone aspect ratio
    phone_x = (width - phone_w) // 2
    phone_y = int(height * 0.16)
    
    # Ensure phone doesn't go too far below
    max_phone_h = height - phone_y + int(height * 0.05)
    if phone_h > max_phone_h:
        phone_h = max_phone_h
    
    draw_phone_frame(img, phone_x, phone_y, phone_w, phone_h, screen_func)
    
    img.save(output_path, 'PNG', quality=95)
    print(f"  ✓ {width}x{height} → {os.path.basename(output_path)}")

def main():
    base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    ss_dir = os.path.join(base_dir, 'assets', 'screenshots')
    os.makedirs(ss_dir, exist_ok=True)
    
    # Screenshot definitions
    screens = [
        {
            'title': 'Alla födelsedagar\npå ett ställe',
            'subtitle': 'Smarta påminnelser så du aldrig glömmer',
            'func': draw_home_screen,
            'bg': (VIOLET, SKY, MINT),
            'name': '01_home',
        },
        {
            'title': 'Kalendervy',
            'subtitle': 'Se alla födelsedagar i månadsöversikt',
            'func': draw_calendar_screen,
            'bg': (SKY, MINT),
            'name': '02_calendar',
        },
        {
            'title': 'Smarta presenttips',
            'subtitle': 'Åldersbaserade förslag via Amazon & Coolstuff',
            'func': draw_gift_screen,
            'bg': (CORAL, PEACH),
            'name': '03_gifts',
        },
        {
            'title': 'Birthday Premium',
            'subtitle': 'Obegränsat, reklamfritt och mer',
            'func': draw_premium_screen,
            'bg': (VIOLET, CORAL),
            'name': '04_premium',
        },
    ]
    
    # App Store sizes
    sizes = {
        'iphone_67': (1290, 2796),   # iPhone 6.7" (required)
        'iphone_65': (1284, 2778),   # iPhone 6.5"
        'iphone_55': (1242, 2208),   # iPhone 5.5"
        'ipad_13': (2064, 2752),     # iPad 13" (required)
    }
    
    print("📸 Generating App Store Screenshots\n")
    
    for size_name, (w, h) in sizes.items():
        print(f"\n📱 {size_name} ({w}x{h}):")
        size_dir = os.path.join(ss_dir, size_name)
        os.makedirs(size_dir, exist_ok=True)
        
        for screen in screens:
            bg = screen['bg']
            if len(bg) == 2:
                bg = (bg[0], bg[1])
            
            output = os.path.join(size_dir, f"{screen['name']}.png")
            create_screenshot(
                w, h,
                screen['title'],
                screen['subtitle'],
                screen['func'],
                bg,
                output
            )
    
    print(f"\n✅ All screenshots generated in: {ss_dir}")
    print("   Upload these to App Store Connect under 'App Preview and Screenshots'")

if __name__ == '__main__':
    main()
