extends SceneTree
func _init():
	print("start")
	var m1 = WK.rbox(Vector3(0.06, 0.04, 0.12), 0.01); print("rbox ", m1.get_surface_count())
	var m2 = WK.lathe([Vector2(0.0, 0), Vector2(0.02, 0), Vector2(0.02, 0.05), Vector2(0.03, 0.06), Vector2(0.03, 0.12), Vector2(0, 0.12)], 32); print("lathe")
	var poly := PackedVector2Array([Vector2(0, 0), Vector2(0.10, 0), Vector2(0.12, 0.05), Vector2(0.06, 0.09), Vector2(0, 0.06)])
	var m3 = WK.extrude(poly, 0.03, 0.004); print("extrude")
	quit()
