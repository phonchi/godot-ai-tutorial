shader_type canvas_item;
// Two slow, soft light pools over a dark garden, plus a vignette.

uniform vec4 base_color : source_color = vec4(0.063, 0.188, 0.176, 1.0);
uniform vec4 warm_light : source_color = vec4(0.965, 0.769, 0.325, 1.0);
uniform vec4 cool_light : source_color = vec4(0.498, 0.847, 0.745, 1.0);

float pool(vec2 uv, vec2 center, float radius) {
	vec2 stretched = (uv - center) * vec2(1.6, 1.0);
	return smoothstep(radius, 0.0, length(stretched));
}

void fragment() {
	float t = TIME * 0.15;
	vec2 warm_center = vec2(0.32 + 0.12 * sin(t * 1.3), 0.38 + 0.10 * cos(t * 1.1));
	vec2 cool_center = vec2(0.70 + 0.10 * cos(t * 0.9), 0.64 + 0.12 * sin(t * 1.7));
	vec3 color = base_color.rgb;
	color += warm_light.rgb * pool(UV, warm_center, 0.55) * 0.22;
	color += cool_light.rgb * pool(UV, cool_center, 0.6) * 0.18;
	float vignette = smoothstep(0.95, 0.35, length(UV - 0.5));
	color *= mix(0.55, 1.0, vignette);
	COLOR = vec4(color, 1.0);
}
