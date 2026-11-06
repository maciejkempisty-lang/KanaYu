"""Render the app's typographic ゆ mark. Requires Pillow; no artwork is altered."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont
import json
root=Path(__file__).resolve().parent.parent

def icon(size,path):
    im=Image.new('RGB',(size,size),'#47664f')
    draw=ImageDraw.Draw(im)
    font=ImageFont.truetype(str(root/'assets/fonts/ZenMaruGothic-Regular.ttf'),int(size*.7))
    box=draw.textbbox((0,0),'ゆ',font=font)
    draw.text(((size-(box[2]-box[0]))/2-box[0],(size-(box[3]-box[1]))/2-box[1]),'ゆ',font=font,fill='#faf7ef')
    im.save(path)
for folder in ['ios/Runner/Assets.xcassets/AppIcon.appiconset','macos/Runner/Assets.xcassets/AppIcon.appiconset']:
    d=root/folder
    for item in json.loads((d/'Contents.json').read_text())['images']:
        if 'filename' in item: icon(round(float(item['size'].split('x')[0])*float(item['scale'].rstrip('x'))),d/item['filename'])
for density,size in [('mdpi',48),('hdpi',72),('xhdpi',96),('xxhdpi',144),('xxxhdpi',192)]:
    icon(size,root/f'android/app/src/main/res/mipmap-{density}/ic_launcher.png')
for size in [192,512]:
    icon(size,root/f'web/icons/Icon-{size}.png')
    icon(size,root/f'web/icons/Icon-maskable-{size}.png')
icon(64,root/'web/favicon.png')
