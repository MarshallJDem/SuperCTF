extends Button

var radius_big = 125;
var radius_small = 50;
var origin = Vector2(0,0);
var margin = Vector2(275,200);
export var is_move = true;
# This is the input vector of the stick
# Its max magnitude is radius_big
var stick_vector = Vector2(0,0);
var button_radius = 0;
var local_player;

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _input(event):
	if Globals.testing:
		local_player = get_tree().get_root().get_node("MainScene/Test_Player");
	elif Globals.localPlayerID != null and get_tree().get_root().get_node("MainScene/Players").has_node("P" + str(Globals.localPlayerID)):
		local_player = get_tree().get_root().get_node("MainScene/Players/P" + str(Globals.localPlayerID));
	if event is InputEventScreenTouch:
		if !is_move:
			if local_player.get_node("Utility_Node").aiming_grenade and event.is_pressed():
				modulate = Color(1,1,1,1);
				var translate = local_player.get_node("Utility_Node").get_global_mouse_position() - get_global_mouse_position();
				local_player.get_node("Utility_Node").utility_released(event.position + translate);
			if event.is_pressed() and (event.position - rect_position).distance_to($Dash.rect_position + $Dash.rect_size/2) < button_radius:
				if local_player != null:
					local_player.teleport_pressed();
				return;
			if event.is_pressed() and (event.position - rect_position).distance_to($Ult.rect_position + $Ult.rect_size/2) < button_radius:
				if local_player != null:
					local_player.get_node("Ability_Node").ult_pressed();
				return;
			if event.is_pressed() and (event.position - rect_position).distance_to($Ability.rect_position + $Ability.rect_size/2) < button_radius:
				if local_player != null:
					local_player.get_node("Ability_Node").ability_pressed();
				return;
			if event.is_pressed() and (event.position - rect_position).distance_to($Utility.rect_position + $Utility.rect_size/2) < button_radius:
				if local_player != null:
					if Globals.current_utility == Globals.Utilities.Grenade:
						modulate = Color(0,0,0,0);
						local_player.get_node("Utility_Node").utility_pressed();
				return;
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
	if Globals.control_scheme != Globals.Control_Schemes.touchscreen:
		return;
	radius_big = OS.get_window_size().y/10
	radius_small = radius_big / 3;
	if is_move:
		origin = Vector2((radius_big + margin.x), rect_size.y - ((radius_big * 1.5) + margin.y));
	else:
		origin = Vector2(rect_size.x - (radius_big + margin.x), rect_size.y - ((radius_big * 1.5) + margin.y));
		
		var dist = 1;
		dist = radius_big * 2.5;
		# Buttons
		button_radius = ($Dash.rect_size.x/2) * 2
		$Dash.rect_position = (origin + (Vector2(-180, 150).normalized() * dist)) - $Dash.rect_size/2;
		$Ult.rect_position = (origin + (Vector2(-163, -10).normalized() * dist)) - $Ult.rect_size/2;
		$Utility.rect_position = (origin + (Vector2(-183, -195).normalized() * dist)) - $Utility.rect_size/2;
		$Ability.rect_position = (origin + (Vector2(0, -1).normalized() * dist)) - $Ability.rect_size/2;
		
		if Globals.current_utility == Globals.Utilities.Grenade:
			$Utility.text = "GRENADE";
		elif Globals.current_utility == Globals.Utilities.Landmine:
			$Utility.text = "LANDMINE"
		if Globals.current_ability == Globals.Abilities.Forcefield:
			$Ability.text = "FORCEFIELD";
		elif Globals.current_ability == Globals.Abilities.Camo:
			$Ability.text = "CAMO"
		
		if local_player != null:
			# Ability button
			var progress = ((local_player.get_node("Ability_Node/Cooldown_Timer").wait_time - local_player.get_node("Ability_Node/Cooldown_Timer").time_left) / local_player.get_node("Ability_Node/Cooldown_Timer").wait_time);
			$Ability.modulate = Color(1,1,1,0.1 + 0.4 * progress);
			ability_color = Color(0.0,0.0,0.0,0.6);
			if progress == 1.0:
				$Ability.modulate = Color(1,1,1,1);
				ability_color = Color(0.5,0.5,0.5,0.4);
			# Utility button
			progress = ((local_player.get_node("Utility_Node/Cooldown_Timer").wait_time - local_player.get_node("Utility_Node/Cooldown_Timer").time_left) / local_player.get_node("Utility_Node/Cooldown_Timer").wait_time);
			$Utility.modulate = Color(1,1,1,0.1 + 0.4 * progress);
			utility_color = Color(0.0,0.0,0.0,0.6);
			if progress == 1.0:
				$Utility.modulate = Color(1,1,1,1);
				utility_color = Color(0.5,0.5,0.5,0.4);
			# Dash button
			progress = ((local_player.get_node("Teleport_Timer").wait_time - local_player.get_node("Teleport_Timer").time_left) / local_player.get_node("Teleport_Timer").wait_time);
			$Dash.modulate = Color(1,1,1,0.1 + 0.4 * progress);
			dash_color = Color(0.0,0.0,0.0,0.6);
			if progress == 1.0:
				$Dash.modulate = Color(1,1,1,1);
				dash_color = Color(0.5,0.5,0.5,0.4);
			# Ult button
			progress = float(local_player.get_node("Ability_Node").ult_charge)/100.0;
			$Ult.modulate = Color(1,1,1,0.1 + 0.1 * progress);
			ult_color = Color(0.0,0.0,0.0,0.1);
			if progress == 1.0:
				$Ult.modulate = Color(1,1,1,1);
				ult_color = Color(0.5,0.5,0.5,0.4);
	update();
	
	
var ability_color = Color(0.5,0.5,0.5,0.4);
var utility_color = Color(0.5,0.5,0.5,0.4);
var dash_color = Color(0.5,0.5,0.5,0.4);
var ult_color = Color(0.5,0.5,0.5,0.4);
func _draw():
	draw_circle(origin,radius_big,Color(0.5,0.5,0.5,0.4));
	draw_circle(origin + stick_vector,radius_small,Color(0.5,0.5,0.5,0.4));
	if !is_move:
		draw_circle($Dash.rect_position + $Dash.rect_size/2,button_radius,dash_color);
		draw_circle($Ult.rect_position + $Ult.rect_size/2,button_radius,ult_color);
		draw_circle($Utility.rect_position + $Utility.rect_size/2,button_radius,utility_color);
		draw_circle($Ability.rect_position + $Ability.rect_size/2,button_radius,ability_color);
