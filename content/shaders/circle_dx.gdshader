shader_type canvas_item;

uniform float radius: hint_range(0.0, 1.0) = 1.;
uniform float border: hint_range(0.0, 1.0) = .1;

void fragment() {
	const vec2 center = vec2(.5, .5);
	float s = SCREEN_PIXEL_SIZE.x*4.;

	float l = length(UV - center);
	float a = smoothstep(s, 0.0, abs(l - radius*.5 + border*.25 + s) - border*.25);
	float x = smoothstep(radius - border, radius, l*2.);
	COLOR.a *= a*x;
}