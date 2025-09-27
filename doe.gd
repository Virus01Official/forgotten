extends CharacterBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 4.5

var malice = 0

@export var isKiller = true

var alive = true

var health = 100

@onready var hitbox: Area3D = $hitbox
@onready var hitbox_shape: CollisionShape3D = $hitbox/CollisionShape3D
@onready var hitbox_mesh: MeshInstance3D = $hitbox/MeshInstance3D

const ATTACK_DURATION = 0.2  # seconds hitbox is active
var attack_timer: float = 0.0
var attacking: bool = false

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	move_and_slide()
	
	if not attacking:
		hitbox.monitoring = true
		attacking = true
		hitbox_mesh.visible = true
		attack_timer = ATTACK_DURATION

func _on_hitbox_body_entered(body: Node) -> void:
	if body is CharacterBody3D and body != self and not body.isKiller and body.health > 0:
		body.health = body.health - (25 + body.weakness)
