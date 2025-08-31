extends Node3D

var last_played_type := ""

var IntroPlaying = false

var victoryPlaying = false

@onready var IntroCam = $IntroCam

@onready var VicCam = $VicCamera

var is_Chase = false

var killer_songs = {
	"john doe": preload("res://assets/music/compass.mp3"),
	"annihilation": preload("res://assets/music/close to me.mp3"),
	"1x": preload("res://assets/music/creation of hatred.mp3"),
	"c00lkid": preload("res://assets/music/c00lkid plead.mp3")
}

var killer_chase = {
	"john doe": preload("res://assets/music/Chase.mp3"),
	"annihilation": preload("res://assets/music/Chase.mp3"),
	"1x": preload("res://assets/music/Chase.mp3"),
	"c00lkid": preload("res://assets/music/Chase.mp3")
}

var killer_victory_voicelines = {
	"envy": preload("res://assets/voicelines/envy/glitch.mp3")
}

var killer_requirements = {
	"annihilation": "elliot", 
	"1x": "Shedletsky",
	"c00lkid": "n7"
}

var default_song = preload("res://assets/music/vanity.mp3")

func _ready() -> void:
	Gamedata.load_progress()
	start_round()
	Network.create_server(1234)
	Network.create_client("127.0.0.1", 1234)
	
func _on_round_end():
	Gamedata.save_progress()

func _physics_process(_delta: float) -> void:
	var killers := []
	var survivor_types := []
	
	for items in get_tree().get_nodes_in_group("items"):
		for item in items.get_children():
			if item.used:
				remove_child(items)
			
	
	for player in get_tree().get_nodes_in_group("players"):
		if player.has_meta("Type"):
			var t = str(player.get_meta("Type")).strip_edges().to_lower()
			if t in killer_songs:
				killers.append(t)
			else:
				survivor_types.append(t)  

	var new_type := "default"

	for killer in killers:
		var k = killer.strip_edges().to_lower()
		if k in killer_requirements:
			var required_survivor = killer_requirements[k].strip_edges().to_lower()
			if required_survivor in survivor_types:
				new_type = k  
				break
		else:
			new_type = k  
			break

	if new_type != last_played_type:
		last_played_type = new_type
		if new_type in killer_songs:
			$LMS.stream = killer_songs[new_type]
		else:
			$LMS.stream = default_song
		$LMS.play()
		
func play_intro_line(killer: String):
	if Gamedata.killer_voicelines["intro"].has(killer):
		var lines = Gamedata.killer_voicelines["intro"][killer]
		if lines.size() > 0:
			var random_line = lines[randi() % lines.size()]
			$IntroAudio.stream = random_line
			$IntroAudio.play()
	
func start_round() -> void:
	var players = get_tree().get_nodes_in_group("players")
	if players.is_empty():
		return
	
	# Reset all players first
	for player in players:
		player.isKiller = false
	
	# Find the player with the most malice
	var killer = players[0]
	for player in players:
		if player.malice > killer.malice:
			killer = player
	
	# Assign killer role
	killer.isKiller = true
	
	print(killer.name, " is the killer for this round with malice: ", killer.malice)
