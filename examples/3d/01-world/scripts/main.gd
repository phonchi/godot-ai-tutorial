extends Node3D
## Floating Isles (3D). Every node is created in code from _ready().
## While the game runs, open the Scene dock's Remote tab to see the real scene tree.

const HORIZON := Color("f2c79a")
const SKY_TOP := Color("4f8fbf")
const GRASS := Color("62a345")
const EARTH := Color("9a5f3a")
const STONE := Color("e2dbcb")
const LEAF := Color("3f8a45")
const BARK := Color("7a5236")
const MINT := Color("7fd8be")
const CREAM := Color("fff1d6")
const INK := Color("1d2b2a")
const START := Vector3(0, 0.75, 9)
const CAMERA_OFFSET := Vector3(0, 3.6, 8.0)
const LOOK_AHEAD := Vector3(0, 1.2, -4.0)
const PlayerScript = preload("res://scripts/player.gd")
# Each island is [top centre, top size on X and Z].
const ISLANDS := [
	[Vector3(0, 0, 8), Vector2(10, 9)],
	[Vector3(-4, 0.5, 0), Vector2(5, 5)],
	[Vector3(3.5, 1.1, -3.5), Vector2(5, 5)],
	[Vector3(3, 1.1, -17), Vector2(6, 5)],
	[Vector3(-3, 1.9, -17.5), Vector2(4, 4)],
	[Vector3(0, 1.9, -31), Vector2(12, 8)],
	[Vector3(4.5, 2.7, -29.5), Vector2(2.2, 2.2)],
]
const FAR_ISLANDS := [
	[Vector3(-18, -2, -22), Vector2(8, 6)], [Vector3(22, 3, -44), Vector2(10, 8)],
	[Vector3(-16, 5, -58), Vector2(7, 7)], [Vector3(16, -4, -6), Vector2(6, 5)],
	[Vector3(-26, 1, 2), Vector2(6, 6)],
]
const TREES := [Vector3(-3.5, 0, 10.5), Vector3(3.8, 0, 5), Vector3(5, 1.1, -15.5), Vector3(-5, 1.9, -33.5), Vector3(5, 1.9, -33.5)]
const ROCKS := [Vector3(2.5, 0, 11), Vector3(-5.2, 0.5, 1.5), Vector3(0.8, 1.1, -15.2), Vector3(-2, 1.9, -28)]

var player: PlayerScript
var camera: Camera3D
var status: Label
var materials: Dictionary = {}


func _ready() -> void:
	configure_input()
	build_environment()
	build_world()
	build_player()
	build_camera()
	build_hud()
	update_hud()


func configure_input() -> void:
	if InputMap.has_action("move_left"):
		return # Restarting keeps the InputMap, so only add bindings once.
	bind("move_left", [KEY_A, KEY_LEFT], [JOY_BUTTON_DPAD_LEFT], JOY_AXIS_LEFT_X, -1.0)
	bind("move_right", [KEY_D, KEY_RIGHT], [JOY_BUTTON_DPAD_RIGHT], JOY_AXIS_LEFT_X, 1.0)
	bind("move_up", [KEY_W, KEY_UP], [JOY_BUTTON_DPAD_UP], JOY_AXIS_LEFT_Y, -1.0)
	bind("move_down", [KEY_S, KEY_DOWN], [JOY_BUTTON_DPAD_DOWN], JOY_AXIS_LEFT_Y, 1.0)
	bind("jump", [KEY_SPACE], [JOY_BUTTON_A])
	bind("restart", [KEY_R], [JOY_BUTTON_BACK])


func bind(action: StringName, keys: Array[Key], buttons: Array[JoyButton], axis: JoyAxis = JOY_AXIS_INVALID, direction: float = 0.0) -> void:
	InputMap.add_action(action, 0.25)
	for key in keys:
		var key_event := InputEventKey.new()
		key_event.physical_keycode = key
		InputMap.action_add_event(action, key_event)
	for button in buttons:
		var button_event := InputEventJoypadButton.new()
		button_event.button_index = button
		InputMap.action_add_event(action, button_event)
	if axis != JOY_AXIS_INVALID:
		var motion := InputEventJoypadMotion.new()
		motion.axis = axis
		motion.axis_value = direction
		InputMap.action_add_event(action, motion)


func build_environment() -> void:
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = SKY_TOP
	sky_material.sky_horizon_color = HORIZON
	sky_material.ground_horizon_color = HORIZON
	sky_material.ground_bottom_color = Color("8fc0e0")
	var sky := Sky.new()
	sky.sky_material = sky_material
	var settings := Environment.new()
	settings.background_mode = Environment.BG_SKY
	settings.sky = sky
	settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	settings.ambient_light_color = Color("8fa3c0")
	settings.ambient_light_energy = 0.6
	settings.tonemap_exposure = 0.85
	settings.tonemap_mode = Environment.TONE_MAPPER_ACES
	settings.adjustment_enabled = true
	settings.adjustment_saturation = 1.2
	settings.fog_enabled = true
	settings.fog_light_color = HORIZON
	settings.fog_density = 0.0045
	settings.fog_sky_affect = 0.25
	settings.glow_enabled = true
	settings.glow_intensity = 0.45
	settings.glow_bloom = 0.05
	var world := WorldEnvironment.new()
	world.environment = settings
	add_child(world)
	var sun := DirectionalLight3D.new()
	sun.name = "Sun"
	sun.rotation_degrees = Vector3(-32, -40, 0)
	sun.light_color = Color("ffe2b8")
	sun.light_energy = 1.0
	sun.shadow_enabled = true
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	sun.directional_shadow_max_distance = 45.0
	add_child(sun)


func material(color: Color) -> StandardMaterial3D:
	if not materials.has(color):
		var surface := StandardMaterial3D.new()
		surface.albedo_color = color
		surface.roughness = 0.9
		materials[color] = surface
	return materials[color]


func make_box(size: Vector3, color: Color, offset: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var box := BoxMesh.new()
	box.size = size
	var mesh := MeshInstance3D.new()
	mesh.mesh = box
	mesh.position = offset
	mesh.material_override = material(color)
	return mesh


func make_collider(size: Vector3, offset: Vector3) -> CollisionShape3D:
	var shape := BoxShape3D.new()
	shape.size = size
	var collider := CollisionShape3D.new()
	collider.shape = shape
	collider.position = offset
	return collider


func build_world() -> void:
	for island in ISLANDS:
		make_island(island[0], island[1], true)
	for island in FAR_ISLANDS:
		make_island(island[0], island[1], false)
	for point in TREES:
		make_tree(point)
	for point in ROCKS:
		make_rock(point)
	for i in 16:
		make_cloud(Vector3(-34 + (i * 23) % 68, -6 - (i % 3) * 1.5, 14 - (i * 17) % 70))


func make_island(top: Vector3, size: Vector2, solid: bool) -> void:
	var island: Node3D = StaticBody3D.new() if solid else Node3D.new()
	island.position = top
	island.add_child(make_box(Vector3(size.x, 0.35, size.y), GRASS, Vector3(0, -0.175, 0)))
	island.add_child(make_box(Vector3(size.x - 0.4, 1.6, size.y - 0.4), EARTH, Vector3(0, -1.15, 0)))
	island.add_child(make_box(Vector3(size.x * 0.55, 1.4, size.y * 0.55), EARTH.darkened(0.2), Vector3(0, -2.6, 0)))
	if solid:
		island.add_child(make_collider(Vector3(size.x, 1.0, size.y), Vector3(0, -0.5, 0)))
	add_child(island)


func make_tree(base: Vector3) -> void:
	var trunk := CylinderMesh.new()
	trunk.top_radius = 0.12
	trunk.bottom_radius = 0.2
	trunk.height = 1.2
	var tree := MeshInstance3D.new()
	tree.mesh = trunk
	tree.material_override = material(BARK)
	tree.position = base + Vector3(0, 0.6, 0)
	add_child(tree)
	for layer in 2:
		var crown := SphereMesh.new()
		crown.radius = 0.9 - layer * 0.25
		crown.height = 1.5 - layer * 0.4
		crown.radial_segments = 7
		crown.rings = 4
		var leaves := MeshInstance3D.new()
		leaves.mesh = crown
		leaves.material_override = material(LEAF.lightened(layer * 0.12))
		leaves.position = Vector3(0, 0.9 + layer * 0.8, 0)
		tree.add_child(leaves)


func make_rock(base: Vector3) -> void:
	var stone := SphereMesh.new()
	stone.radial_segments = 6
	stone.rings = 3
	var rock := MeshInstance3D.new()
	rock.mesh = stone
	rock.material_override = material(Color("a39d92"))
	rock.position = base + Vector3(0, 0.2, 0)
	rock.scale = Vector3(1.1, 0.6, 0.9)
	add_child(rock)


func make_cloud(center: Vector3) -> void:
	var puff := SphereMesh.new()
	var cloud := MeshInstance3D.new()
	cloud.mesh = puff
	cloud.material_override = material(Color.WHITE)
	cloud.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	cloud.position = center
	cloud.scale = Vector3(9, 1.8, 5)
	add_child(cloud)


func build_player() -> void:
	player = PlayerScript.new()
	player.name = "Player"
	player.position = START
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.4
	capsule.height = 1.4
	var collider := CollisionShape3D.new()
	collider.shape = capsule
	player.add_child(collider)
	add_child(player)
	player.enabled = false


func build_camera() -> void:
	camera = Camera3D.new()
	camera.name = "FollowCamera"
	camera.fov = 62.0
	add_child(camera)
	camera.current = true
	player.camera = camera
	snap_camera()


func snap_camera() -> void:
	camera.global_position = player.global_position + CAMERA_OFFSET
	camera.look_at(player.global_position + LOOK_AHEAD)


func build_hud() -> void:
	var layer := CanvasLayer.new()
	layer.name = "HUD"
	add_child(layer)
	status = make_label(layer, 22)
	status.position = Vector2(24, 16)


func make_label(parent: Node, font_size: int) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", CREAM)
	label.add_theme_color_override("font_outline_color", INK)
	label.add_theme_constant_override("outline_size", 7)
	parent.add_child(label)
	return label


func update_hud() -> void:
	status.text = "FLOATING ISLES  ·  sky, fog, sun, islands and materials"


func restart_game() -> void:
	get_tree().reload_current_scene()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("restart"):
		restart_game()
