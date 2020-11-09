extends Node

var amplitude = 0
var priority = 0

var trans = Tween.TRANS_SINE
var easeness = Tween.EASE_IN_OUT

onready var camera = get_parent()

func start(duration = 0.2, frequency = 15, shake_size = 16, importance = 0, transs = Tween.TRANS_SINE, easee = Tween.EASE_IN_OUT):
	if importance >= priority:
		priority = importance
		amplitude = shake_size
		trans = transs
		easeness = easee
		
		$Duration.wait_time = duration
		$Frequency.wait_time = 1 / float(frequency)
		$Duration.start()
		$Frequency.start()



func _new_shake():
	var rand = Vector2()
	rand.x =rand_range(-amplitude, amplitude)
	rand.y =rand_range(-amplitude, amplitude)
	
	$"Shake Tween".interpolate_property(camera, "offset", camera.offset, rand, $Frequency.wait_time, trans, easeness)
	$"Shake Tween".start()
	
func reset():
	$"Shake Tween".interpolate_property(camera, "offset", camera.offset, Vector2(), $Frequency.wait_time, trans, easeness)
	$"Shake Tween".start()
	
	priority = 0
	

func _on_Frequency_timeout() -> void:
	_new_shake()


func _on_Duration_timeout() -> void:
	reset()
	$Frequency.stop()






