extends PopupPanel

const DESCRIPTIONS = {
	"NegativePrompt": "When enabled, will display the negative prompt line you can edit",
	"Amount": "The amount of images to generate with this prompt",
	"ModelSelect": "The currently selected model which will be used to generate your prompt",
	"ModelTrigger": "If this button is enabled, this model requires a specific trigger to do its magic.\nPress it to add that trigger to the end of your prompt.",
	"ModelInfo": "Press this button to see more information about this model.",
	"TrustedWorkers": "When enabled, only trusted workers will fulfil this request at the cost of speed. Use this when you see any suspicious or irrelevant images",
	"NSFW": "When enabled, only workers which allow NSFW generations will fulfil this request, but you will ensure your requests will not be censored for NSFW content.",
	"CensorNSFW": "When enabled, requests which generate NSFW images will be automatically censored before being sent back to you.",
	"SaveAll": "Saves all currently generated images",
	"Width": "The width of the image to generate.\nValues over 576x576 require upfront kudos to generate.",
	"Height": "The height of the image to generate.\nValues over 576x576 require upfront kudos to generate.",
	"StepsSlider": "How many iterations to take to create a good image.\nKeep this value between 30 and 40 for best time-to-result value.\nValues over 50 (or 25 for some samplers) require upfront kudos to generate.",
	"ConfigSlider": "How strongly the image should follow the prompt.\nHigher values will respect your prompt more. Lower values will let the AI be more creative.\nAKA 'Classifier Free Guidance Scale' or 'CFG'.",
	"SamplerMethod": "All samplers are very similar for the same seed, but might produce slightly different results.\bSamplers ending with _a tend to be better, but more random.\nk_heun, and k_dpm_2* double generation time and kudos cost for the same steps but converge faster.",
	"Seed": "You can provide your own seed (to regenerate a previous image), or leave blank to get a random seed",
	"Karras": "Improves image generation at lower steps. Basically magic.",
	"DenoisingStrength": "Low values attempt to retain the underlying image more. High values follow more of the prompt more.\n0 means the image will remain unchanged. 1 will completely replace the undelying image.",
	"PP": "Performing post-processing on the image incurs an extra 20% Kudos consumption per post-processor. Mouse over each selected post-processor to see what it does.",
	"RememberPrompt": "It will remember your prompt you had when you shut down Lucid Creations.",
	"LargerValues": "It allows you to specify very high values for resolution and steps. You will need to have the kudos upfront to request these.",
	"Shared": "text2img images generated and their prompt, will be stored permanently and made accessible to the LAION non-profit to help train improved models. Shared resolutions receive a kudos discount as they cost less to store by the stable horde.",
}

const META_DESCRIPTIONS = {
	"GFPGAN": "GFPGAN is a face-correcting model. Use it to ensure beautiful faces.",
	"RealESRGAN_x4plus": "RealESRGAN_x4plus is an 4X image upscaler. Using it incurs an extra 30% Kudos consumption.",
	"CodeFormers": "CodeFormers is a very powerful face-correcting model however it requires significant power, and therefore comes with an extra 30% Kudos consumption",
}

var current_hovered_node: Control

onready var info = $"%Info"

func _ready():
	# warning-ignore:return_value_discarded
	EventBus.connect("node_hovered",self, "_on_node_hovered")
	# warning-ignore:return_value_discarded
	EventBus.connect("node_unhovered",self, "_on_node_unhovered")
	# warning-ignore:return_value_discarded
	EventBus.connect("rtl_meta_hovered",self, "_on_rtl_meta_hovered")
	# warning-ignore:return_value_discarded
	EventBus.connect("rtl_meta_unhovered",self, "_on_rtl_meta_unhovered")

func _on_node_hovered(node: Control) -> void:
	if not DESCRIPTIONS.has(node.name):
		return
	info.rect_size = Vector2(0,0)
	current_hovered_node = node
	rect_global_position = current_hovered_node.rect_global_position + Vector2(current_hovered_node.rect_size.x + 10,0)
	if rect_global_position.x > get_viewport().size.x:
		rect_global_position.x = get_viewport().size.x - current_hovered_node.rect_size.x
	info.text = DESCRIPTIONS[node.name]
	visible = true
	rect_size = info.rect_size

func _on_node_unhovered(node: Control) -> void:
	if current_hovered_node != node:
		return
	visible = false

func _on_rtl_meta_hovered(node: RichTextLabel, rtl_meta: String) -> void:
	if not META_DESCRIPTIONS.has(rtl_meta):
		return
	info.rect_size = Vector2(0,0)
	current_hovered_node = node
	rect_global_position = current_hovered_node.rect_global_position + Vector2(current_hovered_node.rect_size.x + 10,0)
	if rect_global_position.x > get_viewport().size.x:
		rect_global_position.x = get_viewport().size.x - current_hovered_node.rect_size.x
	info.text = META_DESCRIPTIONS[rtl_meta]
	visible = true
	rect_size = info.rect_size

func _on_rtl_meta_unhovered(node: RichTextLabel) -> void:
	if current_hovered_node != node:
		return
	visible = false
