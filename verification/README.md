# Verification evidence

Environment: Linux / WSL2; Godot `4.7.2.stable.official.ed1daf0bf`; Node.js 24; Python Playwright Chromium. The site is static Astro/Starlight, with local Noto fonts. Test browser work and Godot imports/exports run sequentially.

## Checks

- `astro-check.log`: site component/type checks (generated Web runtime files excluded).
- `site-build.log`: static build and Traditional Chinese Pagefind index.
- `site-check.json`: all generated HTML internal links, local assets, anchors, plus eight ZIP integrity/content checks.
- `godot-stages.log`: eight clean checkpoint imports and behavioral checks for both final games. Checks include duplicate collection, damage invulnerability, hazard spawning/cap, victory/failure, 3D exit gating, restart state and input binding deduplication. Import exit codes alone are insufficient; logs are checked for engine errors.
- `web-export.log`: both real Godot Web exports using the matching official single-thread templates.
- `web-games.json`: genuine browser execution, movement and restart. The 2D player centroid is measured before/after keyboard input and after restart, beyond merely detecting animation changes. 3D input changes the actual rendered viewport. Native rule tests cover 3D collection/exit behavior.
- `browser-check.json`: real 390/768/1440px rendering; page errors, page overflow, SVG text clipping, task-copy interaction, persistent chapter progress, Traditional Chinese search results, mobile navigation.
- `play-controls.json`: zero initial iframes, one active game after switching, zero after unload.
- `diagrams.json`: five accessible embedded SVG variants checked with the installed diagram-design checker.
- `mcp-smoke.log`: actual stdio initialization, tool listing, version and project-info calls at `bradypp/godot-mcp` commit `e11cfc786f8b2491dcceddf85c72c7c9c79a9108`. Scene-editing tools and editor-launch/debug capture are not exercised. Its read-only flag filters the advertised list; source inspection confirms it is not an OS sandbox or a server-side enforcement boundary.
- `codex-smoke.md`: isolated explanation, bounded speed edit, real parse-error diagnosis/repair and runtime check by the parent Codex.
- `claude-smoke.md`: Opus explanation and bounded edit, then repair based on actual error output relayed by Codex. This restricted Claude session has file tools rather than a shell; Codex runs Godot and verifies the repair. Roles are reported explicitly.
- `npm-audit.json`: package audit after the CSS parser override.

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

- Desktop keyboard gameplay is verified in Chromium; Safari, Firefox, mobile gameplay and touch controls are outside this release's acceptance scope.
- Agent outputs vary. The examples are fixed references; headless checks do not prove visual polish or game feel.
- The Claude exercise is a relay between file-editing Opus and shell-executing Codex, not a claim that the restricted child CLI ran shell commands itself.
- MCP compatibility is scoped to the calls actually tested; the course describes its actual read-only limitations.
