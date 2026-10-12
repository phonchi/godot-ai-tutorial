from pathlib import Path
from playwright.sync_api import sync_playwright
import json
ROOT=Path(__file__).resolve().parents[1];result={}
with sync_playwright() as p:
 browser=p.chromium.launch(headless=True,args=['--use-angle=swiftshader','--enable-unsafe-swiftshader','--disable-dev-shm-usage'],chromium_sandbox=False)
 page=browser.new_page(viewport={'width':1440,'height':1000})
 page.goto('http://127.0.0.1:4322/godot-ai-tutorial/play/',wait_until='networkidle')
 buttons=page.locator('.load-game')
 result['initial_frames']=page.locator('.play-card iframe').count()
 buttons.nth(0).click();result['after_first']=page.locator('.play-card iframe').count()
 # Switch without waiting for either full engine download: the former frame must disappear.
 buttons.nth(1).click();result['after_switch']=page.locator('.play-card iframe').count();result['active_game']=page.locator('.play-card iframe').get_attribute('src')
 buttons.nth(1).click();result['after_unload']=page.locator('.play-card iframe').count()
 browser.close()
(ROOT/'verification/play-controls.json').write_text(json.dumps(result,indent=2));print(result)
assert result['initial_frames']==0 and result['after_first']==1 and result['after_switch']==1 and '/3d/' in result['active_game'] and result['after_unload']==0
