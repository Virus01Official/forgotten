extends Node

var coins: int = 0
var owned_items: Array[String] = []

# Separate dictionaries for voicelines and chase themes
var killer_voicelines := {
	"kill": {},
	"intro": {},
	"victory": {}
}

var killer_chase_themes := {}  # <-- NEW dictionary just for chase themes

# Example structure
var shop_items := {
	"envy_default_skin": {
		"type": "skin",
		"killer": "envy",
		"price": 500,
		"limited": false,
		"unlocks": {
			"kill": [
				"res://assets/voicelines/envy/voiceline.mp3",
				"res://assets/voicelines/envy/voiceline2.mp3",
				"res://assets/voicelines/envy/voiceline3.mp3",
				"res://assets/voicelines/envy/becca_uwu.mp3",
				"res://assets/voicelines/envy/voiceline4.mp3",
			],
			"chase": [
				"res://assets/music/Chase.mp3",
			],
			"intro": [
				"res://assets/voicelines/envy/intro1.mp3"
			],
			"victory": [
				"res://assets/voicelines/envy/victory1.mp3"
			]
		}
	},
	"virus": {
		"type": "skin",
		"killer": "envy",
		"price": 0,
		"limited": true, 
		"unlocks": {
			"kill": [
				"res://assets/voicelines/envy/skins/virus/voiceline.mp3",
				"res://assets/voicelines/envy/voiceline2.mp3"
			],
			"chase": [
				"res://assets/music/Chase.mp3",
			],
			"intro": [
				"res://assets/voicelines/envy/skins/virus/virus_intro.mp3"
			],
			"victory": [
				"res://assets/voicelines/envy/victory1.mp3"
			]
		}
	},
	"Gambler": {
		"type": "survivor",
		"price": 300
	},
	"default_slasher": {
		"type": "skin",
		"killer": "slasher",
		"price": 0,
		"limited": false,
	},
}

func _ready() -> void:
	init_default_voicelines()
	init_default_chase_themes()

func save_progress():
	var save_data = {
		"coins": coins,
		"owned_items": owned_items
	}
	var f = FileAccess.open("user://savegame.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(save_data))
	f.close()
	print("Game saved!")

func load_progress():
	if not FileAccess.file_exists("user://savegame.json"):
		print("No save file found, starting fresh")
		return
	var f = FileAccess.open("user://savegame.json", FileAccess.READ)
	var data = JSON.parse_string(f.get_as_text())
	f.close()
	if data:
		coins = data["coins"]
		owned_items = data["owned_items"]
	print("Game loaded! Coins:", coins, " Items:", owned_items)

func add_voiceline(category: String, killer: String, path: String) -> void:
	if not killer_voicelines[category].has(killer):
		killer_voicelines[category][killer] = []
	killer_voicelines[category][killer].append(load(path))

func add_chase_theme(killer: String, path: String) -> void:
	if not killer_chase_themes.has(killer):
		killer_chase_themes[killer] = []
	killer_chase_themes[killer].append(load(path))

func init_default_voicelines() -> void:
	if not killer_voicelines["kill"].has("envy"):
		killer_voicelines["kill"]["envy"] = [
			load("res://assets/voicelines/envy/voiceline.mp3"),
			load("res://assets/voicelines/envy/voiceline2.mp3"),
			load("res://assets/voicelines/envy/voiceline3.mp3"),
			load("res://assets/voicelines/envy/becca_uwu.mp3"),
			load("res://assets/voicelines/envy/voiceline4.mp3")
		]

	if not killer_voicelines["intro"].has("envy"):
		killer_voicelines["intro"]["envy"] = [
			load("res://assets/voicelines/envy/glitch.mp3")
		]

	if not killer_voicelines["victory"].has("envy"):
		killer_voicelines["victory"]["envy"] = [
			load("res://assets/voicelines/envy/glitch.mp3")
		]

func init_default_chase_themes() -> void:
	if not killer_chase_themes.has("envy"):
		killer_chase_themes["envy"] = [
			load("res://assets/music/Chase.mp3")
		]

func buy_item(item_id: String) -> bool:
	if not Gamedata.shop_items.has(item_id):
		print("No such item:", item_id)
		return false
	
	var item = Gamedata.shop_items[item_id]

	if item.get("limited", false):
		print(item_id, "is limited and cannot be bought")
		return false
	
	if item_id in Gamedata.owned_items:
		print("Already owned!")
		return false
	
	if Gamedata.coins < item.price:
		print("Not enough coins!")
		return false
	
	Gamedata.coins -= item.price
	Gamedata.owned_items.append(item_id)

	if "unlocks" in item:
		for category in item.unlocks.keys():
			for v in item.unlocks[category]:
				if category == "chase":
					Gamedata.add_chase_theme(item.killer, v)
				else:
					Gamedata.add_voiceline(category, item.killer, v)
	
	Gamedata.save_progress()
	print("Bought", item_id)
	return true

func grant_item(item_id: String):
	if not Gamedata.shop_items.has(item_id):
		return
	if item_id in Gamedata.owned_items:
		return
	Gamedata.owned_items.append(item_id)
	var item = Gamedata.shop_items[item_id]
	if "unlocks" in item:
		for category in item.unlocks.keys():
			for v in item.unlocks[category]:
				if category == "chase":
					Gamedata.add_chase_theme(item.killer, v)
				else:
					Gamedata.add_voiceline(category, item.killer, v)
	Gamedata.save_progress()
	print("Granted limited item:", item_id)
