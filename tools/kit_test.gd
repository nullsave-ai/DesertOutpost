extends SceneTree
func _init():
	var root := Node3D.new(); get_root().add_child(root)
	var e := Environment.new(); e.background_mode = Environment.BG_COLOR; e.background_color = Color(0.5, 0.55, 0.62); e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; e.ambient_light_color = Color(0.6, 0.6, 0.65); e.ambient_light_energy = 0.8
	var we := WorldEnvironment.new(); we.environment = e; root.add_child(we)
	var sun := DirectionalLight3D.new(); root.add_child(sun); sun.look_at_from_position(Vector3.ZERO, Vector3(-0.4, -0.7, -0.6))
	root.add_child(WK.mi(WK.rbox(Vector3(0.06, 0.04, 0.12), 0.01), "polymer2", "box", Vector3(-0.1, 0, 0)))
	root.add_child(WK.mi(WK.lathe([Vector2(0.0, 0), Vector2(0.02, 0), Vector2(0.02, 0.05), Vector2(0.03, 0.06), Vector2(0.03, 0.12), Vector2(0, 0.12)], 32), "metal", "lathe", Vector3(0.0, 0, 0)))
	var poly := PackedVector2Array([Vector2(0, 0), Vector2(0.10, 0), Vector2(0.12, 0.05), Vector2(0.06, 0.09), Vector2(0, 0.06)])
	root.add_child(WK.mi(WK.extrude(poly, 0.03, 0.004), "accent", "ext", Vector3(0.1, 0, 0)))
	var cam := Camera3D.new(); root.add_child(cam); cam.look_at_from_position(Vector3(0.2, 0.15, 0.35), Vector3(0.0, 0.03, 0.06))
	await create_timer(0.5).timeout
	for i in 4: await process_frame
	get_root().get_texture().get_image().save_png("/tmp/kit_test.png"); print("ok"); quit()
