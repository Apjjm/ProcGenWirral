shader_type spatial;
render_mode unshaded, shadows_disabled, depth_draw_never;

uniform vec3 scale = vec3(1.0, 1.0, 1.0);
uniform vec2 thresholds = vec2(0.1, 0.2);
uniform float power = 0.1;
uniform float ngonality = 1.0;
uniform float speed = 4.0;
uniform float clip_depth = 1.0;

vec3 noise(vec3 p) {
	float n = dot(p, vec3(99.1,287.2,131.3));
	return fract(sin(n)*vec3(918312, 31714, 1143));
}

vec4 sample_voronoi(vec3 n, vec3 f, vec4 res, vec3 cell_offset) {
	vec3 offset = noise(n+cell_offset);
	vec3 r = cell_offset+(offset*ngonality)-f;
	float d = dot(r, r);
	return d<res.w ? vec4(offset,d) : res;
}

vec4 voronoi(vec3 p) {
	vec3 n = floor(p);
	vec3 f = fract(p);
	vec4 res = vec4(0.0,0.0,0.0,10.0);
	for(int z=-1; z<1; ++z) {
		res = sample_voronoi(n, f, res, vec3(-1.0, -1.0, float(z)));
		res = sample_voronoi(n, f, res, vec3(-1.0, 0.0, float(z)));
		res = sample_voronoi(n, f, res, vec3(-1.0, 1.0, float(z)));
		res = sample_voronoi(n, f, res, vec3(0.0, -1.0, float(z)));
		res = sample_voronoi(n, f, res, vec3(0.0, 0.0, float(z)));
		res = sample_voronoi(n, f, res, vec3(0.0, 1.0, float(z)));
		res = sample_voronoi(n, f, res, vec3(1.0, -1.0, float(z)));
		res = sample_voronoi(n, f, res, vec3(1.0, 0.0, float(z)));
		res = sample_voronoi(n, f, res, vec3(1.0, 1.0, float(z)));
	}
	return res;
}

void fragment() {
	float depth = texture(DEPTH_TEXTURE, SCREEN_UV).x;
	vec3 ndc = vec3(SCREEN_UV, depth) * 2.0 - 1.0;
 	vec4 hit = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	vec4 rws = CAMERA_MATRIX * vec4(hit.xyz / hit.w, 1.0);
	vec4 vws = CAMERA_MATRIX * vec4(VERTEX, 1.0);

	// Only apply the effet on the sprite just behind the glitch effect
	if(rws.y < 0.1 || abs(rws.z-vws.z) > clip_depth) {
		discard;
	} 
	
	vec3 vin = (vws.xyz - vec3(0.0, 20.0 * floor(TIME * speed), 0.0)) * scale;
	vec4 vout = voronoi(vin);
	float str = abs(cos(dot(vout.xyz, vec3(99.1,287.2,131.3))));
	if(str > thresholds.y) {
		discard;
	}
	
	float mid = 0.5*(thresholds.y-thresholds.x);
	float p = (str < thresholds.x) ? -power : power;
	vec2 uv = SCREEN_UV-p * sin(vout.xy + vout.zx);
	vec3 col = texture(SCREEN_TEXTURE, uv).rgb;
		
	ALBEDO = (str < thresholds.x + mid * sign(p)) ? col : 0.2*vec3(col.x+col.y+col.z);
}