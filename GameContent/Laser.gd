extends Node2D

# The ID of the player who shot this laser
var player_id = -1;
# The team id this laser belongs to
var team_id = -1;
var target_pos;
var direction;
var size;
var is_blank = false;

func _ready():
	$Death_Timer.connect("timeout", self, "_death_timer_ended");
	#size = get_tree().get_root().get_node("MainScene/NetworkController").get_game_var("laserWidth");
	target_pos -= position;
	
	if is_blank:
		$Area2D.monitorable = false;
		$Area2D.monitoring = false;
	else:
		$Area2D.monitorable = true;
		$Area2D.monitoring = true;
	
	$Area2D.rotation = Vector2(0,0).angle_to_point(target_pos) + PI/2;
	$Area2D/CollisionShape2D.shape.set_extents(Vector2(size/2, Vector2(0,0).distance_to(target_pos)/2));
	$Area2D/CollisionShape2D.position.y = Vector2(0,0).distance_to(target_pos)/2;
	
func _physics_process(delta):
	update();
func _process(delta):
	pass;
	
	

func _draw():
	
	var red = 1 if team_id == 1 else 0;
	var green = 10.0/255.0 if team_id == 1 else 130.0/255.0;
	var blue = 1 if team_id == 0 else 0;
	var lightener = 0.2;
	red = red + lightener;
	green = green + lightener;
	blue = blue + lightener;
	var progress = (1 - ($Death_Timer.time_left / $Death_Timer.wait_time))
	draw_line(Vector2.ZERO,target_pos, Color(red, green, blue, 1 - progress), size-2);
	draw_line(Vector2.ZERO, target_pos, Color(red + 0.3, green + 0.3, blue + 0.3, 1 - progress), size/1.5);
	draw_line(Vector2.ZERO, target_pos, Color(red + 0.7, green + 0.7, blue + 0.7, 1 - progress), size/2.5);
	draw_circle(Vector2.ZERO, size/2, Color(1,1,1));
	draw_circle(Vector2.ZERO, size/2 + 10, Color(red + 0.3, green + 0.3, blue + 0.3, (sin(progress * 2 * PI * 25)+1)/2.0));
	draw_circle(target_pos, size/2, Color(1,1,1));
	draw_circle(target_pos, size/2 + 5, Color(red + 0.3, green + 0.3, blue + 0.3, (sin(progress * 2 * PI * 25)+1)/2.0));

# Called when the death timer ends;
func _death_timer_ended():
	get_parent().remove_child(self);
	call_deferred("queue_free");
