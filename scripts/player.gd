class_name Player
extends CharacterBody3D
## Third-person shooter controller: touch / keyboard movement, over-the-shoulder camera, ADS (first-person through the sight or scope PIP),
## two weapons (AR-9 with swappable optics, LR-7 sniper), recoil, reload, health regen. Layers: world=1, bots=2, player=4.
signal died
signal damaged(amount: float)
signal hit_confirm(kill: bool, head: bool)

var rig: CharacterRig
var cam: Camera3D
var hud: HUD
var weapons: Array[WeaponRig] = []
var cur := 0
var mags := [30, 5]
var reload_t := 0.0
var swap_t := 0.0
var fire_cd := 0.0
var hp := 100.0
var max_hp := 100.0
var since_hit := 99.0
var yaw := 0.0
var pitch := 0.0
var ads := 0.0
var ads_want := false
var kick_pool := 0.0
var active := false
var dead := false
var sprinting := false
var scoped := false
var kills := 0
var _cam_pos := Vector3.ZERO
var _orbit := 0.0
var _body_hidden := false
var _shake := 0.0
var _bob_phase := 0.0
var _trigger_prev := false
var cam_override = null   # debug: Transform3D to force the camera

func _ready() -> void:
	collision_layer = 4; collision_mask = 1
	floor_max_angle = deg_to_rad(52.0); floor_snap_length = 0.35; floor_constant_speed = true
	var cs := CollisionShape3D.new(); var cap := CapsuleShape3D.new(); cap.radius = 0.32; cap.height = 1.75; cs.shape = cap; cs.position.y = 0.875; add_child(cs)
	rig = CharacterRig.new(); add_child(rig); rig.setup(Cfg.char_path()); ScopeView.tag_weapon(rig.model)
	cam = Camera3D.new(); cam.fov = 68; cam.far = 600; cam.near = 0.06; cam.top_level = true; add_child(cam); cam.current = true
	_build_weapons()

func _build_weapons() -> void:
	for w in weapons: w.queue_free()
	weapons.clear()
	var a := WeaponRig.new(); a.hide_from_scope = true; rig.wpivot.add_child(a); a.build("AR9", Cfg.optic_ar)
	var b := WeaponRig.new(); b.hide_from_scope = true; rig.wpivot.add_child(b); b.build("LR7", 0)
	weapons = [a, b]; mags = [a.def["mag"], b.def["mag"]]
	_select(0, true)

func change_character() -> void:
	var rot := rig.rotation
	rig.queue_free(); rig = CharacterRig.new(); add_child(rig); rig.setup(Cfg.char_path()); ScopeView.tag_weapon(rig.model); rig.rotation = rot
	_build_weapons(); _body_hidden = false

func weapon() -> WeaponRig: return weapons[cur]

func _select(i: int, instant := false) -> void:
	cur = i
	for k in weapons.size(): weapons[k].visible = (k == cur)
	rig.weapon = weapons[cur]; reload_t = 0.0; swap_t = 0.0 if instant else 0.45; rig.tilt = 0.0
	if hud: hud.set_weapon_info(self)

func swap_weapon() -> void:
	if dead or swap_t > 0.0: return
	_select(1 - cur); ads_want = false

func cycle_optic() -> void:
	var w := weapon(); w.cycle_optic()
	if w.def_name == "AR9": Cfg.optic_ar = w.optic_index
	if hud: hud.set_weapon_info(self); hud.scope_refresh(self)
	Sfx.play(self, "click", -6.0, 1.3)

func reload() -> void:
	var w := weapon()
	if reload_t > 0.0 or swap_t > 0.0 or mags[cur] >= int(w.def["mag"]) or dead: return
	reload_t = float(w.def["reload"]); ads_want = false; Sfx.play(self, "reload", -3.0)

func take_damage(n: float, from: Vector3 = Vector3.ZERO) -> void:
	if dead or not active: return
	hp -= n; since_hit = 0.0; _shake = 0.5
	Sfx.play(self, "hurt", -4.0); damaged.emit(n)
	if hud: hud.damage_flash(from_dir(from))
	if hp <= 0.0: hp = 0.0; dead = true; ads_want = false; died.emit()

func from_dir(p: Vector3) -> float:
	if p == Vector3.ZERO: return 0.0
	var d := p - global_position; d.y = 0.0
	if d.length() < 0.1: return 0.0
	var fwd := Vector3(-sin(yaw), 0, -cos(yaw)); return fwd.signed_angle_to(d.normalized(), Vector3.UP)

func heal_full() -> void: hp = max_hp; dead = false

func _unhandled_input(e: InputEvent) -> void:
	if not active or dead: return
	if e is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var s := 0.0024 * Cfg.sens * _sens_scale(); yaw -= e.relative.x * s; pitch = clampf(pitch - e.relative.y * s, -1.3, 1.2)
	elif e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED and not DisplayServer.is_touchscreen_available():
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_RIGHT and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		ads_want = e.pressed if not (weapon().optic_kind == "none") else false
	elif e is InputEventKey and e.pressed and not e.echo:
		match e.keycode:
			KEY_R: reload()
			KEY_Q: swap_weapon()
			KEY_E: cycle_optic()
			KEY_ESCAPE: Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _sens_scale() -> float:
	var w := weapon(); return 1.0 / pow(maxf(1.0, w.zoom), 0.75) if ads > 0.5 and w.optic_kind == "pip" else (0.8 if ads > 0.5 else 1.0)

func _input_move() -> Vector2:
	var v := Vector2.ZERO
	if hud and hud.touch_mode: v = hud.move_vec
	if Input.is_key_pressed(KEY_W): v.y -= 1.0
	if Input.is_key_pressed(KEY_S): v.y += 1.0
	if Input.is_key_pressed(KEY_A): v.x -= 1.0
	if Input.is_key_pressed(KEY_D): v.x += 1.0
	return v.limit_length(1.0)

func _fire_pressed() -> bool:
	var f := (hud != null and hud.fire_held)
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT): f = true
	return f

func _physics_process(dt: float) -> void:
	since_hit += dt
	if active and not dead:
		if since_hit > 5.0 and hp < max_hp: hp = minf(max_hp, hp + 9.0 * dt)
		var mv := _input_move()
		if hud and hud.touch_mode:
			yaw -= hud.look.x * 0.0036 * Cfg.sens * _sens_scale(); pitch = clampf(pitch - hud.look.y * 0.0036 * Cfg.sens * _sens_scale(), -1.3, 1.2); hud.look = Vector2.ZERO
			if hud.consume("jump") and is_on_floor(): velocity.y = 7.0
			if hud.consume("reload"): reload()
			if hud.consume("swap"): swap_weapon()
			if hud.consume("optic"): cycle_optic()
			if hud.consume("aim"):
				if weapon().optic_kind != "none" and reload_t <= 0.0: ads_want = not ads_want
		else:
			if Input.is_key_pressed(KEY_SPACE) and is_on_floor(): velocity.y = 7.0
		sprinting = (Input.is_key_pressed(KEY_SHIFT) or (hud != null and hud.touch_mode and mv.length() > 0.96)) and mv.y < -0.2 and ads < 0.2 and reload_t <= 0.0 and not _fire_pressed()
		var sp := 6.4 if sprinting else (2.3 if ads > 0.5 else 4.2)
		var d := Basis(Vector3.UP, yaw) * Vector3(mv.x, 0, mv.y)
		velocity.x = move_toward(velocity.x, d.x * sp, 40.0 * dt); velocity.z = move_toward(velocity.z, d.z * sp, 40.0 * dt)
		_weapon_logic(dt)
	else:
		velocity.x = move_toward(velocity.x, 0.0, 30.0 * dt); velocity.z = move_toward(velocity.z, 0.0, 30.0 * dt)
	velocity.y = (velocity.y - 22.0 * dt) if not is_on_floor() else maxf(velocity.y, -1.0)
	move_and_slide()
	if global_position.y < -40.0: global_position = global_position * Vector3(0, 0, 0) + Vector3(0, 3, 0)

func _weapon_logic(dt: float) -> void:
	var w := weapon(); var wd: Dictionary = w.def
	fire_cd = maxf(0.0, fire_cd - dt); swap_t = maxf(0.0, swap_t - dt)
	if reload_t > 0.0:
		reload_t -= dt; rig.tilt = -0.5 * sin(PI * clampf(1.0 - reload_t / float(wd["reload"]), 0.0, 1.0))
		if reload_t <= 0.0: reload_t = 0.0; mags[cur] = int(wd["mag"]); rig.tilt = 0.0; if hud: hud.set_weapon_info(self)
	var trig := _fire_pressed()
	if trig and swap_t <= 0.0 and reload_t <= 0.0 and fire_cd <= 0.0 and not sprinting:
		if mags[cur] <= 0: reload()
		elif bool(wd["auto"]) or not _trigger_prev: _shoot(w)
	_trigger_prev = trig
	# recoil recovery
	if kick_pool > 0.0:
		var rec := minf(kick_pool, dt * (0.10 + kick_pool * 3.0)); kick_pool -= rec; pitch -= rec * 0.55
	rig.lower = move_toward(rig.lower, 1.0 if sprinting else 0.0, dt * 5.0)

func _shoot(w: WeaponRig) -> void:
	var wd: Dictionary = w.def
	fire_cd = 60.0 / float(wd["rpm"]); mags[cur] -= 1
	var moving := Vector2(velocity.x, velocity.z).length() > 0.5
	var spread: float = float(wd["spread"]) * (1.0 + (0.0 if ads > 0.5 else 1.8) + (1.2 if moving else 0.0) + (0.8 if not is_on_floor() else 0.0))
	var from := cam.global_position; var fw := -cam.global_transform.basis.z
	var up := cam.global_transform.basis.y; var rt := cam.global_transform.basis.x
	var dir := (fw + rt * randf_range(-spread, spread) + up * randf_range(-spread, spread)).normalized()
	var q := PhysicsRayQueryParameters3D.create(from + fw * 0.2, from + dir * 500.0, 3); q.exclude = [get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	var muzzle_pos := w.muzzle.global_position
	var end_pos: Vector3 = hit["position"] if not hit.is_empty() else from + dir * 300.0
	if ads > 0.9 and w.optic_kind != "none": muzzle_pos = muzzle_pos + (end_pos - muzzle_pos).normalized() * 0.2
	Fx.tracer(get_tree().current_scene, muzzle_pos, end_pos, 0.012 if w.def_name == "AR9" else 0.02)
	Fx.muzzle_flash(w.muzzle, w.def_name == "LR7")
	Sfx.play(self, str(wd["snd"]), -2.0, randf_range(0.96, 1.04))
	if not hit.is_empty():
		var col: Object = hit["collider"]
		if col != null and col.has_method("take_hit"):
			var head: bool = float(hit["position"].y) > col.global_position.y + 1.52
			var dmg := float(wd["dmg"]) * (2.0 if head else 1.0)
			var killed: bool = col.take_hit(dmg, head, self)
			hit_confirm.emit(killed, head); Fx.impact(get_tree().current_scene, hit["position"], hit["normal"], Color(0.8, 0.12, 0.1))
			Sfx.play(self, "kill" if killed else "hit", -4.0)
		else: Fx.impact(get_tree().current_scene, hit["position"], hit["normal"])
	var rc := float(wd["recoil"]); pitch += rc; yaw += randf_range(-0.35, 0.35) * rc; kick_pool += rc; _shake = maxf(_shake, 0.2 if w.def_name == "AR9" else 0.9)
	if hud: hud.set_weapon_info(self); hud.vibrate(20 if w.def_name == "AR9" else 50)

func _process(dt: float) -> void:
	if rig == null: return
	var w := weapon()
	if active:
		ads = move_toward(ads, 1.0 if (ads_want and not dead) else 0.0, dt * (6.0 if w.def_name == "AR9" else 4.5))
		if reload_t > 0.0 or sprinting: ads_want = false
	else: ads = 0.0
	var hv := Vector2(velocity.x, velocity.z).length()
	rig.speed_n = clampf(hv / 4.2, 0.0, 1.6) if is_on_floor() else 0.0; rig.run_n = clampf((hv - 4.2) / 2.2, 0.0, 1.0)
	rig.pitch = pitch
	rig.rotation.y = yaw + PI
	rig.animate(dt)
	_update_camera(dt)
	var want_scope := ads > 0.94 and w.optic_kind == "pip" and active and not dead
	if want_scope != scoped:
		scoped = want_scope
		if hud: hud.set_scope(self, scoped)
	var hide_body := ads > 0.55
	if hide_body != _body_hidden: _body_hidden = hide_body; rig.set_body_visible(not hide_body)
	if hud:
		var show_collim := ads > 0.9 and w.optic_kind == "collim" and active
		hud.show_collimator(show_collim, w.collim_style())

func _update_camera(dt: float) -> void:
	var w := weapon()
	if not active:
		_orbit += dt * 0.35
		var c := global_position + Vector3(0, 1.1, 0); var a := _orbit + 0.6
		var p := c + Vector3(sin(a) * 3.3, 0.45, cos(a) * 3.3)
		cam.global_transform = Transform3D(Basis.looking_at(c - p + Vector3(0, 0.1, 0), Vector3.UP), p); cam.fov = 45.0; return
	var b := Basis(Vector3.UP, yaw) * Basis(Vector3.RIGHT, pitch)
	var head := global_position + Vector3(0, 1.55, 0)
	var tps := head + b * Vector3(0.62, 0.12, 2.5)
	var q := PhysicsRayQueryParameters3D.create(head, tps, 1); q.exclude = [get_rid()]
	var h := get_world_3d().direct_space_state.intersect_ray(q)
	if not h.is_empty(): tps = h["position"] + (head - h["position"]).normalized() * 0.25
	var pos := tps; var basis_ := b
	if ads > 0.001:
		var eye := w.global_transform * (w.eye_local + Vector3(0, 0, -0.01))
		pos = tps.lerp(eye, smoothstep(0.0, 1.0, ads))
	if _shake > 0.0:
		_shake = maxf(0.0, _shake - dt * 4.0); var sh := _shake * (0.004 if ads > 0.5 else 0.012)
		pos += b * Vector3(randf_range(-sh, sh), randf_range(-sh, sh), 0)
	cam.global_transform = Transform3D(basis_, pos)
	if cam_override != null: cam.global_transform = cam_override
	var fov_t := 68.0
	if ads > 0.0: fov_t = lerpf(68.0, 52.0 if w.optic_kind == "collim" else 60.0, smoothstep(0.0, 1.0, ads))
	if rig.lower > 0.5: fov_t += 6.0 * rig.lower
	cam.fov = lerpf(cam.fov, fov_t, clampf(dt * 12.0, 0.0, 1.0))
