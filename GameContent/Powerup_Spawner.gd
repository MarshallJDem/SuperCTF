extends Node2D

# 1 = Firerate Up
# 2 = Move speed up
# 3 = Ability Cooldown Down
# 4 = Dash rateup

var colors = ["black", "g","b","r","p","y"];
var powerup_used = true;
var powerup_type = 1;

func _ready():
	$Animation_Timer.connect("timeout",self,"_animation_timer_ended");
	get_tree().get_root().get_node("MainScene/NetworkController").connect("round_started", self, "_round_started");
	$Spawner_Timer.connect("timeout", self, "_spawner_timer_ended");
	if Globals.testing:
		$Spawner_Timer.wait_time = 5;
		var n = randi()%4+1; #%11+1 means random number 1-10
		spawn_powerup(n);
	else:
		_used();

func _round_started():
	$Spawner_Timer.stop();
	$Spawner_Timer.start();

func _process(delta):
	if $Spawner_Timer.time_left == 0:
		$Text.bbcode_text = "";
	else:
		$Text.bbcode_text = "[center][color=black]" + str(int($Spawner_Timer.time_left) + 1);

remotesync func spawn_powerup(n):
	$Powerup.visible = true; 
	powerup_used = false;
	powerup_type = n;
	var sprite = load("res://Assets/Items/powerup-" + colors[powerup_type] + ".png");
	$Powerup.set_texture(sprite);


remotesync func _used():
	powerup_used = true;
	$Powerup.visible = false; 
	$Spawner_Timer.start();

func _animation_timer_ended():
	$Powerup.frame = ($Powerup.frame + 1)%$Powerup.hframes;


func _spawner_timer_ended():
	var n = randi()%4+1; #%11+1 means random number 1-10
	if Globals.testing:
		spawn_powerup(n);
	elif get_tree().is_network_server():
		rpc("spawn_powerup",n);
	
