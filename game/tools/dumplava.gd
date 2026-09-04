extends SceneTree
func _initialize() -> void:
	var out := "/private/tmp/claude-501/-Users-manevskiognjen-ProjectsFlutter-moja-farma/9b73e88a-ac81-486e-be55-8550f54cebc2/scratchpad/lavaf"
	DirAccess.make_dir_recursive_absolute(out)
	for i in 24:
		var tex: Texture2D = load("res://art/svg/lava-pool-%d.svg" % (i + 1))
		tex.get_image().save_png("%s/%d.png" % [out, i + 1])
	print("saved 24")
	quit()
