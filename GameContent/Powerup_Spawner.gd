extends Node2D

var spawner_id = 0;


func _ready():
	$Spawner_Timer.connect("timeout", self, "_spawner_timer_ended");
	if Globals.testing:
		$Spawner_Timer.wait_time = 5;
		$Spawner_Timer.start();
	else:
		spawn_powerup();

func _process(delta):
	if $Spawner_Timer.time_left == 0:
		$Text.bbcode_text = "";
	else:
		$Text.bbcode_text = "[center][color=black]POWERUP IN\n" + str(int($Spawner_Timer.time_left) + 1);

remotesync func spawn_powerup():
	var powerup = load("res://GameContent/Powerup.tscn").instance();
	powerup.position = position + Vector2(0, -15);
	powerup.type = randi()%5+1; #%11+1 means random number 1-10
	print(powerup.type);
	powerup.spawner = self;
	get_tree().get_root().get_node("MainScene").call_deferred("add_child", powerup);
	
remotesync func _powerup_taken():
	$Spawner_Timer.start();

func _spawner_timer_ended():
	if Globals.testing:
		spawn_powerup();
	if get_tree().is_network_server():
		rpc("spawn_powerup");
	
