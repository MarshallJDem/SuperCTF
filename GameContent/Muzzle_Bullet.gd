extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready():
	var _err = $Death_Timer.connect("timeout", self, "_death_timer_ended");
	
func _process(_delta):
	var progress = 1.0 - $Death_Timer.time_left/$Death_Timer.wait_time;
	var frame = int(progress * ($Sprite.hframes + 1)) - 1;
	if frame >= $Sprite.hframes:
		frame = $Sprite.hframes - 1;
	if frame < 0:
		frame = 0;
	$Sprite.frame = frame;

func _death_timer_ended():
	queue_free();
	
