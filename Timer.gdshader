shader_type spatial;

// Color principal
uniform vec3 base_color : source_color = vec3(2, 0.0, 0.0);
// Efecto de borde
uniform float rim_power : hint_range(0.1, 10.0) = 2.0;
uniform float rim_intensity : hint_range(0.0, 1.0) = 0.5;
uniform vec3 rim_color : source_color = vec3(1.0, 0.3, 0.2);
// Propiedades de material
uniform float roughness : hint_range(0, 1) = 0.7;
uniform float metallic : hint_range(0, 1) = 0.1;

void fragment() {
    // Cálculo del efecto de borde (rim light)
    float rim = 1.0 - dot(NORMAL, VIEW);
    rim = pow(rim, rim_power);
    vec3 rim_effect = rim_color * rim * rim_intensity;

    // Color base con sombras (Godot 4 maneja sombras automáticamente)
    ALBEDO = base_color;

    // Añadir efecto de borde
    EMISSION = rim_effect;

    // Propiedades de material para sombras y reflejos
    METALLIC = metallic;
    ROUGHNESS = roughness;
    SPECULAR = 0.5;
}