extends CharacterBody2D

@export var speed: float = 260.0
var enabled: bool = true
var invulnerable: float = 0.0

func _physics_process(delta: float) -> void:
    invulnerable = maxf(0.0, invulnerable - delta)
    var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
    velocity = direction * speed if enabled else Vector2.ZERO
    move_and_slide()
    position = position.clamp(Vector2(28, 74), Vector2(932, 572))
    queue_redraw()

func _draw() -> void:
    var color := Color("2f7e79")
    if invulnerable > 0.0 and int(invulnerable * 10) % 2 == 0:
        color.a = 0.35
    draw_circle(Vector2.ZERO, 17, color)
    draw_circle(Vector2(6, -5), 3, Color.WHITE)
    draw_circle(Vector2(-6, -5), 3, Color.WHITE)
