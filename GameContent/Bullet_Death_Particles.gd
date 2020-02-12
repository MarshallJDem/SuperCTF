extends CPUParticles2D


# Called when the node enters the scene tree for the first time.
func _ready():
	var _err = $Death_Timer.connect("timeout", self, "_death_timer_ended");
	

func _death_timer_ended():
	queue_free();
	
