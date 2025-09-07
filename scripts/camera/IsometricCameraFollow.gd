# IsometricCameraFollow.gd
# Isometric Camera System for Sands of Duat
# Sprint 2: Fixed isometric camera with smooth following

extends Camera3D

# Camera settings from roadmap specs
const CAMERA_DISTANCE = 12.0
const CAMERA_HEIGHT = 8.0
const CAMERA_ANGLE = -45.0  # degrees
const FOLLOW_SPEED = 12.0  # High speed for responsive following
const LOOK_AHEAD_DISTANCE = 0.5  # Reduced for more responsive following

# Target to follow
@export var target: Node3D
var target_position: Vector3
var camera_offset: Vector3

func _ready():
	print("📹 Isometric Camera System: Sprint 2 Ready")
	
	# Setup camera properties
	projection = PROJECTION_ORTHOGONAL
	size = 20.0  # Orthogonal size for isometric view
	fov = 45.0
	
	# Set fixed isometric rotation (45 degrees down, looking at XZ plane)
	rotation_degrees = Vector3(45.0, 45.0, 0.0)
	
	# Calculate isometric offset
	_setup_isometric_position()
	
	# Find player if no target assigned
	if not target:
		_find_target()

func _setup_isometric_position():
	# Calculate offset for isometric view (45° angle, 12 units distance)
	var angle_rad = deg_to_rad(CAMERA_ANGLE)
	camera_offset = Vector3(
		CAMERA_DISTANCE * cos(angle_rad) * 0.707,  # X offset for diagonal
		CAMERA_HEIGHT,  # Y height
		CAMERA_DISTANCE * sin(angle_rad) * 0.707   # Z offset for diagonal
	)
	
	print("🎥 Camera offset calculated: " + str(camera_offset))

func _find_target():
	# Auto-find player target
	var player = get_tree().get_first_node_in_group("player")
	if player:
		target = player
		print("🎯 Camera target found: " + target.name)
	else:
		print("⚠️ No player target found for camera")

func _process(delta):
	if not target:
		return
	
	# Calculate target position with look-ahead
	var target_pos = target.global_position
	
	# Add look-ahead based on player velocity if available
	if target.has_method("get_velocity"):
		var velocity = target.get_velocity()
		if velocity.length() > 0.1:
			target_pos += velocity.normalized() * LOOK_AHEAD_DISTANCE
	
	# Calculate desired camera position
	var desired_position = target_pos + camera_offset
	
	# Smooth camera movement
	global_position = global_position.lerp(desired_position, FOLLOW_SPEED * delta)

# Camera shake for combat feedback (future sprint)
func add_screen_shake(_intensity: float = 1.0):
	# Placeholder for future combat integration
	pass

# Zoom functionality for different areas
func set_zoom(zoom_level: float):
	size = 20.0 / zoom_level
	size = clamp(size, 10.0, 40.0)  # Reasonable limits

# Debug camera info
func get_camera_info() -> Dictionary:
	return {
		"position": global_position,
		"target": target.global_position if target else Vector3.ZERO,
		"offset": camera_offset,
		"size": size
	}

func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_F3:
				var info = get_camera_info()
				print("📹 Camera Info:")
				for key in info:
					print("   " + key + ": " + str(info[key]))