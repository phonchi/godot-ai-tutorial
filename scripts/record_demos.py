"""Record the homepage gameplay previews from the real final checkpoints.

Runs Godot (not headless; needs a display) with Movie Maker mode and a demo driver from scripts/capture/,
then packs the frames into looping animated WebP files under public/previews/.
"""
import os, shutil, subprocess, tempfile
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
ENGINE = os.environ.get('GODOT_BIN', str(ROOT / '.tools/godot/Godot_v4.7.2-stable_linux.x86_64'))
FPS, FRAMES, SIZE = 20, 130, (720, 450)

for dimension, stage in [('2d', '05-final'), ('3d', '04-final')]:
    project = ROOT / 'examples' / dimension / stage
    driver = project / 'tests' / 'autoplay.gd'
    shutil.copy(ROOT / 'scripts' / 'capture' / f'autoplay_{dimension}.gd', driver)
    try:
        with tempfile.TemporaryDirectory() as frames:
            env = dict(os.environ, DEMO_FRAMES=str(FRAMES))
            subprocess.run([ENGINE, '--path', str(project), '--resolution', '960x600', '--fixed-fps', str(FPS),
                            '--write-movie', f'{frames}/frame.png', '--script', 'res://tests/autoplay.gd'],
                           env=env, check=True, capture_output=True)
            paths = sorted(Path(frames).glob('frame*.png'))[10:]
            images = [Image.open(path).convert('RGB').resize(SIZE, Image.LANCZOS) for path in paths]
            target = ROOT / 'public' / 'previews' / f'{dimension}.webp'
            images[0].save(target, save_all=True, append_images=images[1:], duration=1000 // FPS, loop=0, quality=62, method=5)
            print(dimension, len(images), 'frames ->', target.relative_to(ROOT), f'{target.stat().st_size / 1e6:.2f} MB', flush=True)
    finally:
        driver.unlink(missing_ok=True)
        Path(str(driver) + '.uid').unlink(missing_ok=True)
