# AttackSwipe.gd
# Attack Visual Effect for Sands of Duat
# Sprint 4: Linear attack effect from player to attack range

extends Node3D

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var timer: Timer = $Timer

func _ready():
	# Connect timer to auto-destroy
	timer.timeout.connect(_on_timer_timeout)

func setup_attack_line(start_pos: Vector3, direction: Vector3, attack_range: float):
	# Position the attack effect to start at player and extend in direction
	var end_pos = start_pos + direction * attack_range
	var center_pos = (start_pos + end_pos) * 0.5
	
	# Position at center of the line
	global_position = center_pos
	
	# Orient toward the direction
	if direction.length() > 0.1:
		var target_rotation = atan2(-direction.x, -direction.z)
		rotation.y = target_rotation
	
	# Scale the mesh to match the attack range
	if mesh_instance and mesh_instance.mesh:
		var quad_mesh = mesh_instance.mesh as QuadMesh
		if quad_mesh:
			# Set length to attack range, keep width small for swipe effect
			quad_mesh.size = Vector2(attack_range, 0.3)
	
	# Start the animation
	_animate_attack_line()

func _animate_attack_line():
	if not mesh_instance:
		return
	
	# Create glowing material
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(1, 0.8, 0.2, 0.9)  # Golden color
	material.emission_enabled = true
	material.emission = Color(1, 0.6, 0.1, 1)  # Bright glow
	material.flags_transparent = true
	material.flags_unshaded = true
	mesh_instance.set_surface_override_material(0, material)
	
	# Animate the attack line
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Start narrow and expand briefly
	scale = Vector3(0.1, 1.0, 1.0)  # Very thin initially
	tween.tween_property(self, "scale", Vector3(1.0, 1.2, 1.0), 0.1)  # Expand width
	
	# Quick fade out
	tween.tween_property(material, "albedo_color:a", 0.0, 0.25)
	tween.tween_property(self, "scale", Vector3(1.2, 0.8, 1.0), 0.25)

func _on_timer_timeout():
	queue_free()
