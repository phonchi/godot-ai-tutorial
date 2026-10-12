extends CharacterBody3D

@export var speed: float = 6.0
@export var jump_velocity: float = 8.0
var enabled: bool = true
var gravity: float = 22.0

func _physics_process(delta: float) -> void:
    if not is_on_floor():
        velocity.y -= gravity * delta
    var input_direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
    var direction := Vector3(input_direction.x, 0, input_direction.y)
    velocity.x = direction.x * speed if enabled else 0.0
    velocity.z = direction.z * speed if enabled else 0.0
    if enabled and Input.is_action_just_pressed("jump") and is_on_floor():
        velocity.y = jump_velocity
    move_and_slide()
    position.x = clampf(position.x, -13, 13)
    position.z = clampf(position.z, -13, 13)
