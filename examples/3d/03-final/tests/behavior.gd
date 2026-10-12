extends SceneTree

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
