extends SceneTree
# through-the-scope check in the map. args: glb pos(eye) yaw pitch zoom style out
func _init():
	var args := {}
	for a in OS.get_cmdline_user_args():
		var kv = a.split("=", true, 1)
		if kv.size() == 2: args[kv[0]] = kv[1]
	var root := Node3D.new(); get_root().add_child(root)
	root.add_child(MapAtmosphere.new())
	var m := MapLoader.new(); m.colliders = false; root.add_child(m)
	var g := GLTFDocument.new(); var st := GLTFState.new(); g.append_from_file(args.get("glb", "res://art/Weapons/Sniper_LR7.glb"), st)
	var w: Node3D = g.generate_scene(st)
	ScopeView.tag_weapon(w)
	var pivot := Node3D.new(); root.add_child(pivot); pivot.add_child(w)
	var p = args.get("pos", "0,3,60").split(",")
	pivot.position = Vector3(float(p[0]), float(p[1]), float(p[2])); pivot.rotation_degrees = Vector3(float(args.get("pitch", "0")), float(args.get("yaw", "180")), 0)
	var eye: Node3D = w.find_child("ScopeEye", true, false); var obj: Node3D = w.find_child("ObjPoint", true, false)
	for n in ["ObjCapPivot", "EyeCapPivot"]:
		var c = w.find_child(n, true, false); if c: c.rotation_degrees.x = -105 if n == "ObjCapPivot" else 105
	# main camera: just behind the eye, looking down the barrel
	var cam := Camera3D.new(); cam.fov = 60; cam.far = 600; root.add_child(cam); cam.current = true
	await process_frame
	cam.global_transform = eye.global_transform.translated_local(Vector3(0, 0.012, -0.10)) if eye else cam.global_transform
	cam.look_at(cam.global_position + pivot.global_transform.basis.z * 10.0, Vector3.UP)
	var ui := CanvasLayer.new(); root.add_child(ui)
	var sv := ScopeView.new(); sv.setup(obj, float(args.get("zoom", "8")), 60.0, 640, int(args.get("style", "1")))
	sv.size = Vector2(520, 520); sv.position = Vector2(1152 / 2 - 260, 648 / 2 - 260); ui.add_child(sv)
	await create_timer(1.0).timeout
	for i in 8: await process_frame
	get_root().get_texture().get_image().save_png(args.get("out", "/tmp/scope_map.png")); print("saved"); quit()
