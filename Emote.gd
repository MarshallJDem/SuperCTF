extends Node2D

#default amount of time for the emote to appear then disappear
var default_number_of_loops : int = 3
var fading = false
var emoting = false
#is the animation that is being run the starting one?
#var starting_animation = false

#var middle_animation = false

var number_of_loops = -1

var loops_left = 0



func _ready() -> void:
	#$"Emote Timer".connect("timeout", self, "_fade_emote")
	$"Fade Timer".connect("timeout", self, "_stop_emote")
	#$"AnimationPlayer".connect("animation_finished", self, "_animation_ended")
	
	
	
func _process(delta: float) -> void:
	#make button press activate _emote()
	if Input.is_action_just_pressed("score_board"):
		_emote(2)
	if Input.is_action_just_pressed("clickL"):
		_emote(1)
	
	if fading:
		if $"Fade Timer".wait_time != 0:
			$"Still Emote".modulate.a = $"Fade Timer".time_left/$"Fade Timer".wait_time
	
	
	
#load the emote and then emote it
func _emote(emote_number, emote_length : int = default_number_of_loops ):
	if not emoting:
		number_of_loops = emote_length
		emoting = true
		$"Still Emote".texture = load("res://Assets/Emotes/emote_"+ str(emote_number)+ ".png")
		
		$AnimationPlayer.play("Emote_bounce_start")
		
		$"Still Emote".modulate.a = 1
		$"Still Emote".visible = true
	
#start emote fading
func _fade_emote():
	fading = true
	$AnimationPlayer.play("Emote_bounce_end")
	$"Fade Timer".start()
	

		
		
		


#Make emote invisible
func _stop_emote():
	$"Still Emote".visible = false
	fading = false
	emoting = false
	


func _animation_ended():
	print("DUCK!!!!!!!!!!!!")
	print($AnimationPlayer.current_animation)
	if $AnimationPlayer.get_current_animation() == "Emote_bounce_start":
		$AnimationPlayer.play("Emote_bounce_middle")
		
		if number_of_loops <0 :
			loops_left = number_of_loops
		else:
			loops_left = default_number_of_loops
		
	elif $AnimationPlayer.get_current_animation() == "Emote_bounce_middle":
		loops_left -= 1
		if loops_left <= 0:
			_fade_emote()
		else:
			$AnimationPlayer.play("Emote_bounce_middle")
			
			
		

#func set_emote_timing(time):
#	#Make sure the timers and animation speed match the emote time length
#	if time != 0:
#		$AnimationPlayer.playback_speed = 1 / time 
#
#	$"Emote Timer".wait_time = (2.0/3.0)*time
#
#	$"Fade Timer".wait_time = (1.0/3.0)*time
#
