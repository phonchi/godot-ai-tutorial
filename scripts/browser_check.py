from playwright.sync_api import sync_playwright
from pathlib import Path
import json,sys
BASE=sys.argv[1] if len(sys.argv)>1 else 'http://127.0.0.1:4322/godot-ai-tutorial/'
ROOT=Path(__file__).resolve().parents[1];out=ROOT/'verification';out.mkdir(exist_ok=True)
result={'base':BASE,'pages':[],'errors':[]}
with sync_playwright() as p:
 browser=p.chromium.launch(headless=True,args=['--disable-dev-shm-usage','--use-angle=swiftshader','--enable-unsafe-swiftshader'],chromium_sandbox=False)
 page=browser.new_page(viewport={'width':1440,'height':1000},device_scale_factor=1)
 page.on('pageerror',lambda e:result['errors'].append(str(e)))
 for route in ['', 'lessons/04-signals/','lessons/07-2d-movement/','lessons/15-3d-controller/','lessons/18-mcp/','prompts/','downloads/','play/']:
  for width in [1440,768,390]:
   page.set_viewport_size({'width':width,'height':1000 if width==1440 else 844})
   response=page.goto(BASE+route,wait_until='networkidle',timeout=60000)
   page.evaluate('document.fonts.ready');page.wait_for_timeout(100)
   overflow=page.evaluate('document.documentElement.scrollWidth > window.innerWidth + 1')
   name=(route.strip('/').replace('/','-') or 'home')+f'-{width}'
   page.screenshot(path=str(out/f'{name}.png'),full_page=True)
   issues=page.evaluate("""() => Array.from(document.querySelectorAll('.lesson-figure svg text')).flatMap(t => {
    const b=t.getBBox(),v=t.ownerSVGElement.viewBox.baseVal,r=t.previousElementSibling;
    const outside=b.x<v.x-1||b.y<v.y-1||b.x+b.width>v.x+v.width+1||b.y+b.height>v.y+v.height+1;
    let clipped=false;
    if(r?.tagName==='rect'){const x=+r.getAttribute('x'),y=+r.getAttribute('y'),w=+r.getAttribute('width'),h=+r.getAttribute('height');clipped=b.x<x-1||b.y<y-1||b.x+b.width>x+w+1||b.y+b.height>y+h+1;}
    return outside||clipped?[t.textContent]:[];
   })""")
   result['pages'].append({'route':route,'width':width,'status':response.status,'overflow':overflow,'diagram_clipping':issues})
 page.goto(BASE+'prompts/',wait_until='networkidle');page.context.grant_permissions(['clipboard-read','clipboard-write'])
 page.locator('.task-copy').first.click();page.wait_for_function("document.querySelector('.task-copy').textContent === '已複製'",timeout=5000);result['copy']=page.locator('.task-copy').first.inner_text()=='已複製'
 page.goto(BASE+'lessons/04-signals/',wait_until='networkidle');button=page.locator('.progress-button');button.click();page.reload(wait_until='networkidle');result['progress_persists']=page.locator('.progress-button').get_attribute('aria-pressed')=='true';page.locator('.progress-button').click()
 # Built static search must resolve a Traditional Chinese term.
 page.locator('button[data-open-modal]').first.click();page.locator('.pagefind-ui__search-input').fill('訊號');page.wait_for_timeout(1000)
 result['search_results']=page.locator('.pagefind-ui__result').count()
 page.keyboard.press('Escape')
 page.set_viewport_size({'width':390,'height':844})
 page.locator('button[popovertarget="starlight__sidebar"]').click()
 result['mobile_navigation']=page.locator('#starlight__sidebar').is_visible()
 browser.close()
(out/'browser-check.json').write_text(json.dumps(result,ensure_ascii=False,indent=2));print(json.dumps(result,ensure_ascii=False))
assert not result['errors'] and result['copy'] and result['progress_persists'] and result['search_results']>0 and result['mobile_navigation']
assert all(x['status']==200 and not x['overflow'] and not x['diagram_clipping'] for x in result['pages'])
