extends Button

var radius_big = 125;
var radius_small = 50;
var origin = Vector2(0,0);
var margin = Vector2(75,150);
export var is_move = true;
# This is the input vector of the stick
# Its max magnitude is radius_big
var stick_vector = Vector2(0,0);


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _input(event):
	if event is InputEventScreenTouch:
		if (is_move and event.position.x < OS.get_window_size().x/2) or (!is_move and not event.position.x < OS.get_window_size().x/2):
			if event.is_pressed():
				var vector = (event.position - rect_position) - origin;
				var magnitude = sqrt(pow(vector.x,2) + pow(vector.y,2));
				vector = vector.normalized();
				stick_vector = vector * (min(magnitude, radius_big));
			else:
				stick_vector = Vector2(0,0);
	elif event is InputEventScreenDrag:
		if (is_move and event.position.x < OS.get_window_size().x/2) or (!is_move and not event.position.x < OS.get_window_size().x/2):
			var vector = (event.position - rect_position) - origin;
			var magnitude = sqrt(pow(vector.x,2) + pow(vector.y,2));
			vector = vector.normalized();
			stick_vector = vector * (min(magnitude, radius_big));
func _process(_delta):
	
	radius_big = OS.get_window_size().y/6
	radius_small = radius_big / 3;
	if is_move:
		origin = Vector2((radius_big + margin.x), rect_size.y - (radius_big * 1.5));
	else:
		origin = Vector2(rect_size.x - (radius_big + margin.x), rect_size.y - (radius_big * 1.5));
		
	update();
	
func _draw():
	draw_circle(origin,radius_big,Color(0.5,0.5,0.5,0.4));
	draw_circle(origin + stick_vector,radius_small,Color(0.5,0.5,0.5,0.4));
