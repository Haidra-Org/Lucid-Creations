# An ImageTexture coming from AI Generation (such as Stable Diffusion)
class_name AIImageTexture
extends ImageTexture

const FILENAME_TEMPLATE := "{timestamp}_{gen_seed}"
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
# The model which was used to generate this image
var model: String
# The origin image for an img2img generation
var source_image_path: String = ''
# We store the image data to be able to save it later
# I can't figure how to get an Image back from an ImageTexture,
# so I need to store it explicitly
var image: Image
# The full information about this image
# We use this to store them to a file
var attributes: Dictionary
var timestamp: float
var image_horde_id: String

func _init(
		_prompt: String, 
		_imgen_params: Dictionary, 
		_gen_seed,
		_model: String, 
		_worker_id: String, 
		_worker_name: String,
		_timestamp: float,
		_image: Image,
		_image_horde_id: String) -> void:
	._init()
	prompt = _prompt
	attributes = _imgen_params.duplicate(true)
	attributes.erase('n')
	attributes['prompt'] = prompt
	gen_seed = _gen_seed
	attributes['seed'] = _gen_seed
	sampler_name = attributes['sampler_name']
	steps = attributes['steps']
	worker_name = _worker_name
	attributes['worker_name'] = worker_name
	model = _model
	attributes['model'] = model
	worker_id = _worker_id
	attributes['worker_id'] = worker_id
	image = _image
	image_horde_id = _image_horde_id
	timestamp = _timestamp
	
# This can be used to provide metadata for the source image in img2img requests
func set_source_image_path(image_path: String) -> void:
	source_image_path = image_path
	attributes['source_image_path'] = image_path

func get_filename() -> String:
	var fmt := {
		"timestamp": timestamp,
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

func get_full_filename_path(save_dir_path: String, extension = "png") -> String:
	var fmt = {
		"save_dir_path": save_dir_path,
		"relative_dir": get_dirname(),
		"filename": get_filename(),
		"extension": extension,
	}
	var filename = "{save_dir_path}/{relative_dir}/{filename}.{extension}".format(fmt)
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
	save_attributes_to_file(get_full_filename_path(save_dir_path, "json"))

# This assumes the parent directory has been created already
func save_attributes_to_file(filepath:String) -> void:
	var file = File.new()
	file.open(filepath, File.WRITE)
	file.store_string(JSON.print(attributes, '\t'))
	file.close()
	
static func sanitize_filename(filename: String) -> String:
	var replace_chars = [
		'/',
		':',
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
