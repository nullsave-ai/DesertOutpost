extends SceneTree
## godot --headless --path . -s weapons/build_weapons.gd -- out=res://art/Weapons   -> exports Rifle_AR9.glb, Sniper_LR7.glb, Scope_*.glb (+ *_points.json)
static func T(p: Vector3, r := Vector3.ZERO) -> Transform3D:
	return WK.T(p, r)

static func P(a: Array) -> PackedVector2Array:
	return PackedVector2Array(a)

static func teeth(z0: float, z1: float, y: float, w := 0.022, step := 0.0127) -> ArrayMesh:
	var parts := []
	var n := int((z1 - z0) / step)
	parts.append([WK.rbox(Vector3(w, 0.0055, z1 - z0), 0.0012, 1), T(Vector3(0, y, (z0 + z1) * 0.5))])
	for i in n: parts.append([WK.rbox(Vector3(w, 0.0035, 0.0064), 0.0008, 1), T(Vector3(0, y + 0.0042, z0 + step * (i + 0.5)))])
	return WK.merge(parts)

static func slots(z0: float, z1: float, ys: Array, xw: float, n: int, len_ := 0.034) -> ArrayMesh:
	var parts := []
	for sx in [-1.0, 1.0]:
		for y in ys:
			for i in n: parts.append([WK.rbox(Vector3(0.0018, 0.010, len_), 0.0025, 1), T(Vector3(sx * xw, y, lerpf(z0, z1, (i + 0.5) / n)))])
	return WK.merge(parts)


static func _stipple(x: float, pts: Array, nx: int, ny: int, sx: float, sy: float) -> ArrayMesh:
	## small raised dots on a grip panel; pts = [Vector2(z,y) origin, Vector2(z,y) u-dir step, Vector2(z,y) v-dir step]
	var parts := []
	var o: Vector2 = pts[0]; var u: Vector2 = pts[1]; var v: Vector2 = pts[2]
	for j in ny:
		for i in nx:
			var p := o + u * (float(i) + 0.5 * float(j % 2)) + v * float(j)
			parts.append([WK.rbox(Vector3(0.0016, 0.0032, 0.0032), 0.0008, 1), T(Vector3(x, p.y, p.x))])
	return WK.merge(parts)

static func _pin(r: Node3D, nm: String, p: Vector3, rad := 0.0045) -> void:
	for sg in [-1.0, 1.0]:
		r.add_child(WK.mi(WK.lathe([Vector2(0, 0), Vector2(rad, 0), Vector2(rad, 0.0016), Vector2(rad * 0.55, 0.0016), Vector2(rad * 0.55, 0.0026), Vector2(0, 0.0026)], 16), "metal", "%s%d" % [nm, int(sg)], Vector3(p.x * sg, p.y, p.z), Vector3(0, 90 * sg, 0)))

static func _detail_rifle(r: Node3D) -> void:
	# dust cover, forward assist, bolt catch, takedown + pivot pins, barrel nut, accent racing stripes, sling socket
	r.add_child(WK.mi(WK.rbox(Vector3(0.0034, 0.022, 0.060), 0.0012), "gunmetal", "DustCover", Vector3(0.0222, 0.044, 0.002)))
	r.add_child(WK.mi(WK.lathe([Vector2(0, 0), Vector2(0.0050, 0), Vector2(0.0050, 0.012), Vector2(0.0035, 0.014), Vector2(0, 0.014)], 16), "metal", "ForwardAssist", Vector3(0.0215, 0.034, -0.055), Vector3(0, 90, 0)))
	r.add_child(WK.mi(WK.rbox(Vector3(0.0030, 0.008, 0.022), 0.0012), "metal", "BoltCatch", Vector3(-0.0215, 0.002, -0.020)))
	_pin(r, "TakedownPin", Vector3(0.0204, 0.014, -0.136)); _pin(r, "PivotPin", Vector3(0.0204, 0.010, 0.060))
	r.add_child(WK.mi(ScopeBuilder.ring(0.0120, 0.0162, 0.175, 0.188, 32), "metal", "BarrelNut", Vector3(0, 0.042, 0)))
	r.add_child(WK.mi(WK.lathe([Vector2(0.0085, 0.0), Vector2(0.0122, 0.0), Vector2(0.0122, 0.010), Vector2(0.0085, 0.010)], 24, 360.0, 0.0, Callable(), true), "accent", "MuzzleBand", Vector3(0, 0.042, 0.680)))
	for sg in [-1.0, 1.0]:
		r.add_child(WK.mi(WK.rbox(Vector3(0.0022, 0.0036, 0.250), 0.001, 1), "accent", "StripeHG%d" % int(sg), Vector3(sg * 0.0261, 0.060, 0.325)))
		r.add_child(WK.mi(WK.rbox(Vector3(0.0022, 0.0036, 0.150), 0.001, 1), "accent", "StripeRec%d" % int(sg), Vector3(sg * 0.0212, 0.062, 0.000)))
	r.add_child(WK.mi(WK.lathe([Vector2(0, 0), Vector2(0.0052, 0), Vector2(0.0052, 0.004), Vector2(0, 0.004)], 16), "metal", "SlingSocket", Vector3(0.0210, 0.004, -0.300), Vector3(0, 90, 0)))
	# flip-up iron sights (folded): front sight base with post + hood, rear aperture
	r.add_child(WK.mi(WK.rbox(Vector3(0.022, 0.030, 0.026), 0.004), "gunmetal", "FrontSightBase", Vector3(0, 0.0605, 0.506)))
	r.add_child(WK.mi(WK.rbox(Vector3(0.0032, 0.016, 0.0032), 0.0006), "black", "FrontPost", Vector3(0, 0.083, 0.506)))
	for sg in [-1.0, 1.0]: r.add_child(WK.mi(WK.rbox(Vector3(0.0030, 0.016, 0.014), 0.0008), "gunmetal", "FrontEar%d" % int(sg), Vector3(sg * 0.0075, 0.083, 0.506)))
	r.add_child(WK.mi(WK.rbox(Vector3(0.030, 0.008, 0.024), 0.002), "gunmetal", "RearSightBase", Vector3(0, 0.0735, -0.150)))
	r.add_child(WK.mi(WK.lathe([Vector2(0.0030, 0.0), Vector2(0.0070, 0.0), Vector2(0.0070, 0.006), Vector2(0.0030, 0.006)], 20), "black", "RearAperture", Vector3(0, 0.0825, -0.150)))
	for sg in [-1.0, 1.0]: r.add_child(WK.mi(WK.rbox(Vector3(0.0030, 0.014, 0.010), 0.0008), "gunmetal", "RearEar%d" % int(sg), Vector3(sg * 0.0095, 0.0805, -0.150)))
	# stippled pistol grip panels + magazine ribs
	for sg in [-1.0, 1.0]:
		r.add_child(WK.mi(_stipple(sg * 0.0165, [Vector2(-0.080, -0.044), Vector2(-0.0062, 0.0), Vector2(-0.0026, -0.0066)], 4, 10, 0.0, 0.0), "stipple", "GripStipple%d" % int(sg)))
	var ribs := []
	for i in 7:
		var t := float(i) / 6.0; var y := lerpf(-0.062, -0.158, t); var z := lerpf(0.022, 0.043, t) + 0.001
		ribs.append([WK.rbox(Vector3(0.0300, 0.0020, 0.032), 0.0006, 1), T(Vector3(0, y, z), Vector3(-9, 0, 0))])
	r.add_child(WK.mi(WK.merge(ribs), "black", "MagRibs"))

static func _detail_sniper(r: Node3D) -> void:
	r.add_child(WK.mi(WK.lathe([Vector2(0.0105, 0.0), Vector2(0.0125, 0.0), Vector2(0.0125, 0.070), Vector2(0.0100, 0.074), Vector2(0.0, 0.074)], 24), "metal", "BoltShroud", Vector3(0, 0.046, -0.190)))
	r.add_child(WK.mi(WK.rbox(Vector3(0.007, 0.012, 0.010), 0.002), "accent", "CockingPiece", Vector3(0, 0.050, -0.194)))
	r.add_child(WK.mi(ScopeBuilder.ring(0.0140, 0.0200, 0.188, 0.206, 32), "metal", "RecoilLug", Vector3(0, 0.042, 0)))
	r.add_child(WK.mi(ScopeBuilder.ring(0.0108, 0.0150, 0.590, 0.600, 24), "metal", "BarrelBand", Vector3(0, 0.042, 0)))
	r.add_child(WK.mi(ScopeBuilder.ring(0.0108, 0.0150, 0.835, 0.850, 24), "accent", "ThreadRing", Vector3(0, 0.042, 0)))
	_pin(r, "ActionScrew", Vector3(0.0224, 0.024, 0.140), 0.0045); _pin(r, "ActionScrew2", Vector3(0.0224, 0.024, -0.040), 0.0045)
	# bottom rail on the forend (teeth point down), QD sling sockets, mag release lever
	var br := WK.mi(teeth(0.28, 0.50, 0.0, 0.020), "gunmetal", "BottomRail"); br.rotation_degrees = Vector3(0, 0, 180); r.add_child(br)
	for z in [0.230, 0.470]: r.add_child(WK.mi(WK.lathe([Vector2(0, 0), Vector2(0.0052, 0), Vector2(0.0052, 0.004), Vector2(0, 0.004)], 16), "metal", "SlingSocket%d" % int(z * 100), Vector3(0.0262, 0.034, z), Vector3(0, 90, 0)))
	r.add_child(WK.mi(WK.rbox(Vector3(0.006, 0.012, 0.026), 0.002), "accent", "MagRelease", Vector3(0.0, -0.020, -0.026), Vector3(18, 0, 0)))
	# adjustable cheek riser rods + knobs, rear spike monopod, stock spacer plates, stripes
	for z in [-0.290, -0.372]:
		r.add_child(WK.mi(WK.lathe([Vector2(0, 0), Vector2(0.0040, 0), Vector2(0.0040, 0.018), Vector2(0, 0.018)], 12), "metal", "RiserRod%d" % int(-z * 100), Vector3(0, 0.064, z), Vector3(-90, 0, 0)))
	r.add_child(WK.mi(WK.lathe([Vector2(0, 0), Vector2(0.0075, 0), Vector2(0.0075, 0.010), Vector2(0.006, 0.012), Vector2(0, 0.012)], 20, 360.0, 0.0, func(th, z): return 1.0 + 0.06 * cos(th * 14.0)), "accent", "RiserKnob", Vector3(0.0 + 0.020, 0.074, -0.330), Vector3(0, 90, 0)))
	r.add_child(WK.mi(WK.rbox(Vector3(0.036, 0.152, 0.004), 0.0015), "accent", "PadSpacer", Vector3(0, 0.002, -0.4475)))
	r.add_child(WK.mi(WK.lathe([Vector2(0.0, 0.0), Vector2(0.006, 0.0), Vector2(0.004, 0.060), Vector2(0, 0.062)], 12), "metal", "RearSpike", Vector3(0, -0.058, -0.440), Vector3(-90, 0, 0)))
	for sg in [-1.0, 1.0]:
		r.add_child(WK.mi(WK.rbox(Vector3(0.0022, 0.0036, 0.300), 0.001, 1), "accent", "ForendStripe%d" % int(sg), Vector3(sg * 0.0261, 0.052, 0.330)))
		r.add_child(WK.mi(WK.rbox(Vector3(0.0022, 0.0040, 0.240), 0.001, 1), "accent", "StockStripe%d" % int(sg), Vector3(sg * 0.0181, 0.040, -0.300)))
	r.add_child(WK.mi(_stipple(0.0172, [Vector2(-0.0844, -0.040), Vector2(-0.0062, 0.0), Vector2(-0.0022, -0.0066)], 4, 9, 0.0, 0.0), "stipple", "GripStippleR"))
	r.add_child(WK.mi(_stipple(-0.0172, [Vector2(-0.0844, -0.040), Vector2(-0.0062, 0.0), Vector2(-0.0022, -0.0066)], 4, 9, 0.0, 0.0), "stipple", "GripStippleL"))
	for sg in [-1.0, 1.0]:
		r.add_child(WK.mi(WK.lathe([Vector2(0, 0), Vector2(0.0060, 0), Vector2(0.0060, 0.004), Vector2(0, 0.004)], 14), "black", "BipodPivot%d" % int(sg), Vector3(sg * 0.0305, -0.0035, 0.360), Vector3(0, 90 * sg, 0)))
		r.add_child(WK.mi(WK.lathe([Vector2(0, 0), Vector2(0.0085, 0), Vector2(0.0075, 0.012), Vector2(0, 0.012)], 14), "rubber", "BipodFoot%d" % int(sg), Vector3(sg * 0.024, -0.012, 0.510)))

static func marker(root: Node3D, nm: String, p: Vector3) -> void:
	var m := Marker3D.new(); m.name = nm; m.position = p; root.add_child(m)

const RAIL_TOP := 0.0715

static func make_optic(kind: String, cut := false) -> Node3D:
	if kind == "reddot" or kind == "holo": return SightBuilder.build(kind, cut)
	return ScopeBuilder.build(kind, cut)

static func rifle(sk := "prism4x") -> Node3D:
	var r := Node3D.new(); r.name = "Rifle_AR9"
	# receiver
	r.add_child(WK.mi(WK.rbox(Vector3(0.042, 0.050, 0.300), 0.007), "polymer2", "UpperReceiver", Vector3(0, 0.040, 0.020)))
	r.add_child(WK.mi(WK.rbox(Vector3(0.040, 0.060, 0.200), 0.006), "polymer", "LowerReceiver", Vector3(0, -0.004, -0.050)))
	r.add_child(WK.mi(WK.rbox(Vector3(0.044, 0.070, 0.062), 0.006), "polymer", "MagWell", Vector3(0, -0.036, 0.004)))
	r.add_child(WK.mi(teeth(-0.13, 0.17, 0.0655), "gunmetal", "RailUpper"))
	r.add_child(WK.mi(WK.rbox(Vector3(0.0016, 0.016, 0.044), 0.0012, 1), "black", "EjectionPortR", Vector3(0.0212, 0.042, 0.006)))
	r.add_child(WK.mi(WK.rbox(Vector3(0.020, 0.016, 0.030), 0.004), "polymer", "ChargingHandle", Vector3(0, 0.064, -0.140)))
	r.add_child(WK.mi(WK.rbox(Vector3(0.006, 0.010, 0.026), 0.002), "accent", "Selector", Vector3(0.0225, 0.004, -0.076)))
	r.add_child(WK.mi(WK.rbox(Vector3(0.006, 0.012, 0.012), 0.002), "accent", "MagRelease", Vector3(0.0235, -0.022, -0.012)))
	# handguard + rail + slots + barrel
	r.add_child(WK.mi(WK.rbox(Vector3(0.052, 0.054, 0.300), 0.009), "polymer2", "Handguard", Vector3(0, 0.040, 0.320)))
	r.add_child(WK.mi(teeth(0.17, 0.47, 0.0675), "gunmetal", "RailHandguard"))
	r.add_child(WK.mi(slots(0.20, 0.44, [0.052, 0.028], 0.0264, 4), "black", "MLOK"))
	r.add_child(WK.mi(WK.rbox(Vector3(0.056, 0.058, 0.014), 0.006), "accent", "HandguardCap", Vector3(0, 0.040, 0.474)))
	r.add_child(WK.mi(WK.rbox(Vector3(0.022, 0.024, 0.032), 0.005), "gunmetal", "GasBlock", Vector3(0, 0.042, 0.500)))
	r.add_child(WK.mi(WK.lathe([Vector2(0.0085, 0.48), Vector2(0.0085, 0.70), Vector2(0.0085, 0.768)], 20), "metal", "Barrel", Vector3(0, 0.042, 0)))
	r.add_child(WK.mi(WK.lathe([Vector2(0.0, 0.69), Vector2(0.0115, 0.69), Vector2(0.0115, 0.722), Vector2(0.0125, 0.724), Vector2(0.0125, 0.766), Vector2(0.0, 0.768)], 24), "gunmetal", "FlashHider", Vector3(0, 0.042, 0)))
	var fh := []
	for i in 6:
		var a := i * 60.0; fh.append([WK.rbox(Vector3(0.0016, 0.0145, 0.028), 0.0006, 1), Transform3D(Basis(Vector3(0, 0, 1), deg_to_rad(a)), Vector3(0, 0.042, 0.745))])
	r.add_child(WK.mi(WK.merge(fh), "black", "FlashSlots"))
	r.add_child(WK.mi(WK.lathe([Vector2(0.0, 0.0), Vector2(0.016, 0.0), Vector2(0.016, 0.075), Vector2(0.0, 0.075)], 20), "polymer", "VerticalGrip", Vector3(0, 0.016, 0.300), Vector3(90, 0, 0)))
	# pistol grip, trigger guard, trigger
	r.add_child(WK.mi(WK.extrude(P([Vector2(-0.048, -0.028), Vector2(-0.094, -0.028), Vector2(-0.120, -0.116), Vector2(-0.088, -0.126), Vector2(-0.074, -0.098)]), 0.032, 0.004), "polymer2", "PistolGrip"))
	r.add_child(WK.mi(WK.extrude(P([Vector2(-0.040, -0.026), Vector2(0.032, -0.026), Vector2(0.038, -0.060), Vector2(0.024, -0.062), Vector2(0.020, -0.038), Vector2(-0.040, -0.036)]), 0.006, 0.0008), "gunmetal", "TriggerGuard"))
	r.add_child(WK.mi(WK.rbox(Vector3(0.006, 0.024, 0.008), 0.0018), "metal", "Trigger", Vector3(0, -0.040, -0.004), Vector3(14, 0, 0)))
	# magazine
	r.add_child(WK.mi(WK.extrude(P([Vector2(-0.018, -0.040), Vector2(0.034, -0.040), Vector2(0.048, -0.118), Vector2(0.058, -0.172), Vector2(0.030, -0.182), Vector2(0.016, -0.128), Vector2(-0.008, -0.092)]), 0.028, 0.003), "polymer", "Magazine"))
	r.add_child(WK.mi(WK.extrude(P([Vector2(0.058, -0.168), Vector2(0.030, -0.178), Vector2(0.031, -0.190), Vector2(0.062, -0.180)]), 0.030, 0.002), "accent", "MagPlate"))
	# stock
	r.add_child(WK.mi(WK.lathe([Vector2(0.0125, -0.345), Vector2(0.0125, -0.13)], 20), "metal", "BufferTube", Vector3(0, 0.036, 0)))
	r.add_child(WK.mi(WK.extrude(P([Vector2(-0.14, 0.062), Vector2(-0.23, 0.058), Vector2(-0.30, 0.044), Vector2(-0.342, 0.046), Vector2(-0.348, -0.046), Vector2(-0.250, -0.050), Vector2(-0.190, -0.012), Vector2(-0.140, -0.006)]), 0.036, 0.005), "polymer2", "Stock"))
	r.add_child(WK.mi(WK.rbox(Vector3(0.030, 0.014, 0.100), 0.004), "accent", "CheekRiser", Vector3(0, 0.052, -0.250)))
	r.add_child(WK.mi(WK.rbox(Vector3(0.040, 0.100, 0.016), 0.006), "rubber", "ButtPad", Vector3(0, 0.002, -0.352)))
	_detail_rifle(r)
	var sc: Node3D = null
	if sk != "":
		sc = make_optic(sk); sc.position = Vector3(0, RAIL_TOP + float(sc.get_meta("mount_drop")), -0.060 if sk.begins_with("prism") else -0.020); r.add_child(sc)
	marker(r, "Muzzle", Vector3(0, 0.042, 0.768)); marker(r, "Grip", Vector3(0, -0.04, -0.068)); marker(r, "Fore", Vector3(0, -0.02, 0.175)); marker(r, "StockPad", Vector3(0, 0.012, -0.34))
	marker(r, "Sight", Vector3(0, 0.113, 0.03))
	marker(r, "ScopeEye", (sc.position + Vector3(0, 0, -0.045)) if sc else Vector3(0, 0.105, -0.06))
	return r

static func sniper(sk := "long") -> Node3D:
	var r := Node3D.new(); r.name = "Sniper_LR7"
	r.add_child(WK.mi(WK.rbox(Vector3(0.044, 0.056, 0.280), 0.007), "polymer2", "Action", Vector3(0, 0.040, 0.040)))
	r.add_child(WK.mi(teeth(-0.10, 0.34, 0.0655), "gunmetal", "Rail"))
	r.add_child(WK.mi(WK.rbox(Vector3(0.0016, 0.014, 0.060), 0.0012, 1), "black", "EjectionPort", Vector3(0.0222, 0.044, 0.060)))
	# bolt handle with knob
	r.add_child(WK.mi(WK.lathe([Vector2(0.0, 0.0), Vector2(0.005, 0.0), Vector2(0.005, 0.060), Vector2(0.0, 0.060)], 14), "metal", "BoltArm", Vector3(0.020, 0.046, -0.050), Vector3(0, 90, 0)))
	r.add_child(WK.mi(WK.lathe([Vector2(0.0, 0.0), Vector2(0.011, 0.012), Vector2(0.0125, 0.026), Vector2(0.0, 0.034)], 20), "accent", "BoltKnob", Vector3(0.082, 0.046, -0.050), Vector3(0, 90, 0)))
	# chassis forend with slots, barrel with fluting, muzzle brake
	r.add_child(WK.mi(WK.rbox(Vector3(0.050, 0.054, 0.380), 0.009), "polymer2", "Forend", Vector3(0, 0.030, 0.330)))
	r.add_child(WK.mi(slots(0.20, 0.50, [0.040, 0.016], 0.0264, 5, 0.040), "black", "MLOK"))
	r.add_child(WK.mi(WK.rbox(Vector3(0.054, 0.058, 0.014), 0.006), "accent", "ForendCap", Vector3(0, 0.030, 0.526)))
	var flute := func(th: float, z: float) -> float: return 1.0 - (0.05 * maxf(0.0, cos(th * 8.0)) if z > 0.58 and z < 0.80 else 0.0)
	r.add_child(WK.mi(WK.lathe([Vector2(0.0135, 0.40), Vector2(0.0135, 0.56), Vector2(0.0115, 0.60), Vector2(0.0108, 0.86)], 32, 360.0, 0.0, flute), "metal", "Barrel", Vector3(0, 0.042, 0)))
	r.add_child(WK.mi(WK.lathe([Vector2(0.0, 0.85), Vector2(0.0145, 0.85), Vector2(0.0185, 0.866), Vector2(0.0185, 0.930), Vector2(0.0, 0.932)], 28), "gunmetal", "MuzzleBrake", Vector3(0, 0.042, 0)))
	var mb := []
	for i in 3:
		for sg in [-1.0, 1.0]: mb.append([WK.rbox(Vector3(0.0020, 0.0100, 0.012), 0.0006, 1), T(Vector3(sg * 0.0186, 0.042, 0.882 + i * 0.020))])
	r.add_child(WK.mi(WK.merge(mb), "black", "BrakePorts"))
	# chassis stock with high comb + adjustable riser, pistol grip, trigger, magazine
	r.add_child(WK.mi(WK.extrude(P([Vector2(-0.10, 0.062), Vector2(-0.20, 0.058), Vector2(-0.27, 0.076), Vector2(-0.40, 0.078), Vector2(-0.440, 0.070), Vector2(-0.448, -0.062), Vector2(-0.380, -0.072), Vector2(-0.320, -0.022), Vector2(-0.200, -0.026), Vector2(-0.100, -0.030)]), 0.036, 0.005), "polymer2", "Stock"))
	r.add_child(WK.mi(WK.rbox(Vector3(0.032, 0.022, 0.140), 0.005), "accent", "CheekRiser", Vector3(0, 0.078, -0.330)))
	r.add_child(WK.mi(WK.rbox(Vector3(0.040, 0.150, 0.020), 0.007), "rubber", "ButtPad", Vector3(0, 0.002, -0.458)))
	r.add_child(WK.mi(WK.extrude(P([Vector2(-0.052, -0.024), Vector2(-0.098, -0.024), Vector2(-0.124, -0.112), Vector2(-0.092, -0.122), Vector2(-0.076, -0.096)]), 0.034, 0.004), "polymer2", "PistolGrip"))
	r.add_child(WK.mi(WK.extrude(P([Vector2(-0.040, -0.022), Vector2(0.032, -0.022), Vector2(0.038, -0.054), Vector2(0.024, -0.056), Vector2(0.020, -0.034), Vector2(-0.040, -0.032)]), 0.006, 0.0008), "gunmetal", "TriggerGuard"))
	r.add_child(WK.mi(WK.rbox(Vector3(0.006, 0.022, 0.008), 0.0018), "metal", "Trigger", Vector3(0, -0.036, -0.004), Vector3(12, 0, 0)))
	r.add_child(WK.mi(WK.rbox(Vector3(0.032, 0.095, 0.056), 0.006), "polymer", "Magazine", Vector3(0, -0.062, 0.030)))
	r.add_child(WK.mi(WK.rbox(Vector3(0.034, 0.010, 0.060), 0.004), "accent", "MagPlate", Vector3(0, -0.113, 0.030)))
	# bipod (folded along the forend)
	for sg in [-1.0, 1.0]:
		r.add_child(WK.mi(WK.lathe([Vector2(0.0050, 0.0), Vector2(0.0050, 0.150)], 12), "metal", "BipodLeg%d" % int(sg), Vector3(sg * 0.024, -0.012, 0.360), Vector3(0, 0, 0)))
	r.add_child(WK.mi(WK.rbox(Vector3(0.060, 0.016, 0.030), 0.004), "accent", "BipodMount", Vector3(0, -0.001, 0.360)))
	_detail_sniper(r)
	var sc: Node3D = null
	if sk != "":
		sc = make_optic(sk); sc.position = Vector3(0, RAIL_TOP + float(sc.get_meta("mount_drop")), -0.090); r.add_child(sc)
	marker(r, "Muzzle", Vector3(0, 0.042, 0.93)); marker(r, "Grip", Vector3(0, -0.04, -0.074)); marker(r, "Fore", Vector3(0, -0.01, 0.31)); marker(r, "StockPad", Vector3(0, 0.0, -0.45))
	marker(r, "ScopeEye", (sc.position + Vector3(0, 0, -0.045)) if sc else Vector3(0, 0.105, -0.09))
	return r

static func _xf(n: Node3D, root: Node3D) -> Transform3D:
	var t := Transform3D.IDENTITY
	var c: Node = n
	while c != null and c != root.get_parent():
		t = (c as Node3D).transform * t
		if c == root: break
		c = c.get_parent()
	return t

func _init() -> void:
	var args := {}
	for a in OS.get_cmdline_user_args():
		var kv = a.split("=", true, 1)
		if kv.size() == 2: args[kv[0]] = kv[1]
	var out: String = args.get("out", "res://art/Weapons")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
	var only: String = args.get("only", "")
	var jobs := [["Rifle_AR9", rifle()], ["Rifle_AR9_Bare", rifle("")], ["Sniper_LR7", sniper()], ["Sniper_LR7_Bare", sniper("")],
		["Scope_Prism2x", ScopeBuilder.build("prism2x")], ["Scope_Prism3x", ScopeBuilder.build("prism3x")], ["Scope_Prism4x", ScopeBuilder.build("prism4x")],
		["Scope_Long", ScopeBuilder.build("long")], ["Scope_Long_Cutaway", ScopeBuilder.build("long", true)],
		["Sight_RedDot", SightBuilder.build("reddot")], ["Sight_RedDot_Cutaway", SightBuilder.build("reddot", true)], ["Sight_Holo", SightBuilder.build("holo")]]
	for pair in jobs:
		if only != "" and not String(pair[0]).contains(only): (pair[1] as Node).queue_free(); continue
		var node: Node3D = pair[1]; get_root().add_child(node)
		var doc := GLTFDocument.new(); var st := GLTFState.new()
		var err := doc.append_from_scene(node, st); var path: String = out + "/" + pair[0] + ".glb"
		if err == OK: err = doc.write_to_filesystem(st, path)
		print(pair[0], " export ", err, " -> ", path)
		var pts := {}
		for m in node.find_children("*", "Marker3D", true, false):
			var gp: Vector3 = _xf(m as Node3D, node).origin; pts[m.name.to_snake_case()] = [snappedf(gp.x, 0.0001), snappedf(gp.y, 0.0001), snappedf(gp.z, 0.0001)]
		for k in ["mount_drop", "zoom"]:
			if node.has_meta(k): pts[k] = snappedf(float(node.get_meta(k)), 0.0001)
		var f := FileAccess.open(ProjectSettings.globalize_path(out) + "/" + pair[0] + "_points.json", FileAccess.WRITE); f.store_string(JSON.stringify(pts)); f.close()
		node.queue_free()
	quit()
