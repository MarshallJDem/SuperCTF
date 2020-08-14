extends CPUParticles2D

var arrow_g = preload("res://Assets/GUI/arrow_G.png");
var arrow_r = preload("res://Assets/GUI/arrow_R.png");
var arrow_b = preload("res://Assets/GUI/arrow_B.png");
var arrow_p = preload("res://Assets/GUI/arrow_P.png");

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func start(type):
	if type == 1:
		self.texture = arrow_g
	if type == 2:
		self.texture = arrow_b
	if type == 3:
		self.texture = arrow_r
	if type == 4:
		self.texture = arrow_p
	emitting = true;
		
func stop():
	emitting = false;
