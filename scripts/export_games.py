"""Export final games using project-local official Web templates, one at a time."""
import os,shutil,subprocess
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
engine=Path(os.environ.get('GODOT_BIN',ROOT/'.tools/godot/Godot_v4.7.2-stable_linux.x86_64'))
template=ROOT/'.tools/templates/web/web_nothreads_release.zip'
for dim,stage in [('2d','05-final'),('3d','04-final')]:
 source=ROOT/'examples'/dim/stage
 work=ROOT/'.tools/export'/dim
 shutil.copytree(source,work,dirs_exist_ok=True,ignore=shutil.ignore_patterns('.godot'))
 presets=work/'export_presets.cfg'
 presets.write_text(presets.read_text().replace('custom_template/release=""',f'custom_template/release="{template}"'))
 out=ROOT/'public/play'/dim/'index.html';out.parent.mkdir(parents=True,exist_ok=True)
 subprocess.run([str(engine),'--headless','--path',str(work),'--import'],check=True)
 subprocess.run([str(engine),'--headless','--path',str(work),'--export-release','Web',str(out)],check=True)
 out.write_text(out.read_text().rstrip()+'\n')
 print('EXPORTED',dim,flush=True)
