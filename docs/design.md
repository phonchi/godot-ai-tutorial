# Design decisions

Audience: programmers new to Godot. Reading context: laptop for coding, mobile for reviewing lessons. Warm editorial/book base with game accents taken from the two demo games. Visual variance 5/10, motion 3/10 (home, play, downloads, chapter header only; lesson bodies stay calm), information density 6/10, asset dependence 6/10 (real game captures), brand fidelity 5/10.

## Tokens (src/styles/course.css)
- Light: paper #FAF9F5, surface #FFFFFF, ink #141413, text #30302D, muted #55534C, border #D1CFC5, accent #984832 (wash #FBE9DF).
- Dark (Starlight theme select re-enabled): bg #1B1A17, surface #24221D, border #3A3731, text #ECE8DD (~14:1), muted #B5AE9F (~7.9:1), accent #E08A63 (~6.6:1).
- Game accents shared by site and games: dusk night #10302D/#163F3B, star gold #F6C453 (fills only on light backgrounds), mint #7FD8BE, cream #FFF1D6. Threats use terracotta #E0673F; the hero is cream + mint in both games.
- Every component colour is a token; diagrams use --dg-* tokens with light fallbacks embedded in the SVG.
- Local Noto Serif TC titles (tracking ≥ -0.02em for CJK), Noto Sans TC body, platform monospace code and <kbd>.
- Radius 6–14px; soft shadows only on raised cards and the game window. Motion: 120 ms micro, 160–240 ms cards, easing cubic-bezier(.2,.8,.2,1); all motion off under prefers-reduced-motion.

## Components
- Home: hero with a "game window" showing looping animated WebP captures of the real final games (2D/3D tabs; PNG under reduced motion and narrow screens); "mechanics you will build" tiles (07–11, 14–17); four-world course map whose chapter dots light from the existing localStorage progress. Nothing is locked; the map is navigation plus orientation.
- Chapter header: "本章解鎖" badge on mechanic chapters only (src/data/unlocks.ts).
- Play: controls legend with <kbd>, one game iframe at a time, touch-only devices see a desktop notice instead of the load button.
- Downloads: vertical timeline with a real captured frame for each of the nine checkpoints.

## Games
- Procedural art only (code drawing, shaders, particles) and build-time generated CC0 sound effects. No external assets.
- 2D Star Garden: dusk garden arena framed by bushes, cream/mint player, gold five-point stars, terracotta chasers, rose bouncers, fireflies and a soft shader background.
- 3D Floating Isles: warm dawn sky with fog matching the horizon, ACES tonemap, grass-on-earth islands in three depth layers, cloud sea, low warm sun with shadows, emissive orbs and teal gate on a light stone arch, dark-red thorn balls on Path3D.
- Previews: `scripts/record_demos.py` (Godot Movie Maker + demo drivers in scripts/capture/), `scripts/capture_stages.py`, `scripts/capture_games.py` (Web build). All are genuine game execution, not mockups.

## Process
- Official Godot icon identifies the engine. No endorsement implied. See THIRD-PARTY-NOTICES.md.
- No running game is loaded until requested. Browser checks use one page; Godot validation/export runs sequentially.
