extends SceneTree
func _init():
	var c = load("res://art/Character/Girl.glb").instantiate(); get_root().add_child(c)
	for sk in c.find_children("*", "Skeleton3D", true, false):
		var names := []; for i in sk.get_bone_count(): names.append("%s:%s" % [sk.get_bone_name(i), sk.get_bone_parent(i)])
		print(sk.name, " ", names)
	print(c.find_children("*", "AnimationPlayer", true, false).size(), " animplayers")
	quit()
