# An ImageTexture coming from AI Generation (such as Stable Diffusion)
class_name AIImageTexture
extends ImageTexture

const FILENAME_TEMPLATE := "{gen_seed}_{prompt}"
const DIRECTORY_TEMPLATE := "{sampler_name}_{steps}_{prompt}"

# The prompt which generated this image
var prompt: String
# The seed which generated this image
var gen_seed : String
# The sampler which generated this image
var sampler_name: String
# The amount of steps used to generate this image
var steps: int
# The worker ID which generared this image
var worker_id: String
# The worker name which generated this image
var worker_name: String
# We store the image data to be able to save it later
# I can't figure how to get an Image back from an ImageTexture,
# so I need to store it explicitly
var image: Image

func _init(
		_prompt: String, 
		_gen_seed: String, 
		_sampler_name: String, 
		_worker_id: String, 
		_worker_name: String, 
		_steps: int,
		_image: Image) -> void:
	._init()
	prompt = _prompt
	gen_seed = _gen_seed
	sampler_name = _sampler_name
	steps = _steps
	worker_name = _worker_name
	worker_id = _worker_id
	image = _image

func get_filename() -> String:
	var fmt := {
		"prompt": prompt,
		"gen_seed": gen_seed,
	}
	var filename = sanitize_filename(FILENAME_TEMPLATE.format(fmt)).substr(0,100)
	return(filename)

func get_dirname() -> String:
	var fmt := {
		"prompt": prompt,
		"sampler_name": sampler_name,
		"steps": steps,
	}
	var dirname = sanitize_filename(DIRECTORY_TEMPLATE.format(fmt)).substr(0,100)
	return(dirname)

func get_full_save_dir_path(save_dir_path: String) -> String:
	var fmt = {
		"save_dir_path": save_dir_path,
		"relative_dir": get_dirname(),
	}
	var dirname = "{save_dir_path}/{relative_dir}".format(fmt)
	return(dirname)

func get_full_filename_path(save_dir_path: String) -> String:
	var fmt = {
		"save_dir_path": save_dir_path,
		"relative_dir": get_dirname(),
		"filename": get_filename()
	}
	var filename = "{save_dir_path}/{relative_dir}/{filename}.png".format(fmt)
	return(filename)

func save_in_dir(save_dir_path: String) -> void:
	var dir = Directory.new()
	var error = dir.open(save_dir_path)
	if error != OK:
		dir.make_dir(save_dir_path)
	error = dir.open(save_dir_path)
	if error != OK:
		push_error("Could not create directory: " + save_dir_path)
		return
	var filename = get_full_filename_path(save_dir_path)
	dir.make_dir(get_dirname())
	error = image.save_png(filename)
	
static func sanitize_filename(filename: String) -> String:
	var replace_chars = [
		'/',
		'\\',
		'?',
		'%',
		'*',
		'|',
		'"',
		"'",
		'<',
		'>',
		'.',
		',',
		';',
		'=',
		'(',
		')',
		' ',
	]
	for c in replace_chars:
		filename = filename.replace(c,'_')
	return(filename)
