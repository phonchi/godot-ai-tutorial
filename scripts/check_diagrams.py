from pathlib import Path
from bs4 import BeautifulSoup
import subprocess,json
ROOT=Path(__file__).resolve().parents[1];out=ROOT/'.tools/diagram-check';out.mkdir(parents=True,exist_ok=True)
candidates=list((Path.home()/'.codex/plugins/cache/diagram-design').glob('*/**/skills/diagram-design/scripts/self_check.py'))
assert candidates, 'Installed diagram-design checker not found'
checker=max(candidates,key=lambda p:tuple(int(n) for n in p.parents[3].name.split('.')))
reports=[]
for kind,slug in [('scene','02-editor'),('signal','04-signals'),('workflow','06-agent-workflow'),('state','10-ui-state'),('coordinates','15-3d-controller')]:
 s=BeautifulSoup((ROOT/f'dist/lessons/{slug}/index.html').read_text(),'html.parser');svg=s.select_one('figure.lesson-figure svg');assert svg is not None
 file=out/f'{kind}.html';file.write_text('<!doctype html><html lang="zh-TW"><meta charset="utf-8"><title>'+kind+'</title><body>'+str(svg)+'</body></html>')
 r=subprocess.run(['python3',str(checker),str(file)],capture_output=True,text=True)
 reports.append({'kind':kind,'exit_code':r.returncode,'output':r.stdout+r.stderr});assert r.returncode==0,r.stdout+r.stderr
(ROOT/'verification/diagrams.json').write_text(json.dumps(reports,ensure_ascii=False,indent=2));print('DIAGRAM CONTRACTS PASS',len(reports))
