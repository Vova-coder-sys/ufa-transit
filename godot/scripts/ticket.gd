class_name TicketArt
extends RefCounted

# Билет — не строчка в меню, а кассовый чек: бумажная лента с реквизитами,
# которую печатает валидатор. Она же лежит на остановках как потерянный билет.

const PAPER := Color(0.96, 0.95, 0.91)
const PRINT := Color(0.16, 0.17, 0.2)
const WIDTH := 0.19


static func serial(rng: RandomNumberGenerator) -> String:
	return "%06d" % rng.randi_range(1, 999999)


static func make(vehicle_title: String, vehicle_type: String, route_number: String,
		operator: String, stop_name: String, clock: String, fare: int, method: String,
		tender: int, change: int, rng: RandomNumberGenerator) -> Dictionary:
	return {
		"model": vehicle_title,
		"type": vehicle_type,
		"route": route_number,
		"operator": operator,
		"stop": stop_name,
		"clock": clock,
		"fare": fare,
		"method": method,
		"tender": tender,
		"change": change,
		"serial": serial(rng),
		"board": "%d-%02d" % [rng.randi_range(1001, 2999), rng.randi_range(1, 99)],
		"date": "%02d.%02d.2026" % [rng.randi_range(1, 28), rng.randi_range(4, 9)],
	}


static func lines(data: Dictionary) -> String:
	var kind: String = Rules.TYPE_LABEL.get(String(data.get("type", "bus")), "ПРОЕЗД").to_upper()
	var method: String = String(data.get("method", "cash"))
	var fare: int = int(data.get("fare", 0))
	var rows := [
		String(data.get("operator", "БАШАВТОТРАНС")).to_upper(),
		"ГОРОД УФА",
		"------------------------",
		"%s  МАРШРУТ %s" % [kind, String(data.get("route", "0"))],
		String(data.get("model", "")),
		"БОРТ %s" % String(data.get("board", "0000-00")),
		"ОСТ. %s" % String(data.get("stop", "")).to_upper(),
		"------------------------",
		"ПРОЕЗД %s%.2f" % [_pad(11 - 6, fare), float(fare)],
		"В Т.Ч. НДС 20%%%s%.2f" % [_gap(4), float(fare) * 0.1667],
	]
	if method == "alga":
		rows.append("КАРТА АЛГА%s%.2f" % [_gap(6), float(fare)])
	else:
		rows.append("НАЛИЧНЫЕ%s%.2f" % [_gap(8), float(data.get("tender", fare))])
		rows.append("СДАЧА%s%.2f" % [_gap(11), float(data.get("change", 0))])
	rows.append("------------------------")
	rows.append("ЧЕК № %s" % String(data.get("serial", "000000")))
	rows.append("%s  %s" % [String(data.get("date", "")), String(data.get("clock", ""))])
	rows.append("СПАСИБО ЗА ПОЕЗДКУ")
	rows.append("|| ||| | ||| || | ||||")
	return "\n".join(rows)


static func _pad(_slots: int, _value: int) -> String:
	return "        "


static func _gap(count: int) -> String:
	var out := ""
	for _i in count:
		out += " "
	return out


# Бумажный чек в 3D: лента с печатью, слегка помятая.
static func paper(data: Dictionary, scale_factor := 1.0) -> Node3D:
	var root := Node3D.new()
	root.name = "Receipt"
	var text := lines(data)
	var rows: int = text.split("\n").size()
	var height: float = 0.016 * float(rows) + 0.03
	var mesh := BoxMesh.new()
	mesh.size = Vector3(WIDTH, 0.0012, height)
	var mat := MeshLib.mat(PAPER, 0.88)
	mat.albedo_texture = _paper_texture()
	var sheet := MeshLib.mesh_node(mesh, mat, "Sheet")
	root.add_child(sheet)
	var label := Label3D.new()
	label.text = text
	label.font_size = 40
	label.pixel_size = 0.00036
	label.modulate = PRINT
	label.outline_size = 0
	label.double_sided = false
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.line_spacing = 2.0
	label.position = Vector3(0, 0.0012, 0)
	label.rotation_degrees = Vector3(-90, 0, 0)
	root.add_child(label)
	root.scale = Vector3(scale_factor, scale_factor, scale_factor)
	return root


static var _paper_tex: ImageTexture = null


static func _paper_texture() -> ImageTexture:
	if _paper_tex != null:
		return _paper_tex
	var size := 64
	var img := Image.create_empty(size, size, true, Image.FORMAT_RGBA8)
	var noise := FastNoiseLite.new()
	noise.seed = 21
	noise.frequency = 0.18
	for y in size:
		for x in size:
			var n: float = noise.get_noise_2d(float(x), float(y)) * 0.04
			var c := PAPER.lightened(n)
			# Края термобумаги темнее: лента подвыгорела.
			var edge: float = min(float(x), float(size - 1 - x)) / float(size)
			if edge < 0.06:
				c = c.darkened(0.12)
			img.set_pixel(x, y, Color(c.r, c.g, c.b, 1.0))
	img.generate_mipmaps()
	_paper_tex = ImageTexture.create_from_image(img)
	return _paper_tex


# Потерянный билет на остановке: смятый обрывок, который можно подобрать.
static func litter(data: Dictionary, rng: RandomNumberGenerator) -> Node3D:
	var root := Node3D.new()
	root.name = "LostTicket"
	var sheet := paper(data, 1.2)
	sheet.rotation_degrees = Vector3(rng.randf_range(-6.0, 6.0), rng.randf_range(0.0, 360.0), rng.randf_range(-5.0, 5.0))
	root.add_child(sheet)
	return root


# --- альбом -------------------------------------------------------------

static func album_card(data: Dictionary, width := 268) -> PanelContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = PAPER
	style.border_color = Color(0.72, 0.7, 0.64)
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	panel.add_theme_stylebox_override("panel", style)
	panel.custom_minimum_size = Vector2(width, 0)
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 1)
	for row in lines(data).split("\n"):
		var l := Label.new()
		l.text = String(row)
		l.add_theme_font_size_override("font_size", 12)
		l.add_theme_color_override("font_color", PRINT)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		body.add_child(l)
	panel.add_child(body)
	return panel
