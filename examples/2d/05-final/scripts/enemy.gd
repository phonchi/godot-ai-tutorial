extends Area2D
## A threat. Chasers steer toward the target; bouncers fly straight and reflect off the arena edge.

enum Kind { CHASER, BOUNCER }

const CHASER_COLOR := Color("e0673f")
const BOUNCER_COLOR := Color("e85d8a")
const INK := Color("0b2422")

var kind: Kind = Kind.CHASER
var speed: float = 120.0
var drift := Vector2.ZERO
var target: Node2D
var arena := Rect2(48, 96, 864, 456)
var warmup: float = 0.5
var elapsed: float = 0.0


func is_active() -> bool:
	return warmup <= 0.0


func _physics_process(delta: float) -> void:
	elapsed += delta
	if warmup > 0.0:
		warmup -= delta
	elif kind == Kind.CHASER:
		chase(delta)
	else:
		bounce(delta)
	queue_redraw()


func chase(delta: float) -> void:
	if is_instance_valid(target):
		position += position.direction_to(target.global_position) * speed * delta


func bounce(delta: float) -> void:
	position += drift * delta
	if position.x < arena.position.x or position.x > arena.end.x:
		drift.x = -drift.x
	if position.y < arena.position.y or position.y > arena.end.y:
		drift.y = -drift.y
	position = position.clamp(arena.position, arena.end)


func _draw() -> void:
	if not is_active():
		var pulse := 0.5 + 0.5 * sin(elapsed * 24.0)
		draw_arc(Vector2.ZERO, 26.0, 0.0, TAU, 32, Color(CHASER_COLOR, 0.35 + pulse * 0.5), 3.0)
		return
	draw_set_transform(Vector2(0, 16), 0.0, Vector2(1.0, 0.35))
	draw_circle(Vector2.ZERO, 18.0, Color(0, 0, 0, 0.25))
	draw_set_transform(Vector2.ZERO)
	if kind == Kind.CHASER:
		draw_chaser()
	else:
		draw_bouncer()


func draw_chaser() -> void:
	var spikes := PackedVector2Array()
	for i in 16:
		var radius := 21.0 if i % 2 == 0 else 15.0
		spikes.append(Vector2.from_angle(elapsed * 2.0 + i * TAU / 16.0) * radius)
	draw_colored_polygon(spikes, CHASER_COLOR)
	var look := Vector2.RIGHT
	if is_instance_valid(target):
		look = position.direction_to(target.global_position)
	for side in [-1.0, 1.0]:
		var eye: Vector2 = look * 4.0 + look.orthogonal() * side * 6.0
		draw_circle(eye, 4.0, Color.WHITE)
		draw_circle(eye + look * 1.5, 2.0, INK)
		draw_line(eye + Vector2(-5.0 * side, -8), eye + Vector2(4.0 * side, -5), INK, 2.0)


func draw_bouncer() -> void:
	draw_set_transform(Vector2.ZERO, elapsed * 3.0)
	var diamond := PackedVector2Array([Vector2(0, -22), Vector2(15, 0), Vector2(0, 22), Vector2(-15, 0)])
	draw_colored_polygon(diamond, BOUNCER_COLOR)
	draw_colored_polygon(PackedVector2Array([Vector2(0, -11), Vector2(7, 0), Vector2(0, 11), Vector2(-7, 0)]), Color("ffd2df"))
	draw_set_transform(Vector2.ZERO)
