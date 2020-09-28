extends Node2D


var sprite_top_B = preload("res://Assets/Abilities/forcefield_top_B.png");
var sprite_bottom_B = preload("res://Assets/Abilities/forcefield_bottom_B.png");

var sprite_top_R = preload("res://Assets/Abilities/forcefield_top_R.png");
var sprite_bottom_R = preload("res://Assets/Abilities/forcefield_bottom_R.png");

# The id of the player who place this forcefield
var player_id;
var team_id = -1;

var original_time_placed;

# Called when the node enters the scene tree for the first time.
func _ready():
	$Death_Timer.connect("timeout", self, "_death_timer_ended");
	$Death_Animation_Timer.connect("timeout", self, "_death_animation_timer_ended");
	$Animation_Timer.connect("timeout", self, "_animation_timer_ended");
	if team_id == 1:
		$Sprite_Top.set_texture(sprite_top_R);
		$Sprite_Bottom.set_texture(sprite_bottom_R);
	else:
		$Sprite_Top.set_texture(sprite_top_B);
		$Sprite_Bottom.set_texture(sprite_bottom_B);
	
	
	var puppet_time_placed = OS.get_system_time_msecs() - Globals.match_start_time;
	if !Globals.testing and get_tree().get_network_unique_id() != get_network_master():
		if (puppet_time_placed-original_time_placed)/1000.0 > $Death_Timer.wait_time:
			call_deferred("queue_free");
			return;
		$Death_Timer.wait_time += -(puppet_time_placed-original_time_placed)/1000.0;


func _process(delta):
	if $Death_Animation_Timer.time_left > 0:
		$Sprite_Top.modulate = Color(1,1,1, $Death_Animation_Timer.time_left / $Death_Animation_Timer.wait_time);
		$Sprite_Bottom.modulate = Color(1,1,1, $Death_Animation_Timer.time_left / $Death_Animation_Timer.wait_time);

func _death_timer_ended():
	$Death_Animation_Timer.start();

func _death_animation_timer_ended():
	queue_free();

func _animation_timer_ended():
	$Sprite_Top.frame = ($Sprite_Top.frame + 1) % $Sprite_Top.hframes;
