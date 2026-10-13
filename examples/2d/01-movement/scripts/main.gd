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

var player: PlayerScript
var hint: Label


func _ready() -> void:
	configure_input()
	build_player()
	hint = make_label(Vector2(28, 16), 22)
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


func update_hud() -> void:
	hint.text = "MOVE  WASD / Arrows / Stick      DASH  Shift / Space / B      R  Restart"


func restart_game() -> void:
	get_tree().reload_current_scene()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("restart"):
		restart_game()


func _draw() -> void:
	var field := StyleBoxFlat.new()
	field.bg_color = FIELD
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
