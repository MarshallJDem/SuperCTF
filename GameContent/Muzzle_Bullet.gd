extends Node2D

var team_id;

var sprite_B = preload("res://Assets/Weapons/muzzle_bullet_B.png");
var sprite_R = preload("res://Assets/Weapons/muzzle_bullet_R.png");


# Called when the node enters the scene tree for the first time.
func _ready():
	var _err = $Death_Timer.connect("timeout", self, "_death_timer_ended");
	if team_id == 0:
		$Sprite.set_texture(sprite_B);
	else:
		$Sprite.set_texture(sprite_R);
	
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
	
