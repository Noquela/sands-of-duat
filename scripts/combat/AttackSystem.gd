extends Node
## Sistema de Ataque do Khenti - Was Scepter (cetro egípcio)
## Combate básico com timing e hit detection

signal attack_started(attack_type)
signal attack_hit(enemy, damage)
signal attack_finished(attack_type)

# Referência ao player
@onready var player: CharacterBody3D = get_parent()

# Configurações de ataque básico
var base_damage: float = 25.0
var attack_range: float = 2.5
var attack_speed: float = 1.0
var attack_cooldown: float = 0.6

# Estados de ataque
var is_attacking: bool = false
var attack_timer: float = 0.0
var cooldown_timer: float = 0.0
var current_attack: String = ""

# Hit detection
var hit_area: Area3D = null
var hit_enemies: Array[Node] = []

# Combos (implementados em sprints futuros)
var combo_count: int = 0
var combo_timer: float = 0.0
const COMBO_WINDOW: float = 1.0

func _ready():
	print("⚔️ Attack System initialized - Was Scepter ready")
	
	# Sync with GameManager stats
	sync_with_game_manager()
	
	# Create hit detection area
	setup_hit_area()
	
	# Connect signals
	connect_signals()

func sync_with_game_manager():
	"""Sincroniza stats de ataque com GameManager"""
	if GameManager:
		var stats = GameManager.player_stats
		base_damage = stats.get("base_damage", 25.0)
		attack_speed = stats.get("attack_speed", 1.0)
		
		# Calculate actual values
		attack_cooldown = 0.6 / attack_speed
		
		print("⚔️ Attack stats synced - Damage: ", base_damage, " Speed: ", attack_speed)

func setup_hit_area():
	"""Cria área de detecção de hits"""
	hit_area = Area3D.new()
	hit_area.name = "AttackHitArea"
	
	# Collision shape for melee attacks
	var collision_shape = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(4.0, 3.0, 4.0)  # Área de ataque maior para garantir hit
	collision_shape.shape = shape
	
	hit_area.add_child(collision_shape)
	player.add_child.call_deferred(hit_area)
	
	# Configure collision layers
	hit_area.collision_layer = 0  # Don't collide with anything
	hit_area.collision_mask = 2   # Detect enemies (layer 2)
	
	# Connect area signals
	hit_area.body_entered.connect(_on_enemy_entered_attack_area)
	hit_area.body_exited.connect(_on_enemy_exited_attack_area)
	
	# Initially disable hit area
	hit_area.monitoring = false
	hit_area.monitorable = false
	
	print("🎯 Attack hit area configured")

func connect_signals():
	"""Conecta sinais importantes"""
	attack_hit.connect(_on_attack_hit)

func _on_attack_hit(enemy: Node, damage: float):
	"""Callback quando um ataque acerta um inimigo"""
	# TODO: Add hit effects like screen shake, particles, etc. in Sprint 8
	print("🎯 Attack hit callback - Enemy: ", enemy.name, ", Damage: ", damage)

func _process(delta):
	"""Update attack system"""
	# Update timers
	if attack_timer > 0:
		attack_timer -= delta
		if attack_timer <= 0:
			finish_attack()
	
	if cooldown_timer > 0:
		cooldown_timer -= delta
	
	if combo_timer > 0:
		combo_timer -= delta
		if combo_timer <= 0:
			combo_count = 0

func can_attack() -> bool:
	"""Verifica se pode atacar"""
	return not is_attacking and cooldown_timer <= 0 and not player.is_dashing

func perform_basic_attack():
	"""Executa ataque básico com Was Scepter"""
	if not can_attack():
		return false
	
	print("⚔️ Was Scepter attack!")
	
	# Set attack state
	is_attacking = true
	current_attack = "basic_melee"
	attack_timer = 0.3  # Attack duration
	cooldown_timer = attack_cooldown
	
	# Update combo
	combo_timer = COMBO_WINDOW
	combo_count += 1
	combo_count = min(combo_count, 3)  # Max 3-hit combo
	
	# Enable hit detection
	enable_hit_detection()
	
	# Apply movement slowdown during attack
	if player.has_method("set_movement_modifier"):
		player.set_movement_modifier(0.3)  # 30% speed during attack
	
	# Emit signal
	attack_started.emit(current_attack)
	
	# TODO: Add attack animation in Sprint 8
	# TODO: Add attack sound in Sprint 5
	
	return true

func enable_hit_detection():
	"""Ativa detecção de hits"""
	if hit_area:
		hit_area.monitoring = true
		hit_enemies.clear()
		
		# Position hit area in front of player (baseado na direção que está olhando)
		var forward_dir = -player.transform.basis.z
		hit_area.position = forward_dir * 1.5  # Colocar mais perto do player
		
		# Schedule hit detection disable
		await get_tree().create_timer(0.2).timeout
		disable_hit_detection()

func disable_hit_detection():
	"""Desativa detecção de hits"""
	if hit_area:
		hit_area.monitoring = false
		hit_area.position = Vector3.ZERO

func _on_enemy_entered_attack_area(enemy: Node):
	"""Callback quando inimigo entra na área de ataque"""
	if enemy.is_in_group("enemies") and enemy not in hit_enemies:
		hit_enemy(enemy)

func _on_enemy_exited_attack_area(_enemy: Node):
	"""Callback quando inimigo sai da área de ataque"""
	pass

func hit_enemy(enemy: Node):
	"""Aplica dano ao inimigo"""
	if enemy in hit_enemies:
		return  # Evita hit múltiplo no mesmo ataque
	
	hit_enemies.append(enemy)
	
	# Calculate damage with combo multiplier
	var final_damage = base_damage
	match combo_count:
		2:
			final_damage *= 1.2  # +20% no segundo hit
		3:
			final_damage *= 1.5  # +50% no terceiro hit
	
	print("💥 Hit enemy: ", enemy.name, " for ", final_damage, " damage (combo x", combo_count, ")")
	
	# Apply damage to enemy
	if enemy.has_method("take_damage"):
		enemy.take_damage(final_damage, player)
	
	# TODO: Add hit effects in Sprint 8 (screen shake, particles, etc.)
	
	# Emit signal
	attack_hit.emit(enemy, final_damage)

func finish_attack():
	"""Finaliza ataque atual"""
	is_attacking = false
	current_attack = ""
	
	# Restore normal movement
	if player.has_method("set_movement_modifier"):
		player.set_movement_modifier(1.0)
	
	# Disable hit detection
	disable_hit_detection()
	
	print("⚔️ Attack finished")
	attack_finished.emit("basic_melee")

func get_attack_info() -> Dictionary:
	"""Retorna informações de ataque para debug"""
	return {
		"is_attacking": is_attacking,
		"cooldown": cooldown_timer,
		"combo_count": combo_count,
		"combo_timer": combo_timer,
		"base_damage": base_damage,
		"attack_speed": attack_speed,
		"can_attack": can_attack()
	}

# Funções para habilidades futuras
func perform_charged_attack():
	"""Ataque carregado - Sprint 4"""
	print("🔥 Charged attack - Coming in Sprint 4")

func perform_special_ability(ability_name: String):
	"""Habilidades especiais - Sprint 4"""
	print("✨ Special ability: ", ability_name, " - Coming in Sprint 4")

func apply_boon_effects(boon_data: Dictionary):
	"""Aplica efeitos de boons no sistema de ataque"""
	var effects = boon_data.get("effects", {})
	
	if "base_damage" in effects:
		base_damage += effects.base_damage
		print("⚔️ Attack damage increased by ", effects.base_damage)
	
	if "attack_speed" in effects:
		attack_speed += effects.attack_speed
		attack_cooldown = 0.6 / attack_speed
		print("⚡ Attack speed increased to ", attack_speed)
