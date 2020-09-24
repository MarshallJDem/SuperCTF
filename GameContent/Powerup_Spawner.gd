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
	get_tree().connect("connected_to_server",self, "_connected_to_server");
	_used();
	set_network_master(1);
	if Globals.testing:
		$Spawner_Timer.wait_time = 5;
		var n = randi()%4+1; #%11+1 means random number 1-10
		spawn_powerup(n);

func _connected_to_server():
	if !get_tree().is_network_server() and !Globals.testing:
		rpc("request_update");
func _round_started():
	_used();

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
	$Spawner_Timer.stop();

# Called by client on server to ask for an update on the spawner state
master func request_update():
	var id = get_tree().get_rpc_caller_id();
	print("this dude wants AN UPDATE??");
	rpc("receive_update",$Spawner_Timer.time_left,powerup_type,powerup_used, $Powerup.visible);

# Called by the server on the client to send them details on current state
puppet func receive_update(time_left, type, used, v):
	print("WOWZ I GOT MY UPDATE :OOOO");
	if !used:
		spawn_powerup(type);
	else:
		powerup_used = used;
		powerup_type = type;
		$Powerup.visible = v;
		$Spawner_Timer.stop();
		$Spawner_Timer.wait_time = time_left;
		$Spawner_Timer.start();

remotesync func _used():
	powerup_used = true;
	$Powerup.visible = false; 
	$Spawner_Timer.stop();
	$Spawner_Timer.wait_time = 20;
	$Spawner_Timer.start();

func _animation_timer_ended():
	$Powerup.frame = ($Powerup.frame + 1)%$Powerup.hframes;


func _spawner_timer_ended():
	var n = randi()%4+1; #%11+1 means random number 1-10
	if Globals.testing:
		spawn_powerup(n);
	elif get_tree().is_network_server():
		rpc("spawn_powerup",n);
	
