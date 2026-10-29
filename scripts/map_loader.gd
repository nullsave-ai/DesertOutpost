class_name MapLoader
extends Node3D
## Loads art/Map/Map.glb, builds the two 14-layer texture arrays, assigns the ported map shaders,
## adds trimesh colliders (not for foliage) and turns Light_* empties into OmniLight3D (same as MapPrefabBuilder.cs in Unity).
const NAMES := ["sand", "rock", "gravel", "mud", "concrete", "plaster", "brick", "corrugated", "wood", "rust", "slab", "asphalt", "fabric", "paintmetal"]
@export var map_scene: PackedScene = preload("res://art/Map/Map.glb")
@export var colliders := true
@export var lights := true
var spawns := {}

static func _pack(suffix: String) -> Texture2DArray:
	var imgs: Array[Image] = []
	for n in NAMES:
		var im: Image = (load("res://art/Map/Textures/%s_%s.png" % [n, suffix]) as Texture2D).get_image()
		if im.is_compressed(): im.decompress()
		im.convert(Image.FORMAT_RGBA8); im.generate_mipmaps(); imgs.append(im)
	var arr := Texture2DArray.new(); arr.create_from_images(imgs); return arr

func _ready() -> void:
	var alb := _pack("a"); var nor := _pack("n")
	var mats := {}
	for k in ["structure", "terrain", "foliage"]:
		var m := ShaderMaterial.new(); m.shader = load("res://shaders/map_%s.gdshader" % k)
		if k != "foliage": m.set_shader_parameter("albedo_arr", alb); m.set_shader_parameter("normal_arr", nor)
		mats[k] = m
	var inst := map_scene.instantiate(); add_child(inst)
	var cols := 0; var rends := 0
	for mi in inst.find_children("*", "MeshInstance3D", true, false):
		var n: String = mi.name
		var is_fol := n.begins_with("Foliage"); var is_ter := n.begins_with("Terrain")
		var mat: Material = mats["foliage"] if is_fol else (mats["terrain"] if is_ter else mats["structure"])
		for s in mi.mesh.get_surface_count(): mi.set_surface_override_material(s, mat)
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF if n.begins_with("Fence") else GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		rends += 1
		if colliders and not is_fol: mi.create_trimesh_collision(); cols += 1
	for nd in inst.find_children("*", "Node3D", true, false):
		var n: String = nd.name
		if n.begins_with("Spawn"): spawns[n] = nd.global_position
		if lights and n.begins_with("Light_"):
			var l := OmniLight3D.new(); var lamp := n.begins_with("Light_L_"); var wh := n.begins_with("Light_I_WH")
			l.light_color = Color(1, 0.82, 0.52) if lamp else Color(1, 0.94, 0.82)
			l.omni_range = 14.0 if lamp else (17.0 if wh else 8.5)
			l.light_energy = 1.4 if lamp else (2.4 if wh else 1.5); l.shadow_enabled = false
			nd.add_child(l)
	print("[MapLoader] %d renderers, %d colliders, %d spawns" % [rends, cols, spawns.size()])
