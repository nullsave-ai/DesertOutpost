extends SceneTree
func _init():
	var m = load("res://scenes/main.tscn").instantiate(); get_root().add_child(m)
	await create_timer(0.3).timeout
	var p: Player = m.get_children().filter(func(n): return n is Player)[0]
	var y0 := p.position.y
	for i in 120: await physics_frame
	print("start y=%.2f settled y=%.2f on_floor=%s pos=%s" % [y0, p.position.y, p.is_on_floor(), p.position]); quit()
