extends TextureRect

var source_image: Image

func load_image_from_path(path: String) -> void:
	source_image = Image.new()
	source_image.load(path)
	var image_texture = ImageTexture.new();
	image_texture.create_from_image(source_image)
	texture = image_texture
