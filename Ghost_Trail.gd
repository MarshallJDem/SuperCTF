extends Sprite


# Called when the node enters the scene tree for the first time.
func _ready():
	$Death_Timer.connect("timeout", self, "_death_timer_ended");
func _process(delta):
	if $Death_Timer.time_left > 0:
		modulate = Color(1, 1, 1, $Death_Timer.time_left / $Death_Timer.wait_time);
func _death_timer_ended():
	queue_free()