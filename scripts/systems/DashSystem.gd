extends Node3D
class_name DashSystem

signal dash_started
signal dash_ended
signal dash_cooldown_ready

@export_group("Dash Settings")
@export var dash_distance: float = 6.0
@export var dash_duration: float = 0.2
@export var dash_cooldown: float = 2.0
@export var iframe_duration: float = 0.3

@export_group("VFX")
@export var trail_enabled: bool = true
@export var trail_color: Color = Color.CYAN
@export var screen_shake_strength: float = 2.0

# State tracking
var is_dashing: bool = false
var can_dash: bool = true
var has_iframes: bool = false
var dash_timer: float = 0.0
var cooldown_timer: float = 0.0
var iframe_timer: float = 0.0

# References
var player: CharacterBody3D
var original_collision_layer: int
var original_collision_mask: int

# VFX references
var dash_trail: Node3D
var tween: Tween

func _ready():
	# Get player reference
	player = get_parent()
	if player and player is CharacterBody3D:
		original_collision_layer = player.collision_layer
		original_collision_mask = player.collision_mask
	else:
		push_error("DashSystem must be child of CharacterBody3D")

func _process(delta):
	update_timers(delta)
	
	# Handle dash input
	if Input.is_action_just_pressed("dash") and can_dash and not is_dashing:
		perform_dash()

func update_timers(delta):
	# Update dash duration
	if is_dashing:
		dash_timer -= delta
		if dash_timer <= 0:
			end_dash()
	
	# Update cooldown
	if cooldown_timer > 0:
		cooldown_timer -= delta
		if cooldown_timer <= 0:
			can_dash = true
			dash_cooldown_ready.emit()
	
	# Update i-frames
	if has_iframes:
		iframe_timer -= delta
		if iframe_timer <= 0:
			end_iframes()

func perform_dash():
	if not player:
		return
		
	is_dashing = true
	can_dash = false
	has_iframes = true
	
	# Set timers
	dash_timer = dash_duration
	cooldown_timer = dash_cooldown
	iframe_timer = iframe_duration
	
	# Get dash direction (WASD input or facing direction)
	var dash_direction = get_dash_direction()
	
	# Calculate dash target position
	var dash_target = player.global_position + dash_direction * dash_distance
	
	# Start dash movement tween
	start_dash_movement(dash_target)
	
	# Enable i-frames
	start_iframes()
	
	# VFX and feedback
	create_dash_effects()
	
	# Emit signals
	dash_started.emit()
	
	print("Dash started! Direction: ", dash_direction, " Distance: ", dash_distance)

func get_dash_direction() -> Vector3:
	# Get input direction first
	var input_dir = Vector2.ZERO
	
	if Input.is_action_pressed("move_right"):
		input_dir.x += 1
	if Input.is_action_pressed("move_left"):
		input_dir.x -= 1
	if Input.is_action_pressed("move_down"):
		input_dir.y += 1
	if Input.is_action_pressed("move_up"):
		input_dir.y -= 1
	
	var direction = Vector3.ZERO
	
	if input_dir != Vector2.ZERO:
		# Use WASD input direction (same mapping as player movement)
		direction.x = input_dir.y + input_dir.x
		direction.z = input_dir.y - input_dir.x
		direction = direction.normalized()
	else:
		# Fallback to player facing direction
		direction = -player.transform.basis.z
	
	# Ensure we only dash horizontally
	direction.y = 0
	return direction.normalized()

func start_dash_movement(target_position: Vector3):
	# Create smooth dash movement using Tween
	if tween:
		tween.kill()
	
	tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	
	# Move player to target position
	tween.tween_method(set_dash_position, player.global_position, target_position, dash_duration)

func set_dash_position(pos: Vector3):
	if player and is_dashing:
		player.global_position = pos

func start_iframes():
	# Make player invulnerable to damage
	if player:
		# Change collision layer to avoid enemy damage
		player.collision_mask = original_collision_mask & ~2  # Remove enemies layer (bit 1)
		
		# Visual feedback - make player semi-transparent and flickering
		start_flicker_effect()

func start_flicker_effect():
	# Create flickering visual effect during i-frames
	var mesh_instance = player.get_node_or_null("PlayerMesh")
	if mesh_instance and mesh_instance is MeshInstance3D:
		var flicker_tween = create_tween()
		flicker_tween.set_loops()
		flicker_tween.tween_property(mesh_instance, "transparency", 0.5, 0.1)
		flicker_tween.tween_property(mesh_instance, "transparency", 0.0, 0.1)
		
		# Store reference to stop it later
		mesh_instance.set_meta("flicker_tween", flicker_tween)

func end_iframes():
	has_iframes = false
	
	if player:
		# Restore collision mask
		player.collision_mask = original_collision_mask
		
		# Stop flicker effect
		var mesh_instance = player.get_node_or_null("PlayerMesh")
		if mesh_instance and mesh_instance.has_meta("flicker_tween"):
			var flicker_tween = mesh_instance.get_meta("flicker_tween")
			if flicker_tween:
				flicker_tween.kill()
			mesh_instance.remove_meta("flicker_tween")
			
			# Restore full opacity
			if mesh_instance is MeshInstance3D:
				mesh_instance.transparency = 0.0
	
	print("I-frames ended")

func end_dash():
	is_dashing = false
	
	# Stop movement tween if still active
	if tween:
		tween.kill()
	
	# End VFX
	cleanup_dash_effects()
	
	# Emit signal
	dash_ended.emit()
	
	print("Dash ended")

func create_dash_effects():
	# Screen shake
	apply_screen_shake()
	
	# Dash trail effect
	if trail_enabled:
		create_dash_trail()
	
	# Sound effect (placeholder)
	print("Dash VFX: Screen shake + Trail effect")

func apply_screen_shake():
	# Get camera and apply shake
	var camera = get_viewport().get_camera_3d()
	if camera:
		# Simple screen shake implementation
		var shake_tween = create_tween()
		var original_position = camera.global_position
		
		# Quick shake effect
		for i in 3:
			var shake_offset = Vector3(
				randf_range(-screen_shake_strength, screen_shake_strength) * 0.1,
				randf_range(-screen_shake_strength, screen_shake_strength) * 0.1,
				randf_range(-screen_shake_strength, screen_shake_strength) * 0.1
			)
			shake_tween.tween_property(camera, "global_position", original_position + shake_offset, 0.05)
			shake_tween.tween_property(camera, "global_position", original_position, 0.05)

func create_dash_trail():
	# Create simple particle trail effect
	# This is a placeholder - in a full implementation you'd use GPUParticles3D
	print("Dash trail effect created with color: ", trail_color)

func cleanup_dash_effects():
	# Clean up any ongoing VFX
	if dash_trail:
		dash_trail.queue_free()
		dash_trail = null

# Public API
func is_dash_available() -> bool:
	return can_dash and not is_dashing

func get_cooldown_progress() -> float:
	if can_dash:
		return 1.0
	return 1.0 - (cooldown_timer / dash_cooldown)

func is_player_invulnerable() -> bool:
	return has_iframes

# Debug info
func get_dash_info() -> Dictionary:
	return {
		"is_dashing": is_dashing,
		"can_dash": can_dash,
		"has_iframes": has_iframes,
		"cooldown_progress": get_cooldown_progress(),
		"dash_timer": dash_timer,
		"cooldown_timer": cooldown_timer,
		"iframe_timer": iframe_timer
	}