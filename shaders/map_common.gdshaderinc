// Port of Assets/Shaders/MapCommon.hlsl (Unity URP) to Godot 4 shading language.
// The map GLB has no textures: COLOR_0.rgb = tint, COLOR_0.a*32 = material id (structures) or splat weights (terrain).
// glTF z = -Unity z, so all triplanar math is done in "Unity space" (z negated) to reproduce the exact same look.
uniform sampler2DArray albedo_arr : filter_linear_mipmap_anisotropic, repeat_enable;   // rgb albedo, a roughness (linear)
uniform sampler2DArray normal_arr : filter_linear_mipmap_anisotropic, repeat_enable;   // rg normal xy, b AO (linear)
uniform vec4 base_color : source_color = vec4(1.0);

varying vec3 v_wpos;
varying vec3 v_wnrm;

const float MAP_SC[16] = float[16](6.0, 5.0, 1.6, 3.0, 3.0, 2.5, 2.0, 2.0, 1.6, 2.0, 4.0, 3.0, 0.6, 1.5, 1.0, 1.0);
const float MAP_MT[16] = float[16](0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.35, 0.0, 0.3, 0.0, 0.0, 0.0, 0.45, 0.0, 0.0);

struct MapSm { vec3 a; float r; vec3 n; float ao; };
struct MapSurf { vec3 albedo; float rough; float metal; float ao; vec3 N; vec3 emis; float clipv; };

vec4 MapAraw(vec2 uv, float id) { return texture(albedo_arr, vec3(uv, id)); }
// the reference previews work in display space: albedo = texture * vertex tint (both sRGB-like), decoded once at the end (map_albedo)
vec3 map_albedo(vec3 a) { return a; }   // raw values (linear), same as the Unity arrays
vec4 MapA(vec2 uv, float id) { return texture(albedo_arr, vec3(uv, id)); }
vec4 MapN(vec2 uv, float id) { return texture(normal_arr, vec3(uv, id)); }
vec3 MapTsn(vec4 t) { vec2 xy = t.xy * 2.0 - 1.0; return vec3(xy, sqrt(max(0.0, 1.0 - dot(xy, xy)))); }

MapSm MapTri(float id, vec3 p, vec3 N, vec3 w) {
	float s = MAP_SC[int(id)];
	vec2 ux = p.zy / s, uy = p.xz / s, uz = p.xy / s;
	vec4 ax = MapA(ux, id), ay = MapA(uy, id), az = MapA(uz, id);
	vec4 nx = MapN(ux, id), ny = MapN(uy, id), nz = MapN(uz, id);
	vec3 sg = sign(N);
	vec3 tx = MapTsn(nx), ty = MapTsn(ny), tz = MapTsn(nz);
	vec3 nX = vec3(0.0, tx.y, tx.x * sg.x);
	vec3 nY = vec3(ty.x, 0.0, ty.y * sg.y);
	vec3 nZ = vec3(tz.x * sg.z, tz.y, 0.0);
	MapSm r;
	r.n = normalize(N + nX * w.x + nY * w.y + nZ * w.z);
	r.a = ax.rgb * w.x + ay.rgb * w.y + az.rgb * w.z;
	r.r = ax.a * w.x + ay.a * w.y + az.a * w.z;
	r.ao = nx.b * w.x + ny.b * w.y + nz.b * w.z;
	return r;
}

// planar XZ layer with anti-tiling (two rotated samples blended by a low-frequency mask)
MapSm MapPlanar(float id, vec3 p, vec3 N) {
	float sc = MAP_SC[int(id)];
	vec2 q = p.xz / sc;
	vec2 q2 = vec2(0.8 * p.x + 0.6 * p.z, -0.6 * p.x + 0.8 * p.z) / (sc * 0.43) + vec2(0.37, 0.11);
	float bl = smoothstep(0.3, 0.7, MapAraw(p.xz / 53.0, 2.0).r);
	float m = 0.5 * bl + 0.25;
	vec4 a = mix(MapA(q, id), MapA(q2, id), m);
	vec4 n = mix(MapN(q, id), MapN(q2, id), m);
	vec3 t = MapTsn(n);
	MapSm s; s.a = a.rgb; s.r = a.a; s.n = normalize(N + vec3(t.x, 0.0, t.y)); s.ao = n.b;
	return s;
}

MapSurf MapSurfaceStructure(vec3 p, vec3 N, vec4 vc, float dist) {
	float id = min(floor(vc.a * 32.0 + 0.001), 31.0);
	vec3 w = pow(abs(N), vec3(8.0)); w /= (w.x + w.y + w.z);
	MapSm s = MapTri(min(id, 13.0), p, N, w);
	MapSurf o; o.clipv = 1.0; o.emis = vec3(0.0);
	o.albedo = s.a * vc.rgb; o.rough = s.r; o.ao = s.ao; o.N = s.n; o.metal = MAP_MT[int(min(id, 13.0))];
	if (id > 13.5 && id < 14.5) {            // chain-link fence: diamond lattice from world position, clipped between the wires
		vec3 hh = normalize(cross(vec3(0.0, 1.0, 0.0), N)); float u = dot(p, hh);
		float aa = (u + p.y) / 0.055, bb = (u - p.y) / 0.055;
		float da = min(fract(aa), 1.0 - fract(aa)), db = min(fract(bb), 1.0 - fract(bb));
		float th = clamp(0.10 + dist * 0.006, 0.10, 0.42);
		o.clipv = th - min(da, db);
		o.albedo = vc.rgb * 0.75; o.rough = 0.45; o.metal = 0.6; o.ao = 1.0; o.N = N;
	} else if (id > 14.5 && id < 15.5) {     // emissive lamp glass / LEDs / screens
		o.albedo = vc.rgb; o.rough = 0.3; o.metal = 0.0; o.ao = 1.0; o.N = N; o.emis = vc.rgb * 2.2;
	} else if (id > 15.5 && id < 16.5) {     // glass
		o.albedo = vc.rgb; o.rough = 0.07; o.metal = 0.0; o.ao = 1.0; o.N = N;
	} else if (id > 16.5 && id < 17.5) {     // rubber
		o.albedo = vc.rgb; o.rough = 0.88; o.metal = 0.0; o.ao = 1.0; o.N = N;
	} else if (id > 17.5) {                  // glossy vehicle paint
		o.albedo = vc.rgb; o.rough = 0.26; o.metal = 0.0; o.ao = 1.0; o.N = N;
	}
	return o;
}

MapSurf MapSurfaceTerrain(vec3 p, vec3 N, vec4 Wn, float dist) {
	vec3 w = pow(abs(N), vec3(6.0)); w /= (w.x + w.y + w.z);
	MapSm s1 = MapTri(1.0, p, N, w);
	float steep = smoothstep(0.30, 0.62, 1.0 - N.y);
	MapSm s0 = MapPlanar(0.0, p, N);
	MapSm s2 = MapPlanar(2.0, p, N);
	MapSm s3 = MapPlanar(3.0, p, N);
	if (steep > 0.01) {
		MapSm t0 = MapTri(0.0, p, N, w);
		MapSm t2 = MapTri(2.0, p, N, w);
		s0.a = mix(s0.a, t0.a, steep); s0.r = mix(s0.r, t0.r, steep); s0.ao = mix(s0.ao, t0.ao, steep); s0.n = mix(s0.n, t0.n, steep);
		s2.a = mix(s2.a, t2.a, steep); s2.r = mix(s2.r, t2.r, steep); s2.ao = mix(s2.ao, t2.ao, steep); s2.n = mix(s2.n, t2.n, steep);
	}
	vec3 acc = s0.a * Wn.x + s1.a * Wn.y + s2.a * Wn.z + s3.a * Wn.w;
	float rr = s0.r * Wn.x + s1.r * Wn.y + s2.r * Wn.z + s3.r * Wn.w;
	float aoa = s0.ao * Wn.x + s1.ao * Wn.y + s2.ao * Wn.z + s3.ao * Wn.w;
	vec3 nn = s0.n * Wn.x + s1.n * Wn.y + s2.n * Wn.z + s3.n * Wn.w;
	float mac = MapAraw(p.xz / 97.0, 3.0).r;
	float mac2 = MapAraw(p.xz / 41.0, 1.0).r;
	float det = MapAraw(p.xz / 0.9, 0.0).r;
	acc *= (0.62 + 1.1 * mac * (0.5 + mac2)) * mix(1.0, 0.6 + 0.9 * det, clamp(1.0 - dist / 40.0, 0.0, 1.0));
	MapSurf o; o.albedo = acc; o.rough = rr; o.ao = aoa; o.N = normalize(nn); o.metal = 0.0; o.emis = vec3(0.0); o.clipv = 1.0;
	return o;
}

// converts a Unity-space normal back to Godot world space and then to view space for NORMAL
vec3 map_to_view(vec3 nu, mat4 view) {
	vec3 nw = vec3(nu.x, nu.y, -nu.z);
	return normalize((view * vec4(nw, 0.0)).xyz);
}
