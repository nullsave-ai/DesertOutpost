class_name WK
## Hard-surface modelling kit for GDScript (Godot 4.7): rounded boxes, lathe (revolved profiles, optional knurling / sweep), side-profile extrusions with chamfer,
## merge helper, material library. All dimensions in metres, weapons point along +Z, up = +Y.
static var _m := {}

static func mat(name: String) -> StandardMaterial3D:
	if _m.has(name): return _m[name]
	var m := StandardMaterial3D.new(); m.resource_name = name
	match name:
		"polymer": m.albedo_color = Color(0.13, 0.14, 0.17); m.roughness = 0.62
		"polymer2": m.albedo_color = Color(0.22, 0.24, 0.29); m.roughness = 0.58
		"metal": m.albedo_color = Color(0.55, 0.57, 0.62); m.metallic = 0.6; m.roughness = 0.38
		"gunmetal": m.albedo_color = Color(0.27, 0.29, 0.34); m.metallic = 0.5; m.roughness = 0.42
		"accent": m.albedo_color = Color(0.95, 0.46, 0.12); m.roughness = 0.5
		"accent2": m.albedo_color = Color(0.16, 0.66, 0.70); m.roughness = 0.5
		"rubber": m.albedo_color = Color(0.06, 0.06, 0.07); m.roughness = 0.9
		"black": m.albedo_color = Color(0.02, 0.02, 0.025); m.roughness = 0.8
		"white": m.albedo_color = Color(0.92, 0.9, 0.84); m.roughness = 0.6
		"glass":
			m.albedo_color = Color(0.45, 0.62, 0.70, 0.30); m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA; m.roughness = 0.04; m.metallic = 0.3; m.metallic_specular = 0.9
		"lens_coat":
			m.albedo_color = Color(0.40, 0.18, 0.60, 0.40); m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA; m.roughness = 0.03; m.metallic = 0.5
		"fiber": m.albedo_color = Color(1.0, 0.45, 0.1); m.emission_enabled = true; m.emission = Color(1.0, 0.35, 0.05); m.emission_energy_multiplier = 1.4; m.roughness = 0.3
		"led": m.albedo_color = Color(1.0, 0.05, 0.03); m.emission_enabled = true; m.emission = Color(1.0, 0.05, 0.02); m.emission_energy_multiplier = 3.0; m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		"holo_glass":
			m.albedo_color = Color(0.55, 0.75, 0.85, 0.16); m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA; m.roughness = 0.02; m.metallic = 0.2; m.cull_mode = BaseMaterial3D.CULL_DISABLED
		"stipple": m.albedo_color = Color(0.09, 0.10, 0.12); m.roughness = 0.95
		"reticle": m.albedo_color = Color(0.01, 0.01, 0.01); m.roughness = 1.0
	_m[name] = m; return m

static func mi(mesh: Mesh, mname: String, nm: String, pos := Vector3.ZERO, rot_deg := Vector3.ZERO) -> MeshInstance3D:
	var n := MeshInstance3D.new(); n.name = nm; n.mesh = mesh; n.material_override = mat(mname); n.position = pos; n.rotation_degrees = rot_deg; return n

# ---------------------------------------------------------------- rounded box
static func rbox(sz: Vector3, r: float, k := 3) -> ArrayMesh:
	var h := sz * 0.5; r = minf(r, minf(h.x, minf(h.y, h.z)) * 0.98); var inner := h - Vector3(r, r, r)
	var st := SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES); st.set_smooth_group(0)
	var us := PackedFloat32Array()
	var ix := [inner.x / h.x, inner.y / h.y, inner.z / h.z]
	for ax in 3:
		var a := PackedFloat32Array(); var i: float = ix[ax]
		for s in range(k + 1): a.append(lerpf(-1.0, -i, float(s) / k))
		for s in range(k + 1): a.append(lerpf(i, 1.0, float(s) / k))
		us.append_array(a)
	var n1 := (k + 1) * 2
	for face in 6:
		var ax := face / 2; var sg := 1.0 if face % 2 == 0 else -1.0
		var a1 := (ax + 1) % 3; var a2 := (ax + 2) % 3
		var grid := []
		for j in n1:
			var row := []
			for i in n1:
				var p := Vector3.ZERO
				p[ax] = sg; p[a1] = us[a1 * n1 + i]; p[a2] = us[a2 * n1 + j]
				var q := Vector3(p.x * h.x, p.y * h.y, p.z * h.z)
				var c := Vector3(clampf(q.x, -inner.x, inner.x), clampf(q.y, -inner.y, inner.y), clampf(q.z, -inner.z, inner.z))
				var d := q - c; var nn := d.normalized() if d.length() > 1e-7 else Vector3(p.x, p.y, p.z).normalized()
				row.append([c + nn * r, nn])
			grid.append(row)
		for j in n1 - 1:
			for i in n1 - 1:
				var A = grid[j][i]; var Bq = grid[j][i + 1]; var C = grid[j + 1][i + 1]; var D = grid[j + 1][i]
				var flip := (sg > 0) != (ax == 1)
				var tri := [[A, Bq, C], [A, C, D]]
				for t in tri:
					var order = t if not flip else [t[0], t[2], t[1]]
					for v in order: st.set_normal(v[1]); st.add_vertex(v[0])
	return st.commit()

# ---------------------------------------------------------------- lathe: profile = Array of Vector2(radius, z); mod = Callable(theta, z)->radius scale
static func lathe(profile: Array, seg := 32, sweep_deg := 360.0, start_deg := 0.0, mod := Callable(), caps := true) -> ArrayMesh:
	var st := SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES); st.set_smooth_group(0)
	var full := absf(sweep_deg - 360.0) < 0.01; var n := seg if full else seg
	var rows := []
	for pi in profile.size():
		var p: Vector2 = profile[pi]; var row := []
		for s in n + 1:
			var th := deg_to_rad(start_deg + sweep_deg * float(s) / n); var rr: float = p.x * (float(mod.call(th, p.y)) if mod.is_valid() else 1.0)
			row.append(Vector3(cos(th) * rr, sin(th) * rr, p.y))
		rows.append(row)
	for pi in profile.size() - 1:
		for s in n:
			var a: Vector3 = rows[pi][s]; var b: Vector3 = rows[pi][s + 1]; var c: Vector3 = rows[pi + 1][s + 1]; var d: Vector3 = rows[pi + 1][s]
			for v in [a, c, b, a, d, c]: st.add_vertex(v)
	if caps:
		for end in [0, profile.size() - 1]:
			var p: Vector2 = profile[end]
			if p.x < 1e-5: continue
			var cz := Vector3(0, 0, p.y)
			for s in n:
				var a: Vector3 = rows[end][s]; var b: Vector3 = rows[end][s + 1]
				if end == 0: st.add_vertex(cz); st.add_vertex(b); st.add_vertex(a)
				else: st.add_vertex(cz); st.add_vertex(a); st.add_vertex(b)
	st.generate_normals()
	var m := st.commit()
	return _flip_if_inward(m)

static func _flip_if_inward(m: ArrayMesh) -> ArrayMesh:
	# lathe winding is built for outward normals of an axis-aligned revolve; verify with the first vertex normal and flip when needed
	var arr := m.surface_get_arrays(0); var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]; var nr: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
	var s := 0.0
	for i in v.size(): s += Vector3(v[i].x, v[i].y, 0).normalized().dot(nr[i])
	if s >= 0: return m
	var st := SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES); st.set_smooth_group(0)
	for i in range(0, v.size(), 3): st.add_vertex(v[i]); st.add_vertex(v[i + 2]); st.add_vertex(v[i + 1])
	st.generate_normals(); return st.commit()

static func tube(r0: float, r1: float, z0: float, z1: float, seg := 24) -> ArrayMesh:
	return lathe([Vector2(r0, z0), Vector2(r1, z1)], seg)

# ---------------------------------------------------------------- side profile extrusion; poly points = (z, y); width along X.
# chamfer c: end caps use the polygon inset by c, wall spans x = +-(w/2 - c), a 45-degree bevel ring joins them (crisp, hand-painted friendly edges).
static func extrude(poly: PackedVector2Array, width: float, chamfer := 0.0) -> ArrayMesh:
	var st := SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES); st.set_smooth_group(-1)
	var n := poly.size(); var hw := width * 0.5; var c := minf(chamfer, hw * 0.45)
	var cen := Vector2.ZERO
	for p in poly: cen += p
	cen /= n
	var area := 0.0
	for i in n: area += poly[i].x * poly[(i + 1) % n].y - poly[(i + 1) % n].x * poly[i].y
	var ccw := area > 0.0
	var inset := PackedVector2Array()
	for i in n:
		var p0 := poly[(i + n - 1) % n]; var p1 := poly[i]; var p2 := poly[(i + 1) % n]
		var e1 := (p1 - p0).normalized(); var e2 := (p2 - p1).normalized()
		var n1 := Vector2(-e1.y, e1.x) if ccw else Vector2(e1.y, -e1.x); var n2 := Vector2(-e2.y, e2.x) if ccw else Vector2(e2.y, -e2.x)
		var bis := (n1 + n2); bis = bis.normalized() if bis.length() > 1e-6 else n1
		inset.append(p1 + bis * c / maxf(0.35, bis.dot(n1)))
	var V := func(p: Vector2, x: float) -> Vector3: return Vector3(x, p.y, p.x)
	var tri := Geometry2D.triangulate_polygon(inset)
	for i in range(0, tri.size(), 3):
		var ids := [tri[i], tri[i + 1], tri[i + 2]]
		for id in ids: st.add_vertex(V.call(inset[id], hw))
		for id in [ids[0], ids[2], ids[1]]: st.add_vertex(V.call(inset[id], -hw))
	for i in n:
		var j := (i + 1) % n; var pa := poly[i]; var pb := poly[j]; var ia := inset[i]; var ib := inset[j]
		# wall
		for v in [V.call(pa, hw - c), V.call(pb, -hw + c), V.call(pb, hw - c), V.call(pa, hw - c), V.call(pa, -hw + c), V.call(pb, -hw + c)]: st.add_vertex(v)
		# bevels (+x then -x side)
		for v in [V.call(pa, hw - c), V.call(pb, hw - c), V.call(ib, hw), V.call(pa, hw - c), V.call(ib, hw), V.call(ia, hw)]: st.add_vertex(v)
		for v in [V.call(pa, -hw + c), V.call(ib, -hw), V.call(pb, -hw + c), V.call(pa, -hw + c), V.call(ia, -hw), V.call(ib, -hw)]: st.add_vertex(v)
	st.generate_normals()
	return _orient_outward(st.commit())

static func _orient_outward(m: ArrayMesh) -> ArrayMesh:
	var arr := m.surface_get_arrays(0); var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var cen := Vector3.ZERO
	for p in v: cen += p
	cen /= v.size(); var vol := 0.0
	for i in range(0, v.size(), 3): vol += (v[i] - cen).dot((v[i + 1] - cen).cross(v[i + 2] - cen))
	if vol >= 0: return m
	var st := SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES); st.set_smooth_group(-1)
	for i in range(0, v.size(), 3): st.add_vertex(v[i]); st.add_vertex(v[i + 2]); st.add_vertex(v[i + 1])
	st.generate_normals(); return st.commit()

static func merge(parts: Array) -> ArrayMesh:
	## parts: [[mesh, Transform3D], ...] -> one mesh
	var st := SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for p in parts: st.append_from(p[0], 0, p[1])
	return st.commit()

static func T(pos: Vector3, rot_deg := Vector3.ZERO) -> Transform3D:
	return Transform3D(Basis.from_euler(Vector3(deg_to_rad(rot_deg.x), deg_to_rad(rot_deg.y), deg_to_rad(rot_deg.z))), pos)

