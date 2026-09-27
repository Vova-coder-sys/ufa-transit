extends Node3D

const Road = preload("res://scripts/m5.gd")

const Depot = preload("res://scripts/company.gd")

# Уфа: транспорт. Главный узел — мир, смены, камеры, роли.

var hud: Hud
var camera: Camera3D
var sun: DirectionalLight3D
var world_env: WorldEnvironment
var env: Environment
var sky_material: ShaderMaterial
var rain: GPUParticles3D
var snow: GPUParticles3D
var network := {}
var city := {}
var world_root: Node3D
var traffic_root: Node3D

var save_data := {}
var state := {
	"screen": "menu",
	"role": "driver",
	"period": "day",
	"weather": "clear",
	"route_id": "tram-18",
	"model_id": "pesa",
	"quality": "high",
	"wallet": 500,
	"alga": false,
	"album": [],
	"best_rating": 0,
	"shifts": 0,
	"earned": 0,
	"rating": 80,
	"rating_log": [],
	"shift_cash": 0,
	"minutes": 480.0,
	"paused": false,
	"album_open": false,
	"summary": {},
	"small_bus": false,
	"camera": "chase",
	"board_phase": "",
	"wait_index": 0,
	"accident_lock": 0.0,
	"car": false,
	"sold": 0,
	"pocket": [],
	"in_car": false,
	"phone_open": false,
	"reviews": {},
	"achievements": [],
	"office_open": false,
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

var walk_pos := Vector3.ZERO
var walk_path := "prospekt"
var lost_tickets: Array = []
var parcels: Array = []
var errand := {}
var carry: Node3D = null
var lucky := {}
var step_gap := 0.6
var car: TownCar = null
var walker: Node3D = null

var fare := {"open": false, "mode": "", "tender": 0, "due": 0, "pieces": [], "person": null}
var fare_desk: Node3D = null
var fare_bodies: Array = []
var player: Vehicle = null
var traffic: Array = []
var riders: Array = []
var rider_timer := 0.0
var boarders: Array = []
var enter_t := 0.0
var enter_from := Vector3.ZERO
var walk := Vector3.ZERO
var wait_walk := Vector3.ZERO
var look_yaw := 0.0
var look_pitch := 0.0
var chase_pos := Vector3.ZERO
var menu_angle := 0.0
var mouse_captured := false
var shift_active := false
var evening_applied := false
var driver_stops := []
var timetable := []
var bell_time := 0.0
var shot_path := ""
var shot_menu := false
var shot_ride := false
var shot_fare := false
var shot_timer := -1.0
var bot := false
var bot_frames := 0
var bot_throttle := false
var bot_brake := false
var bot_doors := false
var bot_max_speed := 0.0
var bot_served := 0
var bot_phase := "run"
var bot_timer := 0.0
var bot_target := 2
var bot_fares := 0
var rng := RandomNumberGenerator.new()
var fleet_serial := {}
var lod_timer := 0.0
var drift_root: Node3D
var reverse_gear := false
var ic_board_until := -1.0
var ic_dwell_until := -1.0
var ic_dps_until := -1.0
var ic_jam_until := -1.0
var ic_broken := false
var ic_done := {}


func _ready() -> void:
	rng.randomize()
	save_data = SaveGame.load_data()
	for key in ["wallet", "alga", "album", "best_rating", "shifts", "earned", "quality", "car", "sold", "pocket", "reviews", "achievements", "company", "drivers", "fleet_owned", "pass_left", "concession", "modes", "open_routes", "last_profit", "ic_runs", "ic_earned"]:
		state[key] = save_data[key]

	world_root = Node3D.new()
	world_root.name = "World"
	add_child(world_root)
	traffic_root = Node3D.new()
	traffic_root.name = "Traffic"
	add_child(traffic_root)

	_setup_environment()
	network = Routes.build(world_root)
	city = City.build(world_root, network)

	camera = Camera3D.new()
	camera.fov = 72.0
	camera.far = 1600.0
	camera.near = 0.08
	camera.position = Vector3(0, 40, 120)
	add_child(camera)
	camera.current = true

	hud = Hud.new()
	add_child(hud)
	hud.action.connect(_on_action)
	_apply_quality()
	hud.show_menu(state, network["routes"])

	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--shot="):
			shot_path = arg.substr(7)
		elif arg.begins_with("--role="):
			state["role"] = arg.substr(7)
		elif arg.begins_with("--route="):
			state["route_id"] = arg.substr(8)
		elif arg.begins_with("--model="):
			state["model_id"] = arg.substr(8)
		elif arg.begins_with("--weather="):
			state["weather"] = arg.substr(10)
		elif arg.begins_with("--period="):
			state["period"] = arg.substr(9)
		elif arg.begins_with("--view="):
			state["camera"] = arg.substr(7)
		elif arg == "--menu":
			shot_menu = true
		elif arg == "--playtest":
			bot = true
		elif arg.begins_with("--stops="):
			bot_target = int(arg.substr(8))
		elif arg == "--ride":
			shot_ride = true
		elif arg == "--fare":
			shot_fare = true
	if shot_menu:
		hud.visible = false
	if shot_path != "":
		if not shot_menu:
			_start_shift()
		if shot_ride:
			_shot_board()
		if shot_fare:
			_shot_fare()
		shot_timer = 1.6
	if bot:
		_start_shift()
	elif shot_path == "":
		_show_splash()
	print("UFA_READY")


func _show_splash() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 120
	add_child(layer)
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.07, 0.11, 1)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(bg)
	var title := Label.new()
	title.text = "Уфа: транспорт\nСделано в Cursor"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.set_anchors_preset(Control.PRESET_FULL_RECT)
	title.add_theme_font_size_override("font_size", 42)
	title.add_theme_color_override("font_color", Color(0.96, 0.94, 0.88))
	layer.add_child(title)
	var timer := get_tree().create_timer(2.2)
	timer.timeout.connect(func() -> void:
		if is_instance_valid(layer):
			layer.queue_free())

func _setup_environment() -> void:
	sun = DirectionalLight3D.new()
	sun.name = "Sun"
	sun.light_energy = 1.15
	sun.shadow_enabled = true
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	sun.directional_shadow_max_distance = 320.0
	sun.directional_shadow_blend_splits = true
	sun.shadow_bias = 0.04
	sun.rotation_degrees = Vector3(-52, 38, 0)
	add_child(sun)

	env = Environment.new()
	env.background_mode = Environment.BG_SKY
	sky_material = MeshLib.sky_material()
	var sky := Sky.new()
	sky.sky_material = sky_material
	sky.radiance_size = Sky.RADIANCE_SIZE_128
	sky.process_mode = Sky.PROCESS_MODE_INCREMENTAL
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	# Небо стало насыщённо-синим, поэтому в тени подмешиваем нейтральный свет.
	env.ambient_light_sky_contribution = 0.32
	env.ambient_light_color = Color(0.9, 0.91, 0.93)
	env.ambient_light_energy = 0.72
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_white = 6.0
	env.tonemap_exposure = 0.88
	env.ssao_enabled = true
	env.ssao_intensity = 1.4
	env.ssr_enabled = false
	env.glow_enabled = true
	# Softlight по умолчанию заливает светом всю картинку: светящиеся окна
	# размазывались на стены. Аддитивный режим с порогом трогает только яркое.
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_ADDITIVE
	env.glow_hdr_threshold = 1.0
	env.glow_hdr_scale = 1.6
	env.glow_intensity = 0.28
	env.glow_strength = 0.9
	env.glow_bloom = 0.0
	env.adjustment_enabled = true
	env.adjustment_saturation = 1.06
	env.fog_enabled = true
	env.fog_light_color = Color(0.68, 0.74, 0.82)
	env.fog_density = 0.0009
	env.fog_sky_affect = 0.2
	world_env = WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)

	rain = _make_precipitation(true)
	snow = _make_precipitation(false)
	add_child(rain)
	add_child(snow)


func _make_precipitation(is_rain: bool) -> GPUParticles3D:
	var particles := GPUParticles3D.new()
	particles.amount = 1400 if is_rain else 800
	particles.lifetime = 1.6 if is_rain else 6.0
	particles.preprocess = 1.6 if is_rain else 6.0
	particles.visibility_aabb = AABB(Vector3(-46, -40, -46), Vector3(92, 70, 92))
	particles.emitting = false
	var mat := ParticleProcessMaterial.new()
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mat.emission_box_extents = Vector3(34, 6, 34)
	mat.direction = Vector3(0, -1, 0)
	mat.spread = 3.0
	mat.gravity = Vector3(0, -32 if is_rain else -3.2, 0)
	mat.initial_velocity_min = 12.0 if is_rain else 0.6
	mat.initial_velocity_max = 16.0 if is_rain else 1.4
	mat.scale_min = 0.6
	mat.scale_max = 1.0
	if not is_rain:
		mat.turbulence_enabled = true
		mat.turbulence_noise_strength = 1.4
		mat.turbulence_noise_scale = 2.0
	particles.process_material = mat
	var quad := QuadMesh.new()
	quad.size = Vector2(0.02, 0.5) if is_rain else Vector2(0.07, 0.07)
	var draw_mat := StandardMaterial3D.new()
	draw_mat.albedo_color = Color(0.72, 0.82, 0.95, 0.3) if is_rain else Color(1, 1, 1, 0.88)
	draw_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	draw_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	draw_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	draw_mat.billboard_keep_scale = true
	quad.material = draw_mat
	particles.draw_pass_1 = quad
	return particles


func _apply_quality() -> void:
	var high: bool = state["quality"] == "high"
	var vp := get_viewport()
	vp.msaa_3d = Viewport.MSAA_2X if high else Viewport.MSAA_DISABLED
	vp.screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA
	vp.use_taa = false
	# SDFGI и SSIL красили асфальт в цвет кузова и дорого считались.
	env.sdfgi_enabled = false
	env.ssil_enabled = false
	env.ssao_enabled = high
	env.ssao_radius = 1.4
	env.ssao_intensity = 0.8
	sun.directional_shadow_max_distance = 220.0 if high else 140.0


# --- смена --------------------------------------------------------------

func _current_route() -> Dictionary:
	return Routes.find_route(network["routes"], String(state["route_id"]))


func _route_open(route: Dictionary) -> bool:
	var cost := int(route.get("build", 0))
	if cost <= 0:
		return true
	return (state.get("open_routes", []) as Array).has(String(route["id"]))


func _ensure_route() -> void:
	var route := _current_route()
	if not _route_open(route):
		for candidate in network["routes"]:
			if _route_open(candidate):
				state["route_id"] = String(candidate["id"])
				state["model_id"] = String(candidate["models"][0])
				route = candidate
				break
	if state["period"] == "evening" and bool(route["evening_off"]):
		for candidate in network["routes"]:
			if not bool(candidate["evening_off"]) and _route_open(candidate):
				state["route_id"] = String(candidate["id"])
				state["model_id"] = String(candidate["models"][0])
				return
	if not (state["model_id"] in route["models"]):
		state["model_id"] = String(route["models"][0])


func _start_shift() -> void:
	_ensure_route()
	var route := _current_route()
	state["small_bus"] = Fleet.is_small(String(state["model_id"]))
	state["rating"] = 80
	state["rating_log"] = []
	state["shift_cash"] = 0
	state["paused"] = false
	state["summary"] = {}
	state["album_open"] = false
	state["board_phase"] = ""
	state["phone_open"] = false
	state["office_open"] = false
	lucky = {}
	state["accident_lock"] = 0.0
	state["camera"] = "cabin" if state["role"] == "conductor" else state.get("camera", "chase")
	state["minutes"] = 1140.0 if state["period"] == "evening" else 480.0
	evening_applied = state["period"] == "evening"
	fare = {"open": false, "mode": "", "tender": 0, "due": 0, "pieces": [], "person": null}
	walk = Vector3(0, 0, 0)
	wait_walk = Vector3.ZERO
	look_yaw = 0.0
	look_pitch = 0.0
	riders = []
	rider_timer = 0.0
	shift_active = true
	reverse_gear = false
	hud.set_reverse(false, state["role"] == "driver")
	state["screen"] = "play"

	_clear_world()
	_spawn_traffic()
	if state["role"] == "passenger":
		state["wait_index"] = _default_stop_index()
		state["in_car"] = false
		var start: Dictionary = city["stops"][int(state["wait_index"])]
		walk_pos = _snap_to_walkway(Vector3(start["pos"]) + Vector3(start["right"]) * (float(Routes.path_style()[start["path"]]["half"]) + 2.2))
		var face: Vector3 = start["forward"]
		look_yaw = atan2(face.x, -face.z)
		_spawn_lost_tickets()
		_spawn_parcels()
		if not bot:
			hud.toast("Подработка: берите посылку на остановке и несите на указанную")
		if walker == null:
			walker = City.make_person(Color(0.22, 0.36, 0.58))
			walker.name = "Walker"
			world_root.add_child(walker)
		walker.visible = true
		if bool(state["car"]):
			var half: float = float(Routes.path_style()[start["path"]]["half"])
			var spot: Vector3 = Vector3(start["pos"]) + Vector3(start["right"]) * (half + 7.5) + face * 8.0
			_spawn_car(spot, atan2(-face.x, -face.z))
		if not bot and shot_path == "":
			_capture_mouse()
	else:
		player = Vehicle.new()
		player.name = "Player"
		traffic_root.add_child(player)
		player.setup(route, String(state["model_id"]), true)
		player.assign_identity(_take_fleet(String(state["model_id"])))
		player.ai = false
		# Хвост не должен свисать за начало трассы: ставим машину целиком на дорогу.
		player.set_progress(route["m0"] + player.body_length + 4.0)
		player.free_heading = player.vehicle_type != "tram"
		player.sync_heading()
		player.update_pose()
		_clear_ahead_of_player()
		driver_stops = []
		for stop in player.stops():
			driver_stops.append({"near": false, "resolved": false})
		driver_stops[0]["resolved"] = true
		timetable = Rules.timetable(state["minutes"], _stop_offsets(), String(state["weather"]))
		_begin_intercity()
	hud.show_play()
	_update_hint()


func _default_stop_index() -> int:
	for i in city["stops"].size():
		var stop: Dictionary = city["stops"][i]
		if stop["path"] == "prospekt" and String(stop["name"]) == "Госцирк":
			return i
	return 0


func _clear_world() -> void:
	for vehicle in traffic:
		(vehicle as Vehicle).queue_free()
	traffic = []
	if player != null:
		player.queue_free()
		player = null
	for item in boarders:
		var node: Node = item["node"]
		if is_instance_valid(node):
			node.queue_free()
	boarders.clear()
	_clear_passenger_props()


func _take_fleet(model_id: String) -> int:
	var base := int(Fleet.spec(model_id).get("fleet", 1000))
	var n := int(fleet_serial.get(model_id, 0))
	fleet_serial[model_id] = n + 1
	return base + n


func _spawn_traffic() -> void:
	# Машины одной полосы расставляем с зазором, иначе на старте пробка.
	# На маршруте одновременно не больше traffic машин, и все они едут.
	fleet_serial = {}
	var busy := {}
	for route in network["routes"]:
		var count := Rules.traffic_count(route, String(state["period"]))
		for i in count:
			var model_id: String = String(route["models"][i % route["models"].size()])
			var vehicle := Vehicle.new()
			vehicle.name = "AI_%s_%d" % [route["id"], i]
			traffic_root.add_child(vehicle)
			vehicle.setup(route, model_id, false, 1)
			vehicle.assign_identity(_take_fleet(model_id))
			vehicle.dir = 1 if i % 2 == 0 else -1
			var key := "%s:%.1f:%d" % [route["path"], vehicle.lane, vehicle.dir]
			if not busy.has(key):
				busy[key] = []
			var taken: Array = busy[key]
			var m0: float = float(route["m0"])
			var m1: float = float(route["m1"])
			var pick: float = m0
			for attempt in 14:
				var candidate: float = rng.randf_range(m0 + 8.0, max(m0 + 9.0, m1 - 8.0))
				var free := true
				for other in taken:
					if absf(float(other) - candidate) < 52.0:
						free = false
						break
				pick = candidate
				if free:
					break
			taken.append(pick)
			vehicle.set_progress(pick)
			vehicle.speed = 4.0
			traffic.append(vehicle)


func _clear_ahead_of_player() -> void:
	if player == null:
		return
	for vehicle in traffic:
		var other: Vehicle = vehicle
		if other.curve != player.curve or absf(other.lane - player.lane) > 1.0:
			continue
		var ahead: float = (other.progress - player.progress) * float(player.dir)
		if ahead > -20.0 and ahead < 70.0:
			other.set_progress(min(other.m1, other.progress + 70.0 * float(player.dir)))


func _finish_shift() -> void:
	if not shift_active or not state["summary"].is_empty():
		return
	state["earned"] = int(state["earned"]) + max(0, int(state["shift_cash"]))
	state["shifts"] = int(state["shifts"]) + 1
	if state["role"] != "passenger":
		state["best_rating"] = max(int(state["best_rating"]), int(state["rating"]))
	_persist()
	state["summary"] = {
		"rating": state["rating"],
		"cash": state["shift_cash"],
		"wallet": state["wallet"],
		"log": state["rating_log"].duplicate(),
	}
	state["paused"] = true
	shift_active = false
	_release_mouse()
	hud.show_summary(state["summary"])


func _go_menu() -> void:
	_clear_world()
	shift_active = false
	state["screen"] = "menu"
	state["paused"] = false
	state["summary"] = {}
	state["album_open"] = false
	state["phone_open"] = false
	state["office_open"] = false
	lucky = {}
	fare["open"] = false
	_release_mouse()
	hud.hide_dock()
	hud.show_menu(state, network["routes"])


func _hire_driver() -> void:
	if not Depot.can_hire(int(state["drivers"])):
		hud.toast("В депо уже 4 водителя")
		return
	if int(state["wallet"]) < Depot.HIRE_COST:
		hud.toast("Наём: нужно %d ₽" % Depot.HIRE_COST)
		return
	state["wallet"] = int(state["wallet"]) - Depot.HIRE_COST
	state["drivers"] = int(state["drivers"]) + 1
	state["company"] = true
	_persist()
	_check_company_goals()
	hud.toast("Водитель нанят · %d из 4" % int(state["drivers"]))
	hud.show_menu(state, network["routes"])


func _buy_fleet(model_id: String) -> void:
	var cost := Depot.price_of(model_id)
	if cost <= 0:
		return
	if int(state["wallet"]) < cost:
		hud.toast("%s: нужно %d ₽" % [Fleet.title_of(model_id), cost])
		return
	state["wallet"] = int(state["wallet"]) - cost
	var owned: Array = state["fleet_owned"]
	owned.append(model_id)
	state["company"] = true
	_persist()
	_check_company_goals()
	hud.toast("В депо: %s" % Fleet.title_of(model_id))
	hud.show_menu(state, network["routes"])


func _build_route(route_id: String) -> void:
	var route := Routes.find_route(network["routes"], route_id)
	if route.is_empty() or String(route.get("id", "")) != route_id:
		return
	if _route_open(route):
		state["route_id"] = route_id
		state["model_id"] = String(route["models"][0])
		hud.show_menu(state, network["routes"])
		return
	var cost := int(route.get("build", 0))
	if int(state["wallet"]) < cost:
		hud.toast("Маршрут: нужно %d ₽" % cost)
		return
	state["wallet"] = int(state["wallet"]) - cost
	var opened: Array = state["open_routes"]
	opened.append(route_id)
	state["company"] = true
	state["route_id"] = route_id
	state["model_id"] = String(route["models"][0])
	_persist()
	_check_company_goals()
	hud.toast("Маршрут открыт: %s" % String(route["title"]))
	hud.show_menu(state, network["routes"])


func _buy_month() -> void:
	if int(state["wallet"]) < Rules.MONTH_PASS:
		hud.toast("Проездной: нужно %d ₽" % Rules.MONTH_PASS)
		return
	state["wallet"] = int(state["wallet"]) - Rules.MONTH_PASS
	state["pass_left"] = 12
	_persist()
	hud.toast("Месячный проездной на 12 смен")
	hud.show_menu(state, network["routes"])


func _ticket_price(route: Dictionary) -> int:
	if int(state.get("pass_left", 0)) > 0:
		return Rules.ride_price(route, "pass")
	if bool(state.get("concession", false)):
		return Rules.ride_price(route, "concession")
	return Rules.ride_price(route, "cash")


func _grant(id: String, title: String) -> void:
	var book: Array = state["achievements"]
	if book.has(id):
		return
	book.append(id)
	_persist()
	hud.toast("Достижение «%s»" % title)


func _check_company_goals() -> void:
	if int(state["wallet"]) >= 1000000:
		_grant("million", "МИЛЛИОНЕР")
	var owned: Array = state["fleet_owned"]
	if bool(state["company"]) and int(state["drivers"]) > 0 and owned.size() > 0:
		_grant("empire", "ИМПЕРИЯ")


func _persist() -> void:
	for key in SaveGame.defaults().keys():
		if state.has(key):
			save_data[key] = state[key]
	SaveGame.store(save_data)


func _score(code: String) -> void:
	if not (code in Rules.allowed_codes(String(state["role"]), bool(state["small_bus"]))):
		return
	var weight: Dictionary = Rules.WEIGHTS[code]
	state["rating"] = clampi(int(state["rating"]) + int(weight["delta"]), 0, 100)
	var entry := {
		"code": code,
		"delta": int(weight["delta"]),
		"label": String(weight["label"]),
		"clock": Rules.format_clock(float(state["minutes"])),
	}
	var log_list: Array = state["rating_log"]
	log_list.insert(0, entry)
	if log_list.size() > 12:
		log_list.resize(12)
	hud.toast("%s: %s%d" % [weight["label"], "+" if int(weight["delta"]) > 0 else "", int(weight["delta"])])


# --- ввод ---------------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and mouse_captured:
		look_yaw += event.relative.x * 0.0022
		look_pitch = clamp(look_pitch - event.relative.y * 0.002, -1.1, 1.1)
	if event is InputEventKey and event.pressed and not event.echo:
		var key: int = event.keycode
		if key == KEY_ESCAPE:
			if fare["open"]:
				var passenger_pay := String(fare.get("mode", "")) == "passenger"
				_close_fare()
				if passenger_pay:
					var riding := _host()
					if riding != null:
						_show_pay(riding)
			elif state["album_open"]:
				state["album_open"] = false
				hud.hide_modal()
			elif state["phone_open"]:
				_close_phone()
			elif state["office_open"]:
				_close_office()
			elif shift_active and state["summary"].is_empty():
				state["paused"] = not state["paused"]
				if state["paused"]:
					_release_mouse()
					hud.show_pause()
				else:
					hud.hide_modal()
		elif key == KEY_ALT:
			# Alt отпускает мышь, чтобы дотянуться до кнопок, и забирает обратно.
			if mouse_captured:
				_release_mouse()
			elif shift_active and not _modal_open():
				_capture_mouse()
		elif key == KEY_P and shift_active and not fare["open"] and state["summary"].is_empty():
			if state["phone_open"]:
				_close_phone()
			else:
				_open_phone()
		elif key == KEY_R and shift_active and state["role"] == "driver" and not _modal_open():
			_toggle_reverse()
		elif key == KEY_F and ic_broken:
			ic_broken = false
			hud.toast("Починили на месте. Едем дальше")
		elif key == KEY_C and shift_active and state["role"] != "conductor":
			state["camera"] = "chase" if state["camera"] == "cabin" else "cabin"
			if state["camera"] != "cabin":
				_release_mouse()
		elif fare["open"]:
			if key == KEY_ENTER or key == KEY_KP_ENTER:
				_confirm_fare()
			elif key == KEY_BACKSPACE:
				_on_action("undo", "")
			elif key >= KEY_1 and key <= KEY_9:
				var denoms := Money.denominations()
				var slot: int = key - KEY_1
				if slot < denoms.size():
					_on_action("piece", str(denoms[slot]))
	if event is InputEventMouseButton and event.pressed and shift_active and not _modal_open():
		var wants_look: bool = state["role"] == "passenger" or state["role"] == "conductor" or state["camera"] == "cabin"
		if wants_look and not mouse_captured:
			_capture_mouse()


func _modal_open() -> bool:
	return fare["open"] or state["paused"] or state["album_open"] or state["phone_open"] or state["office_open"] or not state["summary"].is_empty()


func _capture_mouse() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	mouse_captured = true


func _release_mouse() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	mouse_captured = false


func _on_action(name: String, arg: String) -> void:
	match name:
		"role":
			state["role"] = arg
		"period":
			state["period"] = arg
			_ensure_route()
		"weather":
			state["weather"] = arg
		"hire":
			_hire_driver()
		"buyFleet":
			_buy_fleet(arg)
		"buyPass":
			_buy_month()
		"buildRoute":
			_build_route(arg)
		"concession":
			state["concession"] = not bool(state["concession"])
			_persist()
		"reverse":
			_toggle_reverse()
		"quality":
			state["quality"] = arg
			_apply_quality()
			_persist()
		"route":
			state["route_id"] = arg
			state["model_id"] = String(_current_route()["models"][0])
		"model":
			state["model_id"] = arg
		"start":
			_start_shift()
			return
		"buy":
			_buy_alga()
		"buyCar":
			_buy_car()
			return
		"album":
			state["album_open"] = true
			hud.show_album(state["album"])
			_release_mouse()
			return
		"closeAlbum":
			state["album_open"] = false
			hud.hide_modal()
			if state["screen"] == "play" and state["paused"]:
				hud.show_pause()
			return
		"reset":
			var fresh := SaveGame.defaults()
			for key in fresh.keys():
				state[key] = fresh[key]
			_persist()
			hud.toast("Сохранение сброшено")
		"resume":
			state["paused"] = false
			hud.hide_modal()
			return
		"finish":
			_finish_shift()
			return
		"menu":
			_go_menu()
			return
		"quit":
			get_tree().quit()
			return
		"piece", "undo", "clearpieces":
			if name == "piece":
				_give_piece(int(arg))
			elif name == "undo":
				_take_back_piece()
			else:
				while fare["pieces"].size() > 0:
					_take_back_piece()
			if String(fare.get("mode", "")) == "passenger":
				hud.show_passenger_till(fare, _host_type())
			else:
				hud.show_fare(fare, _host_type())
			return
		"cancelPay":
			_close_fare()
			var riding_back := _host()
			if riding_back != null and String(state["board_phase"]) == "pay":
				_show_pay(riding_back)
			return
		"confirm":
			_confirm_fare()
			return
		"stop":
			state["wait_index"] = int(arg)
			return
		"board":
			_board(arg)
			return
		"payCash":
			_pay_ride("cash")
			return
		"payAlga":
			_pay_ride("alga")
			return
		"payTicket":
			_pay_ride("ticket")
			return
		"buyPass":
			_buy_pass(arg)
			return
		"closeOffice":
			_close_office()
			return
		"phone":
			_open_phone()
			return
		"takeJob":
			_take_parcel(int(arg))
			return
		"dropJob":
			_finish_delivery()
			return
		"closePhone":
			_close_phone()
			return
		"rate":
			var bits := arg.split(":")
			if bits.size() == 2:
				var book: Dictionary = state["reviews"]
				book[bits[0]] = int(bits[1])
				state["reviews"] = book
				_persist()
				hud.toast("Отзыв № %s · %d из 5" % [bits[0], int(bits[1])])
				hud.show_phone(_phone_rows())
			return
		"leave", "alight":
			var riding := _host()
			if riding != null:
				_alight(riding)
			else:
				state["board_phase"] = ""
				state["camera"] = "chase"
				hud.hide_modal()
				hud.hide_dock()
			return
	if state["screen"] == "menu":
		hud.show_menu(state, network["routes"])


func _buy_alga() -> void:
	if bool(state["alga"]):
		hud.toast("Карта «Алга» уже куплена")
		return
	if int(state["wallet"]) < Rules.ALGA_PRICE:
		hud.toast("Нужно 300 ₽")
		return
	state["wallet"] = int(state["wallet"]) - Rules.ALGA_PRICE
	state["alga"] = true
	_persist()
	hud.toast("Карта «Алга» в кармане")


# --- оплата -------------------------------------------------------------

func _host() -> Vehicle:
	if state["role"] == "passenger":
		for vehicle in traffic:
			if (vehicle as Vehicle).name == String(state.get("boarded", "")):
				return vehicle
		return null
	return player


func _host_type() -> String:
	var host := _host()
	return host.vehicle_type if host != null else "bus"


func _roll_tender():
	var r := rng.randf()
	if r < 0.28:
		return "alga"
	if r < 0.68:
		return 50
	if r < 0.9:
		return 100
	if r < 0.97:
		return 200
	return 500


func _open_fare(person) -> void:
	if fare["open"] or player == null:
		return
	var tender = person["tender"] if typeof(person) == TYPE_DICTIONARY else _roll_tender()
	fare = {
		"open": true,
		"tender": tender,
		"due": _ticket_price(player.route),
		"pieces": [],
		"person": person,
	}
	_release_mouse()
	if not bot:
		_build_fare_desk()
	hud.show_fare(fare, player.vehicle_type)


# Лоток и касса перед кондуктором: сдачу набирают настоящими монетами и
# купюрами, каждая — отдельное физическое тело.
func _build_fare_desk() -> void:
	_drop_fare_desk()
	fare_desk = Node3D.new()
	fare_desk.name = "FareDesk"
	add_child(fare_desk)
	var forward: Vector3 = -camera.global_transform.basis.z
	forward.y = 0.0
	if forward.length() < 0.01:
		forward = Vector3(0, 0, -1)
	forward = forward.normalized()
	fare_desk.global_position = camera.global_position + forward * 0.52 + Vector3(0, -0.32, 0)
	fare_desk.rotation.y = atan2(forward.x, forward.z)

	fare_desk.add_child(Money.tray())
	var drawer := Money.drawer([10, 50, 100, 200])
	drawer.position = Vector3(-0.02, 0.0, 0.2)
	fare_desk.add_child(drawer)

	var lamp := OmniLight3D.new()
	lamp.light_energy = 0.45
	lamp.omni_range = 2.4
	lamp.position = Vector3(0, 0.34, 0.12)
	lamp.shadow_enabled = false
	fare_desk.add_child(lamp)

	var tender = fare["tender"]
	var passenger_pay := String(fare.get("mode", "")) == "passenger"
	if not passenger_pay and Rules.is_card(tender):
		var card := MeshLib.box(Vector3(0.086, 0.002, 0.054), Vector3.ZERO,
			MeshLib.mat(Color(0.12, 0.46, 0.7), 0.5, 0.2), "Alga")
		var holder := Node3D.new()
		holder.position = Vector3(0.0, 0.01, -0.05)
		holder.rotation.y = 0.2
		holder.add_child(card)
		var tag := MeshLib.label("АЛГА", 40, Color(0.95, 0.97, 1.0))
		tag.pixel_size = 0.00035
		tag.position = Vector3(-0.005, 0.002, 0.0)
		tag.rotation_degrees = Vector3(-90, 0, 0)
		holder.add_child(tag)
		fare_desk.add_child(holder)
	elif not passenger_pay:
		# Пассажир кладёт свою купюру в дальний край лотка.
		var body := Money.piece(int(tender))
		fare_desk.add_child(body)
		body.position = Vector3(rng.randf_range(-0.02, 0.02), 0.05, -0.075)
		body.rotation.y = rng.randf_range(-0.3, 0.3)
		body.set_meta("tender", true)

	# Кондуктор на время расчёта смотрит в лоток сверху: борта не заслоняют мелочь.
	var toward_me: Vector3 = -fare_desk.global_transform.basis.z
	camera.global_position = fare_desk.global_position + Vector3(0, 0.42, 0) + toward_me * 0.24
	camera.look_at(fare_desk.global_position + Vector3(0, 0.02, 0), Vector3.UP)


func _drop_fare_desk() -> void:
	fare_bodies.clear()
	if fare_desk != null and is_instance_valid(fare_desk):
		fare_desk.queue_free()
	fare_desk = null


func _give_piece(value: int) -> void:
	if String(fare.get("mode", "")) == "passenger":
		if fare["pieces"].size() >= 12:
			hud.toast("В лотке больше не помещается")
			return
		var held := 0
		for piece in fare["pieces"]:
			held += int(piece)
		if int(state["wallet"]) < held + value:
			hud.toast("В кошельке %d ₽" % int(state["wallet"]))
			return
	fare["pieces"].append(value)
	var pay_clip := Sfx.coin_clip() if Money.is_coin(value) else Sfx.paper_clip()
	Sfx.play(self, pay_clip, -9.0, rng.randf_range(0.94, 1.06))
	if fare_desk == null:
		return
	var body := Money.piece(value)
	fare_desk.add_child(body)
	# Купюры кладём стопкой слева, монеты раскладываем сеткой справа: если
	# сыпать всё в одну точку, тела расталкивают друг друга через бортик.
	var coins := 0
	var notes := 0
	for other in fare_bodies:
		if Money.is_coin(int((other as Node).get_meta("value", 0))):
			coins += 1
		else:
			notes += 1
	if Money.is_coin(value):
		body.position = Vector3(0.055 + 0.045 * float(coins % 3), 0.03 + 0.012 * float(coins / 9),
			0.0 + 0.05 * float((coins / 3) % 3))
	else:
		# Купюры разносим по высоте: если положить их вплотную, решатель
		# выталкивает тонкие тела сквозь дно лотка.
		body.position = Vector3(-0.085 + 0.004 * float(notes), 0.035 + 0.02 * float(notes),
			0.015 + 0.004 * float(notes))
	body.rotation.y = rng.randf_range(-0.12, 0.12)
	fare_bodies.append(body)


func _take_back_piece() -> void:
	if fare["pieces"].size() > 0:
		fare["pieces"].pop_back()
	if fare_bodies.size() > 0:
		var body: Node = fare_bodies.pop_back()
		if is_instance_valid(body):
			body.queue_free()


func _close_fare() -> void:
	var person = fare["person"]
	if typeof(person) == TYPE_DICTIONARY and person.has("node"):
		var node: Node3D = person["node"]
		if is_instance_valid(node):
			node.queue_free()
		riders.erase(person)
	fare = {"open": false, "mode": "", "tender": 0, "due": 0, "pieces": [], "person": null}
	_drop_fare_desk()
	hud.hide_modal()


func _confirm_fare() -> void:
	if not fare["open"]:
		return
	if String(fare.get("mode", "")) == "passenger":
		_confirm_passenger_fare()
		return
	if player == null:
		return
	var sum := 0
	for piece in fare["pieces"]:
		sum += int(piece)
	var ok := false
	var card_pay := Rules.is_card(fare["tender"])
	if card_pay:
		ok = fare["pieces"].is_empty()
	else:
		ok = sum == int(fare["tender"]) - int(fare["due"])
	if ok:
		_credit_fare(int(fare["due"]))
		_score("fareOk")
		var stop_name := "салон"
		if player != null:
			stop_name = String(player.next_stop().get("name", "салон"))
		var data := _add_ticket(player, int(fare["due"]), "alga" if card_pay else "cash", stop_name,
			0 if card_pay else int(fare["tender"]), sum)
		hud.show_receipt(data)
	else:
		_score("fareBad")
		if not card_pay and sum > int(fare["tender"]) - int(fare["due"]):
			_credit_fare(-(sum - (int(fare["tender"]) - int(fare["due"]))))
	_close_fare()


func _credit_fare(amount: int) -> void:
	state["shift_cash"] = int(state["shift_cash"]) + amount
	state["wallet"] = int(state["wallet"]) + amount
	_persist()


func _add_ticket(vehicle: Vehicle, price: int, method: String, stop_name: String,
		tender := 0, change := 0) -> Dictionary:
	var data := TicketArt.make(vehicle.title, vehicle.vehicle_type, String(vehicle.route["number"]),
		String(vehicle.route.get("operator", "Башавтотранс")), stop_name,
		Rules.format_clock(float(state["minutes"])), price, method,
		tender if tender > 0 else price, change, rng)
	var album: Array = state["album"]
	album.append(data)
	_persist()
	Sfx.play(self, Sfx.beep_clip(), -8.0)
	return data


func _start_enter(v: Vehicle) -> void:
	state["board_phase"] = "entering"
	state["boarded"] = v.name
	enter_t = 0.0
	enter_from = walk_pos
	var pts: Dictionary = v.curb_points()
	var to_door: Vector3 = pts["out"] - walk_pos
	if to_door.length() > 0.2:
		look_yaw = atan2(to_door.x, -to_door.z)


func _tick_enter(delta: float) -> void:
	var host := _host()
	if host == null or not host.doors_open:
		state["board_phase"] = ""
		state["boarded"] = ""
		return
	var pts: Dictionary = host.curb_points()
	enter_t += delta
	var to_door: Vector3 = pts["out"] - walk_pos
	if to_door.length() > 0.2:
		look_yaw = atan2(to_door.x, -to_door.z)
	if enter_t < 1.2:
		walk_pos = enter_from.lerp(pts["out"], enter_t / 1.2)
		walk_pos.y = pts["out"].y
	elif enter_t < 2.15:
		walk_pos = pts["out"].lerp(pts["in"], (enter_t - 1.2) / 0.95)
	else:
		_board(host.name)


# У открытой двери видно, как люди выходят на тротуар и заходят в салон.
func _run_boarding(delta: float) -> void:
	var coats := [Color(0.2, 0.28, 0.42), Color(0.45, 0.22, 0.2), Color(0.25, 0.32, 0.22), Color(0.35, 0.28, 0.4)]
	var riding: Array = traffic.duplicate()
	if player != null and state["role"] == "driver":
		riding.append(player)
	for vehicle in riding:
		var v: Vehicle = vehicle
		var cool: float = float(v.get_meta("board_cool", 0.0)) - delta
		v.set_meta("board_cool", max(0.0, cool))
		if not v.doors_open or v.speed > 1.15 or cool > 0.0:
			continue
		var pts: Dictionary = v.curb_points()
		var door: Vector3 = pts["out"]
		var at_stop := false
		for stop in city["stops"]:
			var stop_pos: Vector3 = stop["pos"]
			if Vector2(stop_pos.x, stop_pos.z).distance_to(Vector2(door.x, door.z)) < 22.0:
				at_stop = true
				break
		if not at_stop:
			continue
		var frame: Dictionary = v.road_frame(v.progress)
		var right: Vector3 = frame["right"]
		var forward: Vector3 = frame["forward"]
		var leaving: bool = bool(v.get_meta("board_flip", false))
		v.set_meta("board_flip", not leaving)
		var person := City.make_person(coats[rng.randi() % coats.size()])
		world_root.add_child(person)
		var sidewalk: Vector3 = door + right * 2.6 + forward * rng.randf_range(-1.2, 1.2)
		sidewalk.y = door.y
		if leaving:
			person.global_position = pts["in"]
			boarders.append({"node": person, "vehicle": v, "t": 0.0, "from": pts["in"], "mid": door, "to": sidewalk, "out": true})
		else:
			person.global_position = sidewalk
			boarders.append({"node": person, "vehicle": v, "t": 0.0, "from": sidewalk, "mid": door, "to": pts["in"], "out": false})
		v.set_meta("board_cool", 2.8)
	var left: Array = []
	for item in boarders:
		var node: Node3D = item["node"]
		var v: Vehicle = item["vehicle"]
		if not is_instance_valid(node) or not is_instance_valid(v):
			if is_instance_valid(node):
				node.queue_free()
			continue
		item["t"] = float(item["t"]) + delta
		var t: float = float(item["t"])
		var from: Vector3 = item["from"]
		var mid: Vector3 = item["mid"]
		var to: Vector3 = item["to"]
		# Дверь уехала вместе с машиной: середина и салон берутся заново.
		var live: Dictionary = v.curb_points()
		if bool(item["out"]):
			from = live["in"]
			mid = live["out"]
		else:
			mid = live["out"]
			to = live["in"]
		var pos: Vector3
		if t < 1.15:
			pos = from.lerp(mid, t / 1.15)
		elif t < 2.2:
			pos = mid.lerp(to, (t - 1.15) / 1.05)
		else:
			node.queue_free()
			continue
		pos.y += sin(t * 9.0) * 0.03
		node.global_position = pos
		var step: Vector3 = (mid if t < 1.15 else to) - pos
		if step.length() > 0.05:
			node.rotation.y = atan2(step.x, step.z)
		left.append(item)
	boarders = left


func _board(vehicle_name: String) -> void:
	for vehicle in traffic:
		var v: Vehicle = vehicle
		if v.name == vehicle_name:
			v.upgrade_interior()
			state["boarded"] = vehicle_name
			state["board_phase"] = "pay"
			state["camera"] = "cabin"
			walk = Vector3(0.2, 0, v.salon_span() * 0.4)
			look_yaw = 0.0
			look_pitch = 0.0
			_release_mouse()
			_show_pay(v)
			return


func _show_pay(vehicle: Vehicle) -> void:
	var price := _ticket_price(vehicle.route)
	var label := ""
	var ticket := _peek_ticket(vehicle)
	if not ticket.is_empty():
		var kind := "найденному" if bool(ticket.get("found", false)) else "купленному"
		label = "По %s билету %s" % [kind, String(ticket["route"])]
	hud.show_ride_pay(vehicle, bool(state["alga"]) and not bool(vehicle.route.get("intercity", false)), price, label)


func _peek_ticket(vehicle: Vehicle) -> Dictionary:
	for item in state["pocket"]:
		var ticket: Dictionary = item
		if String(ticket.get("route", "")) == String(vehicle.route["number"]) and String(ticket.get("type", "")) == vehicle.vehicle_type:
			return ticket
	return {}


func _take_ticket(vehicle: Vehicle) -> Dictionary:
	var pocket: Array = state["pocket"]
	for i in pocket.size():
		var ticket: Dictionary = pocket[i]
		if String(ticket.get("route", "")) == String(vehicle.route["number"]) and String(ticket.get("type", "")) == vehicle.vehicle_type:
			pocket.remove_at(i)
			return ticket
	return {}


func _pay_ride(method: String) -> void:
	var host := _host()
	if host == null:
		return
	if method == "ticket":
		var used := _take_ticket(host)
		if used.is_empty():
			hud.toast("Нет билета на этот маршрут")
			return
		if bool(used.get("found", false)):
			lucky = {"from": host.progress, "route": String(host.route["number"])}
			hud.toast("Билет подошёл. Проедьте остановку — «Счастливый билет» и 200 ₽")
		else:
			hud.toast("Билет из кассы, маршрут %s" % String(host.route["number"]))
		state["board_phase"] = "ride"
		state["camera"] = "cabin"
		hud.hide_modal()
		_capture_mouse()
		_persist()
		return
	if method == "cash" and not bot:
		_open_passenger_till()
		return
	if method == "alga" and not bool(state["alga"]):
		hud.toast("Сначала купите карту «Алга»")
		return
	var due := _ticket_price(host.route)
	if int(state["wallet"]) < due:
		hud.toast("Не хватает денег")
		return
	state["wallet"] = int(state["wallet"]) - due
	var stop_name: String = String(city["stops"][int(state["wait_index"])]["name"])
	# Пассажир платит купюрой и получает сдачу: номинал подбираем не меньше цены.
	var tender := due
	for note in Money.NOTE_VALUES:
		if int(note) >= due:
			tender = int(note)
			break
	if method == "alga":
		tender = due
	var data := _add_ticket(host, due, method, stop_name, tender, tender - due)
	state["board_phase"] = "ride"
	state["camera"] = "cabin"
	hud.hide_modal()
	hud.show_receipt(data)
	if not bot:
		_show_hand_receipt(data)


# Чек в руке: печатный билет, который пассажир держит после оплаты.
func _show_hand_receipt(data: Dictionary) -> void:
	var paper := TicketArt.paper(data)
	add_child(paper)
	var forward: Vector3 = -camera.global_transform.basis.z
	paper.global_position = camera.global_position + forward * 0.5 + Vector3(0, -0.22, 0)
	paper.rotation.y = atan2(forward.x, forward.z)
	paper.rotation.x = -0.9
	var timer := get_tree().create_timer(5.0)
	timer.timeout.connect(func():
		if is_instance_valid(paper):
			paper.queue_free())


# --- цикл ---------------------------------------------------------------

func _process(delta: float) -> void:
	delta = min(delta, 0.05)
	if bot:
		delta = 1.0 / 30.0
		_bot_step()
	var running: bool = shift_active and not _modal_open()
	if running:
		state["minutes"] = float(state["minutes"]) + delta * Rules.MINUTES_PER_SECOND
		state["accident_lock"] = max(0.0, float(state["accident_lock"]) - delta)
		_check_evening()
		_update_lead_gaps()
		for vehicle in traffic:
			(vehicle as Vehicle).update_ai(delta, String(state["weather"]))
		if player != null:
			if state["role"] == "driver":
				_drive(delta)
			else:
				player.update_ai(delta, String(state["weather"]))
				_conductor(delta)
		lod_timer += delta
		if lod_timer > 0.5 and camera != null:
			lod_timer = 0.0
			var cam := camera.global_position
			if player != null:
				player.consider_lod(cam, true)
			for vehicle in traffic:
				(vehicle as Vehicle).consider_lod(cam, false)
		elif state["role"] == "passenger" and not bot:
			_passenger(delta)
		if state["role"] == "passenger":
			_sync_walker()
		_run_boarding(delta)
	var hour := fmod(float(state["minutes"]), 1440.0) / 60.0
	Road.tick(delta, String(state["period"]) == "evening" or hour >= 21.0 or hour < 6.0)
	_update_sky()
	_update_weather()
	_update_camera(delta)
	if state["screen"] == "play":
		_update_hud(delta)
	if shot_timer > 0.0:
		shot_timer -= delta
		if shot_timer <= 0.0:
			_take_shot()


func _update_lead_gaps() -> void:
	# ИИ держит дистанцию до машины впереди в своей полосе, в том числе до игрока.
	var all := traffic.duplicate()
	if player != null:
		all.append(player)
	for vehicle in all:
		var self_v: Vehicle = vehicle
		var gap := 999.0
		for other_node in all:
			var other: Vehicle = other_node
			if other == self_v or other.curve != self_v.curve or other.dir != self_v.dir:
				continue
			if absf(other.lane - self_v.lane) > 1.0:
				continue
			var ahead: float = (other.progress - self_v.progress) * float(self_v.dir)
			if ahead <= 0.0:
				continue
			gap = min(gap, ahead - (other.body_length + self_v.body_length) * 0.5)
		self_v.lead_gap = max(0.0, gap)


func _check_evening() -> void:
	if evening_applied:
		return
	if Rules.period_of(float(state["minutes"])) != "evening":
		return
	evening_applied = true
	var keep := {}
	for route in network["routes"]:
		var allowed := Rules.traffic_count(route, "evening")
		var mine := []
		for vehicle in traffic:
			if (vehicle as Vehicle).route["id"] == route["id"]:
				mine.append(vehicle)
		for i in min(allowed, mine.size()):
			keep[mine[i]] = true
	var rest := []
	for vehicle in traffic:
		if keep.has(vehicle):
			rest.append(vehicle)
		else:
			(vehicle as Vehicle).queue_free()
	traffic = rest
	hud.toast("Вечернее расписание: часть машин ушла в парк")


func _intercity() -> bool:
	return player != null and bool(player.route.get("intercity", false)) and String(state["role"]) == "driver"


func _begin_intercity() -> void:
	ic_board_until = -1.0
	ic_dwell_until = -1.0
	ic_dps_until = -1.0
	ic_jam_until = -1.0
	ic_broken = false
	ic_done = {}
	if not _intercity():
		return
	ic_board_until = float(state["minutes"]) + 10.0
	player.doors_open = true
	var night := String(state["period"]) == "evening"
	Road.board(player, night, rng)
	hud.toast("Посадка 10 мин · %d пассажиров · билет %d ₽" % [Road.PAX, Road.FARE])
	if night:
		hud.toast("Ночной рейс: фары включены, пассажиры спят")
	elif String(state["weather"]) == "rain":
		hud.toast("Дождь на М-5: тормозной путь длиннее")
	elif String(state["weather"]) == "snow":
		hud.toast("Снег: медленнее, на обочине сугробы")
	elif String(state["weather"]) == "fog":
		hud.toast("Туман: видимость около 100 м")


func _ic_events() -> void:
	if not _intercity():
		return
	var now := float(state["minutes"])
	var km := Road.km_of(player.progress, player.m0, player.m1)
	if ic_board_until > 0.0 and now >= ic_board_until and not ic_done.has("depart"):
		ic_done["depart"] = true
		player.doors_open = false
		hud.toast("Кондуктор: отправляемся, Уфа — Стерлитамак")
	if km > 30.0 and not ic_done.has("dps"):
		ic_done["dps"] = true
		ic_dps_until = now + 3.5
		player.speed = 0.0
		hud.toast("ДПС остановил. Проверка документов")
	if km > 48.0 and not ic_done.has("jam"):
		ic_done["jam"] = true
		ic_jam_until = now + 8.0
		hud.toast("Пробка на М-5, едем медленно")
	if km > 68.0 and not ic_done.has("sick"):
		ic_done["sick"] = true
		hud.toast("Пассажиру плохо. Остановитесь и откройте двери")
	if ic_done.has("sick") and not ic_done.has("sick_ok") and player.doors_open and player.speed < 0.8:
		ic_done["sick_ok"] = true
		hud.toast("Стоим. Пассажиру легче, можно ехать")
	if km > 36.0 and not ic_done.has("break_roll"):
		ic_done["break_roll"] = true
		if rng.randf() < 0.45:
			ic_broken = true
			player.speed = 0.0
			hud.toast("Поломка. Остановитесь и нажмите F")


func _settle_intercity() -> void:
	var income := Road.PAX * Road.FARE
	var expense := Road.FUEL + Road.CONDUCTOR_PAY
	var profit := income - expense
	state["wallet"] = maxi(0, int(state["wallet"]) + profit)
	state["shift_cash"] = int(state["shift_cash"]) + income
	state["ic_earned"] = int(state["ic_earned"]) + profit
	state["ic_runs"] = int(state["ic_runs"]) + 1
	state["last_profit"] = profit
	var runs := int(state["ic_runs"])
	var earned := int(state["ic_earned"])
	hud.toast("40×500 − топливо %d − кондуктор %d = %d ₽ · рейс %d" % [Road.FUEL, Road.CONDUCTOR_PAY, profit, runs])
	_grant("ic_first", "ПЕРВЫЙ РЕЙС")
	if runs >= 10:
		_grant("ic_10", "ОПЫТНЫЙ")
	if runs >= 50:
		_grant("ic_50", "ДАЛЬНОБОЙЩИК")
	if runs >= 100:
		_grant("ic_100", "ЛЕГЕНДА ТРАССЫ")
	var hour := fmod(float(state["minutes"]), 1440.0) / 60.0
	if String(state["period"]) == "evening" or hour >= 21.0 or hour < 6.0:
		_grant("ic_night", "НОЧНОЙ РЕЙС")
	if String(state["weather"]) == "snow":
		_grant("ic_winter", "ЗИМНИЙ РЕЙС")
	if earned >= 1000000:
		_grant("ic_million", "МИЛЛИОНЕР")
	_persist()


func _ic_holding() -> bool:
	if not _intercity():
		return false
	var now := float(state["minutes"])
	return now < ic_board_until or now < ic_dwell_until or now < ic_dps_until or ic_broken


func _toggle_reverse() -> void:
	if player == null or String(state["role"]) != "driver" or not shift_active:
		return
	if player.speed > 1.1:
		hud.toast("Задний ход: сначала остановитесь")
		return
	reverse_gear = not reverse_gear
	hud.set_reverse(reverse_gear, true)
	hud.toast("Задний ход" if reverse_gear else "Передний ход")


func _drive(delta: float) -> void:
	var weather := String(state["weather"])
	var kind := player.vehicle_type
	_ic_events()
	var throttle: bool = bot_throttle if bot else (Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP))
	var brake: bool = bot_brake if bot else (Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN))
	if _ic_holding():
		throttle = false
	var speed := player.speed
	var cap := 4.2 if reverse_gear else Rules.speed_cap(kind, weather)
	if float(state["minutes"]) < ic_jam_until:
		cap = minf(cap, 3.0)
	var km_now := Road.km_of(player.progress, player.m0, player.m1) if _intercity() else -1.0
	if absf(km_now - 24.0) < 2.0 or absf(km_now - 82.0) < 2.0:
		cap *= 0.75
	if player.doors_open:
		speed = max(0.0, speed - Rules.brake_power(kind, weather) * delta * 1.5)
	elif brake:
		speed = max(0.0, speed - Rules.brake_power(kind, weather) * delta)
	elif throttle:
		speed = min(cap, speed + Rules.accel_power(kind, weather) * delta)
	else:
		speed = max(0.0, speed - 0.6 * delta)
	if ic_broken or float(state["minutes"]) < ic_dps_until:
		speed = 0.0

	# Занос ловит только тех, кто оттормаживается с большой скорости по скользкому.
	var skid_speed: float = 6.0 + 8.0 * Rules.grip_for(kind, weather)
	if kind != "tram" and brake and speed > skid_speed:
		player.set_meta("slip", float(player.get_meta("slip", 0.0)) + delta)
		if float(player.get_meta("slip", 0.0)) > 1.2 and float(state["accident_lock"]) <= 0.0:
			_score("accident")
			speed *= 0.25
			player.set_meta("slip", 0.0)
			state["accident_lock"] = 4.0
	else:
		player.set_meta("slip", max(0.0, float(player.get_meta("slip", 0.0)) - delta))

	player.speed = speed
	player.reversing = reverse_gear
	player.braking = brake or player.doors_open
	var travel := -speed if reverse_gear else speed
	_steer(delta, travel, kind, weather)
	if player.free_heading:
		player.progress += travel * delta * float(player.get_meta("along", 1.0))
	else:
		player.progress += travel * delta * float(player.dir)
	var hit_end := false
	if player.progress >= player.m1:
		player.progress = player.m1
		hit_end = true
	elif player.progress <= player.m0:
		player.progress = player.m0
		hit_end = true
	if absf(player.progress - player.m0) > 12.0 and absf(player.progress - player.m1) > 12.0:
		player.set_meta("left", true)

	var door_key: bool = bot_doors if bot else Input.is_key_pressed(KEY_E)
	if door_key:
		if not bool(player.get_meta("e_latch", false)) and speed < 0.8:
			player.doors_open = not player.doors_open
			player.set_meta("e_latch", true)
			player.set_meta("door_penalty", false)
	else:
		player.set_meta("e_latch", false)
	if player.doors_open and speed > 1.3 and not bool(player.get_meta("door_penalty", false)):
		_score("doors")
		player.set_meta("door_penalty", true)

	if Input.is_key_pressed(KEY_SPACE) and Time.get_ticks_msec() / 1000.0 - bell_time > 0.6:
		bell_time = Time.get_ticks_msec() / 1000.0
		hud.toast("Звонок")
		Sfx.burst(player, Sfx.bell_clip(), -5.0)

	_check_driver_stops(speed)
	_check_collision()

	if hit_end and speed < 0.5 and bool(player.get_meta("left", false)) and not bool(player.get_meta("finish_latch", false)):
		_score("finish")
		player.set_meta("finish_latch", true)
		_grant("first_run", "ПЕРВЫЙ РЕЙС")
		if String(state["weather"]) == "rain":
			_grant("rain_run", "РЕЙС В ЛИВЕНЬ")
		if String(state["weather"]) == "snow":
			_grant("winter", "ЗИМНИЙ МАРАФОН")
		var modes: Array = state["modes"]
		if not modes.has(player.vehicle_type):
			modes.append(player.vehicle_type)
		if modes.has("bus") and modes.has("tram") and modes.has("trolley"):
			_grant("all_modes", "ВСЕ ВИДЫ ТРАНСПОРТА")
		if _intercity():
			_settle_intercity()
		else:
			var fare_in := int(state["shift_cash"])
			var npc := int(state["drivers"]) * Depot.ROUTE_INCOME
			var expense := int(state["drivers"]) * Depot.WAGE + Depot.FUEL
			var profit := fare_in + npc - expense
			state["wallet"] = maxi(0, int(state["wallet"]) + npc - expense)
			state["last_profit"] = profit
			hud.toast("Доход %d · расход %d · прибыль %d ₽" % [fare_in + npc, expense, profit])
		if int(state["pass_left"]) > 0:
			state["pass_left"] = int(state["pass_left"]) - 1
		_check_company_goals()
		_persist()
		player.dir *= -1
		if player.free_heading:
			player.sync_heading()
		player.set_meta("left", false)
		driver_stops = []
		for stop in player.stops():
			driver_stops.append({"near": false, "resolved": false})
		var at_end: int = player.stops().size() - 1 if player.progress >= player.m1 - 0.5 else 0
		driver_stops[at_end]["resolved"] = true
		timetable = Rules.timetable(float(state["minutes"]), _stop_offsets(), String(state["weather"]))
		player.set_meta("served", {})
	if not hit_end:
		player.set_meta("finish_latch", false)
	player.animate(delta)


func _steer(delta: float, speed: float, kind: String, weather: String) -> void:
	if kind == "tram":
		return
	var input := 0.0
	if bot:
		input = _bot_steer()
	else:
		if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
			input -= 1.0
		if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
			input += 1.0
	player.steer = move_toward(player.steer, input, delta * 1.9)
	var grip: float = Rules.grip_for(kind, weather)
	# Середина между первым острым рулём и слишком мягким.
	var yaw_rate: float = -player.steer * speed * 0.033 * grip
	player.heading += yaw_rate * delta
	player.trail_heading = lerp_angle(player.trail_heading, player.heading, clampf(delta * 1.4, 0.0, 1.0))
	player.steer_rate = yaw_rate
	var frame: Dictionary = player.road_frame(player.progress)
	var nose: Vector3 = Vehicle.nose_from_yaw(player.heading)
	var forward: Vector3 = frame["forward"]
	var right: Vector3 = frame["right"]
	player.set_meta("along", lerpf(1.0, nose.dot(forward), 0.55))
	player.lateral += nose.dot(right) * speed * 0.64 * delta

	var style: Dictionary = Routes.path_style()[String(player.route["path"])]
	var half: float = float(style["half"])
	var reserve: float = float(style.get("reserve", 0.0))
	var to_curb: float = half - player.lane - 1.35
	var inner: float = reserve + 1.15 if reserve > 1.0 else 1.4
	var to_middle: float = -(player.lane - inner)
	if player.lateral > to_curb:
		player.lateral = to_curb
		_scrape(speed, "Бордюр")
	elif player.lateral < to_middle:
		player.lateral = to_middle
		_scrape(speed, "Встречная полоса")


# Бот держит нос по дуге впереди и возвращается в свою полосу. Игроку это не делается.
func _bot_steer() -> float:
	var look: float = player.progress + 22.0 * float(player.dir)
	var ahead: Vector3 = player.road_frame(look)["forward"]
	var err: float = wrapf(Vehicle.yaw_from_forward(ahead) - player.heading, -PI, PI)
	var turn: float = clampf(-err * 2.4, -1.0, 1.0)
	var hold: float = clampf(-player.lateral * 0.5, -0.55, 0.55)
	return clampf(turn + hold, -1.0, 1.0)


func _scrape(speed: float, what: String) -> void:
	if speed < 3.0 or float(state["accident_lock"]) > 0.0:
		return
	player.speed *= 0.7
	player.steer_rate = 0.0
	state["accident_lock"] = 3.0
	hud.toast("%s — задели" % what)
	_score("curb")


func _stop_offsets() -> Array:
	# Отметки остановок в порядке проезда: расписание считается по перегонам.
	var offsets := []
	for stop in player.stops():
		offsets.append(float(stop["offset"]))
	offsets.sort()
	if player.dir < 0:
		offsets.reverse()
	return offsets


func _check_driver_stops(speed: float) -> void:
	var stops: Array = player.stops()
	var order := []
	for i in stops.size():
		order.append(i)
	if player.dir < 0:
		order.reverse()
	for index in stops.size():
		var stop: Dictionary = stops[index]
		var mark: Dictionary = driver_stops[index]
		var near: bool = absf(float(stop["offset"]) - player.progress) < 14.0
		if near and player.doors_open and speed < 1.6 and not bool(mark["resolved"]):
			var ordinal: int = max(0, order.find(index))
			var scheduled: float = float(timetable[min(ordinal, timetable.size() - 1)])
			if OS.has_environment("UFA_DEBUG_STOPS"):
				print("stop %s ord=%d of %d off=%.1f sched=%.1f now=%.1f dir=%d" % [
					stop["name"], ordinal, timetable.size(), float(stop["offset"]),
					scheduled, float(state["minutes"]), player.dir])
			_score(Rules.judge_stop(float(state["minutes"]), scheduled, true))
			mark["resolved"] = true
			if bool(player.route.get("intercity", false)):
				var dwell := 20.0 if String(stop["name"]).find("Кафе") >= 0 else 7.0
				ic_dwell_until = float(state["minutes"]) + dwell
				player.doors_open = true
				hud.toast("Кондуктор: «%s». Стоянка %d мин, чай в проходе" % [stop["name"], int(dwell)])
			elif not bool(state["small_bus"]):
				var heads: int = rng.randi_range(2, 4)
				var due: int = _ticket_price(player.route) * heads
				_credit_fare(due)
				hud.toast("Посадка %d чел. · +%d ₽" % [heads, due])
			if player.vehicle_type != "tram":
				var half: float = float(Routes.path_style()[String(player.route["path"])]["half"])
				var curb_gap: float = half - player.lane - player.lateral - 1.35
				if curb_gap > 1.6:
					hud.toast("До бордюра %.1f м — подъезжайте ближе" % curb_gap)
			if bool(state["small_bus"]):
				var served: Dictionary = player.get_meta("served", {})
				var key := "%d:%s" % [player.dir, stop["name"]]
				if not served.has(key):
					served[key] = true
					player.set_meta("served", served)
					hud.toast("Оплата на остановке «%s»" % stop["name"])
					_open_fare({"tender": _roll_tender()})
		if bool(mark["near"]) and not near and not bool(mark["resolved"]):
			if OS.has_environment("UFA_DEBUG_STOPS"):
				print("skip %s offset=%.1f progress=%.1f dir=%d speed=%.1f doors=%s" % [
					stop["name"], float(stop["offset"]), player.progress, player.dir, speed, player.doors_open])
			_score("skip")
			mark["resolved"] = true
		mark["near"] = near


func _check_collision() -> void:
	if float(state["accident_lock"]) > 0.0 or player.speed < 3.0:
		return
	for vehicle in traffic:
		var other: Vehicle = vehicle
		if other.route["id"] != player.route["id"]:
			continue
		var gap: float = absf(other.progress - player.progress)
		if other.dir == player.dir and gap < (other.body_length + player.body_length) * 0.45:
			_score("accident")
			player.speed *= 0.2
			state["accident_lock"] = 4.0
			return


# Шаг пешком в плоскости XZ относительно взгляда: W вперёд, D вправо.
func _walk_delta(step: float) -> Vector2:
	var forward := 0.0
	var strafe := 0.0
	if Input.is_key_pressed(KEY_W):
		forward += 1.0
	if Input.is_key_pressed(KEY_S):
		forward -= 1.0
	if Input.is_key_pressed(KEY_A):
		strafe -= 1.0
	if Input.is_key_pressed(KEY_D):
		strafe += 1.0
	return Vector2(
		(sin(look_yaw) * forward + cos(look_yaw) * strafe) * step,
		(-cos(look_yaw) * forward + sin(look_yaw) * strafe) * step)


func _conductor(delta: float) -> void:
	if fare["open"] or player == null:
		return
	var move := _walk_delta(2.4 * delta)
	walk.x += move.x
	walk.z += move.y
	var span: float = player.salon_span()
	walk.x = clamp(walk.x, -0.6, 0.6)
	walk.z = clamp(walk.z, -span, span)

	rider_timer += delta
	var rider_gap := 14.0 if String(state["period"]) == "evening" else 7.0
	if rider_timer > rider_gap and riders.size() < 1:
		rider_timer = 0.0
		var person := City.make_person(Color(0.25, 0.35, 0.5))
		var z: float = rng.randf_range(-span * 0.6, span * 0.6)
		person.position = Vector3(rng.randf_range(-0.4, 0.4), float(Fleet.spec(player.model_id)["floor"]) + 0.06, z)
		person.scale = Vector3(0.95, 0.95, 0.95)
		player.front().add_child(person)
		riders.append({"node": person, "tender": _roll_tender(), "z": z})

	if Input.is_key_pressed(KEY_E) and not bool(player.get_meta("e_latch", false)):
		player.set_meta("e_latch", true)
		for person in riders:
			var node: Node3D = person["node"]
			if not is_instance_valid(node):
				continue
			var dist: float = Vector2(node.position.x - walk.x, node.position.z - walk.z).length()
			if dist < 1.8:
				_open_fare(person)
				break
	elif not Input.is_key_pressed(KEY_E):
		player.set_meta("e_latch", false)


func _clear_passenger_props() -> void:
	for item in lost_tickets:
		var node: Node = item["node"]
		if is_instance_valid(node):
			node.queue_free()
	lost_tickets.clear()
	for item in parcels:
		var box: Node = item["node"]
		if is_instance_valid(box):
			box.queue_free()
	parcels.clear()
	errand = {}
	_set_carry(false)
	if car != null and is_instance_valid(car):
		car.queue_free()
	car = null
	state["in_car"] = false
	if walker != null:
		walker.visible = false


func _spawn_lost_tickets() -> void:
	for stop in city["stops"]:
		var path_name := String(stop["path"])
		var half: float = float(Routes.path_style()[path_name]["half"])
		for n in 2:
			var route: Dictionary = network["routes"][rng.randi_range(0, network["routes"].size() - 1)]
			var model := String(route["models"][0])
			var kind := Fleet.type_of(model)
			var due := Rules.ride_price(route, "cash")
			var data := TicketArt.make(Fleet.title_of(model), kind, String(route["number"]),
				String(route.get("operator", "Башавтотранс")), String(stop["name"]),
				Rules.format_clock(rng.randf_range(480.0, 1200.0)), due, "cash", 50, max(0, 50 - due), rng)
			var node := TicketArt.litter(data, rng)
			var side := 1.0 if n == 0 else -1.0
			var pos: Vector3 = stop["pos"] + stop["right"] * side * (half + 2.4) + stop["forward"] * rng.randf_range(-5.0, 5.0)
			node.position = Vector3(pos.x, pos.y + City.SIDEWALK_H + 0.03, pos.z)
			world_root.add_child(node)
			lost_tickets.append({"node": node, "data": data})


func _spawn_car(spot: Vector3, heading: float) -> void:
	if car != null and is_instance_valid(car):
		car.queue_free()
	car = TownCar.new()
	world_root.add_child(car)
	car.setup(Color(0.72, 0.13, 0.14))
	var y := 0.0
	if city.has("terrain"):
		y = City.surface_y(spot.x, spot.z, city["terrain"])
	car.place(Vector3(spot.x, y, spot.z), heading)


func _open_passenger_till() -> void:
	var host := _host()
	if host == null:
		return
	var due := _ticket_price(host.route)
	if int(state["wallet"]) < due:
		hud.toast("Не хватает денег")
		return
	fare = {"open": true, "mode": "passenger", "tender": 0, "due": due, "pieces": [], "person": null}
	_release_mouse()
	_build_fare_desk()
	hud.show_passenger_till(fare, host.vehicle_type)


func _confirm_passenger_fare() -> void:
	var sum := 0
	for piece in fare["pieces"]:
		sum += int(piece)
	var due := int(fare["due"])
	if sum < due:
		hud.toast("Мало денег в лотке: нужно %d ₽" % due)
		return
	var host := _host()
	if host == null:
		_close_fare()
		return
	state["wallet"] = int(state["wallet"]) - due
	var stop_name: String = String(city["stops"][int(state["wait_index"])]["name"])
	var data := _add_ticket(host, due, "cash", stop_name, sum, sum - due)
	state["board_phase"] = "ride"
	state["camera"] = "cabin"
	hud.show_receipt(data)
	_close_fare()
	if not bot:
		_show_hand_receipt(data)
		_capture_mouse()


func _pick_lost_ticket() -> bool:
	var me := Vector2(walk_pos.x, walk_pos.z)
	var best := -1
	var best_d := 2.6
	for i in lost_tickets.size():
		var node: Node3D = lost_tickets[i]["node"]
		if not is_instance_valid(node):
			continue
		var dist := Vector2(node.global_position.x, node.global_position.z).distance_to(me)
		if dist < best_d:
			best_d = dist
			best = i
	if best < 0:
		return false
	var item: Dictionary = lost_tickets[best]
	var pocket: Array = state["pocket"]
	pocket.append(item["data"])
	if is_instance_valid(item["node"]):
		item["node"].queue_free()
	lost_tickets.remove_at(best)
	_persist()
	hud.show_receipt(item["data"])
	item["data"]["found"] = true
	hud.toast("Чек маршрута %s. Проедете по нему — достижение «Счастливый билет» и 200 ₽" % String(item["data"]["route"]))
	return true


func _spawn_parcels() -> void:
	var stops: Array = city["stops"]
	if stops.size() < 2:
		return
	var step: int = maxi(2, int(stops.size() / 4))
	for i in stops.size():
		if i % 3 != 0:
			continue
		_place_parcel(i, (i + step) % stops.size())
	var here := int(state["wait_index"])
	if not _stop_has_parcel(here):
		_place_parcel(here, (here + step) % stops.size())


func _place_parcel(from_i: int, dest_i: int) -> void:
	if from_i == dest_i or _stop_has_parcel(from_i):
		return
	var stop: Dictionary = city["stops"][from_i]
	var dest: Dictionary = city["stops"][dest_i]
	var half: float = float(Routes.path_style()[String(stop["path"])]["half"])
	var pos: Vector3 = stop["pos"] + stop["right"] * (half + 2.5) + stop["forward"] * 3.2
	var root := Node3D.new()
	root.name = "Parcel"
	root.position = Vector3(pos.x, pos.y + City.SIDEWALK_H + 0.16, pos.z)
	world_root.add_child(root)
	root.add_child(MeshLib.box(Vector3(0.46, 0.32, 0.34), Vector3.ZERO,
		MeshLib.mat(Color(0.62, 0.42, 0.22), 0.9), "Box"))
	var pay := Rules.delivery_pay(Vector3(stop["pos"]).distance_to(Vector3(dest["pos"])))
	var lab := MeshLib.label("→ %s\n%d ₽" % [String(dest["name"]), pay], 28, Color(0.98, 0.94, 0.82))
	lab.position = Vector3(0, 0.42, 0)
	lab.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	root.add_child(lab)
	parcels.append({"node": root, "from": from_i, "dest": dest_i, "pay": pay})


func _stop_has_parcel(index: int) -> bool:
	for item in parcels:
		if int(item["from"]) == index:
			return true
	return false


func _nearby_parcel(limit := 3.4) -> int:
	var me := Vector2(walk_pos.x, walk_pos.z)
	var best := -1
	var best_d := limit
	for i in parcels.size():
		var node: Node3D = parcels[i]["node"]
		if not is_instance_valid(node):
			continue
		var dist := Vector2(node.global_position.x, node.global_position.z).distance_to(me)
		if dist < best_d:
			best_d = dist
			best = i
	return best


func _near_stop(index: int) -> bool:
	var stop: Dictionary = city["stops"][index]
	var half: float = float(Routes.path_style()[String(stop["path"])]["half"])
	var me := Vector2(walk_pos.x, walk_pos.z)
	for side in [-1.0, 1.0]:
		var pad: Vector3 = stop["pos"] + stop["right"] * side * (half + 2.2)
		if me.distance_to(Vector2(pad.x, pad.z)) < 8.0:
			return true
	return false


func _try_delivery() -> bool:
	if not errand.is_empty():
		if _near_stop(int(errand["dest"])):
			_finish_delivery()
			return true
		return false
	var index := _nearby_parcel()
	if index < 0:
		return false
	_take_parcel(index)
	return true


func _take_parcel(index: int) -> void:
	if not errand.is_empty() or index < 0 or index >= parcels.size():
		return
	var item: Dictionary = parcels[index]
	var dest: Dictionary = city["stops"][int(item["dest"])]
	errand = {
		"dest": int(item["dest"]),
		"name": String(dest["name"]),
		"pay": int(item["pay"]),
		"from": int(item["from"]),
	}
	if is_instance_valid(item["node"]):
		item["node"].queue_free()
	parcels.remove_at(index)
	_set_carry(true)
	hud.toast("Посылка на «%s» · +%d ₽" % [errand["name"], int(errand["pay"])])


func _finish_delivery() -> void:
	if errand.is_empty():
		return
	if not _near_stop(int(errand["dest"])):
		hud.toast("Сдайте посылку на «%s»" % String(errand["name"]))
		return
	var pay := int(errand["pay"])
	var dest_i := int(errand["dest"])
	var from_i := int(errand["from"])
	state["wallet"] = int(state["wallet"]) + pay
	_persist()
	hud.toast("Доставка на «%s»: +%d ₽" % [String(errand["name"]), pay])
	errand = {}
	_set_carry(false)
	var stops: Array = city["stops"]
	var next: int = (dest_i + maxi(2, int(stops.size() / 4))) % stops.size()
	if next == dest_i:
		next = (dest_i + 1) % stops.size()
	if next == from_i:
		next = (next + 1) % stops.size()
	_place_parcel(dest_i, next)


func _set_carry(on: bool) -> void:
	if carry != null and is_instance_valid(carry):
		carry.queue_free()
	carry = null
	if not on or walker == null:
		return
	carry = MeshLib.box(Vector3(0.36, 0.26, 0.3), Vector3(0.22, 1.02, 0.28),
		MeshLib.mat(Color(0.62, 0.42, 0.22), 0.9), "Carry")
	walker.add_child(carry)


func _errand_button() -> Dictionary:
	if not errand.is_empty():
		if _near_stop(int(errand["dest"])):
			return {"text": "Сдать посылку · +%d ₽" % int(errand["pay"]), "act": "dropJob", "arg": ""}
		return {}
	var index := _nearby_parcel(9.0)
	if index < 0:
		return {}
	var item: Dictionary = parcels[index]
	var dest: Dictionary = city["stops"][int(item["dest"])]
	return {
		"text": "Взять посылку → %s · %d ₽" % [String(dest["name"]), int(item["pay"])],
		"act": "takeJob",
		"arg": str(index),
	}


func _check_lucky(host: Vehicle) -> void:
	if lucky.is_empty():
		return
	if absf(host.progress - float(lucky["from"])) < 60.0:
		return
	lucky = {}
	state["wallet"] = int(state["wallet"]) + 200
	var book: Array = state["achievements"]
	var first := not book.has("lucky")
	if first:
		book.append("lucky")
	_persist()
	if first:
		hud.toast("Достижение «Счастливый билет» · +200 ₽")
	else:
		hud.toast("Снова по найденному билету · +200 ₽")


func _open_office() -> void:
	var list := []
	for route in network["routes"]:
		if bool(route.get("intercity", false)):
			list.append(route)
	state["office_open"] = true
	_release_mouse()
	hud.show_office(list, int(state["wallet"]))


func _close_office() -> void:
	state["office_open"] = false
	hud.hide_modal()
	if shift_active and not state["paused"]:
		_capture_mouse()


func _buy_pass(route_id: String) -> void:
	var route := Routes.find_route(network["routes"], route_id)
	if not bool(route.get("intercity", false)):
		return
	var price := int(route["fare"])
	if int(state["wallet"]) < price:
		hud.toast("Нужно %d ₽" % price)
		return
	state["wallet"] = int(state["wallet"]) - price
	var data := TicketArt.make(String(route["models"][0]), "bus", String(route["number"]),
		String(route["operator"]), "Автовокзал", Rules.format_clock(float(state["minutes"])),
		price, "касса", price, 0, rng)
	data["model"] = String(route["title"])
	data["bought"] = true
	data["found"] = false
	var pocket: Array = state["pocket"]
	pocket.append(data)
	_persist()
	hud.toast("Билет %s · −%d ₽" % [String(route["number"]), price])
	_open_office()


func _use_service() -> bool:
	var here := Vector2(walk_pos.x, walk_pos.z)
	var office: Dictionary = city.get("office", {})
	if not office.is_empty():
		var desk: Vector3 = office["pos"]
		if Vector2(desk.x, desk.z).distance_to(here) < 8.0:
			_open_office()
			return true
	for kiosk in city.get("kiosks", []):
		var at: Vector3 = kiosk["pos"]
		if Vector2(at.x, at.z).distance_to(here) < 8.0:
			return _sell_pocket()
	var market: Dictionary = city.get("market", {})
	if not market.is_empty():
		var at: Vector3 = market["pos"]
		if Vector2(at.x, at.z).distance_to(here) < 14.0:
			return _buy_car()
	if _near_own_car():
		_enter_car()
		return true
	return false


func _sell_pocket() -> bool:
	var pocket: Array = state["pocket"]
	if pocket.is_empty():
		hud.toast("Нечего сдавать — ищите чеки на остановках")
		return true
	var pay := pocket.size() * Rules.FOUND_PRICE
	state["wallet"] = int(state["wallet"]) + pay
	state["sold"] = int(state["sold"]) + pocket.size()
	pocket.clear()
	_persist()
	hud.toast("Скупка приняла находки: +%d ₽" % pay)
	return true


func _buy_car() -> bool:
	if bool(state["car"]):
		hud.toast("Машина уже ваша — она стоит у обочины")
		return true
	if int(state["wallet"]) < TownCar.PRICE:
		hud.toast("Автосалон: нужно %d ₽" % TownCar.PRICE)
		return true
	state["wallet"] = int(state["wallet"]) - TownCar.PRICE
	state["car"] = true
	_persist()
	var face := Vector3(sin(look_yaw), 0.0, -cos(look_yaw))
	_spawn_car(walk_pos + face * 5.5, atan2(-face.x, -face.z))
	hud.toast("Ключи ваши. Подойдите и нажмите E")
	return true


func _near_own_car() -> bool:
	if car == null or not is_instance_valid(car) or bool(state["in_car"]):
		return false
	return Vector2(car.global_position.x, car.global_position.z).distance_to(Vector2(walk_pos.x, walk_pos.z)) < 5.0


func _enter_car() -> void:
	state["in_car"] = true
	look_yaw = 0.0
	look_pitch = -0.08
	if not mouse_captured and not bot:
		_capture_mouse()


func _drive_car(delta: float, exit_pressed: bool) -> void:
	var throttle := 1.0 if (Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP)) else 0.0
	var brake := 1.0 if (Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN)) else 0.0
	var steer_input := 0.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		steer_input += 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		steer_input -= 1.0
	var prev := car.global_position
	car.drive(delta, throttle, brake, steer_input, Rules.grip_for("bus", String(state["weather"])))
	if city.has("terrain"):
		var ground := City.surface_y(car.global_position.x, car.global_position.z, city["terrain"])
		if ground > 1.8:
			car.global_position = prev
			car.speed = 0.0
		else:
			car.global_position.y = ground
	if exit_pressed and absf(car.speed) < 1.5:
		state["in_car"] = false
		look_yaw = -car.yaw
		look_pitch = 0.0
		walk_pos = _snap_to_walkway(car.door_position())
		car.silence()
		hud.toast("Вы вышли из машины")


func _sync_walker() -> void:
	if walker == null:
		return
	var phase := String(state["board_phase"])
	var on_foot: bool = shift_active and state["role"] == "passenger" and (phase == "" or phase == "entering") and not bool(state["in_car"])
	walker.visible = on_foot
	if not on_foot:
		return
	walker.global_position = walk_pos
	walker.rotation.y = look_yaw


func _passenger(delta: float) -> void:
	var move := _walk_delta(2.8 * delta)
	var press_e: bool = Input.is_key_pressed(KEY_E)
	var latch: bool = bool(state.get("pass_latch", false))
	state["pass_latch"] = press_e
	if String(state["board_phase"]) == "entering":
		_tick_enter(delta)
		return
	if String(state["board_phase"]) == "ride":
		var host := _host()
		if host == null:
			return
		_check_lucky(host)
		walk.x = clamp(walk.x + move.x, -0.6, 0.6)
		walk.z = clamp(walk.z + move.y, -host.salon_span(), host.salon_span())
		if press_e and not latch and host.doors_open:
			_alight(host)
		return

	if bool(state["in_car"]) and car != null:
		_drive_car(delta, press_e and not latch)
		return

	# Свободная ходьба по городу: от остановки к остановке, вдоль тротуаров.
	var run: bool = Input.is_key_pressed(KEY_SHIFT)
	var step := _walk_delta((11.0 if run else 5.0) * delta)
	walk_pos += Vector3(step.x, 0, step.y)
	walk_pos = _snap_to_walkway(walk_pos)
	if step.length() > 0.002:
		step_gap -= step.length()
		if step_gap <= 0.0:
			step_gap = 0.48 if run else 0.74
			Sfx.play(self, Sfx.step_clip(), -16.0, rng.randf_range(0.92, 1.08))
	state["wait_index"] = _nearest_stop(walk_pos)
	if press_e and not latch:
		if _pick_lost_ticket():
			return
		if _use_service():
			return
		var me: Vector3 = walk_pos + Vector3(0, 1.6, 0)
		for vehicle in traffic:
			var v: Vehicle = vehicle
			if not v.doors_open:
				continue
			for section in v.sections:
				if (section as Node3D).global_position.distance_to(me) < 12.0:
					if bot:
						_board(v.name)
					else:
						_start_enter(v)
					return
		_try_delivery()


# Пешехода держим у дороги: вдоль улицы свободно, в стороны — до тротуара.
func _snap_to_walkway(pos: Vector3) -> Vector3:
	var best_path := walk_path
	var best_dist := 1.0e9
	var best_y := 0.0
	for key in network["paths"].keys():
		var curve: Curve3D = (network["paths"][key] as Path3D).curve
		var d: float = curve.get_closest_offset(pos)
		var p: Vector3 = curve.sample_baked(d)
		var dist: float = Vector2(p.x, p.z).distance_to(Vector2(pos.x, pos.z))
		if dist < best_dist:
			best_dist = dist
			best_path = String(key)
			best_y = p.y
	walk_path = best_path
	var half: float = float(Routes.path_style()[best_path]["half"])
	var dist_road := best_dist
	var y := best_y
	if dist_road <= half + 0.6:
		y = best_y + 0.05
	elif dist_road <= half + 8.0:
		y = best_y + City.SIDEWALK_H
	elif city.has("terrain"):
		y = City.surface_y(pos.x, pos.z, city["terrain"])
	# По городу можно идти свободно: с автобусной остановки до трамвайной.
	return Vector3(pos.x, y, pos.z)


func _on_crossing(path_name: String, offset: float) -> bool:
	for cross in city["crossings"]:
		if String(cross["path"]) == path_name and absf(float(cross["offset"]) - offset) < 7.0:
			return true
	return false


func _open_phone() -> void:
	var rows := _phone_rows()
	if rows.is_empty():
		hud.toast("Рядом нет транспорта с бортовым номером")
		return
	state["phone_open"] = true
	_release_mouse()
	hud.show_phone(rows)


func _close_phone() -> void:
	state["phone_open"] = false
	hud.hide_modal()
	if shift_active and not state["paused"] and not fare["open"]:
		_capture_mouse()


func _phone_rows() -> Array:
	var origin := walk_pos
	var riding := _host()
	if riding != null:
		origin = riding.front_position()
	elif player != null:
		origin = player.front_position()
	var pool: Array = traffic.duplicate()
	if player != null:
		pool.append(player)
	var ranked := []
	var seen := {}
	for vehicle in pool:
		var v: Vehicle = vehicle
		if v.fleet_no <= 0 or seen.has(v.fleet_no):
			continue
		var dist: float = v.front_position().distance_to(origin)
		if v != riding and dist > 40.0:
			continue
		seen[v.fleet_no] = true
		ranked.append({"v": v, "dist": dist})
	ranked.sort_custom(func(a, b): return float(a["dist"]) < float(b["dist"]))
	if ranked.size() > 6:
		ranked.resize(6)
	var book: Dictionary = state["reviews"]
	var rows := []
	for item in ranked:
		var v: Vehicle = item["v"]
		var key := str(v.fleet_no)
		var stars := int(book.get(key, 0))
		rows.append({
			"no": v.fleet_no,
			"line": "№ %d · %s %s" % [v.fleet_no, Rules.TYPE_LABEL[v.vehicle_type], v.route["number"]],
			"sub": "%s · %s" % [v.title, String(v.condition.get("label", ""))],
			"stars": stars,
		})
	return rows


func _nearest_stop(pos: Vector3) -> int:
	var best := 0
	var best_dist := 1.0e9
	for i in city["stops"].size():
		var d: float = Vector3(city["stops"][i]["pos"]).distance_to(Vector3(pos.x, 0, pos.z))
		if d < best_dist:
			best_dist = d
			best = i
	return best


func _alight(host: Vehicle) -> void:
	var best := int(state["wait_index"])
	var best_dist := 1.0e9
	for i in city["stops"].size():
		var d: float = (city["stops"][i]["pos"] as Vector3).distance_to(host.front_position())
		if d < best_dist:
			best_dist = d
			best = i
	state["wait_index"] = best
	state["board_phase"] = ""
	state["camera"] = "chase"
	var landed: Dictionary = city["stops"][best]
	var landed_face: Vector3 = landed["forward"]
	look_yaw = atan2(landed_face.x, -landed_face.z)
	var landed_half: float = float(Routes.path_style()[String(landed["path"])]["half"])
	walk_pos = _snap_to_walkway(landed["pos"] + landed["right"] * (landed_half + 2.2))
	wait_walk = Vector3.ZERO
	hud.hide_modal()
	hud.hide_dock()
	hud.toast("Вы вышли на «%s»" % String(city["stops"][best]["name"]))


# --- атмосфера и камера -------------------------------------------------

func _update_sky() -> void:
	var day: float = Rules.sun_factor(float(state["minutes"]))
	var night: float = 1.0 - day
	var elevation: float = lerp(-6.0, -58.0, day)
	sun.rotation_degrees = Vector3(elevation, lerp(120.0, 38.0, day), 0)
	sun.light_energy = lerp(0.05, 1.25, day)
	sun.light_color = Color(1.0, 0.72, 0.45).lerp(Color(1.0, 0.96, 0.9), day)
	var top := Color(0.04, 0.06, 0.13).lerp(Color(0.2, 0.42, 0.78), day)
	var horizon := Color(0.1, 0.12, 0.18).lerp(Color(0.72, 0.82, 0.92), day)
	var cover := 0.42
	var lit := Color(0.24, 0.26, 0.32).lerp(Color(1.0, 0.99, 0.96), day)
	var shade := Color(0.14, 0.15, 0.2).lerp(Color(0.66, 0.68, 0.74), day)
	if state["weather"] == "rain":
		top = top.lerp(Color(0.24, 0.28, 0.33), 0.7)
		horizon = horizon.lerp(Color(0.4, 0.44, 0.48), 0.7)
		cover = 0.78
		lit = lit.lerp(Color(0.5, 0.53, 0.58), 0.75)
		shade = shade.lerp(Color(0.26, 0.28, 0.33), 0.75)
	elif state["weather"] == "snow":
		top = top.lerp(Color(0.56, 0.62, 0.7), 0.75)
		horizon = horizon.lerp(Color(0.8, 0.83, 0.87), 0.75)
		cover = 0.82
		lit = lit.lerp(Color(0.9, 0.92, 0.95), 0.8)
		shade = shade.lerp(Color(0.6, 0.63, 0.68), 0.8)
	elif state["weather"] == "fog":
		top = top.lerp(Color(0.62, 0.66, 0.7), 0.85)
		horizon = horizon.lerp(Color(0.78, 0.8, 0.82), 0.9)
		cover = 0.92
		lit = lit.lerp(Color(0.8, 0.82, 0.84), 0.8)
		shade = shade.lerp(Color(0.55, 0.58, 0.6), 0.8)
	sky_material.set_shader_parameter("top_color", top)
	sky_material.set_shader_parameter("horizon_color", horizon)
	sky_material.set_shader_parameter("ground_color", horizon.darkened(0.45))
	sky_material.set_shader_parameter("cloud_lit", lit)
	sky_material.set_shader_parameter("cloud_shade", shade)
	sky_material.set_shader_parameter("cover", cover)
	sky_material.set_shader_parameter("haze", 0.1 + day * 0.35)
	sky_material.set_shader_parameter("sun_size", 0.0012)
	env.ambient_light_energy = lerp(0.16, 0.72, day)
	env.ambient_light_color = Color(0.5, 0.56, 0.72).lerp(Color(0.9, 0.91, 0.93), day)
	env.fog_light_color = horizon
	var fog := 0.0008
	if state["weather"] == "snow":
		fog = 0.003
	elif state["weather"] == "rain":
		fog = 0.0022
	elif state["weather"] == "fog":
		fog = 0.03
	env.fog_density = fog
	env.glow_intensity = 0.2 + night * 0.25

	for mat in city["night_materials"]:
		(mat as StandardMaterial3D).emission_energy_multiplier = night * 1.8
	for mat in city["lamp_materials"]:
		(mat as StandardMaterial3D).emission_energy_multiplier = night * 3.0
	for light in city["lamps"]:
		(light as OmniLight3D).light_energy = night * 2.2
	var host_v := _host()
	var lamp_k := night
	if String(state["period"]) == "evening" or night > 0.45:
		lamp_k = 1.0
	if String(state["weather"]) == "fog":
		lamp_k = maxf(lamp_k, 0.8)
	if host_v != null:
		for beam in host_v.beams:
			(beam as SpotLight3D).light_energy = lamp_k * 3.4
			if String(state["weather"]) == "fog":
				(beam as SpotLight3D).spot_angle = 28.0
			else:
				(beam as SpotLight3D).spot_angle = 38.0
		for lamp in host_v.headlights:
			(lamp as MeshInstance3D).material_override.emission_energy_multiplier = 0.5 + lamp_k * 2.6
	var wet: float = 1.0 if state["weather"] == "rain" else 0.0
	for mat in city["road_materials"]:
		var road: StandardMaterial3D = mat
		road.roughness = lerp(0.92, 0.28, wet)
		road.metallic = lerp(0.0, 0.35, wet)
	if city.has("terrain_material"):
		(city["terrain_material"] as ShaderMaterial).set_shader_parameter("snow", 1.0 if state["weather"] == "snow" else 0.0)
	if player != null:
		for lamp in player.headlights:
			(lamp as MeshInstance3D).material_override.emission_energy_multiplier = 0.6 + lamp_k * 3.0
		for strip in player.interior_lights:
			(strip as MeshInstance3D).material_override.emission_energy_multiplier = 0.2 + night * 2.4


func _update_weather() -> void:
	var active: bool = shift_active
	rain.emitting = active and state["weather"] == "rain"
	snow.emitting = active and state["weather"] == "snow"
	var anchor: Vector3 = camera.global_position + Vector3(0, 11, 0)
	rain.global_position = anchor
	snow.global_position = anchor
	_sync_drifts()


func _sync_drifts() -> void:
	var want: bool = shift_active and String(state["weather"]) == "snow"
	if not want:
		if drift_root != null and is_instance_valid(drift_root):
			drift_root.queue_free()
		drift_root = null
		return
	if drift_root != null:
		return
	drift_root = Node3D.new()
	drift_root.name = "Drifts"
	world_root.add_child(drift_root)
	var mat := MeshLib.mat(Color(0.94, 0.96, 0.98), 0.8)
	for key in ["prospekt", "north"]:
		if not network["paths"].has(key):
			continue
		var curve: Curve3D = network["paths"][key].curve
		var length := curve.get_baked_length()
		var step := 46.0
		var at := 20.0
		while at < length - 20.0:
			var p: Vector3 = curve.sample_baked(at)
			var pile := MeshLib.box(Vector3(1.6, 0.35, 3.2), p + Vector3(0, 0.15, 0), mat, "Drift")
			drift_root.add_child(pile)
			at += step


func _update_camera(delta: float) -> void:
	if fare["open"] and fare_desk != null:
		# На время расчёта камера смотрит на лоток и не дёргается за кузовом.
		return
	if not shift_active:
		menu_angle += delta * 0.06
		var focus: Vector3 = city.get("focus", Vector3(-50, 8, 10))
		var radius := 150.0
		var height := 42.0
		if shot_menu:
			radius = 520.0
			height = 380.0
		camera.position = focus + Vector3(cos(menu_angle) * radius, height, sin(menu_angle) * radius)
		camera.look_at(focus, Vector3.UP)
		return
	if state["role"] == "passenger" and (String(state["board_phase"]) == "" or String(state["board_phase"]) == "entering"):
		_sync_walker()
		if bool(state["in_car"]) and car != null and is_instance_valid(car):
			var orbit := car.yaw + look_yaw
			var behind := Vector3(sin(orbit), 0.0, cos(orbit))
			var eye := car.global_position + behind * 8.4 + Vector3(0, 2.6, 0)
			eye.y = max(eye.y, car.global_position.y + 1.3)
			camera.global_position = camera.global_position.lerp(eye, 1.0 - exp(-delta * 5.5))
			camera.look_at(car.global_position + Vector3(0, 1.2 + sin(look_pitch), 0), Vector3.UP)
			return
		var facing := Vector3(sin(look_yaw), 0.0, -cos(look_yaw))
		var eye := walk_pos - facing * 6.4 + Vector3(0, 3.6, 0)
		eye.y = max(eye.y, walk_pos.y + 1.4)
		camera.global_position = camera.global_position.lerp(eye, 1.0 - exp(-delta * 10.0))
		camera.look_at(walk_pos + Vector3(0, 1.35, 0) + facing * 4.0 + Vector3(0, sin(look_pitch) * 3.0, 0), Vector3.UP)
		return
	var host := _host()
	if host == null:
		return
	var inside: bool = state["role"] == "conductor" or state["camera"] == "cabin"
	if inside:
		var basis_node: Node3D = host.front()
		var origin: Vector3
		if state["role"] == "driver":
			origin = host.cabin_point().global_position
		else:
			# Кондуктор и пассажир стоят в салоне и ходят по нему.
			origin = basis_node.to_global(Vector3(walk.x,
				float(Fleet.spec(host.model_id)["floor"]) + 1.62, walk.z))
		camera.global_position = origin
		var look_dir: Vector3 = basis_node.global_transform.basis * Vector3(
			sin(look_yaw) * cos(look_pitch), sin(look_pitch), -cos(look_yaw) * cos(look_pitch))
		camera.look_at(origin + look_dir, Vector3.UP)
		return
	var front: Node3D = host.front()
	var offset := Vector3(0, 5.4, 10.0 + host.body_length * 0.85)
	match String(state["camera"]):
		"side":
			offset = Vector3(9.0 + host.body_length * 0.3, 2.8, -host.body_length * 0.05)
		"front":
			offset = Vector3(4.0, 2.6, -host.body_length * 0.75)
		"rear":
			offset = Vector3(3.2, 2.6, host.body_length * 0.9)
		"top":
			offset = Vector3(0.1, host.body_length * 0.9, 0.1)
	var want: Vector3 = front.global_position + front.global_transform.basis * offset
	if chase_pos == Vector3.ZERO or shot_path != "":
		chase_pos = want
	else:
		chase_pos = chase_pos.lerp(want, 1.0 - exp(-delta * 3.2))
	camera.global_position = chase_pos
	var target: Vector3 = front.global_position + Vector3(0, 2.2, 0)
	if String(state["camera"]) == "rear":
		target = front.global_position + front.global_transform.basis * Vector3(0, 1.8, host.body_length * 0.8)
	if String(state["camera"]) == "side":
		target = front.global_position + front.global_transform.basis * Vector3(0, 1.6, host.body_length * 0.25)
	camera.look_at(target, Vector3.UP)


func _update_hud(delta: float) -> void:
	var host := _host()
	var kind: String = host.vehicle_type if host != null else String(_current_route()["type"])
	hud.set_chip("clock", "%s · %s" % [Rules.format_clock(float(state["minutes"])),
		Rules.PERIOD_LABEL[Rules.period_of(float(state["minutes"]))]])
	hud.set_chip("weather", Rules.WEATHER_LABEL[state["weather"]])
	var pocket_n := 0
	if state.has("pocket"):
		pocket_n = state["pocket"].size()
	hud.set_chip("money", "Кошелёк %d ₽ · чеков %d%s" % [int(state["wallet"]), pocket_n, " · Алга" if bool(state["alga"]) else ""])
	hud.set_chip("rating", "Без оценки" if state["role"] == "passenger" else "Оценка %d" % int(state["rating"]))
	var speed_ms := 0.0
	if bool(state["in_car"]) and car != null:
		speed_ms = car.speed
	elif host != null:
		speed_ms = host.speed
	var speed_text := "%d км/ч" % int(round(absf(speed_ms) * 3.6))
	if reverse_gear and state["role"] == "driver":
		speed_text = "−" + speed_text
	hud.set_chip("speed", speed_text)
	hud.set_chip("grip", "Рельс 100%" if kind == "tram" else "Сцепление %d%%" % int(round(Rules.grip_for(kind, String(state["weather"])) * 100.0)))
	if host != null and state["role"] != "passenger":
		if bool(host.route.get("intercity", false)):
			var km := Road.km_of(host.progress, host.m0, host.m1)
			hud.set_chip("next", "М-5 · %d км · %s" % [int(km), String(host.next_stop()["name"])])
		else:
			hud.set_chip("next", "Далее: %s" % String(host.next_stop()["name"]))
	elif state["role"] == "passenger":
		hud.set_chip("next", String(city["stops"][int(state["wait_index"])]["name"]))
	hud.set_banner(player != null and state["role"] == "driver" and player.at_terminus()
		and player.speed < 0.6 and not player.doors_open)
	hud.set_reverse(reverse_gear, state["role"] == "driver" and player != null)

	if state["role"] == "passenger":
		state["dock_timer"] = float(state.get("dock_timer", 0.0)) + delta
		if float(state["dock_timer"]) > 0.4:
			state["dock_timer"] = 0.0
			if String(state["board_phase"]) == "":
				var stop: Dictionary = city["stops"][int(state["wait_index"])]
				var ready := []
				for vehicle in traffic:
					var v: Vehicle = vehicle
					if v.doors_open and v.front_position().distance_to(walk_pos) < 14.0:
						ready.append(v)
				hud.show_dock(String(stop["name"]), ready, bool(state["alga"]), state["pocket"].size(), bool(state["car"]), _errand_button())
			elif String(state["board_phase"]) == "ride":
				var host_v := _host()
				hud.show_alight(host_v != null and host_v.doors_open)
	_update_hint()


func _update_hint() -> void:
	var text := ""
	match String(state["role"]):
		"driver":
			var wheel: String = "" if player == null or player.vehicle_type == "tram" else "A/D руль · "
			text = "W/S ход и тормоз · R задний ход · %sE двери · P телефон · C кабина · Alt курсор · Esc пауза · касса %d ₽" % [
				wheel, int(state["shift_cash"])]
			if player != null and player.fleet_no > 0:
				text = "№ %d · %s · " % [player.fleet_no, String(player.condition.get("label", ""))] + text
			if player != null and player.lead_gap < 22.0:
				text = "Впереди машина, %d м — держите дистанцию · " % int(player.lead_gap) + text
		"conductor":
			text = "WASD по салону · мышь обзор · E оплата · P телефон · Alt курсор · Esc пауза · касса %d ₽" % int(state["shift_cash"])
		_:
			if bool(state["in_car"]):
				text = "WASD ход и тормоз · A/D руль · мышь камера · E выйти · P телефон · Alt курсор"
			elif String(state["board_phase"]) == "ride":
				text = "WASD по салону · мышь обзор · E выйти · P телефон и отзыв · Alt курсор · Esc пауза"
			else:
				text = "WASD тротуар и зебра · Shift бег · E посылка или посадка · P телефон · Alt курсор"
			if not errand.is_empty():
				text = "Посылка на «%s» · +%d ₽ · " % [String(errand["name"]), int(errand["pay"])] + text
	hud.set_hint(text)


func _bot_passenger() -> void:
	var phase := String(state["board_phase"])
	if phase == "":
		var stop: Dictionary = city["stops"][int(state["wait_index"])]
		for vehicle in traffic:
			var v: Vehicle = vehicle
			if v.doors_open and v.front_position().distance_to(stop["pos"]) < 26.0:
				_board(v.name)
				break
	elif phase == "pay":
		_pay_ride("cash")
	elif phase == "ride":
		print("UFA_PLAY_OK boarded album=%d wallet=%d frames=%d" % [
			state["album"].size(), int(state["wallet"]), bot_frames])
		get_tree().quit(0)
	if bot_frames > 5400:
		print("UFA_PLAY_FAIL passenger phase=%s frames=%d" % [phase, bot_frames])
		get_tree().quit(1)


func _bot_step() -> void:
	bot_frames += 1
	if state["role"] == "passenger":
		_bot_passenger()
		return
	if player == null:
		return
	if fare["open"]:
		# Робот отдаёт сдачу монетами и купюрами из Rules.DENOMS.
		var need: int = 0 if Rules.is_card(fare["tender"]) else int(fare["tender"]) - int(fare["due"])
		var rest := need
		for i in range(Rules.DENOMS.size() - 1, -1, -1):
			var denom: int = Rules.DENOMS[i]
			while rest >= denom:
				fare["pieces"].append(denom)
				rest -= denom
		_confirm_fare()
		bot_fares += 1
		return
	if state["role"] == "conductor":
		if riders.size() > 0:
			_open_fare(riders[0])
		if bot_fares >= bot_target or bot_frames > 5400:
			var done: bool = bot_fares >= bot_target
			print("UFA_PLAY_%s fares=%d rating=%d cash=%d frames=%d" % [
				"OK" if done else "FAIL", bot_fares, int(state["rating"]), int(state["shift_cash"]), bot_frames])
			get_tree().quit(0 if done else 1)
		return
	bot_max_speed = max(bot_max_speed, player.speed)
	var step := 1.0 / 30.0
	var dist := player.distance_to_next()
	bot_doors = false
	bot_timer = max(0.0, bot_timer - step)
	match bot_phase:
		"run":
			# По скользкому бот держит скорость ниже порога заноса и тормозит раньше.
			var grip: float = Rules.grip_for(player.vehicle_type, String(state["weather"]))
			var slick: bool = grip < 0.9
			var cap: float = Rules.speed_cap(player.vehicle_type, String(state["weather"])) * 0.86 if slick else 12.0
			var reach: float = 40.0 if slick else 26.0
			var target: float = cap if dist > reach else clamp((dist - 1.5) * 0.55 * (0.75 if slick else 1.0), 0.0, cap)
			if player.lead_gap < 22.0:
				target = min(target, clamp((player.lead_gap - 9.0) * 0.5, 0.0, cap))
			bot_throttle = player.speed < target
			bot_brake = player.speed > target + (1.2 if slick else 0.5)
			if dist < 6.0:
				# Последние метры добираем тормозом, иначе прокатимся мимо.
				bot_throttle = false
				bot_brake = true
			# Если встали в пробке у остановки, всё равно открываем двери.
			if dist < 13.0 and player.speed < 0.6:
				bot_doors = true
				bot_phase = "dwell"
				bot_timer = 2.0
		"dwell":
			bot_throttle = false
			bot_brake = true
			if bot_timer <= 0.0:
				bot_doors = true
				bot_phase = "depart"
				bot_timer = 6.0
		"depart":
			bot_throttle = true
			bot_brake = false
			# Полторы секунды уезжаем без оглядки, иначе залипнем на своей же остановке.
			if bot_timer <= 0.0 or (dist < 24.0 and bot_timer < 4.5):
				bot_phase = "run"
	if OS.has_environment("UFA_DEBUG_BOT") and bot_frames % 90 == 0:
		print("bot t=%.0fs phase=%s speed=%.1f dist=%.1f lead=%.1f lat=%.2f next=%s" % [
			bot_frames / 30.0, bot_phase, player.speed, dist, player.lead_gap,
			player.lateral, String(player.next_stop()["name"])])
	var served := 0
	for entry in state["rating_log"]:
		if entry["code"] in ["onTime", "late"]:
			served += 1
	bot_served = served
	if (bot_served >= bot_target and bot_max_speed > 5.0) or bot_frames > 9000:
		var ok: bool = bot_served >= bot_target and bot_max_speed > 5.0
		var codes := []
		for entry in state["rating_log"]:
			codes.append("%s%d" % [entry["code"], entry["delta"]])
		if not ok:
			print("UFA_DIAG progress=%.1f m0=%.1f m1=%.1f dir=%d lead=%.1f doors=%s phase=%s next=%s dist=%.1f" % [
				player.progress, player.m0, player.m1, player.dir, player.lead_gap,
				str(player.doors_open), bot_phase, String(player.next_stop()["name"]), player.distance_to_next()])
			for vehicle in traffic:
				var other: Vehicle = vehicle
				if other.curve != player.curve or other.dir != player.dir or absf(other.lane - player.lane) > 1.0:
					continue
				var ahead: float = (other.progress - player.progress) * float(player.dir)
				if ahead > 0.0 and ahead < 60.0:
					print("UFA_DIAG lead=%s progress=%.1f speed=%.2f dwell=%.1f m0=%.1f m1=%.1f next=%s" % [
						other.name, other.progress, other.speed, other.dwell, other.m0, other.m1,
						String(other.next_stop()["name"])])
		print("UFA_PLAY_%s speed=%.1f stops=%d rating=%d cash=%d frames=%d log=%s" % [
			"OK" if ok else "FAIL", bot_max_speed * 3.6, bot_served, int(state["rating"]),
			int(state["shift_cash"]), bot_frames, ", ".join(codes)])
		get_tree().quit(0 if ok else 1)


# Для скриншота кассы: сажаем пассажира с крупной купюрой и набираем часть сдачи.
func _shot_fare() -> void:
	if player == null:
		return
	state["role"] = "conductor"
	# Камера ещё в меню-облёте: ставим её в салон, иначе лоток окажется в небе.
	_update_camera(0.0)
	var person := City.make_person(Color(0.3, 0.36, 0.5))
	person.position = Vector3(0.3, float(Fleet.spec(player.model_id)["floor"]) + 0.06, 1.2)
	player.front().add_child(person)
	var rider := {"node": person, "tender": 500, "z": 1.2}
	riders.append(rider)
	_open_fare(rider)
	for value in [200, 200, 50, 5, 2, 1]:
		_give_piece(int(value))
	hud.show_fare(fare, player.vehicle_type)


# Для скриншота салона сажаем пассажира в ближайшую машину сразу.
func _shot_board() -> void:
	if traffic.is_empty():
		return
	var pick: Vehicle = traffic[0]
	pick.doors_open = true
	pick.door_amount = 1.0
	_board(pick.name)
	state["board_phase"] = "ride"
	hud.hide_modal()


func _frame_shot(node_name: String, back: float) -> void:
	var node := find_child(node_name, true, false)
	if node == null or not (node is Node3D):
		print("UFA_MISS %s" % node_name)
		return
	var marker := node as Node3D
	camera.global_position = marker.global_position - marker.global_transform.basis.z * back + Vector3(0, 1.4, 0)
	camera.look_at(marker.global_position, Vector3.UP)


func _take_shot() -> void:
	shot_timer = -1.0
	if shot_path.ends_with("sign.png"):
		_frame_shot("SignBoard", 5.5)
	elif shot_path.ends_with("fleet.png"):
		_frame_shot("FleetPlate", 3.2)
	elif shot_path.ends_with("cross.png"):
		_frame_shot("Junction", 22.0)
	elif shot_path.ends_with("office.png"):
		_frame_shot("TicketOffice", 8.0)
	if OS.has_environment("UFA_DEBUG_CASH"):
		print("cash bodies=%d desk=%s" % [fare_bodies.size(),
			str(fare_desk.global_position) if fare_desk != null else "nil"])
		for body in fare_bodies:
			if is_instance_valid(body):
				print("  %s at %s sleeping=%s" % [body.name, str((body as Node3D).global_position),
					str((body as RigidBody3D).sleeping)])
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	image.save_png(shot_path)
	print("UFA_SHOT %s" % shot_path)
	get_tree().quit()
