extends Node2D

var hitting = {}
var ripples = []
var fire = []

func _ready():
	hitting = {"bass": false, "snare": false, "hihat": false, "crash": false, "tom": false}
	for i in 120:
		fire.append(new_fire())

func new_fire():
	var s = get_viewport().get_visible_rect().size
	return {"x": randf_range(0, s.x), "y": randf_range(0, s.y), "speed": randf_range(60, 180), "size": randf_range(8, 28), "hue": randf_range(0.0, 0.08)}

func new_player():
	var p = AudioStreamPlayer.new()
	var s = AudioStreamGenerator.new()
	s.mix_rate = 44100
	s.buffer_length = 0.4
	p.stream = s
	add_child(p)
	return p

func gen_sound(player, frames, use_noise, freq_start, freq_end, decay):
	player.play()
	var pb = player.get_stream_playback()
	var sr = 44100.0
	for i in frames:
		var t = float(i) / sr
		var amp = exp(-t * decay)
		var sample = 0.0
		if use_noise:
			sample = amp * randf_range(-1.0, 1.0)
		else:
			var freq = freq_start * exp(-t * 15.0) + freq_end
			sample = amp * sin(TAU * freq * t)
		pb.push_frame(Vector2(sample, sample))

func play_bass():
	var p = new_player()
	p.play()
	var pb = p.get_stream_playback()
	var sr = 44100.0
	for i in int(sr * 0.4):
		var t = float(i) / sr
		var freq = 150.0 * exp(-t * 18.0) + 40.0
		var amp = exp(-t * 6.0)
		pb.push_frame(Vector2(amp * (sin(TAU * freq * t) * 0.8 + randf_range(-1.0, 1.0) * 0.2), amp * (sin(TAU * freq * t) * 0.8 + randf_range(-1.0, 1.0) * 0.2)))

func play_snare():
	var p = new_player()
	p.play()
	var pb = p.get_stream_playback()
	var sr = 44100.0
	for i in int(sr * 0.2):
		var t = float(i) / sr
		var s = exp(-t * 20.0) * sin(TAU * 180.0 * t) * 0.4 + exp(-t * 12.0) * randf_range(-1.0, 1.0) * 0.7
		pb.push_frame(Vector2(s, s))

func play_hihat():
	gen_sound(new_player(), int(44100.0 * 0.08), true, 0, 0, 60.0)

func play_crash():
	gen_sound(new_player(), int(44100.0 * 0.8), true, 0, 0, 3.5)

func play_tom():
	var p = new_player()
	p.play()
	var pb = p.get_stream_playback()
	var sr = 44100.0
	for i in int(sr * 0.3):
		var t = float(i) / sr
		var freq = 220.0 * exp(-t * 12.0) + 80.0
		var amp = exp(-t * 8.0)
		pb.push_frame(Vector2(amp * sin(TAU * freq * t), amp * sin(TAU * freq * t)))

func _input(event):
	if event is InputEventKey and event.pressed and not event.echo:
		var s = get_viewport().get_visible_rect().size
		var cx = s.x / 2
		var cy = s.y / 2
		if event.keycode == KEY_A:
			play_bass()
			flash("bass")
			ripples.append({"pos": Vector2(cx, cy + 100), "size": 10.0, "color": Color(0.9, 0.2, 0.2), "alpha": 1.0})
		if event.keycode == KEY_S:
			play_snare()
			flash("snare")
			ripples.append({"pos": Vector2(cx - 160, cy + 10), "size": 10.0, "color": Color(0.2, 0.5, 0.9), "alpha": 1.0})
		if event.keycode == KEY_D:
			play_hihat()
			flash("hihat")
			ripples.append({"pos": Vector2(cx - 270, cy - 50), "size": 10.0, "color": Color(0.9, 0.85, 0.1), "alpha": 1.0})
		if event.keycode == KEY_G:
			play_crash()
			flash("crash")
			ripples.append({"pos": Vector2(cx + 270, cy - 50), "size": 10.0, "color": Color(0.9, 0.85, 0.1), "alpha": 1.0})
		if event.keycode == KEY_H:
			play_tom()
			flash("tom")
			ripples.append({"pos": Vector2(cx + 160, cy + 10), "size": 10.0, "color": Color(0.8, 0.4, 0.1), "alpha": 1.0})

func flash(drum):
	hitting[drum] = true
	await get_tree().create_timer(0.15).timeout
	hitting[drum] = false

func oval(pos, rx, ry):
	var pts = PackedVector2Array()
	for i in 32:
		pts.append(pos + Vector2(cos(TAU / 32 * i) * rx, sin(TAU / 32 * i) * ry))
	return pts

func draw_drum(pos, rx, ry, label, key, hit, color):
	var col = color if hit else color * 0.5
	var pts = oval(pos, rx, ry)
	draw_colored_polygon(pts, col)
	draw_polyline(pts + PackedVector2Array([pts[0]]), Color(0.85, 0.75, 0.25), 5)
	var inner = oval(pos, rx * 0.85, ry * 0.75)
	draw_colored_polygon(inner, col * 1.3 if hit else col * 0.7)
	draw_polyline(inner + PackedVector2Array([inner[0]]), Color(0.6, 0.55, 0.15), 2)
	draw_string(ThemeDB.fallback_font, pos + Vector2(-18, -8), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.WHITE)
	draw_string(ThemeDB.fallback_font, pos + Vector2(-10, 10), "[" + key + "]", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.9, 0.85, 0.4))

func draw_cymbal(pos, rx, ry, label, key, hit):
	var pts = oval(pos, rx, ry)
	var col = Color(1.0, 0.9, 0.15) if hit else Color(0.55, 0.48, 0.08)
	draw_colored_polygon(pts, col)
	draw_polyline(pts + PackedVector2Array([pts[0]]), Color(1.0, 0.95, 0.4) if hit else Color(0.7, 0.6, 0.1), 3)
	draw_circle(pos, 10, Color(0.9, 0.8, 0.2) if hit else Color(0.6, 0.5, 0.1))
	draw_string(ThemeDB.fallback_font, pos + Vector2(-18, -ry - 18), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color.WHITE)
	draw_string(ThemeDB.fallback_font, pos + Vector2(-10, -ry - 4), "[" + key + "]", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.9, 0.85, 0.4))

func _draw():
	var s = get_viewport().get_visible_rect().size
	var cx = s.x / 2
	var cy = s.y / 2

	draw_rect(Rect2(0, 0, s.x, s.y), Color(0.05, 0.03, 0.03))

	for p in fire:
		var heat = 1.0 - (p["y"] / s.y)
		draw_circle(Vector2(p["x"], p["y"]), p["size"] * heat, Color.from_hsv(p["hue"] + heat * 0.06, 1.0, min(heat + 0.3, 1.0)))

	for r in ripples:
		draw_arc(r["pos"], r["size"], 0, TAU, 64, Color(r["color"].r, r["color"].g, r["color"].b, r["alpha"]), 10.0)
		draw_arc(r["pos"], r["size"] * 0.75, 0, TAU, 64, Color(r["color"].r, r["color"].g, r["color"].b, r["alpha"] * 0.6), 6.0)
		draw_arc(r["pos"], r["size"] * 0.5, 0, TAU, 64, Color(r["color"].r, r["color"].g, r["color"].b, r["alpha"] * 0.3), 4.0)

	# Gold ground
	draw_rect(Rect2(0, s.y - 40, s.x, 40), Color(0.7, 0.55, 0.05))
	draw_line(Vector2(0, s.y - 40), Vector2(s.x, s.y - 40), Color(0.9, 0.75, 0.1), 3)

	draw_line(Vector2(cx - 270, cy - 30), Vector2(cx - 270, s.y - 40), Color(0.45, 0.45, 0.45), 3)
	draw_line(Vector2(cx + 270, cy - 30), Vector2(cx + 270, s.y - 40), Color(0.45, 0.45, 0.45), 3)
	draw_line(Vector2(cx - 160, cy + 50), Vector2(cx - 190, s.y - 40), Color(0.45, 0.45, 0.45), 3)
	draw_line(Vector2(cx - 160, cy + 50), Vector2(cx - 130, s.y - 40), Color(0.45, 0.45, 0.45), 3)
	draw_line(Vector2(cx + 160, cy + 50), Vector2(cx + 130, s.y - 40), Color(0.45, 0.45, 0.45), 3)
	draw_line(Vector2(cx + 160, cy + 50), Vector2(cx + 190, s.y - 40), Color(0.45, 0.45, 0.45), 3)
	draw_line(Vector2(cx - 30, cy + 180), Vector2(cx - 100, s.y - 40), Color(0.45, 0.45, 0.45), 4)
	draw_line(Vector2(cx + 30, cy + 180), Vector2(cx + 100, s.y - 40), Color(0.45, 0.45, 0.45), 4)

	draw_drum(Vector2(cx, cy + 100), 100, 80, "BASS", "A", hitting["bass"], Color(0.7, 0.15, 0.15))
	draw_drum(Vector2(cx - 160, cy + 10), 60, 25, "SNARE", "S", hitting["snare"], Color(0.2, 0.4, 0.7))
	draw_drum(Vector2(cx + 160, cy + 10), 60, 25, "TOM", "H", hitting["tom"], Color(0.7, 0.3, 0.1))
	draw_cymbal(Vector2(cx - 270, cy - 50), 55, 12, "HIHAT", "D", hitting["hihat"])
	draw_cymbal(Vector2(cx + 270, cy - 50), 55, 12, "CRASH", "G", hitting["crash"])

	draw_string(ThemeDB.fallback_font, Vector2(cx - 60, 38), "DRUM KIT", HORIZONTAL_ALIGNMENT_LEFT, -1, 32, Color.WHITE)

func _process(delta):
	for r in ripples:
		r["size"] += 350.0 * delta
		r["alpha"] -= 0.7 * delta
	ripples = ripples.filter(func(r): return r["alpha"] > 0)
	for p in fire:
		p["y"] -= p["speed"] * delta
		p["x"] += randf_range(-3, 3)
		if p["y"] < 0:
			var s = get_viewport().get_visible_rect().size
			p["y"] = s.y
			p["x"] = randf_range(0, s.x)
			p["size"] = randf_range(8, 28)
	queue_redraw()
