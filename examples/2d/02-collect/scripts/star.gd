extends Area2D
## A collectible star. Main listens to body_entered; the star only animates itself.

const GOLD := Color("f6c453")
const LIGHT := Color("fff0b3")
const SHADOW := Color(0, 0, 0, 0.22)

var elapsed: float = 0.0
var taken: bool = false


func _process(delta: float) -> void:
	elapsed += delta
	if not taken:
		rotation = sin(elapsed * 2.0) * 0.15
	queue_redraw()


func pop() -> void:
	taken = true
	set_deferred("monitoring", false)
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(1.8, 1.8), 0.18)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.18)
	tween.tween_callback(queue_free)


func star_points(outer: float, inner: float, offset: Vector2) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in 10:
		var radius := outer if i % 2 == 0 else inner
		var angle := -PI / 2.0 + i * PI / 5.0
		points.append(offset + Vector2.from_angle(angle) * radius)
	return points


func _draw() -> void:
	var bob := Vector2(0, sin(elapsed * 3.0) * 4.0)
	draw_circle(bob, 30.0, Color(GOLD, 0.12))
	draw_set_transform(Vector2(0, 18), -rotation, Vector2(1.0, 0.3))
	draw_circle(Vector2.ZERO, 14.0, SHADOW)
	draw_set_transform(Vector2.ZERO)
	draw_colored_polygon(star_points(21.0, 9.5, bob), GOLD)
	draw_colored_polygon(star_points(11.0, 5.0, bob + Vector2(-2, -2)), LIGHT)
