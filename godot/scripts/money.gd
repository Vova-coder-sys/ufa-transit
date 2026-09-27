class_name Money
extends RefCounted

# Наличные как физика: каждая монета и каждая купюра — отдельное тело
# с коллизией. Кондуктор набирает сдачу в лоток, а не жмёт цифры в меню.

const COIN_VALUES := [1, 2, 5, 10]
const NOTE_VALUES := [50, 100, 200, 500, 1000]

# Размеры настоящие: рубль 20 мм, пятёрка 25 мм, купюра 150×65 мм.
const COIN_SPEC := {
	1: {"r": 0.0103, "h": 0.0025, "face": Color(0.78, 0.79, 0.81), "edge": Color(0.62, 0.63, 0.66)},
	2: {"r": 0.0115, "h": 0.0027, "face": Color(0.76, 0.77, 0.8), "edge": Color(0.6, 0.61, 0.64)},
	5: {"r": 0.0125, "h": 0.0030, "face": Color(0.74, 0.75, 0.78), "edge": Color(0.58, 0.59, 0.62)},
	10: {"r": 0.0110, "h": 0.0026, "face": Color(0.85, 0.7, 0.32), "edge": Color(0.66, 0.53, 0.22)},
}

const NOTE_SPEC := {
	50: {"paper": Color(0.86, 0.9, 0.94), "ink": Color(0.24, 0.42, 0.66), "city": "СПЕТЕРБУРГ"},
	100: {"paper": Color(0.93, 0.89, 0.8), "ink": Color(0.52, 0.42, 0.26), "city": "МОСКВА"},
	200: {"paper": Color(0.86, 0.93, 0.87), "ink": Color(0.2, 0.5, 0.33), "city": "СЕВАСТОПОЛЬ"},
	500: {"paper": Color(0.9, 0.87, 0.93), "ink": Color(0.42, 0.3, 0.56), "city": "АРХАНГЕЛЬСК"},
	1000: {"paper": Color(0.87, 0.92, 0.91), "ink": Color(0.18, 0.44, 0.44), "city": "ЯРОСЛАВЛЬ"},
}

const NOTE_W := 0.15
const NOTE_D := 0.065
const NOTE_H := 0.0016

static var _note_tex := {}
static var _coin_tex := {}


static func is_coin(value: int) -> bool:
	return value in COIN_VALUES


static func denominations() -> Array:
	var list := []
	list.append_array(COIN_VALUES)
	list.append_array(NOTE_VALUES)
	return list


# Набор для сдачи: жадно, крупными номиналами.
static func split(amount: int) -> Array:
	var rest := amount
	var out := []
	var all := denominations()
	for i in range(all.size() - 1, -1, -1):
		var denom: int = int(all[i])
		while rest >= denom:
			out.append(denom)
			rest -= denom
	return out


# --- текстуры -----------------------------------------------------------

static func _note_texture(value: int) -> ImageTexture:
	if _note_tex.has(value):
		return _note_tex[value]
	var spec: Dictionary = NOTE_SPEC[value]
	var paper: Color = spec["paper"]
	var ink: Color = spec["ink"]
	var w := 192
	var h := 96
	var img := Image.create_empty(w, h, true, Image.FORMAT_RGBA8)
	var noise := FastNoiseLite.new()
	noise.seed = value
	noise.frequency = 0.08
	for y in h:
		for x in w:
			var fx := float(x) / float(w)
			var fy := float(y) / float(h)
			var c := paper
			# Гильош: концентрические волны от центра плюс косая сетка.
			var dx := (fx - 0.5) * 2.0
			var dy := (fy - 0.5) * 2.0
			var rad: float = sqrt(dx * dx + dy * dy)
			var guilloche: float = 0.5 + 0.5 * sin(rad * 46.0 + float(value))
			var grid: float = 0.5 + 0.5 * sin((fx * 90.0 + fy * 52.0))
			var pattern: float = guilloche * 0.55 + grid * 0.2
			c = c.lerp(ink, pattern * 0.3)
			# Купонное поле слева под водяной знак и полоса справа.
			if fx < 0.26:
				c = c.lerp(paper.lightened(0.18), 0.55)
			if fx > 0.9:
				c = c.lerp(ink, 0.45)
			# Рамка.
			if fx < 0.03 or fx > 0.97 or fy < 0.05 or fy > 0.95:
				c = c.lerp(ink, 0.7)
			c = c.lightened(noise.get_noise_2d(float(x), float(y)) * 0.05)
			img.set_pixel(x, y, Color(c.r, c.g, c.b, 1.0))
	img.generate_mipmaps()
	var tex := ImageTexture.create_from_image(img)
	_note_tex[value] = tex
	return tex


static func _coin_texture(value: int) -> ImageTexture:
	if _coin_tex.has(value):
		return _coin_tex[value]
	var spec: Dictionary = COIN_SPEC[value]
	var face: Color = spec["face"]
	var size := 96
	var img := Image.create_empty(size, size, true, Image.FORMAT_RGBA8)
	for y in size:
		for x in size:
			var dx := (float(x) / size - 0.5) * 2.0
			var dy := (float(y) / size - 0.5) * 2.0
			var rad: float = sqrt(dx * dx + dy * dy)
			var c := face
			# Кольцевой рант и радиальные насечки по краю.
			if rad > 0.86:
				var teeth: float = 0.5 + 0.5 * sin(atan2(dy, dx) * 60.0)
				c = face.darkened(0.16 + teeth * 0.18)
			elif rad > 0.78:
				c = face.darkened(0.1)
			else:
				c = face.lightened(0.06 * sin(rad * 18.0))
			img.set_pixel(x, y, Color(c.r, c.g, c.b, 1.0))
	img.generate_mipmaps()
	var tex := ImageTexture.create_from_image(img)
	_coin_tex[value] = tex
	return tex


# --- тела ---------------------------------------------------------------

static func _digits(value: int, size: float, color: Color) -> Label3D:
	var node := Label3D.new()
	node.text = str(value)
	node.font_size = 64
	node.pixel_size = size / 64.0
	node.modulate = color
	node.outline_size = 0
	node.double_sided = false
	node.no_depth_test = false
	node.rotation_degrees = Vector3(-90, 0, 0)
	return node


static func coin_visual(value: int) -> Node3D:
	var spec: Dictionary = COIN_SPEC[value]
	var root := Node3D.new()
	root.name = "Coin%d" % value
	var r: float = float(spec["r"])
	var thick: float = float(spec["h"])
	var mesh := CylinderMesh.new()
	mesh.top_radius = r
	mesh.bottom_radius = r
	mesh.height = thick
	mesh.radial_segments = 28
	mesh.rings = 1
	var mat := MeshLib.mat(Color(1, 1, 1), 0.34, 0.82)
	mat.albedo_texture = _coin_texture(value)
	root.add_child(MeshLib.mesh_node(mesh, mat, "Disc"))
	var ink: Color = Color(0.2, 0.18, 0.14) if value == 10 else Color(0.24, 0.25, 0.28)
	for side in [1.0, -1.0]:
		var text := _digits(value, r * 0.9, ink)
		text.position = Vector3(0, (thick * 0.5 + 0.0012) * side, 0)
		if side < 0.0:
			text.rotation_degrees = Vector3(90, 0, 0)
		root.add_child(text)
	return root


static func note_visual(value: int) -> Node3D:
	var spec: Dictionary = NOTE_SPEC[value]
	var root := Node3D.new()
	root.name = "Note%d" % value
	var mesh := BoxMesh.new()
	mesh.size = Vector3(NOTE_W, NOTE_H * 0.5, NOTE_D)
	var mat := MeshLib.mat(Color(1, 1, 1), 0.74)
	mat.albedo_texture = _note_texture(value)
	root.add_child(MeshLib.mesh_node(mesh, mat, "Paper"))
	var ink: Color = spec["ink"]
	for side in [1.0, -1.0]:
		var text := _digits(value, NOTE_D * 0.42, ink)
		# Отступ от бумаги больше её толщины: иначе цифры дерутся за глубину
		# с обратной стороной и читаются зеркально.
		text.position = Vector3(NOTE_W * 0.22, 0.0014 * side, 0)
		if side < 0.0:
			text.rotation_degrees = Vector3(90, 0, 0)
		root.add_child(text)
		var city := Label3D.new()
		city.text = String(spec["city"])
		city.font_size = 64
		city.pixel_size = NOTE_D * 0.06 / 64.0 * 6.0
		city.modulate = ink
		city.outline_size = 0
		city.double_sided = false
		city.position = Vector3(-NOTE_W * 0.16, 0.0014 * side, NOTE_D * 0.3)
		city.rotation_degrees = Vector3(-90 * side, 0, 0)
		root.add_child(city)
	return root


static func visual(value: int) -> Node3D:
	return coin_visual(value) if is_coin(value) else note_visual(value)


# Физическое тело одной монеты или купюры.
static func piece(value: int) -> RigidBody3D:
	var body := RigidBody3D.new()
	body.name = "Cash%d" % value
	body.set_meta("value", value)
	body.mass = 0.02 if is_coin(value) else 0.006
	body.continuous_cd = true
	body.contact_monitor = false
	body.can_sleep = true
	var phys := PhysicsMaterial.new()
	phys.friction = 0.85 if is_coin(value) else 1.0
	phys.bounce = 0.12 if is_coin(value) else 0.0
	body.physics_material_override = phys
	var shape := CollisionShape3D.new()
	if is_coin(value):
		var spec: Dictionary = COIN_SPEC[value]
		var cyl := CylinderShape3D.new()
		cyl.radius = float(spec["r"])
		cyl.height = maxf(float(spec["h"]), 0.004)
		shape.shape = cyl
		body.angular_damp = 3.5
	else:
		var box := BoxShape3D.new()
		box.size = Vector3(NOTE_W, 0.008, NOTE_D)
		shape.shape = box
		body.angular_damp = 6.0
		body.linear_damp = 1.4
	body.add_child(shape)
	body.add_child(visual(value))
	return body


# --- лоток и касса ------------------------------------------------------

static func tray(size := Vector2(0.34, 0.24)) -> Node3D:
	var root := StaticBody3D.new()
	root.name = "Tray"
	var wood := MeshLib.mat(Color(0.2, 0.22, 0.26), 0.55, 0.2)
	var felt := MeshLib.mat(Color(0.12, 0.26, 0.2), 0.95)
	var wall := 0.018
	var parts := [
		# Дно делаем толстым: по тонкому статичному щиту монеты проскакивают.
		[Vector3(size.x, 0.05, size.y), Vector3(0, -0.025, 0), felt],
		[Vector3(size.x + wall * 2.0, 0.042, wall), Vector3(0, 0.015, -size.y * 0.5 - wall * 0.5), wood],
		[Vector3(size.x + wall * 2.0, 0.042, wall), Vector3(0, 0.015, size.y * 0.5 + wall * 0.5), wood],
		[Vector3(wall, 0.042, size.y), Vector3(-size.x * 0.5 - wall * 0.5, 0.015, 0), wood],
		[Vector3(wall, 0.042, size.y), Vector3(size.x * 0.5 + wall * 0.5, 0.015, 0), wood],
	]
	for part in parts:
		var box_size: Vector3 = part[0]
		var pos: Vector3 = part[1]
		root.add_child(MeshLib.box(box_size, pos, part[2], "Panel"))
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = box_size
		shape.shape = box
		shape.position = pos
		root.add_child(shape)
	return root


# Касса кондуктора: визуальные стопки по номиналам, из них берут пачками.
static func drawer(values: Array) -> Node3D:
	var root := Node3D.new()
	root.name = "Drawer"
	var frame := MeshLib.mat(Color(0.16, 0.18, 0.22), 0.6, 0.25)
	var pitch := 0.085
	var width: float = float(values.size()) * pitch
	root.add_child(MeshLib.box(Vector3(width, 0.014, 0.1), Vector3(0, -0.007, 0), frame, "Base"))
	for i in values.size():
		var value: int = int(values[i])
		var x: float = -width * 0.5 + pitch * 0.5 + pitch * float(i)
		root.add_child(MeshLib.box(Vector3(0.004, 0.026, 0.1),
			Vector3(x + pitch * 0.5, 0.007, 0), frame, "Rib"))
		var stack := Node3D.new()
		stack.position = Vector3(x, 0.002, 0)
		for k in 3:
			var item := visual(value)
			item.position = Vector3(0, float(k) * (0.003 if is_coin(value) else 0.0018), -0.004 * float(k))
			item.rotation.y = 0.05 * float(k)
			if not is_coin(value):
				item.scale = Vector3(0.5, 1.0, 0.98)
			stack.add_child(item)
		root.add_child(stack)
		var tag := MeshLib.label("%d" % value, 40, Color(0.95, 0.85, 0.5))
		tag.position = Vector3(x, 0.014, 0.056)
		tag.rotation_degrees = Vector3(-62, 0, 0)
		tag.pixel_size = 0.0004
		root.add_child(tag)
	return root
