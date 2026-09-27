class_name TownCar
extends Node3D

# Личная машина пассажира: аркадная развозка по городу.
# Кузов собран из тех же примитивов, что и автопарк, чтобы держать один стиль.

const MAX_SPEED := 26.0
const MAX_REVERSE := -7.0
const ACCEL := 6.2
const BRAKE := 11.0
const DRAG := 1.6
const PRICE := 3500

var speed := 0.0
var yaw := 0.0
var steer := 0.0
var wheels: Array = []
var knuckles: Array = []
var spin := 0.0
var tail_materials: Array = []
var engine: AudioStreamPlayer3D


static func body_mesh(color: Color) -> Node3D:
	var root := Node3D.new()
	root.name = "CarBody"
	var paint := MeshLib.paint(color)
	var dark := MeshLib.mat(Color(0.1, 0.11, 0.13), 0.6, 0.3)
	var glass := MeshLib.glass(Color(0.14, 0.18, 0.22), 0.5)
	# Низ кузова, капот, багажник и крыша: седан без лишних деталей.
	root.add_child(MeshLib.box(Vector3(1.78, 0.5, 4.3), Vector3(0, 0.62, 0), paint, "Hull"))
	root.add_child(MeshLib.box(Vector3(1.7, 0.3, 1.2), Vector3(0, 0.95, -1.5), paint, "Hood"))
	root.add_child(MeshLib.box(Vector3(1.7, 0.34, 1.0), Vector3(0, 0.97, 1.6), paint, "Trunk"))
	root.add_child(MeshLib.box(Vector3(1.62, 0.62, 2.1), Vector3(0, 1.2, 0.1), paint, "Cabin"))
	root.add_child(MeshLib.box(Vector3(1.5, 0.5, 0.08), Vector3(0, 1.22, -0.95), glass, "Windshield"))
	root.add_child(MeshLib.box(Vector3(1.5, 0.46, 0.08), Vector3(0, 1.22, 1.15), glass, "RearGlass"))
	for side in [-1.0, 1.0]:
		root.add_child(MeshLib.box(Vector3(0.06, 0.44, 1.9), Vector3(side * 0.82, 1.2, 0.1), glass, "SideGlass"))
		root.add_child(MeshLib.box(Vector3(0.3, 0.18, 0.1), Vector3(side * 0.6, 0.86, -2.14),
			MeshLib.emissive(Color(1.0, 0.96, 0.86), 0.6), "Head"))
		root.add_child(MeshLib.box(Vector3(0.32, 0.16, 0.1), Vector3(side * 0.62, 0.9, 2.14),
			MeshLib.emissive(Color(0.9, 0.12, 0.1), 0.9), "Tail"))
		root.add_child(MeshLib.box(Vector3(0.14, 0.1, 0.5), Vector3(side * 0.9, 1.26, -0.8), dark, "Mirror"))
	root.add_child(MeshLib.box(Vector3(1.6, 0.16, 0.12), Vector3(0, 0.66, -2.16), dark, "Bumper"))
	root.add_child(MeshLib.box(Vector3(1.6, 0.16, 0.12), Vector3(0, 0.66, 2.16), dark, "BumperRear"))
	for axle in [-1.42, 1.42]:
		for side in [-1.0, 1.0]:
			var wheel := MeshLib.wheel(0.33, 0.22)
			wheel.position = Vector3(side * 0.86, 0.33, axle)
			root.add_child(wheel)
	return root


func setup(color := Color(0.75, 0.16, 0.16)) -> void:
	name = "OwnCar"
	var shell := Node3D.new()
	shell.name = "Shell"
	add_child(shell)
	var paint := MeshLib.paint(color)
	var dark := MeshLib.mat(Color(0.1, 0.11, 0.13), 0.6, 0.3)
	var glass := MeshLib.glass(Color(0.14, 0.18, 0.22), 0.5)
	shell.add_child(MeshLib.box(Vector3(1.78, 0.5, 4.3), Vector3(0, 0.62, 0), paint, "Hull"))
	shell.add_child(MeshLib.box(Vector3(1.7, 0.3, 1.2), Vector3(0, 0.95, -1.5), paint, "Hood"))
	shell.add_child(MeshLib.box(Vector3(1.7, 0.34, 1.0), Vector3(0, 0.97, 1.6), paint, "Trunk"))
	shell.add_child(MeshLib.box(Vector3(1.62, 0.62, 2.1), Vector3(0, 1.2, 0.1), paint, "Cabin"))
	shell.add_child(MeshLib.box(Vector3(1.5, 0.5, 0.08), Vector3(0, 1.22, -0.95), glass, "Windshield"))
	shell.add_child(MeshLib.box(Vector3(1.5, 0.46, 0.08), Vector3(0, 1.22, 1.15), glass, "RearGlass"))
	shell.add_child(MeshLib.box(Vector3(1.4, 0.06, 1.9), Vector3(0, 0.88, 0.1),
		MeshLib.mat(Color(0.14, 0.15, 0.18), 0.9), "Floor"))
	for side in [-1.0, 1.0]:
		shell.add_child(MeshLib.box(Vector3(0.06, 0.44, 1.9), Vector3(side * 0.82, 1.2, 0.1), glass, "SideGlass"))
		shell.add_child(MeshLib.box(Vector3(0.3, 0.18, 0.1), Vector3(side * 0.6, 0.86, -2.14),
			MeshLib.emissive(Color(1.0, 0.96, 0.86), 1.4), "Head"))
		var tail_mat := MeshLib.emissive(Color(0.9, 0.12, 0.1), 1.0)
		tail_materials.append(tail_mat)
		shell.add_child(MeshLib.box(Vector3(0.32, 0.16, 0.1), Vector3(side * 0.62, 0.9, 2.14), tail_mat, "Tail"))
		shell.add_child(MeshLib.box(Vector3(0.14, 0.1, 0.5), Vector3(side * 0.9, 1.26, -0.8), dark, "Mirror"))
		shell.add_child(MeshLib.box(Vector3(0.44, 0.5, 0.6), Vector3(side * 0.42, 1.0, 0.5),
			MeshLib.mat(Color(0.2, 0.22, 0.28), 0.9), "Seat"))
	shell.add_child(MeshLib.box(Vector3(1.6, 0.16, 0.12), Vector3(0, 0.66, -2.16), dark, "Bumper"))
	shell.add_child(MeshLib.box(Vector3(1.6, 0.16, 0.12), Vector3(0, 0.66, 2.16), dark, "BumperRear"))
	for axle in [-1.42, 1.42]:
		for side in [-1.0, 1.0]:
			var knuckle := Node3D.new()
			knuckle.position = Vector3(side * 0.86, 0.33, axle)
			var wheel := MeshLib.wheel(0.33, 0.22)
			knuckle.add_child(wheel)
			shell.add_child(knuckle)
			wheels.append(wheel)
			if axle < 0.0:
				knuckles.append(knuckle)


func place(pos: Vector3, heading: float) -> void:
	yaw = heading
	global_position = pos
	rotation.y = yaw


func drive(delta: float, throttle: float, brake: float, steer_input: float, grip: float) -> void:
	steer = move_toward(steer, steer_input, delta * 1.8)
	if throttle > 0.0:
		speed += ACCEL * grip * throttle * delta * (1.0 - clampf(speed / MAX_SPEED, 0.0, 0.9))
	if brake > 0.0:
		speed -= BRAKE * grip * brake * delta
		if speed < MAX_REVERSE:
			speed = MAX_REVERSE
	if throttle <= 0.0 and brake <= 0.0:
		speed = move_toward(speed, 0.0, DRAG * delta)
	speed = clampf(speed, MAX_REVERSE, MAX_SPEED)
	# Руль работает тем сильнее, чем быстрее едем, но на месте машина не крутится.
	var turn: float = steer * 1.1 * clampf(absf(speed) / 8.0, 0.0, 1.0) * signf(speed if absf(speed) > 0.01 else 1.0)
	yaw += turn * delta
	rotation.y = yaw
	# Капот модели смотрит в −Z, поэтому ход совпадает с носом, а не с багажником.
	var forward := Vector3(-sin(yaw), 0.0, -cos(yaw))
	global_position += forward * speed * delta
	spin += speed * delta / 0.33
	for wheel in wheels:
		(wheel as Node3D).rotation.x = spin
	for knuckle in knuckles:
		(knuckle as Node3D).rotation.y = steer * 0.5
	for mat in tail_materials:
		(mat as StandardMaterial3D).emission_energy_multiplier = 4.0 if brake > 0.0 else 1.0
	_tick_engine()


func _tick_engine() -> void:
	if engine == null:
		engine = AudioStreamPlayer3D.new()
		engine.stream = Sfx.car_clip()
		engine.unit_size = 5.0
		engine.max_distance = 24.0
		add_child(engine)
	var moving := clampf(absf(speed) / 14.0, 0.0, 1.0)
	engine.pitch_scale = lerpf(0.9, 1.55, moving)
	engine.volume_db = lerpf(-18.0, -8.0, moving)
	if not engine.playing:
		engine.play()


func silence() -> void:
	if engine != null:
		engine.stop()


func seat_position() -> Vector3:
	return to_global(Vector3(-0.42, 1.18, -0.2))


func door_position() -> Vector3:
	return to_global(Vector3(-1.5, 0.4, 0.2))
