extends RigidBody3D
## Projectile for Sacred Bolt ability - Sprint 5

var damage: float = 35.0
var speed: float = 15.0
var lifetime: float = 3.0
var owner_node: Node = null

func _ready():
	print("🔮 Sacred Bolt projectile created")
	
	# Set physics properties
	gravity_scale = 0.1  # Slight downward arc
	linear_damp = 0.0    # No air resistance
	
	# Connect collision signal
	body_entered.connect(_on_body_entered)
	
	# Auto-destroy after lifetime
	get_tree().create_timer(lifetime).timeout.connect(_on_lifetime_expired)

func set_damage(new_damage: float):
	"""Set projectile damage"""
	damage = new_damage

func set_projectile_owner(new_owner: Node):
	"""Set projectile owner"""
	owner_node = new_owner

func launch(direction: Vector3, launch_speed: float = 15.0):
	"""Launch projectile in direction"""
	speed = launch_speed
	linear_velocity = direction.normalized() * speed
	print("🔮 Projectile launched with speed: ", speed)

func _on_body_entered(body):
	"""Handle collision with other bodies"""
	if body == owner_node:
		return  # Ignore collision with owner
	
	if body.is_in_group("enemies"):
		# Hit enemy
		if body.has_method("take_damage"):
			body.take_damage(damage, owner_node)
			print("🔮 Sacred Bolt hit ", body.name, " for ", damage, " damage!")
		
		# Create hit effect
		create_hit_effect()
		destroy_projectile()
		
	elif body.is_in_group("environment") or body.is_in_group("walls"):
		# Hit wall or environment
		print("🔮 Sacred Bolt hit wall")
		create_hit_effect()
		destroy_projectile()

func create_hit_effect():
	"""Create visual effect on impact"""
	print("✨ Sacred Bolt impact effect")
	# TODO: Add particle effects, light flash, etc.

func _on_lifetime_expired():
	"""Handle projectile lifetime expiration"""
	print("🔮 Sacred Bolt expired")
	destroy_projectile()

func destroy_projectile():
	"""Safely destroy projectile"""
	if is_inside_tree():
		queue_free()