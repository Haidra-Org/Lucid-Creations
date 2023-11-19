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
	"ClipSkipSlider": "The number of CLIP language processor layers to skip",
	"SamplerMethod": "All samplers are very similar for the same seed, but might produce slightly different results.\bSamplers ending with _a tend to be better, but more random.\nk_heun, and k_dpm_2* double generation time and kudos cost for the same steps but converge faster.",
	"Seed": "You can provide your own seed (to regenerate a previous image), or leave blank to get a random seed",
	"Karras": "Improves image generation at lower steps. Basically magic.",
	"HiResFix": "For resolutions higher than 512x512, uses the 512x512 as the baseline for the composition of the higher resolution image.",
	"DenoisingStrength": "Low values attempt to retain the underlying image more. High values follow more of the prompt more.\n0 means the image will remain unchanged. 1 will completely replace the undelying image.",
	"PP": "Performing post-processing on the image incurs an extra 20% Kudos consumption per post-processor. Mouse over each selected post-processor to see what it does.",
	"RememberPrompt": "It will remember your prompt you had when you shut down Lucid Creations.",
	"LargerValues": "It allows you to specify very high values for resolution and steps. You will need to have the kudos upfront to request these.",
	"LoadSeedFromDisk": "If enabled, seeds will be also preset when loading previous generation jsons from disk",
	"Shared": "text2img images generated and their prompt, will be stored permanently and made accessible to the LAION non-profit to help train improved models. Shared resolutions receive a kudos discount as they cost less to store by the stable horde.",
	"AestheticRating": "How much do you like this image, subjectively an in isolation from the other images? Please rate it from 1 (I hate it) to 10 (I am in love with it!)\nEach rating will refund 5 kudos.\nRemember to press the submit ratings button once you've rated all images.!",
	"ArtifactsRating": "The artifacts rating for this image.\n0 for flawless generation that perfectly fits to the prompt.\n1 for small, hardly recognizable flaws.\n2 small flaws that can easily be spotted, but don not harm the aesthetic experience.\n3 for flaws that look obviously wrong, but only mildly harm the aesthetic experience.\n4 for flaws that look obviously wrong & significantly harm the aesthetic experience.\n5 for flaws that make the image look like total garbage",
	"BestOf": "From this set of generated images, is this the best one?\nIf you select a bestof, you are refunded 15 kudos. You do not need select a bestof if you rate all images, unless you've tied one image for top place.\nRemember to press the submit ratings button once you've rated all images.!",
	"SubmitRatings": "Will submit the aesthetic ratings and best-of selection. It's disabled until you've rated at least one image in the set. You can only rate images if you've selected to share them (in the options menu). Rating your images will refund some of the kudos used for the generations.",
	"ControlType": "By selecting a Control Type, you will request that the horde utilize the ControlNet technology to process the source image, which will provide significantly more accurate conversion, at the cost of processing time. Using this option will triple the kudos cost for this request and limit the amount of steps you can use.",
	"ImageIsControl": "When this option is selected, the source image will be treated the intermediate step of a ControlNet processing.",
	"FetchFromCivitAI": "Will search CivitAI for LoRa which match the provided text.",
	"FetchTIsFromCivitAI": "Will search CivitAI for Textual Inversions which match the provided text.",
	"ShowAllModels": "Will display an list of all known models, from which to select one manually.",
	"ShowAllLoras": "Will display an list of all known LoRas, from which to select one manually.",
	"ShowAllTIs": "Will display an list of all known Textual Inversions, from which to select one manually.",
	"WipeCache": "Will remove all CivitAI cached information. You will have to search for your loras once more after this.",
	"BlockList": "When enabled, the workers specified will NOT be used for generations (This option requires upfront kudos). When disabled only the workers specified will be used for the generation.",
	"WorkerAutoComplete": "Specify workers to use for this generation. Use the toggle below to specify using them as an allowlist or a blocklist. When models are selected, only workers which can generate any of those models will be shown.",
	"ShowAllWorkers": "Press this button to display and select available workers for your selected model.",
}

const META_DESCRIPTIONS = {
	"GFPGAN": "GFPGAN is a face-correcting model. Use it to ensure beautiful faces.",
	"RealESRGAN_x4plus": "RealESRGAN_x4plus is an 4X image upscaler. Using it incurs an extra 30% Kudos consumption.",
	"CodeFormers": "CodeFormers is a very powerful face-correcting model however it requires significant power, and therefore comes with an extra 30% Kudos consumption",
	"ModelHover": "Click to show information about this model.",
	"ModelDelete": "Click to remove this model from the list.",
	"ModelTrigger": "Click to inject this model's triggers into your prompt.",
	"LoRaHover": "Click to show information about this LoRa.",
	"LoRaDelete": "Click to remove this LoRa from the list.",
	"LoRaTrigger": "Click to inject this LoRa's triggers into your prompt.",
	"TIHover": "Click to show information about this Textual Inversion.",
	"TIDelete": "Click to remove this Textual Inversion from the list.",
	"TITrigger": "Click to inject this Textual Inversion's triggers into your prompt.",
	"TIEmbed": "Click to inject this Textual Inversion's embedding and strength into your prompt. Use this only if you've not autoinjecting this into your prompt.",
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
	if rect_global_position.y + info.rect_size.y > get_viewport().size.y:
		rect_global_position.y = get_viewport().size.y - info.rect_size.y - 10 
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
	if rect_global_position.y + info.rect_size.y > get_viewport().size.y:
		rect_global_position.y = get_viewport().size.y - info.rect_size.y 
	info.text = META_DESCRIPTIONS[rtl_meta]
	visible = true
	rect_size = info.rect_size

func _on_rtl_meta_unhovered(node: RichTextLabel) -> void:
	if current_hovered_node != node:
		return
	visible = false
