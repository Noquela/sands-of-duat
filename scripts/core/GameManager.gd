extends Node
## Singleton principal que gerencia o estado global do jogo Sands of Duat
## Responsável por coordenar sistemas, persistência e fluxo principal

signal player_died
signal run_completed
signal boon_selected(boon_data)
signal room_entered(room_type)
signal boss_defeated(boss_name)

# Estados do jogo
enum GameState {
	MENU,
	PLAYING,
	PAUSED,
	INVENTORY,
	DIALOGUE,
	GAME_OVER,
	VICTORY
}

# Variáveis de estado global
var current_state: GameState = GameState.MENU
var current_run_data: Dictionary = {}
var player_stats: Dictionary = {}
var persistent_data: Dictionary = {}

# Referências importantes
var player_node: Node = null
var current_room: Node = null
var hud_manager: Node = null

# Configurações de desempenho
var target_fps: int = 60
var enable_debug: bool = false

func _ready():
	print("🏛️ Sands of Duat - GameManager initialized")
	print("⚡ Target FPS: ", target_fps)
	
	# Configura performance inicial
	Engine.max_fps = target_fps
	
	# Inicializa dados de run
	reset_run_data()
	
	# Carrega dados persistentes (se existirem)
	load_persistent_data()
	
	# Conecta sinais importantes
	connect_global_signals()

func _process(_delta):
	# Debug info (apenas se habilitado)
	if enable_debug and Input.is_action_just_pressed("ui_accept"):
		print_debug_info()

func reset_run_data():
	"""Reseta dados da run atual - chamado no início de cada tentativa"""
	current_run_data = {
		"rooms_cleared": 0,
		"enemies_defeated": 0,
		"damage_dealt": 0,
		"damage_taken": 0,
		"boons_collected": [],
		"currency_earned": 0,
		"time_started": Time.get_unix_time_from_system(),
		"deaths": 0,
		"current_biome": "cavernas_esquecidos"
	}
	
	player_stats = {
		"max_health": 100,
		"current_health": 100,
		"base_damage": 25,
		"movement_speed": 5.0,
		"dash_cooldown": 2.0,
		"attack_speed": 1.0
	}
	
	print("🔄 Run data reset - New attempt started")

func change_state(new_state: GameState):
	"""Muda o estado do jogo com validação"""
	var old_state = current_state
	current_state = new_state
	
	print("🎮 State changed: ", GameState.keys()[old_state], " → ", GameState.keys()[new_state])
	
	# Lógica específica por estado
	match current_state:
		GameState.PLAYING:
			Engine.time_scale = 1.0
		GameState.PAUSED:
			Engine.time_scale = 0.0
		GameState.GAME_OVER:
			handle_game_over()
		GameState.VICTORY:
			handle_victory()

func handle_game_over():
	"""Processa morte do player e fim da run"""
	current_run_data.deaths += 1
	var run_time = Time.get_unix_time_from_system() - current_run_data.time_started
	
	print("💀 Game Over - Run duration: ", "%.1f" % run_time, "s")
	print("📊 Rooms cleared: ", current_run_data.rooms_cleared)
	print("👹 Enemies defeated: ", current_run_data.enemies_defeated)
	
	# Salva estatísticas para analytics
	save_run_statistics()
	
	# Emite sinal para UI e outros sistemas
	player_died.emit()

func handle_victory():
	"""Processa vitória da run"""
	var run_time = Time.get_unix_time_from_system() - current_run_data.time_started
	
	print("👑 Victory! Run completed in ", "%.1f" % run_time, "s")
	print("🏆 Perfect run: ", current_run_data.deaths == 0)
	
	# Adiciona rewards por completar run
	add_persistent_currency("memory_fragments", 50)
	
	# Salva progresso
	save_run_statistics()
	save_persistent_data()
	
	run_completed.emit()

func add_boon(boon_data: Dictionary):
	"""Adiciona boon à run atual"""
	current_run_data.boons_collected.append(boon_data)
	
	print("✨ Boon added: ", boon_data.get("name", "Unknown"))
	
	# Aplica efeitos do boon
	apply_boon_effects(boon_data)
	
	boon_selected.emit(boon_data)

func apply_boon_effects(boon_data: Dictionary):
	"""Aplica os efeitos de um boon aos stats do player"""
	var effects = boon_data.get("effects", {})
	
	for stat in effects:
		if stat in player_stats:
			var old_value = player_stats[stat]
			
			# Diferentes tipos de modificação
			if boon_data.get("type") == "multiplicative":
				player_stats[stat] *= (1.0 + effects[stat])
			else:
				player_stats[stat] += effects[stat]
			
			print("📈 Stat changed - %s: %.1f → %.1f" % [stat, old_value, player_stats[stat]])

func add_persistent_currency(currency_type: String, amount: int):
	"""Adiciona moeda persistente (meta-progression)"""
	if not persistent_data.has("currencies"):
		persistent_data.currencies = {}
	
	if not persistent_data.currencies.has(currency_type):
		persistent_data.currencies[currency_type] = 0
	
	persistent_data.currencies[currency_type] += amount
	print("💰 Added %d %s (total: %d)" % [amount, currency_type, persistent_data.currencies[currency_type]])

func save_run_statistics():
	"""Salva estatísticas da run para analytics"""
	var stats_data = current_run_data.duplicate()
	stats_data.merge(player_stats)
	
	# TODO: Implementar analytics mais avançados no Sprint 4
	print("📊 Run statistics saved")

func save_persistent_data():
	"""Salva dados persistentes em arquivo"""
	var save_file = FileAccess.open("user://sands_of_duat_save.dat", FileAccess.WRITE)
	if save_file:
		save_file.store_string(JSON.stringify(persistent_data))
		save_file.close()
		print("💾 Persistent data saved")
	else:
		print("❌ Failed to save persistent data")

func load_persistent_data():
	"""Carrega dados persistentes do arquivo"""
	var save_file = FileAccess.open("user://sands_of_duat_save.dat", FileAccess.READ)
	if save_file:
		var json_string = save_file.get_as_text()
		save_file.close()
		
		var json = JSON.new()
		var parse_result = json.parse(json_string)
		
		if parse_result == OK:
			persistent_data = json.get_data()
			print("📁 Persistent data loaded")
		else:
			print("❌ Failed to parse save data")
	else:
		print("📁 No save data found - starting fresh")
		persistent_data = {
			"currencies": {
				"memory_fragments": 0,
				"ankh_fragments": 0,
				"golden_scarabs": 0,
				"heart_pieces": 0
			},
			"weapons_unlocked": ["was_scepter"],
			"upgrades_purchased": [],
			"achievements": [],
			"runs_completed": 0,
			"total_deaths": 0
		}

func connect_global_signals():
	"""Conecta sinais importantes do jogo"""
	# Conectar sinais de outros sistemas quando forem criados
	pass

func print_debug_info():
	"""Imprime informações de debug úteis"""
	print("\n=== DEBUG INFO ===")
	print("State: ", GameState.keys()[current_state])
	print("FPS: ", Engine.get_frames_per_second())
	print("Player Health: ", player_stats.current_health, "/", player_stats.max_health)
	print("Rooms Cleared: ", current_run_data.rooms_cleared)
	print("Boons: ", current_run_data.boons_collected.size())
	print("=================\n")

func get_run_progress() -> float:
	"""Retorna progresso da run atual (0.0 a 1.0)"""
	# TODO: Implementar baseado na estrutura do Duat
	var max_rooms = 30  # Placeholder
	return float(current_run_data.rooms_cleared) / float(max_rooms)

func is_run_active() -> bool:
	"""Verifica se há uma run ativa"""
	return current_state == GameState.PLAYING

func quit_to_menu():
	"""Volta ao menu principal"""
	change_state(GameState.MENU)
	# TODO: Carregar cena do menu quando for criada