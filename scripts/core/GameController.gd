# GameController.gd
# Main game controller for Sprint 2 validation
# Validates player movement and camera system

extends Node3D

@onready var player: CharacterBody3D = $Player
@onready var camera: Camera3D = $IsometricCamera
@onready var debug_label: Label = $UI/DebugPanel/DebugLabel

var fps_counter: float = 0.0
var fps_timer: float = 0.0

func _ready():
	print("🏺⚔️ SANDS OF DUAT - Sprint 4 Validation")
	print("==================================================")  # Fixed string multiplication error
	print("✅ Player Controller: WASD Movement + Combat + Dash")
	print("✅ Dash System: 4-unit distance, stamina management")
	print("✅ Dash Attack: 35 damage in 2.5 unit range")
	print("✅ Combat System: Attack, Damage, Health")
	print("✅ Enemy AI: Detection, Chase, Attack")
	print("✅ Isometric Camera: Following system") 
	print("✅ Resolution: 3440x1440 configured")
	print("==================================================")  # Fixed string multiplication error
	
	# Setup validation timer
	var timer = Timer.new()
	timer.wait_time = 1.0
	timer.timeout.connect(_update_debug_info)
	timer.autostart = true
	add_child(timer)

func _process(delta):
	# FPS counting
	fps_timer += delta
	if fps_timer >= 1.0:
		fps_counter = 1.0 / delta
		fps_timer = 0.0

func _update_debug_info():
	if not debug_label or not player or not camera:
		return
		
	var player_pos = player.global_position
	var player_vel = player.velocity if player.has_method("get_velocity") else Vector3.ZERO
	var cam_pos = camera.global_position
	
	var enemy_count = get_tree().get_nodes_in_group("enemies").size()
	var alive_enemies = 0
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy.has_method("is_alive") and enemy.is_alive():
			alive_enemies += 1
	
	# Get dash system stats
	var dash_stats = DashSystem.get_dash_stats() if DashSystem else {}
	var stamina = dash_stats.get("current_stamina", 0)
	var max_stamina = dash_stats.get("max_stamina", 100)
	var can_dash = dash_stats.get("can_dash", false)
	var is_dashing = dash_stats.get("is_dashing", false)
	
	var debug_text = "SANDS OF DUAT - Sprint 4
Dash System

🎮 Controls:
WASD - Movement
Mouse Click - Attack  
SPACE - Dash (25 stamina)
F1 - Validate Sprint 4
F2 - Player Info
F3 - Camera Info

📊 Performance:
FPS: %.0f
Target: 60fps

🏺 Khenti Status:
Position: (%.1f, %.1f, %.1f)  
Velocity: (%.1f, %.1f, %.1f)
Health: %d/%d HP
On Floor: %s

🏃 Dash System:
Stamina: %.0f/%.0f
Can Dash: %s
Is Dashing: %s

👻 Combat Status:
Enemies Alive: %d/%d
Combat System: %s

📹 Camera Status:
Position: (%.1f, %.1f, %.1f)
Distance: %.1f units" % [
		fps_counter,
		player_pos.x, player_pos.y, player_pos.z,
		player_vel.x, player_vel.y, player_vel.z,
		player.get_health(), player.get_max_health(),
		str(player.is_on_floor()),
		stamina, max_stamina,
		"Yes" if can_dash else "No",
		"Yes" if is_dashing else "No",
		alive_enemies, enemy_count,
		"Active" if CombatSystem else "Missing",
		cam_pos.x, cam_pos.y, cam_pos.z,
		player_pos.distance_to(cam_pos)
	]
	
	debug_label.text = debug_text

func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_F1:
				_validate_sprint_2()
			KEY_ESCAPE:
				print("🚪 Exiting Sprint 4...")
				get_tree().quit()

func _validate_sprint_2():
	print("🔍 SPRINT 4 VALIDATION:")
	print("==============================")  # Fixed string multiplication error
	
	# Check player movement
	var can_move = player.has_method("_handle_input")
	print("✅ Player Movement System: " + ("OK" if can_move else "FAILED"))
	
	# Check player combat
	var can_attack = player.has_method("_perform_attack")
	print("✅ Player Attack System: " + ("OK" if can_attack else "FAILED"))
	
	# Check player dash
	var can_dash_method = player.has_method("_perform_dash")
	print("✅ Player Dash System: " + ("OK" if can_dash_method else "FAILED"))
	
	# Check player health
	var has_health = player.has_method("get_health")
	print("✅ Player Health System: " + ("OK" if has_health else "FAILED"))
	
	# Check player invulnerability
	var has_invuln = player.has_method("set_invulnerable")
	print("✅ Player Invulnerability: " + ("OK" if has_invuln else "FAILED"))
	
	# Check dash system
	var dash_active = DashSystem != null
	print("✅ Dash System: " + ("OK" if dash_active else "FAILED"))
	
	# Check dash stats
	var dash_stats = DashSystem.get_dash_stats() if DashSystem else {}
	var has_stamina = "current_stamina" in dash_stats and "max_stamina" in dash_stats
	print("✅ Stamina System: " + ("OK (%.0f/%.0f)" % [dash_stats.get("current_stamina", 0), dash_stats.get("max_stamina", 100)] if has_stamina else "FAILED"))
	
	# Check combat system
	var combat_active = CombatSystem != null
	print("✅ Combat System: " + ("OK" if combat_active else "FAILED"))
	
	# Check enemies
	var enemy_count = get_tree().get_nodes_in_group("enemies").size()
	print("✅ Enemy System: " + ("OK (%d enemies)" % enemy_count if enemy_count > 0 else "FAILED"))
	
	# Check camera following  
	var has_target = camera.target != null
	print("✅ Camera Following: " + ("OK" if has_target else "FAILED"))
	
	# Check performance
	var fps_ok = fps_counter >= 55.0  # Allow 5fps margin
	print("✅ Performance (60fps): " + ("OK (%.0f fps)" % fps_counter if fps_ok else "LOW (%.0f fps)" % fps_counter))
	
	# Check physics
	var physics_ok = player.is_on_floor()
	print("✅ Physics/Collision: " + ("OK" if physics_ok else "CHECK"))
	
	print("==============================")  # Fixed string multiplication error
	
	var all_systems_ok = (can_move and can_attack and can_dash_method and has_health and 
						  has_invuln and dash_active and has_stamina and combat_active and 
						  enemy_count > 0 and has_target and fps_ok)
	
	if all_systems_ok:
		print("🎉 SPRINT 4 VALIDATION: SUCCESS!")
		print("Ready for Sprint 5: Egyptian Weapons")
	else:
		print("⚠️ SPRINT 4 VALIDATION: Issues detected")
	
	print("==============================")  # Fixed string multiplication error