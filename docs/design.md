# Design decisions

Audience: programmers new to Godot. Reading context: laptop for coding, mobile for reviewing lessons. New teaching site, warm editorial/book language; visual variance 3/10, motion 1/10, information density 6/10, asset dependence 4/10, brand fidelity 4/10.

- Paper #FAF9F5, ink #141413, neutral #55534C, text accent #984832, accent wash #FBE9DF, border #D1CFC5.
- Local Noto Serif TC titles, Noto Sans TC body, platform monospace code. No synthetic Chinese italics.
- 8px spacing base, 4–8px radius, borders instead of shadows. Main reading measure limited; wider homepage.
- Official Godot icon identifies the engine. No endorsement implied. See THIRD-PARTY-NOTICES.md.
- 2D/3D preview PNGs captured from genuine exported game execution, not mockups.
- Lesson diagrams: scene tree (tree), signal flow (sequence), collaboration (flow), game state (state), axes (dependency). Shared accessible inline SVG and site tokens; diagrams scroll locally on small screens.
- html-visualizer informs concept ordering, examples, boundary cases, progressive disclosure. diagram-design informs geometry and readable relationships. The public teaching UI has no authoring-session badges or review controls.
- No running game is loaded until requested. Browser checks use one page; Godot validation/export runs sequentially.
