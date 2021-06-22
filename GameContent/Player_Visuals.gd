extends Control

var look_direction = 0;
var current_class = Globals.Classes.Bullet;
var current_class_name = "gunner";
var equipped_head = 1;
var equipped_body = 2;
var gun_skin = 0;
var team_id = 0;

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
	$Sprite_Arms.position = $Sprite_Gun.position

func _update_look_direction(dir):
	look_direction = dir;
	$Sprite_Head.frame = dir;
	$Sprite_Gun.frame = dir;
	$Sprite_Arms.frame = dir;
	$Sprite_Body.frame = dir;
	$Sprite_Legs.frame = dir + (int((1-($Leg_Animation_Timer.time_left / $Leg_Animation_Timer.wait_time)) * 4)%4) * $Sprite_Legs.hframes;
	if dir == 2 or dir == 3:
		$Sprite_Head.z_index =1;
		$Sprite_Body.z_index =0;
		$Sprite_Gun.z_index =2;
		$Sprite_Arms.z_index =3;
	else:
		$Sprite_Head.z_index =2;
		$Sprite_Body.z_index =0;
		$Sprite_Gun.z_index =1;
		$Sprite_Arms.z_index =1.5;

func _update_class(c):
	var n = "gunner"
	if c == Globals.Classes.Bullet:
		n = "gunner";
	elif c == Globals.Classes.Laser:
		n = "laser";
	elif c == Globals.Classes.Demo:
		n = "demo";
	
	current_class_name = n;
	current_class = c;
	
	refresh_textures();

func _update_team_id(t):
	team_id = t;
	refresh_textures();

func _start_shoot_animation():
	$Shoot_Animation_Timer.start()

func refresh_textures():
	var t = "B";
	if team_id == 1:
		t = "R";
	
	#store skin in body variable
	var body = "res://Assets/Player/Skins/" + str(equipped_body) + "_body_" + str(t) + ".png";
	#check if the skin exists
	if ResourceLoader.exists(body):
		#if it does, set the body texture to the new skin
		$Sprite_Body.set_texture(load(body));
	else:
		print("Error in Player_Visuals.gd No skin found at "+ body)
	
	#store skin in arms variable
	var arms = "res://Assets/Player/Skins/" + str(equipped_body) + "_arms_" + str(t) + ".png";
	#check if the skin exists
	if ResourceLoader.exists(arms):
		#if it does, set the arms texture to the new skin
		$Sprite_Arms.set_texture(load(arms));
	else:
		print("Error in Player_Visuals.gd No skin found at "+ arms)
	
	var head = "res://Assets/Player/Skins/" + str(equipped_head) + "_head_" + str(t) + ".png";
	if ResourceLoader.exists(head):
		$Sprite_Head.set_texture(load(head));
	else:
		print("Error in Player_Visuals.gd No skin found at "+ head)
	var gun = "res://Assets/Player/Weapons" + str(current_class_name) + "_gun_" + str(t) + ".png";
	if ResourceLoader.exists(gun):
		$Sprite_Gun.set_texture(load(gun));


func _update_equipped_cosmetics(equipped_cosmetics):
	var new_head: int = 0 if !equipped_cosmetics.has("equippedHead") else equipped_cosmetics.equippedHead
	var new_body: int = 1 if !equipped_cosmetics.has("equippedBody") else equipped_cosmetics.equippedBody
	# Only refresh if data changed
	if equipped_head != new_head or equipped_body != new_body:
		equipped_head = new_head
		equipped_body = new_body
		refresh_textures();
