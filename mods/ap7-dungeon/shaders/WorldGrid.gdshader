shader_type spatial;
render_mode blend_mix,diffuse_burley,specular_disabled,depth_draw_opaque;

uniform vec3 grid_scale = vec3(2.0, 2.0, 2.0);
uniform vec3 grid_line = vec3(0.1, 0.1, 0.1);
uniform vec4 grid_cell_color : hint_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform vec4 grid_line_color : hint_color = vec4(1.0);
uniform vec4 grid_line_emission : hint_color = vec4(1.0);
uniform float grid_glow_yfactor = -0.02;
uniform float grid_glow_tfactor = 1.0;
uniform vec3 fade_origin = vec3(0.0, 0.0, 0.0);
uniform vec4 fade_oiio = vec4(0.0, 30.0, 70.0, 100.0); // radius for fade out -> in & in -> out

float hacky_dither(vec3 x) {
	return fract(dot(vec3(0.4142136, 0.730951, 0.242097), x));
}

void fragment() {
	vec4 vws = CAMERA_MATRIX * vec4(VERTEX, 1.0);
	
	// Fade in/out w/ positon of some origin point
	vec3 dws = vws.xyz - fade_origin;
	vec4 f2 = fade_oiio * fade_oiio;
	float d = dot(dws, dws);
	float fade = smoothstep(f2.x, f2.y, d)-smoothstep(f2.z, f2.w, d);
	if(fade < hacky_dither(dws)) {
		discard;
	}

	//vec3 on_grid = step(grid_line, fract(vws.xyz / grid_scale));
	vec3 on_grid = smoothstep(vec3(0.0), grid_line, fract(vws.xyz / grid_scale));
	on_grid = 2.0 * max(0.5-on_grid, on_grid-0.5); // Give the line a smooth falloff in each side
	float cellness = min(on_grid.x, min(on_grid.y, on_grid.z));
	cellness = 1.0 - (cellness*cellness*cellness*cellness); // Sharpen & invert

	// Grid glow over time
	float glow = 0.5*(1.0 + sin(grid_glow_yfactor*vws.y + TIME*grid_glow_tfactor));
	glow = glow*glow*glow*glow*glow;

	ALBEDO = mix(grid_cell_color, grid_line_color, cellness).rgb;
	EMISSION = mix(vec4(0.0), grid_line_emission*glow, cellness).rgb;
}