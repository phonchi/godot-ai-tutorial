"""Record an isolated agent exercise: understand, edit, diagnose, repair, execute."""
from pathlib import Path
import shutil,subprocess
ROOT=Path(__file__).resolve().parents[1];dest=ROOT/'.tools/codex-smoke'
shutil.copytree(ROOT/'examples/2d/01-movement',dest,dirs_exist_ok=True,ignore=shutil.ignore_patterns('.godot'))
engine=ROOT/'.tools/godot/Godot_v4.7.2-stable_linux.x86_64';player=dest/'scripts/player.gd'
original=player.read_text();feature=original.replace('speed: float = 260.0','speed: float = 300.0')
assert feature!=original
player.write_text(feature.replace('var enabled: bool = true','var enabled: bool = "broken"'))
def run(args,name):
 r=subprocess.run([str(engine),'--headless','--path',str(dest),*args],capture_output=True,text=True,timeout=30)
 text=r.stdout+r.stderr;(ROOT/'verification'/name).write_text(text);return r.returncode,text
bad_code,bad_log=run(['--check-only','--script','scripts/player.gd'],'codex-smoke-error.log')
assert 'Parse Error' in bad_log or 'SCRIPT ERROR' in bad_log
player.write_text(feature)
good_code,good_log=run(['--check-only','--script','scripts/player.gd'],'codex-smoke-repaired.log')
assert good_code==0 and 'ERROR' not in good_log
import_code,import_log=run(['--import'],'codex-smoke-import.log')
assert import_code==0 and 'ERROR' not in import_log
run_code,run_log=run(['--quit-after','10'],'codex-smoke-run.log')
assert run_code==0 and 'ERROR' not in run_log
(ROOT/'verification/codex-smoke.md').write_text(f'''# Codex agent exercise\n\nA bounded exercise executed by the parent Codex in an isolated copy of the movement checkpoint.\n\n1. Read `scripts/player.gd`: `Input.get_vector` computes the normalized/deadzone-aware 2D input vector. `velocity = direction * speed` expresses pixels per second; `move_and_slide()` applies the physics-step movement, so no second delta multiplication is needed.\n2. Feature edit: speed 260 -> 300 only in `.tools/codex-smoke`.\n3. Diagnosis: introduced an invalid string assignment to a bool, executed Godot `--check-only --script scripts/player.gd`, observed the actual parse diagnostic, then restored a boolean.\n4. Repaired check exit: {good_code}. Runtime `--quit-after 10` exit: {run_code}.\n\nRaw logs: codex-smoke-error.log, codex-smoke-repaired.log, codex-smoke-run.log. Formal downloadable projects were not modified by this exercise.\n''')
print('CODEX AGENT EXERCISE PASS')
