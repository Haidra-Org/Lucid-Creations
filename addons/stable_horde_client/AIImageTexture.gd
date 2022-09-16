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

func _init(_prompt: String, _gen_seed: String, _sampler_name: String, _steps: int) -> void:
	._init()
	prompt = _prompt
	gen_seed = _gen_seed
	sampler_name = _sampler_name
	steps = _steps

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
