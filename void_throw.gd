extends Area3D

var idfk = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func _on_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D and body != idfk and body.health > 0:
		body.health = body.health - 15
