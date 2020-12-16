extends KinematicBody2D

var control = false;
# The ID of this player 0,1,2 etc. NOT the network unique ID
var player_id = -1;
var team_id = -1;
var BASE_SPEED = 200;
const SPRINT_SPEED = 50;
const FLAG_SLOWDOWN_SPEED = -25;
var TELEPORT_SPEED = 3000;
var POWERUP_SPEED = 0;
var DASH_COOLDOWN_PMODIFIER = 0;
var player_name = "Guest999";
# Where this player starts on the map and should respawn at
var start_pos = Vector2(0,0);
# Whether or not this player is alive
var alive = true;
# Whether or not this player is currently invincible
var invincible = false;
# The camera that is associated with this player. A reference is used because it may switch parents
var camera_ref = null;
# The time in millis the last position was received
var time_of_last_received_pos = 0;
# The position to start lerping from
var lerp_start_pos = Vector2(0,0);
# The position to end lerping at
var lerp_end_pos = Vector2(0,0);
# Whether or not the player is sprinting
var sprintEnabled = false;
# The position the player was in last frame
var last_position = Vector2(0,0);
# The frame of the all of the sprite on the top (Gun, Head, Body)
var look_direction = 0;
var has_moved_after_respawn = false;
var current_class;

# Only accurately being tracked by server
var stats = {"kills" : 0, "deaths": 0, "captures" : 0, "recovers" : 0};

var Ghost_Trail = preload("res://GameContent/Ghost_Trail.tscn");
var Player_Death = preload("res://GameContent/Player_Death.tscn");


func _ready():
	camera_ref = $Center_Pivot/Camera;
	
	last_position = position;
	
	if Globals.testing:
		activate_camera();
		control = true
	
	Globals.connect("class_changed", self, "loadout_class_updated");
	if Globals.localPlayerID == player_id:
		loadout_class_updated();
	else:
		update_class(current_class);
	$Respawn_Timer.connect("timeout", self, "_respawn_timer_ended");
	$Invincibility_Timer.connect("timeout", self, "_invincibility_timer_ended");
	$Powerup_Timer.connect("timeout", self, "_powerup_timer_ended");
	$Teleport_Invincibility_Timer.connect("timeout", self, "_teleport_invincibility_timer_ended");
	lerp_start_pos = position;
	lerp_end_pos = position;
	

func _input(event):
	if Globals.is_typing_in_chat:
		return;
	if control:
		if event is InputEventKey and event.pressed:
			if event.scancode == KEY_T:
				get_tree().get_root().get_node("MainScene/NetworkController").rpc("test_ping");
			if event.scancode == KEY_CONTROL:
				if !has_flag():
					pass;
					#printEnabled = !sprintEnabled;
			if event.scancode == KEY_SPACE:
				#Attempt a teleport
				# Re-enable line below to prevent telporting while you have flag
				teleport_pressed();
func teleport_pressed():
	if $Teleport_Timer.time_left == 0 and $Weapon_Node/Laser_Timer.time_left == 0:
		move_on_inputs(true);
		camera_ref.lag_smooth();
		$Teleport_Timer.start();
func is_in_own_spawn() -> bool:
	if team_id == 1:
		return $Area2D.is_in_red_spawn;
	else:
		return $Area2D.is_in_blue_spawn;

func _process(delta):
	BASE_SPEED = get_tree().get_root().get_node("MainScene/NetworkController").get_game_var("playerSpeed");
	
	TELEPORT_SPEED = get_tree().get_root().get_node("MainScene/NetworkController").get_game_var("dashDistance");
	$Teleport_Timer.wait_time = DASH_COOLDOWN_PMODIFIER + float(get_tree().get_root().get_node("MainScene/NetworkController").get_game_var("dashCooldown"))/1000.0;
	if !get_tree().get_root().get_node("MainScene/NetworkController").round_is_running:
		has_moved_after_respawn = false;
	if !Globals.testing and is_network_master():
		Globals.player_active_after_respawn = has_moved_after_respawn and control;
		Globals.displaying_loadout = is_in_own_spawn();
	elif Globals.testing:
		Globals.displaying_loadout = true;
		Globals.player_active_after_respawn = true;
	if control:
		activate_camera();
		# Don't look around if we're shooting a laser
		if Globals.current_class != Globals.Classes.Laser or $Weapon_Node/Laser_Timer.time_left == 0:
			update_look_direction();
		# Move around as long as we aren't typing in chat
		if !Globals.is_typing_in_chat:
			move_on_inputs();
	if is_instance_valid(camera_ref):
		camera_ref.get_node("Canvas_Layer/Vignette_Blue").visible = false;
		camera_ref.get_node("Canvas_Layer/Vignette_Red").visible = false;
	if control and has_flag():
		if team_id == 1:
			camera_ref.get_node("Canvas_Layer/Vignette_Red").visible = true;
		else:
			camera_ref.get_node("Canvas_Layer/Vignette_Blue").visible = true;
	
	update();
	
	
	#check if the player is the one we ar e controlling
	if player_id == Globals.localPlayerID:
		#get the players flag home
		var flagHome = get_tree().get_root().get_node("MainScene/Map/YSort/Flag_Home-" + str(team_id));
		#turn the helper arrow on if they have the flag and off if they dont
		flagHome.toggle_score_helper(has_flag())

	
	
	
	
	if $Invincibility_Timer.time_left > 0:
		var t = $Invincibility_Timer.time_left / $Invincibility_Timer.wait_time 
		var x =  (t * 10);
		var color = Color(1,1,1,(sin( (PI / 2) + (x * (1 + (t * ((2 * PI) - 1))))) + 1)/2);
		modulate = color;
	
	z_index = global_position.y + 5;
	
	# If we are a puppet and not the server, then lerp our position
	if !Globals.testing and !is_network_master() and !get_tree().is_network_server():
		position = lerp(lerp_start_pos, lerp_end_pos, clamp(float(OS.get_ticks_msec() - time_of_last_received_pos)/float(Globals.player_lerp_time), 0.0, 1.0));
	
	if !Globals.testing and is_network_master() and !get_tree().is_network_server():
		rpc_unreliable("update_position", position);
	
	# Animation
	var diff = last_position - position;
	if sqrt(pow(diff.x, 2) + pow(diff.y, 2)) < 0.1:
		# Idle
		if team_id == 1:
			#$Sprite_Top.set_texture(idle_top_atlas_red);
			pass;
		else:
			#$Sprite_Top.set_texture(idle_top_atlas_blue);
			pass;
		$Sprite_Legs.frame = look_direction;
	else:
		# Moving
		if team_id == 1:
			#$Sprite_Top.set_texture(running_top_atlas_red);
			pass;
		else:
			#$Sprite_Top.set_texture(running_top_atlas_blue);
			pass;
		$Sprite_Legs.frame = look_direction + (int((1-($Leg_Animation_Timer.time_left / $Leg_Animation_Timer.wait_time)) * 4)%4) * $Sprite_Legs.hframes;
	
	
	$Sprite_Head.position.y = int(2 * sin((1 - $Top_Animation_Timer.time_left/$Top_Animation_Timer.wait_time)*(2 * PI)))/2.0;
		
	# Name tag
	var color = "blue";
	if team_id == 1:
		color = "red";
	$Name_Parent/Label_Name.bbcode_text = "[center][color=" + color + "]" + player_name;
	last_position = position;



func update_class(c):
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

func loadout_class_updated():
	update_class(Globals.current_class);

func _draw():
	pass;

func has_flag() -> bool:
	return $Flag_Holder.get_child_count() != 0;

# Attempts to drop the flag the player is potentially holding. Returns true if there was a flag to drop false otherwise
func attempt_drop_flag(given_pos = null, ignore_drop_buffer = true) -> bool:
	if !has_flag():
		return false;
	else: # Otherwise drop our flag
		var pos = given_pos;
		if given_pos == null:
			pos = $Flag_Holder.get_global_position();
		
		drop_current_flag(pos, ignore_drop_buffer);
		rpc_id(1, "send_drop_flag", pos, ignore_drop_buffer);
		return true;

# A vector 2D representing the last movement key directions pressed
var last_movement_input = Vector2(0,0);
func _teleport_invincibility_timer_ended():
	invincible = false;
remotesync func teleport(start, end):
	$Teleport_Audio.play();
	$Teleport_Invincibility_Timer.start();
	invincible = true;
	for i in range(6):
		var node = Ghost_Trail.instance();
		node.position = start;
		node.position.x = node.position.x + ((i) * (end.x - start.x)/4)
		node.position.y = node.position.y + ((i) * (end.y - start.y)/4)
		node.z_index = z_index;
		node.look_direction = look_direction;
		node.scale = $Sprite_Body.scale
		if has_flag():
			if team_id == 1:
				node.flag_team_id = 0;
			else:
				node.flag_team_id = 1;
		node.get_node("Sprite_Gun").texture = $Sprite_Gun.texture
		node.get_node("Sprite_Gun").z_index = $Sprite_Gun.z_index
		node.get_node("Sprite_Head").texture = $Sprite_Head.texture
		node.get_node("Sprite_Head").z_index = $Sprite_Head.z_index
		node.get_node("Sprite_Body").texture = $Sprite_Body.texture
		node.get_node("Sprite_Body").z_index = $Sprite_Body.z_index
		node.get_node("Sprite_Legs").texture = $Sprite_Legs.texture
		node.get_node("Sprite_Legs").frame = $Sprite_Legs.frame
		get_tree().get_root().get_node("MainScene").add_child(node);  
		node.get_node("Death_Timer").start((i) * 0.05 + 0.0001);
	# If this is a puppet, use this ghost trail as an oppurtunity to also update its position
	if !is_network_master():
		lerp_start_pos = end;
		lerp_end_pos = end;
		position = end;

# Checks the current pressed keys and calculates a new player position using the KinematicBody2D
func move_on_inputs(teleport = false):
	var input = Vector2(0,0);
	if Globals.control_scheme == Globals.Control_Schemes.touchscreen:
		input = get_tree().get_root().get_node("MainScene/UI_Layer/Move_Stick").stick_vector / get_tree().get_root().get_node("MainScene/UI_Layer/Move_Stick").radius_big;
	else:
		input.x = (1 if Input.is_key_pressed(KEY_D) else 0) - (1 if Input.is_key_pressed(KEY_A) else 0)
		input.y = (1 if Input.is_key_pressed(KEY_S) else 0) - (1 if Input.is_key_pressed(KEY_W) else 0)
		input = input.normalized();
	last_movement_input = input;
	if teleport or (input.x != 0 or input.y != 0):
		has_moved_after_respawn = true;
	
	var speed = BASE_SPEED + POWERUP_SPEED;
	if $Weapon_Node/Laser_Timer.time_left > 0:
		speed = POWERUP_SPEED + $Weapon_Node.AIMING_SPEED * ($Weapon_Node/Laser_Timer.time_left / $Weapon_Node/Laser_Timer.wait_time);
	
	if(has_flag()):
		speed += FLAG_SLOWDOWN_SPEED;
	if sprintEnabled:
		speed += SPRINT_SPEED;
	var areas = $Area2D.get_overlapping_areas();
	for i in range(areas.size()):
		if areas[i].is_in_group("Landmine_Bodies") and areas[i].monitorable:
			speed = speed / 2.0;
			break;
	if teleport:
		speed = TELEPORT_SPEED;
	var vec = (input * speed);
	
	var previous_pos = position;
	var change = move_and_slide(vec);
	var new_pos = position;
	
	if teleport:
		if Globals.testing:
			teleport(previous_pos, new_pos);
		else:
			rpc("teleport", previous_pos, new_pos);

remotesync func enable_powerup(type):
	var text = "";
	if type == 1:
		$Weapon_Node.reduced_cooldown_enabled = true;
		$Powerup_Timer.wait_time = 10;
		text = "[wave amp=50 freq=12][color=green]^^ FIRE RATE UP ^^";
	elif type == 2:
		POWERUP_SPEED = 50;
		$Powerup_Timer.wait_time = 10;
		text = "[wave amp=50 freq=12][color=blue]^^ SPEED UP ^^";
	elif type == 3:
		#$Ability_Node.reduced_cooldown_enabled = true;
		$Powerup_Timer.wait_time = 1;
		$Ability_Node.ability_stacks += 1;
		text = "[wave amp=50 freq=12][color=red]^^ +1 INSTANT ABILITY USE ^^";
	elif type == 4:
		DASH_COOLDOWN_PMODIFIER = -2.0;
		$Powerup_Timer.wait_time = 10;
		text = "[wave amp=50 freq=12][color=purple]˅˅˅˅˅˅^^ DASH RATE UP ^^";
	if Globals.testing or is_network_master():
		get_tree().get_root().get_node("MainScene/UI_Layer/Input_GUIs/PowerupParticles").start(type);
	
	# Only display message if this is our local player
	if Globals.testing or player_id == Globals.localPlayerID:
		$Powerup_Audio.play();
		get_tree().get_root().get_node("MainScene/UI_Layer").set_alert_text("[center]" + text);
	$PowerupParticles.start(type);
	$Powerup_Timer.start();

func _powerup_timer_ended():
	stop_powerups();

# This function is called by player and networkcontroller (potentially back to back)
func stop_powerups():
	POWERUP_SPEED = 0;
	DASH_COOLDOWN_PMODIFIER = 0;
	$Weapon_Node.reduced_cooldown_enabled = false;
	$Ability_Node.reduced_cooldown_enabled = false;
	if Globals.testing or is_network_master():
		get_tree().get_root().get_node("MainScene/UI_Layer/Input_GUIs/PowerupParticles").stop();
	$PowerupParticles.stop();

	
# Changes the sprite's frame to make it "look" at the mouse
var previous_dist = Vector2(0,0);
func update_look_direction():
	var pos = get_global_mouse_position();
	var dist = pos - position;
	if Globals.control_scheme == Globals.Control_Schemes.touchscreen:
		dist = get_tree().get_root().get_node("MainScene/UI_Layer/Shoot_Stick").stick_vector;
		if dist == Vector2.ZERO:
			dist = get_tree().get_root().get_node("MainScene/UI_Layer/Move_Stick").stick_vector;
			if dist == Vector2.ZERO:
				dist = previous_dist;
	previous_dist = dist;
	var angle = get_vector_angle(dist);
	var adjustedAngle = -1 * (angle + (PI/8));
	var octant = (adjustedAngle / (2 * PI)) * 8
	var dir = int((octant + 9) + 4) % 8;
	if dir != look_direction: # If it changed since last time
		set_look_direction(dir);
		if !Globals.testing:
			rpc_unreliable_id(1, "send_look_direction", dir, player_id);


# Gets the angle that a vector is making
func get_vector_angle(dist):
	var angle = (-(PI / 2) if dist.y < 0 else ( 3 * PI / 2)) if dist.x == 0 else atan(dist.y / dist.x);
	angle = angle * -1;
	angle += PI/2;
	if dist.x < 0:
		angle += PI;
	return angle;

# Set the direction that the player is "looking" at by changing sprite frame
func set_look_direction(dir):
	look_direction = dir;
	$Sprite_Head.frame = dir;
	$Sprite_Gun.frame = dir;
	$Sprite_Body.frame = dir;
	$Sprite_Legs.frame = look_direction + (int((1-($Leg_Animation_Timer.time_left / $Leg_Animation_Timer.wait_time)) * 4)%4) * $Sprite_Legs.hframes;
	if dir == 2 or dir == 3:
		$Sprite_Head.z_index =1;
		$Sprite_Body.z_index =0;
		$Sprite_Gun.z_index =2;
	else:
		$Sprite_Head.z_index =2;
		$Sprite_Body.z_index =0;
		$Sprite_Gun.z_index =1;
	

# Updates this player's position with the new given position. Only ever called remotely
remotesync func update_position(new_pos):
	if is_network_master():
		return;
	# Instantly update position for server
	if get_tree().is_network_server():
		position = new_pos;
		return;
	# Otherwise lerp
	
	position = lerp(lerp_start_pos, lerp_end_pos, clamp(float(OS.get_ticks_msec() - time_of_last_received_pos)/float(Globals.player_lerp_time), 0.0, 1.0));
	time_of_last_received_pos = OS.get_ticks_msec();
	lerp_start_pos = position;
	lerp_end_pos = new_pos;

# Activates the camera on this player
func activate_camera():
	if camera_ref != null and is_instance_valid(camera_ref):
		camera_ref.current = true;

# De-activates the camera on this player
func deactivate_camera():
	if camera_ref != null and is_instance_valid(camera_ref):
		camera_ref.current = false;

# Called when this player is hit by a projectile
func hit_by_projectile(attacker_id, projectile_type):
	var attacker = get_tree().get_root().get_node("MainScene/Players/P" + str(attacker_id));
	if attacker != null:
		attacker.stats["kills"] += 1;
		attacker.get_node("Ability_Node").ult_charge += 10;
	else:
		print_stack();
	if projectile_type == 0 || projectile_type == 1 || projectile_type == 2 || projectile_type == 3: # Bullet or Laser or Landmine
		die();
		var attacker_team_id = get_tree().get_root().get_node("MainScene/NetworkController").players[attacker_id]["team_id"]
		var attacker_name = get_tree().get_root().get_node("MainScene/NetworkController").players[attacker_id]["name"]
		var color_1 = "red"
		var color_2 = "blue"
		if team_id == 1:
			color_1 = "blue";
			color_2 = "red";
		if attacker_id == Globals.localPlayerID:
			get_tree().get_root().get_node("MainScene/UI_Layer").set_alert_text("[center][color=black] KILLED [color=" + color_2 +"]" + player_name);
		get_tree().get_root().get_node("MainScene/UI_Layer").add_to_kill_feed("[right][color=" + color_1 + "]" + attacker_name + "[color=black] KILLED [color=" + color_2 +"]" + player_name);
		if is_network_master():
			get_tree().get_root().get_node("MainScene/UI_Layer").set_big_label_text("KILLED BY\n" + str(attacker_name), attacker_team_id);
			camera_ref.get_parent().remove_child(camera_ref);
			var pivot = get_tree().get_root().get_node("MainScene/Players/P" + str(attacker_id) + "/Center_Pivot");
			if pivot != null:
				pivot.add_child(camera_ref)
			else:
				print_stack();
			

# "Kills" the player. Only for visuals on client - the server handles the respawning.
func die():
	visible = false;
	control = false;
	alive = false;
	$Weapon_Node.ult_active = false;
	stats["deaths"] += 1;
	$Ability_Node.ability_stacks = 0;
	spawn_death_particles();
	stop_powerups();
	# If we're the server
	if get_tree().is_network_server():
		$Respawn_Timer.start();
	# Drop the flag if you have one
	drop_current_flag($Flag_Holder.get_global_position());
	position = start_pos;
	if is_network_master():
		$Death_Audio.play();
	else:
		$Killed_Audio.play();

func spawn_death_particles():
	var node = Player_Death.instance();
	node.position = position;
	node.xFrame = look_direction;
	node.z_index = z_index;
	get_tree().get_root().get_node("MainScene").add_child(node);

# Called by the respawn timer when it ends
func _respawn_timer_ended():
	rpc("receive_respawn");

# Respawns the player at their team's start location
func respawn():
	visible = true;
	alive = true;
	position = start_pos;
	has_moved_after_respawn = false;
	if is_network_master() and get_tree().get_root().get_node("MainScene/NetworkController").round_is_running:
		control = true;
	start_temporary_invincibility();
	if is_network_master():
		get_tree().get_root().get_node("MainScene/UI_Layer").clear_big_label_text();
		camera_ref.get_parent().remove_child(camera_ref);
		$Center_Pivot.add_child(camera_ref);
	else:
		lerp_start_pos = position;
		lerp_end_pos = position;
		time_of_last_received_pos = 0;

func get_stats():
	return stats;

# Takes the given flag
func take_flag(flag_id):
	if !alive:
		return;
	if Globals.testing or is_network_master():
		get_tree().get_root().get_node("MainScene").speedup_music();
	$Flag_Pickup_Audio.play();
	var flag_team_id;
	for flag in get_tree().get_nodes_in_group("Flags"):
		if flag.flag_id == flag_id:
			flag.re_parent($Flag_Holder);
			flag.is_at_home = false;
			flag.position = Vector2(0,0);
			flag_team_id = flag.team_id;
	sprintEnabled = false;
	var subject = player_name;
	var subjectColor = "blue"
	var color = "red";
	var teamNoun = "RED TEAM";
	if team_id == 1:
		subjectColor = "red";
		color = "blue";
		teamNoun = "BLUE TEAM";
	if player_id == Globals.localPlayerID:
		subject = "You";
	if !Globals.testing and !get_tree().is_network_server():
		if get_tree().get_root().get_node("MainScene/NetworkController").players[Globals.localPlayerID]["team_id"] == flag_team_id:
			teamNoun = "YOUR TEAM";
		get_tree().get_root().get_node("MainScene/UI_Layer").set_alert_text("[center][color=" + subjectColor + "]" + subject + "[color=black] took " + "[color=" + color + "]" + teamNoun + "'s[color=black] flag!");
	

# Drops the currently held flag (If there is one)
func drop_current_flag(flag_position = $Flag_Holder.get_global_position(), ignore_buffer_reset = true):
	# Only run if there is a flag in the Flag_Holder
	if has_flag():
		if Globals.testing or is_network_master():
			get_tree().get_root().get_node("MainScene").slowdown_music();
		$Flag_Drop_Audio.play();
		# Just get the first flag because there should only ever be one
		var flag = $Flag_Holder.get_children()[0];
		flag.get_node("Area2D").player_id_drop_buffer = player_id;
		flag.get_node("Area2D").ignore_next_buffer_reset = ignore_buffer_reset;
		flag.re_parent(get_tree().get_root().get_node("MainScene"));
		flag.position = flag_position;
		#$Weapon_Node/Cooldown_Timer.start();

# Starts the temporary Invincibility cooldown
func start_temporary_invincibility():
	$Invincibility_Timer.start();
	invincible = true;
# Called by timer when invincibility is over
func _invincibility_timer_ended():
	# If we're the server, make the call to actually end invinciblity
	if get_tree().is_network_server():
		rpc("receive_end_invinciblity");



# -------- NETWORKING ------------------------------------------------------------>


# Client tells the server what direction frame it's looking at 
remote func send_look_direction(frame, player_id):
	if get_tree().is_network_server(): # Only run if it's the server
		var clients = get_tree().get_network_connected_peers();
		for i in clients: # For each connected client
			if i != get_tree().get_rpc_sender_id(): # Don't do it for the player who sent it
				rpc_id(i, "receive_look_direction", frame);
		set_look_direction(frame); # Also call it locally for the server

# "Receives" the direction frame that this player is looking at from the server
remote func receive_look_direction(frame):
	set_look_direction(frame);

# "Receives" notification from the server that this player was hit by a projectile
remotesync func receive_hit(attacker_id, projectile_type):
	hit_by_projectile(attacker_id, projectile_type);

# Receives notification from the server that this player took the given flag
remotesync func receive_take_flag(flag_id):
	take_flag(flag_id);

# Client tells server that it is dropping the flag
remote func send_drop_flag(flag_position,ignore_drop_buffer):
	if get_tree().is_network_server():# Only run if it's the server
		var clients = get_tree().get_network_connected_peers();
		for i in clients: # For each connected client
			if i != get_tree().get_rpc_sender_id(): # Don't do it for the player who sent it
				rpc_id(i, "receive_drop_flag", flag_position, ignore_drop_buffer);
		drop_current_flag(flag_position, ignore_drop_buffer); # Also call it locally for the server

# Sent by server to tell clients that this player dropped its flag at the given position
remote func receive_drop_flag(flag_position, ignore_drop_buffer):
	drop_current_flag(flag_position, ignore_drop_buffer);

# Receives notification from the server to respawn this player
remotesync func receive_respawn():
	respawn();

# Received by server to end this player's invincibility
remotesync func receive_end_invinciblity():
	invincible = false;
	$Invincibility_Timer.stop();
	modulate = Color(1,1,1,1);
