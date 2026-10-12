extends Node2D

const STAGE: int = 1
const TARGET: int = 10
var score: int = 0
var hits: int = 0
var finished: bool = false
var won: bool = false
var player: CharacterBody2D
var hud: Label
var collect_sound: AudioStreamPlayer
var collectibles: Array[Area2D] = []
var hazards: Array[Area2D] = []
var spawn_timer: Timer
const ItemScript = preload("res://scripts/item.gd")
const PlayerScript = preload("res://scripts/player.gd")

func _ready() -> void:
    configure_input()
    player = CharacterBody2D.new()
    player.name = "Player"
    player.set_script(PlayerScript)
    player.position = Vector2(480, 320)
    player.collision_layer = 1
    var shape := CollisionShape2D.new()
    var circle := CircleShape2D.new()
    circle.radius = 17
    shape.shape = circle
    player.add_child(shape)
    add_child(player)
    var canvas := CanvasLayer.new()
    canvas.name = "HUD"
    add_child(canvas)
    hud = Label.new()
    hud.position = Vector2(26, 14)
    hud.add_theme_font_size_override("font_size", 21)
    hud.add_theme_color_override("font_color", Color("293c3b"))
    canvas.add_child(hud)
    collect_sound = AudioStreamPlayer.new()
    collect_sound.stream = preload("res://audio/collect.wav")
    collect_sound.volume_db = -12
    add_child(collect_sound)
    if STAGE >= 2:
        for i in range(TARGET):
            var point := Vector2(100 + (i % 5) * 185, 150 + (i / 5) * 340)
            collectibles.append(create_item(point, false, i))
    if STAGE >= 3:
        for i in range(4):
            hazards.append(create_item(Vector2(180 + i * 200, 250), true, i))
    if STAGE >= 3:
        spawn_timer = Timer.new()
        spawn_timer.name = "SpawnTimer"
        spawn_timer.wait_time = 6.0
        spawn_timer.timeout.connect(spawn_hazard)
        add_child(spawn_timer)
        spawn_timer.start()
    update_hud()
    queue_redraw()

func spawn_hazard() -> void:
    if finished or hazards.size() >= 8:
        spawn_timer.stop()
        return
    var index := hazards.size()
    hazards.append(create_item(Vector2(60, 110 + index * 45), true, index))

func configure_input() -> void:
    var keys := {"move_left": [KEY_A, KEY_LEFT], "move_right": [KEY_D, KEY_RIGHT], "move_up": [KEY_W, KEY_UP], "move_down": [KEY_S, KEY_DOWN], "restart": [KEY_R]}
    for action in keys:
        if not InputMap.has_action(action):
            InputMap.add_action(action)
        for key in keys[action]:
            var event := InputEventKey.new()
            event.physical_keycode = key
            InputMap.action_add_event(action, event)

func create_item(point: Vector2, hazard: bool, index: int) -> Area2D:
    var item := Area2D.new()
    item.set_script(ItemScript)
    item.name = ("Hazard" if hazard else "Collectible") + str(index + 1)
    item.position = point
    item.hazard = hazard
    item.drift = Vector2(100 + index * 18, 70 if index % 2 == 0 else -85)
    item.collision_layer = 0
    item.collision_mask = 1
    var collider := CollisionShape2D.new()
    var shape := CircleShape2D.new()
    shape.radius = 17 if hazard else 12
    collider.shape = shape
    item.add_child(collider)
    add_child(item)
    if hazard:
        item.body_entered.connect(func(body: Node2D):
            if body == player:
                damage_player())
    else:
        item.body_entered.connect(func(body: Node2D):
            if body == player:
                collect_item(item))
    return item

func collect_item(item: Area2D) -> void:
    if finished or not is_instance_valid(item) or not collectibles.has(item):
        return
    collectibles.erase(item)
    item.queue_free()
    score += 1
    if STAGE >= 5 and DisplayServer.get_name() != "headless":
        collect_sound.play()
    if score >= TARGET:
        finished = true
        won = true
        player.enabled = false
        if is_instance_valid(spawn_timer):
            spawn_timer.stop()
    update_hud()

func damage_player() -> void:
    if finished or player.invulnerable > 0.0:
        return
    hits += 1
    player.invulnerable = 1.4
    if hits >= 3:
        finished = true
        won = false
        player.enabled = false
        if is_instance_valid(spawn_timer):
            spawn_timer.stop()
    update_hud()

func restart_game() -> void:
    get_tree().reload_current_scene()

func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("restart"):
        restart_game()

func update_hud() -> void:
    if finished:
        hud.text = ("YOU WIN!" if won else "GAME OVER") + "   |   R: Restart"
    elif STAGE == 1:
        hud.text = "MOVE: WASD / Arrow keys   |   R: Restart"
    elif STAGE < 4:
        hud.text = "Collect gold circles. Avoid red diamonds.   |   R: Restart"
    else:
        hud.text = "COLLECT %d / %d    |    HITS %d / 3    |    WASD / Arrows    |    R: Restart" % [score, TARGET, hits]

func _draw() -> void:
    draw_rect(Rect2(0, 0, 960, 600), Color("f5efdf"))
    draw_rect(Rect2(20, 65, 920, 515), Color("e5e8d7"), true)
    for x in range(40, 940, 40):
        draw_line(Vector2(x, 65), Vector2(x, 580), Color("d6dccb"), 1)
    for y in range(80, 580, 40):
        draw_line(Vector2(20, y), Vector2(940, y), Color("d6dccb"), 1)
