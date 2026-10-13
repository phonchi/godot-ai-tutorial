extends CharacterBody2D
## The player: smooth top-down movement plus a short dash.

signal dashed

@export var speed: float = 270.0
@export var acceleration: float = 1800.0
@export var friction: float = 2300.0
@export var dash_speed: float = 800.0
@export var dash_time: float = 0.15
@export var dash_cooldown: float = 0.75

const RADIUS: float = 22.0
const BODY_COLOR := Color("fff1d6")
const ACCENT_COLOR := Color("7fd8be")
const INK := Color("0b2422")

var enabled: bool = true
var arena := Rect2(48, 96, 864, 456)
var facing := Vector2.RIGHT
var dash_left: float = 0.0
var cooldown_left: float = 0.0
var dash_direction := Vector2.ZERO
var invulnerable: float = 0.0
#@ 5+
var trail: Array[Vector2] = []
#@ end


func _physics_process(delta: float) -> void:
	invulnerable = maxf(0.0, invulnerable - delta)
	cooldown_left = maxf(0.0, cooldown_left - delta)
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if direction != Vector2.ZERO:
		facing = direction.normalized()
	if enabled and Input.is_action_just_pressed("dash"):
		try_dash()
	if not enabled:
		dash_left = 0.0
		velocity = Vector2.ZERO
	elif dash_left > 0.0:
		dash_left -= delta
		velocity = dash_direction * dash_speed
	else:
		apply_movement(direction, delta)
	move_and_slide()
	position = position.clamp(arena.position, arena.end)
#@ 5+
	update_trail()
#@ end
	queue_redraw()


func apply_movement(direction: Vector2, delta: float) -> void:
	velocity = velocity.limit_length(speed) # Leaving a dash drops straight back to walking speed.
	if direction == Vector2.ZERO:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
	else:
		velocity = velocity.move_toward(direction * speed, acceleration * delta)


func try_dash() -> bool:
	if dash_left > 0.0 or cooldown_left > 0.0:
		return false
	dash_direction = facing
	dash_left = dash_time
	cooldown_left = dash_cooldown
	invulnerable = maxf(invulnerable, dash_time)
	dashed.emit()
	return true


func is_dashing() -> bool:
	return dash_left > 0.0
#@ 5+


func update_trail() -> void:
	if is_dashing():
		trail.push_front(global_position)
	elif not trail.is_empty():
		trail.pop_back()
	if trail.size() > 6:
		trail.pop_back()
#@ end


func _draw() -> void:
#@ 5+
	for i in trail.size():
		var ghost := Color(ACCENT_COLOR, 0.32 - i * 0.05)
		draw_circle(trail[i] - global_position, RADIUS * (1.0 - i * 0.08), ghost)
#@ end
	draw_set_transform(Vector2(0, 16), 0.0, Vector2(1.0, 0.35))
	draw_circle(Vector2.ZERO, RADIUS, Color(0, 0, 0, 0.25))
	var stretch := 1.3 if is_dashing() else 1.0
	draw_set_transform(Vector2.ZERO, facing.angle(), Vector2(stretch, 1.0 / stretch))
	var body := BODY_COLOR
	if invulnerable > 0.0 and not is_dashing() and int(invulnerable * 12.0) % 2 == 0:
		body.a = 0.35
	draw_circle(Vector2.ZERO, RADIUS + 3.0, Color(INK, body.a))
	draw_circle(Vector2.ZERO, RADIUS, body)
	draw_arc(Vector2.ZERO, RADIUS - 5.0, PI * 0.6, PI * 1.4, 12, Color(ACCENT_COLOR, body.a), 5.0)
	for side in [-1.0, 1.0]:
		draw_circle(Vector2(8, side * 7), 5.5, Color(Color.WHITE, body.a))
		draw_circle(Vector2(10, side * 7), 3.0, Color(INK, body.a))
	draw_set_transform(Vector2.ZERO)
