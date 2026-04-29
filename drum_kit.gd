extends Node2D

var hitting = {}
var hit_size = {}

func _ready():
	hitting = {
		"bass": false,
		"snare": false,
		"hihat": false,
		"crash": false,
		"tom": false
	}
	hit_size = {
		"bass": 0.0,
		"snare": 0.0,
		"hihat": 0.0,
		"crash": 0.0,
		"tom": 0.0
	}

func make_player():
	var player = AudioStreamPlayer.new()
	var stream = AudioStreamGenerator.new()
	stream.mix_rate = 44100
	stream.buffer_length = 0.4
	player.stream = stream
	add_child(player)
	return player

func play_bass():
	var player = make_player()
	player.play()
	var playback = player.get_stream_playback()
	var sample_rate = 44100.0
	var frames = int(sample_rate * 0.4)
	for i in frames:
		var t = float(i) / sample_rate
		# Frequency drops fast from 150hz to 40hz for that deep thud
		var freq = 150.0 * exp(-t * 18.0) + 40.0
		var amp = exp(-t * 6.0)
		# Mix sine wave with a bit of noise for texture
		var sample = amp * (sin(TAU * freq * t) * 0.8 + randf_range(-1.0, 1.0) * 0.2)
		playback.push_frame(Vector2(sample, sample))

func play_snare():
	var player = make_player()
	player.play()
	var playback = player.get_stream_playback()
	var sample_rate = 44100.0
	var frames = int(sample_rate * 0.2)
	for i in frames:
		var t = float(i) / sample_rate
		# Snare is a mix of a body tone and a sharp noise crack
		var body_amp = exp(-t * 20.0)
		var noise_amp = exp(-t * 12.0)
		var body = body_amp * sin(TAU * 180.0 * t)
		var noise = noise_amp * randf_range(-1.0, 1.0)
		var sample = body * 0.4 + noise * 0.7
		playback.push_frame(Vector2(sample, sample))

func play_hihat():
	var player = make_player()
	player.play()
	var playback = player.get_stream_playback()
	var sample_rate = 44100.0
	var frames = int(sample_rate * 0.08)
	for i in frames:
		var t = float(i) / sample_rate
		# Hi-hat is very short high frequency noise
		var amp = exp(-t * 60.0)
		var sample = amp * randf_range(-1.0, 1.0) * 0.6
		playback.push_frame(Vector2(sample, sample))

func play_crash():
	var player = make_player()
	player.play()
	var playback = player.get_stream_playback()
	var sample_rate = 44100.0
	var frames = int(sample_rate * 0.8)
	for i in frames:
		var t = float(i) / sample_rate
		# Crash is long noise that fades slowly
		var amp = exp(-t * 3.5)
		# Mix two noise layers for a richer cymbal sound
		var sample = amp * (randf_range(-1.0, 1.0) * 0.5 + randf_range(-1.0, 1.0) * 0.5)
		playback.push_frame(Vector2(sample, sample))

func play_tom():
	var player = make_player()
	player.play()
	var playback = player.get_stream_playback()
	var sample_rate = 44100.0
	var frames = int(sample_rate * 0.3)
	for i in frames:
		var t = float(i) / sample_rate
		# Tom is like bass drum but higher pitched
		var freq = 220.0 * exp(-t * 12.0) + 80.0
		var amp = exp(-t * 8.0)
		var sample = amp * (sin(TAU * freq * t) * 0.8 + randf_range(-1.0, 1.0) * 0.15)
		playback.push_frame(Vector2(sample, sample))

func _input(event):
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_A:
			play_bass()
			flash("bass")
		if event.keycode == KEY_S:
			play_snare()
			flash("snare")
		if event.keycode == KEY_D:
			play_hihat()
			flash("hihat")
		if event.keycode == KEY_G:
			play_crash()
			flash("crash")
		if event.keycode == KEY_H:
			play_tom()
			flash("tom")

func flash(drum):
	hitting[drum] = true
	hit_size[drum] = 0.0
	await get_tree().create_timer(0.15).timeout
	hitting[drum] = false

func draw_drum(pos, rx, ry, label, key, hit, color):
	var points = PackedVector2Array()
	for i in 32:
		var angle = (TAU / 32) * i
		points.append(pos + Vector2(cos(angle) * rx, sin(angle) * ry))
	var col = color if hit else color * 0.4
	draw_colored_polygon(points, col)
	draw_polyline(points + PackedVector2Array([points[0]]), Color(0.8, 0.7, 0.2), 3)
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

func draw_ripple(pos, drum, color):
	# Draw expanding circles when a drum is hit
	if hit_size[drum] < 200:
		var alpha = 1.0 - (hit_size[drum] / 200.0)
		draw_arc(pos, hit_size[drum], 0, TAU, 32, Color(color.r, color.g, color.b, alpha), 3.0)

func _draw():
	var screen = get_viewport().get_visible_rect().size
	var cx = screen.x / 2
	var cy = screen.y / 2

	# dark background
	draw_rect(Rect2(0, 0, screen.x, screen.y), Color(0.08, 0.08, 0.08))

	# draw ripple visuals behind the drums
	draw_ripple(Vector2(cx, cy + 100), "bass", Color(0.8, 0.2, 0.2))
	draw_ripple(Vector2(cx - 160, cy + 10), "snare", Color(0.2, 0.5, 0.9))
	draw_ripple(Vector2(cx + 160, cy + 10), "tom", Color(0.8, 0.4, 0.1))
	draw_ripple(Vector2(cx - 270, cy - 50), "hihat", Color(0.9, 0.85, 0.1))
	draw_ripple(Vector2(cx + 270, cy - 50), "crash", Color(0.9, 0.85, 0.1))

	# floor
	draw_rect(Rect2(0, screen.y - 40, screen.x, 40), Color(0.15, 0.1, 0.05))

	# stands
	draw_line(Vector2(cx - 270, cy - 30), Vector2(cx - 270, screen.y - 40), Color(0.4, 0.4, 0.4), 3)
	draw_line(Vector2(cx + 270, cy - 30), Vector2(cx + 270, screen.y - 40), Color(0.4, 0.4, 0.4), 3)
	draw_line(Vector2(cx - 160, cy + 50), Vector2(cx - 190, screen.y - 40), Color(0.4, 0.4, 0.4), 3)
	draw_line(Vector2(cx - 160, cy + 50), Vector2(cx - 130, screen.y - 40), Color(0.4, 0.4, 0.4), 3)
	draw_line(Vector2(cx + 160, cy + 50), Vector2(cx + 130, screen.y - 40), Color(0.4, 0.4, 0.4), 3)
	draw_line(Vector2(cx + 160, cy + 50), Vector2(cx + 190, screen.y - 40), Color(0.4, 0.4, 0.4), 3)
	draw_line(Vector2(cx - 30, cy + 180), Vector2(cx - 100, screen.y - 40), Color(0.4, 0.4, 0.4), 4)
	draw_line(Vector2(cx + 30, cy + 180), Vector2(cx + 100, screen.y - 40), Color(0.4, 0.4, 0.4), 4)

	# drums
	draw_drum(Vector2(cx, cy + 100), 100, 80, "BASS", "A", hitting["bass"], Color(0.7, 0.15, 0.15))
	draw_drum(Vector2(cx - 160, cy + 10), 60, 25, "SNARE", "S", hitting["snare"], Color(0.2, 0.4, 0.7))
	draw_drum(Vector2(cx + 160, cy + 10), 60, 25, "TOM", "H", hitting["tom"], Color(0.7, 0.3, 0.1))
	draw_cymbal(Vector2(cx - 270, cy - 50), 55, 12, "HIHAT", "D", hitting["hihat"])
	draw_cymbal(Vector2(cx + 270, cy - 50), 55, 12, "CRASH", "G", hitting["crash"])

	# title
	draw_string(ThemeDB.fallback_font, Vector2(cx - 55, 35), "DRUM KIT", HORIZONTAL_ALIGNMENT_LEFT, -1, 30, Color.WHITE)

	# key guide
	draw_string(ThemeDB.fallback_font, Vector2(20, screen.y - 10), "A=Bass  S=Snare  D=HiHat  G=Crash  H=Tom", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(0.6, 0.6, 0.6))

func _process(delta):
	# Grow the ripple circles outward over time
	for drum in hit_size:
		if hit_size[drum] > 0 or hitting[drum]:
			hit_size[drum] += 300.0 * delta
			if hit_size[drum] > 200:
				hit_size[drum] = 0.0
	queue_redraw()
