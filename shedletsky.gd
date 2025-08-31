extends CharacterBody3D

var malice = 100

var alive = true
@export var isKiller = false
const SPEED = 5.0
const JUMP_VELOCITY = 4.5
var health = 100

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor() and alive:
		velocity += get_gravity() * delta
	
	if health <= 0:
		alive = false
		
	move_and_slide()

func _on_hitbox_body_entered(body: Node) -> void:
	if body is CharacterBody3D and body != self and body.health > 0 and body.isKiller:
		body.apply_stun(3.0)
		body.health = body.health - 30
