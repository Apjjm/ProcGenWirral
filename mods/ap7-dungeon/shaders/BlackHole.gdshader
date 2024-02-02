shader_type spatial;
render_mode unshaded, shadows_disabled, depth_draw_always;

uniform vec3 radii = vec3(3.0, 4.0, 9.0); //Inner radius, Swirl radius, lensing radius respectively
uniform vec2 pulse = vec2(4.0, 6.0);
uniform vec4 swirl_color : hint_color = vec4(1.0, 1.0, 0.8, 1.0);
uniform sampler2D swirl_noise : hint_albedo;

float singularity_d2(vec3 ro, vec3 rd, vec3 so) {
	// Basically just distance squared to a point
	vec3 z = so-ro;
	float z2 = dot(z, z);
	float x2 = dot(z, rd)*dot(z, rd);
	return z2 - x2;
}

// Assume we are on a sphere object, with the origin in model space
void fragment() {
	float tl_slow = sin(TIME * 1.0);
	float tl_fast = sin(TIME * 6.0);
	
	vec3 ows = WORLD_MATRIX[3].xyz + vec3(0.0, tl_slow, 0.0);
	vec3 vws = (CAMERA_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec3 ro = CAMERA_MATRIX[3].xyz;
	vec3 rd = normalize(vws - ro); // There has to be a better way to get this??
	float d2 = singularity_d2(ro, rd, ows);

	vec4 ndc = PROJECTION_MATRIX * INV_CAMERA_MATRIX * vec4(ows, 1.0);
	ndc /= ndc.w;
	vec2 ouv = (ndc.xy + vec2(1.0)) * 0.5;

	vec3 r2 = radii * radii + vec3(tl_slow * pulse.x, tl_fast * pulse.y, 0.0);
	float hole = 1.0 - step(r2.x, d2);
	float swirl = 1.0 - smoothstep(r2.x, r2.y, d2);
	float lensing = 1.0 - smoothstep(r2.x, r2.z, d2);
	
	vec2 lens_uv = mix(SCREEN_UV, ouv, lensing);
	vec3 lens_col = texture(SCREEN_TEXTURE, lens_uv).rgb;
	vec2 swirl_uv = vec2(0.5) + vec2(tl_slow, sin(d2 * swirl * 0.1)) * 0.08; // Trial and error formula tuned to a specific input texture
	vec3 swirl_col = swirl_color.rgb * swirl * texture(swirl_noise, swirl_uv).r * 1.2;

	ALBEDO = mix(clamp(lens_col + swirl_col, 0.0, 1.0), vec3(0.0), hole);
}