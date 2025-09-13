extends Node

@export var port: int = 9000
@export var max_players: int = 5  # 1 killer + 4 survivors

var is_host := false

func _ready():
	multiplayer.connected_to_server.connect(_on_connected)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

# === HOST FUNCTIONS ===
func host_game():
	var peer = ENetMultiplayerPeer.new()
	var result = peer.create_server(port, max_players)
	if result != OK:
		push_error("Failed to start server")
		return
	multiplayer.multiplayer_peer = peer
	is_host = true
	print("Server started on port %d" % port)


# === CLIENT FUNCTIONS ===
func join_game(address: String):
	var peer = ENetMultiplayerPeer.new()
	var result = peer.create_client(address, port)
	if result != OK:
		push_error("Failed to connect to server")
		return
	multiplayer.multiplayer_peer = peer
	is_host = false
	print("Connecting to %s:%d" % [address, port])


# === SIGNALS ===
func _on_connected():
	print("Connected to server!")

func _on_connection_failed():
	print("Failed to connect!")

func _on_server_disconnected():
	print("Disconnected from server")
