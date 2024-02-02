shader_type spatial;
render_mode async_visible,blend_mix,depth_draw_opaque,unshaded,cull_back;

uniform sampler2D texture_albedo : hint_albedo;
uniform vec3 grid_scale = vec3(1.0, 1.0, 1.0);
uniform vec3 grid_line = vec3(0.1, 0.1, 0.1);
uniform vec4 grid_cell_color : hint_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform vec4 grid_line_color : hint_color = vec4(0.2, 0.1, 0.1, 1.0);
uniform float cull_y = 0.0;

void fragment() {
	vec3 ows = WORLD_MATRIX[3].xyz;
	vec4 vws = CAMERA_MATRIX * vec4(VERTEX, 1.0);
	if(vws.y < cull_y) {
		discard;
	}

	vec4 vcs = PROJECTION_MATRIX * vec4(VERTEX, 1.0);
	vcs /= vcs.w;

	vec3 hws = vec3(vcs.x + vcs.y * 0.3 - TIME * 0.1, vcs.y - vcs.x * 0.7, 1.0) * 20.0;

    vec3 on_grid = smoothstep(vec3(0.0), grid_line, fract(hws.xyz / grid_scale));
    on_grid = 2.0 * max(0.5-on_grid, on_grid-0.5); // Give the line a smooth falloff in each side
    float cellness = min(on_grid.x, min(on_grid.y, on_grid.z));
    cellness = 1.0 - (cellness*cellness*cellness*cellness); // Sharpen & invert

	vec4 gc = grid_line_color * smoothstep(-1.0, -0.1, vcs.y); // Hacky clip space fade

	vec3 tex = texelFetch(texture_albedo,ivec2(ceil(1024.0 * UV)), 0).rgb;
	ALBEDO = mix(tex.rgb, mix(grid_cell_color, gc, cellness).rgb, 1.0 - tex.r);
}
