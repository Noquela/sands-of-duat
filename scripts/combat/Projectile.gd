# Projectile.gd
# Divine Projectile for Sands of Duat ability system
# Sprint 5: Special Abilities - Divine Projectile

extends RigidBody3D

var damage: float = 60.0
var speed: float = 15.0
var lifetime: float = 3.0
var direction: Vector3

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var collision_shape: CollisionShape3D = $CollisionShape3D

func _ready():
	# Setup projectile appearance
	if not mesh_instance.mesh:
		# Create ankh-shaped placeholder (cylinder for now)
		var cylinder_mesh = CylinderMesh.new()
		cylinder_mesh.top_radius = 0.1
		cylinder_mesh.bottom_radius = 0.1
		cylinder_mesh.height = 0.5
		mesh_instance.mesh = cylinder_mesh
		
		# Apply golden material
		var material = StandardMaterial3D.new()
		material.albedo_color = Color.GOLD
		material.emission_enabled = true
		material.emission = Color(1.0, 0.8, 0.0, 1.0)
		material.emission_energy = 1.5
		mesh_instance.material_override = material
	
	# Set collision layer for projectiles
	collision_layer = 8  # Layer 4 (Projectiles)
	collision_mask = 4   # Layer 2 (Enemies)
	
	# Connect collision signal
	body_entered.connect(_on_body_entered)
	
	# Set lifetime timer
	var timer = get_tree().create_timer(lifetime)
	timer.timeout.connect(_on_lifetime_expired)
	
	print("🏺 Divine projectile ready - damage: %.1f, speed: %.1f" % [damage, speed])

func setup_projectile(proj_direction: Vector3, proj_damage: float, proj_speed: float):
	"""Setup projectile parameters"""
	direction = proj_direction.normalized()
	damage = proj_damage
	speed = proj_speed
	
	# Set initial velocity
	linear_velocity = direction * speed
	
	# Orient projectile to face direction
	if direction.length() > 0.1:
		look_at(global_position + direction, Vector3.UP)
	
	print("⚡ Divine projectile launched: direction %s, damage %.1f" % [direction, damage])

func _on_body_entered(body: Node3D):
	"""Handle collision with enemies"""
	if body.is_in_group("enemies"):
		# Deal damage to enemy
		if body.has_method("take_damage"):
			body.take_damage(int(damage), "divine_projectile")
			print("🎯 Divine projectile hit %s for %.1f damage!" % [body.name, damage])
		
		# Create impact effect
		_create_impact_effect()
		
		# Destroy projectile
		queue_free()
	elif body.is_in_group("environment"):
		# Hit environment, create effect and destroy
		print("💥 Divine projectile hit environment")
		_create_impact_effect()
		queue_free()

func _on_lifetime_expired():
	"""Projectile expired naturally"""
	print("🌟 Divine projectile faded away")
	_create_fade_effect()
	queue_free()

func _create_impact_effect():
	"""Create impact visual effect"""
	# TODO: Create proper particle effect
	print("✨ Divine impact effect at %s" % global_position)

func _create_fade_effect():
	"""Create fade visual effect"""
	# TODO: Create proper fade particle effect
	print("🌟 Divine fade effect at %s" % global_position)