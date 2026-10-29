shader_type spatial;
render_mode cull_disabled;
uniform float wind_strength = 1.0;
vec3 map_wind(vec3 P, float w, float strength) {
	float t = TIME;
	float ph = P.x * 0.35 + P.z * 0.27;
	P.x += (sin(t * 1.7 + ph) * 0.16 * strength + sin(t * 3.1 + ph * 2.3) * 0.04) * w;
	P.z += cos(t * 1.3 + ph * 1.3) * 0.10 * w * strength;
	return P;
}
void vertex() {
	vec3 wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wp = map_wind(wp, COLOR.a, wind_strength);
	VERTEX = (inverse(MODEL_MATRIX) * vec4(wp, 1.0)).xyz;
}
void fragment() { ALBEDO = COLOR.rgb; ROUGHNESS = 0.85; METALLIC = 0.0; }
