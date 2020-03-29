extends Node2D

var spawner;
var used = false;
var type = 1;
# 1 = Speed Boost

func _ready():
	pass;

func _used():
	used = true;
	if Globals.testing:
		spawner._powerup_taken();
	if get_tree().is_network_server():
		spawner.rpc("_powerup_taken");
