shader_type canvas_item;

uniform vec4 color1 : source_color = vec4(0.1, 0.0, 0.3, 1.0);
uniform vec4 color2 : source_color = vec4(0.0, 0.8, 0.9, 1.0);
uniform float speed = 0.5;
uniform float range = 0.3; // how far it swings (0.0 - 1.0)

void fragment() {
    float offset = sin(TIME * speed) * range;
    float t = clamp(UV.x + offset, 0.0, 1.0);
    COLOR = mix(color1, color2, t);
}   