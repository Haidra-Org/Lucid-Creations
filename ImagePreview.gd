extends TextureRect

var source_image: Image
var source_path: String

func load_image_from_path(path: String) -> void:
	source_image = Image.new()
	source_path = path
	var error = source_image.load(path)
	if error != OK:
		var error_msg := "Couldn't load the image."
		push_error(error_msg)
		return
	var image_texture = ImageTexture.new();
	image_texture.create_from_image(source_image)
	texture = image_texture
