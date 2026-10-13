extends SceneTree
## Headless behaviour checks for the final 3D game. Run:
## godot --headless --path . --script res://tests/behavior.gd

var failures: int = 0


func _initialize() -> void:
	call_deferred("run")


func check(condition: bool, message: String) -> void:
	print(("  ok   " if condition else "  FAIL ") + message)
	if not condition:
		failures += 1


func physics_frames(count: int) -> void:
	for i in count:
		await physics_frame
	await process_frame


func run() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://best.cfg"))
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await physics_frames(10)
	check(game.state == game.State.TITLE and not game.player.enabled, "game opens on the title screen")
	game.start_game()
	var player = game.player
	await physics_frames(20)
	check(player.is_on_floor(), "player lands on the start island")

	# Jump: pressing the action lifts the player; holding it in the air does not double jump.
	var ground_y: float = player.position.y
	Input.action_press("jump")
	await physics_frames(10)
	Input.action_release("jump")
	check(player.position.y > ground_y + 0.4, "jump lifts the player")
	await physics_frames(60)
	check(player.is_on_floor() and absf(player.position.y - ground_y) < 0.05, "player lands again")

	# Gate stays shut until all five orbs are collected.
	check(not game.try_exit() and game.state == game.State.PLAYING, "exit is locked before collection")
	var first = game.orbs[0]
	player.global_position = first.global_position + Vector3(0, -0.25, 0)
	player.velocity = Vector3.ZERO
	await physics_frames(5)
	check(game.score == 1, "touching an orb collects it through body_entered")
	game.collect_item(first)
	check(game.score == 1, "the same orb cannot count twice")
	for orb in game.orbs.duplicate():
		game.collect_item(orb)
	check(game.score == 5 and game.gate_open and game.state == game.State.PLAYING, "five orbs open the gate without winning")
	await physics_frames(90)
	check(game.gate.position.y < -1.5, "gate tween lowers the door")

	# Moving platforms carry a CharacterBody3D standing on them.
	var platform = game.platforms[0]
	player.global_position = platform.global_position + Vector3(0, 0.8, 0)
	player.velocity = Vector3.ZERO
	await physics_frames(10)
	var offset: Vector3 = player.global_position - platform.global_position
	await physics_frames(60)
	var drift: Vector3 = (player.global_position - platform.global_position) - offset
	check(player.is_on_floor() and Vector2(drift.x, drift.z).length() < 0.15, "moving platform carries the player (drift %.3f)" % Vector2(drift.x, drift.z).length())

	# Respawn: falling returns to the active respawn point; flags move that point.
	game.activate_checkpoint(game.flags[0])
	var saved: Vector3 = game.respawn_point
	check(saved.distance_to(game.FLAG_POINTS[0]) < 1.0, "touching a flag saves a respawn point")
	player.global_position = Vector3(0, -20, 0)
	await physics_frames(3)
	check(player.global_position.distance_to(saved) < 0.5 and game.falls == 1, "falling respawns at the flag")

	# Patrols advance along their Path3D and send the player back on contact.
	var patrol = game.patrols[0]
	var progress_before: float = patrol.progress
	await physics_frames(30)
	check(patrol.progress > progress_before, "patrol enemy advances along its path")
	player.global_position = patrol.hitbox.global_position
	await physics_frames(3)
	check(game.falls == 2 and player.global_position.distance_to(saved) < 1.0, "touching a patrol respawns the player")
	await physics_frames(40)
	check(game.falls == 2, "a respawn is not followed by a second, stale hit")

	game.elapsed = 75.25
	player.global_position = game.exit_area.global_position + Vector3(0, -0.75, 0)
	player.velocity = Vector3.ZERO
	await physics_frames(5)
	check(game.state == game.State.WON and not player.enabled, "walking through the open gate wins")
	check(is_equal_approx(game.load_best_time(), game.best_time) and absf(game.best_time - 75.25) < 0.5, "best time is saved to user://")

	game.restart_game()
	await physics_frames(3)
	var restarted = current_scene
	check(is_instance_valid(restarted) and restarted != game, "restart creates a new scene")
	check(restarted.state == restarted.State.PLAYING and restarted.score == 0 and restarted.orbs.size() == 5, "restart skips the title and resets orbs")
	check(InputMap.action_get_events("move_left").size() == 4, "restart does not duplicate input bindings")

	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://best.cfg"))
	current_scene = null
	restarted.queue_free()
	await physics_frames(2)
	print("BEHAVIOR CHECKS: ", "PASS" if failures == 0 else "FAIL", " (", failures, " failures)")
	quit(0 if failures == 0 else 1)
