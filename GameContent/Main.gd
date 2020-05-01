extends Node2D


var Bullet_Death_Particles = preload("res://GameContent/Bullet_Death_Particles.tscn");

# Called when the node enters the scene tree for the first time.
func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE);
	if !Globals.testing:
		$Test_Player.queue_free();
		
func _process(delta):
	
	#if abs($Music_Audio.pitch_scale - target_music_pitch) < 0.03:
	#	$Music_Audio.set_pitch_scale(target_music_pitch);
	#else:
	#	var change = 0.4 * delta;
	#	if $Music_Audio.pitch_scale > target_music_pitch:
	#		change *= -1;
	#	$Music_Audio.set_pitch_scale($Music_Audio.pitch_scale + change);
	pass;
	
	
var target_music_pitch = 1.0;
func speedup_music():
	target_music_pitch = 1.1;

func slowdown_music():
	target_music_pitch = 1.0;
