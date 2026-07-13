extends Control

# Nodes
@onready var stats_hbox = $VBoxContainer/StatsHBox
@onready var progress_lbl = $VBoxContainer/StatsHBox/ProgressLabel
@onready var correct_lbl = $VBoxContainer/StatsHBox/CorrectLabel
@onready var incorrect_lbl = $VBoxContainer/StatsHBox/IncorrectLabel

@onready var mode_panel = $VBoxContainer/ModeSelectionPanel
@onready var mode1_btn = $VBoxContainer/ModeSelectionPanel/ButtonsHBox/Mode1Button
@onready var mode2_btn = $VBoxContainer/ModeSelectionPanel/ButtonsHBox/Mode2Button

@onready var game_panel = $VBoxContainer/GamePanel
@onready var prompt_lbl = $VBoxContainer/GamePanel/PromptLabel
@onready var pinyin_prompt_lbl = $VBoxContainer/GamePanel/PinyinPromptLabel
@onready var answer_input = $VBoxContainer/GamePanel/InputHBox/AnswerInput
@onready var submit_btn = $VBoxContainer/GamePanel/InputHBox/SubmitButton
@onready var feedback_lbl = $VBoxContainer/GamePanel/FeedbackLabel
@onready var next_btn = $VBoxContainer/GamePanel/NextButton

@onready var back_btn = $VBoxContainer/FooterHBox/BackButton

@onready var summary_overlay = $SummaryOverlay
@onready var summary_stats_lbl = $SummaryOverlay/Panel/VBoxContainer/SummaryStats
@onready var return_btn = $SummaryOverlay/Panel/VBoxContainer/ReturnButton

# Game State
var dataset = {}
var words = []
var game_mode = 1 # 1: Chinese -> English, 2: English -> Chinese
var current_index = 0
var correct_count = 0
var incorrect_count = 0
var has_answered = false

func _ready():
	# Load dataset from Global dynamically
	if is_inside_tree():
		var global_node = get_node_or_null("/root/Global")
		if global_node and (dataset == null or dataset.is_empty()):
			dataset = global_node.selected_dataset

	if dataset == null or not dataset.has("words") or dataset["words"].size() == 0:
		print("No active dataset loaded for the game. Returning.")
		_return_to_datasets()
		return

	words = dataset["words"]

	# Connect signals
	mode1_btn.pressed.connect(_on_ModeSelected.bind(1))
	mode2_btn.pressed.connect(_on_ModeSelected.bind(2))

	submit_btn.pressed.connect(_on_SubmitPressed)
	answer_input.text_submitted.connect(_on_AnswerSubmitted)
	next_btn.pressed.connect(_on_NextPressed)
	back_btn.pressed.connect(_on_QuitPressed)
	return_btn.pressed.connect(_on_ReturnPressed)

	# Setup initial layout
	mode_panel.visible = true
	game_panel.visible = false
	summary_overlay.visible = false
	stats_hbox.visible = false

func _on_ModeSelected(mode: int):
	game_mode = mode
	current_index = 0
	correct_count = 0
	incorrect_count = 0

	# Duplicate and shuffle words list on each new game start
	words = dataset["words"].duplicate(true)
	words.shuffle()

	mode_panel.visible = false
	game_panel.visible = true
	stats_hbox.visible = true

	_update_stats()
	_show_word()

func _update_stats():
	progress_lbl.text = "Word: %d / %d" % [current_index + 1 if current_index < words.size() else words.size(), words.size()]
	correct_lbl.text = "Correct: %d" % correct_count
	incorrect_lbl.text = "Incorrect: %d" % incorrect_count

func _show_word():
	if current_index >= words.size():
		_end_game()
		return

	has_answered = false
	var word = words[current_index]

	if game_mode == 1:
		# Chinese -> English (Pinyin hint is also visible!)
		prompt_lbl.text = word["chinese"]
		pinyin_prompt_lbl.text = "Pinyin: " + word["pinyin"]
		pinyin_prompt_lbl.visible = true
	else:
		# English -> Chinese
		prompt_lbl.text = word["english"]
		pinyin_prompt_lbl.visible = false

	answer_input.text = ""
	answer_input.editable = true
	submit_btn.disabled = false
	feedback_lbl.text = ""
	next_btn.visible = false

	if is_inside_tree():
		answer_input.grab_focus()

func _on_AnswerSubmitted(_text: String):
	_on_SubmitPressed()

func _on_SubmitPressed():
	if has_answered or current_index >= words.size():
		return

	var user_ans = answer_input.text.strip_edges()
	if user_ans == "":
		feedback_lbl.text = "Please enter an answer!"
		feedback_lbl.add_theme_color_override("font_color", Color(1, 0.7, 0.2, 1)) # orange warning
		return

	has_answered = true
	answer_input.editable = false
	submit_btn.disabled = true

	var word = words[current_index]
	var is_correct = false
	var correct_ans = ""

	if game_mode == 1:
		# Mode 1: Answer English (case insensitive)
		correct_ans = word["english"]
		is_correct = (user_ans.to_lower() == correct_ans.to_lower())
	else:
		# Mode 2: Answer Chinese Hanzi (exact/trimmed)
		correct_ans = word["chinese"]
		is_correct = (user_ans == correct_ans)

	if is_correct:
		correct_count += 1
		feedback_lbl.text = "Correct! (正确!)"
		feedback_lbl.add_theme_color_override("font_color", Color(0.368627, 0.768627, 0.368627, 1)) # green
	else:
		incorrect_count += 1
		feedback_lbl.text = "Incorrect! Answer is: " + correct_ans
		feedback_lbl.add_theme_color_override("font_color", Color(0.92549, 0.25098, 0.25098, 1)) # red

	_update_stats()

	# Show next button
	next_btn.text = "Finish Session" if current_index == words.size() - 1 else "Next Word"
	next_btn.visible = true
	if is_inside_tree():
		next_btn.grab_focus()

func _on_NextPressed():
	current_index += 1
	if current_index >= words.size():
		_end_game()
	else:
		_update_stats()
		_show_word()

func _end_game():
	game_panel.visible = false
	stats_hbox.visible = false
	summary_overlay.visible = true
	summary_stats_lbl.text = "You guessed %d out of %d words correctly!" % [correct_count, words.size()]
	if is_inside_tree():
		return_btn.grab_focus()

func _on_QuitPressed():
	_return_to_datasets()

func _on_ReturnPressed():
	_return_to_datasets()

func _return_to_datasets():
	var err = get_tree().change_scene_to_file("res://scenes/DatasetSelection.tscn")
	if err != OK:
		print("Error loading DatasetSelection: ", err)
