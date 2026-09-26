shader_type canvas_item;


uniform float invert_intensity : hint_range(0.0, 1.0) = 0.0;
uniform vec4 flash_color : source_color = vec4(1.0, 1.0, 1.0, 0.0);
uniform float desaturate : hint_range(0.0, 1.0) = 0.0;


void fragment() {
	COLOR.rgb = mix(COLOR.rgb, 1.0 - COLOR.rgb, invert_intensity);
	COLOR.rgb = mix(COLOR.rgb, flash_color.rgb, COLOR.a*flash_color.a);
	float gray = dot(COLOR.rgb, vec3(0.299, 0.587, 0.114));
	COLOR.rgb = mix(COLOR.rgb, vec3(gray) * 0.7, desaturate);
}