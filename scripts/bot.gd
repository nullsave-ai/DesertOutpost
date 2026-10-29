class_name Bot
extends CharacterBody3D
## Enemy soldier: nav-mesh chase, line-of-sight check, burst fire with distance-based accuracy, headshots, fall-over death.
signal killed(bot: Bot, head: bool)
var rig: CharacterRig
var hp := 100.0
var max_hp := 100.0
var player: Player
var agent: NavigationAgent3D
var dead := false
var level := 1
var wr: WeaponRig
var _repath := 0.0
var _cd := 0.5
var _burst := 0
var _pause := 0.0
var _strafe := 0.0
var _strafe_t := 0.0
var _bar_fg: MeshInstance3D
var _bar: Node3D
var _speed := 3.6
var _yaw := 0.0
var _los := false
var _los_t := 0.0
var _flash_t := 0.0

func setup(p: Player, pos: Vector3, lvl: int) -> void:
	player = p; level = lvl; position = pos
	max_hp = 70.0 + 12.0 * lvl; hp = max_hp; _speed = 3.4 + minf(1.6, 0.12 * lvl) + randf() * 0.5; _strafe_t = randf() * 2.0
	collision_layer = 2; collision_mask = 1; floor_max_angle = deg_to_rad(52.0); floor_snap_length = 0.35
	var cs := CollisionShape3D.new(); var cap := CapsuleShape3D.new(); cap.radius = 0.34; cap.height = 1.85; cs.shape = cap; cs.position.y = 0.93; add_child(cs)
	rig = CharacterRig.new(); add_child(rig); rig.setup("res://art/Character/Soldier.glb")
	wr = WeaponRig.new(); rig.wpivot.add_child(wr); wr.build("BOT", 0); rig.weapon = wr
	agent = NavigationAgent3D.new(); agent.path_desired_distance = 0.8; agent.target_desired_distance = 1.5; agent.radius = 0.4; agent.height = 1.8; add_child(agent)
	# health bar
	_bar = Node3D.new(); _bar.position = Vector3(0, 2.18, 0); add_child(_bar)
	for k in 2:
		var mi := MeshInstance3D.new(); var q := QuadMesh.new(); q.size = Vector2(0.62, 0.07); mi.mesh = q
		var m := StandardMaterial3D.new(); m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED; m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED; m.no_depth_test = false
		m.albedo_color = Color(0.05, 0.05, 0.05, 0.8) if k == 0 else Color(0.9, 0.2, 0.15); m.render_priority = k; m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mi.material_override = m; mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF; _bar.add_child(mi)
		if k == 1: _bar_fg = mi; mi.position.z = 0.002

func take_hit(dmg: float, head: bool, _by: Node) -> bool:
	if dead: return false
	hp -= dmg; _flash_t = 0.12
	_bar_fg.scale.x = maxf(0.001, hp / max_hp); _bar_fg.position.x = -(1.0 - _bar_fg.scale.x) * 0.31
	if hp <= 0.0: _die(head); return true
	_los_t = 4.0   # got shot: stay aggressive
	return false

func _die(head: bool) -> void:
	dead = true; collision_layer = 0; _bar.visible = false; velocity = Vector3.ZERO
	killed.emit(self, head)
	var base_y := rig.rotation.y; var dirs := [-1.0, 1.0]; var s: float = dirs[randi() % 2]
	var tw := create_tween(); tw.tween_method(func(t: float): rig.basis = Basis(Vector3.UP, base_y) * Basis(Vector3.RIGHT, s * deg_to_rad(88.0) * t * t), 0.0, 1.0, 0.55)
	tw.tween_interval(3.0); tw.tween_callback(queue_free)

func _physics_process(dt: float) -> void:
	if dead:
		velocity.x = 0; velocity.z = 0; velocity.y -= 22.0 * dt; move_and_slide(); return
	if player == null or player.dead:
		velocity.x = move_toward(velocity.x, 0, 20 * dt); velocity.z = move_toward(velocity.z, 0, 20 * dt); velocity.y -= 22.0 * dt; move_and_slide(); rig.speed_n = 0.0; return
	var to_p := player.global_position - global_position; var flat := Vector3(to_p.x, 0, to_p.z); var dist := flat.length()
	_los_t = maxf(0.0, _los_t - dt)
	# line of sight (every 0.15 s)
	_repath -= dt
	if _repath <= 0.0:
		_repath = 0.35
		var eye := global_position + Vector3(0, 1.6, 0); var tgt := player.global_position + Vector3(0, 1.3, 0)
		var q := PhysicsRayQueryParameters3D.create(eye, tgt, 1); q.exclude = [get_rid()]
		_los = get_world_3d().direct_space_state.intersect_ray(q).is_empty() and dist < 60.0
		agent.target_position = player.global_position
	var engage := 24.0 + 3.0 * minf(level, 6)
	var want_stop := _los and dist < engage and dist > 6.0
	var dir := Vector3.ZERO
	if not want_stop:
		var nxt := agent.get_next_path_position(); var dn := nxt - global_position; dn.y = 0
		dir = dn.normalized() if (dn.length() > 0.15 and not agent.is_navigation_finished()) else flat.normalized()
		if dist < 5.0: dir = Vector3.ZERO
	else:
		_strafe_t -= dt
		if _strafe_t <= 0.0: _strafe_t = randf_range(0.8, 2.2); _strafe = [-1.0, 0.0, 1.0][randi() % 3]
		var side := Vector3(-flat.z, 0, flat.x).normalized(); dir = side * _strafe * 0.55
	var sp := _speed if not want_stop else 2.0
	velocity.x = move_toward(velocity.x, dir.x * sp, 30.0 * dt); velocity.z = move_toward(velocity.z, dir.z * sp, 30.0 * dt)
	velocity.y = (velocity.y - 22.0 * dt) if not is_on_floor() else maxf(velocity.y, -1.0)
	move_and_slide()
	# facing: toward player when engaging, else along the path
	var face := flat.normalized() if (want_stop or _los) else (Vector3(velocity.x, 0, velocity.z).normalized() if Vector2(velocity.x, velocity.z).length() > 0.3 else flat.normalized())
	var ty := atan2(-face.x, -face.z); _yaw = lerp_angle(_yaw, ty, clampf(dt * 8.0, 0.0, 1.0))
	rig.rotation.y = _yaw + PI
	rig.pitch = clampf(atan2(player.global_position.y + 1.3 - (global_position.y + 1.4), maxf(dist, 1.0)), -0.5, 0.5)
	rig.speed_n = clampf(Vector2(velocity.x, velocity.z).length() / 4.2, 0.0, 1.5); rig.run_n = clampf((Vector2(velocity.x, velocity.z).length() - 4.0) / 2.0, 0.0, 1.0)
	rig.lower = 0.0 if (want_stop or _los) else 0.6
	rig.animate(dt)
	# shooting
	_cd -= dt; _pause -= dt
	if want_stop and _pause <= 0.0 and _cd <= 0.0 and absf(angle_difference(_yaw, ty)) < 0.25:
		_cd = 0.14 + randf() * 0.08; _burst += 1
		if _burst >= 4 + randi() % 3: _burst = 0; _pause = maxf(0.7, 1.9 - 0.12 * level)
		_fire(dist)

func _fire(dist: float) -> void:
	var pa := clampf(0.95 - dist / 40.0, 0.08, 0.5) * (1.0 + 0.03 * level)
	var tgt := player.global_position + Vector3(0, 1.2, 0)
	var hit := randf() < pa * (0.65 if player.ads > 0.5 else 1.0)
	var end_pos := tgt if hit else tgt + Vector3(randf_range(-1.2, 1.2), randf_range(-0.8, 0.8), randf_range(-1.2, 1.2))
	var mp := wr.muzzle.global_position
	Fx.tracer(get_tree().current_scene, mp, end_pos, 0.01, Color(1.0, 0.35, 0.25, 0.8))
	Fx.muzzle_flash(wr.muzzle, false)
	Sfx.play3d(get_tree().current_scene, mp, "bot", -4.0, randf_range(0.9, 1.1))
	if hit: player.take_damage(3.0 + 0.5 * level, global_position)
