extends SceneTree
## Demo driver for the homepage preview: a simple bot plays Star Garden while Godot's movie writer records frames.

var game: Node


func _initialize() -> void:
	call_deferred("run")


func run() -> void:
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	game.start_game()
	physics_frame.connect(steer)
	for i in int(OS.get_environment("DEMO_FRAMES")):
		await process_frame
	quit()


func steer() -> void:
	var player = game.player
	var direction := Vector2.ZERO
	var nearest := INF
	for star in game.stars:
		var gap: float = player.position.distance_to(star.position)
		if gap < nearest:
			nearest = gap
			direction = player.position.direction_to(star.position)
	for enemy in game.enemies:
		if not enemy.is_active():
			continue
		var distance: float = player.position.distance_to(enemy.position)
		if distance < 95.0:
			direction += enemy.position.direction_to(player.position) * (95.0 - distance) / 90.0
		if distance < 90.0 and player.cooldown_left <= 0.0:
			player.facing = direction.normalized()
			player.try_dash()
	direction = direction.normalized()
	axis("move_left", "move_right", direction.x)
	axis("move_up", "move_down", direction.y)


func axis(negative: StringName, positive: StringName, value: float) -> void:
	Input.action_release(negative)
	Input.action_release(positive)
	if value < -0.05:
		Input.action_press(negative, -value)
	elif value > 0.05:
		Input.action_press(positive, value)
