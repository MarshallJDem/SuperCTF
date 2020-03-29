   extends Node2D

# The ID of the player who shot this laser
var player_id = -1;
# The team id this laser belongs to
var team_id = -1;
var WIDTH_PMODIFIER = 0;


func _ready():
	$Death_Timer.connect("timeout", self, "_death_timer_ended");

func _process(delta):
	
	
	update();

func _draw():
	var size = WIDTH_PMODIFIER + get_tree().get_root().get_node("MainScene/NetworkController").get_game_var("laserWidth");
	var length = get_tree().get_root().get_node("MainScene/NetworkController").get_game_var("laserLength");
	
	$Area2D/CollisionShape2D.scale = Vector2(size/3, length);
	
	var red = 1 if team_id == 1 else 0;
	var green = 10.0/255.0 if team_id == 1 else 130.0/255.0;
	var blue = 1 if team_id == 0 else 0;
	var lightener = 0.2;
	red = red + lightener;
	green = green + lightener;
	blue = blue + lightener;
	var progress = (1 - ($Death_Timer.time_left / $Death_Timer.wait_time))
	var shrinkage = 0 * progress;
	draw_line(Vector2(0,shrinkage), Vector2(0, length - shrinkage), Color(red, green, blue, 1 - progress), size-2);
	draw_line(Vector2(0,shrinkage), Vector2(0, length - shrinkage), Color(red + 0.3, green + 0.3, blue + 0.3, 1 - progress), size/1.5);
	draw_line(Vector2(0,shrinkage), Vector2(0, length - shrinkage), Color(red + 0.7, green + 0.7, blue + 0.7, 1 - progress), size/2.5);

# Called when the death timer ends;
func _death_timer_ended():
	get_parent().remove_child(self);
	queue_free();
