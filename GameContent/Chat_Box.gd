extends RichTextLabel


func _ready() -> void:
	pass
	
	
	
func _process(delta: float) -> void:
	#if typing rest the timer
	if Globals.is_typing_in_chat:
		$Chat_Fade_Timer.start()
	
	#for the last 2 seconds of the timer fade the text out
	if $Chat_Fade_Timer.time_left < 2:
		modulate.a = $Chat_Fade_Timer.time_left/2
	#if the timer still has more than 2 seconds left the alpha = 1
	else:
		modulate.a = 1
	
