extends CharacterBody3D
## Controle principal do Khenti - Príncipe egípcio do Sands of Duat
## Sistema de movimento isométrico 3D otimizado para ultrawide 165Hz

signal health_changed(new_health, max_health)
signal player_died
signal dash_performed
signal ability_used(ability_name)  # Used in Sprint 4 for ability system

# Referências aos nós
@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var camera_arm: Node3D = $CameraArm
@onready var visual_effects: Node3D = $VisualEffects
@onready var audio: AudioStreamPlayer3D = $Audio
@onready var attack_system: Node = $AttackSystem

# Stats base do jogador (conectados com GameManager)
var max_health: float = 100.0
var current_health: float = 100.0
var movement_speed: float = 8.0  # Aumentado para 165Hz
var dash_speed: float = 20.0
var dash_duration: float = 0.3
var dash_cooldown: float = 1.5

# Estados de movimento e combate
var is_dashing: bool = false
var is_stunned: bool = false
var is_attacking: bool = false
var movement_modifier: float = 1.0  # For attack slowdown
var dash_timer: float = 0.0
var dash_cooldown_timer: float = 0.0

# Direções baseadas na câmera (calculadas dinamicamente)
# Será definido em _ready() baseado na orientação real da câmera
var camera_forward: Vector3
var camera_back: Vector3  
var camera_left: Vector3
var camera_right: Vector3

# Física
const GRAVITY = 9.8
const JUMP_VELOCITY = 4.5

func _ready():
	print("👑 Khenti initialized - Prince of the Duat")
	
	# Adiciona ao grupo player para detecção de inimigos
	add_to_group("player")
	
	# Sincroniza stats com GameManager
	sync_with_game_manager()
	
	# Conecta sinais
	connect_signals()
	
	# Setup visual inicial
	setup_player_visual()
	
	# Calcula direções baseadas na câmera
	setup_camera_directions()
	
	print("⚡ Movement speed optimized for 165Hz: ", movement_speed)

func sync_with_game_manager():
	"""Sincroniza stats do player com GameManager"""
	if GameManager:
		var stats = GameManager.player_stats
		max_health = stats.get("max_health", 100)
		current_health = stats.get("current_health", 100)
		movement_speed = stats.get("movement_speed", 8.0)
		dash_cooldown = stats.get("dash_cooldown", 1.5)
		
		print("📊 Stats synced with GameManager")

func connect_signals():
	"""Conecta sinais importantes"""
	if GameManager:
		health_changed.connect(_on_health_changed)
		player_died.connect(GameManager.handle_game_over)

func setup_player_visual():
	"""Configura visual básico do Khenti (placeholder)"""
	# Material dourado egípcio básico
	var material = StandardMaterial3D.new()
	material.albedo_color = Color.GOLD
	material.metallic = 0.3
	material.roughness = 0.7
	mesh_instance.material_override = material
	
	print("✨ Player visual configured - Golden Egyptian theme")

func setup_camera_directions():
	"""Calcula direções de movimento baseadas na orientação da câmera"""
	var camera = get_viewport().get_camera_3d()
	if not camera:
		print("⚠️ Camera not found, using default directions")
		# Fallback para direções padrão
		camera_forward = Vector3(0, 0, -1)
		camera_back = Vector3(0, 0, 1)
		camera_left = Vector3(-1, 0, 0)
		camera_right = Vector3(1, 0, 0)
		return
	
	# Pega as direções da câmera (já na orientação correta)
	var cam_transform = camera.global_transform
	
	# Forward/Back da câmera (direção Z)
	var cam_forward = -cam_transform.basis.z
	cam_forward.y = 0  # Mantém no plano horizontal
	cam_forward = cam_forward.normalized()
	
	# Right/Left da câmera (direção X)  
	var cam_right = cam_transform.basis.x
	cam_right.y = 0  # Mantém no plano horizontal
	cam_right = cam_right.normalized()
	
	# Mapeia para os controles WASD
	camera_forward = cam_forward    # W = "para frente" da câmera
	camera_back = -cam_forward      # S = "para trás" da câmera
	camera_right = cam_right        # D = "para direita" da câmera  
	camera_left = -cam_right        # A = "para esquerda" da câmera
	
	print("📐 Camera directions calculated:")
	print("  Forward (W): ", camera_forward)
	print("  Right (D): ", camera_right)

func _physics_process(delta):
	"""Loop principal de física do player - 165Hz ready"""
	# Gravity
	if not is_on_floor():
		velocity.y -= GRAVITY * delta

	# Dash system
	update_dash_system(delta)
	
	# Movement input (apenas se não estiver dashando ou stunned)
	if not is_dashing and not is_stunned:
		handle_movement_input(delta)
	
	# Apply movement
	move_and_slide()
	
	# Update visual effects based on movement
	update_movement_effects()

func handle_movement_input(delta):
	"""Processa input de movimento isométrico"""
	var input_vector = Vector3.ZERO
	
	# WASD input com direções calculadas pela câmera
	if Input.is_action_pressed("move_up"):      # W
		input_vector += camera_forward
	if Input.is_action_pressed("move_down"):    # S  
		input_vector += camera_back
	if Input.is_action_pressed("move_left"):    # A
		input_vector += camera_left
	if Input.is_action_pressed("move_right"):   # D
		input_vector += camera_right
	
	# Normalize diagonal movement
	if input_vector.length() > 0:
		input_vector = input_vector.normalized()
		
		# Apply movement with modifier (attacks slow you down)
		var final_speed = movement_speed * movement_modifier
		velocity.x = input_vector.x * final_speed
		velocity.z = input_vector.z * final_speed
		
		# Rotate player to face movement direction (only when not attacking)
		if not is_attacking:
			look_at(global_position + input_vector, Vector3.UP)
	else:
		# Friction when not moving
		velocity.x = move_toward(velocity.x, 0, movement_speed * 3 * delta)
		velocity.z = move_toward(velocity.z, 0, movement_speed * 3 * delta)

func update_dash_system(delta):
	"""Sistema de dash com cooldown"""
	# Update timers
	if dash_timer > 0:
		dash_timer -= delta
		if dash_timer <= 0:
			is_dashing = false
			print("⚡ Dash ended")
	
	if dash_cooldown_timer > 0:
		dash_cooldown_timer -= delta
	
	# Check for dash input
	if Input.is_action_just_pressed("dash") and can_dash():
		perform_dash()

func can_dash() -> bool:
	"""Verifica se pode fazer dash"""
	return dash_cooldown_timer <= 0 and not is_dashing and not is_stunned

func perform_dash():
	"""Executa dash na direção do movimento"""
	var dash_direction = Vector3.ZERO
	
	# Get current movement direction or forward if stationary
	if velocity.length() > 0.1:
		dash_direction = Vector3(velocity.x, 0, velocity.z).normalized()
	else:
		dash_direction = -transform.basis.z  # Forward direction
	
	# Apply dash velocity
	velocity.x = dash_direction.x * dash_speed
	velocity.z = dash_direction.z * dash_speed
	
	# Set dash state
	is_dashing = true
	dash_timer = dash_duration
	dash_cooldown_timer = dash_cooldown
	
	print("💨 Dash performed - Direction: ", dash_direction)
	dash_performed.emit()
	
	# TODO: Add dash visual effects in Sprint 8

func take_damage(amount: float, source: Node = null):
	"""Sistema de dano"""
	if is_dashing:
		print("🛡️  Damage blocked by dash i-frames")
		return
	
	current_health = max(current_health - amount, 0)
	print("💔 Khenti took ", amount, " damage - Health: ", current_health, "/", max_health)
	
	health_changed.emit(current_health, max_health)
	
	# Check for death
	if current_health <= 0:
		die()

func heal(amount: float):
	"""Sistema de cura"""
	current_health = min(current_health + amount, max_health)
	print("💚 Khenti healed ", amount, " - Health: ", current_health, "/", max_health)
	
	health_changed.emit(current_health, max_health)

func die():
	"""Morte do jogador"""
	print("☠️  Khenti has fallen - Returning to the Duat...")
	is_stunned = true
	
	# TODO: Add death animation in Sprint 8
	
	player_died.emit()

func update_movement_effects():
	"""Atualiza efeitos visuais baseados no movimento"""
	var is_moving = velocity.length() > 0.1 and is_on_floor()
	
	if is_moving and not is_dashing:
		# TODO: Add walking dust particles in Sprint 8
		pass
	elif is_dashing:
		# TODO: Add dash trail effect in Sprint 8
		pass

func _on_health_changed(new_health: float, max_hp: float):
	"""Callback para mudanças de vida"""
	# Update GameManager stats
	if GameManager:
		GameManager.player_stats.current_health = new_health
		GameManager.player_stats.max_health = max_hp

func set_movement_modifier(modifier: float):
	"""Define modificador de velocidade (usado pelo sistema de ataque)"""
	movement_modifier = modifier
	
	if modifier < 1.0:
		is_attacking = true
	else:
		is_attacking = false

func get_movement_info() -> Dictionary:
	"""Retorna informações de movimento para debug"""
	var attack_info = {}
	if attack_system and attack_system.has_method("get_attack_info"):
		attack_info = attack_system.get_attack_info()
	
	return {
		"position": global_position,
		"velocity": velocity,
		"speed": velocity.length(),
		"is_dashing": is_dashing,
		"is_attacking": is_attacking,
		"is_on_floor": is_on_floor(),
		"health": current_health,
		"dash_cooldown": dash_cooldown_timer,
		"attack_info": attack_info
	}

# Input handling para abilities (implementadas nos próximos sprints)
func _input(event):
	"""Handle input events"""
	if event.is_action_pressed("attack"):
		# Perform basic attack with Was Scepter
		if attack_system and attack_system.has_method("perform_basic_attack"):
			attack_system.perform_basic_attack()
	
	if event.is_action_pressed("ability_1"):
		# TODO: Implement abilities in Sprint 4  
		print("🔥 Ability 1 - Coming in Sprint 4")
	
	if event.is_action_pressed("ability_2"):
		print("⚡ Ability 2 - Coming in Sprint 4")
	
	if event.is_action_pressed("ability_3"):
		print("💫 Ability 3 - Coming in Sprint 4")
