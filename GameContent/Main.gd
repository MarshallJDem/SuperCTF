extends Node2D


var Bullet_Death_Particles = preload("res://GameContent/Bullet_Death_Particles.tscn");

# Called when the node enters the scene tree for the first time.
func _ready():
	Globals.options_menu_should_scale = true;
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE);
	if !Globals.testing:
		$Test_Player.call_deferred("queue_free");
	get_tree().set_screen_stretch(SceneTree.STRETCH_MODE_DISABLED, SceneTree.STRETCH_ASPECT_EXPAND,Vector2(1920,1080), 1);
func _process(delta):
	#get_tree().set_screen_stretch(SceneTree.STRETCH_MODE_DISABLED, SceneTree.STRETCH_ASPECT_IGNORE, Vector2(1920,1080));
	
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
