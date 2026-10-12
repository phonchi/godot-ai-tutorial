# Codex agent exercise

A bounded exercise executed by the parent Codex in an isolated copy of the movement checkpoint.

1. Read `scripts/player.gd`: `Input.get_vector` computes the normalized/deadzone-aware 2D input vector. `velocity = direction * speed` expresses pixels per second; `move_and_slide()` applies the physics-step movement, so no second delta multiplication is needed.
2. Feature edit: speed 260 -> 300 only in `.tools/codex-smoke`.
3. Diagnosis: introduced an invalid string assignment to a bool, executed Godot `--check-only --script scripts/player.gd`, observed the actual parse diagnostic, then restored a boolean.
4. Repaired check exit: 0. Runtime `--quit-after 10` exit: 0.

Raw logs: codex-smoke-error.log, codex-smoke-repaired.log, codex-smoke-run.log. Formal downloadable projects were not modified by this exercise.
