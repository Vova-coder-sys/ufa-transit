class_name City
extends RefCounted

# Сборка города: дороги, рельсы, контактная сеть, кварталы, остановки.

const SIDEWALK_H := 0.16
const Road = preload("res://scripts/m5.gd")


static func build(parent: Node3D, network: Dictionary) -> Dictionary:
	var out := {
		"stops": [],
		"night_materials": [],
		"lamp_materials": [],
		"lamps": [],
		"road_materials": [],
		"crossings": [],
	}
	_ground(parent, out)
	var styles := Routes.path_style()
	for key in network["paths"].keys():
		var path: Path3D = network["paths"][key]
		var style: Dictionary = styles[key]
		_road(parent, path.curve, style, out, key)
	_river_and_bridge(parent, network, out)
	_junctions(parent, network)
	_districts(parent, network, out)
	_stops(parent, network, out)
	_landmarks(parent, network, out)
	_services(parent, network, out)
	_terrain(parent, network, out)
	Road.dress(parent, network)
	return out


# Скупщик билетов и автосалон: пассажиру есть куда сдать находки и на что
# потратить выручку.
static func _services(parent: Node3D, network: Dictionary, out: Dictionary) -> void:
	out["kiosks"] = []
	out["market"] = {}
	var stops: Array = out["stops"]
	var body := MeshLib.mat(Color(0.86, 0.5, 0.14), 0.6)
	var dark := MeshLib.mat(Color(0.18, 0.2, 0.24), 0.6, 0.3)
	var glass := MeshLib.glass(Color(0.18, 0.26, 0.3), 0.36)
	for i in stops.size():
		if i % 3 != 1:
			continue
		var stop: Dictionary = stops[i]
		var right: Vector3 = stop["right"]
		var forward: Vector3 = stop["forward"]
		var half: float = float(Routes.path_style()[String(stop["path"])]["half"])
		var base: Vector3 = Vector3(stop["pos"]) + right * (half + 5.4) + forward * 2.0
		for _step in 5:
			var overlap := _carriage_intrusion(base, forward, right, 1.5, 1.3, network)
			if overlap <= 0.1:
				break
			base += right * minf(overlap + 1.0, 3.0)
		var group := Node3D.new()
		group.name = "Kiosk"
		group.position = Vector3(base.x, base.y + SIDEWALK_H, base.z)
		group.add_child(MeshLib.box(Vector3(2.4, 2.5, 2.0), Vector3(0, 1.25, 0), body, "Booth"))
		group.add_child(MeshLib.box(Vector3(2.8, 0.14, 2.4), Vector3(0, 2.56, 0), dark, "Roof"))
		group.add_child(MeshLib.box(Vector3(1.6, 1.0, 0.06), Vector3(0, 1.5, -1.02), glass, "Window"))
		group.add_child(MeshLib.box(Vector3(2.0, 0.1, 0.5), Vector3(0, 1.0, -1.2), dark, "Shelf"))
		var sign := MeshLib.label("СКУПКА %d ₽" % Rules.FOUND_PRICE, 40, Color(0.98, 0.94, 0.8))
		sign.position = Vector3(0, 2.3, -1.06)
		sign.pixel_size = 0.0032
		group.add_child(sign)
		parent.add_child(group)
		if right.length() > 0.2:
			group.look_at(group.global_position - right, Vector3.UP)
		out["kiosks"].append({"pos": Vector3(base.x, 0.0, base.z), "stop": i})

	if network["anchors"].has("highway") and not network["anchors"]["highway"].is_empty():
		var stop: Dictionary = network["anchors"]["highway"][0]
		var right: Vector3 = stop["right"] if stop.has("right") else Vector3.RIGHT
		var forward: Vector3 = stop["forward"] if stop.has("forward") else Vector3(0, 0, 1)
		# Остановки ещё без right: считаем касательную по соседней точке пути.
		var curve: Curve3D = network["paths"]["highway"].curve
		var d: float = float(stop["offset"])
		var p: Vector3 = curve.sample_baked(d)
		var ahead: Vector3 = curve.sample_baked(minf(curve.get_baked_length(), d + 2.0))
		forward = Vector3(ahead.x - p.x, 0, ahead.z - p.z)
		if forward.length() < 0.05:
			forward = Vector3(0, 0, 1)
		forward = forward.normalized()
		right = -forward.cross(Vector3.UP).normalized()
		var half: float = float(Routes.path_style()["highway"]["half"])
		var base: Vector3 = p + right * (half + 5.6) + forward * 3.0
		var office := Node3D.new()
		office.name = "TicketOffice"
		office.position = Vector3(base.x, base.y + SIDEWALK_H, base.z)
		office.add_child(MeshLib.box(Vector3(2.4, 2.5, 2.0), Vector3(0, 1.25, 0), body, "Booth"))
		office.add_child(MeshLib.box(Vector3(2.8, 0.14, 2.4), Vector3(0, 2.56, 0), dark, "Roof"))
		office.add_child(MeshLib.box(Vector3(1.6, 1.0, 0.06), Vector3(0, 1.5, -1.02), glass, "Window"))
		var sign := MeshLib.label("КАССА\nБИЛЕТЫ", 42, Color(0.98, 0.94, 0.8))
		sign.position = Vector3(0, 2.15, -1.06)
		sign.pixel_size = 0.008
		sign.outline_size = 4
		sign.double_sided = true
		office.add_child(sign)
		var side_sign := MeshLib.label("КАССА", 48, Color(0.98, 0.94, 0.8))
		side_sign.position = Vector3(1.26, 1.7, 0)
		side_sign.rotation_degrees = Vector3(0, 90, 0)
		side_sign.pixel_size = 0.01
		side_sign.outline_size = 4
		side_sign.double_sided = true
		office.add_child(side_sign)
		parent.add_child(office)
		office.look_at(office.global_position - right, Vector3.UP)
		out["office"] = {"pos": Vector3(base.x, 0.0, base.z)}

	# Автосалон у Госцирка, сбоку от проезжей части: отсюда пассажир начинает путь.
	if stops.size() > 0:
		var stop: Dictionary = stops[0]
		for item in stops:
			var candidate: Dictionary = item
			if String(candidate["path"]) == "prospekt" and String(candidate["name"]) == "Госцирк":
				stop = candidate
				break
		var right: Vector3 = stop["right"]
		var forward: Vector3 = stop["forward"]
		var half: float = float(Routes.path_style()[String(stop["path"])]["half"])
		var base: Vector3 = Vector3(stop["pos"]) + right * (half + 22.0) + forward * 6.0
		var group := Node3D.new()
		group.name = "CarMarket"
		group.position = Vector3(base.x, base.y + 0.02, base.z)
		group.add_child(MeshLib.box(Vector3(26.0, 0.1, 18.0), Vector3(0, 0.05, 0),
			MeshLib.mat(Color(0.26, 0.27, 0.29), 0.85), "Lot"))
		group.add_child(MeshLib.box(Vector3(9.0, 4.4, 7.0), Vector3(-7.0, 2.2, 4.0),
			MeshLib.glass(Color(0.3, 0.42, 0.5), 0.42), "Showroom"))
		group.add_child(MeshLib.box(Vector3(9.4, 0.3, 7.4), Vector3(-7.0, 4.5, 4.0), dark, "ShowRoof"))
		var sign := MeshLib.label("АВТОСАЛОН\n%d ₽" % TownCar.PRICE, 48, Color(0.98, 0.86, 0.4))
		sign.position = Vector3(0, 3.6, -9.5)
		sign.pixel_size = 0.012
		sign.outline_size = 4
		group.add_child(sign)
		var sign_back := MeshLib.label("АВТОСАЛОН\n%d ₽" % TownCar.PRICE, 48, Color(0.98, 0.86, 0.4))
		sign_back.position = Vector3(0, 3.6, -9.2)
		sign_back.rotation_degrees = Vector3(0, 180, 0)
		sign_back.pixel_size = 0.012
		sign_back.outline_size = 4
		group.add_child(sign_back)
		for i in 3:
			var demo := TownCar.body_mesh(Color(0.7, 0.16, 0.16) if i == 0
				else (Color(0.2, 0.3, 0.6) if i == 1 else Color(0.85, 0.86, 0.88)))
			demo.position = Vector3(2.0 + float(i) * 5.0, 0.1, -2.0)
			demo.rotation.y = -0.35
			group.add_child(demo)
		parent.add_child(group)
		if right.length() > 0.2:
			group.look_at(group.global_position - right, Vector3.UP)
		out["market"] = {"pos": Vector3(base.x, 0.0, base.z), "spawn": Vector3(base.x, 0.0, base.z)
			+ Vector3(right.x, 0.0, right.z).normalized() * -9.0}


static func _sample(curve: Curve3D, step: float) -> Array:
	var length: float = curve.get_baked_length()
	var samples := []
	var count: int = max(2, int(length / step))
	for i in count + 1:
		var d: float = min(length, float(i) * length / count)
		var p: Vector3 = curve.sample_baked(d)
		var ahead: Vector3 = curve.sample_baked(min(length, d + 0.6))
		var behind: Vector3 = curve.sample_baked(max(0.0, d - 0.6))
		var raw: Vector3 = ahead - behind
		var forward := Vector3(raw.x, 0.0, raw.z)
		if forward.length() < 0.05:
			forward = Vector3(0, 0, 1)
		else:
			forward = forward.normalized()
		var right: Vector3 = forward.cross(Vector3.UP).normalized()
		samples.append({"p": p, "f": forward, "r": -right, "d": d})
	return samples


static func _sample_at(curve: Curve3D, d: float) -> Dictionary:
	var length: float = curve.get_baked_length()
	var at: float = clamp(d, 0.0, length)
	var p: Vector3 = curve.sample_baked(at)
	var ahead: Vector3 = curve.sample_baked(min(length, at + 0.6))
	var behind: Vector3 = curve.sample_baked(max(0.0, at - 0.6))
	var raw: Vector3 = ahead - behind
	var forward := Vector3(raw.x, 0.0, raw.z)
	if forward.length() < 0.05:
		forward = Vector3(0, 0, 1)
	else:
		forward = forward.normalized()
	return {"p": p, "f": forward, "r": -forward.cross(Vector3.UP).normalized(), "d": at}


static func _edges(samples: Array, offset: float, y: float) -> Array:
	var pts := []
	for s in samples:
		var p: Vector3 = s["p"] + s["r"] * offset
		pts.append(Vector3(p.x, s["p"].y + y, p.z))
	return pts


static func _ribbon(parent: Node3D, samples: Array, from_off: float, to_off: float, y: float,
		material: Material, name: String) -> void:
	var left := _edges(samples, from_off, y)
	var right := _edges(samples, to_off, y)
	var mesh := MeshLib.strip(left, right, 0.08)
	parent.add_child(MeshLib.mesh_node(mesh, material, name))


static func _ground(_parent: Node3D, out: Dictionary) -> void:
	out["ground_grass"] = MeshLib.ground_texture(7)
	out["ground_snow"] = MeshLib.texture_from(MeshLib.noise_image(192, 192, Color(0.93, 0.95, 0.99), 0.12, 0.03, 11))


static func _road(parent: Node3D, curve: Curve3D, style: Dictionary, out: Dictionary, key: String) -> void:
	var samples := _sample(curve, 4.5)
	var half: float = float(style["half"])

	var track := String(style.get("track", ""))
	if track == "only":
		_trackway(parent, samples, half, style, out, key)
		return
	if track == "median":
		_avenue(parent, samples, half, style, out, key)
		return

	var asphalt := MeshLib.mat(Color(1, 1, 1), 0.92)
	asphalt.albedo_texture = MeshLib.asphalt_texture(hash(key) % 1000)
	asphalt.uv1_scale = Vector3(4, 1, 1)
	asphalt.normal_enabled = true
	asphalt.normal_texture = MeshLib.noise_normal(3.0, 0.22, hash(key) % 997)
	asphalt.normal_scale = 0.7
	_ribbon(parent, samples, -half, half, 0.02, asphalt, "Road_" + key)
	out["road_materials"].append(asphalt)

	var rural := key == "highway"
	if not rural:
		var walk := MeshLib.mat(Color(1, 1, 1), 0.85)
		walk.albedo_texture = MeshLib.tile_texture(Color(0.63, 0.63, 0.61), hash(key) % 991)
		walk.uv1_scale = Vector3(1.2, 6.0, 1)
		_ribbon(parent, samples, half, half + 3.4, SIDEWALK_H, walk, "WalkR_" + key)
		_ribbon(parent, samples, -half - 3.4, -half, SIDEWALK_H, walk, "WalkL_" + key)
	var verge := MeshLib.mat(Color(0.62, 0.56, 0.38) if rural else Color(0.34, 0.42, 0.24), 0.96)
	var verge_from := 0.35 if rural else 3.4
	_ribbon(parent, samples, half + verge_from, half + 8.5, 0.04, verge, "VergeR_" + key)
	_ribbon(parent, samples, -half - 8.5, -half - verge_from, 0.04, verge, "VergeL_" + key)

	# Бордюр — вертикальная стенка между дорогой и тротуаром. На М-5 его нет.
	if not rural:
		var curb_mat := MeshLib.mat(Color(0.7, 0.69, 0.66), 0.8)
		for side in [-1.0, 1.0]:
			var edge: float = side * half
			var low := _edges(samples, edge, 0.02)
			var high := _edges(samples, edge, SIDEWALK_H)
			parent.add_child(MeshLib.mesh_node(MeshLib.wall(low, high, side > 0.0), curb_mat, "Curb_" + key))

	var paint := MeshLib.mat(Color(0.92, 0.9, 0.82), 0.7)
	paint.albedo_texture = MeshLib.dash_texture()
	paint.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	paint.uv1_scale = Vector3(1, 6, 1)
	_ribbon(parent, samples, half - 0.35, half - 0.2, 0.05, paint, "Line_" + key)
	_ribbon(parent, samples, -half + 0.2, -half + 0.35, 0.05, paint, "Line2_" + key)

	var solid := MeshLib.mat(Color(0.93, 0.91, 0.84), 0.65)
	_ribbon(parent, samples, -0.18, -0.04, 0.045, solid, "Axis1_" + key)
	_ribbon(parent, samples, 0.04, 0.18, 0.045, solid, "Axis2_" + key)
	var dash := MeshLib.mat(Color(0.92, 0.9, 0.82), 0.7)
	dash.albedo_texture = MeshLib.dash_texture()
	dash.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	dash.uv1_scale = Vector3(1, 6, 1)
	for side in [-1.0, 1.0]:
		_ribbon(parent, samples, side * half * 0.5 - 0.07, side * half * 0.5 + 0.07, 0.045, dash, "Lane_" + key)

	_catenary(parent, samples, half, style, key)
	_street_furniture(parent, samples, half, style, out)


# Проспект: две проезжие части для машин и отдельное трамвайное полотно посередине.
static func _avenue(parent: Node3D, samples: Array, half: float, style: Dictionary, out: Dictionary, key: String) -> void:
	var inner := 5.0
	var reserve: float = float(style.get("reserve", 4.3))
	var asphalt := _asphalt(key)
	out["road_materials"].append(asphalt)
	_ribbon(parent, samples, inner, half, 0.02, asphalt, "RoadR_" + key)
	_ribbon(parent, samples, -half, -inner, 0.02, asphalt, "RoadL_" + key)
	var grass := MeshLib.mat(Color(0.3, 0.4, 0.22), 0.96)
	_ribbon(parent, samples, -reserve, reserve, 0.045, grass, "Median_" + key)
	_rails(parent, samples, 1.75)
	var curb_mat := MeshLib.mat(Color(0.7, 0.69, 0.66), 0.8)
	for edge in [inner, -inner, half, -half]:
		var low := _edges(samples, edge, 0.02)
		var high := _edges(samples, edge, SIDEWALK_H if absf(edge) > inner + 1.0 else 0.1)
		parent.add_child(MeshLib.mesh_node(MeshLib.wall(low, high, edge > 0.0), curb_mat, "Curb"))
	_walks(parent, samples, half, key)
	var solid := MeshLib.mat(Color(0.93, 0.91, 0.84), 0.65)
	var dash := MeshLib.mat(Color(0.92, 0.9, 0.82), 0.7)
	dash.albedo_texture = MeshLib.dash_texture()
	dash.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	dash.uv1_scale = Vector3(1, 6, 1)
	for side in [-1.0, 1.0]:
		_ribbon(parent, samples, side * (inner + 0.16), side * (inner + 0.32), 0.05, solid, "InEdge")
		_ribbon(parent, samples, side * (half - 0.32), side * (half - 0.16), 0.05, solid, "OutEdge")
		_ribbon(parent, samples, side * 9.2, side * 9.38, 0.05, dash, "Lane")
	_catenary(parent, samples, half, style, key)
	_street_furniture(parent, samples, half, style, out)


# Черниковка: только трамвай, без автомобильной проезжей части.
static func _trackway(parent: Node3D, samples: Array, half: float, style: Dictionary, out: Dictionary, key: String) -> void:
	var bed := MeshLib.mat(Color(0.34, 0.34, 0.32), 0.94)
	_ribbon(parent, samples, -half, half, 0.03, bed, "TrackBed_" + key)
	_rails(parent, samples, 1.75)
	var curb_mat := MeshLib.mat(Color(0.7, 0.69, 0.66), 0.8)
	for side in [-1.0, 1.0]:
		var low := _edges(samples, side * half, 0.03)
		var high := _edges(samples, side * half, SIDEWALK_H)
		parent.add_child(MeshLib.mesh_node(MeshLib.wall(low, high, side > 0.0), curb_mat, "Curb"))
	_walks(parent, samples, half, key)
	_catenary(parent, samples, half, style, key)
	_street_furniture(parent, samples, half, style, out)


static func _rails(parent: Node3D, samples: Array, gauge: float) -> void:
	var rail_mat := MeshLib.mat(Color(0.55, 0.56, 0.58), 0.28, 0.85)
	var sleeper := MeshLib.mat(Color(0.32, 0.3, 0.28), 0.9)
	for side in [-1.0, 1.0]:
		var center: float = side * gauge
		_ribbon(parent, samples, center - 0.95, center + 0.95, 0.055, sleeper, "Sleepers")
		_ribbon(parent, samples, center - 0.78, center - 0.64, 0.11, rail_mat, "Rail")
		_ribbon(parent, samples, center + 0.64, center + 0.78, 0.11, rail_mat, "Rail")


static func _asphalt(key: String) -> StandardMaterial3D:
	var asphalt := MeshLib.mat(Color(1, 1, 1), 0.92)
	asphalt.albedo_texture = MeshLib.asphalt_texture(hash(key) % 1000)
	asphalt.uv1_scale = Vector3(4, 1, 1)
	asphalt.normal_enabled = true
	asphalt.normal_texture = MeshLib.noise_normal(3.0, 0.22, hash(key) % 997)
	asphalt.normal_scale = 0.7
	return asphalt


static func _walks(parent: Node3D, samples: Array, half: float, key: String) -> void:
	var walk := MeshLib.mat(Color(1, 1, 1), 0.85)
	walk.albedo_texture = MeshLib.tile_texture(Color(0.63, 0.63, 0.61), hash(key) % 991)
	walk.uv1_scale = Vector3(1.2, 6.0, 1)
	_ribbon(parent, samples, half, half + 3.4, SIDEWALK_H, walk, "WalkR_" + key)
	_ribbon(parent, samples, -half - 3.4, -half, SIDEWALK_H, walk, "WalkL_" + key)
	var verge := MeshLib.mat(Color(0.34, 0.42, 0.24), 0.96)
	_ribbon(parent, samples, half + 3.4, half + 8.5, 0.04, verge, "VergeR_" + key)
	_ribbon(parent, samples, -half - 8.5, -half - 3.4, 0.04, verge, "VergeL_" + key)


# Контактная сеть на тех же опорах, что и фонари: поперечина, струны и провода над полосой.
static func _catenary(parent: Node3D, samples: Array, half: float, style: Dictionary, path_name: String) -> void:
	var kind := String(style.get("catenary", ""))
	if kind == "" or samples.size() < 2:
		return
	var lines: Array = []
	if kind == "both" or kind == "trolley":
		var lane: float = Routes.lane_offset("trolley", path_name)
		for side in [-1.0, 1.0]:
			lines.append(side * lane - 0.3)
			lines.append(side * lane + 0.3)
	if kind == "both" or kind == "tram":
		var lane: float = Routes.lane_offset("tram", path_name)
		for side in [-1.0, 1.0]:
			lines.append(side * lane)
	var wire_y := 5.9
	var span_y := 7.55
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for off in lines:
		for i in samples.size() - 1:
			var a: Vector3 = samples[i]["p"] + samples[i]["r"] * float(off) + Vector3(0, wire_y, 0)
			var b: Vector3 = samples[i + 1]["p"] + samples[i + 1]["r"] * float(off) + Vector3(0, wire_y, 0)
			_push_cable(st, a, b, 0.045)
	var density: float = float(style["density"])
	var every: int = max(4, int(6.0 / max(density, 0.2)))
	for i in samples.size():
		if (i + 1) % every != 0:
			continue
		var s: Dictionary = samples[i]
		var left: Vector3 = s["p"] + s["r"] * -(half + 1.2) + Vector3(0, span_y, 0)
		var right: Vector3 = s["p"] + s["r"] * (half + 1.2) + Vector3(0, span_y, 0)
		_push_cable(st, left, right, 0.032)
		for off in lines:
			var top: Vector3 = s["p"] + s["r"] * float(off) + Vector3(0, span_y, 0)
			var bot: Vector3 = s["p"] + s["r"] * float(off) + Vector3(0, wire_y, 0)
			_push_cable(st, top, bot, 0.028)
	var mat := MeshLib.mat(Color(0.16, 0.16, 0.17), 0.32, 0.82)
	parent.add_child(MeshLib.mesh_node(st.commit(), mat, "Catenary"))


static func _push_cable(st: SurfaceTool, a: Vector3, b: Vector3, radius: float) -> void:
	var axis: Vector3 = b - a
	var length: float = axis.length()
	if length < 0.05:
		return
	axis /= length
	var helper := Vector3.UP
	if absf(axis.dot(helper)) > 0.9:
		helper = Vector3.RIGHT
	var side: Vector3 = axis.cross(helper).normalized()
	var up: Vector3 = side.cross(axis).normalized()
	var n_sides := 5
	var ring_a: Array = []
	var ring_b: Array = []
	for i in n_sides:
		var ang: float = TAU * float(i) / float(n_sides)
		var off: Vector3 = (side * cos(ang) + up * sin(ang)) * radius
		ring_a.append(a + off)
		ring_b.append(b + off)
	for i in n_sides:
		var j: int = (i + 1) % n_sides
		var mid_ang: float = TAU * (float(i) + 0.5) / float(n_sides)
		var normal: Vector3 = (side * cos(mid_ang) + up * sin(mid_ang)).normalized()
		st.set_normal(normal)
		st.add_vertex(ring_a[i])
		st.set_normal(normal)
		st.add_vertex(ring_b[i])
		st.set_normal(normal)
		st.add_vertex(ring_a[j])
		st.set_normal(normal)
		st.add_vertex(ring_a[j])
		st.set_normal(normal)
		st.add_vertex(ring_b[i])
		st.set_normal(normal)
		st.add_vertex(ring_b[j])


static func _street_furniture(parent: Node3D, samples: Array, half: float, style: Dictionary, out: Dictionary) -> void:
	var pole_mat := MeshLib.mat(Color(0.32, 0.34, 0.36), 0.55, 0.5)
	var lamp_mat := MeshLib.emissive(Color(1.0, 0.88, 0.62), 0.0)
	out["lamp_materials"].append(lamp_mat)
	var density: float = float(style["density"])
	var every: int = max(4, int(6 / max(density, 0.2)))
	var index := 0
	var trunk_mat := MeshLib.mat(Color(0.26, 0.2, 0.14), 0.95)
	var leaf_mat := MeshLib.mat(Color(0.19, 0.36, 0.16), 0.95)
	for s in samples:
		index += 1
		if index % every == 0:
			for side in [-1.0, 1.0]:
				var mast := MeshLib.cylinder(0.11, 8.4, pole_mat, 8)
				mast.position = s["p"] + s["r"] * (side * (half + 1.2)) + Vector3(0, 4.2, 0)
				parent.add_child(mast)
				var arm := MeshLib.cylinder(0.07, 1.6, pole_mat, 6)
				arm.position = s["p"] + s["r"] * (side * (half + 0.55)) + Vector3(0, 8.3, 0)
				arm.rotation_degrees = Vector3(0, 0, 90)
				arm.look_at_from_position(arm.position, arm.position + s["f"], Vector3.UP)
				arm.rotate_object_local(Vector3(1, 0, 0), PI * 0.5)
				parent.add_child(arm)
				var head := MeshLib.box(Vector3(0.7, 0.16, 0.34), Vector3.ZERO, lamp_mat, "LampHead")
				head.position = s["p"] + s["r"] * (side * (half - 0.1)) + Vector3(0, 8.2, 0)
				parent.add_child(head)
				var light := OmniLight3D.new()
				light.light_color = Color(1.0, 0.86, 0.6)
				light.light_energy = 0.0
				light.omni_range = 26.0
				light.shadow_enabled = false
				light.position = head.position + Vector3(0, -0.4, 0)
				parent.add_child(light)
				out["lamps"].append(light)
		if index % 3 == 0 and density > 0.5:
			for side in [-1.0, 1.0]:
				var base: Vector3 = s["p"] + s["r"] * (side * (half + 6.4))
				parent.add_child(_tree(base, index * 7 + int(side)))


static func _tree(base: Vector3, seed_value: int) -> Node3D:
	# Крона из трёх шапок разного оттенка: дерево перестаёт быть шаром на палке.
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var root := Node3D.new()
	root.name = "Tree"
	root.position = base
	root.rotation.y = rng.randf() * TAU
	var height: float = rng.randf_range(2.6, 3.6)
	var trunk := MeshLib.cylinder(0.17, height, MeshLib.mat(Color(0.24, 0.18, 0.13), 0.95), 6)
	trunk.position = Vector3(0, height * 0.5, 0)
	root.add_child(trunk)
	var tint: float = rng.randf_range(-0.04, 0.05)
	for i in 3:
		var blob := SphereMesh.new()
		blob.radius = rng.randf_range(1.15, 1.7)
		blob.height = blob.radius * 1.9
		blob.radial_segments = 12
		blob.rings = 7
		var leaf := MeshLib.mat(Color(0.17 + tint, 0.34 + tint, 0.14 + tint * 0.5), 0.95)
		var node := MeshLib.mesh_node(blob, leaf, "Crown")
		var angle: float = TAU * float(i) / 3.0 + rng.randf() * 0.7
		var spread: float = rng.randf_range(0.35, 0.85)
		node.position = Vector3(cos(angle) * spread, height + rng.randf_range(0.5, 1.2), sin(angle) * spread)
		node.scale = Vector3(1.0, rng.randf_range(0.85, 1.15), 1.0)
		root.add_child(node)
	return root


static func _river_and_bridge(parent: Node3D, network: Dictionary, out: Dictionary) -> void:
	# Мост через Белую: дорога идёт дамбой, вода ниже, перила и быки по бокам.
	var anchors: Array = network["anchors"]["airport"]
	var mid: Vector3 = anchors[2]["pos"]
	out["river"] = mid
	var plane := PlaneMesh.new()
	plane.size = Vector2(260, 150)
	plane.subdivide_width = 12
	plane.subdivide_depth = 8
	var node := MeshLib.mesh_node(plane, MeshLib.water_material(), "River")
	var curve: Curve3D = network["paths"]["airport"].curve
	var frame := _sample_at(curve, float(anchors[2]["offset"]))
	node.position = Vector3(mid.x, -0.55, mid.z)
	node.rotation.y = atan2(frame["f"].x, frame["f"].z)
	parent.add_child(node)

	var samples := _sample(curve, 6.0)
	var span := []
	for s in samples:
		if Vector2(s["p"].x, s["p"].z).distance_to(Vector2(mid.x, mid.z)) < 100.0:
			span.append(s)
	if span.size() < 2:
		return
	var rail_mat := MeshLib.mat(Color(0.78, 0.8, 0.82), 0.32, 0.7)
	var half: float = float(Routes.path_style()["airport"]["half"])
	_ribbon(parent, span, half + 0.05, half + 0.38, 1.05, rail_mat, "BridgeRail")
	_ribbon(parent, span, -half - 0.38, -half - 0.05, 1.05, rail_mat, "BridgeRail")
	var concrete := MeshLib.mat(Color(0.52, 0.53, 0.54), 0.86)
	var i := 0
	for s in span:
		i += 1
		if i % 4 != 0:
			continue
		for side in [-1.0, 1.0]:
			parent.add_child(MeshLib.box(Vector3(1.5, 4.4, 1.5),
				s["p"] + s["r"] * side * (half + 3.4) + Vector3(0, -2.3, 0), concrete, "Pier"))


# Сколько метров от оси улицы нельзя занимать: проезжая часть, тротуар и полоска газона.
static func _road_keepout(path_name: String) -> float:
	return float(Routes.path_style()[path_name]["half"]) + 7.5


static func _box_corners(center: Vector3, forward: Vector3, right: Vector3, half_w: float, half_d: float) -> Array:
	return [
		center + right * half_w + forward * half_d,
		center + right * half_w - forward * half_d,
		center - right * half_w + forward * half_d,
		center - right * half_w - forward * half_d,
	]


# Залезла ли точка на сам асфальт, без широкой полосы под дома.
static func _carriage_intrusion(center: Vector3, forward: Vector3, right: Vector3,
		half_w: float, half_d: float, network: Dictionary) -> float:
	var worst := 0.0
	for corner in _box_corners(center, forward, right, half_w, half_d):
		for key in network["paths"].keys():
			var curve: Curve3D = network["paths"][key].curve
			var at: float = curve.get_closest_offset(corner)
			var on_road: Vector3 = curve.sample_baked(at)
			var dist := Vector2(corner.x - on_road.x, corner.z - on_road.z).length()
			var limit: float = float(Routes.path_style()[String(key)]["half"]) + 1.2
			worst = maxf(worst, limit - dist)
		for extra in network.get("extras", []):
			var origin: Vector3 = extra["p"]
			var axis: Vector3 = extra["f"]
			var rel := Vector2(corner.x - origin.x, corner.z - origin.z)
			var along: float = rel.dot(Vector2(axis.x, axis.z))
			if along < -2.0 or along > float(extra["len"]) + 2.0:
				continue
			var side: float = absf(rel.dot(Vector2(-axis.z, axis.x)))
			worst = maxf(worst, float(extra["keep"]) - side)
	return worst


# Насколько угол дома залез на запретную полосу любой улицы. 0 — стоит свободно.
static func _road_intrusion(point: Vector3, network: Dictionary) -> float:
	var worst := 0.0
	for key in network["paths"].keys():
		var curve: Curve3D = network["paths"][key].curve
		var at: float = curve.get_closest_offset(point)
		var on_road: Vector3 = curve.sample_baked(at)
		var dist := Vector2(point.x - on_road.x, point.z - on_road.z).length()
		worst = maxf(worst, _road_keepout(String(key)) - dist)
	for extra in network.get("extras", []):
		var origin: Vector3 = extra["p"]
		var axis: Vector3 = extra["f"]
		var rel := Vector2(point.x - origin.x, point.z - origin.z)
		var along: float = rel.dot(Vector2(axis.x, axis.z))
		if along < -2.0 or along > float(extra["len"]) + 2.0:
			continue
		var side: float = absf(rel.dot(Vector2(-axis.z, axis.x)))
		worst = maxf(worst, float(extra["keep"]) - side)
	return worst


# Сдвигает дом в сторону от своей улицы, пока все углы не выйдут с проезжей части.
# null — места нет, дом лучше не ставить.
static func _settle_off_road(center: Vector3, push: Vector3, forward: Vector3, right: Vector3,
		half_w: float, half_d: float, network: Dictionary) -> Variant:
	var pos := center
	for _step in 10:
		var overlap := 0.0
		for corner in _box_corners(pos, forward, right, half_w, half_d):
			overlap = maxf(overlap, _road_intrusion(corner, network))
		if overlap <= 0.2:
			return pos
		pos += push.normalized() * (overlap + 2.0)
	return null


static func _districts(parent: Node3D, network: Dictionary, out: Dictionary) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 20260922
	var palettes := [
		[Color(0.78, 0.74, 0.66), Color(0.1, 0.14, 0.18)],
		[Color(0.84, 0.83, 0.8), Color(0.12, 0.16, 0.2)],
		[Color(0.66, 0.58, 0.5), Color(0.1, 0.13, 0.16)],
		[Color(0.72, 0.76, 0.79), Color(0.09, 0.13, 0.17)],
	]
	var textures := []
	for i in palettes.size():
		textures.append(MeshLib.facade_pair(palettes[i][0], palettes[i][1], 100 + i * 37))

	var plans := [
		{"path": "prospekt", "side": 1.0, "offset": 42.0, "count": 26, "min_h": 18.0, "max_h": 42.0, "kind": "tower"},
		{"path": "prospekt", "side": -1.0, "offset": 42.0, "count": 24, "min_h": 16.0, "max_h": 36.0, "kind": "tower"},
		{"path": "east", "side": 1.0, "offset": 34.0, "count": 16, "min_h": 9.0, "max_h": 16.0, "kind": "panel"},
		{"path": "east", "side": -1.0, "offset": 34.0, "count": 14, "min_h": 8.0, "max_h": 14.0, "kind": "panel"},
		{"path": "north", "side": 1.0, "offset": 36.0, "count": 8, "min_h": 6.0, "max_h": 11.0, "kind": "plant"},
		{"path": "plant", "side": 1.0, "offset": 28.0, "count": 6, "min_h": 5.0, "max_h": 9.0, "kind": "plant"},
		{"path": "plant", "side": -1.0, "offset": 28.0, "count": 5, "min_h": 5.0, "max_h": 8.0, "kind": "plant"},
		{"path": "airport", "side": 1.0, "offset": 22.0, "count": 12, "min_h": 3.2, "max_h": 4.6, "kind": "dacha"},
		{"path": "airport", "side": -1.0, "offset": 22.0, "count": 10, "min_h": 3.0, "max_h": 4.4, "kind": "dacha"},
	]
	for plan in plans:
		var curve: Curve3D = network["paths"][plan["path"]].curve
		var length: float = curve.get_baked_length()
		var count: int = int(plan["count"])
		for i in count:
			var d: float = length * (float(i) + 0.5) / count
			var p: Vector3 = curve.sample_baked(d)
			var ahead: Vector3 = curve.sample_baked(min(length, d + 1.0))
			var raw: Vector3 = ahead - p
			var forward := Vector3(raw.x, 0.0, raw.z).normalized()
			if forward.length() < 0.5:
				forward = Vector3(0, 0, 1)
			var right: Vector3 = -forward.cross(Vector3.UP).normalized()
			# Ширина — поперёк улицы (локальная ось X совпадает с right), глубина — вдоль.
			var kind := String(plan.get("kind", "tower"))
			var depth: float = rng.randf_range(7.0, 10.0) if kind == "dacha" else rng.randf_range(14.0, 28.0 if kind == "plant" else 18.0)
			var width: float = rng.randf_range(7.0, 11.0) if kind == "dacha" else rng.randf_range(12.0, 22.0 if kind == "plant" else 18.0)
			var height: float = rng.randf_range(float(plan["min_h"]), float(plan["max_h"]))
			var half_w := width * 0.5
			var half_d := depth * 0.5
			var side := float(plan["side"])
			var push: Vector3 = right * side
			# Ближняя стена начинается за тротуаром, а не на кромке асфальта.
			var away: float = _road_keepout(String(plan["path"])) + 4.0 + half_w + rng.randf_range(0.0, 8.0)
			var settled = _settle_off_road(p + push * away, push, forward, right, half_w, half_d, network)
			if settled == null:
				continue
			var center: Vector3 = settled
			var pick: int = rng.randi_range(0, textures.size() - 1)
			var mat := MeshLib.mat(Color(1, 1, 1), 0.9)
			if kind == "plant":
				mat = MeshLib.mat(Color(0.42, 0.44, 0.46), 0.88)
			elif kind == "dacha":
				mat = MeshLib.mat(Color(0.74, 0.58, 0.4), 0.9)
			else:
				mat.albedo_texture = textures[pick][0]
				mat.emission_enabled = true
				mat.emission_texture = textures[pick][1]
			# С операцией ADD цвет эмиссии прибавляется к текстуре и светится вся
			# стена; нужно умножение, чтобы горели только окна.
			mat.emission_operator = BaseMaterial3D.EMISSION_OP_MULTIPLY
			mat.emission = Color(1, 1, 1)
			mat.emission_energy_multiplier = 0.0
			mat.uv1_scale = Vector3(width / 7.0, height / 7.0, 1.0)
			var box := BoxMesh.new()
			box.size = Vector3(width, height, depth)
			var node := MeshLib.mesh_node(box, mat, "Block")
			node.position = Vector3(center.x, height * 0.5, center.z)
			node.rotation.y = atan2(forward.x, forward.z)
			var occluder := OccluderInstance3D.new()
			var box_occ := BoxOccluder3D.new()
			box_occ.size = box.size
			occluder.occluder = box_occ
			node.add_child(occluder)
			parent.add_child(node)
			if kind == "tower" or kind == "panel":
				out["night_materials"].append(mat)

			if kind == "dacha":
				var roof := MeshLib.box(Vector3(width + 0.6, 0.7, depth + 0.6),
					Vector3(center.x, height + 0.35, center.z), MeshLib.mat(Color(0.55, 0.22, 0.16), 0.85), "Roof")
				roof.rotation.y = node.rotation.y
				parent.add_child(roof)
				var fence := MeshLib.box(Vector3(width + 3.0, 0.9, 0.12),
					Vector3(center.x, 0.5, center.z), MeshLib.mat(Color(0.55, 0.5, 0.42), 0.9), "Fence")
				fence.rotation.y = node.rotation.y
				parent.add_child(fence)
			elif kind == "plant":
				var stack := MeshLib.cylinder(0.7, height * 0.85, MeshLib.mat(Color(0.62, 0.62, 0.64), 0.7), 12)
				stack.position = center + Vector3(width * 0.28, height + height * 0.4, 0)
				parent.add_child(stack)
			else:
				var roof := MeshLib.box(Vector3(width * 0.3, 1.6, depth * 0.3),
					Vector3(center.x, height + 0.8, center.z), MeshLib.mat(Color(0.4, 0.42, 0.44), 0.9), "RoofBox")
				roof.rotation.y = node.rotation.y
				parent.add_child(roof)
	_zone_signs(parent, network)


static func _zone_signs(parent: Node3D, network: Dictionary) -> void:
	var marks := [
		["prospekt", 0.45, "ЦЕНТР"],
		["east", 0.5, "СПАЛЬНЫЙ"],
		["north", 0.55, "ПРОМЗОНА"],
		["airport", 0.55, "ПРИГОРОД"],
		["highway", 0.08, "АВТОВОКЗАЛ"],
		["plant", 0.5, "ПРОМЗОНА"],
	]
	for mark in marks:
		var key := String(mark[0])
		if not network["paths"].has(key):
			continue
		var curve: Curve3D = network["paths"][key].curve
		var d: float = curve.get_baked_length() * float(mark[1])
		var p: Vector3 = curve.sample_baked(d)
		var sign := MeshLib.label(String(mark[2]), 72, Color(0.95, 0.9, 0.55))
		sign.position = p + Vector3(0, 14, 0)
		sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		parent.add_child(sign)


# Поперечные улицы, светофоры и знаки там, где проспект встречается с боковой дорогой.
static func _junctions(parent: Node3D, network: Dictionary) -> void:
	var spots := [
		["prospekt", 1], ["prospekt", 3], ["prospekt", 5],
		["east", 2], ["airport", 1],
	]
	var styles := Routes.path_style()
	for spot in spots:
		var key := String(spot[0])
		var index: int = int(spot[1])
		var anchors: Array = network["anchors"][key]
		if index >= anchors.size():
			continue
		var anchor: Dictionary = anchors[index]
		var curve: Curve3D = network["paths"][key].curve
		var frame := _sample_at(curve, float(anchor["offset"]))
		var half: float = float(styles[key]["half"])
		_side_road(parent, network, frame, half, key + str(index))
		_corner_signals(parent, frame, half)
		_road_sign(parent, frame["p"] + frame["r"] * (half + 3.6) + frame["f"] * 8.0, frame["f"], "60", Color(0.92, 0.92, 0.94))
		_road_sign(parent, frame["p"] - frame["r"] * (half + 6.5) + frame["f"] * 5.5, frame["r"], "УСТУПИ", Color(0.9, 0.9, 0.92))
		_road_sign(parent, frame["p"] + frame["r"] * (half + 3.6) - frame["f"] * 10.0, frame["f"], "ГЛАВНАЯ", Color(0.95, 0.78, 0.2))
		_road_sign(parent, frame["p"] + frame["r"] * (half + 3.6) + frame["f"] * 16.0, frame["f"], "ПЕШЕХОД", Color(0.2, 0.38, 0.72))
	# У отдельного полотна — знак, что это не полоса для машин.
	var prospekt: Array = network["anchors"]["prospekt"]
	if prospekt.size() > 2:
		var curve: Curve3D = network["paths"]["prospekt"].curve
		var frame := _sample_at(curve, float(prospekt[2]["offset"]))
		_road_sign(parent, frame["p"] + frame["r"] * 5.6, frame["f"], "ТРАМВАЙ", Color(0.15, 0.45, 0.28))


static func _side_road(parent: Node3D, network: Dictionary, frame: Dictionary, main_half: float, name: String) -> void:
	if not network.has("extras"):
		network["extras"] = []
	var along: Vector3 = frame["r"]
	var across: Vector3 = frame["f"]
	var asphalt := _asphalt(name)
	var side_half := 4.6
	for dir in [-1.0, 1.0]:
		var samples := []
		var steps := 12
		for i in steps:
			var dist: float = main_half * 0.15 + float(i) * 7.0
			samples.append({
				"p": frame["p"] + along * dir * dist,
				"r": across,
				"f": along * dir,
			})
		_ribbon(parent, samples, -side_half, side_half, 0.03, asphalt, "Cross_" + name)
		network["extras"].append({
			"p": samples[0]["p"],
			"f": (along * dir).normalized(),
			"len": float(steps - 1) * 7.0,
			"keep": side_half + 6.0,
		})
		var curb_mat := MeshLib.mat(Color(0.7, 0.69, 0.66), 0.8)
		for edge in [-side_half, side_half]:
			var low := _edges(samples, edge, 0.03)
			var high := _edges(samples, edge, SIDEWALK_H)
			parent.add_child(MeshLib.mesh_node(MeshLib.wall(low, high, edge > 0.0), curb_mat, "CrossCurb"))
		var walk := MeshLib.mat(Color(0.62, 0.62, 0.6), 0.85)
		_ribbon(parent, samples, side_half, side_half + 2.2, SIDEWALK_H, walk, "CrossWalk")
		_ribbon(parent, samples, -side_half - 2.2, -side_half, SIDEWALK_H, walk, "CrossWalk")
		var bar := MeshLib.mat(Color(0.95, 0.95, 0.96), 0.5)
		var stop := [samples[0], samples[1]]
		_ribbon(parent, stop, -side_half + 0.4, side_half - 0.4, 0.06, bar, "StopBar")
	# Площадка поперёк проспекта: боковые улицы входят в неё, перекрёсток читается.
	var apron := MeshLib.box(Vector3(main_half * 2.5, 0.07, side_half * 2.8),
		frame["p"] + Vector3(0, 0.05, 0),
		MeshLib.mat(Color(0.22, 0.23, 0.24), 0.75), "Junction")
	apron.rotation.y = atan2(frame["f"].x, frame["f"].z)
	parent.add_child(apron)


static func _corner_signals(parent: Node3D, frame: Dictionary, half: float) -> void:
	var pole_mat := MeshLib.mat(Color(0.22, 0.23, 0.25), 0.45, 0.55)
	var housing := MeshLib.mat(Color(0.1, 0.11, 0.12), 0.5)
	for side in [-1.0, 1.0]:
		for fore in [-1.0, 1.0]:
			var at: Vector3 = frame["p"] + frame["r"] * side * (half + 0.8) + frame["f"] * fore * 7.5
			var pole := MeshLib.cylinder(0.08, 4.6, pole_mat, 8)
			pole.position = at + Vector3(0, 2.3, 0)
			parent.add_child(pole)
			var head := MeshLib.box(Vector3(0.28, 0.95, 0.22), at + Vector3(0, 4.35, 0), housing, "Signal")
			parent.add_child(head)
			var colors := [Color(0.85, 0.12, 0.1), Color(0.9, 0.72, 0.12), Color(0.15, 0.72, 0.28)]
			for i in 3:
				var lamp := MeshLib.emissive(colors[i], 2.4 if i == 2 else 0.15)
				parent.add_child(MeshLib.box(Vector3(0.16, 0.16, 0.08),
					at + Vector3(0, 4.62 - float(i) * 0.28, 0.12), lamp, "Lamp"))


static func _road_sign(parent: Node3D, pos: Vector3, forward: Vector3, text: String, board: Color) -> void:
	var pole := MeshLib.cylinder(0.05, 2.7, MeshLib.mat(Color(0.25, 0.26, 0.28), 0.5, 0.4), 6)
	pole.position = pos + Vector3(0, 1.35, 0)
	parent.add_child(pole)
	var root := Node3D.new()
	root.name = "SignBoard"
	root.position = pos + Vector3(0, 2.55, 0)
	parent.add_child(root)
	var aim := Vector3(forward.x, 0, forward.z)
	if aim.length() > 0.1:
		root.look_at(root.global_position + aim, Vector3.UP)
	root.add_child(MeshLib.box(Vector3(2.3, 0.9, 0.05), Vector3.ZERO, MeshLib.mat(board, 0.72), "Sign"))
	var ink := Color(0.98, 0.98, 0.99) if board.get_luminance() < 0.45 else Color(0.06, 0.06, 0.08)
	var px := 0.013 if text.length() <= 3 else 0.0075
	var front := MeshLib.label(text, 48, ink)
	front.position = Vector3(0, 0, -0.08)
	front.pixel_size = px
	front.outline_size = 6
	front.double_sided = true
	front.no_depth_test = true
	root.add_child(front)
	var back := MeshLib.label(text, 48, ink)
	back.position = Vector3(0, 0, 0.08)
	back.rotation_degrees = Vector3(0, 180, 0)
	back.pixel_size = px
	back.outline_size = 6
	back.double_sided = true
	back.no_depth_test = true
	root.add_child(back)


static func _stops(parent: Node3D, network: Dictionary, out: Dictionary) -> void:
	var seen := {}
	var glass := MeshLib.glass(Color(0.2, 0.28, 0.32), 0.34)
	var metal := MeshLib.mat(Color(0.26, 0.28, 0.3), 0.5, 0.6)
	var roof_mat := MeshLib.mat(Color(0.84, 0.5, 0.12), 0.6)
	var pad_mat := MeshLib.mat(Color(0.68, 0.68, 0.66), 0.9)
	var styles := Routes.path_style()
	for key in network["anchors"].keys():
		var half: float = float(styles[key]["half"])
		var curve: Curve3D = network["paths"][key].curve
		for stop in network["anchors"][key]:
			var id: String = "%s:%s" % [key, stop["name"]]
			if seen.has(id):
				continue
			seen[id] = true
			var d: float = float(stop["offset"])
			var p: Vector3 = curve.sample_baked(d)
			var ahead: Vector3 = curve.sample_baked(minf(curve.get_baked_length(), d + 1.0))
			var tangent: Vector3 = ahead - p
			if tangent.length() < 0.05:
				var back: Vector3 = curve.sample_baked(maxf(0.0, d - 1.0))
				tangent = p - back
			if tangent.length() < 0.05:
				tangent = Vector3(0, 0, 1)
			var forward: Vector3 = tangent.normalized()
			var right: Vector3 = -forward.cross(Vector3.UP).normalized()
			var yaw: float = atan2(forward.x, forward.z)

			# Пешеходный переход за остановкой. По нему можно перейти улицу.
			out["crossings"].append({"path": key, "offset": d + 11.0, "half": half})
			var zebra_samples := []
			for t in [-2.2, 0.0, 2.2]:
				zebra_samples.append(_sample_at(curve, d + 11.0 + t))
			var zebra := MeshLib.mat(Color(1, 1, 1), 0.7)
			zebra.albedo_texture = MeshLib.zebra_texture()
			zebra.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
			zebra.uv1_scale = Vector3(half * 0.55, 1, 1)
			_ribbon(parent, zebra_samples, -half + 0.4, half - 0.4, 0.04, zebra, "Zebra")

			for side in [1.0, -1.0]:
				var stop_name := String(stop["name"])
				var kind := "bus"
				if key == "north" or (key == "prospekt" and side < 0.0):
					kind = "tram"
				elif key == "prospekt":
					kind = "trolley"
				elif key == "highway" and stop_name == "Автовокзал":
					if side < 0.0:
						continue
					kind = "station"
				var curb := half + (10.0 if kind == "station" else 1.7)
				var base: Vector3 = p + right * (side * curb)
				var group := Node3D.new()
				group.name = "Stop"
				group.position = base
				group.rotation.y = yaw
				parent.add_child(group)
				_furnish_stop(group, kind, stop_name, side, metal, glass, roof_mat, pad_mat)
				for i in 2:
					var person := make_person(Color(0.2 + 0.2 * i, 0.3, 0.45 - 0.1 * i))
					person.position = Vector3(0.2 + 0.4 * i, SIDEWALK_H + 0.05, -1.0 + 1.6 * i)
					person.rotation.y = PI * 0.5
					group.add_child(person)
			out["stops"].append({
				"name": String(stop["name"]),
				"path": key,
				"offset": d,
				"pos": p,
				"right": right,
				"forward": forward,
			})


static func _furnish_stop(group: Node3D, kind: String, stop_name: String, side: float, metal: Material, glass: Material, roof_mat: Material, pad_mat: Material) -> void:
	var wood := MeshLib.mat(Color(0.45, 0.3, 0.16), 0.9)
	var ink := MeshLib.mat(Color(0.08, 0.09, 0.1), 0.55)
	if kind == "station":
		group.add_child(MeshLib.box(Vector3(18.0, 0.2, 36.0), Vector3(0, 0.1, 0), pad_mat, "Plaza"))
		group.add_child(MeshLib.box(Vector3(16.0, 7.2, 30.0), Vector3(0, 3.7, 0),
			MeshLib.mat(Color(0.72, 0.7, 0.66), 0.82), "Hall"))
		var kassa := MeshLib.mat(Color(0.08, 0.16, 0.28), 0.25, 0.15)
		var face := -side * 8.55
		for z in [-11.0, -5.5, 0.0, 5.5, 11.0]:
			group.add_child(MeshLib.box(Vector3(0.45, 2.1, 3.4), Vector3(face, 2.5, z), kassa, "Kassa"))
		group.add_child(MeshLib.box(Vector3(3.2, 0.16, 14.0), Vector3(-side * 9.6, 3.7, 0), roof_mat, "Canopy"))
		var board := MeshLib.box(Vector3(0.2, 2.6, 5.4), Vector3(face, 5.0, -6.0), ink, "Schedule")
		group.add_child(board)
		var times := MeshLib.label("РАСПИСАНИЕ\n501  08:10\n502  11:40\n503  15:20", 32, Color(0.85, 0.95, 0.7))
		times.position = Vector3(face - side * 0.2, 5.0, -6.0)
		times.rotation_degrees = Vector3(0, 90 if side > 0 else -90, 0)
		group.add_child(times)
		var desks := MeshLib.label("КАССЫ", 48, Color(0.95, 0.85, 0.35))
		desks.position = Vector3(face - side * 0.35, 4.2, 6.0)
		desks.rotation_degrees = Vector3(0, 90 if side > 0 else -90, 0)
		group.add_child(desks)
		var title := MeshLib.label("АВТОВОКЗАЛ", 52)
		title.position = Vector3(0, 7.6, 0)
		group.add_child(title)
		return
	if kind == "bus":
		group.add_child(MeshLib.box(Vector3(2.4, SIDEWALK_H + 0.06, 7.0), Vector3(0, 0.08, 0), pad_mat, "Pad"))
		group.add_child(MeshLib.box(Vector3(1.8, 0.1, 0.42), Vector3(0, 0.55, 0), wood, "Bench"))
		group.add_child(MeshLib.box(Vector3(0.1, 2.8, 0.1), Vector3(side * -0.9, 1.5, 2.4), metal, "SignPost"))
		var plate := MeshLib.label("А", 42, Color(0.15, 0.45, 0.85))
		plate.position = Vector3(side * -0.9, 2.7, 2.4)
		group.add_child(plate)
		var sign := MeshLib.label(stop_name, 36)
		sign.position = Vector3(side * -0.9, 2.15, 2.4)
		sign.rotation_degrees = Vector3(0, 90 if side > 0 else -90, 0)
		group.add_child(sign)
		return
	group.add_child(MeshLib.box(Vector3(3.0, SIDEWALK_H + 0.06, 14.0), Vector3(0, 0.08, 0), pad_mat, "Pad"))
	for dz in [-2.4, 2.4]:
		group.add_child(MeshLib.box(Vector3(0.12, 2.6, 0.12), Vector3(-1.2, 1.44, dz), metal, "Post"))
		group.add_child(MeshLib.box(Vector3(0.12, 2.6, 0.12), Vector3(1.2, 1.44, dz), metal, "Post"))
	group.add_child(MeshLib.box(Vector3(3.2, 0.12, 5.6), Vector3(0, 2.78, 0), roof_mat, "Roof"))
	group.add_child(MeshLib.box(Vector3(0.06, 2.2, 5.4), Vector3(-1.32, 1.6, 0), glass, "BackGlass"))
	group.add_child(MeshLib.box(Vector3(2.6, 0.1, 0.42), Vector3(-0.7, 0.62, 0), wood, "Bench"))
	if kind == "tram":
		var rail := MeshLib.mat(Color(0.55, 0.5, 0.46), 0.45, 0.7)
		group.add_child(MeshLib.box(Vector3(0.1, 0.08, 12.0), Vector3(-side * 2.5, 0.08, 0), rail, "Rail"))
		group.add_child(MeshLib.box(Vector3(0.1, 0.08, 12.0), Vector3(-side * 3.05, 0.08, 0), rail, "Rail"))
		group.add_child(MeshLib.box(Vector3(0.08, 0.7, 1.6), Vector3(0, 2.2, -2.3), ink, "Tablo"))
		var times := MeshLib.label("ТАБЛО", 32, Color(0.45, 1.0, 0.55))
		times.position = Vector3(side * 0.08, 2.2, -2.3)
		group.add_child(times)
	else:
		var wire := MeshLib.mat(Color(0.15, 0.16, 0.18), 0.4, 0.2)
		group.add_child(MeshLib.box(Vector3(0.08, 6.2, 0.08), Vector3(-side * 1.4, 3.1, -2.8), metal, "Pole"))
		group.add_child(MeshLib.box(Vector3(0.08, 6.2, 0.08), Vector3(-side * 6.2, 3.1, -2.8), metal, "Pole"))
		group.add_child(MeshLib.box(Vector3(4.8, 0.05, 0.05), Vector3(-side * 3.8, 6.1, -2.8), wire, "Wire"))
	group.add_child(MeshLib.box(Vector3(0.1, 3.2, 0.1), Vector3(1.3, 1.7, 3.6), metal, "SignPost"))
	var sign := MeshLib.label(stop_name, 40)
	sign.position = Vector3(1.42, 3.0, 3.6)
	sign.rotation_degrees = Vector3(0, 90 if side > 0 else -90, 0)
	group.add_child(sign)


static func make_person(coat: Color) -> Node3D:
	var root := Node3D.new()
	root.name = "Person"
	var skin := MeshLib.mat(Color(0.86, 0.68, 0.56), 0.85)
	var cloth := MeshLib.mat(coat, 0.95)
	var legs := MeshLib.mat(Color(0.16, 0.17, 0.2), 0.95)
	var body := CapsuleMesh.new()
	body.radius = 0.2
	body.height = 0.86
	body.radial_segments = 10
	body.rings = 4
	var torso := MeshLib.mesh_node(body, cloth, "Torso")
	torso.position = Vector3(0, 1.16, 0)
	root.add_child(torso)
	var head := SphereMesh.new()
	head.radius = 0.12
	head.height = 0.26
	head.radial_segments = 10
	head.rings = 6
	var head_node := MeshLib.mesh_node(head, skin, "Head")
	head_node.position = Vector3(0, 1.72, 0)
	root.add_child(head_node)
	for side in [-1.0, 1.0]:
		var leg := CapsuleMesh.new()
		leg.radius = 0.09
		leg.height = 0.78
		leg.radial_segments = 8
		leg.rings = 3
		var leg_node := MeshLib.mesh_node(leg, legs, "Leg")
		leg_node.position = Vector3(side * 0.11, 0.42, 0)
		root.add_child(leg_node)
		var arm := CapsuleMesh.new()
		arm.radius = 0.07
		arm.height = 0.66
		arm.radial_segments = 8
		arm.rings = 3
		var arm_node := MeshLib.mesh_node(arm, cloth, "Arm")
		arm_node.position = Vector3(side * 0.28, 1.16, 0)
		root.add_child(arm_node)
	return root


static func _beside(network: Dictionary, path_name: String, index: int, side: float, dist: float) -> Vector3:
	var stops: Array = network["anchors"][path_name]
	var stop: Dictionary = stops[clampi(index, 0, stops.size() - 1)]
	var curve: Curve3D = network["paths"][path_name].curve
	var frame := _sample_at(curve, float(stop["offset"]))
	return frame["p"] + frame["r"] * side * dist


static func _billboard(parent: Node3D, text: String, pos: Vector3, size := 72, color := Color(0.96, 0.8, 0.35)) -> void:
	var label := MeshLib.label(text, size, color)
	label.position = pos
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	parent.add_child(label)


static func _place_landmark(parent: Node3D, network: Dictionary, path_name: String, index: int,
		side: float, size: Vector3, y_center: float, material: Material, node_name: String, title: String) -> void:
	var stops: Array = network["anchors"][path_name]
	var stop: Dictionary = stops[clampi(index, 0, stops.size() - 1)]
	var frame := _sample_at(network["paths"][path_name].curve, float(stop["offset"]))
	var forward: Vector3 = frame["f"]
	var right: Vector3 = frame["r"]
	var half_w := size.x * 0.5
	var half_d := size.z * 0.5
	var push: Vector3 = right * side
	var away: float = _road_keepout(path_name) + 6.0 + half_w
	var settled = _settle_off_road(frame["p"] + push * away, push, forward, right, half_w, half_d, network)
	var center: Vector3 = settled if settled != null else frame["p"] + push * (away + 30.0)
	var node := MeshLib.box(size, Vector3(center.x, y_center, center.z), material, node_name)
	node.rotation.y = atan2(forward.x, forward.z)
	parent.add_child(node)
	_billboard(parent, title, Vector3(center.x, size.y + 6.0, center.z), 72, Color(1, 1, 1))


static func _landmarks(parent: Node3D, network: Dictionary, out: Dictionary) -> void:
	var circus_frame := _sample_at(network["paths"]["prospekt"].curve,
		float(network["anchors"]["prospekt"][2]["offset"]))
	var circus: Vector3 = circus_frame["p"] + circus_frame["r"] * (_road_keepout("prospekt") + 24.0)
	var circus_mat := MeshLib.mat(Color(0.74, 0.16, 0.16), 0.7)
	var drum := CylinderMesh.new()
	drum.top_radius = 17.0
	drum.bottom_radius = 19.0
	drum.height = 13.0
	drum.radial_segments = 28
	var drum_node := MeshLib.mesh_node(drum, circus_mat, "Circus")
	drum_node.position = circus + Vector3(0, 6.5, 0)
	parent.add_child(drum_node)
	var cone := CylinderMesh.new()
	cone.top_radius = 0.6
	cone.bottom_radius = 18.0
	cone.height = 8.0
	cone.radial_segments = 28
	var cone_node := MeshLib.mesh_node(cone, MeshLib.mat(Color(0.9, 0.76, 0.3), 0.6, 0.2), "CircusRoof")
	cone_node.position = circus + Vector3(0, 17.0, 0)
	parent.add_child(cone_node)
	_billboard(parent, "Госцирк", circus + Vector3(0, 25, 0), 72, Color(1, 1, 1))
	out["focus"] = circus + Vector3(0, 8, 0)

	_place_landmark(parent, network, "prospekt", 6, -1.0, Vector3(28, 17, 48), 8.5,
		MeshLib.mat(Color(0.88, 0.85, 0.76), 0.85), "Station", "Ж/д вокзал")
	_place_landmark(parent, network, "prospekt", 0, 1.0, Vector3(22, 11, 40), 5.5,
		MeshLib.mat(Color(0.5, 0.54, 0.57), 0.9), "Depot", "Депо № 1")
	_place_landmark(parent, network, "north", 0, -1.0, Vector3(22, 11, 40), 5.5,
		MeshLib.mat(Color(0.5, 0.54, 0.57), 0.9), "Depot", "Депо Черниковки")

	var park_at := _beside(network, "prospekt", 0, -1.0, _road_keepout("prospekt") + 36.0)
	var park := CylinderMesh.new()
	park.top_radius = 18.0
	park.bottom_radius = 18.0
	park.height = 0.18
	park.radial_segments = 28
	var park_node := MeshLib.mesh_node(park, MeshLib.mat(Color(0.22, 0.4, 0.18), 0.98), "Park")
	park_node.position = park_at + Vector3(0, 0.1, 0)
	parent.add_child(park_node)

	_place_landmark(parent, network, "airport", 4, 1.0, Vector3(24, 12, 48), 6.0,
		MeshLib.mat(Color(0.8, 0.83, 0.86), 0.7), "Airport", "Аэропорт")

	var prospekt_mid: Vector3 = network["paths"]["prospekt"].curve.sample_baked(
		network["paths"]["prospekt"].curve.get_baked_length() * 0.5)
	var north_mid: Vector3 = network["paths"]["north"].curve.sample_baked(
		network["paths"]["north"].curve.get_baked_length() * 0.45)
	_billboard(parent, "Проспект Октября", prospekt_mid + Vector3(0, 42, 0), 96)
	_billboard(parent, "Черниковка", north_mid + Vector3(0, 36, 0), 96)


# Холмы в стороне от улиц, плоская полка под дорогой и ложбина реки.
static func _terrain(parent: Node3D, network: Dictionary, out: Dictionary) -> void:
	var corridor: Array = []
	for key in network["paths"].keys():
		var curve: Curve3D = network["paths"][key].curve
		corridor.append_array(_sample(curve, 10.0))
	var noise := FastNoiseLite.new()
	noise.seed = 41
	noise.frequency = 0.0026
	noise.fractal_octaves = 4
	var terrain := {
		"corridor": corridor,
		"noise": noise,
		"river": out.get("river", Vector3(615, 0, -245)),
	}
	out["terrain"] = terrain
	var x0 := -860.0
	var z0 := -640.0
	var x1 := 1080.0
	var z1 := 700.0
	var step := 10.0
	var cols := int((x1 - x0) / step)
	var rows := int((z1 - z0) / step)
	var heights: Array = []
	for j in rows + 1:
		var row := PackedFloat32Array()
		row.resize(cols + 1)
		var z: float = z0 + float(j) * step
		for i in cols + 1:
			row[i] = ground_height(x0 + float(i) * step, z, terrain)
		heights.append(row)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var uv_scale := 1.0 / 8.0
	for j in rows:
		for i in cols:
			var x_a := x0 + float(i) * step
			var z_a := z0 + float(j) * step
			var x_b := x_a + step
			var z_b := z_a + step
			var h00: float = heights[j][i]
			var h10: float = heights[j][i + 1]
			var h11: float = heights[j + 1][i + 1]
			var h01: float = heights[j + 1][i]
			_terrain_tri(st, Vector3(x_a, h00, z_a), Vector3(x_b, h10, z_a), Vector3(x_b, h11, z_b), uv_scale)
			_terrain_tri(st, Vector3(x_a, h00, z_a), Vector3(x_b, h11, z_b), Vector3(x_a, h01, z_b), uv_scale)
			if h00 > 5.0 and i % 6 == 0 and j % 6 == 0:
				parent.add_child(_tree(Vector3(x_a, h00, z_a), i * 31 + j * 17))
	st.generate_normals()
	var mat := MeshLib.terrain_material(out["ground_grass"])
	out["terrain_material"] = mat
	parent.add_child(MeshLib.mesh_node(st.commit(), mat, "Terrain"))


static func _terrain_tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, uv_scale: float) -> void:
	st.set_uv(Vector2(a.x * uv_scale, a.z * uv_scale))
	st.add_vertex(a)
	st.set_uv(Vector2(b.x * uv_scale, b.z * uv_scale))
	st.add_vertex(b)
	st.set_uv(Vector2(c.x * uv_scale, c.z * uv_scale))
	st.add_vertex(c)


static func ground_height(x: float, z: float, terrain: Dictionary) -> float:
	var best := 1.0e12
	var nearest_y := 0.0
	for s in terrain["corridor"]:
		var p: Vector3 = s["p"]
		var d2 := (p.x - x) * (p.x - x) + (p.z - z) * (p.z - z)
		if d2 < best:
			best = d2
			nearest_y = p.y
	var dist := sqrt(best)
	var noise: FastNoiseLite = terrain["noise"]
	var hill: float = noise.get_noise_2d(x, z) * 18.0
	var river: Vector3 = terrain["river"]
	var basin := 1.0 - smoothstep(48.0, 155.0, Vector2(x - river.x, z - river.z).length())
	var away: float = smoothstep(36.0, 90.0, dist)
	var shaped: float = hill * away - 0.06
	shaped = lerp(shaped, -1.75, basin * (1.0 - smoothstep(20.0, 42.0, dist)))
	# Полка ниже асфальта шире проезжей части: склон холма не перерезает ленту дороги.
	var shelf: float = nearest_y - 0.45
	if dist < 30.0:
		if dist > 16.0 and basin > 0.2:
			return lerp(shelf, -1.8, basin * (dist - 16.0) / 14.0)
		return shelf
	return lerp(shelf, shaped, smoothstep(30.0, 52.0, dist))


static func surface_y(x: float, z: float, terrain: Dictionary) -> float:
	var best := 1.0e12
	var road_y := 0.0
	for s in terrain["corridor"]:
		var p: Vector3 = s["p"]
		var d2 := (p.x - x) * (p.x - x) + (p.z - z) * (p.z - z)
		if d2 < best:
			best = d2
			road_y = p.y
	if best < 324.0:
		return road_y
	return ground_height(x, z, terrain)
