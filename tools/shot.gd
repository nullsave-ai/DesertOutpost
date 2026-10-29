extends SceneTree
# Usage: godot --path . -s tools/shot.gd -- scene=map|char out=/path.png
var args := {}
func _init():
	for a in OS.get_cmdline_user_args():
		var kv = a.split("=", true, 1)
		if kv.size() == 2: args[kv[0]] = kv[1]
	var root := Node3D.new(); get_root().add_child(root)
	root.add_child(MapAtmosphere.new())
	var cam := Camera3D.new(); cam.fov = 55; cam.far = 600; root.add_child(cam)
	var scn: String = args.get("scene", "map")
	if scn == "map":
		var m := MapLoader.new(); m.colliders = false; root.add_child(m)
		var p = args.get("pos", "0,45,130").split(","); var t = args.get("look", "0,0,0").split(",")
		cam.look_at_from_position(Vector3(float(p[0]), float(p[1]), float(p[2])), Vector3(float(t[0]), float(t[1]), float(t[2])))
	elif scn == "both":
		var m := MapLoader.new(); m.colliders = false; root.add_child(m)
		var c = load("res://art/Character/%s.glb" % args.get("who", "Girl")).instantiate(); root.add_child(c)
		CharacterPose.relax_arms(c)
		var base := Vector3(float(args.get("cx", "0")), float(args.get("cy", "0.15")), float(args.get("cz", "-36")))
		c.position = base; c.rotation_degrees.y = float(args.get("yaw", "0"))
		var p = args.get("pos", "1.8,1.5,-32.2").split(","); var t = args.get("look", "0,1.0,-36").split(",")
		cam.fov = float(args.get("fov", "45"))
		cam.look_at_from_position(Vector3(float(p[0]), float(p[1]), float(p[2])), Vector3(float(t[0]), float(t[1]), float(t[2])))
	else:
		var floor_ := MeshInstance3D.new(); var pl := PlaneMesh.new(); pl.size = Vector2(20, 20); floor_.mesh = pl; root.add_child(floor_)
		var c = load("res://art/Character/%s.glb" % args.get("who", "Girl")).instantiate(); root.add_child(c)
		CharacterPose.relax_arms(c)
		var p = args.get("pos", "1.6,1.5,3.2").split(","); var t = args.get("look", "0,0.95,0").split(",")
		cam.look_at_from_position(Vector3(float(p[0]), float(p[1]), float(p[2])), Vector3(float(t[0]), float(t[1]), float(t[2])))
	await create_timer(1.0).timeout
	for i in 6: await process_frame
	var img := get_root().get_texture().get_image(); img.save_png(args.get("out", "/tmp/godot_shot.png")); print("saved ", img.get_size()); quit()
