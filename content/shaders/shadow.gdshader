shader_type canvas_item;


global uniform vec4 SHADOW_COLOR;

uniform sampler2D SCREEN_TEXTURE: hint_screen_texture, filter_nearest;


void fragment() {
	vec3 screen = texture(SCREEN_TEXTURE, SCREEN_UV).rgb;
	COLOR.rgb = mix(screen, SHADOW_COLOR.rgb, SHADOW_COLOR.a);
}