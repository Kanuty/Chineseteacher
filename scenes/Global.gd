extends Node

var selected_dataset = {}

func _ready():
	# Dynamically set font fallback in code as an absolute fallback guarantee!
	var latin_font = load("res://assets/fonts/LiberationSans-Regular.ttf")
	var cjk_font = load("res://assets/fonts/wqy-microhei.ttf")
	if latin_font and cjk_font:
		latin_font.fallbacks = [cjk_font]
