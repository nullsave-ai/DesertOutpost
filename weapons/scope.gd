class_name ScopeBuilder
## Fully modelled optic (outer shell + inner wall, objective / eyepiece lenses, erector tube with lens stack, reticle plate, magnification ring, turrets,
## mount rings, flip-up lens caps on hinges with open/close animations). kind = "prism4x" (compact 4x) or "long" (5-25x56 with sunshade + parallax wheel).
## cutaway=true builds the shell as a lower half so the whole interior is visible.
static func lens(R: float, sag: float, thick: float, front_convex := true, seg := 40) -> ArrayMesh:
	var prof := []
	var n := 8
	for i in n + 1:
		var t := float(i) / n; var r := R * t; var z: float = sag * (1.0 - t * t)
		prof.append(Vector2(r, z + thick))
	for i in range(n, -1, -1):
		var t := float(i) / n; var r := R * t; var z: float = (sag * 0.4) * (1.0 - t * t) * (-1.0 if not front_convex else 1.0)
		prof.append(Vector2(r, z))
	var m := WK.lathe(prof, seg, 360.0, 0.0, Callable(), false)
	return m

static func ring(r_in: float, r_out: float, z0: float, z1: float, seg := 40, mod := Callable()) -> ArrayMesh:
	return WK.lathe([Vector2(r_in, z0), Vector2(r_out, z0), Vector2(r_out, z1), Vector2(r_in, z1), Vector2(r_in, z0)], seg, 360.0, 0.0, mod, false)

static func build(kind: String, cutaway := false) -> Node3D:
	var longk := kind == "long"
	var root := Node3D.new(); root.name = "Scope_" + kind
	var L := 0.380 if longk else float({"prism4x": 0.205, "prism3x": 0.185, "prism2x": 0.165}.get(kind, 0.205))                     # tube length (eyepiece rear rim z=0 -> objective front rim z=L)
	var rt := 0.0175 if longk else 0.0150                   # main tube radius
	var re := 0.0225 if longk else 0.0185                   # eyepiece bell radius
	var ro := 0.0300 if longk else 0.0215                   # objective bell radius
	var wall := 0.0018
	root.set_meta("mount_drop", rt + 0.0165)   # axis -> bottom of the mount base (sit this on the rail top)
	root.set_meta("zoom", {"prism2x": 2.0, "prism3x": 3.0, "prism4x": 4.0, "long": 15.0}.get(kind, 4.0))
	var z_eb := 0.075 if longk else 0.040                   # eyepiece bell end
	var z_ob := L - (0.085 if longk else 0.050)             # objective bell start
	var outer := [Vector2(re, 0.0), Vector2(re + 0.0015, 0.012), Vector2(re - 0.001, z_eb * 0.6), Vector2(rt, z_eb), Vector2(rt, z_ob), Vector2(rt + 0.0035, z_ob + 0.012), Vector2(ro - 0.003, z_ob + 0.035), Vector2(ro, z_ob + 0.05), Vector2(ro, L)]
	var prof := []
	for p in outer: prof.append(p)
	for i in range(outer.size() - 1, -1, -1):
		var p: Vector2 = outer[i]; prof.append(Vector2(maxf(p.x - wall, 0.004), p.y if i != outer.size() - 1 else p.y))
	prof.append(outer[0])
	var shell := Node3D.new(); shell.name = "Shell"; root.add_child(shell)
	var sweep := 180.0 if cutaway else 360.0
	var start := 180.0 if cutaway else 0.0
	shell.add_child(WK.mi(WK.lathe(prof, 48, sweep, start, Callable(), false), "gunmetal", "Body"))
	# anodised accent rings (hand-painted colour band) + magnification ring (knurled)
	var knurl := func(th: float, z: float) -> float: return 1.0 + 0.045 * cos(th * 40.0)
	var zm0 := (0.082 if longk else 0.050); var zm1 := zm0 + (0.045 if longk else 0.020)
	shell.add_child(WK.mi(ring(rt - 0.001, rt + (0.0042 if longk else 0.0035), zm0, zm1, 64, knurl), "polymer", "MagRing"))
	shell.add_child(WK.mi(ring(rt + 0.0005, rt + 0.0045, zm1 + 0.004, zm1 + 0.009, 48), "accent", "AccentRingA"))
	shell.add_child(WK.mi(ring(ro - 0.0005, ro + 0.0030, L - 0.050, L - 0.043, 48), "accent", "AccentRingB"))
	# mount rings + base
	var zr := [0.11, 0.27] if longk else [0.07, 0.14]
	for i in zr.size():
		var rr := rt + 0.0045
		shell.add_child(WK.mi(ring(rt, rr + 0.003, zr[i] - 0.012, zr[i] + 0.012, 48), "metal", "MountRing%d" % i))
		var blk := WK.rbox(Vector3(0.040, 0.012, 0.030), 0.003)
		shell.add_child(WK.mi(blk, "metal", "MountBase%d" % i, Vector3(0, -(rt + 0.0105), zr[i])))
		for sx in [-1.0, 1.0]: shell.add_child(WK.mi(WK.lathe([Vector2(0.0, 0.0), Vector2(0.0042, 0.0), Vector2(0.0042, 0.004), Vector2(0.0, 0.004)], 10), "black", "Screw%d_%d" % [i, int(sx)], Vector3(sx * 0.016, -(rt + 0.0105), zr[i] - 0.006), Vector3(-90, 0, 0)))
	# turrets (axis built along z then rotated to y / x)
	var zt := 0.205 if longk else 0.110
	var tur := func(nm: String, pos: Vector3, rot: Vector3, rbase: float, h: float, hcap: float, acc: bool):
		var t := Node3D.new(); t.name = nm; t.position = pos; t.rotation_degrees = rot; shell.add_child(t)
		t.add_child(WK.mi(WK.lathe([Vector2(0, 0), Vector2(rbase + 0.003, 0), Vector2(rbase + 0.003, h * 0.35), Vector2(rbase, h * 0.40), Vector2(rbase, h), Vector2(0, h)], 28), "metal", "Base"))
		t.add_child(WK.mi(WK.lathe([Vector2(0, h), Vector2(rbase + 0.001, h), Vector2(rbase + 0.001, h + hcap), Vector2(rbase - 0.002, h + hcap + 0.002), Vector2(0, h + hcap + 0.002)], 40, 360.0, 0.0, func(th, z): return 1.0 + 0.04 * cos(th * 36.0)), "accent" if acc else "polymer", "Cap"))
		t.add_child(WK.mi(ring(rbase + 0.0005, rbase + 0.0022, h - 0.0045, h - 0.0040, 32), "white", "Mark"))
	tur.call("TurretElev", Vector3(0, rt - 0.001, zt), Vector3(-90, 0, 0), 0.0105 if longk else 0.0070, 0.016 if longk else 0.009, 0.014 if longk else 0.008, true)
	tur.call("TurretWind", Vector3(rt - 0.001, 0, zt), Vector3(0, 90, 0), 0.0105 if longk else 0.0070, 0.016 if longk else 0.009, 0.014 if longk else 0.008, false)
	if longk: tur.call("TurretParallax", Vector3(-(rt - 0.001), 0, zt), Vector3(0, -90, 0), 0.0100, 0.012, 0.016, false)
	# inner optics
	var inner := Node3D.new(); inner.name = "Inner"; root.add_child(inner)
	var ri := rt - wall - 0.0005
	inner.add_child(WK.mi(lens(re - wall - 0.002, 0.003, 0.003, true), "glass", "EyeLens", Vector3(0, 0, 0.010)))
	inner.add_child(WK.mi(lens(ro - wall - 0.002, 0.004, 0.004, true), "lens_coat", "ObjLensFront", Vector3(0, 0, L - 0.012)))
	inner.add_child(WK.mi(lens(ro - wall - 0.002, 0.003, 0.003, false), "glass", "ObjLensRear", Vector3(0, 0, L - 0.020)))
	var e0 := (0.110 if longk else 0.060); var e1 := L - (0.120 if longk else 0.070)
	inner.add_child(WK.mi(ring(ri - 0.0045, ri - 0.0008, e0, e1, 36), "black", "ErectorTube"))
	for i in 3:
		var zz := lerpf(e0 + 0.01, e1 - 0.01, float(i) / 2.0)
		inner.add_child(WK.mi(lens(ri - 0.0058, 0.0025, 0.0025, i % 2 == 0, 32), "glass", "ErectorLens%d" % i, Vector3(0, 0, zz)))
	var zret := (0.095 if longk else 0.052)
	inner.add_child(WK.mi(lens(ri - 0.0012, 0.0004, 0.0008, true, 32), "glass", "ReticlePlate", Vector3(0, 0, zret)))
	var rt_ := Node3D.new(); rt_.name = "ReticleMarks"; rt_.position = Vector3(0, 0, zret + 0.0012); inner.add_child(rt_)
	rt_.add_child(WK.mi(WK.rbox(Vector3(2 * ri - 0.0030, 0.00035, 0.0002), 0.0001, 1), "reticle", "H"))
	rt_.add_child(WK.mi(WK.rbox(Vector3(0.00035, 2 * ri - 0.0030, 0.0002), 0.0001, 1), "reticle", "V"))
	for i in range(-4, 5):
		if i == 0: continue
		rt_.add_child(WK.mi(WK.rbox(Vector3(0.0009, 0.0009, 0.0002), 0.0003, 1), "reticle", "DotH%d" % i, Vector3(i * 0.0016, 0, 0)))
		rt_.add_child(WK.mi(WK.rbox(Vector3(0.0009, 0.0009, 0.0002), 0.0003, 1), "reticle", "DotV%d" % i, Vector3(0, i * 0.0016, 0)))
	if not longk:
		rt_.add_child(WK.mi(WK.extrude(PackedVector2Array([Vector2(0.0, 0.0), Vector2(-0.0016, -0.0045), Vector2(0.0, -0.0032), Vector2(0.0016, -0.0045)]), 0.0002, 0.0), "fiber", "Chevron", Vector3(0, 0.0, 0), Vector3(0, 90, 0)))
	# sunshade (long scope): slides forward over the objective bell
	if longk:
		var ss := WK.mi(ring(ro + 0.0010, ro + 0.0034, 0.0, 0.085, 56), "polymer", "Sunshade", Vector3(0, 0, L - 0.010))
		root.add_child(ss)
	# flip-up lens caps: hinge pivot at the top of each rim
	var caps := {}
	var capr_o := ro + (0.0045 if longk else 0.0040)
	var cpO := Node3D.new(); cpO.name = "ObjCapPivot"; cpO.position = Vector3(0, capr_o, L + (0.085 - 0.010 + 0.002 if longk else 0.002)); root.add_child(cpO)
	var capO := WK.mi(WK.lathe([Vector2(0.0, 0.0), Vector2(capr_o + 0.002, 0.0), Vector2(capr_o + 0.002, 0.012), Vector2(capr_o - 0.0015, 0.012), Vector2(capr_o - 0.0015, 0.003), Vector2(0.0, 0.003)], 48, 360.0, 0.0, Callable(), false), "rubber", "ObjCap", Vector3(0, -capr_o, 0))
	cpO.add_child(capO); cpO.add_child(WK.mi(WK.rbox(Vector3(0.012, 0.006, 0.006), 0.0015), "accent", "ObjCapHinge", Vector3(0, 0.002, 0.003)))
	cpO.rotation_degrees = Vector3(0, 0, 0)
	var capr_e := re + 0.0030
	var cpE := Node3D.new(); cpE.name = "EyeCapPivot"; cpE.position = Vector3(0, capr_e, -0.002); root.add_child(cpE)
	var capE := WK.mi(WK.lathe([Vector2(0.0, 0.0), Vector2(capr_e + 0.002, 0.0), Vector2(capr_e + 0.002, -0.011), Vector2(capr_e - 0.0015, -0.011), Vector2(capr_e - 0.0015, -0.003), Vector2(0.0, -0.003)], 48, 360.0, 0.0, Callable(), false), "rubber", "EyeCap", Vector3(0, -capr_e, 0))
	cpE.add_child(capE); cpE.add_child(WK.mi(WK.rbox(Vector3(0.012, 0.006, 0.006), 0.0015), "accent", "EyeCapHinge", Vector3(0, 0.002, -0.003)))
	# markers + animations
	var me := Marker3D.new(); me.name = "EyePoint"; me.position = Vector3(0, 0, -0.045); root.add_child(me)
	var mo := Marker3D.new(); mo.name = "ObjPoint"; mo.position = Vector3(0, 0, L + 0.01); root.add_child(mo)
	var ap := AnimationPlayer.new(); ap.name = "AnimationPlayer"; root.add_child(ap)
	var lib := AnimationLibrary.new()
	for nm in ["open", "close"]:
		var a := Animation.new(); a.length = 0.5
		var ta := a.add_track(Animation.TYPE_VALUE); a.track_set_path(ta, NodePath("ObjCapPivot:rotation_degrees"))
		var tb := a.add_track(Animation.TYPE_VALUE); a.track_set_path(tb, NodePath("EyeCapPivot:rotation_degrees"))
		var o0 := Vector3(0, 0, 0); var o1 := Vector3(-105, 0, 0); var e0v := Vector3(0, 0, 0); var e1v := Vector3(105, 0, 0)
		if nm == "close": var tmp := o0; o0 = o1; o1 = tmp; tmp = e0v; e0v = e1v; e1v = tmp
		a.track_insert_key(ta, 0.0, o0); a.track_insert_key(ta, 0.5, o1); a.track_insert_key(tb, 0.0, e0v); a.track_insert_key(tb, 0.5, e1v)
		lib.add_animation(nm, a)
	ap.add_animation_library("", lib)
	return root
