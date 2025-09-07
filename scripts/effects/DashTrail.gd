# DashTrail.gd
# Dash Visual Effect for Sands of Duat
# Sprint 4: Visual trail for dash movement

extends Node3D

@onready var mesh_instance: MeshInstance3D = $TrailMesh
@onready var timer: Timer = $Timer

var start_position: Vector3
var end_position: Vector3
var trail_duration: float = 0.2

func _ready():
	# Connect timer to auto-destroy
	timer.timeout.connect(_on_timer_timeout)

func setup_trail(from: Vector3, to: Vector3, duration: float):
	start_position = from
	end_position = to
	trail_duration = duration
	
	# Position trail at midpoint
	global_position = (start_position + end_position) * 0.5
	
	# Calculate distance and scale
	var distance = start_position.distance_to(end_position)
	var direction = (end_position - start_position).normalized()
	
	# Orient trail along movement direction
	if direction.length() > 0.1:
		look_at(global_position + direction, Vector3.UP)
	
	# Scale trail to match distance
	if mesh_instance and mesh_instance.mesh:
		var quad_mesh = mesh_instance.mesh as QuadMesh
		if quad_mesh:
			quad_mesh.size = Vector2(distance, 0.3)
	
	# Start animation
	_animate_trail()

func _animate_trail():
	if not mesh_instance:
		return
	
	var material = mesh_instance.get_surface_override_material(0)
	if not material:
		return
	
	# Create fade out animation
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Fade alpha
	tween.tween_property(material, "albedo_color:a", 0.0, trail_duration)
	tween.tween_property(material, "emission_energy", 0.0, trail_duration)
	
	# Shrink effect
	tween.tween_property(self, "scale", Vector3(1.0, 0.1, 1.0), trail_duration)

func _on_timer_timeout():
	queue_free()