extends SceneTree
# args: optic=Scope_Prism4x|Scope_Prism3x|Scope_Prism2x|Sight_RedDot|Sight_Holo|Scope_Long  weapon=Rifle_AR9_Bare|Sniper_LR7_Bare  pos yaw zoom out
func _load(path: String) -> Node3D:
	var g := GLTFDocument.new(); var st := GLTFState.new(); g.append_from_file(path, st); return g.generate_scene(st)
func _init():
	var args := {}
	for a in OS.get_cmdline_user_args():
		var kv = a.split("=", true, 1)
		if kv.size() == 2: args[kv[0]] = kv[1]
	var root := Node3D.new(); get_root().add_child(root)
	root.add_child(MapAtmosphere.new())
	var m := MapLoader.new(); m.colliders = false; root.add_child(m)
	var optic: String = args.get("optic", "Scope_Prism4x"); var wn: String = args.get("weapon", "Rifle_AR9_Bare")
	var w := _load("res://art/Weapons/%s.glb" % wn); var o := _load("res://art/Weapons/%s.glb" % optic)
	var js = JSON.parse_string(FileAccess.get_file_as_string("res://art/Weapons/%s_points.json" % optic))
	var pivot := Node3D.new(); root.add_child(pivot); pivot.add_child(w)
	var oz := -0.060 if optic.begins_with("Scope_P") else (-0.090 if optic == "Scope_Long" else -0.020)
	o.position = Vector3(0, 0.0715 + float(js["mount_drop"]), oz); pivot.add_child(o)
	ScopeView.tag_weapon(pivot)
	var p = args.get("pos", "0,2.2,-20").split(",")
	pivot.position = Vector3(float(p[0]), float(p[1]), float(p[2])); pivot.rotation_degrees = Vector3(0, float(args.get("yaw", "0")), 0)
	for n in ["ObjCapPivot", "EyeCapPivot"]:
		var c = o.find_child(n, true, false)
		if c: c.rotation_degrees.x = -105 if n == "ObjCapPivot" else 105
	var cam := Camera3D.new(); cam.fov = 60; cam.far = 600; root.add_child(cam); cam.current = true
	await process_frame
	var eye := o.find_child("EyePoint", true, false) as Node3D
	var obj := o.find_child("ObjPoint", true, false) as Node3D
	cam.global_position = eye.global_position + Vector3(0, 0.0, -0.06) * pivot.global_transform.basis.z.length()
	cam.look_at(cam.global_position + pivot.global_transform.basis.z * 10.0, Vector3.UP)
	var ui := CanvasLayer.new(); root.add_child(ui)
	var sv := ScopeView.new(); ui.add_child(sv)
	var z := float(js["zoom"])
	if optic.begins_with("Sight_"):
		sv.size = Vector2(1152, 648); sv.setup_collimator(1 if optic == "Sight_Holo" else 0)
	else:
		sv.setup(obj, z, 60.0, 640, int(args.get("style", "0")))
		sv.size = Vector2(520, 520); sv.position = Vector2(1152 / 2 - 260, 648 / 2 - 260)
	await create_timer(1.0).timeout
	for i in 8: await process_frame
	get_root().get_texture().get_image().save_png(args.get("out", "/tmp/optic.png")); print("saved ", optic, " zoom ", z); quit()
