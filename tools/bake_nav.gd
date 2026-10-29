extends SceneTree
## godot --headless --path . -s tools/bake_nav.gd   -> res://art/Map/nav.res (navigation mesh baked from the map colliders)
func _init() -> void:
	var root := Node3D.new(); get_root().add_child(root)
	var m := MapLoader.new(); m.lights = false; root.add_child(m)
	await process_frame; await process_frame; await physics_frame
	var nm := NavigationMesh.new()
	nm.agent_radius = 0.45; nm.agent_height = 1.8; nm.agent_max_climb = 0.45; nm.agent_max_slope = 45.0; nm.cell_size = 0.3; nm.cell_height = 0.2
	nm.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS; nm.geometry_collision_mask = 1
	nm.region_min_size = 4.0; nm.region_merge_size = 20.0; nm.edge_max_length = 12.0; nm.edge_max_error = 1.3; nm.vertices_per_polygon = 6.0
	var src := NavigationMeshSourceGeometryData3D.new()
	NavigationServer3D.parse_source_geometry_data(nm, src, root)
	print("parsed; has data: ", src.has_data())
	NavigationServer3D.bake_from_source_geometry_data(nm, src)
	print("baked: polys ", nm.get_polygon_count(), " verts ", nm.get_vertices().size())
	var err := ResourceSaver.save(nm, "res://art/Map/nav.res"); print("saved ", err)
	quit()
