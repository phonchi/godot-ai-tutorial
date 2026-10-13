extends Node2D
## Star Garden (2D). Every node is created in code from _ready().
## While the game runs, open the Scene dock's Remote tab to see the real scene tree.

const ARENA := Rect2(24, 72, 912, 504)
const PLAY_AREA := Rect2(48, 96, 864, 456)
const START := Vector2(480, 324)
const FIELD := Color("163f3b")
const LINE := Color("2a5d57")
const CREAM := Color("fff1d6")
const INK := Color("0b2422")
const FLOWERS: Array[Color] = [Color("f4b6c2"), Color("fff1d6"), Color("b9a7f0")]
const PlayerScript = preload("res://scripts/player.gd")
#@ 2+
const StarScript = preload("res://scripts/star.gd")
const TARGET: int = 10
const STAR_POINTS: Array[Vector2] = [
	Vector2(160, 160), Vector2(800, 160), Vector2(480, 490),
	Vector2(250, 430), Vector2(710, 430), Vector2(480, 150),
	Vector2(120, 330), Vector2(840, 330), Vector2(320, 200), Vector2(640, 500),
]
#@ end
#@ 3+
const EnemyScript = preload("res://scripts/enemy.gd")
const MAX_LIVES: int = 3
#@ end
#@ 3
const MAX_ENEMIES: int = 5
#@ end
#@ 4+
const HudScript = preload("res://scripts/hud.gd")
enum State { TITLE, PLAYING, WON, LOST }
const WAVES: Array[Dictionary] = [
	{"stars": 3, "chasers": 1, "bouncers": 1, "chaser_speed": 120.0},
	{"stars": 3, "chasers": 2, "bouncers": 1, "chaser_speed": 145.0},
	{"stars": 4, "chasers": 3, "bouncers": 2, "chaser_speed": 170.0},
]
static var skip_title: bool = false
#@ end
#@ 5+
const SAVE_PATH := "user://best.cfg"
const SOUND_NAMES: Array[String] = ["collect", "dash", "hit", "wave", "win", "lose"]
#@ end

var player: PlayerScript
#@ 1-3
var hint: Label
#@ end
#@ 2+
var score: int = 0
var stars: Array[Area2D] = []
var dot_texture: GradientTexture2D
#@ end
#@ 2-3
var finished: bool = false
var won: bool = false
#@ end
#@ 3+
var lives: int = MAX_LIVES
var enemies: Array[Area2D] = []
#@ end
#@ 3
var spawn_timer: Timer
#@ end
#@ 4+
var state: State = State.TITLE
var wave_index: int = 0
var wave_collected: int = 0
var elapsed: float = 0.0
var hud: HudScript
#@ end
#@ 5+
var camera: Camera2D
var shake: float = 0.0
var best_time: float = -1.0
var sounds: Dictionary = {}
var rng := RandomNumberGenerator.new()
#@ end


func _ready() -> void:
	configure_input()
#@ 2+
	dot_texture = soft_dot() # Build the particle texture once, before any burst needs it.
#@ end
#@ 5+
	build_background()
	build_camera()
	build_sounds()
	best_time = load_best_time()
#@ end
	build_player()
#@ 1-3
	hint = make_label(Vector2(28, 16), 22)
#@ end
#@ 2-3
	for point in STAR_POINTS:
		spawn_star(point)
#@ end
#@ 3
	spawn_enemy(EnemyScript.Kind.CHASER, 120.0)
	spawn_enemy(EnemyScript.Kind.BOUNCER, 150.0)
	spawn_enemy(EnemyScript.Kind.BOUNCER, 150.0)
	spawn_timer = Timer.new()
	spawn_timer.name = "SpawnTimer"
	spawn_timer.wait_time = 6.0
	spawn_timer.timeout.connect(spawn_hazard)
	add_child(spawn_timer)
	spawn_timer.start()
#@ end
#@ 4+
	build_hud()
	if skip_title:
		start_game()
	else:
		show_title()
#@ end
	update_hud()
	queue_redraw()


func configure_input() -> void:
	if InputMap.has_action("move_left"):
		return # Restarting keeps the InputMap, so only add bindings once.
	bind("move_left", [KEY_A, KEY_LEFT], [JOY_BUTTON_DPAD_LEFT], JOY_AXIS_LEFT_X, -1.0)
	bind("move_right", [KEY_D, KEY_RIGHT], [JOY_BUTTON_DPAD_RIGHT], JOY_AXIS_LEFT_X, 1.0)
	bind("move_up", [KEY_W, KEY_UP], [JOY_BUTTON_DPAD_UP], JOY_AXIS_LEFT_Y, -1.0)
	bind("move_down", [KEY_S, KEY_DOWN], [JOY_BUTTON_DPAD_DOWN], JOY_AXIS_LEFT_Y, 1.0)
	bind("dash", [KEY_SHIFT, KEY_SPACE], [JOY_BUTTON_B, JOY_BUTTON_X])
	bind("restart", [KEY_R], [JOY_BUTTON_BACK])
#@ 4+
	bind("start", [KEY_ENTER, KEY_SPACE], [JOY_BUTTON_A, JOY_BUTTON_START])
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


func build_player() -> void:
	player = PlayerScript.new()
	player.name = "Player"
	player.motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	player.position = START
	player.arena = PLAY_AREA
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 20.0
	shape.shape = circle
	player.add_child(shape)
	add_child(player)
#@ 5+
	player.dashed.connect(on_player_dashed)
#@ end
#@ 1-3


func make_label(text_position: Vector2, font_size: int) -> Label:
	var layer := CanvasLayer.new()
	layer.name = "HUD"
	add_child(layer)
	var label := Label.new()
	label.position = text_position
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", CREAM)
	label.add_theme_color_override("font_outline_color", INK)
	label.add_theme_constant_override("outline_size", 6)
	layer.add_child(label)
	return label
#@ end
#@ 1


func update_hud() -> void:
	hint.text = "MOVE  WASD / Arrows / Stick      DASH  Shift / Space / B      R  Restart"
#@ end
#@ 2


func update_hud() -> void:
	if finished:
		hint.text = "YOU WIN!      R  Restart"
	else:
		hint.text = "STARS  %d / %d      DASH  Shift / Space      R  Restart" % [score, TARGET]
#@ end
#@ 3


func update_hud() -> void:
	if finished:
		hint.text = ("YOU WIN!" if won else "GAME OVER") + "      R  Restart"
	else:
		hint.text = "STARS  %d / %d      LIVES  %d      DASH  Shift / Space      R  Restart" % [score, TARGET, lives]
#@ end
#@ 2+


func spawn_star(point: Vector2) -> void:
	var star: Area2D = StarScript.new()
	star.position = point
	star.collision_layer = 0
	star.collision_mask = 1
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 18.0
	shape.shape = circle
	star.add_child(shape)
	star.body_entered.connect(func(body: Node2D) -> void:
		if body == player:
			collect_item(star))
	stars.append(star)
	add_child(star)


func soft_dot() -> GradientTexture2D:
	var dot := GradientTexture2D.new()
	dot.width = 16
	dot.height = 16
	dot.fill = GradientTexture2D.FILL_RADIAL
	dot.fill_from = Vector2(0.5, 0.5)
	dot.fill_to = Vector2(1.0, 0.5)
	dot.gradient = Gradient.new()
	dot.gradient.set_color(0, Color.WHITE)
	dot.gradient.set_color(1, Color(1, 1, 1, 0))
	return dot


func spawn_burst(point: Vector2, color: Color, amount: int = 18) -> void:
	var burst := CPUParticles2D.new()
	burst.texture = dot_texture
	burst.position = point
	burst.one_shot = true
	burst.explosiveness = 1.0
	burst.amount = amount
	burst.lifetime = 0.45
	burst.spread = 180.0
	burst.gravity = Vector2.ZERO
	burst.initial_velocity_min = 90.0
	burst.initial_velocity_max = 240.0
	burst.damping_min = 200.0
	burst.damping_max = 300.0
	burst.scale_amount_min = 0.5
	burst.scale_amount_max = 1.1
	burst.modulate = color # Tint the whole node; every particle stays white.
	var shrink := Curve.new()
	shrink.add_point(Vector2(0.0, 1.0))
	shrink.add_point(Vector2(1.0, 0.0))
	burst.scale_amount_curve = shrink
	burst.finished.connect(burst.queue_free)
	add_child(burst)
	burst.emitting = true
#@ end
#@ 2-3


func is_playing() -> bool:
	return not finished


func collect_item(star: Area2D) -> void:
	if not is_playing() or not stars.has(star):
		return
	stars.erase(star)
	star.pop()
	spawn_burst(star.position, StarScript.GOLD)
	score += 1
	if score >= TARGET:
		end_game(true)
	update_hud()


func end_game(won_game: bool) -> void:
	finished = true
	won = won_game
	player.enabled = false
#@ 3
	spawn_timer.stop()
	for enemy in enemies:
		enemy.set_physics_process(false)
#@ end
#@ end
#@ 3+


func spawn_enemy(kind: EnemyScript.Kind, speed: float) -> void:
	var enemy: Area2D = EnemyScript.new()
	enemy.kind = kind
	enemy.speed = speed
	enemy.target = player
	enemy.arena = PLAY_AREA
	enemy.position = far_point()
	enemy.drift = Vector2.from_angle(0.7 + enemies.size() * 2.1) * speed
	enemy.collision_layer = 0
	enemy.collision_mask = 1
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 16.0
	shape.shape = circle
	enemy.add_child(shape)
	enemies.append(enemy)
	add_child(enemy)


func far_point() -> Vector2:
	var candidates: Array[Vector2] = [
		PLAY_AREA.position, Vector2(PLAY_AREA.end.x, PLAY_AREA.position.y),
		PLAY_AREA.end, Vector2(PLAY_AREA.position.x, PLAY_AREA.end.y),
		Vector2(480, PLAY_AREA.position.y), Vector2(480, PLAY_AREA.end.y),
	]
	var best := candidates[0]
	var best_score := -INF
	for point in candidates:
		var crowd := 0.0
		for enemy in enemies:
			crowd += 120.0 if enemy.position.distance_to(point) < 60.0 else 0.0
		var point_score := point.distance_to(player.position) - crowd
		if point_score > best_score:
			best = point
			best_score = point_score
	return best


func _physics_process(_delta: float) -> void:
	# A signal fires only on entry, so ongoing contact is checked every physics frame.
	for enemy in enemies:
		if enemy.is_active() and enemy.overlaps_body(player):
			damage_player()
			return


func damage_player() -> void:
	if not is_playing() or player.invulnerable > 0.0:
		return
	lives -= 1
	player.invulnerable = 1.0
#@ 5+
	shake = 0.12
	hud.flash = 0.1
	play_sound("hit")
#@ end
	if lives <= 0:
		end_game(false)
	update_hud()
#@ end
#@ 3


func spawn_hazard() -> void:
	if finished or enemies.size() >= MAX_ENEMIES:
		spawn_timer.stop()
		return
	spawn_enemy(EnemyScript.Kind.CHASER, 120.0)
#@ end
#@ 4+


func build_hud() -> void:
	var layer := CanvasLayer.new()
	layer.name = "HUD"
	add_child(layer)
	hud = HudScript.new()
	hud.name = "Display"
	hud.max_lives = MAX_LIVES
	hud.stars_target = TARGET
	hud.wave_count = WAVES.size()
	layer.add_child(hud)


func is_playing() -> bool:
	return state == State.PLAYING


func show_title() -> void:
	state = State.TITLE
	player.enabled = false
	hud.show_message("STAR GARDEN", "Collect 10 stars over 3 waves and dodge the thorns.\nMove: WASD / Arrows / Stick     Dash: Shift / Space / B\n\nPress Enter or A to start")


func start_game() -> void:
	state = State.PLAYING
	player.enabled = true
	player.cooldown_left = 0.2
	hud.hide_message()
	start_wave(0)


func start_wave(index: int) -> void:
	wave_index = index
	wave_collected = 0
	clear_enemies()
	var wave: Dictionary = WAVES[index]
	var first := 0
	for i in index:
		first += int(WAVES[i]["stars"])
	for i in int(wave["stars"]):
		spawn_star(STAR_POINTS[first + i])
	for i in int(wave["chasers"]):
		spawn_enemy(EnemyScript.Kind.CHASER, wave["chaser_speed"])
	for i in int(wave["bouncers"]):
		spawn_enemy(EnemyScript.Kind.BOUNCER, 150.0)
	hud.show_banner("WAVE %d" % (index + 1))
#@ 5+
	play_sound("wave")
#@ end
	update_hud()


func collect_item(star: Area2D) -> void:
	if not is_playing() or not stars.has(star):
		return
	stars.erase(star)
	star.pop()
	spawn_burst(star.position, StarScript.GOLD)
#@ 5+
	play_sound("collect")
#@ end
	score += 1
	wave_collected += 1
	if wave_collected >= int(WAVES[wave_index]["stars"]):
		finish_wave()
	update_hud()


func finish_wave() -> void:
	if wave_index == WAVES.size() - 1:
		end_game(true)
		return
	clear_enemies()
	get_tree().create_timer(0.8).timeout.connect(next_wave)


func next_wave() -> void:
	if is_playing() and wave_index < WAVES.size() - 1:
		start_wave(wave_index + 1)


func clear_enemies() -> void:
	for enemy in enemies:
		enemy.queue_free()
	enemies.clear()


func end_game(won_game: bool) -> void:
	state = State.WON if won_game else State.LOST
	player.enabled = false
	for enemy in enemies:
		enemy.set_physics_process(false)
#@ 5+
	play_sound("win" if won_game else "lose")
	if won_game and (best_time < 0.0 or elapsed < best_time):
		best_time = elapsed
		save_best_time(best_time)
#@ end
	show_result(won_game)


func show_result(won_game: bool) -> void:
	var detail := "Time  " + HudScript.format_time(elapsed)
#@ 5+
	if best_time >= 0.0:
		detail += "      Best  " + HudScript.format_time(best_time)
#@ end
	hud.show_message("YOU WIN!" if won_game else "GAME OVER", detail + "\n\nPress R or Back to play again")


func update_hud() -> void:
	hud.lives = lives
	hud.stars = score
	hud.wave = wave_index + 1
	hud.time = elapsed
#@ 5+
	hud.best = best_time
#@ end
	hud.queue_redraw()


func _process(delta: float) -> void:
	if is_playing():
		elapsed += delta
		hud.time = elapsed
		hud.queue_redraw()
#@ 5+
	if shake > 0.0:
		shake = maxf(0.0, shake - delta)
		camera.offset = Vector2(rng.randf_range(-4.0, 4.0), rng.randf_range(-4.0, 4.0))
	else:
		camera.offset = Vector2.ZERO
#@ end
#@ end
#@ 5+


func build_background() -> void:
	var background := ColorRect.new()
	background.name = "Background"
	background.size = Vector2(960, 600)
	background.z_index = -1
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shader_material := ShaderMaterial.new()
	shader_material.shader = preload("res://shaders/background.gdshader")
	background.material = shader_material
	add_child(background)
	var fireflies := CPUParticles2D.new()
	fireflies.name = "Fireflies"
	fireflies.z_index = -1
	fireflies.position = Vector2(480, 330)
	fireflies.amount = 36
	fireflies.lifetime = 6.0
	fireflies.preprocess = 6.0
	fireflies.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	fireflies.emission_rect_extents = Vector2(440, 230)
	fireflies.direction = Vector2.UP
	fireflies.spread = 40.0
	fireflies.gravity = Vector2.ZERO
	fireflies.initial_velocity_min = 6.0
	fireflies.initial_velocity_max = 18.0
	fireflies.texture = dot_texture
	fireflies.scale_amount_min = 0.35
	fireflies.scale_amount_max = 0.8
	var additive := CanvasItemMaterial.new()
	additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	fireflies.material = additive
	var glow := Gradient.new()
	glow.set_color(0, Color(0.85, 1.0, 0.6, 0.0))
	glow.add_point(0.5, Color(0.85, 1.0, 0.6, 0.9))
	glow.set_color(glow.get_point_count() - 1, Color(0.85, 1.0, 0.6, 0.0))
	fireflies.color_ramp = glow
	add_child(fireflies)


func build_camera() -> void:
	camera = Camera2D.new()
	camera.name = "ShakeCamera"
	camera.position = Vector2(480, 300)
	add_child(camera)
	rng.seed = 7


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


func on_player_dashed() -> void:
	play_sound("dash")
	spawn_burst(player.position, PlayerScript.ACCENT_COLOR, 10)


func load_best_time() -> float:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return -1.0
	return config.get_value("star_garden", "best_time", -1.0)


func save_best_time(time: float) -> void:
	var config := ConfigFile.new()
	config.set_value("star_garden", "best_time", time)
	var error := config.save(SAVE_PATH)
	if error != OK:
		push_warning("Best time was not saved: " + error_string(error))
#@ end


func restart_game() -> void:
#@ 4+
	skip_title = true
#@ end
	get_tree().reload_current_scene()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("restart"):
		restart_game()
#@ 4+
	elif state == State.TITLE and event.is_action_pressed("start"):
		start_game()
#@ end


func _draw() -> void:
	var field := StyleBoxFlat.new()
	field.bg_color = FIELD
#@ 5+
	field.bg_color = Color(FIELD, 0.45)
#@ end
	field.border_color = LINE
	field.set_border_width_all(3)
	field.set_corner_radius_all(22)
	draw_style_box(field, ARENA)
	for x in range(72, 900, 48):
		for y in range(120, 560, 48):
			draw_circle(Vector2(x, y), 2.0, LINE)
	for i in 14:
		var tuft := Vector2(60 + (i * 137) % 840, 110 + (i * 89) % 440)
		draw_line(tuft, tuft + Vector2(-5, -12), LINE, 3.0)
		draw_line(tuft, tuft + Vector2(1, -15), LINE, 3.0)
		draw_line(tuft, tuft + Vector2(6, -11), LINE, 3.0)
	for i in 9:
		draw_flower(Vector2(90 + (i * 211) % 790, 130 + (i * 157) % 400), FLOWERS[i % FLOWERS.size()])
	for i in 24:
		var edge := float(i) / 24.0
		draw_bush(Vector2(24 + edge * 912, 580 + (i % 3) * 6), 26.0 + (i * 7) % 12)
		draw_bush(Vector2(24 + edge * 912, 70 - (i % 2) * 4), 14.0 + (i * 5) % 8)
	for i in 10:
		var edge := float(i) / 9.0
		draw_bush(Vector2(18 - (i % 2) * 6, 80 + edge * 500), 22.0 + (i * 3) % 10)
		draw_bush(Vector2(942 + (i % 2) * 6, 80 + edge * 500), 22.0 + (i * 3) % 10)


func draw_flower(center: Vector2, petal: Color) -> void:
	for i in 5:
		draw_circle(center + Vector2.from_angle(i * TAU / 5.0) * 5.0, 4.0, Color(petal, 0.75))
	draw_circle(center, 3.0, Color("f6c453"))


func draw_bush(center: Vector2, radius: float) -> void:
	draw_circle(center, radius, Color("0d2826"))
	draw_circle(center + Vector2(-radius * 0.3, -radius * 0.35), radius * 0.6, Color("143633"))
