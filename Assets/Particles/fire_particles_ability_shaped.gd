extends CPUParticles2D

var fire_gradiant_red = preload("res://Assets/Particles/Color Gradients/Red Fire Gradiant.tres");
var fire_gradiant_blue = preload("res://Assets/Particles/Color Gradients/Blue Fire Gradiant.tres");
var fire_gradiant_purple = preload("res://Assets/Particles/Color Gradients/Purple Fire Gradiant.tres");



func _ready() -> void:
	pass

#change color gradiant of fire particles. Can input team id
func start(type):
	#team id of blue
	if type == 0:
		self.color_ramp = fire_gradiant_blue
	#team id of red
	elif type == 1:
		self.color_ramp = fire_gradiant_red
	elif type == 2:
		self.color_ramp = fire_gradiant_purple
		
	emitting = true;

#stop emitting fire
func stop():
	emitting = false;
