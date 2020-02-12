extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready():
	$Death_Timer.connect("timeout", self, "_death_timer_ended");
	
func _process(delta):
	var progress = 1.0 - $Death_Timer.time_left/$Death_Timer.wait_time;
	var frame = int(progress * ($Sprite.hframes + 1)) - 1;
	if frame >= $Sprite.hframes:
		frame = $Sprite.hframes - 1;
	$Sprite.frame = frame;

func _death_timer_ended():
	queue_free();
	
