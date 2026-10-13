extends SceneTree
## Saves one frame of a checkpoint at a moment that shows what the stage adds (download thumbnails).


func _initialize() -> void:
	call_deferred("run")


func frames(count: int) -> void:
	for i in count:
		await process_frame


func run() -> void:
	var stage := OS.get_environment("STAGE_NAME")
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	if game.has_method("start_game"):
		game.start_game()
	if game is Node2D:
		Input.action_press("move_right", 0.8)
		Input.action_press("move_up", 0.4)
		await frames(40 if stage in ["01-movement", "02-collect"] else 110)
		if stage == "02-collect" and not game.stars.is_empty():
			game.collect_item(game.stars[1])
			await frames(3)
		else:
			game.player.cooldown_left = 0.0
			game.player.try_dash()
			await frames(5)
	else:
		if stage == "03-platforms":
			game.player.global_position = Vector3(3.5, 1.85, -4.5)
			game.snap_camera()
		elif stage == "04-final":
			game.player.global_position = Vector3(-1.5, 2.65, -27.6)
			game.snap_camera()
		await frames(40)
		if stage == "02-controller":
			Input.action_press("jump")
			await frames(14)
	root.get_texture().get_image().save_png(OS.get_environment("SHOT_PATH"))
	quit()
