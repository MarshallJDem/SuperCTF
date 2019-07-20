extends CPUParticles2D


# Called when the node enters the scene tree for the first time.
func _ready():
	$Death_Timer.connect("timeout", self, "_death_timer_ended");
	

func _death_timer_ended():
	print("die");
	queue_free();
	
