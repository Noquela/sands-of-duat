shader_type canvas_item;

// Egyptian Cel-Shade Shader para Sands of Duat
// Estilo toon shading com paleta inspirada no antigo Egito

varying vec3 world_position;
varying vec3 world_normal;
varying vec2 uv_coords;

uniform float toon_levels : hint_range(1.0, 10.0) = 4.0;
uniform float toon_smoothness : hint_range(0.0, 1.0) = 0.1;
uniform vec3 main_color : source_color = vec3(0.8, 0.7, 0.5);
uniform vec3 shadow_color : source_color = vec3(0.4, 0.3, 0.2);
uniform vec3 highlight_color : source_color = vec3(1.0, 0.9, 0.7);

uniform float rim_power : hint_range(0.0, 10.0) = 2.0;
uniform vec3 rim_color : source_color = vec3(1.0, 0.8, 0.3);
uniform float rim_intensity : hint_range(0.0, 2.0) = 0.5;

uniform float metallic : hint_range(0.0, 1.0) = 0.0;
uniform float roughness : hint_range(0.0, 1.0) = 0.8;
uniform float specular : hint_range(0.0, 1.0) = 0.5;

uniform sampler2D texture_albedo : source_color, hint_default_white;
uniform sampler2D texture_normal : hint_roughness_normal;

// Egyptian-inspired noise for subtle texture variation
float egyptian_noise(vec2 uv) {
    return fract(sin(dot(uv, vec2(12.9898, 78.233))) * 43758.5453);
}

// Quantize lighting to create toon effect
float toon_lighting(float light_value) {
    float level = floor(light_value * toon_levels) / toon_levels;
    return smoothstep(level - toon_smoothness, level + toon_smoothness, light_value);
}

// Egyptian hieroglyph pattern (subtle overlay)
float hieroglyph_pattern(vec2 uv) {
    vec2 grid = fract(uv * 8.0);
    float pattern = step(0.8, max(grid.x, grid.y));
    return pattern * 0.05; // Very subtle
}

void vertex() {
    world_position = VERTEX;
    world_normal = NORMAL;
    uv_coords = UV;
}

void fragment() {
    // Base texture sampling
    vec4 albedo_tex = texture(texture_albedo, uv_coords);
    vec3 base_color = main_color * albedo_tex.rgb;
    
    // Normal mapping (optional)
    vec3 normal = world_normal;
    if (texture_size(texture_normal) != uvec2(0)) {
        vec3 normal_map = texture(texture_normal, uv_coords).rgb;
        normal_map = normalize(normal_map * 2.0 - 1.0);
        // Simple normal application (should be in view space for proper lighting)
        normal = normalize(normal + normal_map * 0.5);
    }
    
    // Light direction (assume main directional light)
    vec3 light_dir = normalize(vec3(0.5, 1.0, 0.5)); // Egyptian sun angle
    
    // Calculate lighting
    float ndotl = dot(normal, light_dir);
    float light_intensity = max(0.0, ndotl);
    
    // Apply toon quantization
    float toon_light = toon_lighting(light_intensity);
    
    // Mix colors based on lighting
    vec3 lit_color = mix(shadow_color, base_color, toon_light);
    lit_color = mix(lit_color, highlight_color, toon_light * toon_light);
    
    // Rim lighting for dramatic effect
    vec3 view_dir = normalize(vec3(0.0, 0.0, 1.0)); // Simplified view direction
    float rim_dot = 1.0 - dot(normal, view_dir);
    float rim_effect = pow(rim_dot, rim_power);
    rim_effect = step(0.6, rim_effect) * rim_intensity;
    
    vec3 final_color = lit_color + (rim_color * rim_effect);
    
    // Add subtle Egyptian texture variation
    float noise = egyptian_noise(uv_coords * 32.0) * 0.02;
    float hieroglyph = hieroglyph_pattern(uv_coords);
    final_color += noise + hieroglyph;
    
    // Output
    ALBEDO = final_color;
    METALLIC = metallic;
    ROUGHNESS = roughness;
    SPECULAR = specular;
    ALPHA = albedo_tex.a;
}