tool
extends RichTextEffect

# Syntax: [ghost wait=5.0 duration=5.0][/ghost]

# Define the tag name.
var bbcode = "chat"

func _process_custom_fx(char_fx):
	# Get parameters, or use the provided default value if missing.
	var duration = char_fx.env.get("duration", 3.0)
	var wait = char_fx.env.get("wait", 5.0)
	var alpha = 1.0 - (max((char_fx.elapsed_time - wait), 0.0) / duration);
	if Globals.is_typing_in_chat:
		alpha = 1.0;
	char_fx.color.a = alpha
	return true
