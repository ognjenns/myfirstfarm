extends Node2D
## Upravlja ekranima: hub + mini-igre. Ekrani se prave celi iz koda.

const SCREENS := {
	"splash": preload("res://screens/splash_screen.gd"),
	"worlds": preload("res://screens/worlds_screen.gd"),
	"hub": preload("res://screens/hub.gd"),
	"jungle": preload("res://screens/jungle_hub.gd"),
	"memory": preload("res://screens/memory_game.gd"),
	"quiz": preload("res://screens/sound_quiz_game.gd"),
	"jfeed": preload("res://screens/jungle_feed_game.gd"),
	"shower": preload("res://screens/elephant_shower_game.gd"),
	"feed": preload("res://screens/feed_game.gd"),
	"shadows": preload("res://screens/shadow_game.gd"),
	"bath": preload("res://screens/bath_game.gd"),
	"hideseek": preload("res://screens/hideseek_game.gd"),
	"gate": preload("res://screens/parental_gate.gd"),
	"parents": preload("res://screens/parent_corner.gd"),
}

var current: Node = null
var last_world := "hub"  # poslednji hub (farma/džungla) — za povratak iz roditeljskih ekrana

func _ready() -> void:
	add_to_group("main")
	if "--smoke" in OS.get_cmdline_user_args():
		_smoke_test()
	elif "--shots" in OS.get_cmdline_user_args():
		_screenshot_run()
	elif "--autotest" in OS.get_cmdline_user_args():
		Autotest.new(self).run()
	elif "--make-icon" in OS.get_cmdline_user_args():
		_make_icon()
	elif "--make-product-icon" in OS.get_cmdline_user_args():
		_make_product_icon()
	else:
		goto("splash")

## Snimi screenshot svakog ekrana u ../shots/ (vizuelna provera bez klika).
func _screenshot_run() -> void:
	var dir := ProjectSettings.globalize_path("res://").path_join("../shots")
	DirAccess.make_dir_recursive_absolute(dir)
	for screen_name in SCREENS:
		goto(screen_name)
		await get_tree().create_timer(0.9).timeout
		var img := get_viewport().get_texture().get_image()
		img.save_png(dir.path_join("%s.png" % screen_name))
		print("SHOT: ", screen_name)
	print("SHOTS DONE")
	get_tree().quit()

## Ikonica IAP proizvoda za Play konzolu (512px, bez teksta/brenda):
## zlatni otključan katanac sa zvezdicom na zelenom krugu.
func _make_product_icon() -> void:
	get_window().size = Vector2i(512, 512)
	var root := Node2D.new()
	add_child(root)
	var center := Vector2(UI.W / 2, UI.H / 2)
	UI.poly(root, UI.rect_points(1000, 1000), Color("#DFF0D0"), center)
	UI.circle(root, center, 470, Color("#B7DC9A"))
	# otvorena alka: prsten pomeren gore-desno, donji deo "otvoren"
	var shackle := Node2D.new()
	shackle.position = center + Vector2(120, -200)
	shackle.rotation = 0.45
	root.add_child(shackle)
	UI.circle(shackle, Vector2.ZERO, 140, Pal.OUTLINE)
	UI.circle(shackle, Vector2.ZERO, 88, Color("#B7DC9A"))
	UI.poly(shackle, UI.rect_points(320, 170), Color("#B7DC9A"), Vector2(0, 150))
	# telo katanca: zaobljeno, tamna ivica pa zlatno
	var body := center + Vector2(-30, 120)
	for corner_pass in [[Pal.OUTLINE, 470.0, 390.0, 80.0], [Color("#F5B971"), 430.0, 350.0, 62.0]]:
		var col: Color = corner_pass[0]
		var w: float = corner_pass[1]
		var h: float = corner_pass[2]
		var r: float = corner_pass[3]
		UI.poly(root, UI.rect_points(w, h - 2.0 * r), col, body)
		UI.poly(root, UI.rect_points(w - 2.0 * r, h), col, body)
		for sx in [-1, 1]:
			for sy in [-1, 1]:
				UI.circle(root, body + Vector2(sx * (w / 2 - r), sy * (h / 2 - r)), r, col)
	# ključaonica
	UI.circle(root, body + Vector2(0, -30), 42, Pal.OUTLINE)
	UI.poly(root, UI.rect_points(30, 80), Pal.OUTLINE, body + Vector2(0, 30))
	# zvezdica gore-levo
	var pts := PackedVector2Array()
	for i in 10:
		var ang := -PI / 2 + PI * i / 5.0
		var rr := 78.0 if i % 2 == 0 else 32.0
		pts.append(Vector2(cos(ang), sin(ang)) * rr)
	UI.poly(root, pts, Pal.SUN, center + Vector2(-300, -250))
	await get_tree().create_timer(0.5).timeout
	var img := get_viewport().get_texture().get_image()
	var content_scale := minf(img.get_width() / UI.W, img.get_height() / UI.H)
	var cc := center * content_scale
	var half := 500.0 * content_scale
	img = img.get_region(Rect2i(int(cc.x - half), int(cc.y - half), int(half * 2), int(half * 2)))
	img.resize(512, 512, Image.INTERPOLATE_LANCZOS)
	img.save_png(ProjectSettings.globalize_path("res://").path_join("../build/product_unlock.png"))
	print("PRODUCT ICON DONE")
	get_tree().quit()

## Nacrta ikonicu app-a (krava na zelenom krugu) i snimi u res://icon.png (1024px).
func _make_icon() -> void:
	get_window().size = Vector2i(512, 512)
	var root := Node2D.new()
	add_child(root)
	# skaliraj "platno" 1024 na prozor 512 (viewport je 1920x1080 stretch, pa radimo u tim koordinatama)
	var center := Vector2(UI.W / 2, UI.H / 2)
	UI.poly(root, UI.rect_points(1000, 1000), Pal.GRASS_DARK, center)  # puna pozadina do ivica
	UI.circle(root, center, 470, Pal.GRASS)
	UI.circle(root, center, 420, Pal.HILL_MID)
	var f := AnimalFaces.build("cow")
	f.position = center + Vector2(0, 20)
	f.scale = Vector2(3.1, 3.1)
	root.add_child(f)
	await get_tree().create_timer(0.5).timeout
	var img := get_viewport().get_texture().get_image()
	# iseci kvadrat tačno oko kruga (uzimajući u obzir stretch skaliranje)
	var content_scale := minf(img.get_width() / UI.W, img.get_height() / UI.H)
	var c := center * content_scale
	var half := 480.0 * content_scale
	img = img.get_region(Rect2i(int(c.x - half), int(c.y - half), int(half * 2), int(half * 2)))
	img.resize(1024, 1024, Image.INTERPOLATE_LANCZOS)
	# kružna maska — legacy launcheri (npr. Huawei) ne maskiraju sami
	for y in 1024:
		for x in 1024:
			var d := Vector2(x - 511.5, y - 511.5).length()
			if d > 508.0:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
			elif d > 500.0:
				var px := img.get_pixel(x, y)
				px.a = (508.0 - d) / 8.0
				img.set_pixel(x, y, px)
	img.save_png(ProjectSettings.globalize_path("res://icon.png"))

	# Android adaptive: pozadina (puna zelena) + prednji plan (krava, transparentno, safe zone)
	var bg := Image.create(432, 432, false, Image.FORMAT_RGBA8)
	bg.fill(Color("#F7F0E4"))  # krem — ista pozadina kao splash (brend)
	bg.save_png(ProjectSettings.globalize_path("res://icon_adaptive_bg.png"))

	root.queue_free()
	var fg_root := Node2D.new()
	add_child(fg_root)
	get_viewport().transparent_bg = true
	var f2 := AnimalFaces.build("cow")
	f2.position = center
	f2.scale = Vector2(2.3, 2.3)  # manja — adaptive safe zone je centralnih ~66%
	fg_root.add_child(f2)
	await get_tree().create_timer(0.4).timeout
	var fg := get_viewport().get_texture().get_image()
	fg = fg.get_region(Rect2i(int(c.x - half), int(c.y - half), int(half * 2), int(half * 2)))
	fg.resize(432, 432, Image.INTERPOLATE_LANCZOS)
	fg.save_png(ProjectSettings.globalize_path("res://icon_adaptive_fg.png"))

	# boot splash: logo na transparentnoj podlozi (bg boja ide iz project settings)
	fg_root.queue_free()
	var sp_root := Node2D.new()
	add_child(sp_root)
	var lg := Sprite2D.new()
	lg.texture = load("res://art/svg/logo-open.svg")
	lg.position = center
	lg.scale = Vector2.ONE * 1.15
	sp_root.add_child(lg)
	await get_tree().create_timer(0.4).timeout
	var sp := get_viewport().get_texture().get_image()
	var sp_half := 310.0 * content_scale
	sp = sp.get_region(Rect2i(int(c.x - sp_half), int(c.y - sp_half), int(sp_half * 2), int(sp_half * 2)))
	sp.resize(620, 620, Image.INTERPOLATE_LANCZOS)
	sp.save_png(ProjectSettings.globalize_path("res://boot_splash.png"))

	print("ICON DONE")
	get_tree().quit()

## Prođe kroz sve ekrane (za headless proveru): godot --headless --path . -- --smoke
func _smoke_test() -> void:
	for screen_name in SCREENS:
		goto(screen_name)
		for i in 10:
			await get_tree().process_frame
		print("SMOKE OK: ", screen_name)
	print("SMOKE DONE")
	get_tree().quit()

func goto(screen_name: String) -> void:
	if screen_name == "hub" or screen_name == "jungle":
		last_world = screen_name
	if current:
		current.queue_free()
	current = SCREENS[screen_name].new()
	add_child(current)
