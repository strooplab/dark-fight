shader_type spatial;

uniform float porcentaje : hint_range(0.0, 1.0) = 0.5;

void fragment() {
	METALLIC = 0.0;
	ROUGHNESS = 0.2;

	vec3 color_inicio = vec3(0.0, 1.0, 0.0);   // Verde
	vec3 color_medio  = vec3(1.0, 1.0, 0.0);   // Amarillo
	vec3 color_final  = vec3(1.0, 0.0, 0.0);   // Rojo

	vec3 color_barra;

	if (porcentaje < 0.5) {
		color_barra = mix(color_final, color_medio, porcentaje * 2.0);
	} else {
		color_barra = mix(color_medio, color_inicio, (porcentaje - 0.5) * 2.0);
	}

	float sombra = UV.y * 0.3;

	vec3 efecto_3d = color_barra - sombra;
	efecto_3d = clamp(efecto_3d, 0.0, 1.0);

	if (UV.x < porcentaje) {
		ALBEDO = efecto_3d;
	} else {
		ALBEDO = vec3(0.0);
	}
}
