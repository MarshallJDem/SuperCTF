extends Button

var radius_big = 125;
var radius_small = 50;
var origin = Vector2(0,0);
var margin = Vector2(75,150);
# This is the input vector of the stick
# Its max magnitude is radius_big
var stick_vector = Vector2(0,0);

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _process(_delta):
	origin = Vector2((radius_big + margin.x), rect_size.y - margin.y);
	update();
	
func _draw():
	draw_circle(origin,radius_big,Color(0.5,0.5,0.5,0.4));
	if pressed:
		var vector = get_local_mouse_position() - origin;
		var magnitude = sqrt(pow(vector.x,2) + pow(vector.y,2));
		vector = vector.normalized();
		stick_vector = vector * (min(magnitude, radius_big));
	else:
		stick_vector = Vector2(0,0);
	draw_circle(origin + stick_vector,radius_small,Color(0.5,0.5,0.5,0.4));
