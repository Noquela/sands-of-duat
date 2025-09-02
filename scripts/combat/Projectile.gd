extends RigidBody3D
class_name Projectile

@export var speed: float = 20.0
@export var damage: float = 20.0
@export var lifetime: float = 5.0

var direction: Vector3
var shooter: Node3D

func _ready():
	# Set up collision detection
	body_entered.connect(_on_body_entered)
	
	# Configure RigidBody3D for projectile motion
	gravity_scale = 0.0  # No gravity for arrows
	linear_damp = 0.0    # No air resistance
	angular_damp = 0.0   # No rotation dampening
	
	# Auto-destroy after lifetime
	get_tree().create_timer(lifetime).timeout.connect(queue_free)
	
	print("Arrow created at position: ", global_position)

func setup(launch_direction: Vector3, projectile_damage: float, origin: Node3D):
	direction = launch_direction.normalized()
	damage = projectile_damage
	shooter = origin
	
	# Launch projectile immediately
	linear_velocity = direction * speed
	print("Arrow launched with velocity: ", linear_velocity)
	
	# Orient arrow to face direction of travel
	if direction != Vector3.ZERO:
		look_at(global_position + direction, Vector3.UP)

func _on_body_entered(body):
	print("Arrow hit: ", body.name)
	
	if body == shooter:
		print("Hit shooter, ignoring")
		return
	
	# Check if hit an enemy
	if body.is_in_group("enemies") and body.has_method("take_damage"):
		print("Arrow dealing ", damage, " damage to enemy")
		body.take_damage(damage)
		
		# Spawn damage number
		spawn_damage_number(body, damage)
		
		# Flash enemy red
		flash_target_red(body)
	else:
		print("Hit non-enemy: ", body.name, " Groups: ", body.get_groups())
	
	# Destroy projectile
	queue_free()

func spawn_damage_number(target: Node3D, damage_value: float):
	var DamageNumberClass = preload("res://scripts/ui/DamageNumber.gd")
	var damage_number = DamageNumberClass.new()
	get_tree().current_scene.add_child(damage_number)
	damage_number.show_damage(damage_value, target.global_position + Vector3(0, 2, 0))

func flash_target_red(target: Node3D):
	var mesh_instance = target.get_node("EnemyMesh")
	if mesh_instance and mesh_instance is MeshInstance3D and is_instance_valid(target):
		var original_material = mesh_instance.get_surface_override_material(0)
		var flash_material = StandardMaterial3D.new()
		flash_material.albedo_color = Color.RED
		mesh_instance.set_surface_override_material(0, flash_material)
		
		await get_tree().create_timer(0.1).timeout
		
		# Check if target still exists before restoring material
		if is_instance_valid(target) and is_instance_valid(mesh_instance):
			mesh_instance.set_surface_override_material(0, original_material)