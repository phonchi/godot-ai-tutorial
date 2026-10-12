"""Fetch only Web export templates from the official ZIP using HTTP byte ranges."""
import io, shutil, zipfile, requests
from pathlib import Path
URL='https://github.com/godotengine/godot-builds/releases/download/4.7.2-stable/Godot_v4.7.2-stable_export_templates.tpz'
class RemoteZip(io.RawIOBase):
 def __init__(self):
  self.session=requests.Session();r=self.session.head(URL,allow_redirects=True,timeout=30);r.raise_for_status();self.url=r.url;self.size=int(r.headers['Content-Length']);self.pos=0
 def seekable(self):return True
 def tell(self):return self.pos
 def seek(self,offset,whence=0):
  self.pos=offset if whence==0 else self.pos+offset if whence==1 else self.size+offset;return self.pos
 def read(self,size=-1):
  if size<0:size=self.size-self.pos
  size=min(size,self.size-self.pos)
  if not size:return b''
  r=self.session.get(self.url,headers={'Range':f'bytes={self.pos}-{self.pos+size-1}'},stream=True,timeout=60)
  if r.status_code!=206:r.close();raise RuntimeError(f'Range unsupported: {r.status_code}')
  data=r.content;r.close()
  if len(data)!=size:raise RuntimeError(f'Expected {size} bytes, got {len(data)}')
  self.pos+=size;return data
out=Path('.tools/templates/web');out.mkdir(parents=True,exist_ok=True)
with zipfile.ZipFile(RemoteZip()) as archive:
 for info in archive.infolist():
  if 'web' in info.filename.lower():print(info.filename,info.file_size,flush=True)
 for info in archive.infolist():
  if info.filename.endswith('web_nothreads_release.zip') or info.filename.endswith('web_nothreads_debug.zip') or info.filename.endswith('version.txt'):
   target=out/Path(info.filename).name
   with archive.open(info) as source,target.open('wb') as dest:shutil.copyfileobj(source,dest,1024*1024)
   print('EXTRACTED',target,target.stat().st_size,flush=True)
