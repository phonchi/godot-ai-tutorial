# Project guidance

- Use Traditional Chinese for teaching text; retain code, commands and API names in English.
- This is a student-facing teaching site. Teach concepts, operations and observable behavior; keep build/review logs and authoring status in `verification/`.
- Godot baseline: 4.7.2, GDScript, Compatibility renderer, single-thread Web export. Verify version-sensitive claims against matching official docs.
- `scripts/build_examples.py` is the source for the eight generated checkpoints and ZIPs. Change the generator, rebuild, and validate affected behavior. Do not patch only a generated copy.
- `SourceExcerpt.astro` reads actual checkpoint code at build time. Keep lesson input-action names consistent with downloadable projects.
- `scripts/create_diagrams.py` and `LessonDiagram.astro` must stay synchronized. Embedded SVGs inherit site tokens, use accessible titles/descriptions and scroll within their own container.
- Preserve `/godot-ai-tutorial/` base paths. Normalize `import.meta.env.BASE_URL` before appending paths.
- Test meaningful behavior: Godot import and game rules, website build, internal links/ZIP integrity, and browser interactions. Parsing alone does not verify visuals.
- Conserve memory: run Godot and browser work sequentially; the play page permits only one loaded game iframe at a time. Type checking excludes generated `public/` engine files.
- Do not enable billing, API-based metered services, paid plans, renewing trials, or automatic upgrades.
