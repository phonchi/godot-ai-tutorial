extends Control
## Heads-up display. Main writes the numbers; _draw() turns them into hearts, wave pips and a timer.

const INK := Color("0b2422")
const CREAM := Color("fff1d6")
const HEART := Color("e0673f")
const GOLD := Color("f6c453")
const MINT := Color("7fd8be")

var lives: int = 3
var max_lives: int = 3
var stars: int = 0
var stars_target: int = 10
var wave: int = 1
var wave_count: int = 3
var time: float = 0.0
var best: float = -1.0
var flash: float = 0.0
var panel: PanelContainer
var title_label: Label
var detail_label: Label
var banner: Label


func _ready() -> void:
	size = Vector2(960, 600)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel = PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(INK, 0.88)
	style.border_color = MINT
	style.set_border_width_all(3)
	style.set_corner_radius_all(20)
	style.set_content_margin_all(28)
	panel.add_theme_stylebox_override("panel", style)
	panel.position = Vector2(170, 170)
	panel.custom_minimum_size = Vector2(620, 0)
	add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	panel.add_child(column)
	title_label = make_label(52, GOLD)
	detail_label = make_label(20, CREAM)
	column.add_child(title_label)
	column.add_child(detail_label)
	banner = make_label(44, GOLD)
	banner.size = Vector2(960, 60)
	banner.position = Vector2(0, -80)
	add_child(banner)
	panel.visible = false


func make_label(font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", INK)
	label.add_theme_constant_override("outline_size", 8)
	return label


func show_message(title: String, detail: String) -> void:
	title_label.text = title
	detail_label.text = detail
	panel.visible = true
	panel.reset_size()
	panel.position.y = 300 - panel.size.y / 2.0


func hide_message() -> void:
	panel.visible = false


func show_banner(text: String) -> void:
	banner.text = text
	banner.position.y = -80
	banner.modulate.a = 1.0
	var tween := create_tween()
	tween.tween_property(banner, "position:y", 250.0, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_interval(0.6)
	tween.tween_property(banner, "modulate:a", 0.0, 0.3)


static func format_time(seconds: float) -> String:
	return "%d:%05.2f" % [floori(seconds / 60.0), fmod(seconds, 60.0)]


func _process(delta: float) -> void:
	if flash > 0.0:
		flash = maxf(0.0, flash - delta)
		queue_redraw()


func _draw() -> void:
	var font := get_theme_default_font()
	draw_rect(Rect2(0, 0, 960, 64), Color(INK, 0.6))
	for i in max_lives:
		draw_heart(Vector2(40 + i * 40, 33), i < lives)
	draw_star_icon(Vector2(222, 32))
	draw_string(font, Vector2(246, 42), "%d / %d" % [stars, stars_target], HORIZONTAL_ALIGNMENT_LEFT, -1, 26, CREAM)
	draw_string(font, Vector2(400, 42), "WAVE", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, MINT)
	for i in wave_count:
		var filled := i < wave
		draw_circle(Vector2(482 + i * 26, 34), 8.0, MINT if filled else Color(MINT, 0.2))
	draw_string(font, Vector2(720, 42), format_time(time), HORIZONTAL_ALIGNMENT_RIGHT, 216, 26, CREAM)
	if best >= 0.0:
		draw_string(font, Vector2(720, 86), "BEST " + format_time(best), HORIZONTAL_ALIGNMENT_RIGHT, 216, 18, GOLD)
	if flash > 0.0:
		draw_rect(Rect2(0, 0, 960, 600), Color(HEART, flash * 2.0))


func draw_heart(center: Vector2, full: bool) -> void:
	var color := HEART if full else Color(CREAM, 0.2)
	draw_circle(center + Vector2(-6, -4), 8.0, color)
	draw_circle(center + Vector2(6, -4), 8.0, color)
	draw_colored_polygon(PackedVector2Array([center + Vector2(-13.5, 0), center + Vector2(13.5, 0), center + Vector2(0, 14)]), color)


func draw_star_icon(center: Vector2) -> void:
	var points := PackedVector2Array()
	for i in 10:
		var radius := 14.0 if i % 2 == 0 else 6.0
		points.append(center + Vector2.from_angle(-PI / 2.0 + i * PI / 5.0) * radius)
	draw_colored_polygon(points, GOLD)
