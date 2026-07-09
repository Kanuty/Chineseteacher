extends SceneTree

func _init():
	print("--- Running Godot automated validation tests ---")
	test_main_menu()
	test_dataset_selection()
	print("--- All tests passed successfully! ---")
	quit(0)

func test_main_menu():
	print("Testing MainMenu scene...")
	var main_menu_scene = load("res://scenes/MainMenu.tscn")
	assert(main_menu_scene != null, "Failed to load MainMenu.tscn")

	var main_menu = main_menu_scene.instance()
	assert(main_menu != null, "Failed to instance MainMenu")

	# Verify child nodes
	var background = main_menu.get_node_or_null("Background")
	assert(background != null, "Background node not found")
	assert(background is ColorRect, "Background is not a ColorRect")

	var vbox = main_menu.get_node_or_null("VBoxContainer")
	assert(vbox != null, "VBoxContainer node not found")

	var title = vbox.get_node_or_null("Title")
	assert(title != null, "Title node not found")
	assert(title.text == "Chinese Learning App", "Title text is incorrect: " + title.text)

	var subtitle = vbox.get_node_or_null("Subtitle")
	assert(subtitle != null, "Subtitle node not found")
	assert(subtitle.text == "中文学习助手", "Subtitle text is incorrect: " + subtitle.text)

	var start_btn = vbox.get_node_or_null("StartButton")
	assert(start_btn != null, "StartButton node not found")
	assert(start_btn.text == "Start", "StartButton text is incorrect: " + start_btn.text)

	var exit_btn = vbox.get_node_or_null("ExitButton")
	assert(exit_btn != null, "ExitButton node not found")
	assert(exit_btn.text == "Exit", "ExitButton text is incorrect: " + exit_btn.text)

	# Clean up
	main_menu.free()
	print("MainMenu scene test passed!")

func test_dataset_selection():
	print("Testing DatasetSelection scene...")
	var ds_scene = load("res://scenes/DatasetSelection.tscn")
	assert(ds_scene != null, "Failed to load DatasetSelection.tscn")

	var ds = ds_scene.instance()
	assert(ds != null, "Failed to instance DatasetSelection")

	# We call _ready manually because it's not added to the active scene tree yet
	ds._ready()

	var dataset_list = ds.get_node_or_null("VBoxContainer/MainHBox/LeftVBox/DatasetList")
	assert(dataset_list != null, "DatasetList node not found")
	assert(dataset_list is ItemList, "DatasetList is not an ItemList")

	# Verify that the 2 datasets are in the list
	assert(dataset_list.get_item_count() == 2, "Expected 2 datasets, got " + str(dataset_list.get_item_count()))
	assert(dataset_list.get_item_text(0) == "Colors (颜色)", "Unexpected first item: " + dataset_list.get_item_text(0))
	assert(dataset_list.get_item_text(1) == "Body Parts (身体部位)", "Unexpected second item: " + dataset_list.get_item_text(1))

	var word_tree = ds.get_node_or_null("VBoxContainer/MainHBox/RightVBox/WordTree")
	assert(word_tree != null, "WordTree node not found")
	assert(word_tree is Tree, "WordTree is not a Tree")
	assert(word_tree.columns == 3, "WordTree columns count incorrect: " + str(word_tree.columns))

	# Verify colors are selected by default
	var root = word_tree.get_root()
	assert(root != null, "Tree root not found")

	var first_child = root.get_children()
	assert(first_child != null, "Tree should have children items loaded")

	# Collect all words shown
	var words = []
	var current = first_child
	while current != null:
		words.append({
			"english": current.get_text(0),
			"chinese": current.get_text(1),
			"pinyin": current.get_text(2)
		})
		current = current.get_next()

	assert(words.size() == 10, "Expected 10 words, got: " + str(words.size()))

	# Check first word is Red (红色, hóng sè)
	assert(words[0]["english"] == "Red", "Unexpected first word: " + words[0]["english"])
	assert(words[0]["chinese"] == "红色", "Unexpected first word Chinese: " + words[0]["chinese"])
	assert(words[0]["pinyin"] == "hóng sè", "Unexpected first word Pinyin: " + words[0]["pinyin"])

	# Test switching dataset to bodyparts
	ds._on_DatasetList_item_selected(1)

	root = word_tree.get_root()
	first_child = root.get_children()
	assert(first_child != null, "Tree should have bodyparts items loaded")

	words = []
	current = first_child
	while current != null:
		words.append({
			"english": current.get_text(0),
			"chinese": current.get_text(1),
			"pinyin": current.get_text(2)
		})
		current = current.get_next()

	assert(words.size() == 10, "Expected 10 body parts, got: " + str(words.size()))
	assert(words[0]["english"] == "Head", "Unexpected first body part: " + words[0]["english"])
	assert(words[0]["chinese"] == "头", "Unexpected first body part Chinese: " + words[0]["chinese"])
	assert(words[0]["pinyin"] == "tóu", "Unexpected first body part Pinyin: " + words[0]["pinyin"])

	# Clean up
	ds.free()
	print("DatasetSelection scene test passed!")
