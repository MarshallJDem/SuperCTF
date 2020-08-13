extends Node2D

var spawner;
var used = false;
var type = 1;

# 1 = Firerate Up
# 2 = Ability Cooldown Down
# 3 = Move speed up
# 4 = Dash rateup

var colors = ["black", "g","b","r","p","y"];

func _ready():
	$Animation_Timer.connect("timeout",self,"_animation_timer_ended");
	var sprite = load("res://Assets/Items/powerup-" + colors[type] + ".png");
	$Sprite.set_texture(sprite);

func _animation_timer_ended():
	$Sprite.frame = ($Sprite.frame + 1)%$Sprite.hframes;

func _used():
	used = true;
	if Globals.testing:
		spawner._powerup_taken();
	if get_tree().is_network_server():
		spawner.rpc("_powerup_taken");
