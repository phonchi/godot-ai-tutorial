extends Area2D

var hazard: bool = false
var drift := Vector2.ZERO
var elapsed := 0.0

func _physics_process(delta: float) -> void:
    elapsed += delta
    if hazard:
        position += drift * delta
        if position.x < 35 or position.x > 925:
            drift.x *= -1
            position.x = clampf(position.x, 35, 925)
        if position.y < 85 or position.y > 565:
            drift.y *= -1
            position.y = clampf(position.y, 85, 565)
    queue_redraw()

func _draw() -> void:
    if hazard:
        draw_colored_polygon(PackedVector2Array([Vector2(0,-19),Vector2(19,0),Vector2(0,19),Vector2(-19,0)]), Color("bc4e3b"))
        draw_line(Vector2(-6,-6), Vector2(6,6), Color.WHITE, 2)
        draw_line(Vector2(6,-6), Vector2(-6,6), Color.WHITE, 2)
    else:
        draw_circle(Vector2.ZERO, 11 + sin(elapsed * 3) * 1.5, Color("d59c32"))
        draw_circle(Vector2.ZERO, 5, Color("fff1c6"))
