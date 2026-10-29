class_name WeaponRig
extends Node3D
## A runtime weapon: bare weapon GLB + selectable optic GLB, merged into ~10 meshes (one per material) for mobile draw-call budget.
## Weapon forward = +Z, up = +Y. Nodes: ObjPoint (front of the optic), MuzzlePoint. Properties describe stats and hand-grip points.
const RAIL_TOP := 0.0715
const DEFS := {
	"AR9": {"label": "AR-9", "glb": "res://art/Weapons/Rifle_AR9_Bare.glb", "optics": ["Sight_RedDot", "Sight_Holo", "Scope_Prism2x", "Scope_Prism3x", "Scope_Prism4x"],
		"mag": 30, "rpm": 640.0, "dmg": 24.0, "spread": 0.010, "recoil": 0.0065, "auto": true, "reload": 2.0, "grip": Vector3(0, -0.04, -0.068), "left": Vector3(0, -0.050, 0.30),
		"muzzle": Vector3(0, 0.042, 0.78), "snd": "rifle", "optic_z_prism": -0.060, "optic_z_sight": -0.020},
	"LR7": {"label": "LR-7", "glb": "res://art/Weapons/Sniper_LR7_Bare.glb", "optics": ["Scope_Long"],
		"mag": 5, "rpm": 46.0, "dmg": 105.0, "spread": 0.0006, "recoil": 0.034, "auto": false, "reload": 2.8, "grip": Vector3(0, -0.04, -0.074), "left": Vector3(0, -0.050, 0.30),
		"muzzle": Vector3(0, 0.042, 0.94), "snd": "sniper", "optic_z_prism": -0.090, "optic_z_sight": -0.090, "zoom_levels": [6.0, 12.0, 20.0]},
	"BOT": {"label": "BOT", "glb": "res://art/Weapons/Rifle_AR9_Bare.glb", "optics": [], "mag": 30, "rpm": 500.0, "dmg": 7.0, "spread": 0.02, "recoil": 0.0, "auto": true, "reload": 2.0,
		"grip": Vector3(0, -0.04, -0.068), "left": Vector3(0, -0.050, 0.30), "muzzle": Vector3(0, 0.042, 0.78), "snd": "bot", "optic_z_prism": 0.0, "optic_z_sight": 0.0},
}
static var _cache := {}      # path -> PackedScene
var def: Dictionary = {}
var def_name := ""
var optic_index := 0
var optic_name := ""
var eye_local := Vector3(0, 0.105, -0.1)
var obj: Node3D
var muzzle: Node3D
var optic_kind := "none"    # none | collim | pip
var zoom := 1.0
var zoom_index := 0
var _optic_root: Node3D
var _weapon_root: Node3D
var hide_from_scope := false   # player weapons: render on layer 2 too, so the scope camera (which culls layer 2) never sees its own gun

static func _scene(p: String) -> PackedScene:
	if not _cache.has(p): _cache[p] = load(p)
	return _cache[p]

func build(name_: String, optic_i := 0) -> void:
	def_name = name_; def = DEFS[name_]
	_weapon_root = (_scene(def["glb"]) as PackedScene).instantiate(); add_child(_weapon_root); _merge_into(_weapon_root, "Weapon")
	muzzle = Node3D.new(); muzzle.name = "MuzzlePoint"; muzzle.position = def["muzzle"]; add_child(muzzle)
	obj = Node3D.new(); obj.name = "ObjPoint"; add_child(obj)
	set_optic(optic_i)

func optics() -> Array: return def.get("optics", [])

func set_optic(i: int) -> void:
	var ops: Array = optics()
	if _optic_root: _optic_root.queue_free(); _optic_root = null
	if ops.is_empty(): optic_kind = "none"; optic_name = ""; zoom = 1.0; return
	optic_index = posmod(i, ops.size()); optic_name = ops[optic_index]
	var o: Node3D = (_scene("res://art/Weapons/%s.glb" % optic_name) as PackedScene).instantiate()
	var js: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://art/Weapons/%s_points.json" % optic_name))
	var oz: float = def["optic_z_prism"] if optic_name.begins_with("Scope_") else def["optic_z_sight"]
	o.position = Vector3(0, RAIL_TOP + float(js["mount_drop"]), oz)
	for n in ["ObjCapPivot", "EyeCapPivot"]:
		var c := o.find_child(n, true, false)
		if c: c.queue_free()
	var ep := o.find_child("EyePoint", true, false) as Node3D; var op := o.find_child("ObjPoint", true, false) as Node3D
	eye_local = o.position + ep.position; obj.position = o.position + op.position
	add_child(o); _optic_root = o
	_merge_into(o, "Optic")
	if optic_name.begins_with("Sight_"): optic_kind = "collim"; zoom = 1.0
	else:
		optic_kind = "pip"
		if def.has("zoom_levels"): zoom = float(def["zoom_levels"][zoom_index])
		else: zoom = float(js["zoom"])

func cycle_optic() -> void:
	if def.has("zoom_levels"):
		var z: Array = def["zoom_levels"]; zoom_index = (zoom_index + 1) % z.size(); zoom = float(z[zoom_index])
	elif optics().size() > 1: set_optic(optic_index + 1)

func optic_label() -> String:
	match optic_name:
		"Sight_RedDot": return "RED DOT 1x"
		"Sight_Holo": return "HOLO 1x"
		"Scope_Prism2x": return "PRISM 2x"
		"Scope_Prism3x": return "PRISM 3x"
		"Scope_Prism4x": return "PRISM 4x"
		"Scope_Long": return "SCOPE %dx" % int(zoom)
	return "IRON"

func collim_style() -> int: return 1 if optic_name == "Sight_Holo" else 0

static func _rel(n: Node3D, root: Node3D) -> Transform3D:
	var t := Transform3D.IDENTITY; var c: Node = n
	while c != null and c != root.get_parent():
		t = (c as Node3D).transform * t
		if c == root: break
		c = c.get_parent()
	return t

func _merge_into(root: Node3D, tag: String) -> void:
	var groups := {}
	var meshes := root.find_children("*", "MeshInstance3D", true, false)
	for m in meshes:
		var mi := m as MeshInstance3D
		if mi.mesh == null: continue
		var xf := _rel(mi, root)
		for s in mi.mesh.get_surface_count():
			var mat: Material = mi.get_active_material(s)
			var key: int = mat.get_instance_id() if mat else 0
			if not groups.has(key): var st := SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES); groups[key] = [st, mat]
			(groups[key][0] as SurfaceTool).append_from(mi.mesh, s, xf)
	for m in meshes: m.get_parent().remove_child(m); m.free()
	var k := 0
	for key in groups:
		var mesh := (groups[key][0] as SurfaceTool).commit(); var mat2: Material = groups[key][1]
		var out := MeshInstance3D.new(); out.name = "%s_%d" % [tag, k]; out.mesh = mesh; k += 1
		if mat2: out.set_surface_override_material(0, mat2)
		out.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		if hide_from_scope: out.layers = 3
		root.add_child(out)
