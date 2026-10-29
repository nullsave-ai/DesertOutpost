class_name ScopeView
extends Control
## Picture-in-picture scope: a SubViewport camera follows `anchor` (the weapon's ObjPoint marker) and is shown in a circular
## lens with a reticle. Zoom = base_fov / zoom. Usage: var sv := ScopeView.new(); sv.setup(weapon_marker, 4.0, 60.0); hud.add_child(sv)
const SHADER := """
shader_type canvas_item;
uniform float radius = 0.46;
uniform float ring = 0.012;
uniform vec4 reticle_col : source_color = vec4(0.05,0.05,0.05,1.0);
uniform float mil = 0.035;
uniform float thick = 0.0016;
uniform float vignette = 0.55;
uniform int style = 0; // 0 = duplex crosshair + chevron, 1 = mil-dot
float seg(vec2 p, vec2 a, vec2 b){ vec2 pa=p-a, ba=b-a; float h=clamp(dot(pa,ba)/dot(ba,ba),0.,1.); return length(pa-ba*h); }
void fragment(){
	vec2 p = UV - 0.5; float d = length(p);
	vec4 c = texture(TEXTURE, UV);
	float v = 1.0 - smoothstep(radius*vignette, radius, d);
	c.rgb *= mix(0.35, 1.0, v);
	float m = 0.0;
	if (style == 0) {
		m = max(m, 1.0 - smoothstep(thick, thick*1.8, min(seg(p, vec2(-radius*0.95,0), vec2(-0.03,0)), seg(p, vec2(0.03,0), vec2(radius*0.95,0)))));
		m = max(m, 1.0 - smoothstep(thick, thick*1.8, min(seg(p, vec2(0,radius*0.95), vec2(0,0.03)), seg(p, vec2(0,-0.03), vec2(0,-radius*0.95)))));
		m = max(m, 1.0 - smoothstep(thick*3.0, thick*4.0, d));
		for (int i=1;i<=4;i++){ float y = -float(i)*mil*1.6; m = max(m, 1.0 - smoothstep(thick, thick*1.8, seg(p, vec2(-0.014-0.004*float(i), y), vec2(0.014+0.004*float(i), y)))); }
	} else {
		m = max(m, 1.0 - smoothstep(thick, thick*1.8, seg(p, vec2(-radius*0.95,0), vec2(radius*0.95,0))));
		m = max(m, 1.0 - smoothstep(thick, thick*1.8, seg(p, vec2(0,radius*0.95), vec2(0,-radius*0.95))));
		for (int i=-10;i<=10;i++){ if(i==0) continue; float t = float(i)*mil; m = max(m, 1.0 - smoothstep(thick*2.2, thick*3.2, length(p-vec2(t,0)))); m = max(m, 1.0 - smoothstep(thick*2.2, thick*3.2, length(p-vec2(0,t)))); }
	}
	c.rgb = mix(c.rgb, reticle_col.rgb, m * reticle_col.a);
	float edge = smoothstep(radius, radius-0.004, d);
	float rim = smoothstep(radius-ring, radius-ring+0.004, d) * edge;
	c.rgb = mix(c.rgb, vec3(0.0), rim);
	COLOR = vec4(c.rgb, edge);
}
"""
const COLLIM := """
shader_type canvas_item;
uniform int style = 0; // 0 = red dot, 1 = holographic ring + dot
uniform vec4 col : source_color = vec4(1.0, 0.08, 0.04, 1.0);
uniform float dot_r = 0.0035;
uniform float ring_r = 0.085;
uniform float aspect = 1.0;
void fragment(){
	vec2 p = UV - 0.5; p.x *= aspect; float d = length(p); float a = 0.0;
	a = max(a, 1.0 - smoothstep(dot_r, dot_r * 1.6, d));
	a = max(a, 0.35 * (1.0 - smoothstep(dot_r * 1.6, dot_r * 4.5, d)));
	if (style == 1) {
		a = max(a, 1.0 - smoothstep(0.0016, 0.0030, abs(d - ring_r)));
		for (int i = 0; i < 4; i++) { float an = float(i) * 1.5707963; vec2 dir = vec2(cos(an), sin(an)); vec2 q = p - dir * (ring_r + 0.017); a = max(a, 1.0 - smoothstep(0.0014, 0.0026, length(vec2(dot(q, dir) * 0.35, dot(q, vec2(-dir.y, dir.x)))))); }
	}
	COLOR = vec4(col.rgb, a * col.a);
}
"""
var vp: SubViewport
var cam: Camera3D
var anchor: Node3D
var zoom := 4.0
var base_fov := 60.0
var _tex: TextureRect
var _mat: ShaderMaterial

func setup(anchor_: Node3D, zoom_ := 4.0, base_fov_ := 60.0, res := 512, style := 0) -> void:
	anchor = anchor_; zoom = zoom_; base_fov = base_fov_
	vp = SubViewport.new(); vp.size = Vector2i(res, res); vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS; vp.msaa_3d = Viewport.MSAA_2X; add_child(vp)
	cam = Camera3D.new(); cam.near = 0.05; cam.far = 600.0; cam.cull_mask = 0xFFFFF & ~2; vp.add_child(cam)
	_tex = TextureRect.new(); _tex.texture = vp.get_texture(); _tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; _tex.stretch_mode = TextureRect.STRETCH_SCALE
	_tex.set_anchors_preset(Control.PRESET_FULL_RECT); add_child(_tex)
	var sh := Shader.new(); sh.code = SHADER; _mat = ShaderMaterial.new(); _mat.shader = sh; _mat.set_shader_parameter("style", style); _tex.material = _mat
	mouse_filter = Control.MOUSE_FILTER_IGNORE; _tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_zoom(zoom)

## 1x sights (red dot / holographic): no magnification, just a collimated reticle drawn at the aim point.
func setup_collimator(style := 0) -> void:
	var r := ColorRect.new(); r.set_anchors_preset(Control.PRESET_FULL_RECT); r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sh := Shader.new(); sh.code = COLLIM; var m := ShaderMaterial.new(); m.shader = sh; m.set_shader_parameter("style", style); m.set_shader_parameter("aspect", size.x / maxf(size.y, 1.0)); r.material = m; add_child(r)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

## Put the weapon on render layer 2 (and keep layer 1) so the scope camera can ignore the weapon's own meshes.
static func tag_weapon(weapon: Node) -> void:
	for n in weapon.find_children("*", "VisualInstance3D", true, false): (n as VisualInstance3D).layers = 3

func set_active(on: bool) -> void:
	if vp: vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS if on else SubViewport.UPDATE_DISABLED

func set_zoom(z: float) -> void:
	zoom = z; if cam: cam.fov = rad_to_deg(2.0 * atan(tan(deg_to_rad(base_fov) * 0.5) / zoom))

func _process(_dt: float) -> void:
	if anchor and cam: cam.global_transform = Transform3D(anchor.global_transform.basis.orthonormalized() * Basis(Vector3.UP, PI), anchor.global_position)  # weapon fires toward +Z, Godot cameras look toward -Z
