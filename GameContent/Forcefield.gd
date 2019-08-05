extends KinematicBody2D

var player_id;
var team_id;

# Called when the node enters the scene tree for the first time.
func _ready():
	$Death_Timer.connect("timeout", self, "_death_timer_ended");
	$Death_Animation_Timer.connect("timeout", self, "_death_animation_timer_ended");
	$Death_Timer.wait_time = Globals.forcefield_cooldown;

func _process(delta):
	if $Death_Animation_Timer.time_left > 0:
		$Sprite.modulate = Color(1,1,1, $Death_Animation_Timer.time_left / $Death_Animation_Timer.wait_time);

func _death_timer_ended():
	$Death_Animation_Timer.start();

func _death_animation_timer_ended():
	queue_free();