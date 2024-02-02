shader_type spatial;
render_mode blend_mix,diffuse_burley,specular_disabled;

uniform vec3 grid_scale = vec3(2.0, 2.0, 2.0);
uniform vec3 grid_line = vec3(0.1, 0.1, 0.1);
uniform vec4 grid_cell_color : hint_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform vec4 grid_line_color : hint_color = vec4(1.0);
uniform vec4 grid_line_emission : hint_color = vec4(1.0);
uniform float grid_glow_yfactor = -0.02;
uniform float grid_glow_tfactor = 1.0;

void fragment() {
	vec4 vws = CAMERA_MATRIX * vec4(VERTEX, 1.0);

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