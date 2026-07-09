extends Control

const SAVE_PATH = "user://custom_datasets.json"

const BUILT_IN_DATASETS = {
	"colors": {
		"name": "Colors (颜色)",
		"words": [
			{"english": "Red", "chinese": "红色", "pinyin": "hóng sè"},
			{"english": "Blue", "chinese": "蓝色", "pinyin": "lán sè"},
			{"english": "Yellow", "chinese": "黄色", "pinyin": "huáng sè"},
			{"english": "Green", "chinese": "绿色", "pinyin": "lǜ sè"},
			{"english": "Black", "chinese": "黑色", "pinyin": "hēi sè"},
			{"english": "White", "chinese": "白色", "pinyin": "bái sè"},
			{"english": "Orange", "chinese": "橙色", "pinyin": "chéng sè"},
			{"english": "Purple", "chinese": "紫色", "pinyin": "zǐ sè"},
			{"english": "Pink", "chinese": "粉色", "pinyin": "fěn sè"},
			{"english": "Gray", "chinese": "灰色", "pinyin": "huī sè"}
		]
	},
	"bodyparts": {
		"name": "Body Parts (身体部位)",
		"words": [
			{"english": "Head", "chinese": "头", "pinyin": "tóu"},
			{"english": "Eye", "chinese": "眼睛", "pinyin": "yǎn jing"},
			{"english": "Nose", "chinese": "鼻子", "pinyin": "bí zi"},
			{"english": "Mouth", "chinese": "嘴巴", "pinyin": "zuǐ ba"},
			{"english": "Ear", "chinese": "耳朵", "pinyin": "ěr duo"},
			{"english": "Hand", "chinese": "手", "pinyin": "shǒu"},
			{"english": "Foot", "chinese": "脚", "pinyin": "jiǎo"},
			{"english": "Leg", "chinese": "腿", "pinyin": "tuǐ"},
			{"english": "Arm", "chinese": "手臂", "pinyin": "shǒu bì"},
			{"english": "Face", "chinese": "脸", "pinyin": "liǎn"}
		]
	}
}

# UI Node References
@onready var db_list = $VBoxContainer/MainHBox/LeftVBox/DatabaseList
@onready var word_tree = $VBoxContainer/MainHBox/RightVBox/WordTree

# DB buttons
@onready var new_db_btn = $VBoxContainer/MainHBox/LeftVBox/DbButtonsHBox/NewDbButton
@onready var duplicate_db_btn = $VBoxContainer/MainHBox/LeftVBox/DbButtonsHBox/DuplicateDbButton
@onready var delete_db_btn = $VBoxContainer/MainHBox/LeftVBox/DbButtonsHBox/DeleteDbButton

# Word buttons
@onready var add_word_btn = $VBoxContainer/MainHBox/RightVBox/WordButtonsHBox/AddWordButton
@onready var edit_word_btn = $VBoxContainer/MainHBox/RightVBox/WordButtonsHBox/EditWordButton
@onready var delete_word_btn = $VBoxContainer/MainHBox/RightVBox/WordButtonsHBox/DeleteWordButton

# Footer
@onready var back_btn = $VBoxContainer/FooterHBox/BackButton

# Overlays & Inputs
@onready var db_overlay = $DbEditOverlay
@onready var db_overlay_title = $DbEditOverlay/Panel/VBoxContainer/Title
@onready var db_name_input = $DbEditOverlay/Panel/VBoxContainer/NameInput
@onready var db_error_lbl = $DbEditOverlay/Panel/VBoxContainer/ErrorLabel
@onready var db_save_btn = $DbEditOverlay/Panel/VBoxContainer/ButtonsHBox/SaveButton
@onready var db_cancel_btn = $DbEditOverlay/Panel/VBoxContainer/ButtonsHBox/CancelButton

@onready var word_overlay = $WordEditOverlay
@onready var word_overlay_title = $WordEditOverlay/Panel/VBoxContainer/Title
@onready var word_eng_input = $WordEditOverlay/Panel/VBoxContainer/EnglishHBox/Input
@onready var word_chi_input = $WordEditOverlay/Panel/VBoxContainer/ChineseHBox/Input
@onready var word_pin_input = $WordEditOverlay/Panel/VBoxContainer/PinyinHBox/Input
@onready var word_error_lbl = $WordEditOverlay/Panel/VBoxContainer/ErrorLabel
@onready var word_save_btn = $WordEditOverlay/Panel/VBoxContainer/ButtonsHBox/SaveButton
@onready var word_cancel_btn = $WordEditOverlay/Panel/VBoxContainer/ButtonsHBox/CancelButton

# Internal State
var custom_datasets = {}
var all_datasets = {}
var dataset_keys = [] # Order of keys in db_list
var selected_key = "" # Key of currently selected dataset
var editing_word_index = -1 # Index of word being edited, -1 for adding new

# Database creation state
var db_action_type = "" # "new" or "duplicate"

func _ready():
	_connect_signals()
	_load_custom_datasets()
	_merge_all_datasets()
	_configure_word_tree()
	_populate_db_list()

	# Select first item by default
	if db_list.get_item_count() > 0:
		db_list.select(0)
		_on_DatabaseList_item_selected(0)
	else:
		_update_ui_for_selection()

func _connect_signals():
	db_list.item_selected.connect(_on_DatabaseList_item_selected)

	new_db_btn.pressed.connect(_on_NewDbButton_pressed)
	duplicate_db_btn.pressed.connect(_on_DuplicateDbButton_pressed)
	delete_db_btn.pressed.connect(_on_DeleteDbButton_pressed)

	add_word_btn.pressed.connect(_on_AddWordButton_pressed)
	edit_word_btn.pressed.connect(_on_EditWordButton_pressed)
	delete_word_btn.pressed.connect(_on_DeleteWordButton_pressed)

	back_btn.pressed.connect(_on_BackButton_pressed)

	# Overlay buttons
	db_save_btn.pressed.connect(_on_DbSaveButton_pressed)
	db_cancel_btn.pressed.connect(_on_DbCancelButton_pressed)

	word_save_btn.pressed.connect(_on_WordSaveButton_pressed)
	word_cancel_btn.pressed.connect(_on_WordCancelButton_pressed)

func _configure_word_tree():
	word_tree.columns = 3
	word_tree.set_column_title(0, "English")
	word_tree.set_column_title(1, "Chinese (Hanzi)")
	word_tree.set_column_title(2, "Romanised (Pinyin)")
	word_tree.set_column_titles_visible(true)

	word_tree.set_column_expand(0, true)
	word_tree.set_column_expand(1, true)
	word_tree.set_column_expand(2, true)

func _load_custom_datasets():
	if not FileAccess.file_exists(SAVE_PATH):
		custom_datasets = {}
		return

	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		custom_datasets = {}
		return

	var text = file.get_as_text()
	file.close()

	var json = JSON.new()
	var err = json.parse(text)
	if err == OK and typeof(json.data) == TYPE_DICTIONARY:
		custom_datasets = json.data
	else:
		custom_datasets = {}

func _save_custom_datasets():
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if not file:
		print("Error saving custom datasets")
		return
	file.store_string(JSON.stringify(custom_datasets, "  "))
	file.close()

func _merge_all_datasets():
	all_datasets = {}
	dataset_keys = []

	# 1. Built-in
	for key in BUILT_IN_DATASETS.keys():
		var ds = BUILT_IN_DATASETS[key].duplicate(true)
		ds["custom"] = false
		all_datasets[key] = ds
		dataset_keys.append(key)

	# 2. Custom
	for key in custom_datasets.keys():
		var ds = custom_datasets[key].duplicate(true)
		ds["custom"] = true
		all_datasets[key] = ds
		dataset_keys.append(key)

func _populate_db_list():
	db_list.clear()
	for key in dataset_keys:
		var ds = all_datasets[key]
		if ds["custom"]:
			db_list.add_item(ds["name"])
		else:
			db_list.add_item(ds["name"] + " (Built-in)")

func _on_DatabaseList_item_selected(index):
	if index >= 0 and index < dataset_keys.size():
		selected_key = dataset_keys[index]
	else:
		selected_key = ""

	_update_ui_for_selection()
	_display_selected_words()

func _update_ui_for_selection():
	if selected_key == "" or !all_datasets.has(selected_key):
		duplicate_db_btn.disabled = true
		delete_db_btn.disabled = true
		add_word_btn.disabled = true
		edit_word_btn.disabled = true
		delete_word_btn.disabled = true
		return

	var ds = all_datasets[selected_key]
	var is_custom = ds["custom"]

	duplicate_db_btn.disabled = false
	delete_db_btn.disabled = !is_custom
	add_word_btn.disabled = !is_custom

	# Edit/Delete word button status depends on selection in Tree and whether it's custom
	_update_word_selection_buttons()

func _update_word_selection_buttons():
	if selected_key == "" or !all_datasets.has(selected_key):
		edit_word_btn.disabled = true
		delete_word_btn.disabled = true
		return

	var ds = all_datasets[selected_key]
	var is_custom = ds["custom"]
	var selected_item = word_tree.get_selected()

	var has_word_selected = (selected_item != null and selected_item != word_tree.get_root())

	edit_word_btn.disabled = !(is_custom and has_word_selected)
	delete_word_btn.disabled = !(is_custom and has_word_selected)

func _display_selected_words():
	word_tree.clear()
	if selected_key == "" or !all_datasets.has(selected_key):
		return

	var root = word_tree.create_item()
	var words = all_datasets[selected_key]["words"]
	for word in words:
		var item = word_tree.create_item(root)
		item.set_text(0, word["english"])
		item.set_text(1, word["chinese"])
		item.set_text(2, word["pinyin"])

	# Connect tree selection change to update edit/delete buttons
	if not word_tree.item_selected.is_connected(_on_WordTree_item_selected):
		word_tree.item_selected.connect(_on_WordTree_item_selected)

func _on_WordTree_item_selected():
	_update_word_selection_buttons()

func _on_BackButton_pressed():
	var err = get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
	if err != OK:
		print("Error loading MainMenu: ", err)

# ==========================================
# DATASET ACTIONS (NEW, DUPLICATE, DELETE)
# ==========================================

func _on_NewDbButton_pressed():
	db_action_type = "new"
	db_overlay_title.text = "Create New Dataset"
	db_name_input.text = ""
	db_error_lbl.text = ""
	db_overlay.visible = true
	if is_inside_tree():
		db_name_input.grab_focus()

func _on_DuplicateDbButton_pressed():
	if selected_key == "" or !all_datasets.has(selected_key):
		return
	db_action_type = "duplicate"
	db_overlay_title.text = "Duplicate Dataset"
	var current_name = all_datasets[selected_key]["name"]
	db_name_input.text = current_name + " Copy"
	db_error_lbl.text = ""
	db_overlay.visible = true
	if is_inside_tree():
		db_name_input.grab_focus()

func _on_DbCancelButton_pressed():
	db_overlay.visible = false

func _on_DbSaveButton_pressed():
	var db_name = db_name_input.text.strip_edges()
	if db_name == "":
		db_error_lbl.text = "Name cannot be empty!"
		return

	# Check for name uniqueness
	for key in all_datasets.keys():
		if all_datasets[key]["name"].to_lower() == db_name.to_lower():
			db_error_lbl.text = "A dataset with this name already exists!"
			return

	# Generate unique ID in Godot 4 format
	var new_key = "custom_" + str(Time.get_ticks_msec())

	if db_action_type == "new":
		custom_datasets[new_key] = {
			"name": db_name,
			"words": []
		}
	elif db_action_type == "duplicate":
		var source_words = all_datasets[selected_key]["words"].duplicate(true)
		custom_datasets[new_key] = {
			"name": db_name,
			"words": source_words
		}

	_save_custom_datasets()
	_merge_all_datasets()
	_populate_db_list()

	# Select the new dataset
	var index = dataset_keys.find(new_key)
	if index >= 0:
		db_list.select(index)
		_on_DatabaseList_item_selected(index)

	db_overlay.visible = false

func _on_DeleteDbButton_pressed():
	if selected_key == "" or !all_datasets.has(selected_key):
		return
	if !all_datasets[selected_key]["custom"]:
		return # Cannot delete built-in

	custom_datasets.erase(selected_key)
	_save_custom_datasets()
	_merge_all_datasets()
	_populate_db_list()

	# Select first item after deletion
	if db_list.get_item_count() > 0:
		db_list.select(0)
		_on_DatabaseList_item_selected(0)
	else:
		selected_key = ""
		_update_ui_for_selection()
		_display_selected_words()

# ==========================================
# WORD ACTIONS (ADD, EDIT, DELETE)
# ==========================================

func _on_AddWordButton_pressed():
	if selected_key == "" or !all_datasets[selected_key]["custom"]:
		return
	editing_word_index = -1
	word_overlay_title.text = "Add New Word"
	word_eng_input.text = ""
	word_chi_input.text = ""
	word_pin_input.text = ""
	word_error_lbl.text = ""
	word_overlay.visible = true
	if is_inside_tree():
		word_eng_input.grab_focus()

func _on_EditWordButton_pressed():
	if selected_key == "" or !all_datasets[selected_key]["custom"]:
		return

	var selected_item = word_tree.get_selected()
	if selected_item == null or selected_item == word_tree.get_root():
		return

	# Find index of selected word
	var children = word_tree.get_root().get_children()
	editing_word_index = children.find(selected_item)

	if editing_word_index == -1:
		return

	var word = custom_datasets[selected_key]["words"][editing_word_index]
	word_overlay_title.text = "Edit Word"
	word_eng_input.text = word["english"]
	word_chi_input.text = word["chinese"]
	word_pin_input.text = word["pinyin"]
	word_error_lbl.text = ""
	word_overlay.visible = true
	if is_inside_tree():
		word_eng_input.grab_focus()

func _on_WordCancelButton_pressed():
	word_overlay.visible = false

func _on_WordSaveButton_pressed():
	var eng = word_eng_input.text.strip_edges()
	var chi = word_chi_input.text.strip_edges()
	var pin = word_pin_input.text.strip_edges()

	if eng == "" or chi == "" or pin == "":
		word_error_lbl.text = "All fields are required!"
		return

	var word_data = {
		"english": eng,
		"chinese": chi,
		"pinyin": pin
	}

	if editing_word_index == -1:
		# Add new word
		custom_datasets[selected_key]["words"].append(word_data)
	else:
		# Edit existing word
		custom_datasets[selected_key]["words"][editing_word_index] = word_data

	_save_custom_datasets()
	_merge_all_datasets()
	_display_selected_words()

	# Reselect the updated/added word if possible
	var children = word_tree.get_root().get_children()
	if editing_word_index != -1:
		if editing_word_index < children.size():
			children[editing_word_index].select(0)
	else:
		# Select the newly added last word
		if children.size() > 0:
			children[children.size() - 1].select(0)

	word_overlay.visible = false

func _on_DeleteWordButton_pressed():
	if selected_key == "" or !all_datasets[selected_key]["custom"]:
		return

	var selected_item = word_tree.get_selected()
	if selected_item == null or selected_item == word_tree.get_root():
		return

	# Find index of selected word
	var children = word_tree.get_root().get_children()
	var target_idx = children.find(selected_item)

	if target_idx == -1:
		return

	custom_datasets[selected_key]["words"].remove_at(target_idx)
	_save_custom_datasets()
	_merge_all_datasets()
	_display_selected_words()
