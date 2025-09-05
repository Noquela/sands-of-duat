extends Camera3D

@export var target: Node3D
@export var follow_speed: float = 5.0
@export var dash_follow_speed: float = 15.0
@export var distance: float = 12.0
@export var height: float = 12.0

var offset: Vector3

func _ready():
	if not target:
		var player = get_tree().get_first_node_in_group("player")
		if player:
			target = player
	
	setup_isometric_position()

func setup_isometric_position():
	position = Vector3(distance, height, distance)
	look_at(Vector3.ZERO, Vector3.UP)
	projection = PROJECTION_ORTHOGONAL if false else PROJECTION_PERSPECTIVE
	fov = 45.0

func _physics_process(delta):
	if target:
		follow_target(delta)

func follow_target(delta):
	var target_position = target.global_position + offset
	var desired_position = target_position + Vector3(distance, height, distance)
	
	# Check if target is dashing and adjust follow speed
	var current_follow_speed = follow_speed
	if target.has_method("get_node") and target.get_node_or_null("DashSystem"):
		var dash_system = target.get_node("DashSystem")
		if dash_system and dash_system.is_dashing:
			current_follow_speed = dash_follow_speed
	
	global_position = global_position.lerp(desired_position, current_follow_speed * delta)