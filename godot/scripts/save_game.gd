class_name SaveGame
extends RefCounted

const PATH := "user://ufa_transit.json"


static func defaults() -> Dictionary:
	return {
		"wallet": 500,
		"alga": false,
		"album": [],
		"best_rating": 0,
		"shifts": 0,
		"earned": 0,
		"quality": "high",
		"car": false,
		"sold": 0,
		"pocket": [],
		"reviews": {},
		"achievements": [],
		"company": false,
		"drivers": 0,
		"fleet_owned": [],
		"pass_left": 0,
		"concession": false,
		"modes": [],
		"open_routes": [],
		"last_profit": 0,
		"ic_runs": 0,
		"ic_earned": 0,
	}


static func load_data() -> Dictionary:
	var data := defaults()
	if not FileAccess.file_exists(PATH):
		return data
	var file := FileAccess.open(PATH, FileAccess.READ)
	if file == null:
		return data
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return data
	for key in data.keys():
		if parsed.has(key):
			data[key] = parsed[key]
	if typeof(data["album"]) != TYPE_ARRAY:
		data["album"] = []
	if typeof(data["pocket"]) != TYPE_ARRAY:
		data["pocket"] = []
	if typeof(data["reviews"]) != TYPE_DICTIONARY:
		data["reviews"] = {}
	if typeof(data["achievements"]) != TYPE_ARRAY:
		data["achievements"] = []
	if typeof(data["fleet_owned"]) != TYPE_ARRAY:
		data["fleet_owned"] = []
	if typeof(data["modes"]) != TYPE_ARRAY:
		data["modes"] = []
	if typeof(data["open_routes"]) != TYPE_ARRAY:
		data["open_routes"] = []
	return data


static func store(data: Dictionary) -> void:
	var payload := {}
	for key in defaults().keys():
		payload[key] = data.get(key, defaults()[key])
	var file := FileAccess.open(PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(payload))
	file.close()
