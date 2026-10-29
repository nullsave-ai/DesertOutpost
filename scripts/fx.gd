class_name Fx
## Cheap combat effects (tracer, impact puff, muzzle flash). No textures, no particles shaders: fine for the Compatibility renderer.
static var _mat_tracer: StandardMaterial3D
static var _mat_flash: StandardMaterial3D

static func _tracer_mat() -> StandardMaterial3D:
	if _mat_tracer == null:
		_mat_tracer = StandardMaterial3D.new(); _mat_tracer.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED; _mat_tracer.albedo_color = Color(1.0, 0.86, 0.45)
		_mat_tracer.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return _mat_tracer

static func tracer(parent: Node, a: Vector3, b: Vector3, width := 0.012, col := Color(1.0, 0.86, 0.45, 0.9)) -> void:
	var d := b - a; var len_ := d.length()
	if len_ < 0.5: return
	var mi := MeshInstance3D.new(); var bm := BoxMesh.new(); bm.size = Vector3(width, width, minf(len_, 6.0))
	mi.mesh = bm; var m := _tracer_mat().duplicate() as StandardMaterial3D; m.albedo_color = col; mi.material_override = m; mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	var dir := d / len_; var start := a; var end_ := b - dir * minf(len_, 6.0) * 0.5
	mi.global_position = a + dir * minf(len_, 6.0) * 0.5
	mi.look_at(b, Vector3.UP if absf(dir.y) < 0.95 else Vector3.RIGHT)
	var tw := mi.create_tween(); tw.tween_property(mi, "global_position", end_, 0.07); tw.parallel().tween_property(m, "albedo_color:a", 0.0, 0.07); tw.tween_callback(mi.queue_free)

static func impact(parent: Node, pos: Vector3, normal: Vector3, col := Color(0.82, 0.7, 0.5)) -> void:
	var p := CPUParticles3D.new(); p.one_shot = true; p.emitting = true; p.amount = 7; p.lifetime = 0.45; p.explosiveness = 1.0
	p.direction = normal; p.spread = 55.0; p.initial_velocity_min = 1.5; p.initial_velocity_max = 4.0; p.gravity = Vector3(0, -9.0, 0)
	var sm := SphereMesh.new(); sm.radius = 0.025; sm.height = 0.05; sm.radial_segments = 4; sm.rings = 2; p.mesh = sm
	var m := StandardMaterial3D.new(); m.albedo_color = col; m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED; p.material_override = m
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(p); p.global_position = pos + normal * 0.02
	var t := Timer.new(); t.wait_time = 0.8; t.one_shot = true; t.autostart = true; p.add_child(t); t.timeout.connect(p.queue_free)

static func muzzle_flash(muzzle: Node3D, strong := true) -> void:
	var f: Node3D = muzzle.get_node_or_null("Flash")
	if f == null:
		f = Node3D.new(); f.name = "Flash"; muzzle.add_child(f)
		if _mat_flash == null:
			_mat_flash = StandardMaterial3D.new(); _mat_flash.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED; _mat_flash.albedo_color = Color(1.0, 0.8, 0.4)
			_mat_flash.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA; _mat_flash.blend_mode = BaseMaterial3D.BLEND_MODE_ADD; _mat_flash.cull_mode = BaseMaterial3D.CULL_DISABLED
		for k in 2:
			var q := MeshInstance3D.new(); var qm := QuadMesh.new(); qm.size = Vector2(0.22, 0.22); q.mesh = qm; q.material_override = _mat_flash
			q.rotation_degrees = Vector3(0, 90 * k, 0) if k == 0 else Vector3(90, 0, 0); q.position = Vector3(0, 0, 0.08); q.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF; f.add_child(q)
		f.rotation_degrees = Vector3(0, 0, 0)
	f.visible = true; f.scale = Vector3.ONE * (1.0 if strong else 0.6); f.rotation.z = randf() * TAU
	var tm: SceneTreeTimer = muzzle.get_tree().create_timer(0.045); tm.timeout.connect(func(): if is_instance_valid(f): f.visible = false)
