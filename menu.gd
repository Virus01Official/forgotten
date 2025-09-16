extends Control

var loggedIn : bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	GDSync.start_multiplayer()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if loggedIn:
		$Login.visible = false
		$CreateAccount.visible = false
		$LobbyBrowser.visible = true
