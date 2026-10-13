extends CharacterBody3D
## The explorer: camera-relative movement, forgiving jumps and a little squash and stretch.

signal jumped

@export var speed: float = 6.0
@export var acceleration: float = 30.0
@export var deceleration: float = 40.0
@export var jump_velocity: float = 8.0
@export var gravity: float = 22.0
@export var coyote_time: float = 0.10
@export var jump_buffer: float = 0.12

const BODY_COLOR := Color("f7e3bd")
const ACCENT_COLOR := Color("7fd8be")
const INK := Color("1d2b2a")

var enabled: bool = true
var camera: Camera3D
var visual: Node3D
var coyote_left: float = 0.0
var buffer_left: float = 0.0
var was_on_floor: bool = true


func _ready() -> void:
	visual = Node3D.new()
	visual.name = "Visual"
	add_child(visual)
	var body := CapsuleMesh.new()
	body.radius = 0.4
	body.height = 1.4
	add_part(body, BODY_COLOR, Vector3.ZERO, Vector3.ONE)
	var scarf := TorusMesh.new()
	scarf.inner_radius = 0.3
	scarf.outer_radius = 0.47
	add_part(scarf, ACCENT_COLOR, Vector3(0, 0.08, 0), Vector3(1, 0.6, 1))
	add_part(BoxMesh.new(), ACCENT_COLOR, Vector3(0, 0.2, 0.38), Vector3(0.45, 0.5, 0.22))
	for side in [-1.0, 1.0]:
		add_part(SphereMesh.new(), Color.WHITE, Vector3(side * 0.15, 0.38, -0.33), Vector3.ONE * 0.2)
		add_part(SphereMesh.new(), INK, Vector3(side * 0.15, 0.38, -0.42), Vector3.ONE * 0.09)


func add_part(mesh: PrimitiveMesh, color: Color, offset: Vector3, part_scale: Vector3) -> void:
	var part := MeshInstance3D.new()
	part.mesh = mesh
	part.position = offset
	part.scale = part_scale
	var surface := StandardMaterial3D.new()
	surface.albedo_color = color
	surface.roughness = 0.7
	part.material_override = surface
	visual.add_child(part)


func _physics_process(delta: float) -> void:
	update_jump_timers(delta)
	if enabled and Input.is_action_just_pressed("jump"):
		buffer_left = jump_buffer
	if buffer_left > 0.0 and coyote_left > 0.0:
		jump()
	var direction := camera_relative_direction() if enabled else Vector3.ZERO
	var rate := acceleration if direction != Vector3.ZERO else deceleration
	var flat := Vector2(velocity.x, velocity.z).move_toward(Vector2(direction.x, direction.z) * speed, rate * delta)
	velocity.x = flat.x
	velocity.z = flat.y
	move_and_slide()
	if direction != Vector3.ZERO:
		visual.rotation.y = lerp_angle(visual.rotation.y, atan2(-direction.x, -direction.z), 12.0 * delta)
	if is_on_floor() and not was_on_floor:
		squash(Vector3(1.25, 0.75, 1.25))
	was_on_floor = is_on_floor()


func update_jump_timers(delta: float) -> void:
	if is_on_floor():
		coyote_left = coyote_time
	else:
		coyote_left -= delta
		velocity.y -= gravity * delta
	buffer_left -= delta


func camera_relative_direction() -> Vector3:
	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if camera == null:
		return Vector3(input.x, 0, input.y)
	var forward := -camera.global_basis.z
	var right := camera.global_basis.x
	forward.y = 0.0
	right.y = 0.0
	return right.normalized() * input.x - forward.normalized() * input.y


func jump() -> void:
	velocity.y = jump_velocity
	coyote_left = 0.0
	buffer_left = 0.0
	squash(Vector3(0.8, 1.25, 0.8))
	jumped.emit()


func squash(amount: Vector3) -> void:
	visual.scale = amount
	var tween := create_tween()
	tween.tween_property(visual, "scale", Vector3.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
