extends RichTextLabel

const TEXT = """Welcome to Lucid Creations, the easiest way to use Stable Diffusion for free!

You can use this software to generate images using AI and then save them to your disk.

Be aware that this software is relying on the [url=stable horde]Stable Horde crowdsourced cluster[/url], and therefore your speed will depend on how many other people are using this service at the same time and the amount of Kudos your have.

You can [url=register]Register an account[/url] for free, to track your individual contributions and usage.
You can also join your own GPU to the horde which will provide you with Kudos and therefore increase your priority.

This is a free service and relying solely on contributors such as yourself.

Enjoy, let us know of any [url=issue tracker]issues or suggestions[/url] and join us on [url=discord]discord[/url]
"""

func _ready():
	bbcode_text = TEXT

func _on_Infodump_meta_clicked(meta):
	match meta:
		"register":
			# warning-ignore:return_value_discarded
			OS.shell_open("https://aihorde.net/register")
		"stable horde":
			# warning-ignore:return_value_discarded
			OS.shell_open("https://aihorde.net")
		"issue tracker":
			# warning-ignore:return_value_discarded
			OS.shell_open("https://github.com/db0/Lucid-Creations/issues")
		"discord":
			# warning-ignore:return_value_discarded
			OS.shell_open("https://discord.gg/3DxrhksKzn")
