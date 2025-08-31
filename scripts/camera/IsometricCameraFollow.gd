extends Camera3D
## Câmera isométrica que segue o player - Sprint 6 Test

@export var target: Node3D  # Player target
@export var offset: Vector3 = Vector3(5, 12, 5)  # Offset da câmera
@export var follow_speed: float = 5.0
@export var look_ahead_distance: float = 2.0

func _ready():
	print("📷 Isometric Camera Follow initialized")
	
	# Find player if not assigned
	if not target:
		var player = get_tree().get_first_node_in_group("player")
		if player:
			target = player
			print("🎯 Camera target found: ", player.name)

func _process(delta):
	if not target:
		return
	
	# Calculate target position
	var target_pos = target.global_position + offset
	
	# Smooth follow
	global_position = global_position.lerp(target_pos, follow_speed * delta)
	
	# Always look at player position
	look_at(target.global_position, Vector3.UP)