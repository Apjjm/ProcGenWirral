shader_type spatial;
render_mode blend_mix,diffuse_burley,specular_disabled,depth_draw_opaque,unshaded;

uniform sampler2D texture_albedo : hint_albedo;
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

	vec4 albedo_tex = texture(texture_albedo,UV);
	ALBEDO = albedo_tex.rgb;
}
