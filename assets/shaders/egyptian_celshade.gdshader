// Egyptian Cel-Shade Shader
// Optimized for Sands of Duat 3D Isometric Style
// Inspired by Hades artistic direction with Egyptian aesthetics

shader_type canvas_item;
render_mode blend_mix,depth_draw_opaque,cull_disabled,diffuse_burley,specular_schlick_ggx;

uniform float cel_levels : hint_range(1.0, 10.0) = 4.0;
uniform float rim_power : hint_range(0.1, 10.0) = 2.0;
uniform vec4 rim_color : source_color = vec4(1.0, 0.8, 0.4, 1.0);
uniform float outline_thickness : hint_range(0.0, 0.1) = 0.02;
uniform vec4 outline_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);

varying vec3 world_position;
varying vec3 world_normal;

vec4 cel_shade(vec4 color, float ndotl) {
    float cel_factor = floor(ndotl * cel_levels) / cel_levels;
    return color * cel_factor;
}

vec4 rim_light(vec4 color, vec3 normal, vec3 view_dir) {
    float rim = 1.0 - dot(normal, view_dir);
    rim = pow(rim, rim_power);
    return color + rim_color * rim;
}

void vertex() {
    world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
    world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
    vec3 light_dir = normalize(vec3(0.5, 1.0, 0.5)); // Egyptian sun angle
    vec3 view_dir = normalize(-world_position);
    
    float ndotl = max(dot(world_normal, light_dir), 0.0);
    
    vec4 base_color = texture(TEXTURE, UV);
    vec4 shaded = cel_shade(base_color, ndotl);
    vec4 final_color = rim_light(shaded, world_normal, view_dir);
    
    ALBEDO = final_color.rgb;
}