extends RichTextLabel

const TEXT = """[b]Contributors[/b]

Lead Developer: [url=Db0]Db0[/url]
UI: [url=illlustr]illlustr[/url]
"""

func _ready():
	bbcode_text = TEXT


func _on_Credits_meta_clicked(meta):
	match meta:
		"Db0":
			# warning-ignore:return_value_discarded
			OS.shell_open("https://dbzer0.com")
		"illlustr":
			# warning-ignore:return_value_discarded
			OS.shell_open("https://github.com/illlustr")
