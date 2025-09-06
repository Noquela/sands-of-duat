class_name EgyptianPostProcessor
extends Node

## 🎨 EGYPTIAN POST PROCESSING SYSTEM - SANDS OF DUAT
## Sistema de pós-processamento com filtros atmosféricos egípcios
##
## Features:
## - Atmospheric haze com partículas de areia
## - Golden hour lighting simulation (Ra's blessing)
## - Hieroglyph glow enhancement
## - Sandstorm effects dinâmicos
## - Cultural color grading (desert/tomb/divine palettes)

signal post_process_applied(effect: String)
signal atmosphere_changed(intensity: float)

@export var enable_egyptian_atmosphere: bool = true
@export var sand_particle_intensity: float = 0.5
@export var golden_hour_strength: float = 0.8
@export var hieroglyph_glow_multiplier: float = 1.5
@export var cultural_color_intensity: float = 1.0

# Post-processing effects
var post_process_material: ShaderMaterial
var egyptian_shader: Shader
var current_biome_profile: String = ""

# Egyptian atmospheric presets
const EGYPTIAN_ATMOSPHERE_PRESETS = {
	"cavernas_esquecidos": {
		"color_temp": 4500,  # Cool blue undertones
		"saturation": 0.7,
		"contrast": 1.2,
		"shadows_tint": Color(0.2, 0.3, 0.5),
		"highlights_tint": Color(0.8, 0.9, 1.0),
		"sand_particles": 0.2,
		"mystical_glow": 0.8
	},
	"rio_de_fogo": {
		"color_temp": 2800,  # Warm fire tones
		"saturation": 1.3,
		"contrast": 1.4,
		"shadows_tint": Color(0.6, 0.2, 0.1),
		"highlights_tint": Color(1.0, 0.7, 0.3),
		"sand_particles": 0.1,
		"fire_shimmer": 1.2
	},
	"salao_julgamento": {
		"color_temp": 3200,  # Golden divine light
		"saturation": 1.0,
		"contrast": 1.1,
		"shadows_tint": Color(0.3, 0.3, 0.4),
		"highlights_tint": Color(1.0, 0.9, 0.6),
		"sand_particles": 0.05,
		"divine_radiance": 1.0
	}
}

# Shader parameters
var shader_params: Dictionary = {}
var active_effects: Array[String] = []

func _ready():
	print("🎨 EgyptianPostProcessor initialized")
	setup_egyptian_shader()
	setup_atmosphere_system()
	
	if enable_egyptian_atmosphere:
		apply_base_egyptian_atmosphere()

func setup_egyptian_shader():
	"""Configura shader customizado egípcio"""
	
	# Create Egyptian atmosphere shader
	egyptian_shader = create_egyptian_atmosphere_shader()
	
	# Create material
	post_process_material = ShaderMaterial.new()
	post_process_material.shader = egyptian_shader
	
	# Setup viewport post-processing
	var viewport = get_viewport()
	if viewport:
		# Enable environment and post-processing
		var camera = viewport.get_camera_3d()
		if camera and camera.environment:
			setup_camera_post_processing(camera)
	
	print("✅ Egyptian shader setup complete")

func create_egyptian_atmosphere_shader() -> Shader:
	"""Cria shader de atmosfera egípcia customizado"""
	
	var shader = Shader.new()
	
	# Egyptian atmosphere shader code
	var shader_code = """
	shader_type canvas_item;

	// Egyptian atmosphere parameters
	uniform float sand_intensity : hint_range(0.0, 2.0) = 0.5;
	uniform float golden_hour_strength : hint_range(0.0, 2.0) = 0.8;
	uniform float hieroglyph_glow : hint_range(0.0, 3.0) = 1.5;
	uniform float color_temperature : hint_range(1000.0, 10000.0) = 3200.0;
	uniform float saturation_boost : hint_range(0.0, 2.0) = 1.0;
	uniform float contrast_enhancement : hint_range(0.5, 2.0) = 1.1;
	uniform vec3 shadow_tint : hint_color = vec3(0.3, 0.3, 0.4);
	uniform vec3 highlight_tint : hint_color = vec3(1.0, 0.9, 0.6);
	uniform float mystical_glow : hint_range(0.0, 2.0) = 0.0;
	uniform float fire_shimmer : hint_range(0.0, 2.0) = 0.0;
	uniform float divine_radiance : hint_range(0.0, 2.0) = 0.0;
	
	// Noise texture for sand particles
	uniform sampler2D noise_texture : hint_normal;
	uniform float time_scale : hint_range(0.0, 5.0) = 1.0;

	// Egyptian color grading function
	vec3 egyptian_color_grade(vec3 color, float temp, float sat, float contrast) {
		// Color temperature adjustment
		vec3 temp_adjust = vec3(1.0);
		if (temp < 3300.0) {
			temp_adjust.r = temp / 3300.0;
			temp_adjust.g = sqrt(temp / 3300.0);
		} else {
			temp_adjust.b = 3300.0 / temp;
		}
		
		color *= temp_adjust;
		
		// Saturation boost
		float luminance = dot(color, vec3(0.299, 0.587, 0.114));
		color = mix(vec3(luminance), color, sat);
		
		// Contrast enhancement
		color = (color - 0.5) * contrast + 0.5;
		
		return color;
	}

	// Sand particle overlay
	vec3 apply_sand_particles(vec3 color, vec2 uv, float intensity) {
		if (intensity <= 0.0) return color;
		
		// Animated sand noise
		vec2 animated_uv = uv + vec2(TIME * 0.02, TIME * 0.01) * time_scale;
		float noise = texture(noise_texture, animated_uv * 8.0).r;
		
		// Sand particle sparkle
		float sparkle = pow(noise, 3.0) * intensity;
		return color + sparkle * vec3(0.8, 0.7, 0.5);
	}

	// Hieroglyph glow enhancement
	vec3 enhance_hieroglyph_glow(vec3 color, float intensity) {
		if (intensity <= 1.0) return color;
		
		// Detect golden/yellow areas (likely hieroglyphs)
		float golden_mask = smoothstep(0.3, 0.7, dot(color, vec3(0.8, 0.8, 0.2)));
		
		// Apply glow
		vec3 glow = color * golden_mask * (intensity - 1.0);
		return color + glow * vec3(1.0, 0.9, 0.3);
	}

	// Mystical atmosphere (cavernas)
	vec3 apply_mystical_atmosphere(vec3 color, vec2 uv, float intensity) {
		if (intensity <= 0.0) return color;
		
		// Mystical fog effect
		float fog_noise = texture(noise_texture, uv * 4.0 + TIME * 0.03).r;
		vec3 mystical_tint = vec3(0.4, 0.6, 1.0) * fog_noise * intensity * 0.1;
		
		return color + mystical_tint;
	}

	// Fire shimmer (rio de fogo)
	vec3 apply_fire_shimmer(vec3 color, vec2 uv, float intensity) {
		if (intensity <= 0.0) return color;
		
		// Heat shimmer distortion
		vec2 distort = texture(noise_texture, uv * 6.0 + TIME * 0.5).rg - 0.5;
		distort *= intensity * 0.02;
		
		// Fire color boost
		float heat_mask = smoothstep(0.4, 0.8, dot(color, vec3(1.0, 0.5, 0.1)));
		vec3 fire_boost = heat_mask * intensity * vec3(0.3, 0.1, 0.0);
		
		return color + fire_boost;
	}

	// Divine radiance (salao julgamento)
	vec3 apply_divine_radiance(vec3 color, vec2 uv, float intensity) {
		if (intensity <= 0.0) return color;
		
		// Divine glow from center
		float dist_from_center = length(uv - 0.5);
		float radiance = (1.0 - dist_from_center) * intensity * 0.2;
		
		vec3 divine_light = vec3(1.0, 0.9, 0.6) * radiance;
		return color + divine_light;
	}

	void fragment() {
		vec3 color = texture(TEXTURE, UV).rgb;
		
		// Base Egyptian color grading
		color = egyptian_color_grade(color, color_temperature, saturation_boost, contrast_enhancement);
		
		// Apply shadow and highlight tinting
		float luminance = dot(color, vec3(0.299, 0.587, 0.114));
		if (luminance < 0.5) {
			color = mix(color, shadow_tint, (0.5 - luminance) * 0.5);
		} else {
			color = mix(color, highlight_tint, (luminance - 0.5) * 0.3);
		}
		
		// Sand particles overlay
		color = apply_sand_particles(color, UV, sand_intensity);
		
		// Hieroglyph glow enhancement
		color = enhance_hieroglyph_glow(color, hieroglyph_glow);
		
		// Biome-specific effects
		color = apply_mystical_atmosphere(color, UV, mystical_glow);
		color = apply_fire_shimmer(color, UV, fire_shimmer);
		color = apply_divine_radiance(color, UV, divine_radiance);
		
		// Golden hour enhancement
		if (golden_hour_strength > 0.0) {
			vec3 golden_tint = vec3(1.0, 0.8, 0.6) * golden_hour_strength * 0.1;
			color += golden_tint;
		}
		
		COLOR = vec4(color, 1.0);
	}
	"""
	
	shader.code = shader_code
	return shader

func setup_camera_post_processing(camera: Camera3D):
	"""Configura pós-processamento da câmera"""
	
	# Ensure environment exists
	if not camera.environment:
		camera.environment = Environment.new()
	
	var env = camera.environment
	
	# Base Egyptian atmosphere settings
	env.background_mode = Environment.BG_SKY
	env.ambient_light_color = Color(0.4, 0.35, 0.3)
	env.ambient_light_energy = 0.3
	
	# Setup fog for atmospheric depth
	env.fog_enabled = true
	env.fog_light_color = Color(0.8, 0.7, 0.5)
	env.fog_light_energy = 0.5
	env.fog_density = 0.02
	
	# Glow effects for hieroglyphs
	env.glow_enabled = true
	env.glow_intensity = 0.8
	env.glow_strength = 1.2
	env.glow_bloom = 0.3
	
	print("✅ Camera post-processing configured")

func setup_atmosphere_system():
	"""Configura sistema de atmosfera"""
	
	# Create noise texture for sand particles
	var noise_image = Image.create(256, 256, false, Image.FORMAT_RGB8)
	var noise = FastNoiseLite.new()
	noise.seed = 12345
	noise.frequency = 0.1
	
	for x in range(256):
		for y in range(256):
			var noise_val = noise.get_noise_2d(x, y) * 0.5 + 0.5
			noise_image.set_pixel(x, y, Color(noise_val, noise_val, noise_val))
	
	var noise_texture = ImageTexture.new()
	noise_texture.create_from_image(noise_image)
	
	# Set noise texture in shader
	if post_process_material:
		post_process_material.set_shader_parameter("noise_texture", noise_texture)
	
	print("✅ Atmosphere system configured")

func apply_base_egyptian_atmosphere():
	"""Aplica atmosfera base egípcia"""
	
	if not post_process_material:
		return
	
	# Default Egyptian atmosphere settings
	post_process_material.set_shader_parameter("sand_intensity", sand_particle_intensity)
	post_process_material.set_shader_parameter("golden_hour_strength", golden_hour_strength)
	post_process_material.set_shader_parameter("hieroglyph_glow", hieroglyph_glow_multiplier)
	post_process_material.set_shader_parameter("color_temperature", 3200.0)
	post_process_material.set_shader_parameter("saturation_boost", cultural_color_intensity)
	post_process_material.set_shader_parameter("time_scale", 1.0)
	
	print("✅ Base Egyptian atmosphere applied")

func apply_biome_atmosphere(biome_key: String):
	"""Aplica atmosfera específica do bioma"""
	
	if not EGYPTIAN_ATMOSPHERE_PRESETS.has(biome_key):
		print("⚠️ Unknown biome atmosphere: ", biome_key)
		return
	
	var preset = EGYPTIAN_ATMOSPHERE_PRESETS[biome_key]
	current_biome_profile = biome_key
	
	if not post_process_material:
		return
	
	# Apply preset parameters
	post_process_material.set_shader_parameter("color_temperature", preset.color_temp)
	post_process_material.set_shader_parameter("saturation_boost", preset.saturation * cultural_color_intensity)
	post_process_material.set_shader_parameter("contrast_enhancement", preset.contrast)
	post_process_material.set_shader_parameter("shadow_tint", preset.shadows_tint)
	post_process_material.set_shader_parameter("highlight_tint", preset.highlights_tint)
	post_process_material.set_shader_parameter("sand_intensity", preset.sand_particles * sand_particle_intensity)
	
	# Biome-specific effects
	if preset.has("mystical_glow"):
		post_process_material.set_shader_parameter("mystical_glow", preset.mystical_glow)
		active_effects.append("mystical_atmosphere")
	
	if preset.has("fire_shimmer"):
		post_process_material.set_shader_parameter("fire_shimmer", preset.fire_shimmer)
		active_effects.append("fire_shimmer")
	
	if preset.has("divine_radiance"):
		post_process_material.set_shader_parameter("divine_radiance", preset.divine_radiance)
		active_effects.append("divine_radiance")
	
	post_process_applied.emit("biome_atmosphere_" + biome_key)
	print("🎨 Applied biome atmosphere: ", biome_key)

func enhance_hieroglyph_visibility():
	"""Melhora visibilidade dos hieróglifos"""
	
	if not post_process_material:
		return
	
	# Increase hieroglyph glow
	var current_glow = post_process_material.get_shader_parameter("hieroglyph_glow")
	post_process_material.set_shader_parameter("hieroglyph_glow", current_glow * 1.3)
	
	# Add golden enhancement
	post_process_material.set_shader_parameter("golden_hour_strength", golden_hour_strength * 1.2)
	
	active_effects.append("hieroglyph_enhancement")
	post_process_applied.emit("hieroglyph_enhancement")
	
	print("✨ Hieroglyph visibility enhanced")

func apply_sandstorm_effect(intensity: float = 1.0, duration: float = 5.0):
	"""Aplica efeito de tempestade de areia"""
	
	if not post_process_material:
		return
	
	print("🌪️ Applying sandstorm effect: intensity=", intensity, " duration=", duration)
	
	# Increase sand particles dramatically
	var storm_intensity = sand_particle_intensity * (2.0 + intensity)
	post_process_material.set_shader_parameter("sand_intensity", storm_intensity)
	
	# Reduce visibility with warm brown tint
	post_process_material.set_shader_parameter("shadow_tint", Color(0.6, 0.4, 0.2))
	post_process_material.set_shader_parameter("highlight_tint", Color(0.8, 0.6, 0.4))
	
	# Animate time scale for moving sand
	post_process_material.set_shader_parameter("time_scale", 3.0 * intensity)
	
	active_effects.append("sandstorm")
	post_process_applied.emit("sandstorm")
	
	# Return to normal after duration
	if duration > 0:
		await get_tree().create_timer(duration).timeout
		clear_sandstorm_effect()

func clear_sandstorm_effect():
	"""Remove efeito de tempestade de areia"""
	
	if not post_process_material:
		return
	
	# Restore normal settings
	post_process_material.set_shader_parameter("sand_intensity", sand_particle_intensity)
	post_process_material.set_shader_parameter("time_scale", 1.0)
	
	# Restore biome atmosphere
	if current_biome_profile != "":
		apply_biome_atmosphere(current_biome_profile)
	
	active_effects.erase("sandstorm")
	print("🌪️ Sandstorm effect cleared")

func apply_divine_blessing_effect(duration: float = 3.0):
	"""Aplica efeito de bênção divina (dourado brilhante)"""
	
	if not post_process_material:
		return
	
	print("✨ Applying divine blessing effect")
	
	# Golden divine glow
	post_process_material.set_shader_parameter("divine_radiance", 1.5)
	post_process_material.set_shader_parameter("golden_hour_strength", 1.5)
	post_process_material.set_shader_parameter("hieroglyph_glow", hieroglyph_glow_multiplier * 2.0)
	
	# Divine color tint
	post_process_material.set_shader_parameter("highlight_tint", Color(1.0, 0.9, 0.5))
	
	active_effects.append("divine_blessing")
	post_process_applied.emit("divine_blessing")
	
	# Return to normal after duration
	if duration > 0:
		await get_tree().create_timer(duration).timeout
		clear_divine_blessing_effect()

func clear_divine_blessing_effect():
	"""Remove efeito de bênção divina"""
	
	if not post_process_material:
		return
	
	# Restore normal divine radiance
	post_process_material.set_shader_parameter("divine_radiance", 0.0)
	post_process_material.set_shader_parameter("golden_hour_strength", golden_hour_strength)
	post_process_material.set_shader_parameter("hieroglyph_glow", hieroglyph_glow_multiplier)
	
	# Restore biome atmosphere
	if current_biome_profile != "":
		apply_biome_atmosphere(current_biome_profile)
	
	active_effects.erase("divine_blessing")
	print("✨ Divine blessing effect cleared")

func transition_to_biome_atmosphere(new_biome: String, transition_time: float = 2.0):
	"""Transição suave entre atmosferas de biomas"""
	
	if not post_process_material or not EGYPTIAN_ATMOSPHERE_PRESETS.has(new_biome):
		return
	
	print("🔄 Transitioning to biome atmosphere: ", new_biome)
	
	var old_preset = EGYPTIAN_ATMOSPHERE_PRESETS.get(current_biome_profile, {})
	var new_preset = EGYPTIAN_ATMOSPHERE_PRESETS[new_biome]
	
	# Create transition tween
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Animate color temperature
	if old_preset.has("color_temp") and new_preset.has("color_temp"):
		tween.tween_method(
			func(temp: float): post_process_material.set_shader_parameter("color_temperature", temp),
			old_preset.color_temp, new_preset.color_temp, transition_time
		)
	
	# Animate saturation
	if old_preset.has("saturation") and new_preset.has("saturation"):
		tween.tween_method(
			func(sat: float): post_process_material.set_shader_parameter("saturation_boost", sat * cultural_color_intensity),
			old_preset.saturation, new_preset.saturation, transition_time
		)
	
	# Wait for transition to complete
	await tween.finished
	
	# Apply full new biome atmosphere
	apply_biome_atmosphere(new_biome)
	
	atmosphere_changed.emit(1.0)
	print("✅ Biome atmosphere transition complete: ", new_biome)

func set_time_of_day(hour: float):
	"""Define hora do dia para ajustar atmosfera (0-24)"""
	
	if not post_process_material:
		return
	
	# Calculate sun position and intensity
	var sun_intensity = 0.0
	var color_temp = 3200.0
	
	if hour >= 6 and hour <= 18:  # Day time
		var day_progress = (hour - 6) / 12.0
		sun_intensity = sin(day_progress * PI) * golden_hour_strength
		
		# Color temperature varies throughout day
		if hour >= 6 and hour <= 8:  # Dawn
			color_temp = 2800 + (hour - 6) * 200  # 2800 to 3200
		elif hour >= 8 and hour <= 16:  # Day
			color_temp = 5500
		elif hour >= 16 and hour <= 18:  # Dusk
			color_temp = 3200 - (hour - 16) * 200  # 3200 to 2800
	else:  # Night time
		sun_intensity = 0.1
		color_temp = 2200
	
	post_process_material.set_shader_parameter("golden_hour_strength", sun_intensity)
	post_process_material.set_shader_parameter("color_temperature", color_temp)
	
	print("🌅 Time of day set: ", hour, "h (temp: ", color_temp, "K)")

# Public interface

func get_active_effects() -> Array[String]:
	"""Retorna efeitos ativos"""
	return active_effects

func get_current_biome_profile() -> String:
	"""Retorna perfil de bioma atual"""
	return current_biome_profile

func set_atmosphere_intensity(intensity: float):
	"""Define intensidade geral da atmosfera"""
	
	if not post_process_material:
		return
	
	# Scale all atmospheric effects
	var base_sand = sand_particle_intensity * intensity
	var base_golden = golden_hour_strength * intensity
	var base_glow = hieroglyph_glow_multiplier * intensity
	
	post_process_material.set_shader_parameter("sand_intensity", base_sand)
	post_process_material.set_shader_parameter("golden_hour_strength", base_golden)
	post_process_material.set_shader_parameter("hieroglyph_glow", base_glow)
	
	atmosphere_changed.emit(intensity)

# Debug functions

func debug_cycle_biome_atmospheres():
	"""Debug: cicla entre atmosferas de biomas"""
	
	var biomes = EGYPTIAN_ATMOSPHERE_PRESETS.keys()
	for biome in biomes:
		print("🎨 Testing atmosphere: ", biome)
		apply_biome_atmosphere(biome)
		await get_tree().create_timer(3.0).timeout

func debug_test_effects():
	"""Debug: testa todos os efeitos especiais"""
	
	print("🎨 Testing sandstorm...")
	apply_sandstorm_effect(1.0, 2.0)
	await get_tree().create_timer(3.0).timeout
	
	print("🎨 Testing divine blessing...")
	apply_divine_blessing_effect(2.0)
	await get_tree().create_timer(3.0).timeout
	
	print("🎨 Testing hieroglyph enhancement...")
	enhance_hieroglyph_visibility()
	await get_tree().create_timer(2.0).timeout

func get_post_process_info() -> Dictionary:
	"""Retorna informações do sistema de pós-processamento"""
	
	return {
		"enabled": enable_egyptian_atmosphere,
		"current_biome": current_biome_profile,
		"active_effects": active_effects,
		"sand_intensity": sand_particle_intensity,
		"golden_hour": golden_hour_strength,
		"glow_multiplier": hieroglyph_glow_multiplier,
		"cultural_intensity": cultural_color_intensity
	}