extends Node2D

#default amount of time for the emote to appear then disappear
var default_emote_time_length : float = 3
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
	
	if fading:
		if $"Fade Timer".wait_time != 0:
			$"Still Emote".modulate.a = $"Fade Timer".time_left/$"Fade Timer".wait_time
	
	
	
#load the emote and then emote it
func _emote(emote_number, emote_length : float = default_emote_time_length ):
	if not emoting:
		set_emote_timing(emote_length)
		emoting = true
		$"Still Emote".texture = load("res://Assets/Emotes/emote_"+ str(emote_number)+ ".png")
		
		$"Emote Timer".start()
		$AnimationPlayer.play("Emote_bounce")
		
		$"Still Emote".modulate.a = 1
		$"Still Emote".visible = true
	
#start emote fading
func _fade_emote():
	fading = true
	$"Fade Timer".start()
	

		
		
		


#Make emote invisible
func _stop_emote():
	$"Still Emote".visible = false
	fading = false
	emoting = false
	


func set_emote_timing(time):
	#Make sure the timers and animation speed match the emote time length
	if time != 0:
		$AnimationPlayer.playback_speed = 1 / time 
	
	$"Emote Timer".wait_time = (2.0/3.0)*time
	
	$"Fade Timer".wait_time = (1.0/3.0)*time
	
