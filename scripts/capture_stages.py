"""Capture a real frame of every checkpoint for the downloads timeline (needs a display; runs Godot one at a time)."""
import os, shutil, subprocess, tempfile
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
ENGINE = os.environ.get('GODOT_BIN', str(ROOT / '.tools/godot/Godot_v4.7.2-stable_linux.x86_64'))
out_dir = ROOT / 'public' / 'previews' / 'stages'
out_dir.mkdir(parents=True, exist_ok=True)
for project in sorted((ROOT / 'examples').glob('*/*')):
    driver = project / 'tests' / 'stage_shot.gd'
    driver.parent.mkdir(exist_ok=True)
    shutil.copy(ROOT / 'scripts' / 'capture' / 'stage_shot.gd', driver)
    try:
        with tempfile.TemporaryDirectory() as tmp:
            shot = Path(tmp) / 'shot.png'
            subprocess.run([ENGINE, '--path', str(project), '--resolution', '960x600', '--script', 'res://tests/stage_shot.gd'],
                           env=dict(os.environ, SHOT_PATH=str(shot), STAGE_NAME=project.name), check=True, capture_output=True, timeout=120)
            target = out_dir / f'{project.parent.name}-{project.name}.webp'
            Image.open(shot).convert('RGB').resize((480, 300), Image.LANCZOS).save(target, quality=78, method=5)
            print(target.relative_to(ROOT), flush=True)
    finally:
        driver.unlink(missing_ok=True)
        Path(str(driver) + '.uid').unlink(missing_ok=True)
        if not any(driver.parent.iterdir()):
            driver.parent.rmdir()
