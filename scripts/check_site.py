from pathlib import Path
from html.parser import HTMLParser
from urllib.parse import urlparse,unquote,urljoin
import zipfile,json
ROOT=Path(__file__).resolve().parents[1];DIST=ROOT/'dist';BASE='/godot-ai-tutorial/'
class Page(HTMLParser):
 def __init__(self):super().__init__();self.links=[];self.ids=set()
 def handle_starttag(self,tag,attrs):
  attrs=dict(attrs)
  if 'id' in attrs:self.ids.add(attrs['id'])
  if tag in ['a','img','script','link','iframe']:
   value=attrs.get('href',attrs.get('src'))
   if value:self.links.append(value)
pages={}
for path in DIST.rglob('*.html'):
 parser=Page();parser.feed(path.read_text());pages[path.resolve()]=parser
errors=[];count=0
for path,page in pages.items():
 if path.name=='404.html':continue
 url='https://phonchi.github.io'+BASE+path.relative_to(DIST).as_posix()
 for link in page.links:
  parsed=urlparse(urljoin(url,link))
  if parsed.netloc!='phonchi.github.io' or not parsed.path.startswith(BASE):continue
  target=DIST/unquote(parsed.path[len(BASE):])
  if target.is_dir():target=target/'index.html'
  count+=1
  if not target.is_file():errors.append(f'{path.relative_to(DIST)} -> {link}')
  elif parsed.fragment and target.resolve() in pages and unquote(parsed.fragment) not in pages[target.resolve()].ids:
   errors.append(f'{path.relative_to(DIST)} -> missing anchor {link}')
archives=[]
for path in sorted((ROOT/'public/downloads').glob('*.zip')):
 with zipfile.ZipFile(path) as z:
  assert z.testzip() is None
  names=z.namelist()
  assert all('.godot/' not in name for name in names)
  for suffix in ['project.godot','main.tscn','scripts/main.gd','scripts/player.gd','AGENTS.md','CLAUDE.md','LICENSE']:
   assert any(name.endswith('/'+suffix) for name in names),(path,suffix)
  archives.append({'name':path.name,'files':len(names),'bytes':path.stat().st_size})
expected={f'{d}-{s}.zip' for d,stages in {'2d':['01-movement','02-collect','03-hazards','04-interface','05-final'],'3d':['01-world','02-controller','03-platforms','04-final']}.items() for s in stages}
assert {a['name'] for a in archives}==expected,sorted({a['name'] for a in archives}^expected)
report={'html_pages':len(pages),'internal_links_checked':count,'errors':errors,'archives':archives}
(ROOT/'verification/site-check.json').write_text(json.dumps(report,ensure_ascii=False,indent=2));print(json.dumps(report,ensure_ascii=False,indent=2));assert not errors
