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
	
	GDSync.connected.connect(connected)
	GDSync.connection_failed.connect(connection_failed)
	
	GDSync.lobby_created.connect(lobby_created)
	GDSync.lobby_creation_failed.connect(lobby_creation_failed)
	
	GDSync.lobby_joined.connect(lobby_joined)
	GDSync.lobby_join_failed.connect(lobby_join_failed)
	
	GDSync.start_multiplayer()

func lobby_created(lobby_name : String) -> void:
	print("Created lobby ", lobby_name)
	
	GDSync.lobby_join(lobby_name)
	
func lobby_joined(lobby_name : String) -> void:
	print("Joined lobby ", lobby_name)
	
func lobby_join_failed(lobby_name : String, error : int) -> void:
	print("Failed to join lobby ", lobby_name)
	
	if error == ENUMS.LOBBY_JOIN_ERROR.LOBBY_DOES_NOT_EXIST:
		print("Lobby doesn't exist ", lobby_name)
	if error == ENUMS.LOBBY_JOIN_ERROR.LOBBY_IS_CLOSED:
		print(lobby_name, " is closed")
	if error == ENUMS.LOBBY_JOIN_ERROR.LOBBY_IS_FULL:
		print(lobby_name, " is full")
	if error == ENUMS.LOBBY_JOIN_ERROR.LOBBY_DOES_NOT_EXIST:
		print(lobby_name, " doesn't exist")

func lobby_creation_failed(lobby_name : String, error : int) -> void:
	print("Failed to create lobby ", lobby_name)
	
	if error == ENUMS.LOBBY_CREATION_ERROR.LOBBY_ALREADY_EXISTS:
		GDSync.lobby_join(lobby_name)
	elif error == ENUMS.LOBBY_CREATION_ERROR.NAME_TOO_SHORT:
		print("Too short")
	elif error == ENUMS.LOBBY_CREATION_ERROR.LOCAL_PORT_ERROR:
		print("Port error")
	elif error == ENUMS.LOBBY_CREATION_ERROR.DATA_TOO_LARGE:
		print("too much data")
		
func connected() -> void:
	print("connected")
	GDSync.lobby_create("test")
	start_round()
	
func connection_failed(error : int) -> void:
	match(error):
		ENUMS.CONNECTION_FAILED.INVALID_PUBLIC_KEY:
			push_error("The public or private key are invalid")
		ENUMS.CONNECTION_FAILED.TIMEOUT:
			push_error("Unable to connect, please check your internet connection")
	
func _on_round_end():
	Gamedata.save_progress()
		
func set_killer(player_name: String):
	var killer = get_node_or_null(player_name)
	if killer:
		killer.isKiller = true

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
	
@rpc("any_peer", "call_local")
func play_music(track: String):
	if track in killer_songs:
		$LMS.stream = killer_songs[track]
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
	
	# reset
	for player in players:
		player.isKiller = false
	
	# find killer
	var killer = players[0]
	for player in players:
		if player.malice > killer.malice:
			killer = player

	killer.isKiller = true

	print(killer.name, " is the killer for this round with malice: ", killer.malice)

	# 👇 tell clients who the killer is
	set_killer(killer.name)
