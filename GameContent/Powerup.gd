extends Node2D

var used = false;
var type = 1;

# 1 = Firerate Up
# 2 = Move speed up
# 3 = Ability Cooldown Down
# 4 = Dash rateup

var colors = ["black", "g","b","r","p","y"];

func _ready():
	$Animation_Timer.connect("timeout",self,"_animation_timer_ended");

func respawn(n):
	visible = true; 
	used = false;
	type = n;
	var sprite = load("res://Assets/Items/powerup-" + colors[type] + ".png");
	$Sprite.set_texture(sprite);
	
func _animation_timer_ended():
	$Sprite.frame = ($Sprite.frame + 1)%$Sprite.hframes;

remotesync func die():
	visible = false; 
	used = true;

func _used():
	used = true;
	visible = false; 
	if Globals.testing:
		get_parent()._powerup_taken();
		die();
	else:
		rpc("die");
	if get_tree().is_network_server():
		get_parent().rpc("_powerup_taken");
