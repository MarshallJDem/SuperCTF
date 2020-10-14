extends Node2D

var team_id = -1
var xFrame;

var sprite_B = preload("res://Assets/Player/player_death_B.png");
var sprite_R = preload("res://Assets/Player/player_death_R.png");

# Called when the node enters the scene tree for the first time.
func _ready():
	var _err = $Death_Timer.connect("timeout", self, "_death_timer_ended");
	if team_id == 1:
		$Sprite.set_texture(sprite_R);
	else:
		$Sprite.set_texture(sprite_B);
	$Sprite.frame_coords.x = xFrame;

func _process(_delta):
	var progress = 1.0 - $Death_Timer.time_left/$Death_Timer.wait_time;
	var frame = int(progress * ($Sprite.vframes));
	if frame >= $Sprite.vframes:
		frame = $Sprite.vframes - 1;
	if frame < 0:
		frame = 0;
	
	$Sprite.frame_coords.y = frame;

func _death_timer_ended():
	call_deferred("free");
	
