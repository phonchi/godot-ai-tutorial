from playwright.sync_api import sync_playwright
from pathlib import Path
from PIL import Image
from io import BytesIO
import json,sys
ROOT=Path(__file__).resolve().parents[1];BASE=sys.argv[1] if len(sys.argv)>1 else 'http://127.0.0.1:4322/godot-ai-tutorial/'
result=[]
with sync_playwright() as p:
 browser=p.chromium.launch(headless=True,args=['--use-angle=swiftshader','--enable-unsafe-swiftshader','--disable-dev-shm-usage'],chromium_sandbox=False)
 page=browser.new_page(viewport={'width':960,'height':600},device_scale_factor=1)
 errors=[];messages=[];page.on('pageerror',lambda e:errors.append(str(e)));page.on('console',lambda m:messages.append({'type':m.type,'text':m.text}) if m.type=='error' else None)
 for dim in ['2d','3d']:
  errors.clear();messages.clear()
  response=page.goto(BASE+f'play/{dim}/index.html',wait_until='networkidle',timeout=120000)
  page.wait_for_function("document.getElementById('canvas') && (!document.getElementById('status') || document.getElementById('status').style.display === 'none')",timeout=120000)
  page.locator('canvas').click();page.wait_for_timeout(300);page.keyboard.press('Enter');page.wait_for_timeout(1400)
  before=page.screenshot();page.keyboard.down('d');page.wait_for_timeout(550);page.keyboard.up('d');page.wait_for_timeout(100)
  after=page.screenshot();page.keyboard.press('r');page.wait_for_timeout(500);restart=page.screenshot()
  for label,data in [('before',before),('after',after),('restart',restart)]:(ROOT/'verification'/f'game-{dim}-{label}.png').write_bytes(data)
  def difference(a,b):
   aa=Image.open(BytesIO(a)).convert('RGB');bb=Image.open(BytesIO(b)).convert('RGB');return sum(x!=y for x,y in zip(aa.getdata(),bb.getdata()))
  delta=difference(before,after)
  # 2D player body pixels (#fff1d6) provide evidence of actual movement, beyond animated backgrounds.
  movement=None
  if dim=='2d':
   def cx(raw):
    im=Image.open(BytesIO(raw)).convert('RGB');points=[x for y in range(70,580) for x in range(20,940) if im.getpixel((x,y))==(255,241,214)]
    return sum(points)/len(points) if points else None
   a,b,c=cx(before),cx(after),cx(restart);movement={'before':a,'after':b,'restart':c};assert a is not None and b is not None and b>a+30 and abs(c-480)<5
  assert response.status==200 and delta>100 and not errors and not messages
  result.append({'game':dim,'status':response.status,'changed_pixels_after_input':delta,'player_x':movement,'page_errors':list(errors),'console_errors':list(messages)})
 browser.close()
(ROOT/'verification/web-games.json').write_text(json.dumps(result,indent=2));print(json.dumps(result,indent=2))
