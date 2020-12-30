extends Control

var look_direction;

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func _update_animation(position_delta):
	# Feet running
	if sqrt(pow(position_delta.x, 2) + pow(position_delta.y, 2)) < 0.1:
		# Idle
		$Sprite_Legs.frame = look_direction;
	else:
		# Moving
		$Sprite_Legs.frame = look_direction + (int((1-($Leg_Animation_Timer.time_left / $Leg_Animation_Timer.wait_time)) * 4)%4) * $Sprite_Legs.hframes;
		
	# Head Bob
	$Sprite_Head.position.y = int(2 * sin((1 - $Top_Animation_Timer.time_left/$Top_Animation_Timer.wait_time)*(2 * PI)))/2.0;

func _physics_process(delta: float) -> void:
	# Gun Animation
	$Sprite_Gun.position.y = int(2 * sin((PI * 0.25) + (1 - $Top_Animation_Timer.time_left/$Top_Animation_Timer.wait_time)*(2 * PI)))/2.0;
	$Sprite_Gun.position.x = 0;
	# Shooting Animation (Overrides idleness)
	if $Shoot_Animation_Timer.time_left > 0:
		if look_direction == 0:
			$Sprite_Gun.position.y = 20 * $Shoot_Animation_Timer.time_left;
		elif look_direction == 1:
			$Sprite_Gun.position.y = +20 * $Shoot_Animation_Timer.time_left;
			$Sprite_Gun.position.x = -20 * $Shoot_Animation_Timer.time_left;
		elif look_direction == 2 or look_direction == 3:
			$Sprite_Gun.position.y = -20 * $Shoot_Animation_Timer.time_left;
			$Sprite_Gun.position.x = -20 * $Shoot_Animation_Timer.time_left;
		elif look_direction == 4:
			$Sprite_Gun.position.y = -20 * $Shoot_Animation_Timer.time_left;
		elif look_direction == 5 or look_direction == 6:
			$Sprite_Gun.position.y = -20 * $Shoot_Animation_Timer.time_left;
			$Sprite_Gun.position.x = 20 * $Shoot_Animation_Timer.time_left;
		elif look_direction == 7:
			$Sprite_Gun.position.y = +20 * $Shoot_Animation_Timer.time_left;
			$Sprite_Gun.position.x = 20 * $Shoot_Animation_Timer.time_left;

func _update_look_direction(dir):
	look_direction = dir;
	$Sprite_Head.frame = dir;
	$Sprite_Gun.frame = dir;
	$Sprite_Body.frame = dir;
	$Sprite_Legs.frame = dir + (int((1-($Leg_Animation_Timer.time_left / $Leg_Animation_Timer.wait_time)) * 4)%4) * $Sprite_Legs.hframes;
	if dir == 2 or dir == 3:
		$Sprite_Head.z_index =1;
		$Sprite_Body.z_index =0;
		$Sprite_Gun.z_index =2;
	else:
		$Sprite_Head.z_index =2;
		$Sprite_Body.z_index =0;
		$Sprite_Gun.z_index =1;

func _update_class(c, team_id):
	var n = "gunner"
	if c == Globals.Classes.Bullet:
		n = "gunner";
	elif c == Globals.Classes.Laser:
		n = "laser";
	elif c == Globals.Classes.Demo:
		n = "demo";
	
	var t = "B";
	if team_id == 1:
		t = "R";
	
	$Sprite_Head.set_texture(load("res://Assets/Player/" + str(n) + "_head_" +t+ ".png"));
	$Sprite_Body.set_texture(load("res://Assets/Player/" + str(n) + "_body_" +t+ ".png"));
	$Sprite_Gun.set_texture(load("res://Assets/Player/" + str(n) + "_gun_" +t+ ".png"));

func _start_shoot_animation():
	$Shoot_Animation_Timer.start()
