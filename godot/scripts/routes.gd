class_name Routes
extends RefCounted

# Сжатая сеть Уфы: юг (проспект Октября) и отдельная Черниковка.


static func path_points() -> Dictionary:
	# Каждая улица — своя дуга. Оси разведены дальше суммы ширин,
	# иначе ленты асфальта ложатся одна на другую.
	return {
		"prospekt": [
			Vector3(-540, 0, -20), Vector3(-320, 0, 130), Vector3(-70, 0, -30),
			Vector3(170, 0, 150), Vector3(380, 0, -50), Vector3(540, 0, -140), Vector3(700, 0, 10),
		],
		"east": [
			Vector3(-460, 0, 310), Vector3(-200, 0, 230), Vector3(170, 0, 232),
			Vector3(430, 0, 250), Vector3(620, 0, 360),
		],
		"north": [
			Vector3(170, 0, 318), Vector3(340, 0, 510), Vector3(520, 0, 640), Vector3(680, 0, 500),
		],
		"airport": [
			Vector3(755, 0, -40), Vector3(900, 0, -210), Vector3(760, 0, -360),
			Vector3(940, 0, -510), Vector3(780, 0, -640),
		],
		"highway": [
			Vector3(820, 0, 90), Vector3(1600, 0, 220), Vector3(2500, 0, 40),
			Vector3(3400, 0, 260), Vector3(4300, 0, 20), Vector3(5200, 0, 200),
			Vector3(6000, 0, 40),
		],
		"plant": [
			Vector3(200, 0, 460), Vector3(370, 0, 640), Vector3(550, 0, 760), Vector3(720, 0, 620),
		],
	}


static func stop_names() -> Dictionary:
	return {
		"prospekt": [
			"Зелёная Роща", "Улица Менделеева", "Госцирк", "Советская площадь",
			"Гостиный двор", "Национальный музей", "Ж/д вокзал",
		],
		"east": [
			"Санаторий «Зелёная Роща»", "ЦУМ", "Театр оперы и балета", "Проспект Салавата", "Улица Дзержинского",
		],
		"north": ["Депо Черниковки", "Интернациональная", "Улица Трамвайная", "Стадион Гастелло"],
		"airport": ["Улица Дзержинского", "Южный автовокзал", "Мост через Белую", "Посёлок Аэропорт", "Аэропорт"],
		"highway": ["Автовокзал", "Иглино", "Кафе «М-5»", "Зирган", "Стерлитамак", "Салават", "Октябрьский"],
		"plant": ["Промзона", "Склад", "Цех", "Карьер"],
	}


static func path_style() -> Dictionary:
	return {
		# reserve — край трамвайного полотна. Машины за него не заезжают.
		"prospekt": {"half": 14.2, "track": "median", "reserve": 4.3, "catenary": "both", "density": 1.0},
		"east": {"half": 6.0, "track": "", "reserve": 0.0, "catenary": "", "density": 0.7},
		"north": {"half": 4.0, "track": "only", "reserve": 0.0, "catenary": "tram", "density": 0.8},
		"airport": {"half": 6.0, "track": "", "reserve": 0.0, "catenary": "", "density": 0.25},
		"highway": {"half": 4.6, "track": "", "reserve": 0.0, "catenary": "", "density": 0.12},
		"plant": {"half": 6.0, "track": "", "reserve": 0.0, "catenary": "", "density": 0.4},
	}


static func lane_offset(vehicle_type: String, path_name: String) -> float:
	# На проспекте трамвай в своей полосе по центру, машины — на боковых проезжих частях.
	if vehicle_type == "tram":
		return 1.75
	if path_name == "prospekt":
		if vehicle_type == "trolley":
			return 7.6
		return 11.0
	if vehicle_type == "trolley":
		return 2.9
	return 2.9


const CITY := ["vector", "nefaz", "liaz", "liaz677"]
const KTM := ["ktm608", "ktm619", "ktm623", "ktm5"]
const TATRA := ["tatraT3", "tatraT3M", "mttch"]
const OLD_TROLLEY := ["gorozhanin", "btz", "ziu", "ziu9"]


static func route_defs() -> Array:
	return [
		{"id": "bus-30", "number": "30", "type": "bus", "path": "prospekt", "i0": 0, "i1": 6,
			"models": CITY, "traffic": 5, "evening_off": false, "operator": "Башавтотранс", "title": "Зелёная Роща — Ж/д вокзал"},
		{"id": "bus-57", "number": "57", "type": "bus", "path": "east", "i0": 0, "i1": 4,
			"models": CITY, "traffic": 4, "evening_off": false, "operator": "Башавтотранс", "title": "Санаторий — Дзержинского", "district": "Спальный"},
		{"id": "bus-15", "number": "15", "type": "bus", "path": "east", "i0": 0, "i1": 4,
			"models": ["gazelle", "ford", "paz3205"], "traffic": 3, "evening_off": false,
			"operator": "Частный перевозчик", "title": "Спальный — Дзержинского", "district": "Спальный"},
		{"id": "bus-69", "number": "69", "type": "bus", "path": "east", "i0": 1, "i1": 4,
			"models": ["vector", "nefaz"], "traffic": 3, "evening_off": false, "operator": "Башавтотранс", "title": "ЦУМ — Дзержинского"},
		{"id": "bus-74", "number": "74", "type": "bus", "path": "prospekt", "i0": 2, "i1": 6,
			"models": CITY, "traffic": 4, "evening_off": false, "operator": "Башавтотранс", "title": "Госцирк — Ж/д вокзал"},
		{"id": "bus-101", "number": "101", "type": "bus", "path": "airport", "i0": 0, "i1": 4,
			"models": ["yutong", "gazelle", "ford", "paz3206"], "traffic": 3, "evening_off": false,
			"operator": "Башавтотранс", "title": "Дзержинского — Аэропорт", "zone": "suburb"},
		{"id": "bus-25", "number": "25", "type": "bus", "path": "prospekt", "i0": 2, "i1": 5,
			"models": ["gazelle", "ford", "paz3205"], "traffic": 3, "evening_off": true,
			"operator": "Частный перевозчик", "title": "Госцирк — Национальный музей"},
		{"id": "tb-1", "number": "1", "type": "trolley", "path": "prospekt", "i0": 2, "i1": 6,
			"models": OLD_TROLLEY, "traffic": 3, "evening_off": false, "operator": "УГЭТ", "title": "Госцирк — Ж/д вокзал"},
		{"id": "tb-13", "number": "13", "type": "trolley", "path": "prospekt", "i0": 0, "i1": 6,
			"models": ["uttz6243", "gorozhanin"], "traffic": 4, "evening_off": false, "operator": "УГЭТ", "title": "Зелёная Роща — Ж/д вокзал"},
		{"id": "tb-22", "number": "22", "type": "trolley", "path": "prospekt", "i0": 1, "i1": 4,
			"models": OLD_TROLLEY, "traffic": 3, "evening_off": false, "operator": "УГЭТ", "title": "Менделеева — Гостиный двор"},
		{"id": "tram-18", "number": "18", "type": "tram", "path": "prospekt", "i0": 0, "i1": 2,
			"models": ["pesa"], "traffic": 2, "evening_off": false, "operator": "УГЭТ", "title": "Зелёная Роща — Госцирк"},
		{"id": "tram-5", "number": "5", "type": "tram", "path": "prospekt", "i0": 0, "i1": 6,
			"models": ["pesa"], "traffic": 3, "evening_off": false, "operator": "УГЭТ", "title": "Зелёная Роща — Ж/д вокзал"},
		{"id": "tram-1", "number": "1", "type": "tram", "path": "prospekt", "i0": 4, "i1": 6,
			"models": KTM, "traffic": 3, "evening_off": false, "operator": "УГЭТ", "title": "Гостиный двор — Ж/д вокзал"},
		{"id": "tram-10", "number": "10", "type": "tram", "path": "prospekt", "i0": 3, "i1": 6,
			"models": KTM, "traffic": 2, "evening_off": false, "operator": "УГЭТ", "title": "Советская площадь — Ж/д вокзал"},
		{"id": "tram-16", "number": "16", "type": "tram", "path": "prospekt", "i0": 1, "i1": 3,
			"models": ["ktm608", "ktm619"], "traffic": 2, "evening_off": false, "operator": "УГЭТ", "title": "Менделеева — Советская площадь"},
		{"id": "tram-6", "number": "6", "type": "tram", "path": "north", "i0": 1, "i1": 3,
			"models": TATRA, "traffic": 3, "evening_off": false, "operator": "УГЭТ", "title": "Интернациональная — Гастелло"},
		{"id": "tram-8", "number": "8", "type": "tram", "path": "north", "i0": 0, "i1": 3,
			"models": TATRA, "traffic": 3, "evening_off": false, "operator": "УГЭТ", "title": "Депо Черниковки — Гастелло"},
		{"id": "ic-501", "number": "501", "type": "bus", "path": "highway", "i0": 0, "i1": 4,
			"models": ["ikarus"], "traffic": 2, "evening_off": false, "intercity": true, "zone": "intercity", "fare": 500,
			"operator": "Башавтотранс", "title": "Уфа — Стерлитамак", "district": "М-5"},
		{"id": "ic-502", "number": "502", "type": "bus", "path": "highway", "i0": 0, "i1": 5,
			"models": ["ikarus", "yutong"], "traffic": 2, "evening_off": false, "intercity": true, "zone": "intercity", "fare": 500,
			"operator": "Башавтотранс", "title": "Уфа — Салават", "district": "Вокзал"},
		{"id": "cargo-4", "number": "4", "type": "bus", "path": "plant", "i0": 0, "i1": 3,
			"models": ["paz3206", "paz3205"], "traffic": 2, "evening_off": false,
			"operator": "Промтранс", "title": "Промзона — Карьер", "district": "Промзона", "zone": "city"},
		{"id": "ic-503", "number": "503", "type": "bus", "path": "highway", "i0": 0, "i1": 6,
			"models": ["ikarus", "yutong"], "traffic": 1, "evening_off": false, "intercity": true, "zone": "intercity", "fare": 500,
			"operator": "Башавтотранс", "title": "Уфа — Октябрьский", "district": "Вокзал", "build": 480000},
	]


static func build(parent: Node3D) -> Dictionary:
	var points := path_points()
	var names := stop_names()
	var paths := {}
	var anchors := {}
	for key in points.keys():
		var list: Array = points[key]
		var curve := Curve3D.new()
		curve.bake_interval = 0.6
		for i in list.size():
			var p: Vector3 = list[i]
			var prev: Vector3 = list[max(i - 1, 0)]
			var next: Vector3 = list[min(i + 1, list.size() - 1)]
			var handle: Vector3 = (next - prev) * 0.15
			# Вертикальную касательную не раздуваем: проезжая часть остаётся пологой.
			handle.y = 0.0
			curve.add_point(p, -handle, handle)
		var path := Path3D.new()
		path.name = "Path_" + key
		path.curve = curve
		parent.add_child(path)
		paths[key] = path
		var stops := []
		for i in list.size():
			stops.append({
				"name": String(names[key][i]),
				"pos": list[i],
				"offset": curve.get_closest_offset(list[i]),
				"path": key,
			})
		anchors[key] = stops

	var routes := []
	for def in route_defs():
		var route: Dictionary = def.duplicate(true)
		var all_stops: Array = anchors[route["path"]]
		var picked := []
		for i in range(int(route["i0"]), int(route["i1"]) + 1):
			picked.append(all_stops[i])
		route["stops"] = picked
		route["m0"] = float(picked[0]["offset"])
		route["m1"] = float(picked[picked.size() - 1]["offset"])
		route["path_node"] = paths[route["path"]]
		routes.append(route)

	return {"paths": paths, "routes": routes, "anchors": anchors}


static func find_route(routes: Array, id: String) -> Dictionary:
	for route in routes:
		if route["id"] == id:
			return route
	return routes[0]
