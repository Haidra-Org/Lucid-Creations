extends RichTextLabel

const TEXT = """Welcome to Stable Diffusion on Godot!

You can use this software to generate images using AI and then save them to your disk.

Be aware that this software is relying on the [url=stable horde]Stable Horde crowdsourced cluster[/url], and therefore your speed will depend on how many other people are using this service at the same time.

You can [url=register]Register an account[/url] for free, to track your individual contributions and usage.
You can also joing your own GPU to the horde which will provide you with Kudos and therefore increase your priority.

This is a free service and relying solely on contributors such as yourself.

Enjoy and let us know of any [url=issue tracker]issues or suggestions[/url]
"""

func _ready():
	bbcode_text = TEXT

func _on_Infodump_meta_clicked(meta):
	match meta:
		"register":
			# warning-ignore:return_value_discarded
			OS.shell_open("https://stablehorde.net/register")
		"stable horde":
			# warning-ignore:return_value_discarded
			OS.shell_open("https://stablehorde.net")
		"issue tracker":
			# warning-ignore:return_value_discarded
			OS.shell_open("https://github.com/db0/Stable-Horde-Client/issues")
