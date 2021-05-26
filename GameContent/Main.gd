extends Node2D


var Bullet_Death_Particles = preload("res://GameContent/Bullet_Death_Particles.tscn");

# Called when the node enters the scene tree for the first time.
func _ready():
	Globals.options_menu_should_scale = true;
	Globals.is_typing_in_chat = false;
	Globals.active_landmines = 0;
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE);
	if !Globals.testing and !Globals.localTesting:
		$Test_Player.call_deferred("free");
	get_tree().set_screen_stretch(SceneTree.STRETCH_MODE_DISABLED, SceneTree.STRETCH_ASPECT_EXPAND,Vector2(1920,1080), 1);

	
	
var target_music_pitch = 1.0;
func speedup_music():
	target_music_pitch = 1.1;

func slowdown_music():
	target_music_pitch = 1.0;
