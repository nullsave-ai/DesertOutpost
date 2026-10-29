class_name GameMenu
extends CanvasLayer
## Start menu, pause menu, game-over screen (all in code). Large touch-friendly buttons.
signal play
signal resume
signal to_menu
signal retry
signal char_changed
signal quality_changed

var root: Control
var panel: PanelContainer
var vb: VBoxContainer
var title: Label
var info: Label
var mode := "main"
var b_char: Button
var b_sight: Button
var b_q: Button
var b_sens: Button

func _ready() -> void:
	layer = 20; process_mode = Node.PROCESS_MODE_ALWAYS
	root = Control.new(); root.set_anchors_preset(Control.PRESET_FULL_RECT); add_child(root)
	panel = PanelContainer.new(); var sb := StyleBoxFlat.new(); sb.bg_color = Color(0.05, 0.06, 0.08, 0.78); sb.set_corner_radius_all(18); sb.set_content_margin_all(26); panel.add_theme_stylebox_override("panel", sb)
	root.add_child(panel); panel.set_anchors_preset(Control.PRESET_CENTER_LEFT); panel.position = Vector2(46, 120)
	vb = VBoxContainer.new(); vb.add_theme_constant_override("separation", 14); vb.custom_minimum_size = Vector2(430, 0); panel.add_child(vb)
	title = Label.new(); title.add_theme_font_size_override("font_size", 46); vb.add_child(title)
	info = Label.new(); info.add_theme_font_size_override("font_size", 20); info.modulate = Color(1, 1, 1, 0.8); vb.add_child(info)

func _btn(text: String, cb: Callable, fs := 30, h := 74) -> Button:
	var b := Button.new(); b.text = text; b.custom_minimum_size = Vector2(0, h); b.add_theme_font_size_override("font_size", fs); b.pressed.connect(cb)
	for st in ["normal", "hover", "pressed", "focus"]:
		var s := StyleBoxFlat.new(); s.set_corner_radius_all(12)
		s.bg_color = {"normal": Color(0.16, 0.19, 0.25, 0.95), "hover": Color(0.22, 0.27, 0.36, 0.95), "pressed": Color(0.95, 0.46, 0.12, 0.95), "focus": Color(0.2, 0.24, 0.32, 0.95)}[st]
		b.add_theme_stylebox_override(st, s)
	vb.add_child(b); return b

func _clear() -> void:
	for c in vb.get_children():
		if c != title and c != info: c.queue_free()

func show_main() -> void:
	mode = "main"; visible = true; _clear(); title.text = "DESERT OUTPOST"
	info.text = "Survive the waves.   Best: wave %d  /  score %d" % [Cfg.best_wave, Cfg.best_score]
	_btn("PLAY", func(): play.emit(), 38, 86)
	b_char = _btn("", _next_char); b_sight = _btn("", _next_sight); b_q = _btn("", _next_quality); b_sens = _btn("", _next_sens, 26, 62); _refresh()

func _refresh() -> void:
	if b_char: b_char.text = "CHARACTER:  %s" % Cfg.character
	if b_sight: b_sight.text = "AR-9 SIGHT:  %s" % ["RED DOT 1x", "HOLO 1x", "PRISM 2x", "PRISM 3x", "PRISM 4x"][Cfg.optic_ar]
	if b_q: b_q.text = "GRAPHICS:  %s" % ["LOW", "MEDIUM", "HIGH"][Cfg.quality]
	if b_sens: b_sens.text = "SENSITIVITY:  %.1f" % Cfg.sens

func _next_char() -> void:
	var ks := Cfg.CHARS.keys(); Cfg.character = ks[(ks.find(Cfg.character) + 1) % ks.size()]; Cfg.save_cfg(); _refresh(); char_changed.emit()
func _next_sight() -> void: Cfg.optic_ar = (Cfg.optic_ar + 1) % 5; Cfg.save_cfg(); _refresh(); char_changed.emit()
func _next_quality() -> void: Cfg.quality = (Cfg.quality + 1) % 3; Cfg.save_cfg(); _refresh(); quality_changed.emit()
func _next_sens() -> void: Cfg.sens = snappedf(0.6 + fmod(Cfg.sens - 0.6 + 0.2, 1.8), 0.1); Cfg.save_cfg(); _refresh()

func show_pause() -> void:
	mode = "pause"; visible = true; _clear(); title.text = "PAUSED"; info.text = ""
	_btn("RESUME", func(): resume.emit(), 36, 82); b_sens = _btn("", _next_sens, 26, 62); b_q = _btn("", _next_quality); b_char = null; b_sight = null; _refresh()
	_btn("QUIT TO MENU", func(): to_menu.emit(), 28, 66)

func show_gameover(wave: int, score: int, new_best: bool) -> void:
	mode = "over"; visible = true; _clear(); title.text = "YOU DIED"
	info.text = "Reached wave %d   -   score %d%s" % [wave, score, "   (NEW BEST!)" if new_best else ""]
	_btn("RETRY", func(): retry.emit(), 36, 82); _btn("MENU", func(): to_menu.emit(), 28, 66)
