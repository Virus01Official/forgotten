extends Control

func _on_button_pressed() -> void:
	GDSync.lobby_create($Panel/LineEdit.text, $Panel/LineEdit2.text)
