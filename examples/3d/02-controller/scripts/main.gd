extends Node3D

const STAGE: int = 2
const TARGET: int = 5
var score: int = 0
var won: bool = false
var player: CharacterBody3D
var camera: Camera3D
var hud: Label
var exit_area: Area3D
var collectibles: Array[Area3D] = []
const PlayerScript = preload("res://scripts/player.gd")

func _ready() -> void:
    configure_input()
    var environment := WorldEnvironment.new()
    var settings := Environment.new()
    settings.background_mode = Environment.BG_COLOR
    settings.background_color = Color("d8e4df")
    settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    settings.ambient_light_color = Color("fff2d9")
    settings.ambient_light_energy = 0.65
    environment.environment = settings
    add_child(environment)
    var light := DirectionalLight3D.new()
    light.rotation_degrees = Vector3(-55,-30,0)
    light.light_energy = 1.2
    light.shadow_enabled = true
    add_child(light)
    var ground := StaticBody3D.new()
    ground.name = "Ground"
    ground.add_child(make_box(Vector3(28,0.4,28), Color("a4b996")))
    var ground_shape := CollisionShape3D.new()
    var box := BoxShape3D.new()
    box.size = Vector3(28,0.4,28)
    ground_shape.shape = box
    ground.add_child(ground_shape)
    ground.position.y = -0.2
    add_child(ground)
    for point in [Vector3(-9,0,-5), Vector3(8,0,3), Vector3(-5,0,6)]:
        var pillar := StaticBody3D.new()
        pillar.position = point + Vector3(0,1,0)
        pillar.add_child(make_box(Vector3(2,2,2),Color("7a9278")))
        var collider := CollisionShape3D.new()
        var shape := BoxShape3D.new()
        shape.size = Vector3(2,2,2)
        collider.shape = shape
        pillar.add_child(collider)
        add_child(pillar)
    player = CharacterBody3D.new()
    player.set_script(PlayerScript)
    player.name = "Player"
    player.position = Vector3(0,1,8)
    var body_shape := CollisionShape3D.new()
    var capsule := CapsuleShape3D.new()
    capsule.radius = 0.4
    capsule.height = 1.6
    body_shape.shape = capsule
    player.add_child(body_shape)
    var mesh := MeshInstance3D.new()
    var capsule_mesh := CapsuleMesh.new()
    capsule_mesh.radius = 0.4
    capsule_mesh.height = 1.6
    mesh.mesh = capsule_mesh
    mesh.material_override = material(Color("bd6545"))
    player.add_child(mesh)
    player.enabled = STAGE >= 2
    add_child(player)
    camera = Camera3D.new()
    camera.name = "FollowCamera"
    camera.current = true
    camera.fov = 60
    add_child(camera)
    update_camera()
    var canvas := CanvasLayer.new()
    canvas.name = "HUD"
    add_child(canvas)
    hud = Label.new()
    hud.position = Vector2(24,18)
    hud.add_theme_font_size_override("font_size", 23)
    hud.add_theme_color_override("font_color",Color("203a37"))
    canvas.add_child(hud)
    if STAGE >= 3:
        var points := [Vector3(-7,1,7),Vector3(6,1,7),Vector3(-8,1,-8),Vector3(6,1,-6),Vector3(0,1,-2)]
        for i in range(points.size()):
            collectibles.append(create_collectible(points[i], i))
        create_exit()
    update_hud()

func configure_input() -> void:
    var keys := {"move_left":[KEY_A,KEY_LEFT],"move_right":[KEY_D,KEY_RIGHT],"move_up":[KEY_W,KEY_UP],"move_down":[KEY_S,KEY_DOWN],"jump":[KEY_SPACE],"restart":[KEY_R]}
    for action in keys:
        if not InputMap.has_action(action):
            InputMap.add_action(action)
        for key in keys[action]:
            var event := InputEventKey.new()
            event.physical_keycode = key
            InputMap.action_add_event(action,event)

func material(color: Color) -> StandardMaterial3D:
    var result := StandardMaterial3D.new()
    result.albedo_color = color
    result.roughness = 0.85
    return result

func make_box(size: Vector3, color: Color) -> MeshInstance3D:
    var mesh := MeshInstance3D.new()
    var box := BoxMesh.new()
    box.size = size
    mesh.mesh = box
    mesh.material_override = material(color)
    return mesh

func create_collectible(point: Vector3, index: int) -> Area3D:
    var item := Area3D.new()
    item.name = "Collectible" + str(index + 1)
    item.position = point
    item.collision_layer = 0
    item.collision_mask = 1
    var mesh := MeshInstance3D.new()
    var sphere := SphereMesh.new()
    sphere.radius = 0.45
    sphere.height = 0.9
    mesh.mesh = sphere
    mesh.material_override = material(Color("dfac3a"))
    item.add_child(mesh)
    var collider := CollisionShape3D.new()
    var shape := SphereShape3D.new()
    shape.radius = 0.8
    collider.shape = shape
    item.add_child(collider)
    add_child(item)
    item.body_entered.connect(func(body: Node3D):
        if body == player:
            collect_item(item))
    return item

func create_exit() -> void:
    exit_area = Area3D.new()
    exit_area.name = "Exit"
    exit_area.position = Vector3(0,1,-11)
    exit_area.collision_layer = 0
    exit_area.collision_mask = 1
    exit_area.add_child(make_box(Vector3(3,0.15,2),Color("2f7e79")))
    for x in [-1.5,1.5]:
        var post := make_box(Vector3(0.3,3,0.3),Color("2f7e79"))
        post.position = Vector3(x,0.5,0)
        exit_area.add_child(post)
    var top := make_box(Vector3(3.3,0.3,0.3),Color("2f7e79"))
    top.position.y = 2
    exit_area.add_child(top)
    var collider := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = Vector3(3,3,2)
    collider.shape = shape
    exit_area.add_child(collider)
    add_child(exit_area)
    exit_area.body_entered.connect(func(body: Node3D):
        if body == player:
            try_exit())

func collect_item(item: Area3D) -> void:
    if won or not is_instance_valid(item) or not collectibles.has(item):
        return
    collectibles.erase(item)
    item.queue_free()
    score += 1
    update_hud()
    if score == TARGET and exit_area.overlaps_body(player):
        try_exit()

func try_exit() -> bool:
    if score < TARGET:
        hud.text = "Exit locked: collect all five gold spheres first."
        return false
    won = true
    player.enabled = false
    update_hud()
    return true

func restart_game() -> void:
    get_tree().reload_current_scene()

func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("restart"):
        restart_game()

func update_camera() -> void:
    camera.position = player.position + Vector3(0,12,13)
    camera.look_at(player.position, Vector3.UP)

func _process(_delta: float) -> void:
    if is_instance_valid(player):
        update_camera()
    if STAGE >= 3 and not won:
        for item in collectibles:
            item.rotation.y += _delta

func update_hud() -> void:
    if won:
        hud.text = "YOU WIN!   |   R: Restart"
    elif STAGE == 1:
        hud.text = "3D WORLD: inspect ground, light, camera and meshes."
    elif STAGE == 2:
        hud.text = "WASD / Arrows: Move   |   Space: Jump   |   R: Restart"
    else:
        hud.text = "COLLECT %d / 5   |   Find the teal exit   |   Space: Jump   |   R: Restart" % score
