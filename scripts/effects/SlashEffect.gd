# SlashEffect.gd
# Professional slash arc effect using GPUParticles3D
# Based on research of best practices for combat VFX

extends GPUParticles3D

@export var slash_material: ParticleProcessMaterial
var original_position: Vector3

func _ready():
	# Configure GPUParticles3D for slash effect
	emitting = false
	amount = 100  # Number of particles
	lifetime = 0.5  # Effect duration
	one_shot = true  # Single emission
	explosiveness = 1.0  # All particles at once for instant slash
	
	# Setup process material if not assigned
	if not process_material:
		_create_slash_material()

func _create_slash_material():
	# Create professional particle material for slash effect
	var material = ParticleProcessMaterial.new()
	
	# Emission settings
	material.direction = Vector3(0, 0, -1)
	material.initial_velocity_min = 2.0
	material.initial_velocity_max = 8.0
	material.angular_velocity_min = -180.0
	material.angular_velocity_max = 180.0
	
	# Spread for arc effect
	material.spread = 45.0  # Creates arc-like spread
	material.flatness = 0.8  # Flattens to create slash appearance
	
	# Scale animation for dramatic effect
	material.scale_min = 0.1
	material.scale_max = 0.3
	var scale_curve = Curve.new()
	scale_curve.add_point(Vector2(0.0, 0.0))  # Start invisible
	scale_curve.add_point(Vector2(0.1, 1.0))  # Quick expansion
	scale_curve.add_point(Vector2(1.0, 0.0))  # Fade to invisible
	material.scale_curve = scale_curve
	
	# Color gradient for golden slash
	var gradient = Gradient.new()
	gradient.add_point(0.0, Color(1.0, 0.9, 0.2, 1.0))  # Bright gold
	gradient.add_point(0.5, Color(1.0, 0.6, 0.1, 0.8))  # Orange-gold
	gradient.add_point(1.0, Color(0.8, 0.3, 0.0, 0.0))  # Fade to transparent
	material.color = Color.WHITE
	material.color_ramp = gradient
	
	# Gravity and damping
	material.gravity = Vector3(0, -2, 0)  # Slight downward pull
	material.damping_min = 1.0
	material.damping_max = 3.0
	
	process_material = material

func create_slash_at(start_pos: Vector3, direction: Vector3, slash_size: float = 1.0):
	# Position and orient the slash effect
	global_position = start_pos
	
	# Orient toward slash direction
	if direction.length() > 0.1:
		look_at(start_pos + direction, Vector3.UP)
	
	# Scale based on attack range
	scale = Vector3.ONE * slash_size
	
	# Start the particle emission
	restart()
	emitting = true
	
	print("⚔️ Professional slash effect created at: " + str(start_pos))
	
	# Auto cleanup after effect
	get_tree().create_timer(lifetime + 0.1).timeout.connect(_cleanup)

func _cleanup():
	queue_free()