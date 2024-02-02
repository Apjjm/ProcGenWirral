shader_type spatial;
render_mode blend_mix,depth_draw_alpha_prepass,diffuse_burley,specular_schlick_ggx,shadows_disabled;

uniform float base_freq = 64.0;
uniform float speed = 1.0;
uniform float height = 4.0;
uniform float r_scale = 4.0;
uniform float e_scale = 1.0;
uniform float alpha = 1.0;
uniform vec3 color1 = vec3(1.0, 1.0, 1.0);
uniform vec3 color2 = vec3(1.0, 1.0, 1.0);

float hash(vec2 p) {
	float n = dot(p, vec2(99.1,287.2));
	return fract(sin(n)*918312.1);
}

float noise(vec2 x) {
	vec2 p = floor(x);
	vec2 w = fract(x);

	float a = hash(p+vec2(0,0));
	float b = hash(p+vec2(1,0));
	float c = hash(p+vec2(0,1));
	float d = hash(p+vec2(1,1));

	vec2 blur = smoothstep(0.0, 1.0, w);

	return mix(a, b, blur.x) + (c-a) * blur.y * (1.0 - blur.x) + (d-b) * blur.x * blur.y;
}

float fbm(vec2 x) {    
	float freq = base_freq;
	float amp = 1.0;
	
	float result = 0.0;
	result += amp*noise(freq*x); freq*=2.0; amp*=0.7;
	result += amp*noise(freq*x); freq*=2.0; amp*=0.7;
	result += amp*noise(freq*x); freq*=2.0; amp*=0.7;
	result += amp*noise(freq*x); freq*=2.0; amp*=0.7;

	return result;
}

void fragment() {
	float depth = texture(DEPTH_TEXTURE, SCREEN_UV).x;
	vec3 ndc = vec3(SCREEN_UV, depth) * 2.0 - 1.0;
 	vec4 hit = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	vec4 rws = CAMERA_MATRIX * vec4(hit.xyz / hit.w, 1.0);
	vec4 vws = CAMERA_MATRIX * vec4(VERTEX, 1.0);
	  
	vec2 uv = UV - vec2(0.5);
	float r = dot(uv, uv) * r_scale;
	float theta = atan(uv.x, uv.y) + 0.1 * TIME * speed;
	float s = fbm(r * vec2(cos(theta), sin(theta))) * height * 0.5;
	float h = s - 2.0 * (min(r * height * e_scale, 1.0) - 1.0);

	ALPHA = alpha * (1.0 - clamp((rws.y + h - vws.y) / s, 0.0, 1.0));
	ALBEDO = vec3(mix(color1, color2, 0.5 * s / height));
}