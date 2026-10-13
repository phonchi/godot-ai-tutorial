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
#@ 2+
const FALL_LIMIT := -10.0
#@ end
#@ 3+
const OrbScript = preload("res://scripts/orb.gd")
const PlatformScript = preload("res://scripts/moving_platform.gd")
const TARGET: int = 5
const ORB_POINTS := [Vector3(-4, 1.5, 0), Vector3(4.5, 2.1, -4.5), Vector3(4.5, 2.1, -18), Vector3(-3, 2.9, -18), Vector3(4.5, 3.7, -29.5)]
const GATE_POINT := Vector3(0, 1.9, -34)
#@ end
#@ 4
const PatrolScript = preload("res://scripts/patrol_enemy.gd")
const FLAG_POINTS := [Vector3(3, 1.1, -15.2), Vector3(-4.5, 1.9, -27.6)]
const PATROL_ROUTES := [
	[Vector3(1.0, 1.1, -18.8), Vector3(5.2, 1.1, -18.8), Vector3(5.2, 1.1, -16.5), Vector3(1.0, 1.1, -16.5)],
	[Vector3(-4.5, 1.9, -29), Vector3(3, 1.9, -29), Vector3(3, 1.9, -32.5), Vector3(-4.5, 1.9, -32.5)],
]
const SAVE_PATH := "user://best.cfg"
const SOUND_NAMES: Array[String] = ["collect", "jump", "gate", "checkpoint", "respawn", "win"]
enum State { TITLE, PLAYING, WON }
static var skip_title: bool = false
#@ end

var player: PlayerScript
var camera: Camera3D
var status: Label
var materials: Dictionary = {}
#@ 2+
var respawn_point := START
#@ end
#@ 3+
var score: int = 0
var orbs: Array[Area3D] = []
var platforms: Array[AnimatableBody3D] = []
var lamps: Array[MeshInstance3D] = []
var gate: AnimatableBody3D
var exit_area: Area3D
var gate_open: bool = false
#@ end
#@ 3
var won: bool = false
#@ end
#@ 4
var state: State = State.TITLE
var falls: int = 0
var respawn_grace: float = 0.0
var elapsed: float = 0.0
var best_time: float = -1.0
var patrols: Array[PathFollow3D] = []
var flags: Array[Area3D] = []
var sounds: Dictionary = {}
var clock: Label
var panel: PanelContainer
var message: Label
#@ end


func _ready() -> void:
	configure_input()
	build_environment()
	build_world()
	build_player()
	build_camera()
	build_hud()
#@ 3+
	build_platforms()
	for point in ORB_POINTS:
		spawn_orb(point)
	build_gate()
#@ end
#@ 4
	build_checkpoints()
	build_patrols()
	build_sounds()
	best_time = load_best_time()
	if skip_title:
		start_game()
	else:
		show_title()
#@ end
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
#@ 4
	bind("start", [KEY_ENTER], [JOY_BUTTON_START])
#@ end


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
#@ 1
	player.enabled = false
#@ end
#@ 4
	player.jumped.connect(func() -> void: play_sound("jump"))
#@ end


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
#@ 2+


func update_camera(delta: float) -> void:
	var weight := 1.0 - exp(-8.0 * delta)
	var target := player.global_position + CAMERA_OFFSET
	camera.global_position = camera.global_position.lerp(target, weight)
	camera.look_at(player.global_position + LOOK_AHEAD)


func _physics_process(delta: float) -> void:
	update_camera(delta)
	if player.global_position.y < FALL_LIMIT:
		respawn_player()
#@ 4
	respawn_grace = maxf(0.0, respawn_grace - delta)
	if respawn_grace > 0.0:
		return # Just respawned: ignore thorns for a moment, including stale overlaps from the teleport.
	for patrol in patrols:
		if patrol.hitbox.overlaps_body(player):
			respawn_player()
			break
#@ end


func respawn_player() -> void:
	player.global_position = respawn_point
	player.velocity = Vector3.ZERO
	snap_camera()
#@ 3+
	spawn_burst(respawn_point, CREAM)
#@ end
#@ 4
	falls += 1
	respawn_grace = 0.5
	play_sound("respawn")
	update_hud()
#@ end
#@ end


func build_hud() -> void:
	var layer := CanvasLayer.new()
	layer.name = "HUD"
	add_child(layer)
	status = make_label(layer, 22)
	status.position = Vector2(24, 16)
#@ 4
	clock = make_label(layer, 26)
	clock.position = Vector2(624, 14)
	clock.size = Vector2(312, 40)
	clock.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	panel = PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(INK, 0.85)
	style.border_color = MINT
	style.set_border_width_all(3)
	style.set_corner_radius_all(20)
	style.set_content_margin_all(28)
	panel.add_theme_stylebox_override("panel", style)
	panel.position = Vector2(170, 180)
	panel.custom_minimum_size = Vector2(620, 0)
	layer.add_child(panel)
	message = make_label(panel, 22)
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.visible = false
#@ end


func make_label(parent: Node, font_size: int) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", CREAM)
	label.add_theme_color_override("font_outline_color", INK)
	label.add_theme_constant_override("outline_size", 7)
	parent.add_child(label)
	return label
#@ 1


func update_hud() -> void:
	status.text = "FLOATING ISLES  ·  sky, fog, sun, islands and materials"
#@ end
#@ 2


func update_hud() -> void:
	status.text = "MOVE  WASD / Arrows / Stick      JUMP  Space / A      R  Restart"
#@ end
#@ 3


func update_hud() -> void:
	if won:
		status.text = "YOU WIN!      R  Restart"
	else:
		status.text = "ORBS  %d / %d      GATE  %s      JUMP  Space / A      R  Restart" % [score, TARGET, "OPEN" if gate_open else "LOCKED"]
#@ end
#@ 4


func update_hud() -> void:
	status.text = "ORBS  %d / %d      GATE  %s      FALLS  %d" % [score, TARGET, "OPEN" if gate_open else "LOCKED", falls]
	clock.text = format_time(elapsed)
	if best_time >= 0.0:
		clock.text += "\nBEST " + format_time(best_time)
#@ end
#@ 3+


func build_platforms() -> void:
	make_platform(Vector3(3.5, 1.1, -8.5), Vector3(0, 0, -4))
	make_platform(Vector3(-3, 1.9, -21.5), Vector3(0, 0, -4))


func make_platform(top: Vector3, travel: Vector3) -> void:
	var platform: AnimatableBody3D = PlatformScript.new()
	platform.position = top
	platform.travel = travel
	platform.add_child(make_box(Vector3(3, 0.4, 3), STONE, Vector3(0, -0.2, 0)))
	platform.add_child(make_box(Vector3(3.1, 0.1, 3.1), MINT, Vector3(0, -0.45, 0)))
	platform.add_child(make_collider(Vector3(3, 0.4, 3), Vector3(0, -0.2, 0)))
	platforms.append(platform)
	add_child(platform)


func spawn_orb(point: Vector3) -> void:
	var orb: Area3D = OrbScript.new()
	orb.position = point
	orb.collision_layer = 0
	orb.collision_mask = 1
	orb.body_entered.connect(func(body: Node3D) -> void:
		if body == player:
			collect_item(orb))
	orbs.append(orb)
	add_child(orb)


func spawn_burst(point: Vector3, color: Color) -> void:
	var bit := BoxMesh.new()
	bit.size = Vector3.ONE * 0.12
	var bit_material := StandardMaterial3D.new()
	bit_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bit_material.vertex_color_use_as_albedo = true
	bit_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	bit.material = bit_material
	var burst := CPUParticles3D.new()
	burst.mesh = bit
	burst.position = point
	burst.one_shot = true
	burst.explosiveness = 1.0
	burst.amount = 20
	burst.lifetime = 0.6
	burst.spread = 180.0
	burst.initial_velocity_min = 2.0
	burst.initial_velocity_max = 5.0
	burst.gravity = Vector3(0, -6, 0)
	var fade := Gradient.new()
	fade.set_color(0, color)
	fade.set_color(1, Color(color, 0.0))
	burst.color_ramp = fade
	burst.finished.connect(burst.queue_free)
	add_child(burst)
	burst.emitting = true


func build_gate() -> void:
	var arch := Node3D.new()
	arch.name = "Gate"
	arch.position = GATE_POINT
	add_child(arch)
	var stones := StaticBody3D.new()
	arch.add_child(stones)
	for x in [-1.75, 1.75]:
		stones.add_child(make_box(Vector3(0.7, 3.4, 0.7), STONE, Vector3(x, 1.7, 0)))
		stones.add_child(make_collider(Vector3(0.7, 3.4, 0.7), Vector3(x, 1.7, 0)))
	stones.add_child(make_box(Vector3(4.2, 0.6, 0.8), STONE, Vector3(0, 3.7, 0)))
	for i in TARGET:
		var lamp := make_box(Vector3(0.3, 0.3, 0.1), INK, Vector3(-1.2 + i * 0.6, 3.7, 0.42))
		lamps.append(lamp)
		stones.add_child(lamp)
	gate = AnimatableBody3D.new()
	gate.position = Vector3(0, 1.5, 0)
	var glow := StandardMaterial3D.new()
	glow.albedo_color = Color("2f9e8f")
	glow.emission_enabled = true
	glow.emission = Color("2fbfa8")
	glow.emission_energy_multiplier = 0.8
	var door := make_box(Vector3(2.8, 3.0, 0.25), Color.WHITE)
	door.material_override = glow
	gate.add_child(door)
	gate.add_child(make_collider(Vector3(2.8, 3.0, 0.25), Vector3.ZERO))
	arch.add_child(gate)
	exit_area = Area3D.new()
	exit_area.collision_layer = 0
	exit_area.collision_mask = 1
	exit_area.position = Vector3(0, 1.5, -0.9)
	exit_area.add_child(make_collider(Vector3(2.8, 3.0, 1.0), Vector3.ZERO))
	exit_area.body_entered.connect(func(body: Node3D) -> void:
		if body == player:
			try_exit())
	arch.add_child(exit_area)


func collect_item(orb: Area3D) -> void:
	if not is_playing() or not orbs.has(orb):
		return
	orbs.erase(orb)
	orb.pop()
	spawn_burst(orb.global_position, OrbScript.GOLD)
	lamps[score].material_override = OrbScript.glow_material()
	score += 1
#@ 4
	play_sound("collect")
#@ end
	if score == TARGET:
		open_gate()
	update_hud()


func open_gate() -> void:
	gate_open = true
#@ 4
	play_sound("gate")
#@ end
	var tween := create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	tween.tween_property(gate, "position:y", -1.7, 1.2).set_trans(Tween.TRANS_SINE)


func try_exit() -> bool:
	if score < TARGET:
		return false
	end_game()
	return true
#@ end
#@ 3


func is_playing() -> bool:
	return not won


func end_game() -> void:
	won = true
	player.enabled = false
	update_hud()
#@ end
#@ 4


func is_playing() -> bool:
	return state == State.PLAYING


func show_title() -> void:
	state = State.TITLE
	player.enabled = false
	show_message("FLOATING ISLES\n\nCollect 5 orbs to open the gate.\nTouch flags to save a respawn point. Avoid the rolling thorns.\nMove: WASD / Arrows / Stick     Jump: Space / A\n\nPress Enter or Start")


func start_game() -> void:
	state = State.PLAYING
	player.enabled = true
	panel.visible = false


func end_game() -> void:
	state = State.WON
	player.enabled = false
	play_sound("win")
	if best_time < 0.0 or elapsed < best_time:
		best_time = elapsed
		save_best_time(best_time)
	show_message("YOU WIN!\n\nTime %s      Best %s      Falls %d\n\nPress R or Back to play again" % [format_time(elapsed), format_time(best_time), falls])
	update_hud()


func show_message(text: String) -> void:
	message.text = text
	panel.visible = true
	panel.reset_size()
	panel.position.y = 300 - panel.size.y / 2.0


static func format_time(seconds: float) -> String:
	return "%d:%05.2f" % [floori(seconds / 60.0), fmod(seconds, 60.0)]


func _process(delta: float) -> void:
	if is_playing():
		elapsed += delta
		clock.text = format_time(elapsed)


func build_checkpoints() -> void:
	for point in FLAG_POINTS:
		var flag := Area3D.new()
		flag.position = point
		flag.collision_layer = 0
		flag.collision_mask = 1
		flag.add_child(make_box(Vector3(0.12, 2.2, 0.12), STONE, Vector3(0, 1.1, 0)))
		var cloth := make_box(Vector3(0.9, 0.55, 0.06), Color("8a8478"), Vector3(0.5, 1.85, 0))
		cloth.name = "Cloth"
		flag.add_child(cloth)
		flag.add_child(make_collider(Vector3(1.4, 2.2, 1.4), Vector3(0, 1.1, 0)))
		flag.body_entered.connect(func(body: Node3D) -> void:
			if body == player:
				activate_checkpoint(flag))
		flags.append(flag)
		add_child(flag)


func activate_checkpoint(flag: Area3D) -> void:
	var point := flag.position + Vector3(0, 0.75, 0)
	if respawn_point.is_equal_approx(point):
		return
	respawn_point = point
	var cloth: MeshInstance3D = flag.get_node("Cloth")
	cloth.material_override = material(MINT)
	spawn_burst(point + Vector3(0, 1.2, 0), MINT)
	play_sound("checkpoint")


func build_patrols() -> void:
	for route in PATROL_ROUTES:
		var curve := Curve3D.new()
		for point in route:
			curve.add_point(point)
		curve.add_point(route[0]) # Close the loop so the enemy does not jump back.
		var path := Path3D.new()
		path.curve = curve
		add_child(path)
		var patrol: PathFollow3D = PatrolScript.new()
		path.add_child(patrol)
		patrols.append(patrol)


func build_sounds() -> void:
	for sound_name in SOUND_NAMES:
		var sound_player := AudioStreamPlayer.new()
		sound_player.stream = load("res://audio/%s.wav" % sound_name)
		sound_player.volume_db = -9.0
		add_child(sound_player)
		sounds[sound_name] = sound_player


func play_sound(sound_name: String) -> void:
	if DisplayServer.get_name() != "headless":
		sounds[sound_name].play()


func load_best_time() -> float:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return -1.0
	return config.get_value("floating_isles", "best_time", -1.0)


func save_best_time(time: float) -> void:
	var config := ConfigFile.new()
	config.set_value("floating_isles", "best_time", time)
	var error := config.save(SAVE_PATH)
	if error != OK:
		push_warning("Best time was not saved: " + error_string(error))
#@ end


func restart_game() -> void:
#@ 4
	skip_title = true
#@ end
	get_tree().reload_current_scene()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("restart"):
		restart_game()
#@ 4
	elif state == State.TITLE and event.is_action_pressed("start"):
		start_game()
#@ end
