extends Node2D

#how long the emote will show
var emote_time_length = 2
var fading = false

func _ready() -> void:
	$"Emote Timer".connect("timeout", self, "_stop_emote")
	$"Fade Timer".connect("timeout", self, "_stop_fade")

func _emote(emote_number):
	$"Emote Timer".wait_time = emote_time_length
	$"Emote Timer".start()
	
	$"Still Emote".visible = true
	$"Still Emote".modulate.a = 1


func _stop_emote():
	fading = true
	$"Fade Timer".start()
	
func _process(delta: float) -> void:
	#make button press activate _emote()
	if Input.is_action_just_pressed("score_board"):
		_emote(1)
	print($"Emote Timer".time_left)
	if fading:
		print($"Fade Timer".time_left)
		if $"Fade Timer".wait_time != 0:
			$"Still Emote".modulate.a = $"Fade Timer".time_left/$"Fade Timer".wait_time
		
		
		
#		if emote_time_length != 0:
#			var time_left_decimal = $"Emote Timer".time_left/emote_time_length
#			print(time_left_decimal)
#			if time_left_decimal < 0.3:
#				$"Still Emote".modulate.a = time_left_decimal * 3

func _stop_fade():
	$"Still Emote".visible = false
	fading =false
