extends Node2D

var radius;
var team_id;
var player_id;
var alpha = 0.4;

func _ready():
	$Death_Timer.connect("timeout", self, "_death_timer_ended");
	$Flash_Timer.connect("timeout", self, "_flash_timer_ended");
	radius = get_tree().get_root().get_node("MainScene/NetworkController").get_game_var("grenadeRadius");
	$Area2D/CollisionShape2D.scale = Vector2(radius, radius);
	if team_id == 1:
		$BottomRed.visible = true;
		$MainRed.visible = true;
	else:
		$BottomBlue.visible = true;
		$MainBlue.visible = true;

func _process(delta):
	update();

func _draw():
	var color = Color(0,0,1,alpha);
	if team_id == 1:
		color = Color(1,0,0,alpha);
	#draw_circle(Vector2.ZERO, radius, color);

func _death_timer_ended():
	call_deferred("queue_free");

func _flash_timer_ended():
	if alpha == 0.4:
		alpha = 0.1;
	else:
		alpha = 0.4;
