class_name MeshLib
extends RefCounted

# Процедурная геометрия: кузова лофтом по сечению, колёса, стёкла, текстуры.


static func mat(color: Color, roughness := 0.65, metallic := 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = roughness
	m.metallic = metallic
	return m


static var _pbr_normal: ImageTexture
static var _pbr_rough: ImageTexture


static func _ensure_pbr() -> void:
	if _pbr_normal != null:
		return
	# Общий PBR-набор кузова: нормаль и шероховатость 1024², один раз на сессию.
	_pbr_normal = noise_normal(1.6, 0.11, 11, 1024)
	var rough := noise_image(1024, 1024, Color(0.42, 0.42, 0.42), 0.35, 0.04, 19)
	_pbr_rough = texture_from(rough)


static func paint(color: Color) -> StandardMaterial3D:
	var m := mat(color, 0.38, 0.08)
	m.set_feature(BaseMaterial3D.FEATURE_CLEARCOAT, true)
	m.clearcoat = 0.55
	m.clearcoat_roughness = 0.16
	_ensure_pbr()
	m.normal_enabled = true
	m.normal_texture = _pbr_normal
	m.roughness_texture = _pbr_rough
	return m


static func glass(tint := Color(0.1, 0.14, 0.18), alpha := 0.62) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(tint.r, tint.g, tint.b, alpha)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	# Металличность стекла делает из окон синее зеркало, поэтому почти ноль.
	m.roughness = 0.14
	m.metallic = 0.04
	m.specular_mode = BaseMaterial3D.SPECULAR_SCHLICK_GGX
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m


static func emissive(color: Color, energy := 2.0) -> StandardMaterial3D:
	var m := mat(color, 0.4, 0.0)
	m.emission_enabled = true
	m.emission = color
	m.emission_energy_multiplier = energy
	return m


# --- сечение кузова -----------------------------------------------------

static func rounded_profile(half_w: float, y0: float, y1: float, r_bottom: float, r_top: float, steps := 6, tumble := 0.0) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var rb: float = min(r_bottom, min(half_w, (y1 - y0) * 0.5))
	var rt: float = min(r_top, min(half_w, (y1 - y0) * 0.5))
	for i in steps + 1:
		var a: float = lerp(-PI * 0.5, 0.0, float(i) / steps)
		pts.append(Vector2(half_w - rb + cos(a) * rb, y0 + rb + sin(a) * rb))
	for i in steps + 1:
		var a: float = lerp(0.0, PI * 0.5, float(i) / steps)
		pts.append(Vector2(half_w - rt + cos(a) * rt, y1 - rt + sin(a) * rt))
	for i in steps + 1:
		var a: float = lerp(PI * 0.5, PI, float(i) / steps)
		pts.append(Vector2(-half_w + rt + cos(a) * rt, y1 - rt + sin(a) * rt))
	for i in steps + 1:
		var a: float = lerp(PI, PI * 1.5, float(i) / steps)
		pts.append(Vector2(-half_w + rb + cos(a) * rb, y0 + rb + sin(a) * rb))
	if tumble > 0.0:
		var out := PackedVector2Array()
		for p in pts:
			var k: float = clamp((p.y - y0) / max(0.001, y1 - y0), 0.0, 1.0)
			out.append(Vector2(p.x * (1.0 - tumble * k * k), p.y))
		pts = out
	return pts


static func insert_levels(profile: PackedVector2Array, levels: Array, max_edge := 0.42) -> PackedVector2Array:
	# Врезает точки на заданных высотах и дробит длинные прямые борта.
	var out := PackedVector2Array()
	var count := profile.size()
	for i in count:
		var a := profile[i]
		var b := profile[(i + 1) % count]
		out.append(a)
		var extra := []
		for level in levels:
			var y := float(level)
			if (a.y - y) * (b.y - y) < 0.0:
				var t: float = (y - a.y) / (b.y - a.y)
				extra.append(a.lerp(b, t))
		var span := a.distance_to(b)
		if span > max_edge:
			var parts := int(ceil(span / max_edge))
			for k in range(1, parts):
				extra.append(a.lerp(b, float(k) / parts))
		extra.sort_custom(func(p, q): return a.distance_squared_to(p) < a.distance_squared_to(q))
		for p in extra:
			if out[out.size() - 1].distance_to(p) > 0.004 and b.distance_to(p) > 0.004:
				out.append(p)
	return out


static func _end_blend(k: float, curve: String) -> float:
	# 0 — остриё маски, 1 — полный борт. Форма взята с фото: плоский НефАЗ, круг Татры, капот ГАЗели.
	match curve:
		"circle":
			return sqrt(maxf(0.0, 1.0 - (1.0 - k) * (1.0 - k)))
		"flat":
			return pow(k, 0.22)
		"slab":
			# Почти отвесный торец: КТМ-5, НефАЗ, Икарус.
			return 1.0 if k > 0.12 else k / 0.12
		"hood":
			return k * k * (3.0 - 2.0 * k)
		_:
			return sin(k * PI * 0.5)


static func stations(length: float, nose: Dictionary, tail: Dictionary, steps := 5) -> Array:
	# Станции лофта от носа (-Z) к корме (+Z) со скруглением и наклоном стёкол.
	var list := []
	var half := length * 0.5
	var nose_len: float = nose.get("len", 0.45)
	var tail_len: float = tail.get("len", 0.45)
	var nose_curve := String(nose.get("curve", "soft"))
	for i in steps + 1:
		var k: float = float(i) / steps
		var soft: float = _end_blend(k, nose_curve)
		list.append({
			"z": -half + nose_len * k,
			"sx": lerp(float(nose.get("sx", 0.72)), 1.0, soft),
			"sy": lerp(float(nose.get("sy", 0.86)), 1.0, soft),
			"dy": lerp(float(nose.get("dy", 0.04)), 0.0, soft),
			"shear": lerp(float(nose.get("shear", 0.0)), 0.0, soft),
		})
	list.append({"z": -half + nose_len + 0.001, "sx": 1.0, "sy": 1.0, "dy": 0.0, "shear": 0.0})
	list.append({"z": half - tail_len - 0.001, "sx": 1.0, "sy": 1.0, "dy": 0.0, "shear": 0.0})
	var tail_curve := String(tail.get("curve", "soft"))
	for i in steps + 1:
		var k: float = float(i) / steps
		var soft: float = _end_blend(1.0 - k, tail_curve)
		list.append({
			"z": half - tail_len + tail_len * k,
			"sx": lerp(float(tail.get("sx", 0.78)), 1.0, soft),
			"sy": lerp(float(tail.get("sy", 0.9)), 1.0, soft),
			"dy": lerp(float(tail.get("dy", 0.02)), 0.0, soft),
			"shear": lerp(float(tail.get("shear", 0.0)), 0.0, soft),
		})
	return list


static func _station_point(profile: PackedVector2Array, index: int, st: Dictionary, y0: float, y1: float) -> Vector3:
	var p := profile[index]
	var k: float = clamp((p.y - y0) / max(0.001, y1 - y0), 0.0, 1.0)
	return Vector3(
		p.x * float(st["sx"]),
		p.y * float(st["sy"]) + float(st["dy"]),
		float(st["z"]) + float(st.get("shear", 0.0)) * k
	)


static func loft(profile: PackedVector2Array, station_list: Array, y0: float, y1: float, caps := true) -> ArrayMesh:
	var rows := station_list.size()
	var cols := profile.size()
	var grid := []
	for k in rows:
		var row := []
		for i in cols:
			row.append(_station_point(profile, i, station_list[k], y0, y1))
		grid.append(row)

	var centers := []
	for k in rows:
		var c := Vector3.ZERO
		for i in cols:
			c += grid[k][i]
		centers.append(c / float(cols))

	var normals := []
	for k in rows:
		var row := []
		for i in cols:
			var kp: int = min(k + 1, rows - 1)
			var km: int = max(k - 1, 0)
			var ip: int = (i + 1) % cols
			var im: int = (i - 1 + cols) % cols
			var dv: Vector3 = grid[kp][i] - grid[km][i]
			var du: Vector3 = grid[k][ip] - grid[k][im]
			var n: Vector3 = du.cross(dv)
			var outward: Vector3 = grid[k][i] - centers[k]
			outward.z = 0.0
			if n.length() < 0.00001:
				n = outward
			n = n.normalized()
			if outward.length() > 0.0001 and n.dot(outward.normalized()) < 0.0:
				n = -n
			row.append(n)
		normals.append(row)

	var lengths := [0.0]
	var total := 0.0
	for i in cols:
		total += profile[i].distance_to(profile[(i + 1) % cols])
		lengths.append(total)

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var span: float = max(0.001, float(station_list[rows - 1]["z"]) - float(station_list[0]["z"]))
	for k in rows - 1:
		var v0: float = (float(station_list[k]["z"]) - float(station_list[0]["z"])) / span
		var v1: float = (float(station_list[k + 1]["z"]) - float(station_list[0]["z"])) / span
		for i in cols:
			var ip: int = (i + 1) % cols
			var u0: float = lengths[i] / total
			var u1: float = lengths[i + 1] / total
			_quad(st,
				grid[k][i], grid[k][ip], grid[k + 1][ip], grid[k + 1][i],
				normals[k][i], normals[k][ip], normals[k + 1][ip], normals[k + 1][i],
				Vector2(u0, v0), Vector2(u1, v0), Vector2(u1, v1), Vector2(u0, v1))
	if caps:
		fan(st, grid[0], Vector3(0, 0, -1), true)
		fan(st, grid[rows - 1], Vector3(0, 0, 1), false)
	st.generate_tangents()
	return st.commit()


static func level_at(st_data: Dictionary, y: float) -> float:
	return y * float(st_data["sy"]) + float(st_data["dy"])


static func ring_of(profile: PackedVector2Array, st_data: Dictionary, y0: float, y1: float) -> Array:
	var ring := []
	for i in profile.size():
		ring.append(_station_point(profile, i, st_data, y0, y1))
	return ring


static func fan(st: SurfaceTool, poly: Array, normal: Vector3, front: bool) -> void:
	# poly обходится против часовой в плоскости XY, front даёт нормаль -Z.
	var count := poly.size()
	if count < 3:
		return
	var center := Vector3.ZERO
	for p in poly:
		center += p
	center /= float(count)
	for i in count:
		var a: Vector3 = poly[i]
		var b: Vector3 = poly[(i + 1) % count]
		if front:
			_tri(st, center, a, b, normal)
		else:
			_tri(st, center, b, a, normal)


static func _lerp_point(a: Vector3, b: Vector3, y: float) -> Vector3:
	var span: float = b.y - a.y
	if absf(span) < 0.00001:
		return a
	return a.lerp(b, clamp((y - a.y) / span, 0.0, 1.0))


static func cap_with_window(ring: Array, band_low: float, band_high: float, front: bool) -> Array:
	# Торец кузова: глухие панели снизу и сверху плюс стекло в поясе окон.
	var count := ring.size()
	var aug := []
	for i in count:
		var a: Vector3 = ring[i]
		var b: Vector3 = ring[(i + 1) % count]
		aug.append(a)
		var cuts := []
		for level in [band_low, band_high]:
			if (a.y - level) * (b.y - level) < 0.0:
				cuts.append(_lerp_point(a, b, level))
		cuts.sort_custom(func(p, q): return a.distance_to(p) < a.distance_to(q))
		for c in cuts:
			aug.append(c)

	var low_poly := _cyclic_run(aug, func(p): return p.y <= band_low + 0.0005)
	var high_poly := _cyclic_run(aug, func(p): return p.y >= band_high - 0.0005)

	var corners := []
	for p in aug:
		if absf(p.y - band_low) < 0.0006 or absf(p.y - band_high) < 0.0006:
			corners.append(p)

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var normal := Vector3(0, 0, -1) if front else Vector3(0, 0, 1)
	fan(st, low_poly, normal, front)
	fan(st, high_poly, normal, front)
	st.generate_tangents()
	var solid: ArrayMesh = st.commit()

	var glass_mesh: ArrayMesh = null
	if OS.has_environment("UFA_DEBUG_CAP"):
		print("cap aug=%d low=%d high=%d corners=%d" % [aug.size(), low_poly.size(), high_poly.size(), corners.size()])
		for p in aug:
			if absf(p.y - band_low) < 0.02 or absf(p.y - band_high) < 0.02:
				print("  near level: ", p)
	if corners.size() >= 4:
		var lows := []
		var highs := []
		for p in corners:
			if p.y < (band_low + band_high) * 0.5:
				lows.append(p)
			else:
				highs.append(p)
		if lows.size() >= 2 and highs.size() >= 2:
			lows.sort_custom(func(p, q): return p.x > q.x)
			highs.sort_custom(func(p, q): return p.x > q.x)
			# против часовой в плоскости XY: правый низ, правый верх, левый верх, левый низ
			var poly := [lows[0], highs[0], highs[highs.size() - 1], lows[lows.size() - 1]]
			var gst := SurfaceTool.new()
			gst.begin(Mesh.PRIMITIVE_TRIANGLES)
			fan(gst, poly, normal, front)
			gst.generate_tangents()
			glass_mesh = gst.commit()
	return [solid, glass_mesh]


static func _cyclic_run(points: Array, predicate: Callable) -> Array:
	var count := points.size()
	var start := -1
	for i in count:
		var prev: int = (i - 1 + count) % count
		if predicate.call(points[i]) and not predicate.call(points[prev]):
			start = i
			break
	if start < 0:
		var all_in := []
		for p in points:
			if predicate.call(p):
				all_in.append(p)
		return all_in
	var run := []
	for step in count:
		var idx: int = (start + step) % count
		if not predicate.call(points[idx]):
			break
		run.append(points[idx])
	return run


static func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, n: Vector3) -> void:
	st.set_normal(n)
	st.set_uv(Vector2(a.x, a.y))
	st.add_vertex(a)
	st.set_normal(n)
	st.set_uv(Vector2(b.x, b.y))
	st.add_vertex(b)
	st.set_normal(n)
	st.set_uv(Vector2(c.x, c.y))
	st.add_vertex(c)


static func _quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3,
		na: Vector3, nb: Vector3, nc: Vector3, nd: Vector3,
		ua: Vector2, ub: Vector2, uc: Vector2, ud: Vector2) -> void:
	# Godot ждёт обход по часовой стрелке со стороны лицевой грани.
	_vert(st, a, na, ua)
	_vert(st, c, nc, uc)
	_vert(st, b, nb, ub)
	_vert(st, a, na, ua)
	_vert(st, d, nd, ud)
	_vert(st, c, nc, uc)


static func _vert(st: SurfaceTool, p: Vector3, n: Vector3, uv: Vector2) -> void:
	st.set_normal(n)
	st.set_uv(uv)
	st.add_vertex(p)


static func band_runs(profile: PackedVector2Array, y_low: float, y_high: float) -> Array:
	var runs := []
	var current := []
	for i in profile.size():
		var inside: bool = profile[i].y >= y_low - 0.002 and profile[i].y <= y_high + 0.002
		if inside:
			current.append(i)
		elif current.size() > 1:
			runs.append(current)
			current = []
		else:
			current = []
	if current.size() > 1:
		runs.append(current)
	return runs


static func band_mesh(profile: PackedVector2Array, station_list: Array, run: Array, y0: float, y1: float, swell := 1.012) -> ArrayMesh:
	# Открытая полоса кузова по части сечения: борт, юбка, пояс окон.
	var rows := station_list.size()
	var cols := run.size()
	if cols < 2 or rows < 2:
		return ArrayMesh.new()
	var grid := []
	for k in rows:
		var row := []
		for j in cols:
			var p: Vector3 = _station_point(profile, run[j], station_list[k], y0, y1)
			row.append(Vector3(p.x * swell, p.y, p.z))
		grid.append(row)

	var centers := []
	for k in rows:
		centers.append(Vector3(0.0, (y0 + y1) * 0.5, float(station_list[k]["z"])))

	var normals := []
	for k in rows:
		var row := []
		for j in cols:
			var kp: int = min(k + 1, rows - 1)
			var km: int = max(k - 1, 0)
			var jp: int = min(j + 1, cols - 1)
			var jm: int = max(j - 1, 0)
			var dv: Vector3 = grid[kp][j] - grid[km][j]
			var du: Vector3 = grid[k][jp] - grid[k][jm]
			var n: Vector3 = du.cross(dv)
			var outward: Vector3 = grid[k][j] - centers[k]
			outward.z = 0.0
			if n.length() < 0.00001:
				n = outward
			n = n.normalized()
			if outward.length() > 0.0001 and n.dot(outward.normalized()) < 0.0:
				n = -n
			row.append(n)
		normals.append(row)

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for k in rows - 1:
		var v0: float = float(k) / (rows - 1)
		var v1: float = float(k + 1) / (rows - 1)
		for j in cols - 1:
			var u0: float = float(j) / (cols - 1)
			var u1: float = float(j + 1) / (cols - 1)
			_quad(st, grid[k][j], grid[k][j + 1], grid[k + 1][j + 1], grid[k + 1][j],
				normals[k][j], normals[k][j + 1], normals[k + 1][j + 1], normals[k + 1][j],
				Vector2(u0, v0), Vector2(u1, v0), Vector2(u1, v1), Vector2(u0, v1))
	st.generate_tangents()
	return st.commit()


# --- готовые узлы -------------------------------------------------------

static func strip(left: Array, right: Array, uv_repeat := 1.0) -> ArrayMesh:
	# Плоская лента по земле: нормаль вверх.
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var count: int = min(left.size(), right.size())
	for i in count - 1:
		var v0: float = float(i) * uv_repeat
		var v1: float = float(i + 1) * uv_repeat
		var n: Vector3 = (left[i] - right[i]).cross(right[i + 1] - right[i])
		if n.length_squared() < 0.000001:
			n = Vector3.UP
		else:
			n = n.normalized()
		if n.y < 0.0:
			n = -n
		_quad(st, right[i], left[i], left[i + 1], right[i + 1], n, n, n, n,
			Vector2(1, v0), Vector2(0, v0), Vector2(0, v1), Vector2(1, v1))
	st.generate_tangents()
	return st.commit()


static func wall(bottom: Array, top: Array, flip := false) -> ArrayMesh:
	# Вертикальная лента: бордюр, парапет, борт платформы.
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var count: int = min(bottom.size(), top.size())
	for i in count - 1:
		var b0: Vector3 = bottom[i]
		var b1: Vector3 = bottom[i + 1]
		var t0: Vector3 = top[i]
		var t1: Vector3 = top[i + 1]
		var n: Vector3 = (b1 - b0).cross(t0 - b0).normalized()
		if flip:
			n = -n
		var u0 := float(i) * 0.25
		var u1 := float(i + 1) * 0.25
		if flip:
			_quad(st, b0, t0, t1, b1, n, n, n, n, Vector2(u0, 1), Vector2(u0, 0), Vector2(u1, 0), Vector2(u1, 1))
		else:
			_quad(st, b0, b1, t1, t0, n, n, n, n, Vector2(u0, 1), Vector2(u1, 1), Vector2(u1, 0), Vector2(u0, 0))
	st.generate_tangents()
	return st.commit()


static func mesh_node(mesh: Mesh, material: Material, name := "Mesh") -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name = name
	node.mesh = mesh
	if material != null:
		node.material_override = material
	return node


static func box(size: Vector3, pos: Vector3, material: Material, name := "Box") -> MeshInstance3D:
	var m := BoxMesh.new()
	m.size = size
	var node := mesh_node(m, material, name)
	node.position = pos
	return node


static func cylinder(radius: float, height: float, material: Material, segments := 16) -> MeshInstance3D:
	var m := CylinderMesh.new()
	m.top_radius = radius
	m.bottom_radius = radius
	m.height = height
	m.radial_segments = segments
	m.rings = 1
	return mesh_node(m, material, "Cylinder")


static func sphere(radius: float, material: Material, segments := 24) -> MeshInstance3D:
	var m := SphereMesh.new()
	m.radius = radius
	m.height = radius * 2.0
	m.radial_segments = segments
	m.rings = max(8, segments / 2)
	return mesh_node(m, material, "Sphere")


static func wheel(radius: float, width: float, detailed := true) -> Node3D:
	# Ось колеса — X, крутится вместе с корнем. Дальний LOD — гладкая покрышка.
	var root := Node3D.new()
	root.name = "Wheel"
	if not detailed:
		var plain := CylinderMesh.new()
		plain.top_radius = radius
		plain.bottom_radius = radius
		plain.height = width
		plain.radial_segments = 12
		var plain_node := mesh_node(plain, mat(Color(0.06, 0.06, 0.07), 0.9), "Tire")
		plain_node.rotation_degrees = Vector3(0, 0, 90)
		root.add_child(plain_node)
		return root
	var tire := CylinderMesh.new()
	tire.top_radius = radius
	tire.bottom_radius = radius
	tire.height = width * 0.78
	tire.radial_segments = 40
	tire.rings = 2
	var tire_node := mesh_node(tire, mat(Color(0.05, 0.05, 0.055), 0.92), "Tire")
	tire_node.rotation_degrees = Vector3(0, 0, 90)
	root.add_child(tire_node)

	var shoulder := mat(Color(0.09, 0.09, 0.1), 0.88)
	for side in [-1.0, 1.0]:
		var wall := CylinderMesh.new()
		wall.top_radius = radius * 0.9
		wall.bottom_radius = radius * 0.68
		wall.height = width * 0.2
		wall.radial_segments = 36
		var wall_node := mesh_node(wall, shoulder, "Sidewall")
		wall_node.rotation_degrees = Vector3(0, 0, 90)
		wall_node.position.x = side * width * 0.38
		root.add_child(wall_node)

	var rim_mat := mat(Color(0.68, 0.7, 0.73), 0.22, 0.88)
	var rim := CylinderMesh.new()
	rim.top_radius = radius * 0.58
	rim.bottom_radius = radius * 0.58
	rim.height = width * 0.72
	rim.radial_segments = 32
	var rim_node := mesh_node(rim, rim_mat, "Rim")
	rim_node.rotation_degrees = Vector3(0, 0, 90)
	root.add_child(rim_node)

	var hub := CylinderMesh.new()
	hub.top_radius = radius * 0.2
	hub.bottom_radius = radius * 0.2
	hub.height = width * 0.86
	hub.radial_segments = 16
	var hub_node := mesh_node(hub, mat(Color(0.32, 0.33, 0.35), 0.35, 0.75), "Hub")
	hub_node.rotation_degrees = Vector3(0, 0, 90)
	root.add_child(hub_node)

	var spoke_mat := mat(Color(0.74, 0.76, 0.79), 0.2, 0.92)
	var nut_mat := mat(Color(0.22, 0.23, 0.25), 0.4, 0.75)
	for i in 5:
		var holder := Node3D.new()
		holder.rotation.x = TAU * float(i) / 5.0
		var spoke := box(Vector3(width * 0.5, radius * 0.46, 0.03), Vector3(0, radius * 0.36, 0), spoke_mat, "Spoke")
		holder.add_child(spoke)
		root.add_child(holder)
		var nut := CylinderMesh.new()
		nut.top_radius = radius * 0.045
		nut.bottom_radius = radius * 0.045
		nut.height = width * 0.96
		nut.radial_segments = 6
		var nut_node := mesh_node(nut, nut_mat, "Nut")
		nut_node.rotation_degrees = Vector3(0, 0, 90)
		var a: float = TAU * float(i) / 5.0
		nut_node.position = Vector3(0, sin(a) * radius * 0.36, cos(a) * radius * 0.36)
		root.add_child(nut_node)

	var cap_mat := mat(Color(0.78, 0.79, 0.81), 0.18, 0.9)
	for side in [-1.0, 1.0]:
		var cap := sphere(radius * 0.13, cap_mat, 16)
		cap.position.x = side * width * 0.46
		root.add_child(cap)
	return root


static func _arc_point(ang: float, r: float, x: float) -> Vector3:
	return Vector3(x, sin(ang) * r, cos(ang) * r)


static func fender_mesh(outer_r: float, width: float, segs := 20) -> ArrayMesh:
	# Арка над колесом: внешняя и внутренняя оболочки плюс щёки.
	var inner_r: float = outer_r * 0.64
	var hx: float = width * 0.5
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var a0 := PI * 1.15
	var a1 := -PI * 0.15
	for i in segs:
		var ang0: float = lerp(a0, a1, float(i) / float(segs))
		var ang1: float = lerp(a0, a1, float(i + 1) / float(segs))
		var n0 := Vector3(0, sin(ang0), cos(ang0))
		var n1 := Vector3(0, sin(ang1), cos(ang1))
		var o0n := _arc_point(ang0, outer_r, -hx)
		var o0p := _arc_point(ang0, outer_r, hx)
		var o1n := _arc_point(ang1, outer_r, -hx)
		var o1p := _arc_point(ang1, outer_r, hx)
		var i0n := _arc_point(ang0, inner_r, -hx)
		var i0p := _arc_point(ang0, inner_r, hx)
		var i1n := _arc_point(ang1, inner_r, -hx)
		var i1p := _arc_point(ang1, inner_r, hx)
		_quad(st, o0n, o1n, o1p, o0p, n0, n1, n1, n0, Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1))
		_quad(st, i0p, i1p, i1n, i0n, -n0, -n1, -n1, -n0, Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1))
		_quad(st, o0n, i0n, i1n, o1n, Vector3.LEFT, Vector3.LEFT, Vector3.LEFT, Vector3.LEFT,
			Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1))
		_quad(st, o0p, o1p, i1p, i0p, Vector3.RIGHT, Vector3.RIGHT, Vector3.RIGHT, Vector3.RIGHT,
			Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1))
	st.generate_tangents()
	return st.commit()


static func bumper_bar(width: float, radius: float, material: Material) -> Node3D:
	var root := Node3D.new()
	root.name = "Bumper"
	var bar := cylinder(radius, width, material, 20)
	bar.rotation_degrees = Vector3(0, 0, 90)
	root.add_child(bar)
	var valence := box(Vector3(width * 0.96, radius * 1.35, radius * 2.1), Vector3(0, -radius * 0.45, 0), material, "Valence")
	root.add_child(valence)
	for side in [-1.0, 1.0]:
		var cap := sphere(radius, material, 14)
		cap.position.x = side * width * 0.5
		root.add_child(cap)
	return root


static func slat_grille(width: float, height: float, slats := 5) -> Node3D:
	var root := Node3D.new()
	root.name = "Grille"
	var frame := mat(Color(0.08, 0.09, 0.1), 0.45, 0.35)
	var chrome := mat(Color(0.72, 0.74, 0.76), 0.22, 0.85)
	root.add_child(box(Vector3(width, height, 0.06), Vector3.ZERO, frame, "Back"))
	root.add_child(box(Vector3(width + 0.04, 0.035, 0.08), Vector3(0, height * 0.5, -0.01), chrome, "Frame"))
	root.add_child(box(Vector3(width + 0.04, 0.035, 0.08), Vector3(0, -height * 0.5, -0.01), chrome, "Frame"))
	for i in slats:
		var y: float = lerp(-height * 0.36, height * 0.36, float(i) / float(max(1, slats - 1)))
		root.add_child(box(Vector3(width * 0.9, 0.028, 0.05), Vector3(0, y, -0.02), chrome, "Slat"))
	return root


static func lamp_cluster(style: String) -> Dictionary:
	# Локальный ноль — центр фары, свет смотрит в −Z. lenses — стекла, которым игра поднимает яркость ночью.
	var root := Node3D.new()
	root.name = "Lamp"
	var housing := mat(Color(0.07, 0.08, 0.09), 0.4, 0.2)
	var chrome := mat(Color(0.75, 0.77, 0.8), 0.18, 0.9)
	var beam := emissive(Color(1.0, 0.97, 0.88), 1.5)
	var amber := emissive(Color(1.0, 0.55, 0.08), 1.2)
	var drl := emissive(Color(0.9, 0.95, 1.0), 0.9)
	var lenses: Array = []
	match style:
		"round":
			var ring := cylinder(0.125, 0.07, chrome, 28)
			ring.rotation_degrees = Vector3(90, 0, 0)
			root.add_child(ring)
			var lens := sphere(0.095, beam, 22)
			lens.position.z = -0.03
			root.add_child(lens)
			lenses.append(lens)
		"drop":
			var backing := box(Vector3(0.42, 0.22, 0.08), Vector3(0, 0, 0.04), housing, "Back")
			root.add_child(backing)
			var lens := sphere(0.11, beam, 22)
			lens.scale = Vector3(1.7, 0.72, 0.55)
			lens.position = Vector3(0.02, 0.02, -0.04)
			root.add_child(lens)
			lenses.append(lens)
		"swept":
			root.add_child(box(Vector3(0.64, 0.2, 0.1), Vector3(0, 0, 0.03), housing, "Back"))
			var lens := box(Vector3(0.5, 0.1, 0.05), Vector3(-0.02, 0.01, -0.03), beam, "Beam")
			root.add_child(lens)
			lenses.append(lens)
			var wink := sphere(0.055, amber, 16)
			wink.position = Vector3(0.26, -0.02, -0.04)
			root.add_child(wink)
			var drl_bar := box(Vector3(0.46, 0.035, 0.04), Vector3(-0.02, -0.07, -0.03), drl, "DRL")
			root.add_child(drl_bar)
		"rect":
			root.add_child(box(Vector3(0.46, 0.24, 0.1), Vector3(0, 0, 0.03), housing, "Back"))
			var lens := box(Vector3(0.36, 0.14, 0.05), Vector3(0, 0.01, -0.03), beam, "Beam")
			root.add_child(lens)
			lenses.append(lens)
		_:
			# Блок Hella, как на НефАЗ-5299: ближний, поворотник и дневные огни снизу.
			root.add_child(box(Vector3(0.5, 0.36, 0.1), Vector3(0, 0, 0.04), housing, "Back"))
			var lens := box(Vector3(0.26, 0.16, 0.05), Vector3(-0.06, 0.04, -0.03), beam, "Beam")
			root.add_child(lens)
			lenses.append(lens)
			root.add_child(box(Vector3(0.14, 0.16, 0.05), Vector3(0.14, 0.04, -0.03), amber, "Amber"))
			root.add_child(box(Vector3(0.4, 0.045, 0.04), Vector3(0, -0.12, -0.03), drl, "DRL"))
	return {"node": root, "lenses": lenses}


static func sedan_body(color: Color) -> Node3D:
	# Легковой седан: лофт кузова и кабины, решётка, фары и арки. Колёса крепит вызывающий код.
	var root := Node3D.new()
	root.name = "CarBody"
	var paint := paint(color)
	paint.cull_mode = BaseMaterial3D.CULL_DISABLED
	var dark := mat(Color(0.1, 0.11, 0.13), 0.55, 0.25)
	var glass_mat := glass(Color(0.12, 0.16, 0.2), 0.48)
	var half_w := 0.9
	var y0 := 0.46
	var y1 := 0.96
	var length := 4.45
	var profile := rounded_profile(half_w, y0, y1, 0.12, 0.16, 12, 0.04)
	var nose := {"len": 0.9, "sx": 0.58, "sy": 0.86, "dy": 0.02, "shear": 0.16, "curve": "soft"}
	var tail := {"len": 0.72, "sx": 0.66, "sy": 0.9, "dy": 0.0, "shear": -0.08, "curve": "soft"}
	var station_list := stations(length, nose, tail, 10)
	root.add_child(mesh_node(loft(profile, station_list, y0, y1, true), paint, "Hull"))

	var cy0 := 0.94
	var cy1 := 1.48
	var cabin_len := 2.15
	var cprof := rounded_profile(0.8, cy0, cy1, 0.06, 0.2, 12, 0.1)
	var cnose := {"len": 0.58, "sx": 0.72, "sy": 0.55, "dy": 0.04, "shear": 0.32, "curve": "soft"}
	var ctail := {"len": 0.48, "sx": 0.78, "sy": 0.62, "dy": 0.0, "shear": -0.22, "curve": "soft"}
	var cst := stations(cabin_len, cnose, ctail, 8)
	var cabin := Node3D.new()
	cabin.name = "Cabin"
	cabin.position.z = 0.12
	for run in band_runs(cprof, cy1 - 0.2, cy1 + 0.02):
		cabin.add_child(mesh_node(band_mesh(cprof, cst, run, cy0, cy1, 1.0), paint, "Roof"))
	for run in band_runs(cprof, cy0 + 0.1, cy1 - 0.16):
		cabin.add_child(mesh_node(band_mesh(cprof, cst, run, cy0, cy1, 1.002), glass_mat, "Glass"))
	var front_ring := ring_of(cprof, cst[0], cy0, cy1)
	var rear_ring := ring_of(cprof, cst[cst.size() - 1], cy0, cy1)
	var front_caps := cap_with_window(front_ring, level_at(cst[0], cy0 + 0.12), level_at(cst[0], cy1 - 0.16), true)
	cabin.add_child(mesh_node(front_caps[0], paint, "WindFrame"))
	if front_caps[1] != null:
		cabin.add_child(mesh_node(front_caps[1], glass_mat, "Windshield"))
	var rear_caps := cap_with_window(rear_ring, level_at(cst[cst.size() - 1], cy0 + 0.14), level_at(cst[cst.size() - 1], cy1 - 0.18), false)
	cabin.add_child(mesh_node(rear_caps[0], paint, "RearFrame"))
	if rear_caps[1] != null:
		cabin.add_child(mesh_node(rear_caps[1], glass_mat, "RearGlass"))
	var pillar := mat(color.darkened(0.15), 0.4, 0.05)
	for z in [-0.28, 0.42]:
		for side in [-1.0, 1.0]:
			cabin.add_child(box(Vector3(0.06, 0.42, 0.07), Vector3(side * 0.76, 1.18, z), pillar, "Pillar"))
	root.add_child(cabin)

	var front_z := -length * 0.5
	var grille := slat_grille(0.72, 0.28, 4)
	grille.position = Vector3(0, 0.72, front_z + 0.08)
	root.add_child(grille)
	for side in [-1.0, 1.0]:
		var cluster: Dictionary = lamp_cluster("drop")
		var node: Node3D = cluster["node"]
		node.position = Vector3(side * 0.62, 0.74, front_z - 0.02)
		root.add_child(node)
		var tail_lamp := box(Vector3(0.28, 0.14, 0.06), Vector3(side * 0.62, 0.78, length * 0.5 + 0.02),
			emissive(Color(0.85, 0.1, 0.08), 1.1), "Tail")
		root.add_child(tail_lamp)
	var bumper_mat := mat(Color(0.12, 0.13, 0.14), 0.5, 0.2)
	var front_bar := bumper_bar(1.7, 0.07, bumper_mat)
	front_bar.position = Vector3(0, 0.58, front_z - 0.02)
	root.add_child(front_bar)
	var rear_bar := bumper_bar(1.68, 0.07, bumper_mat)
	rear_bar.position = Vector3(0, 0.58, length * 0.5 + 0.02)
	root.add_child(rear_bar)
	for side in [-1.0, 1.0]:
		var arm := cylinder(0.02, 0.28, dark, 8)
		arm.rotation_degrees = Vector3(0, 0, 70 * side)
		arm.position = Vector3(side * 0.92, 1.12, -0.72)
		root.add_child(arm)
		root.add_child(box(Vector3(0.05, 0.22, 0.14), Vector3(side * 1.02, 1.08, -0.7),
			mat(Color(0.25, 0.28, 0.32), 0.2, 0.6), "Mirror"))
	var arch_mat := mat(Color(0.07, 0.08, 0.09), 0.88)
	arch_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	for axle in [-1.42, 1.42]:
		for side in [-1.0, 1.0]:
			var arch := mesh_node(fender_mesh(0.46, 0.28, 18), arch_mat, "Arch")
			arch.position = Vector3(side * 0.9, 0.36, axle)
			root.add_child(arch)
	return root


static func label(text: String, size := 48, color := Color(0.96, 0.97, 1.0)) -> Label3D:
	var node := Label3D.new()
	node.text = text
	node.font_size = size
	node.modulate = color
	node.outline_size = int(size * 0.18)
	node.outline_modulate = Color(0.02, 0.03, 0.05, 0.9)
	node.pixel_size = 0.004
	node.double_sided = false
	return node


# --- небо ---------------------------------------------------------------

const SKY_CODE := """
shader_type sky;

uniform vec3 top_color : source_color;
uniform vec3 horizon_color : source_color;
uniform vec3 ground_color : source_color;
uniform vec3 cloud_lit : source_color;
uniform vec3 cloud_shade : source_color;
uniform float cover = 0.45;
uniform float sun_size = 0.004;
uniform float haze = 0.35;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float fbm(vec2 p) {
	float sum = 0.0;
	float amp = 0.5;
	for (int i = 0; i < 5; i++) {
		sum += vnoise(p) * amp;
		p = p * 2.03 + vec2(13.7, 7.1);
		amp *= 0.5;
	}
	return sum;
}

void sky() {
	vec3 dir = normalize(EYEDIR);
	float up = dir.y;
	vec3 col = mix(horizon_color, top_color, pow(clamp(up, 0.0, 1.0), 0.58));
	col = mix(col, ground_color, smoothstep(0.0, -0.18, up));

	vec3 to_sun = -LIGHT0_DIRECTION;
	float sun_dot = dot(dir, to_sun);
	// Дымка у горизонта со стороны солнца и мягкое свечение вокруг него.
	col += LIGHT0_COLOR * haze * pow(max(sun_dot, 0.0), 8.0) * (1.0 - clamp(up, 0.0, 1.0) * 0.6);
	float disk = smoothstep(1.0 - sun_size, 1.0 - sun_size * 0.35, sun_dot);
	col += LIGHT0_COLOR * disk * LIGHT0_ENERGY * 1.8;

	if (up > 0.005) {
		// Облака — слой на высоте, спроецированный по направлению взгляда.
		vec2 uv = dir.xz / max(up, 0.06) * 0.85 + vec2(TIME * 0.0035, TIME * 0.0012);
		float f = fbm(uv);
		float mask = smoothstep(1.0 - cover, 1.0 - cover + 0.45, f) * smoothstep(0.005, 0.16, up);
		float lit = smoothstep(0.35, 0.95, f + max(sun_dot, 0.0) * 0.2);
		vec3 cloud = mix(cloud_shade, cloud_lit, lit) * (0.75 + 0.45 * LIGHT0_ENERGY);
		col = mix(col, cloud, mask * 0.92);
	}
	COLOR = col;
}
"""


const TERRAIN_CODE := """
shader_type spatial;
uniform sampler2D grass_tex : repeat_enable;
uniform float snow : hint_range(0.0, 1.0) = 0.0;
varying float height;

void vertex() {
	height = VERTEX.y;
}

void fragment() {
	vec3 grass = texture(grass_tex, UV).rgb;
	float rock = smoothstep(4.0, 12.0, height);
	float sand = 1.0 - smoothstep(-1.35, -0.2, height);
	vec3 col = mix(grass, vec3(0.42, 0.4, 0.36), rock);
	col = mix(col, vec3(0.62, 0.56, 0.4), sand);
	col = mix(col, vec3(0.94, 0.96, 0.99), snow);
	ALBEDO = col;
	ROUGHNESS = mix(0.94, 0.62, snow);
}
"""

const WATER_CODE := """
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled;
uniform vec4 water_color : source_color = vec4(0.05, 0.22, 0.34, 0.9);

void fragment() {
	float wave = sin(UV.x * 48.0 + TIME * 1.3) * sin(UV.y * 32.0 - TIME * 0.9);
	float glint = smoothstep(0.55, 0.95, wave);
	ALBEDO = water_color.rgb + vec3(0.05, 0.07, 0.06) * wave + vec3(glint) * 0.08;
	ROUGHNESS = 0.08;
	METALLIC = 0.42;
	ALPHA = 0.88;
	SPECULAR = 0.6;
}
"""


static func terrain_material(grass: Texture2D) -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = TERRAIN_CODE
	var m := ShaderMaterial.new()
	m.shader = shader
	m.set_shader_parameter("grass_tex", grass)
	m.set_shader_parameter("snow", 0.0)
	return m


static func water_material() -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = WATER_CODE
	var m := ShaderMaterial.new()
	m.shader = shader
	return m


static func sky_material() -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = SKY_CODE
	var m := ShaderMaterial.new()
	m.shader = shader
	return m


# --- текстуры -----------------------------------------------------------

static func noise_image(width: int, height: int, base: Color, contrast: float, freq: float, seed_value: int) -> Image:
	var noise := FastNoiseLite.new()
	noise.seed = seed_value
	noise.frequency = freq
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	var img := Image.create_empty(width, height, true, Image.FORMAT_RGBA8)
	for y in height:
		for x in width:
			var n: float = noise.get_noise_2d(float(x), float(y)) * 0.5 + 0.5
			var k: float = 1.0 - contrast + contrast * n
			img.set_pixel(x, y, Color(base.r * k, base.g * k, base.b * k, 1.0))
	img.generate_mipmaps()
	return img


static func texture_from(img: Image) -> ImageTexture:
	return ImageTexture.create_from_image(img)


static func facade_pair(wall: Color, glass_color: Color, seed_value: int) -> Array:
	# Возвращает [albedo, emission] для фасада: этажи с окнами.
	var size := 256
	var albedo := noise_image(size, size, wall, 0.14, 0.05, seed_value)
	var emission := Image.create_empty(size, size, true, Image.FORMAT_RGBA8)
	emission.fill(Color(0, 0, 0, 1))
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var floors := 4
	var columns := 4
	var cell := size / floors
	var col_w := size / columns
	for f in floors:
		for c in columns:
			var x0: int = c * col_w + int(col_w * 0.22)
			var x1: int = c * col_w + int(col_w * 0.78)
			var y0: int = f * cell + int(cell * 0.2)
			var y1: int = f * cell + int(cell * 0.68)
			var lit: bool = rng.randf() < 0.55
			var warm := Color(1.0, 0.85, 0.55) if rng.randf() < 0.7 else Color(0.75, 0.9, 1.0)
			for y in range(y0, y1):
				for x in range(x0, x1):
					albedo.set_pixel(x, y, glass_color)
					if lit:
						emission.set_pixel(x, y, warm)
			for x in range(x0 - 2, x1 + 2):
				for y in [y0 - 2, y1 + 1]:
					if x >= 0 and x < size and y >= 0 and y < size:
						albedo.set_pixel(x, y, wall.darkened(0.25))
	albedo.generate_mipmaps()
	emission.generate_mipmaps()
	return [texture_from(albedo), texture_from(emission)]


static func asphalt_texture(seed_value: int) -> ImageTexture:
	return texture_from(noise_image(128, 128, Color(0.19, 0.2, 0.21), 0.3, 0.09, seed_value))


static func ground_texture(seed_value: int) -> ImageTexture:
	var img := noise_image(192, 192, Color(0.28, 0.33, 0.2), 0.45, 0.035, seed_value)
	img.generate_mipmaps()
	return texture_from(img)


static func dash_texture() -> ImageTexture:
	var img := Image.create_empty(16, 64, true, Image.FORMAT_RGBA8)
	img.fill(Color(1, 1, 1, 0))
	for y in range(8, 40):
		for x in range(4, 12):
			img.set_pixel(x, y, Color(0.95, 0.93, 0.85, 1))
	img.generate_mipmaps()
	return texture_from(img)


static func noise_normal(strength: float, freq: float, seed_value: int, size := 128) -> ImageTexture:
	# Карта нормалей из шума: асфальт и бетон перестают быть стеклянно-гладкими.
	var noise := FastNoiseLite.new()
	noise.seed = seed_value
	noise.frequency = freq
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	var img := Image.create_empty(size, size, true, Image.FORMAT_RGBA8)
	for y in size:
		for x in size:
			var l: float = noise.get_noise_2d(float(x - 1), float(y))
			var r: float = noise.get_noise_2d(float(x + 1), float(y))
			var d: float = noise.get_noise_2d(float(x), float(y - 1))
			var u: float = noise.get_noise_2d(float(x), float(y + 1))
			var n := Vector3((l - r) * strength, (d - u) * strength, 1.0).normalized()
			img.set_pixel(x, y, Color(n.x * 0.5 + 0.5, n.y * 0.5 + 0.5, n.z * 0.5 + 0.5, 1.0))
	img.generate_mipmaps()
	return texture_from(img)


static func zebra_texture() -> ImageTexture:
	# Пешеходный переход: белые полосы вдоль ширины дороги.
	var img := Image.create_empty(64, 8, true, Image.FORMAT_RGBA8)
	img.fill(Color(1, 1, 1, 0))
	for x in 64:
		if (x / 8) % 2 == 0:
			for y in 8:
				img.set_pixel(x, y, Color(0.93, 0.93, 0.9, 1))
	img.generate_mipmaps()
	return texture_from(img)


static func tile_texture(base: Color, seed_value: int) -> ImageTexture:
	# Тротуарная плитка: сетка швов и лёгкий разброс оттенка.
	var size := 128
	var img := noise_image(size, size, base, 0.1, 0.06, seed_value)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var cell := 32
	for y in size:
		for x in size:
			if x % cell == 0 or y % cell == 0:
				img.set_pixel(x, y, base.darkened(0.3))
	for cy in range(0, size, cell):
		for cx in range(0, size, cell):
			var shade: float = rng.randf_range(-0.05, 0.05)
			for y in range(cy + 1, cy + cell):
				for x in range(cx + 1, cx + cell):
					var c: Color = img.get_pixel(x, y)
					img.set_pixel(x, y, Color(c.r + shade, c.g + shade, c.b + shade, 1.0))
	img.generate_mipmaps()
	return texture_from(img)
