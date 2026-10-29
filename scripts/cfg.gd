class_name Cfg
## Persistent player settings (user://settings.cfg) + quality presets.
const CHARS := {"Girl": "res://art/Character/Girl.glb", "Sana": "res://art/Character/Sana.glb", "Soldier": "res://art/Character/Soldier.glb"}
static var character := "Girl"
static var quality := 1            # 0 low, 1 medium, 2 high
static var sens := 1.0
static var optic_ar := 1           # index into AR9 optics (0 red dot, 1 holo, 2 2x, 3 3x, 4 4x)
static var best_wave := 0
static var best_score := 0
static var _loaded := false

static func load_cfg() -> void:
	if _loaded: return
	_loaded = true
	var c := ConfigFile.new()
	if c.load("user://settings.cfg") != OK: return
	character = str(c.get_value("game", "character", character)); quality = int(c.get_value("game", "quality", quality)); sens = float(c.get_value("game", "sens", sens))
	optic_ar = int(c.get_value("game", "optic_ar", optic_ar)); best_wave = int(c.get_value("game", "best_wave", 0)); best_score = int(c.get_value("game", "best_score", 0))
	if not CHARS.has(character): character = "Girl"

static func save_cfg() -> void:
	var c := ConfigFile.new()
	c.set_value("game", "character", character); c.set_value("game", "quality", quality); c.set_value("game", "sens", sens)
	c.set_value("game", "optic_ar", optic_ar); c.set_value("game", "best_wave", best_wave); c.set_value("game", "best_score", best_score)
	c.save("user://settings.cfg")

static func char_path() -> String: return CHARS[character]

static func apply_quality(vp: Viewport, sun: DirectionalLight3D) -> void:
	var scale_: float = [0.6, 0.8, 1.0][quality]
	vp.scaling_3d_mode = Viewport.SCALING_3D_MODE_BILINEAR; vp.scaling_3d_scale = scale_
	vp.msaa_3d = Viewport.MSAA_DISABLED
	if sun:
		sun.shadow_enabled = quality >= 1
		sun.directional_shadow_max_distance = [40.0, 70.0, 95.0][quality]
