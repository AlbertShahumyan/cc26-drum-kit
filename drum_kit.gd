extends Node2D

var hitting = {}

func _ready():
	hitting = {
		"bass": false,
		"snare": false,
		"hihat": false,
		"crash": false,
		"tom": false
	}

func make_player():
	var player = AudioStreamPlayer.new()
	var stream = AudioStreamGenerator.new()
	stream.mix_rate = 44100
	stream.buffer_length = 0.3
	player.stream = stream
	add_child(player)
	return player

func play_sound(freq, duration, is_noise):
	var player = make_player()
	player.play()
	var playback = player.get_stream_playback()
	var sample_rate = 44100.0
	var frames = int(sample_rate * duration)
	for i in frames:
		var t = float(i) / sample_rate
		var amp = 1.0 - (t / duration)
		var sample = 0.0
		if is_noise:
			sample = amp * randf_range(-1.0, 1.0)
		else:
			sample = amp * sin(TAU * freq * t)
		playback.push_frame(Vector2(sample, sample))

func _input(event):
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_A:
			play_sound(80, 0.3, false)
			flash("bass")
		if event.keycode == KEY_S:
			play_sound(200, 0.15, true)
			flash("snare")
		if event.keycode == KEY_D:
			play_sound(800, 0.05, true)
			flash("hihat")
		if event.keycode == KEY_G:
			play_sound(400, 0.4, true)
			flash("crash")
		if event.keycode == KEY_H:
			play_sound(150, 0.2, false)
			flash("tom")

func flash(drum):
	hitting[drum] = true
	await get_tree().create_timer(0.15).timeout
	hitting[drum] = false

func draw_drum(pos, rx, ry, label, key, hit, color):
	# draw the drum body as an oval using a polygon
	var points = PackedVector2Array()
	for i in 32:
		var angle = (TAU / 32) * i
		points.append(pos + Vector2(cos(angle) * rx, sin(angle) * ry))
	var col = color if hit else color * 0.4
	draw_colored_polygon(points, col)
	# draw a rim around it
	draw_polyline(points + PackedVector2Array([points[0]]), Color(0.8, 0.7, 0.2), 3)
	# draw the label
	draw_string(ThemeDB.fallback_font, pos + Vector2(-rx + 5, 6), label + " [" + key + "]", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color.WHITE)

func draw_cymbal(pos, rx, ry, label, key, hit):
	var points = PackedVector2Array()
	for i in 32:
		var angle = (TAU / 32) * i
		points.append(pos + Vector2(cos(angle) * rx, sin(angle) * ry))
	var col = Color(0.9, 0.8, 0.1) if hit else Color(0.5, 0.45, 0.05)
	draw_colored_polygon(points, col)
	draw_polyline(points + PackedVector2Array([points[0]]), Color(1.0, 0.9, 0.3), 2)
	draw_circle(pos, 6, Color(0.8, 0.7, 0.1))
	draw_string(ThemeDB.fallback_font, pos + Vector2(-rx + 5, 5), label + " [" + key + "]", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color.WHITE)

func _draw():
	var screen = get_viewport().get_visible_rect().size
	var cx = screen.x / 2
	var cy = screen.y / 2

	# dark background
	draw_rect(Rect2(0, 0, screen.x, screen.y), Color(0.08, 0.08, 0.08))

	# floor
	draw_rect(Rect2(0, screen.y - 40, screen.x, 40), Color(0.15, 0.1, 0.05))

	# stands - simple lines
	draw_line(Vector2(cx - 270, cy - 30), Vector2(cx - 270, screen.y - 40), Color(0.4, 0.4, 0.4), 3)
	draw_line(Vector2(cx + 270, cy - 30), Vector2(cx + 270, screen.y - 40), Color(0.4, 0.4, 0.4), 3)
	draw_line(Vector2(cx - 160, cy + 50), Vector2(cx - 190, screen.y - 40), Color(0.4, 0.4, 0.4), 3)
	draw_line(Vector2(cx - 160, cy + 50), Vector2(cx - 130, screen.y - 40), Color(0.4, 0.4, 0.4), 3)
	draw_line(Vector2(cx + 160, cy + 50), Vector2(cx + 130, screen.y - 40), Color(0.4, 0.4, 0.4), 3)
	draw_line(Vector2(cx + 160, cy + 50), Vector2(cx + 190, screen.y - 40), Color(0.4, 0.4, 0.4), 3)

	# bass drum stand legs
	draw_line(Vector2(cx - 30, cy + 180), Vector2(cx - 100, screen.y - 40), Color(0.4, 0.4, 0.4), 4)
	draw_line(Vector2(cx + 30, cy + 180), Vector2(cx + 100, screen.y - 40), Color(0.4, 0.4, 0.4), 4)

	# bass drum - big oval viewed from front
	draw_drum(Vector2(cx, cy + 100), 100, 80, "BASS", "A", hitting["bass"], Color(0.7, 0.15, 0.15))

	# snare drum - medium oval left of center
	draw_drum(Vector2(cx - 160, cy + 10), 60, 25, "SNARE", "S", hitting["snare"], Color(0.2, 0.4, 0.7))

	# tom drum - medium oval right of center
	draw_drum(Vector2(cx + 160, cy + 10), 60, 25, "TOM", "H", hitting["tom"], Color(0.7, 0.3, 0.1))

	# hihat cymbal - flat oval top left
	draw_cymbal(Vector2(cx - 270, cy - 50), 55, 12, "HIHAT", "D", hitting["hihat"])

	# crash cymbal - flat oval top right
	draw_cymbal(Vector2(cx + 270, cy - 50), 55, 12, "CRASH", "G", hitting["crash"])

	# title
	draw_string(ThemeDB.fallback_font, Vector2(cx - 55, 35), "DRUM KIT", HORIZONTAL_ALIGNMENT_LEFT, -1, 30, Color.WHITE)

	# key guide at bottom
	draw_string(ThemeDB.fallback_font, Vector2(20, screen.y - 10), "A=Bass  S=Snare  D=HiHat  G=Crash  H=Tom", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(0.6, 0.6, 0.6))

func _process(delta):
	queue_redraw()
