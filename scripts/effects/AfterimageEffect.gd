# AfterimageEffect.gd  
# Professional afterimage/ghost trail effect for dash
# Creates multiple ghost copies that fade out over time

extends Node3D

class_name AfterimageEffect

var afterimage_scene = preload("res://scenes/effects/GhostImage.tscn")
var trail_points: Array[Dictionary] = []
var max_trail_length: int = 8
var spawn_interval: float = 0.05  # Time between afterimage spawns
var last_spawn_time: float = 0.0

func _ready():
	# Setup for afterimage trail system
	set_process(true)

func start_trail(target_node: Node3D):
	# Begin creating afterimage trail for the target
	trail_points.clear()
	_create_afterimage(target_node)

func _process(delta):
	last_spawn_time += delta

func create_afterimage_at(target_position: Vector3, target_rotation: Vector3, target_scale: Vector3, mesh: Mesh = null):
	# Create a single afterimage at the specified transform
	if last_spawn_time < spawn_interval:
		return
	
	last_spawn_time = 0.0
	
	# Create ghost image
	var ghost = afterimage_scene.instantiate()
	get_tree().current_scene.add_child(ghost)
	
	# Set transform
	ghost.global_position = target_position
	ghost.rotation = target_rotation
	ghost.scale = target_scale
	
	# Setup the ghost appearance
	if ghost.has_method("setup_ghost"):
		ghost.setup_ghost(mesh)
	
	# Clean up old trail points
	_cleanup_old_trail()

func _create_afterimage(target: Node3D):
	# Extract mesh from target for ghost creation
	var mesh_instance = target.get_node_or_null("MeshInstance3D")
	var target_mesh: Mesh = null
	
	if mesh_instance and mesh_instance.mesh:
		target_mesh = mesh_instance.mesh
	
	# Create afterimage at target position
	create_afterimage_at(
		target.global_position,
		target.rotation,
		target.scale,
		target_mesh
	)

func _cleanup_old_trail():
	# Remove excess trail points to maintain performance
	while trail_points.size() > max_trail_length:
		trail_points.pop_front()

func stop_trail():
	# Stop creating new afterimages
	trail_points.clear()

func update_trail(target: Node3D):
	# Called continuously during dash to create trail
	_create_afterimage(target)