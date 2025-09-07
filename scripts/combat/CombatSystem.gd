# CombatSystem.gd
# Main Combat System for Sands of Duat
# Sprint 3: Combat System Base
# Handles attack mechanics, damage calculation, and combat flow

extends Node

signal damage_dealt(target: Node3D, damage: int, damage_type: String)
signal enemy_defeated(enemy: Node3D)
signal player_hit(damage: int)

# Combat settings from roadmap
const BASE_ATTACK_DAMAGE = 25
const ATTACK_RANGE = 2.0
const ATTACK_COOLDOWN = 0.5
const CRIT_CHANCE = 0.15
const CRIT_MULTIPLIER = 1.5

# Combat state
var is_attacking: bool = false
var attack_timer: float = 0.0
var combo_count: int = 0
var combo_timer: float = 0.0
const COMBO_WINDOW = 1.5

func _ready():
	print("⚔️ Combat System: Sprint 3 Initialized")
	print("   Base Damage: %d" % BASE_ATTACK_DAMAGE)
	print("   Attack Range: %.1f units" % ATTACK_RANGE)
	print("   Crit Chance: %.1f%%" % (CRIT_CHANCE * 100))

func _process(delta):
	# Handle attack cooldown
	if attack_timer > 0:
		attack_timer -= delta
		if attack_timer <= 0:
			is_attacking = false
	
	# Handle combo timer
	if combo_timer > 0:
		combo_timer -= delta
		if combo_timer <= 0:
			combo_count = 0

# Main attack function called by player
func perform_attack(attacker: Node3D, attack_position: Vector3, attack_direction: Vector3) -> bool:
	if is_attacking or attack_timer > 0:
		return false
	
	print("⚔️ Khenti attacks! Position: " + str(attack_position))
	
	is_attacking = true
	attack_timer = ATTACK_COOLDOWN
	
	# Increment combo
	combo_count += 1
	combo_timer = COMBO_WINDOW
	
	# Find targets in range
	var targets = _find_targets_in_range(attack_position, ATTACK_RANGE)
	
	# Apply damage to all targets
	for target in targets:
		if target.has_method("take_damage"):
			var damage = _calculate_damage(attacker, target)
			target.take_damage(damage, "physical")
			damage_dealt.emit(target, damage, "physical")
			
			# Create hit flash effect on enemy
			_create_hit_effect(target)
			
			# Check if enemy defeated
			if target.has_method("get_health") and target.get_health() <= 0:
				enemy_defeated.emit(target)
	
	# Create attack effect
	_create_attack_effect(attack_position, attack_direction)
	
	return true

func _find_targets_in_range(position: Vector3, attack_range: float) -> Array[Node3D]:
	var targets: Array[Node3D] = []
	var _space_state = get_tree().current_scene.get_world_3d().direct_space_state
	
	# Find all enemies in range
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if not enemy is Node3D:
			continue
			
		var distance = position.distance_to(enemy.global_position)
		if distance <= attack_range:
			targets.append(enemy)
			print("🎯 Target found: " + enemy.name + " (distance: %.1f)" % distance)
	
	return targets

func _calculate_damage(attacker: Node3D, target: Node3D) -> int:
	var base_damage = BASE_ATTACK_DAMAGE
	
	# Combo bonus
	var combo_bonus = 1.0 + (combo_count - 1) * 0.1  # +10% per combo hit
	base_damage *= combo_bonus
	
	# Critical hit check
	var is_crit = randf() < CRIT_CHANCE
	if is_crit:
		base_damage *= CRIT_MULTIPLIER
		print("💥 CRITICAL HIT! %.1fx damage" % CRIT_MULTIPLIER)
	
	# Apply attacker bonuses if available
	if attacker.has_method("get_attack_power"):
		base_damage += attacker.get_attack_power()
	
	# Apply target resistances if available
	if target.has_method("get_defense"):
		base_damage = max(1, base_damage - target.get_defense())
	
	var final_damage = int(base_damage)
	print("⚔️ Damage calculated: %d (combo: x%.1f)" % [final_damage, combo_bonus])
	
	return final_damage

func _create_attack_effect(position: Vector3, direction: Vector3):
	# Create visual attack effect
	var effect_scene = preload("res://scenes/effects/AttackSwipe.tscn")
	if effect_scene:
		var effect = effect_scene.instantiate()
		get_tree().current_scene.add_child(effect)
		effect.global_position = position
		effect.look_at(position + direction, Vector3.UP)
		print("✨ Attack effect created at: " + str(position))

func _create_hit_effect(target: Node3D):
	# Create hit flash effect on enemy
	var hit_flash_script = preload("res://scripts/effects/HitFlash.gd")
	if hit_flash_script and target:
		var hit_effect = Node3D.new()
		hit_effect.set_script(hit_flash_script)
		get_tree().current_scene.add_child(hit_effect)
		
		# Find enemy mesh
		var enemy_mesh = target.get_node_or_null("MeshInstance3D")
		if enemy_mesh:
			hit_effect.setup(enemy_mesh)
			print("💥 Hit effect created on: " + target.name)

# Damage dealing to player
func deal_damage_to_player(player: Node3D, damage: int, damage_type: String = "physical"):
	if player.has_method("take_damage"):
		player.take_damage(damage, damage_type)
		player_hit.emit(damage)
		print("💔 Player takes %d %s damage" % [damage, damage_type])

# Get combat stats for UI
func get_combat_stats() -> Dictionary:
	return {
		"is_attacking": is_attacking,
		"attack_cooldown": attack_timer,
		"combo_count": combo_count,
		"combo_timer": combo_timer,
		"base_damage": BASE_ATTACK_DAMAGE
	}

# Reset combat state (for scene changes, etc.)
func reset_combat():
	is_attacking = false
	attack_timer = 0.0
	combo_count = 0
	combo_timer = 0.0
	print("⚔️ Combat system reset")