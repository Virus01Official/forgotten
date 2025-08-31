extends Node

func create_server(port: int = 1234):
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(port)
	if error != OK:
		push_error("Failed to start server on port %d" % port)
		return
	multiplayer.multiplayer_peer = peer
	print("Server started on port", port)

func create_client(address: String, port: int = 1234):
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(address, port)
	if error != OK:
		push_error("Failed to connect to server")
		return
	multiplayer.multiplayer_peer = peer
	print("Connected to server at %s:%d" % [address, port])

func _ready():
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)

func _on_peer_connected(id: int):
	print("Peer connected:", id)

func _on_peer_disconnected(id: int):
	print("Peer disconnected:", id)
