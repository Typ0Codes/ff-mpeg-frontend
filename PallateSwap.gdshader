shader_type canvas_item;
uniform vec4 src_color : source_color;
uniform vec4 target_color : source_color;
uniform float tolerance : hint_range(0.0, 1.0) = 0.1;

void fragment() {
    vec4 current_color = texture(TEXTURE, UV);
    
    if (distance(current_color.rgb, src_color.rgb) <= tolerance) {
        COLOR = vec4(target_color.rgb, current_color.a);
    } else {
        COLOR = current_color;
    }
}   