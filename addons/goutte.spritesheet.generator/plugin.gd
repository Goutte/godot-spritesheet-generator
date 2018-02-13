tool
extends EditorPlugin

func _enter_tree():
	add_custom_type(
		"SpritesheetGenerator", "Node",
		preload("res://addons/goutte.spritesheet.generator/spritesheet_generator.gd"),
		preload("res://addons/goutte.spritesheet.generator/icon_16.png")
	)
	# … and a description, or should it be in the script? I'm confused.

func _exit_tree():
	remove_custom_type("SpritesheetGenerator")
