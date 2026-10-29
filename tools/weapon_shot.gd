extends SceneTree
# args: glb=res://art/Weapons/Rifle_AR9.glb pos= look= fov= out= open=1
func _init():
	var args := {}
	for a in OS.get_cmdline_user_args():
		var kv = a.split("=", true, 1)
		if kv.size() == 2: args[kv[0]] = kv[1]
	var root := Node3D.new(); get_root().add_child(root)
	var e := Environment.new(); e.background_mode = Environment.BG_COLOR; e.background_color = Color(0.50, 0.56, 0.64); e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; e.ambient_light_color = Color(0.7, 0.7, 0.75); e.ambient_light_energy = 0.9
	var we := WorldEnvironment.new(); we.environment = e; root.add_child(we)
	var sun := DirectionalLight3D.new(); root.add_child(sun); sun.look_at_from_position(Vector3.ZERO, Vector3(-0.4, -0.7, -0.6)); sun.shadow_enabled = true
	var d := DirectionalLight3D.new(); d.light_energy = 0.4; root.add_child(d); d.look_at_from_position(Vector3.ZERO, Vector3(0.6, -0.3, 0.7))
	var g := GLTFDocument.new(); var st := GLTFState.new()
	g.append_from_file(args.get("glb", "res://art/Weapons/Rifle_AR9.glb"), st)
	var w: Node3D = g.generate_scene(st); root.add_child(w)
	if args.has("optic"):
		var og := GLTFDocument.new(); var os := GLTFState.new(); og.append_from_file("res://art/Weapons/%s.glb" % args["optic"], os)
		var o: Node3D = og.generate_scene(os); w.add_child(o)
		var js = JSON.parse_string(FileAccess.get_file_as_string("res://art/Weapons/%s_points.json" % args["optic"]))
		o.position = Vector3(0, 0.0715 + float(js["mount_drop"]), float(args.get("oz", "-0.04"))); w = o
	if args.get("open", "0") == "1":
		var o = w.find_child("ObjCapPivot", true, false); var ey = w.find_child("EyeCapPivot", true, false)
		if o: o.rotation_degrees.x = -105
		if ey: ey.rotation_degrees.x = 105
	var p = args.get("pos", "0.9,0.35,0.3").split(","); var t = args.get("look", "0,0.02,0.2").split(",")
	var cam := Camera3D.new(); cam.fov = float(args.get("fov", "30")); root.add_child(cam); cam.look_at_from_position(Vector3(float(p[0]), float(p[1]), float(p[2])), Vector3(float(t[0]), float(t[1]), float(t[2])))
	await create_timer(0.5).timeout
	for i in 4: await process_frame
	get_root().get_texture().get_image().save_png(args.get("out", "/tmp/w.png")); print("saved"); quit()
