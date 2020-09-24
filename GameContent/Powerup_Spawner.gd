extends Node2D

func _ready():
	get_tree().get_root().get_node("MainScene/NetworkController").connect("round_started", self, "_round_started");
	$Spawner_Timer.connect("timeout", self, "_spawner_timer_ended");
	if Globals.testing:
		$Spawner_Timer.wait_time = 5;
		var n = randi()%4+1; #%11+1 means random number 1-10
		spawn_powerup(n);

func _round_started():
	$Spawner_Timer.start();

func _process(delta):
	if $Spawner_Timer.time_left == 0:
		$Text.bbcode_text = "";
	else:
		$Text.bbcode_text = "[center][color=black]" + str(int($Spawner_Timer.time_left) + 1);

remotesync func spawn_powerup(n):
	$Powerup.respawn(n);
	
remotesync func _powerup_taken():
	$Spawner_Timer.start();

func _spawner_timer_ended():
	var n = randi()%4+1; #%11+1 means random number 1-10
	if Globals.testing:
		spawn_powerup(n);
	elif get_tree().is_network_server():
		rpc("spawn_powerup",n);
	
