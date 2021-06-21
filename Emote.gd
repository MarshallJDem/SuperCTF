extends Node2D

#how long the emote will show
var emote_time_length = 2

func _ready() -> void:
	$"Still Emote".connect("timeout", self, "_stop_emote")

func _emote(emote_number):
	$"Emote Timer".wait_time = emote_time_length
	$"Emote Timer".start()
	
	$"Still Emote".visible = true
	
	pass
func _stop_emote():
	$"Still Emote".visible = false
	
func _process(delta: float) -> void:
	if emote_time_length != 0:
		var time_left_decimal = $"Emote Timer".time_left/emote_time_length
	
		if time_left_decimal < 0.1:
			$"Still Emote".modulate.a = time_left_decimal
