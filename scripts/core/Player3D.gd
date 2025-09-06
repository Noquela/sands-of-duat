extends CharacterBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 4.5

# Preload combat classes
const CombatSystemClass = preload("res://scripts/combat/CombatSystem.gd")
# WeaponSystem now added as child node in scene 
const HealthSystemClass = preload("res://scripts/combat/HealthSystem.gd")
const DashSystemClass = preload("res://scripts/systems/DashSystem.gd")
const AbilitySystemClass = preload("res://scripts/systems/AbilitySystem.gd")

# Advanced combat systems
const ParrySystemClass = preload("res://scripts/combat/ParrySystem.gd")
const ComboSystemClass = preload("res://scripts/combat/ComboSystem.gd")
const StatusEffectsClass = preload("res://scripts/combat/StatusEffects.gd")

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

# Combat components
var combat_system: CombatSystemClass
var weapon_system: Node
var health_system: HealthSystemClass
var dash_system: DashSystemClass
var ability_system: AbilitySystemClass

# Advanced combat components
var parry_system: ParrySystemClass
var combo_system: ComboSystemClass
var status_effects: StatusEffectsClass

# Combat state tracking
var is_blocking: bool = false
var current_combo: Array = []

func _ready():
	add_to_group("player")
	setup_combat_systems()

func setup_combat_systems():
	# Create combat system
	combat_system = CombatSystemClass.new()
	add_child(combat_system)
	
	# Create weapon system
	# Get WeaponSystem node added in scene
	weapon_system = get_node_or_null("WeaponSystem")
	if weapon_system:
		weapon_system.combat_system = combat_system
		# Connect signals for experience gain
		if combat_system and combat_system.has_signal("attack_hit"):
			combat_system.attack_hit.connect(_on_attack_hit)
		if combat_system and combat_system.has_signal("enemy_killed"):
			combat_system.enemy_killed.connect(_on_enemy_killed)
	
	# Create health system
	health_system = HealthSystemClass.new()
	health_system.max_health = 100.0
	health_system.can_regenerate = true
	health_system.regeneration_rate = 5.0
	add_child(health_system)
	
	# Create dash system
	dash_system = DashSystemClass.new()
	add_child(dash_system)
	
	# Connect dash signals
	dash_system.dash_started.connect(_on_dash_started)
	dash_system.dash_ended.connect(_on_dash_ended)
	
	# Create ability system
	ability_system = AbilitySystemClass.new()
	add_child(ability_system)
	
	# Connect ability signals
	ability_system.ability_used.connect(_on_ability_used)
	
	# Create advanced combat systems
	setup_advanced_combat_systems()

func setup_advanced_combat_systems():
	# Create parry system
	parry_system = ParrySystemClass.new()
	add_child(parry_system)
	
	# Connect parry signals
	parry_system.parry_successful.connect(_on_parry_successful)
	parry_system.parry_failed.connect(_on_parry_failed)
	parry_system.counter_attack_ready.connect(_on_counter_attack_ready)
	
	# Create combo system
	combo_system = ComboSystemClass.new()
	add_child(combo_system)
	
	# Connect combo signals
	combo_system.combo_started.connect(_on_combo_started)
	combo_system.combo_continued.connect(_on_combo_continued)
	combo_system.combo_finished.connect(_on_combo_finished)
	combo_system.air_combo_started.connect(_on_air_combo_started)
	
	# Create status effects system
	status_effects = StatusEffectsClass.new()
	add_child(status_effects)
	
	# Connect status effect signals
	status_effects.effect_applied.connect(_on_status_effect_applied)
	status_effects.effect_removed.connect(_on_status_effect_removed)
	status_effects.effect_damage.connect(_on_status_effect_damage)

func _physics_process(delta):
	handle_gravity(delta)
	handle_movement(delta)
	handle_combat()
	
	# Update advanced combat systems
	if parry_system:
		parry_system.update_parry_system(delta)
	if combo_system:
		combo_system.update_combo_system(delta, self)
	if status_effects:
		status_effects.process_effects(delta, self)
		
	move_and_slide()

func handle_combat():
	# Block/Parry input - Hold/Press right mouse button
	if Input.is_action_pressed("block") and parry_system:
		if not is_blocking:
			is_blocking = true
			parry_system.start_blocking(self)
	elif is_blocking and parry_system:
		is_blocking = false
		parry_system.stop_blocking(self)
	
	# Perfect parry timing - Release block at right moment
	if Input.is_action_just_released("block") and parry_system:
		parry_system.attempt_parry(self)
	
	# Attack input with combo system integration
	if Input.is_action_just_pressed("attack"):
		if combo_system and combo_system.can_continue_combo():
			# Continue existing combo
			var attack_success = combat_system.try_attack(self)
			if attack_success:
				combo_system.continue_combo(get_current_weapon_type())
		else:
			# Start new attack/combo
			var attack_success = combat_system.try_attack(self)
			if attack_success and combo_system:
				combo_system.start_combo(get_current_weapon_type())

func get_current_weapon_type() -> String:
	if weapon_system and weapon_system.has_method("get_current_weapon_type"):
		return weapon_system.get_current_weapon_type()
	return "Khopesh"  # Default Egyptian weapon

func handle_gravity(delta):
	if not is_on_floor():
		velocity.y -= gravity * delta

func handle_movement(delta):
	# Don't handle normal movement during dash
	if dash_system and dash_system.is_dashing:
		return
		
	var input_dir = Vector2.ZERO
	
	if Input.is_action_pressed("ui_right") or Input.is_action_pressed("move_right"):
		input_dir.x += 1
	if Input.is_action_pressed("ui_left") or Input.is_action_pressed("move_left"):
		input_dir.x -= 1
	if Input.is_action_pressed("ui_down") or Input.is_action_pressed("move_down"):
		input_dir.y += 1
	if Input.is_action_pressed("ui_up") or Input.is_action_pressed("move_up"):
		input_dir.y -= 1
	
	# Fix isometric movement mapping
	var direction = Vector3.ZERO
	
	if input_dir != Vector2.ZERO:
		# Correct mapping for isometric camera - flip Y input
		direction.x = input_dir.y + input_dir.x   # W should go up (positive direction)
		direction.z = input_dir.y - input_dir.x   # Adjust Z accordingly
		direction = direction.normalized()
	
	if direction != Vector3.ZERO:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
		
		var target_rotation = atan2(-direction.x, -direction.z)
		rotation.y = lerp_angle(rotation.y, target_rotation, 10.0 * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED * 3 * delta)
		velocity.z = move_toward(velocity.z, 0, SPEED * 3 * delta)
	
	# Weapon switching inputs - handled by WeaponSystem itself now
	if weapon_system:
		weapon_system.handle_weapon_switching()
	
	# Special ability input - V key
	if Input.is_action_just_pressed("ability_special") and weapon_system:
		weapon_system.use_special_ability()

# Dash system callbacks
func _on_dash_started():
	print("Player dash started!")
	# Cancel any ongoing attacks
	if combat_system:
		combat_system.is_attacking = false

func _on_dash_ended():
	print("Player dash ended!")

# Ability system callbacks
func _on_ability_used(ability_name: String):
	print("Player used ability: ", ability_name)

# Public API for damage system
func take_damage(damage: float, attacker: Node3D = null):
	# Check for i-frames
	if dash_system and dash_system.is_player_invulnerable():
		print("Damage blocked by i-frames!")
		return
	
	# Check for parry if actively blocking
	if is_blocking and parry_system and attacker:
		if parry_system.try_parry_attack(attacker, damage):
			return  # Attack was parried
	
	# Apply status effect modifiers
	if status_effects:
		damage = status_effects.modify_incoming_damage(damage, self)
	
	# Check for shield
	if has_meta("has_shield"):
		var shield_reduction = get_meta("shield_reduction", 0.0)
		damage = damage * (1.0 - shield_reduction)
		print("Damage reduced by shield: ", damage)
	
	# Apply damage to health system
	if health_system:
		health_system.take_damage(damage)
		print("Player took ", damage, " damage")
		
		# Interrupt combos on significant damage
		if damage > 20.0 and combo_system:
			combo_system.interrupt_combo()

# Weapon experience callbacks
func _on_attack_hit(_enemy: Node3D):
	if weapon_system:
		weapon_system.gain_weapon_experience(weapon_system.current_weapon, weapon_system.mastery_exp_per_hit)

func _on_enemy_killed(_enemy: Node3D):
	if weapon_system:
		weapon_system.gain_weapon_experience(weapon_system.current_weapon, weapon_system.mastery_exp_per_kill)

# Advanced combat system callbacks
func _on_parry_successful(attacker: Node3D, damage_blocked: float):
	print("Perfect parry! Blocked ", damage_blocked, " damage from ", attacker.name)
	
	# Apply parry boon effects
	if status_effects:
		status_effects.apply_effect("Divine_Protection", self, 3.0, {"damage_reduction": 0.3})
	
	# Gain weapon experience for successful parry
	if weapon_system:
		weapon_system.gain_weapon_experience(get_current_weapon_type(), 15)

func _on_parry_failed():
	print("Parry failed - timing was off!")
	
	# Apply brief vulnerability after failed parry
	if status_effects:
		status_effects.apply_effect("Vulnerable", self, 1.0, {"damage_multiplier": 1.2})

func _on_counter_attack_ready(counter_type: String):
	print("Counter attack ready: ", counter_type)
	
	# Visual/audio feedback for available counter
	if weapon_system and weapon_system.has_method("show_counter_indicator"):
		weapon_system.show_counter_indicator(counter_type)

func _on_combo_started(weapon_type: String, combo_name: String):
	print("Started ", weapon_type, " combo: ", combo_name)
	
	# Apply combo starter effects
	if status_effects:
		status_effects.apply_effect("Combat_Focus", self, 5.0, {"attack_speed": 1.2})

func _on_combo_continued(hit_count: int, damage_multiplier: float):
	print("Combo hit ", hit_count, " - damage multiplier: ", damage_multiplier)
	
	# Visual feedback for combo progression
	if weapon_system and weapon_system.has_method("show_combo_counter"):
		weapon_system.show_combo_counter(hit_count, damage_multiplier)

func _on_combo_finished(weapon_type: String, combo_name: String, total_hits: int):
	print("Finished ", weapon_type, " combo: ", combo_name, " (", total_hits, " hits)")
	
	# Apply combo finisher effects
	if total_hits >= 5:
		if status_effects:
			status_effects.apply_effect("Warrior_Fury", self, 8.0, {"damage": 1.5, "attack_speed": 1.3})
	
	# Bonus weapon experience for completed combos
	if weapon_system:
		weapon_system.gain_weapon_experience(weapon_type, total_hits * 5)

func _on_air_combo_started():
	print("Air combo initiated!")
	
	# Reduce gravity during air combo
	gravity = ProjectSettings.get_setting("physics/3d/default_gravity") * 0.3

func _on_status_effect_applied(effect_name: String, duration: float):
	print("Status effect applied: ", effect_name, " for ", duration, "s")
	
	# UI feedback for status effects
	if has_method("update_status_ui"):
		update_status_ui(effect_name, duration, true)

func _on_status_effect_removed(effect_name: String):
	print("Status effect removed: ", effect_name)
	
	# Special cleanup for certain effects
	if effect_name == "Air_Combo_Active":
		# Restore normal gravity
		gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
	
	# UI feedback for status effect removal
	if has_method("update_status_ui"):
		update_status_ui(effect_name, 0.0, false)

func _on_status_effect_damage(damage: float, effect_name: String):
	print("Taking ", damage, " damage from status effect: ", effect_name)
	
	# Apply damage through health system
	if health_system:
		health_system.take_damage(damage)

