extends Control

func _ready():
	var start_btn = $VBoxContainer/StartButton
	var manage_btn = $VBoxContainer/ManageDbButton
	var exit_btn = $VBoxContainer/ExitButton

	if start_btn:
		start_btn.pressed.connect(_on_StartButton_pressed)
	if manage_btn:
		manage_btn.pressed.connect(_on_ManageDbButton_pressed)
	if exit_btn:
		exit_btn.pressed.connect(_on_ExitButton_pressed)

func _on_StartButton_pressed():
	var err = get_tree().change_scene_to_file("res://scenes/DatasetSelection.tscn")
	if err != OK:
		print("Error loading DatasetSelection scene: ", err)

func _on_ManageDbButton_pressed():
	var err = get_tree().change_scene_to_file("res://scenes/DatabaseManager.tscn")
	if err != OK:
		print("Error loading DatabaseManager scene: ", err)

func _on_ExitButton_pressed():
	get_tree().quit()
