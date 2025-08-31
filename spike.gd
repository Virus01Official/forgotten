extends Area3D

var damage = 0

func initialize(dmg: int) -> void:
	damage = dmg
	get_tree().create_timer(2.0).timeout.connect(queue_free)

func _on_body_entered(body: Node) -> void:
	if body is CharacterBody3D and body.health > 0:
		body.health -= damage
