extends AnimatableBody3D
## Moves back and forth along `travel` in the physics step, so a CharacterBody3D standing on it is carried.

@export var travel := Vector3(0, 0, -4)
@export var cycle_time: float = 10.0

var origin := Vector3.ZERO
var phase: float = 0.0


func _ready() -> void:
	origin = position


func _physics_process(delta: float) -> void:
	phase += delta / cycle_time
	var weight := 0.5 - 0.5 * cos(phase * TAU)
	position = origin + travel * weight
