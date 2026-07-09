extends SceneTree

const TEST_SAVE_PATH = "user://custom_datasets.json"

func _init():
	print("--- Running Godot 4 automated validation tests ---")
	test_main_menu()
	test_font_fallbacks()
	test_database_manager()
	test_dataset_selection_with_custom()
	print("--- All tests passed successfully! ---")
	quit(0)

func test_main_menu():
	print("Testing MainMenu scene...")
	var main_menu_scene = load("res://scenes/MainMenu.tscn")
	assert(main_menu_scene != null, "Failed to load MainMenu.tscn")

	var main_menu = main_menu_scene.instantiate()
	assert(main_menu != null, "Failed to instantiate MainMenu")

	# Verify child nodes
	var background = main_menu.get_node_or_null("Background")
	assert(background != null, "Background node not found")

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

	var manage_btn = vbox.get_node_or_null("ManageDbButton")
	assert(manage_btn != null, "ManageDbButton node not found")
	assert(manage_btn.text == "Manage Databases", "ManageDbButton text is incorrect: " + manage_btn.text)

	var exit_btn = vbox.get_node_or_null("ExitButton")
	assert(exit_btn != null, "ExitButton node not found")
	assert(exit_btn.text == "Exit", "ExitButton text is incorrect: " + exit_btn.text)

	# Clean up
	main_menu.free()
	print("MainMenu scene test passed!")

func test_font_fallbacks():
	print("Testing Font Fallback configuration...")
	var font = load("res://assets/fonts/ChineseFont.tres")
	assert(font != null, "Failed to load ChineseFont.tres")
	assert(font is FontVariation, "ChineseFont is not a FontVariation")

	var fallback_count = font.fallbacks.size()
	assert(fallback_count > 0, "ChineseFont does not have fallback fonts configured")

	var fallback_font = font.fallbacks[0]
	assert(fallback_font != null, "Fallback font at index 0 is null")

	var title_font = load("res://assets/fonts/TitleFont.tres")
	assert(title_font != null, "Failed to load TitleFont.tres")
	assert(title_font is FontVariation, "TitleFont is not a FontVariation")
	assert(title_font.fallbacks.size() > 0, "TitleFont does not have fallback fonts configured")

	print("Font Fallback configuration test passed!")

func test_database_manager():
	print("Testing DatabaseManager scene and logic...")

	# 1. Clean any existing custom database file for testing
	if FileAccess.file_exists(TEST_SAVE_PATH):
		DirAccess.remove_absolute(TEST_SAVE_PATH)

	var dm_scene = load("res://scenes/DatabaseManager.tscn")
	assert(dm_scene != null, "Failed to load DatabaseManager.tscn")

	var dm = dm_scene.instantiate()
	assert(dm != null, "Failed to instantiate DatabaseManager")

	# Initialize scene
	dm._ready()

	# Verify default database list contains built-in ones
	assert(dm.db_list.get_item_count() == 2, "Default database list should have 2 built-in items")
	assert(dm.db_list.get_item_text(0) == "Colors (颜色) (Built-in)", "First item name incorrect")
	assert(dm.db_list.get_item_text(1) == "Body Parts (身体部位) (Built-in)", "Second item name incorrect")

	# Test duplication of built-in Colors
	dm._on_DatabaseList_item_selected(0) # Select Colors
	dm._on_DuplicateDbButton_pressed()

	# Overlay should be visible
	assert(dm.db_overlay.visible == true, "DB edit overlay should be visible on duplicate")
	assert(dm.db_name_input.text == "Colors (颜色) Copy", "Duplicate default name incorrect: " + dm.db_name_input.text)

	# Save duplicated dataset
	dm._on_DbSaveButton_pressed()
	assert(dm.db_overlay.visible == false, "Overlay should hide after save")

	# Database count should now be 3 (2 built-in + 1 custom)
	assert(dm.db_list.get_item_count() == 3, "Db list should now have 3 items")
	assert(dm.db_list.get_item_text(2) == "Colors (颜色) Copy", "Duplicated dataset name incorrect: " + dm.db_list.get_item_text(2))

	# Verify that the duplicated dataset has 10 words
	dm._on_DatabaseList_item_selected(2)
	var children = dm.word_tree.get_root().get_children()
	assert(children.size() == 10, "Duplicated dataset should have 10 words, got: " + str(children.size()))

	# Test Edit Word on Duplicated Dataset
	# Select the first word in the tree (Red)
	assert(children.size() > 0, "First word item should exist")
	var first_word_item = children[0]
	first_word_item.select(0)
	dm._on_WordTree_item_selected()

	# Click edit word
	dm._on_EditWordButton_pressed()
	assert(dm.word_overlay.visible == true, "Word overlay should be visible on edit")
	assert(dm.word_eng_input.text == "Red", "Word eng input incorrect: " + dm.word_eng_input.text)

	# Change word to Crimson / 绯红 / fēihóng
	dm.word_eng_input.text = "Crimson"
	dm.word_chi_input.text = "绯红"
	dm.word_pin_input.text = "fēihóng"
	dm._on_WordSaveButton_pressed()

	assert(dm.word_overlay.visible == false, "Word overlay should hide after save")

	# Verify edited word is saved and displayed
	var children_verify = dm.word_tree.get_root().get_children()
	first_word_item = children_verify[0]
	assert(first_word_item.get_text(0) == "Crimson", "Edited word English incorrect: " + first_word_item.get_text(0))
	assert(first_word_item.get_text(1) == "绯红", "Edited word Chinese incorrect: " + first_word_item.get_text(1))
	assert(first_word_item.get_text(2) == "fēihóng", "Edited word Pinyin incorrect: " + first_word_item.get_text(2))

	# Test creating a completely new database
	dm._on_NewDbButton_pressed()
	assert(dm.db_overlay.visible == true, "DB overlay should be visible on new")
	dm.db_name_input.text = "My Custom DB"
	dm._on_DbSaveButton_pressed()

	# Selected DB should now be the new one
	assert(dm.db_list.get_item_count() == 4, "DB count should be 4 now")
	assert(dm.db_list.get_item_text(3) == "My Custom DB", "New DB name incorrect")

	# Word tree should be empty
	dm._on_DatabaseList_item_selected(3)
	var children_empty = dm.word_tree.get_root().get_children()
	assert(children_empty.size() == 0, "New DB should be empty of words")

	# Add a new word
	dm._on_AddWordButton_pressed()
	assert(dm.word_overlay.visible == true, "Word overlay should show on add")
	dm.word_eng_input.text = "Apple"
	dm.word_chi_input.text = "苹果"
	dm.word_pin_input.text = "píngguǒ"
	dm._on_WordSaveButton_pressed()

	# Word tree should now have 1 word
	var children_add = dm.word_tree.get_root().get_children()
	assert(children_add.size() == 1, "Word tree should have 1 child")
	assert(children_add[0].get_text(0) == "Apple", "Added word English incorrect")
	assert(children_add[0].get_text(1) == "苹果", "Added word Chinese incorrect")
	assert(children_add[0].get_text(2) == "píngguǒ", "Added word Pinyin incorrect")

	# Clean up
	dm.free()
	print("DatabaseManager scene and logic test passed!")

func test_dataset_selection_with_custom():
	print("Testing DatasetSelection scene with custom datasets...")

	var ds_scene = load("res://scenes/DatasetSelection.tscn")
	assert(ds_scene != null, "Failed to load DatasetSelection.tscn")

	var ds = ds_scene.instantiate()
	assert(ds != null, "Failed to instantiate DatasetSelection")

	# Initialize scene
	ds._ready()

	# Verification: Since we created custom datasets in test_database_manager, they should be loaded!
	# We added "Colors (颜色) Copy" and "My Custom DB"
	assert(ds.dataset_list.get_item_count() == 4, "Dataset list should load custom items too! Expected 4, got " + str(ds.dataset_list.get_item_count()))
	assert(ds.dataset_list.get_item_text(0) == "Colors (颜色)", "Built-in Colors name incorrect")
	assert(ds.dataset_list.get_item_text(1) == "Body Parts (身体部位)", "Built-in Body parts name incorrect")
	assert(ds.dataset_list.get_item_text(2) == "Colors (颜色) Copy", "Custom Colors Copy name incorrect")
	assert(ds.dataset_list.get_item_text(3) == "My Custom DB", "My Custom DB name incorrect")

	# Select My Custom DB
	ds._on_DatasetList_item_selected(3)
	var children_selection = ds.word_tree.get_root().get_children()
	assert(children_selection.size() > 0, "Custom DB should have words displayed")
	assert(children_selection[0].get_text(0) == "Apple", "Custom DB word English incorrect")
	assert(children_selection[0].get_text(1) == "苹果", "Custom DB word Chinese incorrect")
	assert(children_selection[0].get_text(2) == "píngguǒ", "Custom DB word Pinyin incorrect")

	# Clean up
	ds.free()

	# Clean up test file
	if FileAccess.file_exists(TEST_SAVE_PATH):
		DirAccess.remove_absolute(TEST_SAVE_PATH)

	print("DatasetSelection with custom datasets test passed!")
