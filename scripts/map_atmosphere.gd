class_name MapAtmosphere
extends Node3D
## Port of MapAtmosphere.cs: golden-hour sun, procedural sky, haze fog, ACES + glow + adjustments. Everything built in code.
func _ready() -> void:
	var sun := DirectionalLight3D.new(); sun.name = "Sun"
	# Unity Euler(38,-35,0) -> forward (-0.452,-0.616,+0.645); Godot z is mirrored
	sun.light_color = Color(1.0, 0.86, 0.68); sun.light_energy = 0.85
	sun.shadow_enabled = true; sun.directional_shadow_max_distance = 95.0; sun.shadow_blur = 1.5
	add_child(sun); sun.look_at_from_position(Vector3.ZERO, Vector3(-0.452, -0.616, -0.645))
	var env := Environment.new(); var sky := Sky.new(); var pm := ProceduralSkyMaterial.new()
	pm.sky_top_color = Color(0.30, 0.46, 0.78); pm.sky_horizon_color = Color(0.78, 0.74, 0.66); pm.ground_horizon_color = Color(0.74, 0.69, 0.60); pm.ground_bottom_color = Color(0.62, 0.52, 0.38)
	pm.sun_angle_max = 8.0; sky.sky_material = pm
	env.background_mode = Environment.BG_SKY; env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY; env.ambient_light_energy = 0.45
	env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	env.tonemap_mode = Environment.TONE_MAPPER_ACES; env.tonemap_exposure = 0.75
	env.fog_enabled = true; env.fog_light_color = Color(0.74, 0.69, 0.60); env.fog_density = 0.0030; env.fog_sky_affect = 0.4
	env.glow_enabled = true; env.glow_intensity = 0.12; env.glow_hdr_threshold = 1.1
	env.adjustment_enabled = true; env.adjustment_contrast = 1.08; env.adjustment_saturation = 1.0
	var we := WorldEnvironment.new(); we.environment = env; add_child(we)
