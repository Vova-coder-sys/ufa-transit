class_name M5
extends RefCounted

# Трасса М-5 в масштабе: мир короче 120 км, на щитах и в рейсе километры настоящие.

const ROUTE_KM := 120.0
const PAX := 40
const FARE := 500
const FUEL := 1200
const CONDUCTOR_PAY := 1500

static var curve: Curve3D
static var traffic: Array = []
static var coach: Node3D
static var conductor: Node3D
static var tv: StandardMaterial3D
static var clock := 0.0


static func dress(parent: Node3D, network: Dictionary) -> void:
	traffic = []
	if not network["paths"].has("highway"):
		return
	curve = network["paths"]["highway"].curve
	var length := curve.get_baked_length()
	var wheat := MeshLib.mat(Color(0.78, 0.66, 0.28), 0.95)
	var forest := MeshLib.mat(Color(0.16, 0.34, 0.18), 0.95)
	var trunk := MeshLib.mat(Color(0.28, 0.2, 0.12), 0.95)
	var wall := MeshLib.mat(Color(0.72, 0.62, 0.48), 0.9)
	var roof := MeshLib.mat(Color(0.45, 0.22, 0.16), 0.85)
	var step := 95.0
	var i := 0
	var d := 40.0
	while d < length - 30.0:
		var frame := _frame(d)
		var side := 1.0 if i % 2 == 0 else -1.0
		if i % 3 != 0:
			var field := MeshLib.box(Vector3(36.0, 0.7, 22.0), frame["p"] + frame["r"] * side * 28.0 + Vector3(0, 0.35, 0), wheat, "Wheat")
			field.rotation.y = atan2(frame["f"].x, frame["f"].z)
			parent.add_child(field)
		else:
			for t in 5:
				var at: Vector3 = frame["p"] + frame["r"] * side * (16.0 + float(t % 3) * 4.0) + frame["f"] * (float(t) - 2.0) * 3.5
				var stem := MeshLib.cylinder(0.18, 3.2 + float(t % 2), trunk, 6)
				stem.position = at + Vector3(0, 1.6, 0)
				parent.add_child(stem)
				var crown := MeshLib.cylinder(1.5, 2.4, forest, 7)
				crown.position = at + Vector3(0, 3.8, 0)
				parent.add_child(crown)
		if i % 7 == 2:
			_village(parent, frame, side, wall, roof)
		d += step
		i += 1
	_station(parent, 0.28, "АЗС", Color(0.85, 0.15, 0.12), true)
	_station(parent, 0.74, "АЗС", Color(0.12, 0.35, 0.7), true)
	_station(parent, 0.5, "КАФЕ", Color(0.9, 0.55, 0.15), false)
	_dps(parent, 0.33)
	_repair(parent, 0.2)
	_repair(parent, 0.68)
	for km in [0, 30, 60, 90, 120]:
		var at: float = length * float(km) / ROUTE_KM
		if at > length - 8.0:
			at = length - 8.0
		var frame := _frame(at)
		var sign := MeshLib.label("М-5  %d км" % km, 42, Color(0.95, 0.95, 0.9))
		sign.position = frame["p"] + frame["r"] * 8.0 + Vector3(0, 3.2, 0)
		sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		parent.add_child(sign)
	_spawn_traffic(parent)


static func board(bus: Node3D, night: bool, rng: RandomNumberGenerator) -> void:
	if coach != null and is_instance_valid(coach):
		coach.queue_free()
	coach = Node3D.new()
	coach.name = "CoachLife"
	bus.add_child(coach)
	var coats := [Color(0.25, 0.32, 0.45), Color(0.45, 0.28, 0.22), Color(0.2, 0.35, 0.28), Color(0.4, 0.32, 0.5)]
	for n in 36:
		var person := City.make_person(coats[n % coats.size()])
		var col := -1.0 if n % 2 == 0 else 1.0
		var row := float(n / 2)
		person.position = Vector3(col * 0.72, 1.05, -3.2 + row * 0.42)
		person.rotation.y = PI if col > 0.0 else 0.0
		person.scale = Vector3(0.72, 0.72, 0.72)
		if n % 5 == 0:
			person.rotation.x = 0.5
			person.set_meta("sleep", true)
		elif n % 5 == 1:
			var cup := MeshLib.cylinder(0.04, 0.1, MeshLib.mat(Color(0.9, 0.9, 0.92), 0.4), 6)
			cup.position = Vector3(0.15, 1.15, 0.2)
			person.add_child(cup)
		if n % 4 == 2:
			var bag := MeshLib.box(Vector3(0.28, 0.22, 0.16), Vector3(0.2, 0.35, 0.15), MeshLib.mat(Color(0.35, 0.22, 0.12), 0.9), "Bag")
			person.add_child(bag)
		if night:
			person.rotation.x = 0.45
		coach.add_child(person)
	conductor = City.make_person(Color(0.15, 0.22, 0.48))
	conductor.position = Vector3(0.0, 1.05, 1.2)
	conductor.scale = Vector3(0.78, 0.78, 0.78)
	coach.add_child(conductor)
	var screen := MeshLib.box(Vector3(0.7, 0.4, 0.04), Vector3(0, 2.35, -4.6), MeshLib.emissive(Color(0.2, 0.45, 0.9), 1.4), "FilmTV")
	coach.add_child(screen)
	tv = screen.material_override as StandardMaterial3D


static func tick(delta: float, night: bool) -> void:
	clock += delta
	if curve == null:
		return
	var length := curve.get_baked_length()
	var shown := 0
	for item in traffic:
		var node: Node3D = item["node"]
		if night and int(item["lane"]) % 2 == 0:
			node.visible = false
			continue
		node.visible = true
		shown += 1
		var off: float = float(item["off"]) + float(item["spd"]) * delta * float(item["dir"])
		off = fposmod(off, length)
		item["off"] = off
		var frame := _frame(off)
		node.global_position = frame["p"] + frame["r"] * float(item["lat"]) + Vector3(0, 0.6, 0)
		node.rotation.y = atan2(-frame["f"].x * float(item["dir"]), -frame["f"].z * float(item["dir"]))
	if tv != null and is_instance_valid(tv):
		tv.emission = Color.from_hsv(fmod(clock * 0.07, 1.0), 0.55, 0.9)
	if conductor != null and is_instance_valid(conductor):
		conductor.position.z = 1.2 + sin(clock * 0.35) * 3.4


static func km_of(progress: float, m0: float, m1: float) -> float:
	var span := maxf(m1 - m0, 1.0)
	return clampf((progress - m0) / span, 0.0, 1.0) * ROUTE_KM


static func profit() -> int:
	return PAX * FARE - FUEL - CONDUCTOR_PAY


static func _frame(d: float) -> Dictionary:
	var length := curve.get_baked_length()
	var p: Vector3 = curve.sample_baked(clampf(d, 0.0, length))
	var ahead: Vector3 = curve.sample_baked(minf(length, d + 2.0))
	var f := Vector3(ahead.x - p.x, 0, ahead.z - p.z)
	if f.length() < 0.05:
		f = Vector3(0, 0, 1)
	f = f.normalized()
	var r: Vector3 = -f.cross(Vector3.UP).normalized()
	return {"p": p, "f": f, "r": r}


static func _village(parent: Node3D, frame: Dictionary, side: float, wall: Material, roof: Material) -> void:
	for h in 4:
		var at: Vector3 = frame["p"] + frame["r"] * side * (18.0 + float(h % 2) * 8.0) + frame["f"] * (float(h) - 1.5) * 7.0
		parent.add_child(MeshLib.box(Vector3(6.0, 3.2, 5.0), at + Vector3(0, 1.6, 0), wall, "House"))
		parent.add_child(MeshLib.box(Vector3(6.6, 0.5, 5.6), at + Vector3(0, 3.4, 0), roof, "Roof"))


static func _station(parent: Node3D, along: float, title: String, color: Color, fuel: bool) -> void:
	var frame := _frame(curve.get_baked_length() * along)
	var at: Vector3 = frame["p"] + frame["r"] * 14.0
	var body := MeshLib.mat(color, 0.75)
	parent.add_child(MeshLib.box(Vector3(8.0, 3.2, 6.0), at + Vector3(0, 1.6, 0), body, title))
	if fuel:
		var canopy_at: Vector3 = at + frame["f"] * 8.0
		parent.add_child(MeshLib.box(Vector3(10.0, 0.2, 5.0), canopy_at + Vector3(0, 3.3, 0), MeshLib.mat(Color(0.85, 0.85, 0.88), 0.5), "Canopy"))
		var pole := MeshLib.cylinder(0.15, 3.2, MeshLib.mat(Color(0.3, 0.3, 0.32), 0.5), 6)
		pole.position = canopy_at + Vector3(0, 1.6, 0)
		parent.add_child(pole)
	else:
		parent.add_child(MeshLib.box(Vector3(2.2, 2.4, 2.2), at + frame["f"] * 6.0 + Vector3(0, 1.2, 0), MeshLib.mat(Color(0.75, 0.75, 0.78), 0.8), "WC"))
	var sign := MeshLib.label(title, 48)
	sign.position = at + Vector3(0, 4.2, 0)
	sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	parent.add_child(sign)


static func _dps(parent: Node3D, along: float) -> void:
	var frame := _frame(curve.get_baked_length() * along)
	var at: Vector3 = frame["p"] + frame["r"] * -12.0
	parent.add_child(MeshLib.box(Vector3(3.0, 2.6, 3.0), at + Vector3(0, 1.3, 0), MeshLib.mat(Color(0.12, 0.22, 0.48), 0.7), "DPS"))
	var bar := MeshLib.box(Vector3(0.2, 0.8, 4.0), at + frame["f"] * 3.0 + Vector3(0, 0.8, 0), MeshLib.mat(Color(0.9, 0.75, 0.1), 0.6), "Barrier")
	parent.add_child(bar)
	var sign := MeshLib.label("ДПС", 44, Color(0.7, 0.85, 1.0))
	sign.position = at + Vector3(0, 3.4, 0)
	sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	parent.add_child(sign)


static func _repair(parent: Node3D, along: float) -> void:
	var frame := _frame(curve.get_baked_length() * along)
	var cone := MeshLib.mat(Color(0.9, 0.35, 0.08), 0.7)
	for i in 4:
		var c := MeshLib.cylinder(0.22, 0.7, cone, 6)
		c.position = frame["p"] + frame["f"] * (float(i) * 3.0) + frame["r"] * 1.2 + Vector3(0, 0.35, 0)
		parent.add_child(c)
	var sign := MeshLib.label("РЕМОНТ", 36, Color(1.0, 0.55, 0.2))
	sign.position = frame["p"] + frame["r"] * 6.0 + Vector3(0, 2.4, 0)
	sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	parent.add_child(sign)


static func _spawn_traffic(parent: Node3D) -> void:
	var length := curve.get_baked_length()
	var paints := [Color(0.7, 0.15, 0.12), Color(0.15, 0.25, 0.45), Color(0.85, 0.85, 0.88), Color(0.2, 0.2, 0.22)]
	for i in 8:
		var truck := i % 2 == 0
		var root := Node3D.new()
		root.name = "M5Car"
		var paint := MeshLib.mat(paints[i % paints.size()], 0.6)
		if truck:
			root.add_child(MeshLib.box(Vector3(2.3, 1.6, 3.2), Vector3(0, 1.3, -4.2), paint, "Cab"))
			root.add_child(MeshLib.box(Vector3(2.45, 2.6, 7.5), Vector3(0, 1.8, 1.2), MeshLib.mat(Color(0.55, 0.56, 0.58), 0.75), "Box"))
		else:
			root.add_child(MeshLib.box(Vector3(1.7, 1.1, 4.2), Vector3(0, 0.7, 0), paint, "Car"))
		parent.add_child(root)
		traffic.append({
			"node": root,
			"off": length * float(i) / 8.0,
			"spd": 9.0 if truck else 14.0,
			"dir": -1.0 if i % 2 == 0 else 1.0,
			"lat": -2.4 if i % 2 == 0 else 2.4,
			"lane": i,
		})
