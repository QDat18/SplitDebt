"""Rebuild native brand assets from SVG; requires Inkscape on PATH (development only)."""
from pathlib import Path
import subprocess
ROOT = Path(__file__).resolve().parents[1]
PURPLE = 'M58 18 L83 43 Q92 52 83 61 L61 83 Q52 92 43 83 L18 58 Q9 49 18 40 L40 18 Q49 9 58 18 Z'
GOLD = 'M85 45 L110 70 Q119 79 110 88 L88 110 Q79 119 70 110 L45 85 Q36 76 45 67 L67 45 Q76 36 85 45 Z'
OVER = 'M18 58 L43 83 Q52 92 61 83 L75 69'
def svg(icon=False):
    bg='<rect width="160" height="160" rx="36" fill="#7055E8"/>' if icon else ''
    defs='''<defs><linearGradient id="violet" x1="0" y1="0" x2="1" y2="1"><stop stop-color="#C4A5FF"/><stop offset=".48" stop-color="#8055F6"/><stop offset="1" stop-color="#4822BC"/></linearGradient><linearGradient id="gold" x1="0" y1="0" x2="1" y2="1"><stop stop-color="#FFF1BC"/><stop offset=".45" stop-color="#D4B06A"/><stop offset="1" stop-color="#A8782A"/></linearGradient></defs>'''
    offset='translate(29 29) scale(.8)' if icon else 'translate(16 12)'
    purple='#FFFFFF' if icon else 'url(#violet)'
    gold='#FFFFFF' if icon else 'url(#gold)'
    paths=f'<path d="{PURPLE}" stroke="{purple}"/><path d="{GOLD}" stroke="{gold}"/>'
    if icon:paths+=f'<path d="{OVER}" stroke="#7055E8" stroke-width="24"/>'
    paths+=f'<path d="{OVER}" stroke="{purple}"/>'
    shadow='' if icon else f'<g transform="translate(0 4)" opacity=".22" stroke="#362069"><path d="{PURPLE}"/><path d="{GOLD}"/></g>'
    return f'<svg xmlns="http://www.w3.org/2000/svg" width="160" height="160" viewBox="0 0 160 160">{defs}{bg}<g transform="{offset}" fill="none" stroke-width="17" stroke-linecap="round" stroke-linejoin="round">{shadow}{paths}</g></svg>'
assets=ROOT/'frontend/assets/brand'
for name,icon in [('splitdebt-mark',False),('splitdebt-icon',True)]:
    content=svg(icon);(assets/f'{name}.svg').write_text(content)
    subprocess.run(["inkscape",str(assets/f"{name}.svg"),"--export-type=png","--export-filename="+str(assets/(name+".png")),"--export-width=512","--export-height=512"],check=True,capture_output=True)
for density,size in [('mdpi',48),('hdpi',72),('xhdpi',96),('xxhdpi',144),('xxxhdpi',192)]:
    path=ROOT/f'frontend/android/app/src/main/res/mipmap-{density}/ic_launcher.png'
    subprocess.run(["inkscape",str(assets/"splitdebt-icon.svg"),"--export-type=png",f"--export-filename={path}",f"--export-width={size}",f"--export-height={size}"],check=True,capture_output=True)
print('Generated SVG, Flutter PNG, and five Android launcher densities.')
