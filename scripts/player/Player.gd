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
@onready var dash_system: Node = $DashSystem
@onready var ability_system: Node = $AbilitySystem

# Stats base do jogador (conectados com GameManager)
var max_health: float = 100.0
var current_health: float = 100.0
var movement_speed: float = 8.0  # Aumentado para 165Hz

# Estados de movimento e combate
var is_stunned: bool = false
var is_attacking: bool = false
var movement_modifier: float = 1.0  # For attack slowdown

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

	# Movement input (apenas se não estiver dashando ou stunned)
	var is_dashing = dash_system.is_dashing if dash_system else false
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

func take_damage(amount: float, source: Node = null):
	"""Sistema de dano"""
	# Check for i-frames from dash system
	if dash_system and dash_system.has_iframes:
		print("🛡️ Damage blocked by i-frames")
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
	
	var is_dashing = dash_system.is_dashing if dash_system else false
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
	"""Retorna informações de movimento para debug e outros sistemas"""
	var attack_info = {}
	if attack_system and attack_system.has_method("get_attack_info"):
		attack_info = attack_system.get_attack_info()
	
	var dash_info = {}
	if dash_system and dash_system.has_method("get_dash_info"):
		dash_info = dash_system.get_dash_info()
	
	var ability_info = {}
	if ability_system and ability_system.has_method("get_mana_info"):
		ability_info = ability_system.get_mana_info()
	
	return {
		"position": global_position,
		"velocity": velocity,
		"speed": velocity.length(),
		"is_dashing": dash_info.get("is_dashing", false),
		"is_attacking": is_attacking,
		"is_on_floor": is_on_floor(),
		"health": current_health,
		"attack_info": attack_info,
		"dash_info": dash_info,
		"ability_info": ability_info
	}

# Input handling para attacks
func _input(event):
	"""Handle input events"""
	if event.is_action_pressed("attack"):
		# Perform basic attack with Was Scepter
		if attack_system and attack_system.has_method("perform_basic_attack"):
			attack_system.perform_basic_attack()

# Sprint 5 Integration Functions
func get_camera_directions() -> Dictionary:
	"""Retorna direções da câmera para outros sistemas"""
	return {
		"forward": camera_forward,
		"back": camera_back,
		"left": camera_left,
		"right": camera_right
	}

func cancel_attack():
	"""Cancela ataque atual (usado pelo dash)"""
	if attack_system and attack_system.has_method("cancel_current_attack"):
		attack_system.cancel_current_attack()
	is_attacking = false

func flash_material(color: Color, duration: float):
	"""Flash do material do player (para VFX)"""
	if mesh_instance and mesh_instance.material_override:
		var material = mesh_instance.material_override as StandardMaterial3D
		if material:
			var original_color = material.albedo_color
			material.albedo_color = color
			
			# Restore original color
			await get_tree().create_timer(duration).timeout
			if material:
				material.albedo_color = original_color
