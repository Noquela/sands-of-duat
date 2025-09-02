extends Label3D
class_name DamageNumber

func _ready():
	modulate = Color.RED
	font_size = 32
	billboard = BaseMaterial3D.BILLBOARD_ENABLED
	
	# Create tween for floating animation
	var tween = create_tween()
	tween.parallel().tween_property(self, "position", position + Vector3(0, 2, 0), 1.0)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 1.0)
	
	await tween.finished
	queue_free()

func show_damage(damage: float, pos: Vector3):
	text = str(int(damage))
	position = pos