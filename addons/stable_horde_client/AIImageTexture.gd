# An ImageTexture coming from AI Generation (such as Stable Diffusion)
class_name AIImageTexture
extends ImageTexture

const FILENAME_TEMPLATE := "{prompt}_{gen_seed}"
const DIRECTORY_TEMPLATE := "{prompt}_{sampler_name}_{steps}"

# The prompt which generated this image
var prompt: String
# The seed which generated this image
var gen_seed : String
# The sampler which generated this image
var sampler_name: String
# The amount of steps used to generate this image
var steps: int
# The server ID which generared this image
var server_id: String
# The server name which generated this image
var server_name: String
# We store the image data to be able to save it later
# I can't figure how to get an Image back from an ImageTexture,
# so I need to store it explicitly
var image: Image

func _init(
		_prompt: String, 
		_gen_seed: String, 
		_sampler_name: String, 
		_server_id: String, 
		_server_name: String, 
		_steps: int,
		_image: Image) -> void:
	._init()
	prompt = _prompt
	gen_seed = _gen_seed
	sampler_name = _sampler_name
	steps = _steps
	server_name = _server_name
	server_id = _server_id
	image = _image

func get_filename() -> String:
	var fmt := {
		"prompt": prompt,
		"gen_seed": gen_seed
	}
	return(FILENAME_TEMPLATE.format(fmt))

func get_dirname() -> String:
	var fmt := {
		"prompt": prompt,
		"sampler_name": sampler_name,
		"steps": steps,
	}
	return(DIRECTORY_TEMPLATE.format(fmt))

func save_in_dir(save_dir_path: String) -> void:
	var dir = Directory.new()
	var error = dir.open(save_dir_path)
	if error != OK:
		dir.make_dir(save_dir_path)
	error = dir.open(save_dir_path)
	if error != OK:
		push_error("Could not create directory: " + save_dir_path)
		return
	var fmt = {
		"save_dir_path": save_dir_path,
		"relative_dir": get_dirname(),
		"filename": get_filename()
	}
	var filename = "{save_dir_path}/{relative_dir}/{filename}.png".format(fmt)
	dir.make_dir(get_dirname())
	error = image.save_png(filename)
	
