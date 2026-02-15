#!/usr/bin/env python3
"""
Generate Birthday Reminder app icon in all required sizes.
Uses the app's aurora gradient (violet → sky → mint) with a birthday cake symbol.
"""

from PIL import Image, ImageDraw, ImageFont
import math
import os

def lerp_color(c1, c2, t):
    """Linearly interpolate between two RGB colors."""
    return tuple(int(c1[i] + (c2[i] - c1[i]) * t) for i in range(3))

def draw_aurora_gradient(draw, size):
    """Draw the app's aurora gradient: violet → sky → mint (diagonal)."""
    violet = (124, 92, 252)   # #7C5CFC
    sky = (103, 195, 243)     # #67C3F3
    mint = (110, 231, 183)    # #6EE7B7
    
    for y in range(size):
        for x in range(size):
            # Diagonal progress
            t = (x / size * 0.6 + y / size * 0.4)
            if t < 0.5:
                color = lerp_color(violet, sky, t * 2)
            else:
                color = lerp_color(sky, mint, (t - 0.5) * 2)
            draw.point((x, y), fill=color)

def draw_cake(draw, size):
    """Draw a minimalist birthday cake icon."""
    cx = size // 2
    cy = size // 2 + size // 20
    
    # Scale factors
    s = size / 1024.0
    
    # Cake body - rounded rectangle
    cake_w = int(340 * s)
    cake_h = int(200 * s)
    cake_top = cy - int(20 * s)
    cake_left = cx - cake_w // 2
    cake_right = cx + cake_w // 2
    cake_bottom = cake_top + cake_h
    
    # Cake base layer (white, semi-transparent effect via lighter color)
    cake_color = (255, 255, 255, 220)
    r = int(30 * s)
    draw.rounded_rectangle(
        [cake_left, cake_top, cake_right, cake_bottom],
        radius=r,
        fill=cake_color
    )
    
    # Cake frosting stripe (pink/coral accent)
    frost_h = int(35 * s)
    frost_color = (255, 107, 138, 200)  # #FF6B8A
    draw.rounded_rectangle(
        [cake_left, cake_top, cake_right, cake_top + frost_h],
        radius=r,
        fill=frost_color
    )
    # Fix bottom corners of frosting
    draw.rectangle(
        [cake_left, cake_top + r, cake_right, cake_top + frost_h],
        fill=frost_color
    )
    
    # Candles
    candle_w = int(18 * s)
    candle_h = int(100 * s)
    candle_colors = [
        (255, 176, 136, 230),  # peach #FFB088
        (255, 255, 255, 240),  # white
        (167, 139, 250, 230),  # light violet #A78BFA
    ]
    candle_positions = [cx - int(90 * s), cx, cx + int(90 * s)]
    
    for i, pos in enumerate(candle_positions):
        candle_top = cake_top - candle_h
        candle_left = pos - candle_w // 2
        candle_right = pos + candle_w // 2
        
        # Candle stick
        draw.rounded_rectangle(
            [candle_left, candle_top, candle_right, cake_top + int(5 * s)],
            radius=int(6 * s),
            fill=candle_colors[i % len(candle_colors)]
        )
        
        # Flame - teardrop shape
        flame_cx = pos
        flame_bottom = candle_top - int(4 * s)
        flame_h = int(40 * s)
        flame_w = int(22 * s)
        
        # Outer flame (warm yellow-orange)
        draw.ellipse(
            [flame_cx - flame_w, flame_bottom - flame_h,
             flame_cx + flame_w, flame_bottom + int(10 * s)],
            fill=(255, 200, 60, 220)
        )
        # Inner flame (bright white-yellow)
        inner_w = int(12 * s)
        inner_h = int(24 * s)
        draw.ellipse(
            [flame_cx - inner_w, flame_bottom - inner_h,
             flame_cx + inner_w, flame_bottom + int(4 * s)],
            fill=(255, 245, 200, 240)
        )
    
    # Cake plate / base line
    plate_y = cake_bottom + int(8 * s)
    plate_w = cake_w + int(60 * s)
    draw.rounded_rectangle(
        [cx - plate_w // 2, plate_y, cx + plate_w // 2, plate_y + int(16 * s)],
        radius=int(8 * s),
        fill=(255, 255, 255, 160)
    )

def generate_icon(size, output_path):
    """Generate a single icon at the given size."""
    # Create at 2x for quality, then downscale
    render_size = max(size * 2, 1024)
    
    img = Image.new('RGBA', (render_size, render_size), (255, 255, 255, 255))
    draw = ImageDraw.Draw(img)
    
    # Draw gradient background
    draw_aurora_gradient(draw, render_size)
    
    # Draw cake
    draw_cake(draw, render_size)
    
    # Downscale with high quality
    if render_size != size:
        img = img.resize((size, size), Image.LANCZOS)
    
    # Convert to RGB (no alpha channel) – required by Apple App Store
    img_rgb = Image.new('RGB', img.size, (255, 255, 255))
    img_rgb.paste(img, mask=img.split()[3] if img.mode == 'RGBA' else None)
    
    # Save
    img_rgb.save(output_path, 'PNG')
    print(f"  ✓ {size}x{size} → {output_path}")

def main():
    base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    
    # Output directories
    icon_dir = os.path.join(base_dir, 'assets', 'app_icon')
    os.makedirs(icon_dir, exist_ok=True)
    
    # iOS asset catalog directory
    ios_icon_dir = os.path.join(base_dir, 'ios', 'Runner', 'Assets.xcassets', 'AppIcon.appiconset')
    os.makedirs(ios_icon_dir, exist_ok=True)
    
    # Android icon directories
    android_dirs = {
        'mipmap-mdpi': 48,
        'mipmap-hdpi': 72,
        'mipmap-xhdpi': 96,
        'mipmap-xxhdpi': 144,
        'mipmap-xxxhdpi': 192,
    }
    
    print("🎂 Generating Birthday Reminder App Icons\n")
    
    # 1. Master icon (1024x1024) for App Store
    print("📱 App Store icon:")
    master_path = os.path.join(icon_dir, 'app_icon_1024.png')
    generate_icon(1024, master_path)
    
    # Also copy to iOS assets
    ios_1024 = os.path.join(ios_icon_dir, 'Icon-App-1024x1024@1x.png')
    generate_icon(1024, ios_1024)
    
    # 2. iOS icons
    print("\n🍎 iOS icons:")
    ios_sizes = {
        'Icon-App-20x20@1x.png': 20,
        'Icon-App-20x20@2x.png': 40,
        'Icon-App-20x20@3x.png': 60,
        'Icon-App-29x29@1x.png': 29,
        'Icon-App-29x29@2x.png': 58,
        'Icon-App-29x29@3x.png': 87,
        'Icon-App-40x40@1x.png': 40,
        'Icon-App-40x40@2x.png': 80,
        'Icon-App-40x40@3x.png': 120,
        'Icon-App-60x60@2x.png': 120,
        'Icon-App-60x60@3x.png': 180,
        'Icon-App-76x76@1x.png': 76,
        'Icon-App-76x76@2x.png': 152,
        'Icon-App-83.5x83.5@2x.png': 167,
    }
    
    for filename, size in ios_sizes.items():
        path = os.path.join(ios_icon_dir, filename)
        generate_icon(size, path)
    
    # 3. Android icons
    print("\n🤖 Android icons:")
    for dir_name, size in android_dirs.items():
        android_dir = os.path.join(base_dir, 'android', 'app', 'src', 'main', 'res', dir_name)
        os.makedirs(android_dir, exist_ok=True)
        path = os.path.join(android_dir, 'ic_launcher.png')
        generate_icon(size, path)
    
    # 4. Web favicon
    print("\n🌐 Web icons:")
    web_dir = os.path.join(base_dir, 'web')
    generate_icon(192, os.path.join(web_dir, 'icons', 'Icon-192.png'))
    generate_icon(512, os.path.join(web_dir, 'icons', 'Icon-512.png'))
    generate_icon(16, os.path.join(web_dir, 'favicon.png'))
    
    # 5. Google Play Store icon (512x512)
    print("\n🏪 Store icons:")
    generate_icon(512, os.path.join(icon_dir, 'play_store_512.png'))
    
    print("\n✅ All icons generated successfully!")
    print(f"   Master icon: {master_path}")
    print(f"   iOS icons: {ios_icon_dir}")
    print(f"   Upload {master_path} to App Store Connect")

if __name__ == '__main__':
    main()
