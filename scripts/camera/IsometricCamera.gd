extends Camera3D
## Câmera isométrica que segue o player - Otimizada para ultrawide 165Hz
## Sistema de follow suave com predição de movimento

# Referência ao player
var target_player: Node3D = null

# Configurações da câmera isométrica
const CAMERA_DISTANCE: float = 12.0
const CAMERA_ANGLE: float = 45.0
const CAMERA_HEIGHT_OFFSET: float = 2.0

# Sistema de seguimento suave
var follow_speed: float = 8.0  # Aumentado para 165Hz
var look_ahead_distance: float = 3.0
var smooth_time: float = 0.1

# Shake system para impacts/hits
var shake_intensity: float = 0.0
var shake_duration: float = 0.0
var shake_timer: float = 0.0

# Configurações ultrawide
var base_fov: float = 20.0
var ultrawide_fov_multiplier: float = 1.3

func _ready():
	print("📷 Isometric Camera initialized for ultrawide 165Hz")
	
	# Setup isometric projection
	setup_isometric_projection()
	
	# Find player reference
	find_player_reference()
	
	# Optimize for ultrawide
	optimize_for_ultrawide()

func setup_isometric_projection():
	"""Configura projeção isométrica perfeita"""
	# Set orthogonal projection
	projection = PROJECTION_ORTHOGONAL
	
	# Calculate position based on angle and distance
	var angle_rad = deg_to_rad(CAMERA_ANGLE)
	var x_pos = CAMERA_DISTANCE * cos(angle_rad) * cos(angle_rad)
	var y_pos = CAMERA_DISTANCE * sin(angle_rad) + CAMERA_HEIGHT_OFFSET
	var z_pos = CAMERA_DISTANCE * cos(angle_rad) * sin(angle_rad)
	
	position = Vector3(x_pos, y_pos, z_pos)
	
	# Look at origin with correct orientation
	look_at(Vector3.ZERO, Vector3.UP)
	
	print("📐 Isometric projection configured - Angle: ", CAMERA_ANGLE, "°")

func optimize_for_ultrawide():
	"""Otimiza FOV para monitores ultrawide"""
	var viewport = get_viewport()
	var aspect_ratio = float(viewport.size.x) / float(viewport.size.y)
	
	# Adjust size for ultrawide (21:9, 32:9, etc.)
	if aspect_ratio > 1.7:  # Ultrawide detected
		size = base_fov * (aspect_ratio / 1.77) * ultrawide_fov_multiplier
		print("📺 Ultrawide optimized - Aspect: ", aspect_ratio, " FOV: ", size)
	else:
		size = base_fov
	
	print("🎥 Camera FOV set to: ", size, " for resolution: ", viewport.size)

func find_player_reference():
	"""Encontra referência ao player na cena"""
	# Try to find player in current scene
	var player = get_tree().get_first_node_in_group("player")
	
	if player:
		target_player = player
		print("🎯 Player target found: ", player.name)
	else:
		print("⚠️  Player not found - searching in 1 second...")
		# Retry in 1 second
		await get_tree().create_timer(1.0).timeout
		find_player_reference()

func _process(delta):
	"""Main camera update loop - 165Hz optimized"""
	if not target_player:
		return
	
	# Update camera shake
	update_camera_shake(delta)
	
	# Follow player with smooth movement
	update_camera_follow(delta)

func update_camera_follow(delta):
	"""Sistema de seguimento suave do player"""
	if not target_player:
		return
	
	var target_pos = target_player.global_position
	
	# Look-ahead: predict where player is going
	var player_velocity = Vector3.ZERO
	if target_player.has_method("get_movement_info"):
		var movement_info = target_player.get_movement_info()
		player_velocity = movement_info.get("velocity", Vector3.ZERO)
	
	# Add look-ahead based on velocity
	var look_ahead = Vector3(player_velocity.x, 0, player_velocity.z).normalized() * look_ahead_distance
	var predicted_pos = target_pos + look_ahead
	
	# Calculate desired camera position (maintaining isometric offset)
	var offset = Vector3(
		CAMERA_DISTANCE * cos(deg_to_rad(CAMERA_ANGLE)) * cos(deg_to_rad(CAMERA_ANGLE)),
		CAMERA_DISTANCE * sin(deg_to_rad(CAMERA_ANGLE)) + CAMERA_HEIGHT_OFFSET,
		CAMERA_DISTANCE * cos(deg_to_rad(CAMERA_ANGLE)) * sin(deg_to_rad(CAMERA_ANGLE))
	)
	
	var desired_position = predicted_pos + offset
	
	# Smooth interpolation (higher speed for 165Hz)
	global_position = global_position.lerp(desired_position, follow_speed * delta)
	
	# Always look at the player (with slight offset for better view)
	var look_target = target_pos + Vector3(0, 1, 0)  # Look slightly above player
	look_at(look_target, Vector3.UP)

func update_camera_shake(delta):
	"""Sistema de screen shake"""
	if shake_timer > 0:
		shake_timer -= delta
		
		# Generate random shake offset
		var shake_offset = Vector3(
			randf_range(-shake_intensity, shake_intensity),
			randf_range(-shake_intensity, shake_intensity),
			randf_range(-shake_intensity, shake_intensity)
		)
		
		# Apply shake (temporary position offset)
		position += shake_offset
		
		# Decay shake intensity
		shake_intensity = lerp(shake_intensity, 0.0, delta * 5.0)
	else:
		shake_intensity = 0.0

func trigger_shake(intensity: float, duration: float):
	"""Triggera camera shake (para impactos, explosões, etc.)"""
	shake_intensity = intensity
	shake_duration = duration
	shake_timer = duration
	
	print("📳 Camera shake triggered - Intensity: ", intensity)

func set_follow_target(new_target: Node3D):
	"""Define novo alvo para seguir"""
	target_player = new_target
	if new_target:
		print("🎯 New camera target set: ", new_target.name)

func adjust_follow_speed(new_speed: float):
	"""Ajusta velocidade de seguimento (útil para diferentes situações)"""
	follow_speed = new_speed
	print("⚡ Camera follow speed adjusted to: ", new_speed)

func get_screen_center_world_pos() -> Vector3:
	"""Retorna posição do mundo no centro da tela (útil para mira)"""
	var viewport = get_viewport()
	var center_screen = viewport.size / 2
	
	# Project from screen to world space
	var from = project_ray_origin(center_screen)
	var to = from + project_ray_normal(center_screen) * 1000
	
	# Raycast para encontrar posição no plano do chão
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = 4  # Environment layer
	
	var result = space_state.intersect_ray(query)
	if result:
		return result.position
	
	# Fallback: calculate intersection with y=0 plane
	var ray_dir = project_ray_normal(center_screen)
	var t = -from.y / ray_dir.y
	return from + ray_dir * t

func get_camera_info() -> Dictionary:
	"""Retorna informações da câmera para debug"""
	return {
		"position": global_position,
		"target": target_player.global_position if target_player else Vector3.ZERO,
		"fov": size,
		"follow_speed": follow_speed,
		"shake_active": shake_timer > 0,
		"aspect_ratio": float(get_viewport().size.x) / float(get_viewport().size.y)
	}