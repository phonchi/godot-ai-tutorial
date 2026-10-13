extends PathFollow3D
## Rolls along its parent Path3D. PathFollow3D does not move by itself: we advance `progress`.

@export var speed: float = 2.4

var hitbox: Area3D


func _ready() -> void:
	rotation_mode = PathFollow3D.ROTATION_Y
	hitbox = Area3D.new()
	hitbox.collision_layer = 0
	hitbox.collision_mask = 1
	var shape := SphereShape3D.new()
	shape.radius = 0.55
	var collider := CollisionShape3D.new()
	collider.shape = shape
	hitbox.add_child(collider)
	hitbox.position.y = 0.55
	add_child(hitbox)
	var body := MeshInstance3D.new()
	var ball := SphereMesh.new()
	ball.radius = 0.5
	ball.height = 1.0
	body.mesh = ball
	body.material_override = paint(Color("b8432f"))
	hitbox.add_child(body)
	for i in 8:
		var spike := MeshInstance3D.new()
		var cone := CylinderMesh.new()
		cone.top_radius = 0.0
		cone.bottom_radius = 0.14
		cone.height = 0.4
		spike.mesh = cone
		spike.material_override = paint(Color("3a1d1a"))
		var angle := i * TAU / 8.0
		spike.rotation.x = angle
		spike.position = Vector3.UP.rotated(Vector3.RIGHT, angle) * 0.55
		hitbox.add_child(spike)


func paint(color: Color) -> StandardMaterial3D:
	var surface := StandardMaterial3D.new()
	surface.albedo_color = color
	surface.roughness = 0.5
	return surface


func _physics_process(delta: float) -> void:
	progress += speed * delta
	hitbox.rotate_x(-speed * delta / 0.5)
