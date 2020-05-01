extends Node2D

var table = ['"Dads in Space" - Stephen Walking','"Crystal Dolphin" - Engelwood', 
'"Back Again" - Archie', '"Oh Mama" - Run The Jewels', '"Good Time" - Nightcore Remix','"Superman" - Goldfinger',
'"Bubbletea" - Dark Cat', '"When Can I See You Again" - Nightcore Remix'];
var db_table = [1,6,7,9,10,4,5,10];
var current_song = -1;
var song_ids = [0,1,2,3,4,5,6,7];


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$CanvasLayer/Options_Button.connect("button_up", self, "_button_clicked");
	$CanvasLayer/Music_Background/Skip_Text.connect("meta_clicked", self, "_skip_pressed");
	$Music_Player.connect("finished", self, "play_next_song");

var rotation_delay = 0.5;
var time_elapsed = 0;
func _process(delta: float) -> void:
	if $CanvasLayer/Music_Background/Title_Rotate_Buffer.time_left == 0:
		time_elapsed += delta;
		if time_elapsed > rotation_delay:
			time_elapsed = 0;
			rotate_music_title();

func saved_song_loaded(song_id):
	if current_song == -1:
		current_song = song_id;
		play_next_song();
		

func _skip_pressed(meta):
	play_next_song();

func play_next_song():
	return;
	current_song = (current_song + 1) % table.size();
	Globals.write_save_data();
	$CanvasLayer/Music_Background/Music_Title.text = table[song_ids[current_song]] + "  |  ";
	$CanvasLayer/Music_Background/Title_Rotate_Buffer.start();
	$CanvasLayer/Music_Background/Music_Image.texture = load("res://Assets/Music/" + str(song_ids[current_song]) + ".jpg");
	$Music_Player.stream = load("res://Assets/Music/" + str(song_ids[current_song]) + ".ogg");
	$Music_Player.volume_db = db_table[current_song];
	$Music_Player.play();

func rotate_music_title():
	var text = $CanvasLayer/Music_Background/Music_Title.text;
	var first = text.substr(0,1);
	text = text.substr(1, len(text) - 1);
	$CanvasLayer/Music_Background/Music_Title.text = text + first;

func _button_clicked():
	Globals.toggle_options_menu();
	$CanvasLayer/Options_Button.release_focus();

