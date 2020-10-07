extends Node2D
var look_direction;
var legs_frame;
var flag_team_id = -1;
# Called when the node enters the scene tree for the first time.
func _ready():
	$Death_Timer.connect("timeout", self, "_death_timer_ended");
	$Sprite_Head.frame = look_direction;
	$Sprite_Body.frame = look_direction;
	$Sprite_Gun.frame = look_direction;
	if flag_team_id == 0:
		$Sprite_Flag_B.visible = true;
	elif flag_team_id == 1:
		$Sprite_Flag_R.visible = true;
func _process(delta):
	if $Death_Timer.time_left > 0:
		modulate = Color(1, 1, 1, $Death_Timer.time_left / $Death_Timer.wait_time);
func _death_timer_ended():
	call_deferred("queue_free");
