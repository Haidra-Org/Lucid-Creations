class_name Utils
extends Reference


# Shuffles all possible backgrounds in the game and selects one at random
# Retuns an ImageTexture
static func get_random_background() -> ImageTexture:
	var all_backgrounds := list_imported_in_directory("res://assets/backgrounds/")
	shuffle_array(all_backgrounds)
	var selected_background :String = all_backgrounds[0]
	if selected_background.ends_with('.web'):
		selected_background += 'p'
	var bpath: String = "res://assets/backgrounds/"
	var return_res := convert_texture_to_image(bpath + selected_background)
	return(return_res)

# Returns a an array of all images in a specific directory.
#
# Due to the way Godot exports work, we cannot look for image
# Files. Instead we have to explicitly look for their .import
# filenames, and grab the filename from there.
static func list_imported_in_directory(path: String, full_path := false) -> Array:
	var files := []
	var dir := Directory.new()
	# warning-ignore:return_value_discarded
	dir.open(path)
	# warning-ignore:return_value_discarded
	dir.list_dir_begin()
	while true:
		var file := dir.get_next()
		if file == "":
			break
		elif file.ends_with(".import"):
			if full_path:
				files.append(path + file.rstrip(".import"))
			else:
				files.append(file.rstrip(".import"))
	dir.list_dir_end()
	return(files)

# Randomize array through our own seed
# If avoid_cfc_rng, it will randomize using godot's internal randomizer
# use this for randomizations you do not care to repeat
static func shuffle_array(array: Array) -> void:
	var n = array.size()
	if n<2:
		return
	var j
	var tmp
	for i in range(n-1,0,-1):
		# Because there is a problem with the calling sequence of static classes,
		# if you call randi directly, you will not call CFUtils.randi
		# but call math.randi, so we call cfc.game_rng.randi() directly
		j = randi()%(i+1)
		tmp = array[j]
		array[j] = array[i]
		array[i] = tmp


# Converts a resource path to a texture, or a StreamTexture object
# (which you get with `preload()`)
# into an ImageTexture you can assign to a node's texture property.
static func convert_texture_to_image(texture, is_lossless = false) -> ImageTexture:
	var tex: StreamTexture
	if typeof(texture) == TYPE_STRING:
		tex = load(texture)
	else:
#		print_debug(texture)
		tex = texture
	var new_texture = ImageTexture.new();
	if is_lossless:
		new_texture.storage = ImageTexture.STORAGE_COMPRESS_LOSSLESS
	var image = tex.get_data()
	new_texture.create_from_image(image)
	return(new_texture)
