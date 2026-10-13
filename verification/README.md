# Verification evidence

Environment: Linux / WSL2; Godot `4.7.2.stable.official.ed1daf0bf`; Node.js 24; Python Playwright Chromium. The site is static Astro/Starlight, with local Noto fonts. Test browser work and Godot imports/exports run sequentially.

## Checks

- `astro-check.log`: site component/type checks (generated Web runtime files excluded).
- `site-build.log`: static build and Traditional Chinese Pagefind index.
- `site-check.json`: all generated HTML internal links, local assets, anchors, plus ZIP integrity/content checks. The ZIP set must equal the nine expected checkpoints exactly, so stale archives fail the check.
- `godot-stages.log`: all nine checkpoints are imported and smoke-run headless for 240 frames; any ERROR or WARNING line fails the build. Both final games then run `tests/behavior.gd` through real physics frames. 2D: title state, dash distance and cooldown, chaser steering after warm-up, per-frame contact damage with invulnerability, wave composition 3/3/4 with enemy counts, duplicate collection, win/lose, best time saved to `user://`, restart skipping the title, and no duplicated input bindings. 3D: landing, jump via the input action, orb deduplication, gate opening without auto-win, door tween, moving-platform carry (measured drift), flag respawn point, fall and patrol-contact respawn, exit win, best time, and restart.
- `web-export.log`: both real Godot Web exports using the matching official single-thread templates.
- `web-games.json`: genuine browser execution: click for focus, Enter leaves the title screen, then movement and restart. The 2D player centroid (body colour #FFF1D6) is measured before/after keyboard input and after restart. 3D input changes the actual rendered viewport. Native rule tests cover the 3D rules.
- `browser-check.json`: ten representative routes at 390/768/1440px in light mode and 390/1440px in dark mode (50 cases); page errors, page overflow, SVG text clipping, applied theme, task-copy interaction, persistent chapter progress, homepage progress dot, hero preview tab switch, chapter unlock badge, Traditional Chinese search results, mobile navigation.
- `play-controls.json`: zero initial iframes, one active game after switching, zero after unload.
- `diagrams.json`: eight accessible embedded SVG variants (including dash, waves and respawn) checked with the installed diagram-design checker.
- `mcp-smoke.log`: actual stdio initialization, tool listing, version and project-info calls at `bradypp/godot-mcp` commit `e11cfc786f8b2491dcceddf85c72c7c9c79a9108`. Scene-editing tools and editor-launch/debug capture are not exercised. Its read-only flag filters the advertised list; source inspection confirms it is not an OS sandbox or a server-side enforcement boundary.
- `codex-smoke.md`: isolated explanation, bounded speed edit, real parse-error diagnosis/repair and runtime check by the parent Codex.
- `claude-smoke.md`: Opus explanation and bounded edit, then repair based on actual error output relayed by Codex. This restricted Claude session has file tools rather than a shell; Codex runs Godot and verifies the repair. Roles are reported explicitly.
- `npm-audit.json`: package audit after the CSS parser override.
- Previews: `public/previews/{2d,3d}.webp` come from `scripts/record_demos.py` (Godot Movie Maker driving the real final games with demo scripts in `scripts/capture/`); `public/previews/stages/*.webp` from `scripts/capture_stages.py`; `public/previews/{2d,3d}.png` from `scripts/capture_games.py` against the Web export. All are genuine execution.
- Cross-model design review and code/visual review records are kept privately; their findings were verified before being applied.

Screenshots and raw logs remain in this project folder, excluded from Git as generated evidence. Public game preview PNGs are committed. Private cross-model supervisor records and prompt files are not published.

## Reproduce

```bash
npm ci
npm run check
npm run build
python3 scripts/check_site.py
GODOT_BIN=/absolute/path/godot python3 scripts/build_examples.py --test
npm run preview
# Set the actual preview URL if Astro selects another port.
python3 scripts/browser_check.py http://127.0.0.1:4322/godot-ai-tutorial/
python3 scripts/test_web_games.py http://127.0.0.1:4322/godot-ai-tutorial/
```

The Python browser scripts require Playwright and its Chromium; image checks additionally use Pillow. `check_diagrams.py` requires the installed diagram-design plugin and BeautifulSoup. The website build and public site do not require these verification tools.

## Practical limits

- Desktop keyboard gameplay is verified in Chromium; Safari, Firefox, mobile gameplay and touch controls are outside this release's acceptance scope. Gamepad bindings are verified as InputMap entries (event counts) only; no physical gamepad was exercised.
- SwiftShader (software WebGL) shows stray colours in `CPUParticles2D` per-instance colours during the first frames of a burst. The same Web build in GPU-backed Chromium (WSLg) renders the burst correctly; particles are tinted through node `modulate`, which minimises the artefact. Preview PNGs are captured with the GPU-backed browser when a display is available.
- Agent outputs vary. The examples are fixed references; headless checks do not prove visual polish or game feel.
- The Claude exercise is a relay between file-editing Opus and shell-executing Codex, not a claim that the restricted child CLI ran shell commands itself.
- MCP compatibility is scoped to the calls actually tested; the course describes its actual read-only limitations.
