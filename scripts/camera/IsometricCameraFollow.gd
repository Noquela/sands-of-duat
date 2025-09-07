# IsometricCameraFollow.gd
# Isometric Camera System for Sands of Duat
# Sprint 2: Simple and stable isometric camera

extends Camera3D

# Target to follow
@export var target: Node3D

func _ready():
	print("📹 Isometric Camera System: Sprint 2 Ready")
	
	# Setup camera properties
	projection = PROJECTION_ORTHOGONAL
	size = 20.0
	
	# Find player if no target assigned
	if not target:
		var player = get_tree().get_first_node_in_group("player")
		if player:
			target = player
			print("🎯 Camera target found: " + target.name)
	
	# Position camera in isometric view
	if target:
		global_position = target.global_position + Vector3(8, 12, 8)
		look_at(target.global_position, Vector3.UP)

func _process(_delta):
	if not target:
		return
	
	# Simple direct following - no lerping or smoothing
	global_position = target.global_position + Vector3(8, 12, 8)