extends Node2D

#how long the emote will show
var emote_time_length = 2
var fading = false
var emoting = false
func _ready() -> void:
	$"Emote Timer".connect("timeout", self, "_fade_emote")
	$"Fade Timer".connect("timeout", self, "_stop_emote")
	
	
	
func _process(delta: float) -> void:
	#make button press activate _emote()
	if Input.is_action_just_pressed("score_board"):
		_emote(2)
	if Input.is_action_just_pressed("clickL"):
		_emote(1)
	print($"Emote Timer".time_left)
	
	if fading:
		print($"Fade Timer".time_left)
		if $"Fade Timer".wait_time != 0:
			$"Still Emote".modulate.a = $"Fade Timer".time_left/$"Fade Timer".wait_time
	
	
	
#load the emote and then emote it
func _emote(emote_number):
	if not emoting:
		emoting = true
		$"Still Emote".texture = load("res://Assets/Emotes/emote_"+ str(emote_number)+ ".png")
		$"Emote Timer".wait_time = emote_time_length
		$"Emote Timer".start()
		$AnimationPlayer.play("Emote_bounce")
		
		$"Still Emote".modulate.a = 1
		$"Still Emote".visible = true
	
#start emote fading
func _fade_emote():
	fading = true
	$"Fade Timer".start()
	

		
		
		
#		if emote_time_length != 0:
#			var time_left_decimal = $"Emote Timer".time_left/emote_time_length
#			print(time_left_decimal)
#			if time_left_decimal < 0.3:
#				$"Still Emote".modulate.a = time_left_decimal * 3

#Make emote invisible
func _stop_emote():
	$"Still Emote".visible = false
	fading = false
	emoting = false
