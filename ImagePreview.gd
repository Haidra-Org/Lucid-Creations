extends TextureRect

var source_image: Image = null
var source_path: String

func load_image_from_path(path: String) -> bool:
	"""Returns true if image load successful
	Else return false
	"""
	source_image = Image.new()
	source_path = path
	var error = source_image.load(path)
	if error != OK:
		var error_msg := "Couldn't load the image."
		push_error(error_msg)
		return false
	var image_texture = ImageTexture.new();
	image_texture.create_from_image(source_image)
	texture = image_texture
	return true
