class_name Vehicle
extends Node3D

# Машина на маршруте: секции едут по одной кривой со своим смещением.

var model_id: String
var title: String
var vehicle_type: String
var route: Dictionary
var curve: Curve3D
var path_length: float

var sections: Array = []
var offsets: Array = []
var doors: Array = []
var wheels: Array = []
var knuckles: Array = []
var headlights: Array = []
var interior_lights: Array = []
var beams: Array = []
var taillights: Array = []
var braking := false
var cabin: Node3D = null
var seat: Node3D = null
var steering_rim: Node3D = null

var body_length := 12.0
var lane := 0.0
var progress := 0.0
var dir := 1
var speed := 0.0
var reversing := false
var doors_open := false
var door_amount := 0.0
var dwell := 0.0
var ai := true
var m0 := 0.0
var m1 := 0.0
var skip_offset := -1.0
var wheel_spin := 0.0
var last_stop_name := ""
var lead_gap := 999.0
var end_latch := false
var detailed := false
var lateral := 0.0
var steer := 0.0
var steer_rate := 0.0
# Курс кузова в мире. Нос смотрит в (−sin, 0, −cos). Дорога сама его не крутит.
var heading := 0.0
var trail_heading := 0.0
var free_heading := false
var booms: Array = []
var fleet_no := 0
var lod := 0
var clack_wait := 0.0
var radio: AudioStreamPlayer3D
var condition := {}
var squeak_player: AudioStreamPlayer3D
var squeak_wait := 0.0
var engine: AudioStreamPlayer3D
var door_was := false


func setup(route_data: Dictionary, model: String, with_interior: bool, lod_level := 0) -> void:
	route = route_data
	model_id = model
	lod = lod_level
	_install(Fleet.build(model, String(route["number"]), with_interior, lod_level), with_interior)
	if fleet_no > 0:
		assign_identity(fleet_no)
	var path_node: Path3D = route["path_node"]
	curve = path_node.curve
	path_length = curve.get_baked_length()
	m0 = float(route["m0"])
	m1 = float(route["m1"])
	lane = Routes.lane_offset(vehicle_type, String(route["path"]))
	progress = m0
	update_pose()


# Пассажир садится в рейсовую машину, у которой салона не было: достраиваем.
func upgrade_interior() -> void:
	if detailed:
		return
	var number := fleet_no
	for section in sections:
		(section as Node3D).queue_free()
	_install(Fleet.build(model_id, String(route["number"]), true, 0), true)
	lod = 0
	update_pose()
	animate(0.0)
	if number > 0:
		assign_identity(number)


func _install(built: Dictionary, with_interior: bool) -> void:
	detailed = with_interior
	sections = built["sections"]
	offsets = built["offsets"]
	doors = built["doors"]
	wheels = built["wheels"]
	knuckles = built["steer"]
	headlights = built["headlights"]
	interior_lights = built["interior_lights"]
	beams = built["beams"]
	taillights = built["taillights"]
	cabin = built["cabin"]
	seat = built["seat"]
	steering_rim = built["steering"]
	booms = built["booms"]
	body_length = float(built["length"])
	title = String(built["title"])
	vehicle_type = String(built["type"])
	for section in sections:
		add_child(section)


# Половина длины салона одной секции — по ней ограничиваем ходьбу внутри.
func salon_span() -> float:
	return max(0.8, body_length / float(max(1, sections.size())) * 0.5 - 1.3)


func stops() -> Array:
	return route["stops"]


func set_progress(value: float) -> void:
	progress = clamp(value, m0, m1)
	update_pose()


func road_frame(at: float) -> Dictionary:
	var d: float = clampf(at, 0.6, max(0.6, path_length - 0.6))
	var p: Vector3 = curve.sample_baked(d)
	var ahead: Vector3 = curve.sample_baked(min(path_length, d + 0.8))
	var behind: Vector3 = curve.sample_baked(max(0.0, d - 0.8))
	var raw := Vector3(ahead.x - behind.x, 0.0, ahead.z - behind.z)
	var forward := raw
	if forward.length() < 0.05:
		forward = Vector3(0, 0, -1)
	else:
		forward = forward.normalized() * float(dir)
	var right: Vector3 = forward.cross(Vector3.UP).normalized()
	return {"p": p, "forward": forward, "right": right, "d": d}


static func yaw_from_forward(forward: Vector3) -> float:
	return atan2(-forward.x, -forward.z)


static func nose_from_yaw(yaw: float) -> Vector3:
	return Vector3(-sin(yaw), 0.0, -cos(yaw))


func sync_heading() -> void:
	heading = yaw_from_forward(road_frame(progress)["forward"])
	trail_heading = heading


func update_pose() -> void:
	for i in sections.size():
		var along: float = (body_length * 0.5 - float(offsets[i])) * float(dir)
		var frame: Dictionary = road_frame(progress + along)
		var right: Vector3 = frame["right"]
		var node: Node3D = sections[i]
		node.global_position = frame["p"] + right * (lane + lateral)
		var aim: Vector3 = frame["forward"]
		if free_heading:
			var yaw: float = heading if i == 0 else trail_heading
			aim = nose_from_yaw(yaw)
		node.look_at(node.global_position + aim, Vector3.UP)
	_stick_booms()


# Башмаки штанг держатся за два провода над своей полосой и едут по ним.
func _stick_booms() -> void:
	if booms.is_empty() or curve == null:
		return
	for boom in booms:
		var pivot: Node3D = boom["pivot"]
		var section: Node3D = pivot.get_parent() as Node3D
		var idx: int = sections.find(section)
		if idx < 0:
			continue
		var along: float = (body_length * 0.5 - float(offsets[idx])) * float(dir)
		# Длинный ход назад: штанга достаёт провод и у оси, и у бордюра.
		var back: Dictionary = road_frame(progress + along - 6.8 * float(dir))
		var right: Vector3 = back["right"]
		var side: float = float(boom["side"])
		var wire: Vector3 = back["p"] + right * (lane + side * 0.3) + Vector3(0, 5.9, 0)
		var base: Vector3 = pivot.global_position
		var delta: Vector3 = wire - base
		var dist: float = delta.length()
		if dist < 0.35:
			continue
		pivot.look_at(wire, Vector3.UP)
		# Цилиндр идёт вдоль +Y, look_at направляет −Z на провод.
		pivot.rotate_object_local(Vector3.RIGHT, -PI * 0.5)
		var pole: MeshInstance3D = boom["pole"]
		var cyl: CylinderMesh = pole.mesh as CylinderMesh
		cyl.height = dist
		pole.position = Vector3(0, dist * 0.5, 0)
		var shoe: Node3D = boom["shoe"]
		shoe.position = Vector3(0, dist, 0)


# Бортовой номер модели и состояние: грязь на кузове, скрип на ходу.
func assign_identity(number: int) -> void:
	fleet_no = number
	condition = Fleet.condition_for(number)
	squeak_wait = float(number % 5) * 0.35
	_apply_dirt(float(condition["dirt"]))
	_apply_plates(str(number))
	_ensure_squeak()


func _apply_dirt(amount: float) -> void:
	if amount < 0.04:
		return
	var names := ["BodyLow", "BodyHigh", "FrontCap", "RearCap", "Skirt", "Bonnet", "FrontSkirt"]
	var mud := Color(0.3, 0.25, 0.18)
	for section in sections:
		for child in (section as Node3D).get_children():
			if not (child is MeshInstance3D) or not (String(child.name) in names):
				continue
			var mesh_node := child as MeshInstance3D
			var src := mesh_node.material_override as StandardMaterial3D
			if src == null:
				continue
			var painted := src.duplicate() as StandardMaterial3D
			painted.albedo_color = src.albedo_color.lerp(mud, amount)
			painted.roughness = lerpf(src.roughness, 0.94, amount)
			painted.clearcoat = lerpf(src.clearcoat, 0.0, amount)
			mesh_node.material_override = painted


func _apply_plates(text: String) -> void:
	var sp := Fleet.spec(model_id)
	var half_w: float = float(sp["half_w"])
	var y0: float = float(sp["y0"])
	var board_y: float = min(float(sp["win_high"]) + 0.34, float(sp["y1"]) - 0.16)
	var front: Node3D = sections[0]
	var seg: float = float(offsets[0]) * 2.0
	var nose: float = 0.95 if bool(sp.get("bonnet", false)) else 0.08
	var front_y := y0 + 0.55 if model_id == "ikarus" else board_y - 0.55
	_plate(front, text, Vector3(0, front_y, -seg * 0.5 - nose - 0.06), 180.0)
	_plate(front, text, Vector3(half_w + 0.1, y0 + 1.15, seg * 0.05), 90.0)
	_plate(front, text, Vector3(-(half_w + 0.1), y0 + 1.15, seg * 0.05), -90.0)
	var rear: Node3D = sections[sections.size() - 1]
	var rear_z: float = seg * 0.5 + 0.02
	if sections.size() > 1:
		rear_z = max(2.2, (float(offsets[offsets.size() - 1]) - float(offsets[offsets.size() - 2])) * 0.42)
	_plate(rear, text, Vector3(0, y0 + 0.72, rear_z), 0.0)


func _plate(parent: Node3D, text: String, pos: Vector3, yaw: float) -> void:
	var root := Node3D.new()
	root.name = "FleetPlate"
	root.position = pos
	root.rotation_degrees = Vector3(0, yaw, 0)
	parent.add_child(root)
	root.add_child(MeshLib.box(Vector3(1.35, 0.46, 0.04), Vector3.ZERO,
		MeshLib.mat(Color(0.96, 0.95, 0.9), 0.5), "Plate"))
	var ink := Color(0.05, 0.05, 0.07)
	var face := MeshLib.label(text, 64, ink)
	face.position = Vector3(0, 0, -0.07)
	face.pixel_size = 0.0045
	face.outline_size = 4
	root.add_child(face)
	var back := MeshLib.label(text, 64, ink)
	back.position = Vector3(0, 0, 0.07)
	back.rotation_degrees = Vector3(0, 180, 0)
	back.pixel_size = 0.0045
	back.outline_size = 4
	root.add_child(back)


func _ensure_squeak() -> void:
	if float(condition.get("squeak", 0.0)) < 0.15:
		return
	if squeak_player != null:
		return
	squeak_player = AudioStreamPlayer3D.new()
	squeak_player.stream = Fleet.squeak_clip()
	squeak_player.unit_size = 7.0
	squeak_player.max_distance = 26.0
	squeak_player.volume_db = lerpf(-16.0, -7.0, float(condition["squeak"]))
	squeak_player.pitch_scale = float(condition["pitch"])
	add_child(squeak_player)


func consider_lod(cam: Vector3, keep_near: bool) -> void:
	if keep_near:
		return
	var dist := global_position.distance_to(cam)
	var next := 0 if dist < 32.0 else (1 if dist < 78.0 else 2)
	if next == lod:
		return
	var number := fleet_no
	var open := doors_open
	lod = next
	for section in sections:
		(section as Node3D).queue_free()
	_install(Fleet.build(model_id, String(route["number"]), false, next), false)
	if number > 0:
		assign_identity(number)
	doors_open = open
	update_pose()


func _tick_engine(delta: float) -> void:
	if engine == null:
		engine = AudioStreamPlayer3D.new()
		engine.stream = Sfx.engine_clip(vehicle_type, model_id)
		engine.unit_size = 8.0
		engine.max_distance = 38.0
		engine.volume_db = -22.0
		add_child(engine)
		engine.play()
	var moving := clampf(absf(speed) / 11.0, 0.0, 1.0)
	var tone := 1.0
	if Fleet.is_small(model_id):
		tone = 1.28
	elif model_id == "ikarus" or model_id == "yutong":
		tone = 0.72
	engine.pitch_scale = lerpf(0.84, 1.42, moving) * tone
	var quiet := -6.0 if model_id == "ikarus" or model_id == "yutong" else 0.0
	engine.volume_db = lerpf(-23.0, -11.0, moving) + quiet
	if not engine.playing:
		engine.play()
	if Fleet.is_small(model_id) and radio == null:
		radio = AudioStreamPlayer3D.new()
		radio.stream = Sfx.tune_clip()
		radio.unit_size = 4.0
		radio.max_distance = 14.0
		radio.volume_db = -20.0
		add_child(radio)
		radio.play()
	if vehicle_type == "tram" and absf(speed) > 2.0:
		clack_wait -= delta
		if clack_wait <= 0.0:
			clack_wait = 0.34
			Sfx.burst(self, Sfx.clack_clip(), -14.0, 0.9 + absf(speed) / 20.0)
	elif vehicle_type == "trolley" and absf(speed) > 1.2:
		clack_wait -= delta
		if clack_wait <= 0.0:
			clack_wait = 1.8
			Sfx.burst(self, Sfx.squeak_clip(), -16.0, 0.85)


func _tick_doors() -> void:
	if doors_open == door_was:
		return
	door_was = doors_open
	Sfx.burst(self, Sfx.door_clip(doors_open), -9.0)
	if vehicle_type == "bus":
		Sfx.burst(self, Sfx.squeak_clip(), -11.0, 0.62)


func _tick_wear(delta: float) -> void:
	if squeak_player == null or speed < 1.4:
		return
	squeak_wait -= delta
	if squeak_wait > 0.0:
		return
	squeak_wait = lerpf(2.6, 0.65, float(condition.get("squeak", 0.0)))
	squeak_player.play()


func animate(delta: float) -> void:
	var target: float = 1.0 if doors_open else 0.0
	door_amount = move_toward(door_amount, target, delta * 1.8)
	for door in doors:
		var node: Node3D = door["node"]
		var base: Vector3 = door["base"]
		var slide: Vector3 = door["slide"]
		node.position = base + slide * door_amount
	var spin_speed := -speed if reversing else speed
	if absf(spin_speed) > 0.01:
		wheel_spin += spin_speed * delta / 0.5
		for w in wheels:
			(w as Node3D).rotation.x = wheel_spin
	for knuckle in knuckles:
		(knuckle as Node3D).rotation.y = -steer * 0.5
	if steering_rim != null:
		steering_rim.rotation.y = -steer * 2.1
	for mat in taillights:
		(mat as StandardMaterial3D).emission_energy_multiplier = 4.0 if braking else 1.1
	update_pose()
	_tick_wear(delta)
	_tick_engine(delta)
	_tick_doors()


func next_stop() -> Dictionary:
	var list: Array = stops()
	var best := {}
	if dir > 0:
		for stop in list:
			if float(stop["offset"]) > progress + 1.0 and not _skipped(stop):
				return stop
		best = list[list.size() - 1]
	else:
		for i in range(list.size() - 1, -1, -1):
			var stop: Dictionary = list[i]
			if float(stop["offset"]) < progress - 1.0 and not _skipped(stop):
				return stop
		best = list[0]
	return best


func _skipped(stop: Dictionary) -> bool:
	return skip_offset >= 0.0 and absf(float(stop["offset"]) - skip_offset) < 3.0


func distance_to_next() -> float:
	var stop := next_stop()
	if stop.is_empty():
		return 999.0
	return absf(float(stop["offset"]) - progress)


func _check_terminus() -> void:
	# У конечной машина разворачивается один раз и уходит обратно.
	if end_latch:
		if progress > m0 + 14.0 and progress < m1 - 14.0:
			end_latch = false
		return
	if dir > 0 and progress >= m1 - 3.5:
		dir = -1
	elif dir < 0 and progress <= m0 + 3.5:
		dir = 1
	else:
		return
	end_latch = true
	speed = 0.0
	skip_offset = -1.0
	dwell = max(dwell, 5.0)


func update_ai(delta: float, weather: String) -> void:
	var cap: float = Rules.speed_cap(vehicle_type, weather) * 0.82
	_check_terminus()
	if skip_offset >= 0.0 and absf(progress - skip_offset) > 25.0:
		skip_offset = -1.0
	if dwell > 0.0:
		speed = 0.0
		braking = true
		dwell -= delta
		doors_open = dwell > 0.6
	else:
		var dist := distance_to_next()
		var target: float = cap if dist > 30.0 else clamp(dist * 0.45, 0.0, cap)
		if lead_gap < 18.0:
			target = min(target, clamp((lead_gap - 7.0) * 0.6, 0.0, cap))
		braking = target < speed - 0.2
		if speed < target:
			speed = min(target, speed + 3.0 * delta)
		else:
			speed = max(target, speed - 6.0 * delta)
		if dist < 2.5 and speed < 1.6:
			speed = 0.0
			dwell = 7.0
			doors_open = true
			var stop := next_stop()
			skip_offset = float(stop["offset"])
			last_stop_name = String(stop["name"])
	_advance(delta)
	animate(delta)


func _advance(delta: float) -> void:
	progress += speed * delta * float(dir)
	if progress >= m1:
		progress = m1
		if dir > 0:
			dir = -1
			speed = 0.0
			skip_offset = -1.0
			dwell = max(dwell, 4.0)
	elif progress <= m0:
		progress = m0
		if dir < 0:
			dir = 1
			speed = 0.0
			skip_offset = -1.0
			dwell = max(dwell, 4.0)


func at_terminus() -> bool:
	return progress <= m0 + 0.8 or progress >= m1 - 0.8


func front() -> Node3D:
	return sections[0] as Node3D


func front_position() -> Vector3:
	return (sections[0] as Node3D).global_position


# Точка у правой двери и точка уже в салоне: пассажир идёт с тротуара внутрь.
func curb_points() -> Dictionary:
	var section: Node3D = front()
	var z := 1.0
	var x := 1.7
	if not doors.is_empty():
		var leaf: Node3D = doors[0]["node"]
		if leaf.get_parent() is Node3D:
			section = leaf.get_parent() as Node3D
		var base: Vector3 = doors[0]["base"]
		z = base.z
		x = absf(base.x) + 0.85
	var floor_y: float = float(Fleet.spec(model_id)["floor"])
	return {
		"out": section.to_global(Vector3(x, 0.05, z)),
		"in": section.to_global(Vector3(0.2, floor_y, z * 0.25)),
	}


func cabin_point() -> Node3D:
	return cabin if cabin != null else (sections[0] as Node3D)


func seat_point() -> Node3D:
	return seat if seat != null else (sections[0] as Node3D)


func dispose() -> void:
	queue_free()
