extends CharacterBody3D

const WALK_SPEED = 5.0
const SPRINT_SPEED = 9.0
const JUMP_VELOCITY = 4.5
const MOUSE_SENSITIVITY = 0.003

var heal_duration := 5.0 # how many seconds the healing takes
var heal_timer := 0.0

var survivor_health = {
	"Chance": 80,
	"Engineer": 95
}

var stunned = false
var stun_timer: float = 0.0

var healing = false

const STUN_DURATION: float = 2.0

@export var isKiller := false:
	set(value):
		isKiller = value
		if isKiller:
			maxhealth = 1000
			health = maxhealth
		else:
			if survivor_health.has(selectedSurvivor):
				maxhealth = survivor_health[selectedSurvivor]
				health = maxhealth
				
@export var spike_scene: PackedScene
@export var malice = 1
var health = 100
var maxhealth = 100

@onready var voiceline = $"../voicelines"

var testVoiceline = preload("res://assets/voicelines/envy/voiceline.mp3")

var killer_stun_voicelines = {
	"envy": [
		preload("res://assets/voicelines/envy/voiceline_stun.mp3"),
	],
}

var void_throw = preload("res://void_throw.tscn")

var weakness = 0

var luckToken = 0
var alive = true
var spikeTimer = 0

var held_object = null

var spikeDelay = 20

var MAX_STAMINA = 100.0
const STAMINA_DRAIN = 25.0   
const STAMINA_RECOVER = 15.0 
const STAMINA_RECOVER_EXHAUSTED = 5 
const ATTACK_DURATION = 0.2
const envy_DASH_SPEED = 30.0
const envy_DASH_TIME = 1.0
const envy_DASH_DAMAGE = 40

var spikeUsed = false

const SLASHER_SPIKE_SPEED = 20.0
const SLASHER_SPIKE_DAMAGE = 30

var damage = 20

@export var selectedKiller = "envy"
@export var selectedSkin = "Default"
@export var selectedSurvivor: String = "Chance"

@onready var camera: Camera3D = $Camera3D
@onready var hitbox: Area3D = $hitbox
@onready var hitbox_shape: CollisionShape3D = $hitbox/CollisionShape3D
@onready var hitbox_mesh: MeshInstance3D = $hitbox/MeshInstance3D
@onready var GUI = $GUI
@onready var Stamina = $GUI/Stamina
@onready var Health = $GUI/Health
@onready var effects = $GUI/GridContainer/Label
@onready var tokensGui = $GUI/TextureButton5/Token
@onready var healthText = $GUI/Health/Label
@onready var StaminaText = $GUI/Stamina/Label
@onready var healingBar = $GUI/ProgressBar

var pitch: float = 0.0
var stamina: float = MAX_STAMINA
var is_sprinting: bool = false
var attack_timer: float = 0.0
var attacking: bool = false

var cola_active: bool = false
var cola_timer: float = 0.0
const COLA_DURATION: float = 15.0
const COLA_SPEED_MULTIPLIER: float = 2.0

var dash_timer = 0.0
var dashing = false

var exhausted: bool = false       
var sprint_needs_reset: bool = false 

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)

		pitch -= event.relative.y * MOUSE_SENSITIVITY
		pitch = clamp(pitch, deg_to_rad(-80), deg_to_rad(80))
		camera.rotation.x = pitch

func start_healing():
	healingBar.visible = true
	healing = true
	heal_timer = 0.0
	healingBar.value = 0
	healingBar.max_value = heal_duration
	
func _physics_process(delta: float) -> void:
	set_meta("Type", selectedSurvivor)
		
	if attacking:
		attack_timer -= delta
		if attack_timer <= 0.0:
			attacking = false
			hitbox.monitoring = false
			hitbox_mesh.visible = false
			
	# Gravity
	if not is_on_floor():
		velocity += get_gravity() * delta
		
	tokensGui.text = str(luckToken)
	
	Health.max_value = maxhealth
	healthText.text = str(health) + "/" + str(maxhealth)
	
	Stamina.max_value = MAX_STAMINA
	StaminaText.text = str(int(stamina)) + "/" + str(MAX_STAMINA)
	
	if healing:
		heal_timer += delta
		healingBar.value = heal_timer

		if heal_timer >= heal_duration:
			# Healing complete
			health = maxhealth
			healing = false
			healingBar.visible = false
	# Jump
	#if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		#velocity.y = JUMP_VELOCITY

	# Attack
	if Input.is_action_just_pressed("primary") and not attacking:
		if isKiller:
			hitbox.monitoring = true
			attacking = true
			hitbox_mesh.visible = true
			attack_timer = ATTACK_DURATION
			damage = 20
		else:
			if held_object:
				if held_object.name == "medkit":
					start_healing()
					held_object.used = true
				elif held_object.name == "cola":
					held_object.used = true
					cola_active = true
					cola_timer = COLA_DURATION
					print("Cola activated: Speed boost for 15 seconds!")
				held_object = null
		
	elif Input.is_action_just_pressed("ability1") and not attacking:
		if isKiller:
			if selectedKiller == "Slasher":
				hitbox.monitoring = true
				attacking = true
				hitbox_mesh.visible = true
				attack_timer = 0.5
				damage = 35
			elif selectedKiller == "envy":
				if $RayCast3D.is_colliding():
					var collider = $RayCast3D.get_collider()
					
					if collider is CharacterBody3D and not collider.isKiller and collider.health > 0:
						collider.health = collider.health - 50
						print(collider, " took 50 damage")
		else:
			if selectedSurvivor == "Chance":
				var num = randi_range(1, 2)
				if num == 1:
					if luckToken < 3:
						luckToken = luckToken + 1
						print("Luck Token: ", luckToken)
				elif num == 2:
					weakness = weakness + 1
					print("Weakness: ", weakness)
					effects.text = "Weakness: " + str(weakness)
							
	elif Input.is_action_just_pressed("ability2") and not attacking:
		if isKiller:
			if selectedKiller == "envy":
				dashing = true
				dash_timer = envy_DASH_TIME
				hitbox.monitoring = true
				hitbox_mesh.visible = true # optional, keep hitbox invisible during dash
				damage = envy_DASH_DAMAGE
			elif selectedKiller == "Slasher":
				hitbox.monitoring = true
				attacking = true
				hitbox_mesh.visible = true
				attack_timer = 0.5
				damage = 50
		else:
			if selectedSurvivor == "Chance":
				var num = randi_range(1, 3)
				
				if num == 1:
					if $RayCast3D.is_colliding():
						var collider = $RayCast3D.get_collider()
						if collider.isKiller:
							collider.health -= 30
							print(collider, " took 30 damage")
						else:
							print("Hit something, but not the killer")
					else:
						print("Shot missed completely")
					luckToken = 0
				elif num == 2:
					health = health - (60 + weakness)
					luckToken = 0
				else:
					print("Gun didn't fire")
					luckToken = 0
							
	elif Input.is_action_just_pressed("ability3") and not attacking:
		if isKiller:
			if selectedKiller == "Slasher" and not spikeUsed:
				spawn_spike()
				spikeUsed = true
				spikeTimer = spikeDelay
		else:
			if selectedSurvivor == "Chance" and luckToken > 0:
				if health == maxhealth:
					maxhealth = randi_range(60, 300)
					health = maxhealth
				else:
					maxhealth = randi_range(60, 300)
				luckToken = 0
	elif Input.is_action_just_pressed("ability4") and not attacking:
		if isKiller:
			return
		else:
			if selectedSurvivor == "Chance" and luckToken == 3:
				luckToken = 0
				weakness = 0
						
	var current_speed = WALK_SPEED
	
	if cola_active:
		cola_timer -= delta
		if cola_timer <= 0:
			cola_active = false
			cola_timer = 0
			print("Cola effect ended")
			
	if cola_active:
		current_speed *= COLA_SPEED_MULTIPLIER
		
	if stamina <= 0.0:
		exhausted = true
		sprint_needs_reset = true
		
	if spikeUsed:
		spikeTimer -= delta
		if spikeTimer <= 0:
			spikeUsed = false
		
	if dashing:
		dash_timer -= delta
		if dash_timer > 0:
			velocity = -transform.basis.z * envy_DASH_SPEED
		else:
			dashing = false
			hitbox.monitoring = false
			hitbox_mesh.visible = false
	
	if isKiller:
		MAX_STAMINA = 110
		Stamina.max_value = 110
	else:
		MAX_STAMINA = 100
		Stamina.max_value = 100
		
	if held_object:
		var collisionShape = held_object.get_node("CollisionShape3D")
		var offset = Vector3(0, 0, -1) 
		held_object.global_position = global_transform.origin + global_transform.basis * offset
		collisionShape.disabled = true
	
	if $interactionRaycast.is_colliding():
		var collider = $interactionRaycast.get_collider()
		
		if collider.name == "generator":
			if Input.is_action_just_pressed("interact") and not isKiller:
				print("gen task")
		elif collider.get_parent().is_in_group("items"):
			if Input.is_action_just_pressed("interact") and not isKiller:
				held_object = collider
		
	if Input.is_action_pressed("sprint") and not exhausted and not sprint_needs_reset:
		is_sprinting = true
	else:
		is_sprinting = false
	
	if is_sprinting:
		current_speed = SPRINT_SPEED
		if cola_active:
			current_speed *= COLA_SPEED_MULTIPLIER
		stamina = max(stamina - STAMINA_DRAIN * delta, 0.0)
	else:
		
		if exhausted:
			stamina = min(stamina + STAMINA_RECOVER_EXHAUSTED * delta, MAX_STAMINA)
			if stamina >= MAX_STAMINA * 0.25:
				exhausted = false
		else:
			stamina = min(stamina + STAMINA_RECOVER * delta, MAX_STAMINA)
	
	
	if not Input.is_action_pressed("sprint"):
		sprint_needs_reset = false
	
	if health <= 0:
		alive = false
	
	Stamina.value = floor(stamina)
	Health.value = floor(health)
	
	if stunned:
		stun_timer -= delta
		if stun_timer <= 0.0:
			stunned = false
			stun_timer = 0.0
		
		# prevent movement/attacks while stunned
		velocity.x = move_toward(velocity.x, 0, WALK_SPEED)
		velocity.z = move_toward(velocity.z, 0, WALK_SPEED)
		move_and_slide()
		return
	
	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if direction and not dashing and not healing:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, WALK_SPEED)
		velocity.z = move_toward(velocity.z, 0, WALK_SPEED)

	move_and_slide()
	
func _on_hitbox_body_entered(body: Node) -> void:
	if body is CharacterBody3D and body != self and body.health > 0:
		body.health = body.health - damage
		if body.health <= 0:
			if isKiller and Gamedata.killer_voicelines["kill"].has(selectedKiller):
				var lines = Gamedata.killer_voicelines["kill"][selectedKiller]
				if lines.size() > 0:
					var random_line = lines[randi() % lines.size()]
					voiceline.stream = random_line
					voiceline.play()
					$"../IntermissionTimer".wait_time += 0.3 
		
func apply_stun(duration: float = STUN_DURATION) -> void:
	stunned = true
	stun_timer = duration
	# Optional: add a visual or UI effect
	print("Player stunned for ", duration, " seconds!")
	if isKiller and killer_stun_voicelines.has(selectedKiller):
		var lines = killer_stun_voicelines[selectedKiller]
		if lines.size() > 0:
			var random_line = lines[randi() % lines.size()]
			voiceline.stream = random_line
			voiceline.play()

func spawn_spike():
	if spike_scene == null:
		print("No spike scene assigned!")
		return
	
	# Player's forward direction (ignores mouse ray)
	var forward = -global_transform.basis.z.normalized()
	var start_pos = global_transform.origin - Vector3.UP * 0.5  # chest height
	
	# Spawn multiple spikes in a line ahead
	for i in range(5):
		var spike = spike_scene.instantiate()
		get_tree().current_scene.add_child(spike)
		
		spike.global_transform.origin = start_pos + forward * (i * 2.0)
		spike.look_at(spike.global_transform.origin + forward, Vector3.UP)
		
		if spike.has_method("initialize"):
			spike.initialize(SLASHER_SPIKE_DAMAGE)
			
# boobs
