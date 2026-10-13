extends SceneTree
## Demo driver for the homepage preview: a slow camera glide across Floating Isles, recorded by Godot's movie writer.

const PATH := [Vector3(0, 6.5, 17), Vector3(7, 5.5, 2), Vector3(8, 6, -12), Vector3(-6, 6.5, -20), Vector3(0, 5.5, -21)]
const LOOK := [Vector3(0, 0.5, 4), Vector3(0, 1, -6), Vector3(0, 1.5, -18), Vector3(0, 2, -28), Vector3(0, 2.5, -34)]


func _initialize() -> void:
	call_deferred("run")


func sample(points: Array, t: float) -> Vector3:
	var scaled := t * (points.size() - 1)
	var i := mini(int(scaled), points.size() - 2)
	var local := scaled - i
	var before: Vector3 = points[maxi(i - 1, 0)]
	var after: Vector3 = points[mini(i + 2, points.size() - 1)]
	return points[i].cubic_interpolate(points[i + 1], before, after, local)


func run() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	game.start_game()
	game.set_physics_process(false)
	var frames := int(OS.get_environment("DEMO_FRAMES"))
	for frame in frames:
		var t := smoothstep(0.0, 1.0, float(frame) / float(frames - 1))
		game.camera.global_position = sample(PATH, t)
		game.camera.look_at(sample(LOOK, t))
		await process_frame
	quit()
