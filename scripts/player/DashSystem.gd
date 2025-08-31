extends Node
## Sistema de Dash Avançado - Sprint 5
## Dash com i-frames, VFX trail e mecânicas táticas

signal dash_started(direction)
signal dash_ended
signal iframe_activated
signal iframe_ended

# Referência ao player
@onready var player: CharacterBody3D = get_parent()

# Configurações de dash - Sprint 5 specs
const DASH_DISTANCE: float = 6.0
const DASH_DURATION: float = 0.3
const DASH_COOLDOWN: float = 2.0
const IFRAME_DURATION: float = 0.3  # I-frames durante todo o dash

# Estado do dash
var is_dashing: bool = false
var dash_timer: float = 0.0
var cooldown_timer: float = 0.0
var dash_direction: Vector3 = Vector3.ZERO
var dash_speed: float = 0.0

# I-frames system
var has_iframes: bool = false
var iframe_timer: float = 0.0
var original_collision_layer: int = 0

# VFX trail system
var trail_points: Array[Vector3] = []
var trail_timer: float = 0.0
const TRAIL_LENGTH: int = 8
const TRAIL_INTERVAL: float = 0.05

func _ready():
	print("⚡ Advanced Dash System initialized - Sprint 5")
	
	# Calculate dash speed based on distance and duration
	dash_speed = DASH_DISTANCE / DASH_DURATION
	
	# Store original collision layer for i-frames
	original_collision_layer = player.collision_layer
	
	print("🚀 Dash specs - Distance: ", DASH_DISTANCE, " Duration: ", DASH_DURATION, "s")

func _process(delta):
	"""Update dash system"""
	update_timers(delta)
	update_trail(delta)
	handle_dash_input()

func update_timers(delta):
	"""Update all dash-related timers"""
	# Dash timer
	if dash_timer > 0:
		dash_timer -= delta
		if dash_timer <= 0:
			end_dash()
	
	# Cooldown timer  
	if cooldown_timer > 0:
		cooldown_timer -= delta
	
	# I-frame timer
	if iframe_timer > 0:
		iframe_timer -= delta
		if iframe_timer <= 0:
			deactivate_iframes()
	
	# Trail timer
	if trail_timer > 0:
		trail_timer -= delta

func update_trail(_delta):
	"""Update VFX trail system"""
	if is_dashing and trail_timer <= 0:
		# Add new trail point
		trail_points.append(player.global_position)
		
		# Limit trail length
		if trail_points.size() > TRAIL_LENGTH:
			trail_points.pop_front()
		
		trail_timer = TRAIL_INTERVAL

func handle_dash_input():
	"""Handle dash input with ability cancellation"""
	if Input.is_action_just_pressed("dash") and can_dash():
		perform_dash()

func can_dash() -> bool:
	"""Check if dash is available"""
	return cooldown_timer <= 0 and not is_dashing and player.current_health > 0

func perform_dash():
	"""Execute dash with i-frames and VFX"""
	# Cancel current attack if any
	cancel_current_actions()
	
	# Determine dash direction
	dash_direction = get_dash_direction()
	
	# Start dash
	is_dashing = true
	dash_timer = DASH_DURATION
	cooldown_timer = DASH_COOLDOWN
	
	# Activate i-frames
	activate_iframes()
	
	# Apply dash velocity
	var dash_velocity = dash_direction * dash_speed
	player.velocity.x = dash_velocity.x
	player.velocity.z = dash_velocity.z
	
	# Initialize trail
	trail_points.clear()
	trail_points.append(player.global_position)
	
	# Visual feedback
	create_dash_vfx()
	
	# Emit signal
	dash_started.emit(dash_direction)
	
	print("💨 Dash performed - Direction: ", dash_direction)

func get_dash_direction() -> Vector3:
	"""Get dash direction based on input or facing"""
	var direction = Vector3.ZERO
	
	# Get current movement input (same logic as Player.gd)
	if player.has_method("get_camera_directions"):
		var cam_dirs = player.get_camera_directions()
		
		# Build direction based on current input
		if Input.is_action_pressed("move_up"):      # W
			direction += cam_dirs.forward
		if Input.is_action_pressed("move_down"):    # S  
			direction += cam_dirs.back
		if Input.is_action_pressed("move_left"):    # A
			direction += cam_dirs.left
		if Input.is_action_pressed("move_right"):   # D
			direction += cam_dirs.right
	
	# If no input, dash in the direction player is facing
	if direction.length() < 0.1:
		direction = -player.transform.basis.z
	
	direction.y = 0
	return direction.normalized()

func cancel_current_actions():
	"""Cancel attacks and other actions for dash"""
	# Cancel attack if player has attack system
	if player.has_method("cancel_attack"):
		player.cancel_attack()
	
	# Reset player state for dash - direct access since we know the property exists
	player.is_attacking = false

func activate_iframes():
	"""Activate invincibility frames"""
	has_iframes = true
	iframe_timer = IFRAME_DURATION
	
	# Disable collision with enemies (keep environment collision)
	player.collision_layer = 1  # Only player layer, not enemy-detectable
	
	# Visual feedback for i-frames
	create_iframe_vfx()
	
	iframe_activated.emit()
	print("🛡️ I-frames activated - Duration: ", IFRAME_DURATION, "s")

func deactivate_iframes():
	"""Deactivate invincibility frames"""
	has_iframes = false
	
	# Restore original collision layer
	player.collision_layer = original_collision_layer
	
	iframe_ended.emit()
	print("🛡️ I-frames ended")

func end_dash():
	"""End dash and cleanup"""
	is_dashing = false
	
	# Gradual velocity reduction instead of immediate stop
	var current_vel = Vector3(player.velocity.x, 0, player.velocity.z)
	if current_vel.length() > player.movement_speed:
		player.velocity.x = lerp(player.velocity.x, 0.0, 0.5)
		player.velocity.z = lerp(player.velocity.z, 0.0, 0.5)
	
	# Clear trail
	trail_points.clear()
	
	dash_ended.emit()
	print("⚡ Dash ended")

func create_dash_vfx():
	"""Create dash visual effects"""
	# Flash player material for dash start
	if player.has_method("flash_material"):
		player.flash_material(Color.CYAN, 0.2)
	
	print("✨ Dash VFX created")

func create_iframe_vfx():
	"""Create i-frame visual effects"""
	# Make player slightly transparent during i-frames
	if player.has_node("MeshInstance3D"):
		var mesh_inst = player.get_node("MeshInstance3D")
		if mesh_inst.material_override:
			var material = mesh_inst.material_override as StandardMaterial3D
			if material:
				# Semi-transparent with emission
				material.albedo_color.a = 0.7
				material.emission_enabled = true
				material.emission = Color(0.3, 0.8, 1.0)  # Cyan glow
	
	print("🌟 I-frame VFX created")

func _physics_process(_delta):
	"""Handle dash physics"""
	if is_dashing:
		# Maintain dash velocity
		var target_velocity = dash_direction * dash_speed
		player.velocity.x = target_velocity.x
		player.velocity.z = target_velocity.z

func get_dash_info() -> Dictionary:
	"""Return dash system information for UI/debug"""
	return {
		"is_dashing": is_dashing,
		"dash_available": can_dash(),
		"cooldown_remaining": max(0, cooldown_timer),
		"cooldown_progress": 1.0 - (cooldown_timer / DASH_COOLDOWN),
		"has_iframes": has_iframes,
		"iframe_remaining": max(0, iframe_timer)
	}

func get_trail_points() -> Array[Vector3]:
	"""Return trail points for VFX rendering"""
	return trail_points

func modify_dash_stats(distance_mult: float = 1.0, cooldown_mult: float = 1.0):
	"""Modify dash stats (for boons/upgrades later)"""
	# This will be useful for boon system in later sprints
	print("🔧 Dash stats modified - Distance: x", distance_mult, " Cooldown: x", cooldown_mult)
