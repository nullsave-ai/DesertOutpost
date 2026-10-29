class_name SightBuilder
## Non-magnifying / low-power sights that exist in real life: "reddot" (closed-tube micro red dot, 1x) and "holo" (windowed holographic sight, 1x).
## Same conventions as ScopeBuilder: weapon forward = +Z, up = +Y, rear rim at z=0, markers EyePoint/ObjPoint, meta mount_drop / zoom, flip caps for reddot.
static func _mount(root: Node3D, y_axis_to_base: float, z0: float, z1: float, w: float) -> void:
	var zc := (z0 + z1) * 0.5
	root.add_child(WK.mi(WK.rbox(Vector3(w, 0.010, z1 - z0), 0.003), "metal", "MountBase", Vector3(0, -y_axis_to_base + 0.005 + 0.004, zc)))
	root.add_child(WK.mi(WK.rbox(Vector3(w + 0.012, 0.006, 0.020), 0.002), "gunmetal", "RailClamp", Vector3(0, -y_axis_to_base + 0.003, zc)))
	# quick-detach lever + bolts
	root.add_child(WK.mi(WK.rbox(Vector3(0.006, 0.010, 0.022), 0.002), "accent", "QDLever", Vector3(w * 0.5 + 0.008, -y_axis_to_base + 0.010, zc)))
	for sx in [-1.0, 1.0]: root.add_child(WK.mi(WK.lathe([Vector2(0.0, 0.0), Vector2(0.0040, 0.0), Vector2(0.0040, 0.004), Vector2(0.0, 0.004)], 10), "black", "Bolt%d" % int(sx), Vector3(sx * (w * 0.5 - 0.004), -y_axis_to_base + 0.011, z0 + 0.007), Vector3(-90, 0, 0)))

static func build(kind: String, cutaway := false) -> Node3D:
	if kind == "holo": return _holo()
	return _reddot(cutaway)

static func _reddot(cutaway: bool) -> Node3D:
	var root := Node3D.new(); root.name = "Sight_reddot"
	var r := 0.0155; var rh := 0.0190; var L := 0.072; var wall := 0.0016
	root.set_meta("mount_drop", r + 0.0165); root.set_meta("zoom", 1.0)
	var outer := [Vector2(rh, 0.0), Vector2(rh, 0.010), Vector2(r, 0.016), Vector2(r, 0.054), Vector2(rh + 0.0005, 0.060), Vector2(rh + 0.0005, L)]
	var prof := []
	for p in outer: prof.append(p)
	for i in range(outer.size() - 1, -1, -1): prof.append(Vector2(maxf(outer[i].x - wall, 0.004), outer[i].y))
	prof.append(outer[0])
	root.add_child(WK.mi(WK.lathe(prof, 48, 180.0 if cutaway else 360.0, 180.0 if cutaway else 0.0, Callable(), false), "gunmetal", "Body"))
	root.add_child(WK.mi(ScopeBuilder.ring(rh - 0.001, rh + 0.0020, L - 0.012, L - 0.005, 40), "accent", "AccentRing"))
	# objective collimator lens (large, angled look via coat) + ocular window + LED emitter + dot plate
	root.add_child(WK.mi(ScopeBuilder.lens(rh - wall - 0.002, 0.0035, 0.0025, true), "lens_coat", "ObjLens", Vector3(0, 0, L - 0.016)))
	root.add_child(WK.mi(ScopeBuilder.lens(rh - wall - 0.003, 0.0025, 0.0025, false), "glass", "EyeLens", Vector3(0, 0, 0.012)))
	root.add_child(WK.mi(WK.rbox(Vector3(0.007, 0.003, 0.007), 0.001), "black", "LEDHousing", Vector3(0, -(r - wall - 0.0035), 0.040)))
	root.add_child(WK.mi(WK.lathe([Vector2(0, 0), Vector2(0.0013, 0), Vector2(0.0013, 0.0016), Vector2(0, 0.0016)], 12), "led", "LED", Vector3(0, -(r - wall - 0.0017), 0.040), Vector3(-90, 0, 0)))
	root.add_child(WK.mi(WK.lathe([Vector2(0, 0), Vector2(0.0009, 0), Vector2(0.0009, 0.0008), Vector2(0, 0.0008)], 12), "led", "Dot", Vector3(0, 0, 0.0200)))
	# turrets (elevation up, windage right), battery cap left, brightness knob left-rear
	for t in [["TurretElev", Vector3(0, r - 0.001, 0.034), Vector3(-90, 0, 0), "accent"], ["TurretWind", Vector3(r - 0.001, 0, 0.034), Vector3(0, 90, 0), "polymer"]]:
		var n := Node3D.new(); n.name = t[0]; n.position = t[1]; n.rotation_degrees = t[2]; root.add_child(n)
		n.add_child(WK.mi(WK.lathe([Vector2(0, 0), Vector2(0.0058, 0), Vector2(0.0058, 0.0075), Vector2(0.0052, 0.0082), Vector2(0, 0.0082)], 24, 360.0, 0.0, func(th, z): return 1.0 + 0.04 * cos(th * 24.0)), t[3], "Cap"))
	var bn := Node3D.new(); bn.name = "BatteryCap"; bn.position = Vector3(-(r - 0.001), 0, 0.040); bn.rotation_degrees = Vector3(0, -90, 0); root.add_child(bn)
	bn.add_child(WK.mi(WK.lathe([Vector2(0, 0), Vector2(0.0070, 0), Vector2(0.0070, 0.0070), Vector2(0, 0.0070)], 24, 360.0, 0.0, func(th, z): return 1.0 + 0.05 * cos(th * 20.0)), "polymer", "Cap"))
	bn.add_child(WK.mi(WK.rbox(Vector3(0.010, 0.0016, 0.0010), 0.0003, 1), "black", "Slot", Vector3(0, 0, 0.0072)))
	_mount(root, r + 0.0165, 0.016, 0.056, 0.034)
	# flip caps
	var capr := rh + 0.0025
	var cpO := Node3D.new(); cpO.name = "ObjCapPivot"; cpO.position = Vector3(0, capr, L + 0.002); root.add_child(cpO)
	cpO.add_child(WK.mi(WK.lathe([Vector2(0.0, 0.0), Vector2(capr + 0.0015, 0.0), Vector2(capr + 0.0015, 0.011), Vector2(capr - 0.0012, 0.011), Vector2(capr - 0.0012, 0.0025), Vector2(0.0, 0.0025)], 40, 360.0, 0.0, Callable(), false), "rubber", "ObjCap", Vector3(0, -capr, 0)))
	var cpE := Node3D.new(); cpE.name = "EyeCapPivot"; cpE.position = Vector3(0, capr, -0.002); root.add_child(cpE)
	cpE.add_child(WK.mi(WK.lathe([Vector2(0.0, 0.0), Vector2(capr + 0.0015, 0.0), Vector2(capr + 0.0015, -0.010), Vector2(capr - 0.0012, -0.010), Vector2(capr - 0.0012, -0.0025), Vector2(0.0, -0.0025)], 40, 360.0, 0.0, Callable(), false), "rubber", "EyeCap", Vector3(0, -capr, 0)))
	_caps_anim(root)
	_markers(root, L, -0.060)
	return root

static func _holo() -> Node3D:
	var root := Node3D.new(); root.name = "Sight_holo"
	var W := 0.056; var H := 0.050; var L := 0.092; var t := 0.005    # outer width/height, length; wall thickness
	var yc := 0.012                                               # window centre above bore-axis line (axis = reticle centre)
	root.set_meta("mount_drop", 0.0 + 0.036); root.set_meta("zoom", 1.0)
	# housing: floor, two side walls, roof hood with front lip; windows are real openings (fronts & rears are glass in frames)
	root.add_child(WK.mi(WK.rbox(Vector3(W, 0.012, L), 0.004), "polymer2", "Floor", Vector3(0, -0.027, L * 0.5)))
	for sx in [-1.0, 1.0]:
		root.add_child(WK.mi(WK.rbox(Vector3(t, H, L), 0.002), "polymer2", "Wall%d" % int(sx), Vector3(sx * (W * 0.5 - t * 0.5), -0.027 + 0.006 + H * 0.5 - 0.004, L * 0.5)))
	root.add_child(WK.mi(WK.rbox(Vector3(W, 0.011, L * 0.62), 0.004), "polymer2", "Roof", Vector3(0, 0.0225 + 0.0, L * 0.5 - 0.016)))
	root.add_child(WK.mi(WK.rbox(Vector3(W - 0.006, 0.006, 0.016), 0.002), "gunmetal", "RoofLip", Vector3(0, 0.0235, L - 0.010)))
	# window frames + glass (front = objective, rear = ocular)
	for z in [0.004, L - 0.004]:
		var nm := "Rear" if z < 0.05 else "Front"
		root.add_child(WK.mi(WK.rbox(Vector3(0.046, 0.003, 0.003), 0.001, 1), "gunmetal", nm + "FrameTop", Vector3(0, 0.0165, z)))
		root.add_child(WK.mi(WK.rbox(Vector3(0.046, 0.003, 0.003), 0.001, 1), "gunmetal", nm + "FrameBot", Vector3(0, -0.0205, z)))
		root.add_child(WK.mi(WK.rbox(Vector3(0.046, 0.034, 0.0012), 0.0004, 1), "holo_glass", nm + "Glass", Vector3(0, -0.002, z)))
	# laser/LED emitter (rear-bottom) + hologram grating plate (rear glass) + reticle projected pattern
	root.add_child(WK.mi(WK.rbox(Vector3(0.014, 0.008, 0.012), 0.002), "black", "LaserBox", Vector3(0, -0.0175, 0.022)))
	root.add_child(WK.mi(WK.lathe([Vector2(0, 0), Vector2(0.0013, 0), Vector2(0.0013, 0.0016), Vector2(0, 0.0016)], 12), "led", "LaserLED", Vector3(0, -0.0135, 0.022), Vector3(-90, 0, 0)))
	root.add_child(WK.mi(WK.rbox(Vector3(0.040, 0.026, 0.0012), 0.0003, 1), "holo_glass", "HologramPlate", Vector3(0, -0.001, 0.032)))
	var ring_ := WK.lathe([Vector2(0.0076, 0.0), Vector2(0.0082, 0.0), Vector2(0.0082, 0.0002), Vector2(0.0076, 0.0002), Vector2(0.0076, 0.0)], 48, 360.0, 0.0, Callable(), false)
	root.add_child(WK.mi(ring_, "led", "ReticleRing", Vector3(0, 0, 0.0330)))
	root.add_child(WK.mi(WK.lathe([Vector2(0, 0), Vector2(0.0006, 0), Vector2(0.0006, 0.0004), Vector2(0, 0.0004)], 12), "led", "ReticleDot", Vector3(0, 0, 0.0332)))
	# controls: two brightness buttons on the rear-left wall, battery cap on the rear-right, side QD lever, front lens guard rails
	for i in 2: root.add_child(WK.mi(WK.rbox(Vector3(0.004, 0.009, 0.012), 0.002), "accent" if i == 0 else "polymer", "Button%d" % i, Vector3(-W * 0.5 - 0.0012, -0.004, 0.020 + i * 0.020)))
	root.add_child(WK.mi(WK.lathe([Vector2(0, 0), Vector2(0.0080, 0), Vector2(0.0080, 0.0045), Vector2(0, 0.0045)], 24, 360.0, 0.0, func(th, z): return 1.0 + 0.05 * cos(th * 20.0)), "polymer", "BatteryCap", Vector3(W * 0.5, -0.006, 0.060), Vector3(0, 90, 0)))
	# QD base + clamp lever on the left
	_mount(root, 0.036, 0.020, 0.074, 0.040)
	_markers(root, L, -0.060)
	return root

static func _markers(root: Node3D, L: float, eye_z: float) -> void:
	var me := Marker3D.new(); me.name = "EyePoint"; me.position = Vector3(0, 0, eye_z); root.add_child(me)
	var mo := Marker3D.new(); mo.name = "ObjPoint"; mo.position = Vector3(0, 0, L + 0.01); root.add_child(mo)

static func _caps_anim(root: Node3D) -> void:
	var ap := AnimationPlayer.new(); ap.name = "AnimationPlayer"; root.add_child(ap)
	var lib := AnimationLibrary.new()
	for nm in ["open", "close"]:
		var a := Animation.new(); a.length = 0.5
		var ta := a.add_track(Animation.TYPE_VALUE); a.track_set_path(ta, NodePath("ObjCapPivot:rotation_degrees"))
		var tb := a.add_track(Animation.TYPE_VALUE); a.track_set_path(tb, NodePath("EyeCapPivot:rotation_degrees"))
		var o0 := Vector3.ZERO; var o1 := Vector3(-105, 0, 0); var e0 := Vector3.ZERO; var e1 := Vector3(105, 0, 0)
		if nm == "close": var tmp := o0; o0 = o1; o1 = tmp; tmp = e0; e0 = e1; e1 = tmp
		a.track_insert_key(ta, 0.0, o0); a.track_insert_key(ta, 0.5, o1); a.track_insert_key(tb, 0.0, e0); a.track_insert_key(tb, 0.5, e1)
		lib.add_animation(nm, a)
	ap.add_animation_library("", lib)
