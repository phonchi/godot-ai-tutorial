extends SceneTree
## Headless behaviour checks for the final 2D game. Run:
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
	await physics_frames(2)
	check(game.state == game.State.TITLE and not game.player.enabled, "game opens on the title screen")
	game.start_game()
	await physics_frames(2)
	check(game.state == game.State.PLAYING and game.wave_index == 0, "start enters wave 1")
	check(game.stars.size() == 3 and game.enemies.size() == 2, "wave 1 has 3 stars, 1 chaser, 1 bouncer")

	# Dash: a short, fixed burst of speed with a cooldown.
	var player = game.player
	player.cooldown_left = 0.0
	player.facing = Vector2.RIGHT
	var before: Vector2 = player.position
	check(player.try_dash(), "dash starts")
	check(not player.try_dash(), "cooldown blocks an immediate second dash")
	await physics_frames(12)
	var dash_distance: float = player.position.x - before.x
	check(dash_distance > 95.0 and dash_distance < 150.0, "dash travels about 120 px (got %.1f)" % dash_distance)
	check(not player.is_dashing(), "dash ends after dash_time")

	# Chasers wait for their warm-up, then steer toward the player.
	var chaser = game.enemies[0]
	player.invulnerable = 99.0
	await physics_frames(32)
	var gap_before: float = chaser.position.distance_to(player.position)
	await physics_frames(20)
	check(chaser.position.distance_to(player.position) < gap_before, "chaser moves toward the player")

	# Ongoing contact is checked every physics frame; invulnerability blocks repeats.
	player.invulnerable = 0.0
	chaser.position = player.position
	await physics_frames(3)
	check(game.lives == 2, "touching an active enemy costs one life")
	await physics_frames(10)
	check(game.lives == 2, "invulnerability prevents repeated damage")

	# Waves: 3 + 3 + 4 stars, enemies grow each wave.
	player.invulnerable = 99.0
	for star in game.stars.duplicate():
		game.collect_item(star)
	check(game.score == 3 and game.enemies.is_empty(), "clearing wave 1 removes its enemies")
	check(game.wave_index == 0, "the next wave waits for the pause timer")
	await physics_frames(60)
	check(game.wave_index == 1 and game.stars.size() == 3 and game.enemies.size() == 3, "wave 2: 3 stars, 2 chasers, 1 bouncer")
	var repeated = game.stars[0]
	game.collect_item(repeated)
	game.collect_item(repeated)
	check(game.score == 4, "the same star cannot count twice")
	for star in game.stars.duplicate():
		game.collect_item(star)
	game.next_wave()
	await physics_frames(2)
	check(game.wave_index == 2 and game.stars.size() == 4 and game.enemies.size() == 5, "wave 3: 4 stars, 3 chasers, 2 bouncers")
	game.elapsed = 42.5
	for star in game.stars.duplicate():
		game.collect_item(star)
	check(game.score == 10 and game.state == game.State.WON, "ten stars win")
	check(not player.enabled, "winning disables the player")
	player.cooldown_left = 0.0
	player.dash_left = player.dash_time
	var frozen: Vector2 = player.position
	await physics_frames(6)
	check(player.position.distance_to(frozen) < 0.5 and not player.is_dashing(), "a dash in progress stops when the game ends")
	check(is_equal_approx(game.load_best_time(), 42.5), "best time is saved to user://")

	game.restart_game()
	await physics_frames(3)
	var restarted = current_scene
	check(is_instance_valid(restarted) and restarted != game, "restart creates a new scene")
	check(restarted.state == restarted.State.PLAYING and restarted.score == 0 and restarted.lives == 3, "restart skips the title and resets progress")
	check(is_equal_approx(restarted.best_time, 42.5), "best time is loaded on restart")
	check(InputMap.action_get_events("move_left").size() == 4, "restart does not duplicate input bindings")

	# Losing: three separate hits end the run.
	for i in 3:
		restarted.player.invulnerable = 0.0
		restarted.damage_player()
	check(restarted.state == restarted.State.LOST and not restarted.player.enabled, "three hits lose")

	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://best.cfg"))
	current_scene = null
	restarted.queue_free()
	await physics_frames(2)
	print("BEHAVIOR CHECKS: ", "PASS" if failures == 0 else "FAIL", " (", failures, " failures)")
	quit(0 if failures == 0 else 1)
