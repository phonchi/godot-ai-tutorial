from pathlib import Path
from playwright.sync_api import sync_playwright
import json,os
ROOT=Path(__file__).resolve().parents[1]
BASE='http://127.0.0.1:4322/godot-ai-tutorial/'
with sync_playwright() as p:
 # Prefer a GPU-backed browser when a display exists: SwiftShader shows stray colours in CPUParticles2D instance colours.
 gpu=bool(os.environ.get('DISPLAY'))
 args=['--use-angle=gl','--ignore-gpu-blocklist','--disable-dev-shm-usage'] if gpu else ['--use-angle=swiftshader','--enable-unsafe-swiftshader','--disable-dev-shm-usage']
 browser=p.chromium.launch(headless=not gpu,args=args,chromium_sandbox=False)
 page=browser.new_page(viewport={'width':960,'height':600},device_scale_factor=1)
 for dim in ['2d','3d']:
  errors=[];page.on('pageerror',lambda e:errors.append(str(e)))
  page.goto(BASE+f'play/{dim}/index.html',wait_until='networkidle',timeout=120000)
  page.wait_for_function("document.getElementById('canvas') && (!document.getElementById('status') || document.getElementById('status').style.display === 'none')",timeout=120000)
  page.locator('canvas').click();page.keyboard.press('Enter');page.wait_for_timeout(2600 if dim=='2d' else 1800)
  if dim=='2d':
   page.keyboard.down('d');page.keyboard.down('w');page.wait_for_timeout(700);page.keyboard.press('Shift');page.wait_for_timeout(120);page.keyboard.up('d');page.keyboard.up('w')
  else:
   page.keyboard.down('w');page.wait_for_timeout(600);page.keyboard.up('w');page.wait_for_timeout(900)
  out=ROOT/'public/previews'/f'{dim}.png';out.parent.mkdir(parents=True,exist_ok=True)
  page.screenshot(path=str(out));print(dim,errors,flush=True)
 browser.close()
