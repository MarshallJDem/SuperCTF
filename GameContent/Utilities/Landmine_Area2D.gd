extends Area2D

# Called when the node enters the scene tree for the first time.
func _ready():
	var _err = self.connect("area_entered",self, "_area_entered");
	get_parent().get_node("Detonation_Timer").connect("timeout", self, "_detonation_timer_ended");
	get_parent().get_node("Death_Timer").connect("timeout", self, "_death_timer_ended");

func _detonation_timer_ended():
	if get_tree().is_network_server():
		monitoring = true;
	get_parent().get_node("Death_Timer").start();

func _death_timer_ended():
	get_parent().call_deferred("queue_free");
# Called when this area enters another area
func _area_entered(body):
	if !get_tree().is_network_server():
		return;
	if body.is_in_group("Player_Bodies"):
		collided_with_player(body.get_parent());

# Called when this bullet collides with a wall
func collided_with_player(player):
	var mine = get_parent();
	# If mine and player are on same team, ignore
	if mine.team_id == player.team_id:
		return;
	# Otherwise receive a hit from the grenade
	player.rpc("receive_hit", mine.player_id, 3);
