extends Node3D
## Game flow: map + atmosphere + nav mesh, menu with a live character preview, wave survival against nav-mesh bots.
var map: MapLoader
var sun: DirectionalLight3D
var player: Player
var hud: HUD
var menu: GameMenu
var nav: NavigationRegion3D
var bots: Array[Bot] = []
var wave := 0
var score := 0
var playing := false
var to_spawn := 0
var spawn_cd := 0.0
var wave_gap := 0.0
var max_alive := 4
var start_pos := Vector3(0, 0.6, -36)
var start_yaw := PI
var _args := {}

func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		var kv = a.trim_prefix("--").split("=", true, 1); _args[kv[0]] = kv[1] if kv.size() == 2 else "1"
	Cfg.load_cfg()
	map = MapLoader.new(); map.lights = Cfg.quality >= 1; add_child(map)
	var atm := MapAtmosphere.new(); add_child(atm); sun = atm.get_node("Sun")
	Cfg.apply_quality(get_viewport(), sun)
	if ResourceLoader.exists("res://art/Map/nav.res"):
		nav = NavigationRegion3D.new(); nav.navigation_mesh = load("res://art/Map/nav.res"); add_child(nav)
	if map.spawns.has("Spawn_Gate"): start_pos = map.spawns["Spawn_Gate"] + Vector3(0, 0.4, 0)
	var d := Vector3(0, 0, 0) - start_pos; start_yaw = atan2(-d.x, -d.z)
	player = Player.new(); add_child(player); player.global_position = start_pos; player.yaw = start_yaw
	hud = HUD.new(); add_child(hud); hud.set_player(player); player.hud = hud; hud.visible = false
	hud.pause_pressed.connect(_pause)
	player.died.connect(_on_player_died); player.hit_confirm.connect(func(k, h): hud.hit_marker(k, h))
	menu = GameMenu.new(); add_child(menu); menu.show_main()
	menu.play.connect(_start); menu.resume.connect(_resume); menu.to_menu.connect(_to_menu); menu.retry.connect(_start)
	menu.char_changed.connect(func(): player.change_character(); player.hud = hud; hud.set_player(player))
	menu.quality_changed.connect(func(): Cfg.apply_quality(get_viewport(), sun))
	if _args.has("autotest"): _autotest.call_deferred(str(_args["autotest"]))

func _start() -> void:
	_clear_bots(); wave = 0; score = 0; menu.visible = false; hud.visible = true; get_tree().paused = false
	player.heal_full(); player.global_position = start_pos; player.velocity = Vector3.ZERO; player.yaw = start_yaw; player.pitch = 0.0
	player._build_weapons(); player.hud = hud; hud.set_player(player); player.active = true; playing = true; player.ads_want = false
	if not DisplayServer.is_touchscreen_available() and not hud.touch_mode: Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_next_wave()

func _clear_bots() -> void:
	for b in bots: if is_instance_valid(b): b.queue_free()
	bots.clear()

func _next_wave() -> void:
	wave += 1; to_spawn = mini(3 + wave * 2, 20); max_alive = mini(3 + wave, 9); spawn_cd = 1.5
	hud.banner("WAVE %d" % wave, "%d enemies" % to_spawn); hud.update_status(wave, score, to_spawn + bots.size())

func _pause() -> void:
	if not playing or get_tree().paused: return
	get_tree().paused = true; Input.mouse_mode = Input.MOUSE_MODE_VISIBLE; menu.show_pause()

func _resume() -> void:
	get_tree().paused = false; menu.visible = false
	if not hud.touch_mode: Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _to_menu() -> void:
	get_tree().paused = false; playing = false; player.active = false; _clear_bots(); hud.visible = false; Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if player.scoped: player.hud.set_scope(player, false)
	player.heal_full(); player.global_position = start_pos; menu.show_main()

func _on_player_died() -> void:
	playing = false; Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var nb := wave > Cfg.best_wave or score > Cfg.best_score
	Cfg.best_wave = maxi(Cfg.best_wave, wave); Cfg.best_score = maxi(Cfg.best_score, score); Cfg.save_cfg()
	if player.scoped: hud.set_scope(player, false)
	await get_tree().create_timer(1.6).timeout
	menu.show_gameover(wave, score, nb)

func _spawn_point() -> Vector3:
	var pts: Array[Vector3] = []
	for k in map.spawns: pts.append(map.spawns[k])
	var far: Array[Vector3] = []
	for p in pts:
		if p.distance_to(player.global_position) > 32.0: far.append(p)
	var p: Vector3 = far[randi() % far.size()] if not far.is_empty() else pts[randi() % pts.size()]
	p += Vector3(randf_range(-3, 3), 0.3, randf_range(-3, 3))
	if nav != null:
		var m := nav.get_navigation_map()
		if NavigationServer3D.map_get_iteration_id(m) > 0: p = NavigationServer3D.map_get_closest_point(m, p) + Vector3(0, 0.1, 0)
	return p

func _on_bot_killed(b: Bot, head: bool) -> void:
	score += 150 if head else 100; player.kills += 1; bots.erase(b)
	hud.update_status(wave, score, to_spawn + bots.size())

func _process(dt: float) -> void:
	if not playing: return
	bots = bots.filter(func(b): return is_instance_valid(b))
	if not player.dead:
		if to_spawn > 0:
			spawn_cd -= dt
			if spawn_cd <= 0.0 and bots.size() < max_alive:
				spawn_cd = 1.6; to_spawn -= 1
				var b := Bot.new(); add_child(b); b.setup(player, _spawn_point(), wave); b.killed.connect(_on_bot_killed); bots.append(b)
				hud.update_status(wave, score, to_spawn + bots.size())
		elif bots.is_empty() and wave_gap <= 0.0:
			wave_gap = 5.0; hud.banner("WAVE %d CLEARED" % wave, "next wave in 5 s", 3.5)
		if wave_gap > 0.0:
			wave_gap -= dt
			if wave_gap <= 0.0: _next_wave()

func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed and e.keycode == KEY_P and playing: _pause()

# ------------------------------------------------------------------ headless/xvfb scripted checks (args: --autotest=name --out=/tmp/at)
func _shot(n: String) -> void:
	await get_tree().process_frame; await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png("%s_%s.png" % [_args.get("out", "/tmp/at"), n]); print("shot ", n)

func _wait(s: float) -> void: await get_tree().create_timer(s).timeout

func _autotest(name_: String) -> void:
	await _wait(2.0)
	if name_ == "menu":
		await _shot("menu"); await _wait(1.0); menu.b_char.pressed.emit(); await _wait(1.5); await _shot("menu2")
	else:
		menu.play.emit(); await _wait(1.0)
		player.yaw = start_yaw; player.pitch = -0.05
		await _wait(1.0); await _shot("tps")
		if name_ == "walk":
			player.velocity = Vector3(0, 0, 0)
			for i in 3: await _wait(0.5); await _shot("w%d" % i)
		if name_ == "combat":
			hud.fire_held = true
			for i in 4:
				await _wait(1.5); await _shot("c%d" % i); print("DBG mags ", player.mags, " cd ", player.fire_cd, " spr ", player.sprinting, " rl ", player.reload_t, " swap ", player.swap_t, " fire ", hud.fire_held, " bots ", bots.size(), " hp ", player.hp)
		if name_ == "bot":
			to_spawn = 0; wave_gap = 99.0
			var fwd := Vector3(-sin(player.yaw), 0, -cos(player.yaw))
			for k in 3:
				var b := Bot.new(); add_child(b); b.setup(player, player.global_position + fwd * (12.0 + k * 3.0) + Vector3(-3.0 + 3.0 * k, 0.3, 0), 1); b.killed.connect(_on_bot_killed); bots.append(b)
			await _wait(2.0); await _shot("b0")
			player.pitch = 0.0; hud.fire_held = true
			for i in 3: await _wait(1.2); await _shot("b%d" % (i + 1)); print("DBG bots ", bots.size(), " score ", score, " hp ", player.hp)
		if name_ == "touch":
			to_spawn = 0; wave_gap = 99.0
			var tp := func(idx: int, pos: Vector2, down: bool): var e := InputEventScreenTouch.new(); e.index = idx; e.position = pos; e.pressed = down; Input.parse_input_event(e)
			var dr := func(idx: int, pos: Vector2, rel: Vector2): var e := InputEventScreenDrag.new(); e.index = idx; e.position = pos; e.relative = rel; Input.parse_input_event(e)
			tp.call(0, Vector2(1130, 550), true); await _wait(0.2); print("DBG fire_held ", hud.fire_held); tp.call(0, Vector2(1130, 550), false); await _wait(0.2); print("DBG fire_held after ", hud.fire_held)
			tp.call(1, Vector2(150, 560), true); dr.call(1, Vector2(150, 480), Vector2(0, -80)); await _wait(0.3); print("DBG stick ", hud.move_vec, " player vel ", player.velocity)
			var y0 := player.yaw; tp.call(2, Vector2(700, 300), true); dr.call(2, Vector2(780, 300), Vector2(80, 0)); await _wait(0.3); print("DBG yaw delta ", player.yaw - y0)
			tp.call(2, Vector2(780, 300), false); tp.call(1, Vector2(150, 480), false)
			var m0: int = player.mags[0]; tp.call(3, Vector2(1130, 550), true); dr.call(3, Vector2(1160, 540), Vector2(30, -10)); await _wait(0.6); print("DBG fire+drag mags ", m0, "->", player.mags[0], " yaw ", player.yaw); tp.call(3, Vector2(1160, 540), false)
			tp.call(4, Vector2(985, 615), true); tp.call(4, Vector2(985, 615), false); await _wait(0.5); print("DBG aim toggled ", player.ads_want, " ads ", player.ads); await _shot("touch_ads")
			tp.call(5, Vector2(1175, 335), true); tp.call(5, Vector2(1175, 335), false); await _wait(0.1)
			tp.call(6, Vector2(900, 550), true); tp.call(6, Vector2(900, 550), false); await _wait(0.2); print("DBG swap cur ", player.cur)
		if name_ == "pose":
			to_spawn = 0; wave_gap = 99.0
			hud.stick.vec = Vector2(0, -0.6); player.rig.run_n = 0.0
			for i in 4:
				await _wait(0.35)
				var c := player.global_position + Vector3(0, 1.0, 0); var side := Vector3(cos(player.yaw), 0, -sin(player.yaw))
				player.cam_override = Transform3D(Basis.looking_at(-side * 1.0, Vector3.UP), c + side * 3.2 + Vector3(0, 0.1, 0)); await _shot("p%d" % i)
			hud.stick.vec = Vector2(0, -1.0); await _wait(0.8)
			var c2 := player.global_position + Vector3(0, 1.0, 0); var side2 := Vector3(cos(player.yaw), 0, -sin(player.yaw))
			player.cam_override = Transform3D(Basis.looking_at(-side2, Vector3.UP), c2 + side2 * 3.2 + Vector3(0, 0.1, 0)); await _shot("sprint")
			hud.stick.vec = Vector2.ZERO; await _wait(0.5)
			var f := Vector3(-sin(player.yaw), 0, -cos(player.yaw)); var c3 := player.global_position + Vector3(0, 1.4, 0)
			player.cam_override = Transform3D(Basis.looking_at(-(side2 * 0.5 + f * 0.9), Vector3.UP), c3 + (side2 * 0.5 + f * 0.9) * 1.6); await _shot("front")
		if name_ == "ads":
			player.ads_want = true; await _wait(1.0); await _shot("ads_ar")
			player.ads_want = false; player.swap_weapon(); await _wait(1.0); player.ads_want = true; await _wait(1.5); await _shot("ads_sniper")
			player.cycle_optic(); await _wait(0.5); await _shot("ads_sniper2")
	await _wait(0.5); get_tree().quit()
