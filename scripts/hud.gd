class_name HUD
extends CanvasLayer
## Touch HUD + combat HUD, all built in code. Controls are Controls with _gui_input (proper multi-touch, per-finger tracking).
signal pause_pressed

class TouchCtl extends Control:
	signal pressed_
	signal released_
	signal dragged(rel: Vector2)
	var kind := "button"            # button | stick | look | fire
	var label := ""
	var radius := 50.0
	var down := false
	var latched := false            # toggle state (aim)
	var finger := -1
	var vec := Vector2.ZERO
	var center := Vector2.ZERO
	var rest_center := Vector2.ZERO
	var col := Color(1, 1, 1, 0.22)
	func _ready() -> void: mouse_filter = Control.MOUSE_FILTER_STOP
	func _gui_input(e: InputEvent) -> void:
		if e is InputEventScreenTouch:
			if e.pressed and finger < 0:
				if kind == "button" or kind == "fire":
					if e.position.distance_to(size * 0.5) > radius * 1.12: return
				finger = e.index; down = true
				if kind == "stick": center = e.position; vec = Vector2.ZERO
				pressed_.emit(); queue_redraw(); accept_event()
			elif not e.pressed and e.index == finger:
				finger = -1; down = false; vec = Vector2.ZERO
				released_.emit(); queue_redraw(); accept_event()
		elif e is InputEventScreenDrag and e.index == finger:
			if kind == "stick": vec = ((e.position - center) / (radius * 0.9)).limit_length(1.0); queue_redraw()
			else: dragged.emit(e.relative)
			accept_event()
	func _draw() -> void:
		var f := ThemeDB.fallback_font
		if kind == "stick":
			var c := center if down else rest_center
			draw_circle(c, radius, Color(1, 1, 1, 0.10)); draw_arc(c, radius, 0, TAU, 48, Color(1, 1, 1, 0.35), 3.0, true)
			draw_circle(c + vec * radius * 0.8, radius * 0.42, Color(1, 1, 1, 0.38 if down else 0.22))
		elif kind == "button" or kind == "fire":
			var c := size * 0.5; var a := 0.46 if (down or latched) else 0.20
			draw_circle(c, radius, Color(col.r, col.g, col.b, a)); draw_arc(c, radius, 0, TAU, 40, Color(1, 1, 1, 0.55), 3.0, true)
			var fs := int(radius * 0.40) if label.length() <= 4 else int(radius * 0.30)
			var ts := f.get_string_size(label, HORIZONTAL_ALIGNMENT_CENTER, -1, fs)
			draw_string(f, c + Vector2(-ts.x * 0.5, fs * 0.36), label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(1, 1, 1, 0.95))

class Crosshair extends Control:
	var gap := 8.0
	var mark := 0.0
	var mark_col := Color.WHITE
	func _ready() -> void: mouse_filter = Control.MOUSE_FILTER_IGNORE
	func _draw() -> void:
		var c := size * 0.5; var w := Color(1, 1, 1, 0.9); var s := Color(0, 0, 0, 0.5)
		for d in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
			draw_line(c + d * gap + Vector2(1, 1), c + d * (gap + 9.0) + Vector2(1, 1), s, 3.0); draw_line(c + d * gap, c + d * (gap + 9.0), w, 2.0)
		draw_circle(c, 1.8, w)
		if mark > 0.0:
			for d in [Vector2(1, 1), Vector2(-1, 1), Vector2(1, -1), Vector2(-1, -1)]:
				draw_line(c + d * 8.0, c + d * 17.0, Color(mark_col.r, mark_col.g, mark_col.b, clampf(mark * 6.0, 0, 1)), 3.0)

var touch_mode := false
var move_vec := Vector2.ZERO
var look := Vector2.ZERO
var fire_held := false
var _pending := {}
var root: Control
var stick: TouchCtl
var look_zone: TouchCtl
var btn := {}
var cross: Crosshair
var hp_bar: ColorRect
var hp_fill: ColorRect
var hp_label: Label
var wave_label: Label
var ammo_label: Label
var weap_label: Label
var optic_label: Label
var feed_label: Label
var banner_label: Label
var banner_sub: Label
var vignette: ColorRect
var scope_root: Control
var scope_view: ScopeView
var collim := {}
var reload_bar: ColorRect
var _vig_t := 0.0
var _feed_t := 0.0
var _player: Player
var _size := Vector2(1280, 720)

func _ready() -> void:
	layer = 10
	touch_mode = DisplayServer.is_touchscreen_available() or OS.has_feature("android") or OS.has_feature("ios") or "--touch" in OS.get_cmdline_user_args() or "touch" in OS.get_cmdline_user_args()
	root = Control.new(); root.set_anchors_preset(Control.PRESET_FULL_RECT); root.mouse_filter = Control.MOUSE_FILTER_IGNORE; add_child(root)
	look_zone = TouchCtl.new(); look_zone.kind = "look"; look_zone.set_anchors_preset(Control.PRESET_FULL_RECT); root.add_child(look_zone)
	look_zone.dragged.connect(func(r: Vector2): look += r)
	stick = TouchCtl.new(); stick.kind = "stick"; stick.radius = 95.0; root.add_child(stick)
	stick.pressed_.connect(func(): pass)
	_mk_btn("fire", "FIRE", 82.0, Color(1.0, 0.35, 0.25)); _mk_btn("aim", "AIM", 52.0, Color(0.3, 0.7, 1.0)); _mk_btn("jump", "JUMP", 46.0, Color(0.9, 0.9, 0.9))
	_mk_btn("reload", "RLD", 44.0, Color(1.0, 0.8, 0.3)); _mk_btn("swap", "SWAP", 42.0, Color(0.6, 1.0, 0.6)); _mk_btn("optic", "SIGHT", 42.0, Color(0.8, 0.6, 1.0)); _mk_btn("pause", "II", 28.0, Color(1, 1, 1))
	btn["fire"].pressed_.connect(func(): fire_held = true); btn["fire"].released_.connect(func(): fire_held = false)
	btn["fire"].dragged.connect(func(r: Vector2): look += r)
	for k in ["aim", "jump", "reload", "swap", "optic"]: btn[k].pressed_.connect(func(): _pending[k] = true)
	btn["pause"].pressed_.connect(func(): pause_pressed.emit())
	cross = Crosshair.new(); cross.set_anchors_preset(Control.PRESET_FULL_RECT); root.add_child(cross)
	# health
	hp_bar = ColorRect.new(); hp_bar.color = Color(0, 0, 0, 0.5); root.add_child(hp_bar); hp_fill = ColorRect.new(); hp_fill.color = Color(0.3, 0.9, 0.4); hp_bar.add_child(hp_fill)
	hp_label = _lbl(18, Color.WHITE); wave_label = _lbl(22, Color.WHITE); ammo_label = _lbl(40, Color.WHITE); weap_label = _lbl(18, Color(1, 1, 1, 0.8)); optic_label = _lbl(16, Color(0.8, 0.9, 1.0, 0.9))
	feed_label = _lbl(20, Color(1, 0.9, 0.5)); banner_label = _lbl(64, Color.WHITE); banner_sub = _lbl(26, Color(1, 1, 1, 0.9))
	for l in [banner_label, banner_sub, wave_label]: l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ammo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT; weap_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT; optic_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT; feed_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	reload_bar = ColorRect.new(); reload_bar.color = Color(1, 0.85, 0.3, 0.9); reload_bar.visible = false; root.add_child(reload_bar)
	# damage vignette
	vignette = ColorRect.new(); vignette.set_anchors_preset(Control.PRESET_FULL_RECT); vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sh := Shader.new(); sh.code = "shader_type canvas_item; uniform float a = 0.0; void fragment(){ vec2 p = UV - 0.5; float d = smoothstep(0.25, 0.75, length(p * vec2(1.0, 1.15))); COLOR = vec4(0.85, 0.02, 0.02, d * a); }"
	var vm := ShaderMaterial.new(); vm.shader = sh; vignette.material = vm; root.add_child(vignette)
	# scope overlay (black frame + PIP circle) and collimator reticles
	scope_root = Control.new(); scope_root.set_anchors_preset(Control.PRESET_FULL_RECT); scope_root.mouse_filter = Control.MOUSE_FILTER_IGNORE; scope_root.visible = false; add_child(scope_root)
	var blk := ColorRect.new(); blk.color = Color.BLACK; blk.set_anchors_preset(Control.PRESET_FULL_RECT); blk.mouse_filter = Control.MOUSE_FILTER_IGNORE; scope_root.add_child(blk)
	for st in [0, 1]:
		var cv := ScopeView.new(); cv.set_anchors_preset(Control.PRESET_FULL_RECT); root.add_child(cv); cv.setup_collimator(st); cv.visible = false; collim[st] = cv
	get_viewport().size_changed.connect(_layout)
	_layout()
	set_touch_visible(touch_mode)

func _lbl(fs: int, col: Color) -> Label:
	var l := Label.new(); l.add_theme_font_size_override("font_size", fs); l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85)); l.add_theme_constant_override("outline_size", 5); l.mouse_filter = Control.MOUSE_FILTER_IGNORE; root.add_child(l); return l

func _mk_btn(k: String, label: String, r: float, col: Color) -> void:
	var b := TouchCtl.new(); b.kind = "fire" if k == "fire" else "button"; b.label = label; b.radius = r; b.col = col; b.size = Vector2(r * 2, r * 2); root.add_child(b); btn[k] = b

func set_touch_visible(v: bool) -> void:
	stick.visible = v; look_zone.visible = v
	for k in btn: btn[k].visible = v or k == "pause"

func _layout() -> void:
	var s := get_viewport().get_visible_rect().size; _size = s; var W := s.x; var H := s.y
	stick.position = Vector2(0, H * 0.30); stick.size = Vector2(W * 0.42, H * 0.70); stick.rest_center = Vector2(150, stick.size.y - 150)
	var place := {"fire": Vector2(W - 150, H - 170), "aim": Vector2(W - 300, H - 105), "jump": Vector2(W - 70, H - 345), "reload": Vector2(W - 255, H - 265), "swap": Vector2(W - 380, H - 200), "optic": Vector2(W - 430, H - 330), "pause": Vector2(W - 44, 44)}
	for k in place: var b: TouchCtl = btn[k]; b.position = place[k] - b.size * 0.5
	hp_bar.position = Vector2(26, 22); hp_bar.size = Vector2(320, 16); hp_fill.size = hp_bar.size
	hp_label.position = Vector2(26, 40); wave_label.position = Vector2(W * 0.5 - 200, 14); wave_label.size = Vector2(400, 30)
	ammo_label.position = Vector2(W - 440, 90); ammo_label.size = Vector2(380, 50); weap_label.position = Vector2(W - 440, 138); weap_label.size = Vector2(380, 24)
	optic_label.position = Vector2(W - 440, 160); optic_label.size = Vector2(380, 24); feed_label.position = Vector2(W - 440, 190); feed_label.size = Vector2(380, 26)
	banner_label.position = Vector2(0, H * 0.22); banner_label.size = Vector2(W, 80); banner_sub.position = Vector2(0, H * 0.22 + 78); banner_sub.size = Vector2(W, 34)
	reload_bar.position = Vector2(W * 0.5 - 60, H * 0.5 + 44); reload_bar.size = Vector2(120, 5)
	if scope_view:
		var sq := minf(W, H) * 0.98; scope_view.size = Vector2(sq, sq); scope_view.position = Vector2((W - sq) * 0.5, (H - sq) * 0.5)

func consume(k: String) -> bool:
	if _pending.has(k): _pending.erase(k); return true
	return false

func vibrate(ms: int) -> void:
	if touch_mode: Input.vibrate_handheld(ms)

func _process(dt: float) -> void:
	move_vec = stick.vec if touch_mode else Vector2.ZERO
	if cross.mark > 0.0: cross.mark = maxf(0.0, cross.mark - dt); cross.queue_redraw()
	if _vig_t > 0.0: _vig_t = maxf(0.0, _vig_t - dt * 1.4); (vignette.material as ShaderMaterial).set_shader_parameter("a", clampf(_vig_t, 0, 1) * 0.9)
	if _feed_t > 0.0:
		_feed_t -= dt; feed_label.modulate.a = clampf(_feed_t * 2.0, 0.0, 1.0)
	if _player:
		var p := _player; var w := p.weapon()
		hp_fill.size.x = hp_bar.size.x * clampf(p.hp / p.max_hp, 0.0, 1.0); hp_fill.color = Color(0.3, 0.9, 0.4).lerp(Color(0.95, 0.25, 0.2), clampf(1.0 - p.hp / p.max_hp * 1.4, 0, 1))
		hp_label.text = "HP %d" % int(ceil(p.hp))
		cross.visible = p.ads < 0.5 and p.active and not p.dead; cross.gap = 7.0 + clampf(Vector2(p.velocity.x, p.velocity.z).length(), 0, 7.0) * 1.6 + (6.0 if p.kick_pool > 0.002 else 0.0)
		cross.queue_redraw() if cross.visible else null
		reload_bar.visible = p.reload_t > 0.0
		if p.reload_t > 0.0: reload_bar.size.x = 120.0 * (1.0 - p.reload_t / float(w.def["reload"]))
		btn["aim"].latched = p.ads_want; btn["aim"].queue_redraw()
		for k in ["aim", "optic"]: btn[k].modulate.a = 1.0 if w.optic_kind != "none" else 0.35

func set_player(p: Player) -> void:
	_player = p; set_weapon_info(p)

func set_weapon_info(p: Player) -> void:
	var w := p.weapon()
	ammo_label.text = "%d / %d" % [p.mags[p.cur], int(w.def["mag"])]; weap_label.text = str(w.def["label"]); optic_label.text = w.optic_label()

func update_status(wave: int, score: int, alive: int, best := false) -> void:
	wave_label.text = "WAVE %d    ENEMIES %d    SCORE %d" % [wave, alive, score]

func damage_flash(_angle: float) -> void: _vig_t = 1.0

func hit_marker(kill: bool, head: bool) -> void:
	cross.mark = 0.18; cross.mark_col = Color(1, 0.2, 0.2) if kill else (Color(1, 0.85, 0.2) if head else Color.WHITE)
	if kill: feed("ELIMINATED" + (" - HEADSHOT" if head else "") + "  +%d" % (150 if head else 100))

func feed(t: String) -> void: feed_label.text = t; _feed_t = 2.2; feed_label.modulate.a = 1.0

func banner(t: String, sub := "", secs := 2.2) -> void:
	banner_label.text = t; banner_sub.text = sub; banner_label.modulate.a = 1.0; banner_sub.modulate.a = 1.0
	var tw := create_tween(); tw.tween_interval(secs); tw.tween_property(banner_label, "modulate:a", 0.0, 0.5); tw.parallel().tween_property(banner_sub, "modulate:a", 0.0, 0.5)

func set_scope(p: Player, on: bool) -> void:
	scope_root.visible = on
	if scope_view: scope_view.set_active(on)
	if on: scope_refresh(p)
	get_viewport().disable_3d = on
	for k in btn: if k != "pause": btn[k].modulate.a = btn[k].modulate.a   # keep

func scope_refresh(p: Player) -> void:
	var w := p.weapon()
	if scope_view: scope_view.queue_free(); scope_view = null
	if w.optic_kind != "pip": return
	scope_view = ScopeView.new(); scope_root.add_child(scope_view)
	scope_view.setup(w.obj, w.zoom, 60.0, 640 if Cfg.quality < 2 else 896, 1 if w.def_name == "LR7" else 0)
	scope_view.set_active(scope_root.visible); _layout()

func show_collimator(on: bool, style: int) -> void:
	for k in collim: collim[k].visible = on and k == style
