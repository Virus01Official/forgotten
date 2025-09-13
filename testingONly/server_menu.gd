extends Control

@onready var ip_input = $LineEdit

func _ready():
	pass

func _on_HostButton_pressed():
	Network.host_game()

func _on_JoinButton_pressed():
	Network.join_game("127.0.0.1")

func _on_connected():
	get_tree().change_scene_to_file("res://main.tscn")
