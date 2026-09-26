shader_type canvas_item;


void fragment() {
	float v = length(vec2(0.5) - UV);
	float f = fwidth(v);
	//COLOR.a *= v;
	COLOR.a *= smoothstep(v - f, v, 0.5);
}
