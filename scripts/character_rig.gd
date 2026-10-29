class_name CharacterRig
extends Node3D
## Procedural animation of the 54-bone humanoid (the GLBs ship no clips): leg walk cycle, two-bone arm IK onto the held weapon, head pitch.
## The model faces +Z in rig space (same as the weapons). Everything is computed from the skeleton's rest pose each frame.
var model: Node3D
var skel: Skeleton3D
var wpivot: Node3D
var weapon: WeaponRig
var bone := {}
var rest := {}
var phase := 0.0
var speed_n := 0.0            # 0..1 walk intensity
var run_n := 0.0
var pitch := 0.0              # aim pitch (rad, + = up)
var lower := 0.0              # 0..1 weapon lowered (sprint / reload dip)
var tilt := 0.0               # extra weapon pitch (rad) for reload / recoil
var holding := true
var _body_vis := true
var shoulder_x := 0.16
var sh_y := 1.37
var sh_z := 0.02
var lean := 0.0

func setup(glb: String) -> void:
	for c in get_children(): c.queue_free()
	model = (load(glb) as PackedScene).instantiate(); add_child(model)
	skel = model.find_children("*", "Skeleton3D", true, false)[0]
	for m in skel.find_children("*LOD1*", "MeshInstance3D", true, false): m.free()
	for i in skel.get_bone_count():
		bone[skel.get_bone_name(i)] = i; rest[i] = skel.get_bone_global_rest(i)
	var rs: Transform3D = rest[bone["RightUpperArm"]]
	shoulder_x = absf(rs.origin.x); sh_y = rs.origin.y; sh_z = rs.origin.z
	wpivot = Node3D.new(); wpivot.name = "WeaponPivot"; add_child(wpivot)

func set_weapon(w: WeaponRig) -> void:
	weapon = w
	for c in wpivot.get_children(): wpivot.remove_child(c)
	if w: wpivot.add_child(w)

func set_body_visible(v: bool) -> void:
	if v == _body_vis: return
	_body_vis = v
	for m in skel.find_children("*", "MeshInstance3D", true, false): (m as MeshInstance3D).visible = v

func _from_to(a: Vector3, b: Vector3) -> Quaternion:
	var d := a.dot(b)
	if d > 0.99999: return Quaternion.IDENTITY
	if d < -0.99999: return Quaternion(a.cross(Vector3.UP).normalized() if absf(a.y) < 0.9 else a.cross(Vector3.RIGHT).normalized(), PI)
	return Quaternion(a, b)

func _ik_arm(side: String, target_w: Vector3, pole: Vector3) -> void:
	var si: int = bone[side + "UpperArm"]; var ei: int = bone[side + "LowerArm"]; var hi: int = bone[side + "Hand"]
	var T: Vector3 = skel.global_transform.affine_inverse() * target_w
	var rs: Transform3D = rest[si]; var re: Transform3D = rest[ei]; var rh: Transform3D = rest[hi]
	var S := rs.origin; var E0 := re.origin; var H0 := rh.origin
	var l1 := S.distance_to(E0); var l2 := E0.distance_to(H0)
	var to := T - S; var d := clampf(to.length(), 0.10, (l1 + l2) * 0.995); var dn := to.normalized()
	var a := (l1 * l1 - l2 * l2 + d * d) / (2.0 * d); var h := sqrt(maxf(l1 * l1 - a * a, 0.0))
	var pv := pole - dn * pole.dot(dn); pv = pv.normalized() if pv.length() > 0.001 else Vector3.DOWN
	var E := S + dn * a + pv * h
	var q1 := _from_to((E0 - S).normalized(), (E - S).normalized())
	skel.set_bone_global_pose(si, Transform3D(Basis(q1) * rs.basis, S))
	var Tc := S + dn * d
	var q2 := _from_to((q1 * (H0 - E0)).normalized(), (Tc - E).normalized()) * q1
	skel.set_bone_global_pose(ei, Transform3D(Basis(q2) * re.basis, E))
	skel.set_bone_global_pose(hi, Transform3D(Basis(q2) * rh.basis, E + q2 * (H0 - E0)))

func _leg(side: String, ang: float, bend: float) -> void:
	var ui: int = bone[side + "UpperLeg"]; var li: int = bone[side + "LowerLeg"]; var fi: int = bone[side + "Foot"]
	var ru: Transform3D = rest[ui]; var rl: Transform3D = rest[li]; var rf: Transform3D = rest[fi]
	var q1 := Quaternion(Vector3.RIGHT, ang)
	skel.set_bone_global_pose(ui, Transform3D(Basis(q1) * ru.basis, ru.origin))
	var p_l: Vector3 = ru.origin + q1 * (rl.origin - ru.origin)
	var q2 := Quaternion(Vector3.RIGHT, ang + bend)
	skel.set_bone_global_pose(li, Transform3D(Basis(q2) * rl.basis, p_l))
	var p_f: Vector3 = p_l + q2 * (rf.origin - rl.origin)
	skel.set_bone_global_pose(fi, Transform3D(rf.basis, p_f))

func animate(dt: float) -> void:
	if skel == null: return
	skel.reset_bone_poses()
	phase += dt * (5.5 + 4.0 * run_n) * speed_n
	var amp := (0.50 + 0.25 * run_n) * speed_n
	var s := sin(phase); var s2 := sin(phase + PI)
	_leg("Left", -amp * s, maxf(0.0, -s) * 1.05 * speed_n + 0.04)
	_leg("Right", -amp * s2, maxf(0.0, -s2) * 1.05 * speed_n + 0.04)
	var bob := absf(sin(phase)) * 0.018 * speed_n
	model.position.y = -bob
	# head follows aim pitch
	var hi: int = bone["Head"]; var rh: Transform3D = rest[hi]
	skel.set_bone_global_pose(hi, Transform3D(Basis(Vector3.RIGHT, -pitch * 0.55) * rh.basis, rh.origin))
	if holding and weapon != null:
		var sd := 1.0
		# weapon pivot: right shoulder pocket, pitched with the aim; lowered when sprinting/reloading
		var pit := pitch + tilt - lower * 0.55
		wpivot.position = Vector3(-shoulder_x * 0.62, sh_y - 0.045 - lower * 0.10, sh_z + 0.27 - lower * 0.05)
		wpivot.basis = Basis(Vector3.RIGHT, -pit) * Basis(Vector3.UP, lower * 0.35)
		var g: Vector3 = weapon.def["grip"]; var f: Vector3 = weapon.def["left"]
		var tr: Vector3 = wpivot.global_transform * g
		var tl: Vector3 = wpivot.global_transform * f
		_ik_arm("Right", tr, Vector3(-0.6, -1.0, -0.4).rotated(Vector3.UP, 0.0))
		_ik_arm("Left", tl, Vector3(0.7, -1.0, -0.2))
