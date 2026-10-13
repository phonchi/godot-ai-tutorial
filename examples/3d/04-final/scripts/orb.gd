extends Area3D
## A glowing orb. It bobs and spins; Main decides what collecting it means.

const GOLD := Color("f6c453")

var visual: MeshInstance3D
var elapsed: float = 0.0
var taken: bool = false


func _ready() -> void:
	visual = MeshInstance3D.new()
	var gem := SphereMesh.new()
	gem.radius = 0.38
	gem.height = 0.76
	gem.radial_segments = 8
	gem.rings = 4
	visual.mesh = gem
	visual.material_override = glow_material()
	add_child(visual)
	var shape := SphereShape3D.new()
	shape.radius = 0.8
	var collider := CollisionShape3D.new()
	collider.shape = shape
	add_child(collider)


static func glow_material() -> StandardMaterial3D:
	var glow := StandardMaterial3D.new()
	glow.albedo_color = GOLD
	glow.emission_enabled = true
	glow.emission = GOLD
	glow.emission_energy_multiplier = 1.1
	return glow


func _process(delta: float) -> void:
	elapsed += delta
	visual.rotation.y += delta * 2.0
	visual.position.y = sin(elapsed * 2.5) * 0.12


func pop() -> void:
	taken = true
	set_deferred("monitoring", false)
	# The Compatibility renderer ignores GeometryInstance3D.transparency, so fade the material's alpha instead.
	var fade: StandardMaterial3D = visual.material_override
	fade.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var tween := create_tween()
	tween.tween_property(visual, "scale", Vector3.ONE * 2.0, 0.2)
	tween.parallel().tween_property(fade, "albedo_color:a", 0.0, 0.2)
	tween.tween_callback(queue_free)
