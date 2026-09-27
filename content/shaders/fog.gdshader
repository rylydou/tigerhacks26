shader_type canvas_item;


uniform vec2 resolution = vec2(100.0, 100.0);
uniform vec2 uv_aspect = vec2(1.0, 1.0);
uniform vec2 noise_scroll = vec2(0.0, 0.0);
uniform sampler2D noise_remap : filter_nearest, repeat_disable;

group_uniforms NoiseA;
uniform vec2 noise_a_scroll = vec2(0.0, 0.0);
uniform sampler2D noise_a : filter_linear, repeat_enable;
uniform sampler2D noise_a_remap : filter_linear, repeat_disable;
uniform sampler2D noise_a_density : filter_linear, repeat_disable;

group_uniforms NoiseB;
uniform vec2 noise_b_scroll = vec2(0.0, 0.0);
uniform sampler2D noise_b : filter_linear, repeat_enable;
uniform sampler2D noise_b_remap : filter_linear, repeat_disable;
uniform sampler2D noise_b_density : filter_linear, repeat_disable;


float remap_noise(float value, sampler2D remap, sampler2D density, vec2 uv) {
	return texture(remap, vec2(value, 0.0)).r * texture(density, uv).r;
}


float sample_noise(sampler2D noise, sampler2D remap, sampler2D density, vec2 uv, vec2 scroll) {
	return remap_noise(texture(noise, scroll).r, remap, density, uv);
}


void fragment() {
	vec2 uv = floor(UV * resolution) / resolution;
	vec2 aspect_uv = uv * uv_aspect;

	float layer_a = sample_noise(noise_a, noise_a_remap, noise_a_density, uv, aspect_uv + noise_scroll * TIME + noise_a_scroll * TIME);
	float layer_b = sample_noise(noise_b, noise_b_remap, noise_b_density, uv, aspect_uv + noise_scroll * TIME + noise_b_scroll * TIME);

	COLOR *= texture(noise_remap, vec2(layer_a + layer_b, 0.0));
	//COLOR.r = layer_a;
	//COLOR.g = 0.0;
	//COLOR.b = layer_b;
}
