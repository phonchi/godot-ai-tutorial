#!/usr/bin/env python3
"""Rebuild every independent Godot course checkpoint and deterministic ZIP downloads.
Run: python3 scripts/build_examples.py
Export: GODOT_BIN=/path/to/godot python3 scripts/build_examples.py --export
"""
from pathlib import Path
import argparse, os, subprocess, zipfile, math, wave, struct
ROOT = Path(__file__).resolve().parents[1]
P2 = '''extends CharacterBody2D

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
'''
ITEM = '''extends Area2D

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
'''
M2 = '''extends Node2D

const STAGE: int = {stage}
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
    var keys := {{"move_left": [KEY_A, KEY_LEFT], "move_right": [KEY_D, KEY_RIGHT], "move_up": [KEY_W, KEY_UP], "move_down": [KEY_S, KEY_DOWN], "restart": [KEY_R]}}
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
'''
P3 = '''extends CharacterBody3D

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
'''
M3 = '''extends Node3D

const STAGE: int = {stage}
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
    var keys := {{"move_left":[KEY_A,KEY_LEFT],"move_right":[KEY_D,KEY_RIGHT],"move_up":[KEY_W,KEY_UP],"move_down":[KEY_S,KEY_DOWN],"jump":[KEY_SPACE],"restart":[KEY_R]}}
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
'''
TEST = '''extends SceneTree

var failures: int = 0

func _initialize() -> void:
    call_deferred("run")

func check(condition: bool, message: String) -> void:
    if not condition:
        failures += 1
        push_error(message)

func run() -> void:
    var game = load("res://main.tscn").instantiate()
    root.add_child(game)
    current_scene = game
    await process_frame
    check(game.score == 0, "initial score")
    if game is Node2D:
        var start_hazards: int = game.hazards.size()
        game.spawn_hazard()
        check(game.hazards.size() == start_hazards + 1, "timer callback spawns hazard")
        for i in range(10):
            game.spawn_hazard()
        check(game.hazards.size() == 8 and game.spawn_timer.is_stopped(), "hazards capped at eight")
        game.damage_player()
        check(game.hits == 1, "first damage")
        game.damage_player()
        check(game.hits == 1, "invulnerability blocks repeated damage")
        for i in range(2):
            game.player.invulnerable = 0
            game.damage_player()
        check(game.finished and not game.won, "three hits lose")
        game.finished = false
        game.hits = 0
        game.player.enabled = true
        var first = game.collectibles[0]
        game.collect_item(first)
        game.collect_item(first)
        check(game.score == 1, "same collectible cannot count twice")
        for item in game.collectibles.duplicate():
            game.collect_item(item)
        check(game.score == 10 and game.won and game.finished, "ten collectibles win")
        check(not game.player.enabled, "end disables player")
    else:
        check(not game.try_exit() and not game.won, "exit gated before collection")
        var first = game.collectibles[0]
        game.collect_item(first)
        game.collect_item(first)
        check(game.score == 1, "same collectible cannot count twice")
        for item in game.collectibles.duplicate():
            game.collect_item(item)
        check(game.score == 5 and not game.won, "collection alone does not win")
        check(game.try_exit() and game.won, "exit unlocks after five")
        check(not game.player.enabled, "win disables player")
    game.restart_game()
    await process_frame
    await process_frame
    var restarted = current_scene
    check(is_instance_valid(restarted) and restarted != game, "restart creates scene")
    check(restarted.score == 0 and not restarted.won, "restart resets progress")
    check(InputMap.action_get_events("move_left").size() == 2, "restart does not duplicate input bindings")
    if restarted is Node2D:
        check(restarted.hits == 0 and restarted.collectibles.size() == 10, "restart resets damage and collectibles")
    else:
        check(restarted.collectibles.size() == 5, "restart restores collectibles")
    current_scene = null
    restarted.queue_free()
    await process_frame
    await process_frame
    print("BEHAVIOR CHECKS: ", "PASS" if failures == 0 else "FAIL", " (", failures, " failures)")
    quit(0 if failures == 0 else 1)
'''
PROJECT = '''; Generated by scripts/build_examples.py. Edit its templates to rebuild.
config_version=5

[application]
config/name="{name}"
run/main_scene="res://main.tscn"

[display]
window/size/viewport_width=960
window/size/viewport_height=600
window/stretch/mode="canvas_items"

[rendering]
renderer/rendering_method="gl_compatibility"
renderer/rendering_method.mobile="gl_compatibility"
environment/defaults/default_clear_color=Color(0.96,0.94,0.88,1)
'''
EXPORT = '''[preset.0]
name="Web"
platform="Web"
runnable=true
advanced_options=false
dedicated_server=false
custom_features=""
export_filter="all_resources"
include_filter=""
exclude_filter="tests/*"
export_path=""
encryption_include_filters=""
encryption_exclude_filters=""
encrypt_pck=false
encrypt_directory=false
script_export_mode=2

[preset.0.options]
custom_template/debug=""
custom_template/release=""
variant/extensions_support=false
variant/thread_support=false
vram_texture_compression/for_desktop=true
vram_texture_compression/for_mobile=false
html/export_icon=true
html/custom_html_shell=""
html/head_include=""
html/canvas_resize_policy=2
html/focus_canvas_on_start=true
html/experimental_virtual_keyboard=false
progressive_web_app/enabled=false
'''

def write(path, text):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding='utf-8')

def sound(path):
    path.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(path), 'wb') as wav:
        wav.setparams((1,2,22050,0,'NONE','not compressed'))
        wav.writeframes(b''.join(struct.pack('<h',int(9000 * math.sin(2*math.pi*(660 if i<2205 else 880)*i/22050)*(1-i/4410))) for i in range(4410)))

def archive(project, target):
    target.parent.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(target,'w',zipfile.ZIP_DEFLATED) as z:
        for path in sorted(project.rglob('*')):
            if path.is_file() and '.godot' not in path.parts:
                info = zipfile.ZipInfo(str(Path(project.name)/path.relative_to(project)),(2026,1,1,0,0,0))
                info.compress_type = zipfile.ZIP_DEFLATED
                z.writestr(info,path.read_bytes())

def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('--export',action='store_true')
    parser.add_argument('--test',action='store_true')
    args=parser.parse_args()
    projects=[]
    for dimension, stages in [('2d',['01-movement','02-collect','03-hazards','04-interface','05-final']),('3d',['01-world','02-controller','03-final'])]:
        for stage,name in enumerate(stages,1):
            project=ROOT/'examples'/dimension/name
            write(project/'project.godot',PROJECT.format(name=f'Godot AI • {dimension.upper()} • {name}'))
            node='Node2D' if dimension=='2d' else 'Node3D'
            write(project/'main.tscn',f'[gd_scene load_steps=2 format=3]\n\n[ext_resource type="Script" path="res://scripts/main.gd" id="1"]\n\n[node name="Main" type="{node}"]\nscript = ExtResource("1")\n')
            write(project/'scripts'/'main.gd',(M2 if dimension=='2d' else M3).format(stage=stage))
            write(project/'scripts'/'player.gd',P2 if dimension=='2d' else P3)
            if dimension=='2d':
                write(project/'scripts'/'item.gd',ITEM)
                sound(project/'audio'/'collect.wav')
            write(project/'export_presets.cfg',EXPORT)
            write(project/'.gitignore','.godot/\n')
            write(project/'README.md',f'# {dimension.upper()} {name}\n\nOpen `project.godot` in Godot 4.7.2, then press F6 with `main.tscn` open or F5.\n\nWASD / arrow keys: move. R: restart. '+('Space: jump. Collect five spheres, then enter the teal exit.' if dimension=='3d' else 'Gold circles: collect. Red diamonds: avoid. Ten collected wins; three hits loses.')+'\n\nProcedural original graphics; no external assets. Generated collect sound is CC0. Code: MIT.\n')
            if name.endswith('final'):
                write(project/'tests'/'behavior.gd',TEST)
            rules = "# Project rules\n\nGodot 4.7.2, GDScript, Compatibility renderer. Keep the current stage scope.\nExplain a bounded change before editing; report files changed and checks actually run.\nRead project.godot and scripts before making assumptions. Do not modify global settings or add paid services.\nVerify logs and actual behavior separately. Do not commit or push without instructions.\n"
            write(project/'AGENTS.md',rules)
            write(project/'CLAUDE.md',rules)
            write(project/'LICENSE',(ROOT/'LICENSE').read_text() if (ROOT/'LICENSE').exists() else "MIT License. Copyright (c) 2026 phonchi.\n")
            projects.append((dimension,name,project))
    godot=os.environ.get('GODOT_BIN','godot')
    if args.test or args.export:
        for dimension,name,project in projects:
            subprocess.run([godot,'--headless','--path',str(project),'--editor','--import'],check=True)
            if args.test and name.endswith('final'):
                subprocess.run([godot,'--headless','--path',str(project),'--script','res://tests/behavior.gd'],check=True)
            if args.export and name.endswith('final'):
                target=ROOT/'public'/'play'/dimension/'index.html'
                target.parent.mkdir(parents=True,exist_ok=True)
                subprocess.run([godot,'--headless','--path',str(project),'--export-release','Web',str(target)],check=True)
    for dimension,name,project in projects:
        archive(project,ROOT/'public'/'downloads'/f'{dimension}-{name}.zip')
    print(f'Generated {len(projects)} independent projects and ZIPs.')

if __name__=='__main__':
    main()
