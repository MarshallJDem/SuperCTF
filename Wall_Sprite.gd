extends Sprite

export var override_z : bool = true;

# Called when the node enters the scene tree for the first time.
func _ready():
	
	self.position.x = (round(self.position.x));
	self.position.y = (round(self.position.y));

func _process(delta):
	if override_z:
		z_index = position.y + 5;
