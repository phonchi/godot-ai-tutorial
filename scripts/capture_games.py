from pathlib import Path
from playwright.sync_api import sync_playwright
import json
ROOT=Path(__file__).resolve().parents[1]
BASE='http://127.0.0.1:4322/godot-ai-tutorial/'
with sync_playwright() as p:
 browser=p.chromium.launch(headless=True,args=['--use-angle=swiftshader','--enable-unsafe-swiftshader','--disable-dev-shm-usage'],chromium_sandbox=False)
 page=browser.new_page(viewport={'width':960,'height':600},device_scale_factor=1)
 for dim in ['2d','3d']:
  errors=[];page.on('pageerror',lambda e:errors.append(str(e)))
  page.goto(BASE+f'play/{dim}/index.html',wait_until='networkidle',timeout=120000)
  page.wait_for_function("document.getElementById('canvas') && (!document.getElementById('status') || document.getElementById('status').style.display === 'none')",timeout=120000)
  page.wait_for_timeout(800)
  out=ROOT/'public/previews'/f'{dim}.png';out.parent.mkdir(parents=True,exist_ok=True)
  page.screenshot(path=str(out));print(dim,errors,flush=True)
 browser.close()
