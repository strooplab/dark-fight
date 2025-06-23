shader_type spatial;
render_mode unshaded, cull_disabled;

// Aseguramos que el color base sea negro usando vec3
uniform vec3 base_color = vec3(0); // Negro absoluto en RGB
uniform vec4 highlight_color = vec4(1.0, 0.85, 0.5, 1.0); // Luz dorada con alpha

uniform float light_width = 0.2;
uniform float light_speed = 0.7;
uniform float light_strength = 1.0;

void fragment() {
    float light_pos = mod(TIME * light_speed, 2.0);
    float light_line = UV.x + UV.y;

    float dist = abs(light_line - light_pos);
    float light = smoothstep(light_width, 0.0, dist);

    // Mezcla directa con vec3 para el color base
    vec3 final_rgb = mix(base_color, highlight_color.rgb, light * light_strength);

    ALBEDO = final_rgb; // Usamos el vec3 resultante
    ALPHA = highlight_color.a; // Alpha del highlight o podrías usar 1.0
}