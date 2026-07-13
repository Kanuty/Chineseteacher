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

var all_datasets = {}
var dataset_keys = []
var selected_dataset_key = ""

@onready var dataset_list = $VBoxContainer/MainHBox/LeftVBox/DatasetList
@onready var word_tree = $VBoxContainer/MainHBox/RightVBox/WordTree
@onready var start_game_button = $VBoxContainer/FooterHBox/StartGameButton
@onready var back_button = $VBoxContainer/FooterHBox/BackButton

func _ready():
	# Connect signals
	dataset_list.item_selected.connect(_on_DatasetList_item_selected)
	start_game_button.pressed.connect(_on_StartGameButton_pressed)
	back_button.pressed.connect(_on_BackButton_pressed)

	# Configure Tree
	word_tree.columns = 3
	word_tree.set_column_title(0, "English")
	word_tree.set_column_title(1, "Chinese (Hanzi)")
	word_tree.set_column_title(2, "Romanised (Pinyin)")
	word_tree.set_column_titles_visible(true)

	# Set column sizes and alignment
	word_tree.set_column_expand(0, true)
	word_tree.set_column_expand(1, true)
	word_tree.set_column_expand(2, true)

	# Load all datasets (Built-in + Custom)
	_load_all_datasets()

	# Populate ItemList
	dataset_list.clear()
	for key in dataset_keys:
		dataset_list.add_item(all_datasets[key]["name"])

	# Select the first dataset by default
	if dataset_list.get_item_count() > 0:
		dataset_list.select(0)
		_on_DatasetList_item_selected(0)
	else:
		start_game_button.disabled = true

func _load_all_datasets():
	all_datasets = {}
	dataset_keys = []

	# Load built-in first
	for key in BUILT_IN_DATASETS.keys():
		all_datasets[key] = BUILT_IN_DATASETS[key].duplicate(true)
		dataset_keys.append(key)

	# Load custom from user storage
	var custom_datasets = {}
	if FileAccess.file_exists(SAVE_PATH):
		var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
		if file:
			var text = file.get_as_text()
			file.close()
			var json = JSON.new()
			var err = json.parse(text)
			if err == OK and typeof(json.data) == TYPE_DICTIONARY:
				custom_datasets = json.data

	for key in custom_datasets.keys():
		all_datasets[key] = custom_datasets[key]
		dataset_keys.append(key)

func _on_DatasetList_item_selected(index):
	if index >= 0 and index < dataset_keys.size():
		selected_dataset_key = dataset_keys[index]
		_display_dataset(selected_dataset_key)

		var ds = all_datasets[selected_dataset_key]
		var has_words = ds.has("words") and ds["words"].size() > 0
		start_game_button.disabled = not has_words

		if is_inside_tree():
			var global_node = get_node_or_null("/root/Global")
			if global_node:
				global_node.selected_dataset = ds
	else:
		start_game_button.disabled = true
		if is_inside_tree():
			var global_node = get_node_or_null("/root/Global")
			if global_node:
				global_node.selected_dataset = {}

func _display_dataset(key):
	word_tree.clear()
	var root = word_tree.create_item()

	var words = all_datasets[key]["words"]
	for word in words:
		var item = word_tree.create_item(root)
		item.set_text(0, word["english"])
		item.set_text(1, word["chinese"])
		item.set_text(2, word["pinyin"])

func _on_StartGameButton_pressed():
	var ds = null
	if is_inside_tree():
		var global_node = get_node_or_null("/root/Global")
		if global_node:
			ds = global_node.selected_dataset
	if ds == null or not ds.has("words") or ds["words"].size() == 0:
		return
	var err = get_tree().change_scene_to_file("res://scenes/FlashcardGame.tscn")
	if err != OK:
		print("Error loading FlashcardGame scene: ", err)

func _on_BackButton_pressed():
	var err = get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
	if err != OK:
		print("Error loading MainMenu scene: ", err)
