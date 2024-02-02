shader_type canvas_item;

uniform float slices = 1024.0;
uniform float yphase = 32.0;
uniform float xmax = 0.5;

vec3 noise(float p) {
	return fract(sin(p*131.3)*vec3(918312.0, 31714.0, 1143.0));
}

void fragment() {
	vec2 uv = SCREEN_UV;
	float bucket = slices + floor(slices*0.5*sin(uv.y*yphase));
	vec3 n = noise(bucket);
	vec3 x = fract(vec3(uv.x + 1.0) + n*xmax);
	float r = texture(SCREEN_TEXTURE, vec2(x.x, uv.y)).r;
	float g = texture(SCREEN_TEXTURE, vec2(x.y, uv.y)).g;
	float b = texture(SCREEN_TEXTURE, vec2(x.z, uv.y)).b;
	COLOR = vec4(r,g,b, 1.0);
}