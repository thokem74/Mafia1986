shader_type canvas_item;

void fragment() {
	vec4 terrain = texture(TEXTURE, UV);
	// Only the non-playable outer border blends into the surrounding rooftops.
	vec2 border = min(UV, vec2(1.0) - UV) * vec2(32.0, 24.0);
	terrain.a *= smoothstep(0.0, 0.9, min(border.x, border.y));
	COLOR = terrain;
}
