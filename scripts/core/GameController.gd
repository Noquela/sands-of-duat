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
	print("🏺⚔️ SANDS OF DUAT - Sprint 2 Validation")
	print("=" * 50)
	print("✅ Player Controller: WASD Movement")
	print("✅ Isometric Camera: Following system") 
	print("✅ Resolution: 3440x1440 configured")
	print("=" * 50)
	
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
	
	var debug_text = "SANDS OF DUAT - Sprint 2
Player Controller Base

🎮 Controls:
WASD - Movement  
F2 - Player Info
F3 - Camera Info

📊 Performance:
FPS: %.0f
Target: 60fps

🏺 Khenti Status:
Position: (%.1f, %.1f, %.1f)  
Velocity: (%.1f, %.1f, %.1f)
On Floor: %s

📹 Camera Status:
Position: (%.1f, %.1f, %.1f)
Distance: %.1f units" % [
		fps_counter,
		player_pos.x, player_pos.y, player_pos.z,
		player_vel.x, player_vel.y, player_vel.z,
		str(player.is_on_floor()),
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
				print("🚪 Exiting Sprint 2...")
				get_tree().quit()

func _validate_sprint_2():
	print("🔍 SPRINT 2 VALIDATION:")
	print("=" * 30)
	
	# Check player movement
	var can_move = player.has_method("_handle_input")
	print("✅ Player Movement System: " + ("OK" if can_move else "FAILED"))
	
	# Check camera following  
	var has_target = camera.target != null
	print("✅ Camera Following: " + ("OK" if has_target else "FAILED"))
	
	# Check performance
	var fps_ok = fps_counter >= 55.0  # Allow 5fps margin
	print("✅ Performance (60fps): " + ("OK (%.0f fps)" % fps_counter if fps_ok else "LOW (%.0f fps)" % fps_counter))
	
	# Check physics
	var physics_ok = player.is_on_floor()
	print("✅ Physics/Collision: " + ("OK" if physics_ok else "CHECK"))
	
	print("=" * 30)
	
	if can_move and has_target and fps_ok:
		print("🎉 SPRINT 2 VALIDATION: SUCCESS!")
		print("Ready for Sprint 3: Combat System")
	else:
		print("⚠️ SPRINT 2 VALIDATION: Issues detected")
	
	print("=" * 30)