extends SceneTree
func _init():
	var args := {}
	for a in OS.get_cmdline_user_args():
		var kv = a.split("=", true, 1)
		if kv.size() == 2: args[kv[0]] = kv[1]
	var root := Node3D.new(); get_root().add_child(root)
	var e := Environment.new(); e.background_mode = Environment.BG_COLOR; e.background_color = Color(0.55, 0.60, 0.68); e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; e.ambient_light_color = Color(0.7, 0.7, 0.75); e.ambient_light_energy = 0.9
	var we := WorldEnvironment.new(); we.environment = e; root.add_child(we)
	var sun := DirectionalLight3D.new(); root.add_child(sun); sun.look_at_from_position(Vector3.ZERO, Vector3(-0.4, -0.7, -0.6)); sun.shadow_enabled = true
	var kind: String = args.get("kind", "long")
	var s := ScopeBuilder.build(kind, args.get("cut", "0") == "1"); root.add_child(s)
	if args.get("open", "0") == "1": s.get_node("ObjCapPivot").rotation_degrees.x = -105; s.get_node("EyeCapPivot").rotation_degrees.x = 105
	var p = args.get("pos", "0.28,0.16,0.50").split(","); var t = args.get("look", "0,0,0.19").split(",")
	var cam := Camera3D.new(); cam.fov = float(args.get("fov", "35")); root.add_child(cam); cam.look_at_from_position(Vector3(float(p[0]), float(p[1]), float(p[2])), Vector3(float(t[0]), float(t[1]), float(t[2])))
	await create_timer(0.5).timeout
	for i in 4: await process_frame
	get_root().get_texture().get_image().save_png(args.get("out", "/tmp/scope.png")); print("saved"); quit()
