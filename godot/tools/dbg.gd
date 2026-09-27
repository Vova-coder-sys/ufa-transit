extends SceneTree


func _initialize() -> void:
	var y0 := 0.30
	var y1 := 3.02
	var profile := MeshLib.rounded_profile(1.28, y0, y1, 0.22, 0.42, 7, 0.05)
	profile = MeshLib.insert_levels(profile, [0.92, 1.06, 1.2, 1.46, 1.51, 1.52, 2.42, 2.43, 2.48, 2.62])
	print("profile points: ", profile.size())
	var ys := []
	for p in profile:
		ys.append(snappedf(p.y, 0.01))
	print("profile y: ", ys)
	var st := MeshLib.stations(12.2, {"len": 0.5, "sx": 0.9, "sy": 0.93, "dy": 0.02, "shear": 0.0},
		{"len": 0.45, "sx": 0.92, "sy": 0.95, "dy": 0.01, "shear": 0.0}, 6)
	var ring := MeshLib.ring_of(profile, st[0], y0, y1)
	var ring_y := []
	for p in ring:
		ring_y.append(snappedf(p.y, 0.01))
	print("ring y: ", ring_y)
	var aug_count := 0
	var corner_count := 0
	for i in ring.size():
		var a: Vector3 = ring[i]
		var b: Vector3 = ring[(i + 1) % ring.size()]
		aug_count += 1
		for level in [1.52, 2.42]:
			if (a.y - level) * (b.y - level) < 0.0:
				aug_count += 1
				corner_count += 1
	print("aug: ", aug_count, " corners: ", corner_count)
	var caps := MeshLib.cap_with_window(ring, 1.52, 2.42, true)
	var solid: ArrayMesh = caps[0]
	print("solid surfaces: ", solid.get_surface_count())
	if solid.get_surface_count() > 0:
		print("solid verts: ", solid.surface_get_array_len(0))
	print("glass: ", caps[1])
	if caps[1] != null:
		print("glass verts: ", (caps[1] as ArrayMesh).surface_get_array_len(0))
	var runs := MeshLib.band_runs(profile, 0.30, 0.92)
	print("skirt runs: ", runs)
	var win := MeshLib.band_runs(profile, 1.52, 2.42)
	print("window runs: ", win)
	quit()
