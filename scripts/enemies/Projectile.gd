extends RigidBody3D
## Projectile system for ranged enemies
## Handles arrow/magic projectile physics and damage

var velocity: Vector3
var damage: float = 15.0
var lifetime: float = 8.0  # Auto-destroy after 8 seconds
var hit_something: bool = false

signal projectile_hit(target, damage_amount)

func _ready():
	# Setup physics
	set_gravity_scale(0.2)
	set_contact_monitor(true)
	set_max_contacts_reported(10)
	
	# Connect collision signal
	body_entered.connect(_on_body_entered)
	
	# Auto-destroy timer
	var timer = Timer.new()
	timer.wait_time = lifetime
	timer.one_shot = true
	timer.timeout.connect(_on_lifetime_expired)
	add_child(timer)
	timer.start()
	
	print("🏹 Projectile created with damage: ", damage)

func _physics_process(_delta):
	# Apply custom velocity (since we're using RigidBody3D)
	if not hit_something:
		linear_velocity = velocity

func _on_body_entered(body):
	"""Handle collision with objects"""
	if hit_something:
		return
	
	hit_something = true
	print("🏹 Projectile hit: ", body.name)
	
	# Check if hit player
	if body.has_method("take_damage"):
		body.take_damage(damage, self)
		projectile_hit.emit(body, damage)
		print("💥 Projectile dealt ", damage, " damage to ", body.name)
	
	# Stop movement
	linear_velocity = Vector3.ZERO
	set_freeze_enabled(true)
	
	# Hide projectile and destroy
	hide()
	await get_tree().create_timer(0.1).timeout
	queue_free()

func _on_lifetime_expired():
	"""Auto-destroy after lifetime expires"""
	if not hit_something:
		print("🏹 Projectile expired after ", lifetime, " seconds")
		queue_free()

func set_damage(new_damage: float):
	"""Set projectile damage"""
	damage = new_damage

func set_velocity(new_velocity: Vector3):
	"""Set projectile velocity"""
	velocity = new_velocity