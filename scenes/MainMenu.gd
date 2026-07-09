extends Control

func _ready():
	var start_btn = $VBoxContainer/StartButton
	var exit_btn = $VBoxContainer/ExitButton
	if start_btn:
		start_btn.connect("pressed", self, "_on_StartButton_pressed")
	if exit_btn:
		exit_btn.connect("pressed", self, "_on_ExitButton_pressed")

func _on_StartButton_pressed():
	var err = get_tree().change_scene("res://scenes/DatasetSelection.tscn")
	if err != OK:
		print("Error loading DatasetSelection scene: ", err)

func _on_ExitButton_pressed():
	get_tree().quit()
