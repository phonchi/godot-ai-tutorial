extends CharacterBody3D
## The explorer: camera-relative movement, forgiving jumps and a little squash and stretch.

signal jumped

@export var speed: float = 6.0
@export var acceleration: float = 30.0
@export var deceleration: float = 40.0
@export var jump_velocity: float = 8.0
@export var gravity: float = 22.0

const BODY_COLOR := Color("f7e3bd")
const ACCENT_COLOR := Color("7fd8be")
const INK := Color("1d2b2a")

var enabled: bool = true
var camera: Camera3D
var visual: Node3D


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
	if not is_on_floor():
		velocity.y -= gravity * delta
	move_and_slide()
