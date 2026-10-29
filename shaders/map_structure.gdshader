shader_type spatial;
render_mode cull_back;
#include "res://shaders/map_common.gdshaderinc"
void vertex() {
	v_wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_wnrm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}
void fragment() {
	vec3 pu = vec3(v_wpos.x, v_wpos.y, -v_wpos.z);
	vec3 Nu = normalize(vec3(v_wnrm.x, v_wnrm.y, -v_wnrm.z));
	MapSurf s = MapSurfaceStructure(pu, Nu, COLOR, distance(v_wpos, CAMERA_POSITION_WORLD));
	if (s.clipv < 0.0) discard;
	ALBEDO = map_albedo(s.albedo * base_color.rgb); ROUGHNESS = clamp(s.rough, 0.04, 1.0); METALLIC = s.metal; AO = s.ao; AO_LIGHT_AFFECT = 0.6;
	NORMAL = map_to_view(s.N, VIEW_MATRIX); EMISSION = s.emis;
}
