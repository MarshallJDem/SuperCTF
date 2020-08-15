extends Node2D

var spawner;
var used = false;
var type = 1;

# 1 = Firerate Up
# 2 = Move speed up
# 3 = Ability Cooldown Down
# 4 = Dash rateup

var colors = ["black", "g","b","r","p","y"];

func _ready():
	$Animation_Timer.connect("timeout",self,"_animation_timer_ended");
	var sprite = load("res://Assets/Items/powerup-" + colors[type] + ".png");
	$Sprite.set_texture(sprite);

func _animation_timer_ended():
	$Sprite.frame = ($Sprite.frame + 1)%$Sprite.hframes;

remotesync func die():
	call_deferred("queue_free");

func _used():
	used = true;
	if Globals.testing:
		spawner._powerup_taken();
		die();
	else:
		rpc("die");
	if get_tree().is_network_server():
		spawner.rpc("_powerup_taken");
