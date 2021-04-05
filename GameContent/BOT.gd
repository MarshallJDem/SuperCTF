extends Node2D


onready var player = $".."

var enemy_target = null

var path = null

# STATE MACHINE IN ORDER OF PRIORITY
# Recovering = our team's flag is not home. Top priority is to return it
# Capturing = we are holding the enemy flag and taking it home
# Defending = enemy is within danger zone of our flag (defend the flag)
# Attacking = no enemies are within danger zone of our flag (go try to take enemy flag)
enum {RECOVERING, CAPTURING, DEFENDING, ATTACKING} 
var state = DEFENDING

# Called when the node enters the scene tree for the first time.
func _ready():
	if !player.is_bot:
		return
	
	if Globals.testing:
		enemy_target = get_tree().get_root().get_node("MainScene/Test_Player")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if !player.is_bot:
		last_endpoint = null
		return;
	if !player.control:
		last_endpoint = null
		return;
	
	# Update state machine
	update_state_machine()
	
	var enemy_team_id = 0 if player.team_id == 1 else 1
	
	# Navigation
	if state == RECOVERING:
		# Update Nav to our team's flag
		var flagHome = get_tree().get_root().get_node("MainScene/Map/YSort/Flag_Home-" + str(player.team_id));
		var flag_id = flagHome.flag_id
		for flag in get_tree().get_nodes_in_group("Flags"):
			if flag.flag_id == flag_id:
				update_nav(flag.get_global_position())
				break
	elif state == CAPTURING:
		# Update Nav to our team's flaghome
		var flagHome = get_tree().get_root().get_node("MainScene/Map/YSort/Flag_Home-" + str(player.team_id));
		update_nav(flagHome.position)
	elif state == DEFENDING:
		# Update Nav to enemy targey player
		update_nav(enemy_target.position)
	elif state == ATTACKING:
		# Update Nav to enemy flag
		var enemy_flagHome = get_tree().get_root().get_node("MainScene/Map/YSort/Flag_Home-" + str(enemy_team_id));
		var flag_id = enemy_flagHome.flag_id
		for flag in get_tree().get_nodes_in_group("Flags"):
			if flag.flag_id == flag_id:
				update_nav(flag.get_global_position())
				break
	
	
	# Look direction
	var target_pos = Vector2(0,1)
	if is_instance_valid(enemy_target):
		target_pos = enemy_target.position 
	elif path != null and path.size()> 1:
		target_pos = path[1]
	var dir = player.position.direction_to(target_pos)
	player.update_look_direction(target_pos)
	
	# Shooting
	# If enemy is within reasonable range
	if enemy_target != null and enemy_target.position.distance_to(player.position) < 1000:
		if state == RECOVERING:
			# Shoot
			attack_in_direction(dir, rand_range(0,PI/8) - PI/16)
		elif state == CAPTURING:
			pass
		elif state == DEFENDING:
			# Shoot
			attack_in_direction(dir, rand_range(0,PI/8) - PI/16)
		elif state == ATTACKING:
			# Shoot
			attack_in_direction(dir, rand_range(0,PI/8) - PI/16)
		
	
	# Movement
	move(delta)
	
	
func _input(event):
	if !player.is_bot:
		return;
	if event is InputEventMouseButton:
		pass

var last_endpoint = null

func update_nav(pos):
	var nav = get_tree().get_root().get_node("MainScene/Map/BOT_Navigation")
	if !is_instance_valid(nav):
		print("ERROR: NAV INSTANCE WAS NOT VALID")
		return
	# Dont do fancy randomizing if our target might be changing constantly
	if state == RECOVERING or state == DEFENDING:
		path = nav.get_simple_path(player.position, pos)
		last_endpoint = null
	# Check if were still on the same path. If not, reroute
	elif last_endpoint != pos:
		path = nav.get_simple_path(player.position, pos)
		last_endpoint = pos
		# Randomize path
		for iterator in range(path.size()-2):
			var i = iterator + 1
			var attempts = 0
			while attempts < 10:
				var new_pos = nav.get_closest_point(path[i] + Vector2(rand_range(0,100)-50, rand_range(0,100)-50))
				# If this new position doesn't add complexity, use it as the new target
				var test_path1 = nav.get_simple_path(path[i-1], new_pos)
				var test_path2 = nav.get_simple_path(new_pos, path[i+1])
				if test_path1.size() <= 2 and test_path2.size() <= 2:
					path[i] = new_pos
					break
				attempts += 1
	
	nav.get_node("Line2D").points = path

func attack_in_direction(dir, random_angle = 0):
	dir = Vector2((dir.x * cos(random_angle)) - (sin(random_angle)*dir.y),(dir.x * sin(random_angle)) + (cos(random_angle) * dir.y)) 
	player.get_node("Weapon_Node").shoot_on_inputs(dir)
	
func update_state_machine():
	# Pick an enemy target
	var closest_enemy = null
	for p in get_tree().get_nodes_in_group("Players"):
		if p.alive and p.team_id != player.team_id:
			if closest_enemy == null:
				closest_enemy = p
			elif p.position.distance_to(player.position) < closest_enemy.position.distance_to(player.position):
				closest_enemy = p
	enemy_target = closest_enemy
	
	# Check if our flag is home
	var flagHome = get_tree().get_root().get_node("MainScene/Map/YSort/Flag_Home-" + str(player.team_id));
	var flag_id = flagHome.flag_id
	for flag in get_tree().get_nodes_in_group("Flags"):
		if flag.flag_id == flag_id:
			if !flag.is_at_home:
				state = RECOVERING
				return
			
	# Check if we are holding a flag and taking it home
	if player.has_flag():
		state = CAPTURING
		return
	
	# Check if enemy is on our side of map and we should defend
	if is_instance_valid(enemy_target):
		if (player.team_id == 1 and enemy_target.position.x >= 0) or (player.team_id == 0 and enemy_target.position.x <= 0):
			state = DEFENDING
			return
	
	state = ATTACKING
	return

func move(delta):
	if path == null:
		return;
	
		
	# Calculate the movement distance for this frame
	var distance_to_walk = player.BASE_SPEED*3/4 * delta
	
	# Move the player along the path until he has run out of movement or the path ends.
	while distance_to_walk > 0 and path.size() > 0:
		var distance_to_next_point = player.position.distance_to(path[0])
		if distance_to_walk <= distance_to_next_point:
			# The player does not have enough movement left to get to the next point.
			player.position += player.position.direction_to(path[0]) * distance_to_walk
		else:
			# The player get to the next point
			player.position = path[0]
			path.remove(0)
		# Update the distance to walk
		distance_to_walk -= distance_to_next_point

	path.insert(0, player.position)
