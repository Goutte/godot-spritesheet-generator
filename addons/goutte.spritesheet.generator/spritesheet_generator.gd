tool
extends Node

# Generated files will be created in this directory. Leave empty for Desktop.
export(String, DIR, GLOBAL) var output_path = ""
# Try not to put spaces or exotic characters in here. Please? It'll melt.
export var file_prefix = "mY_pREciOUs"
# We try different strategies for transparency
export(Color, RGB) var transparent_color_1 = Color(0, 0, 0)
# Useful for shadows, notably
export(Color, RGB) var transparent_color_2 = Color(0, 0, 0)

const DEFAULT_WINDOW_SIZE = 128
const DEFAULT_RECORD_FRAMES = 12
const DEFAULT_RECORD_DURATION = 3.0

var __record_frames = DEFAULT_RECORD_FRAMES
var __record_duration = DEFAULT_RECORD_DURATION * 1000.0  # ms
var __record_current_frame = 0
var __record_in_progress = false
var __record_started_at  # local timestamp in ms


### METHOD A -- RECORD FOR A DURATION ##########################################

func record_for_a_while(
		duration=DEFAULT_RECORD_DURATION, frames=DEFAULT_RECORD_FRAMES,
		window_size=Vector2(DEFAULT_WINDOW_SIZE, DEFAULT_WINDOW_SIZE)):
	"""
	/!. Recording will wait for two frames before actually starting.
	    This can be compensated or overlooked, but it is annoying.
		If you have suggestions regarding this matter, PRs are most welcome!
	
	duration: a float, in seconds. Defaults to 3.
	frames: how many frames you want, the number of sprites in the sheet. 12.
	window_size: Vector2 or null to disable, defaults to a 128px square.
	             You are advised to use powers of two. Probably. Depends. Maybe?
				 It's an opt-out because high sizes fly too close to the sun.
	"""
	assert duration > 0
	assert frames > 0
	__record_frames = frames
	__record_duration = duration * 1000.0
	__record_in_progress = true
	__record_started_at = null
	__record_current_frame = 0

	if window_size:
		OS.window_size = window_size


### METHOD B -- CAPTURE YOUR FRAMES YOURSELF AND THEN GENERATE #################

var __capture_index = 0
func capture_image():
	get_viewport().set_clear_mode(Viewport.CLEAR_MODE_ONLY_NEXT_FRAME)
	yield(get_tree(), "idle_frame")
	yield(get_tree(), "idle_frame")
	var image = get_viewport().get_texture().get_data()
	image.flip_y()
	image.save_png("%s%s_capture_%03d.png" % [
		__get_output_path(), file_prefix, __capture_index
	])
	__capture_index += 1


func generate_spritesheet():
	print("Generating spritesheets…")
	
	var pid
	var is_blocking = true
	var output = []
	var file = 'addons/goutte.spritesheet.generator/magic.sh'
	var options = [
		file, __get_output_path(), file_prefix,
		transparent_color_1.r8, transparent_color_1.g8, transparent_color_1.b8,
		transparent_color_2.r8, transparent_color_2.g8, transparent_color_2.b8
	]
	pid = OS.execute('/bin/bash', options, is_blocking, output)
	if (not output) or (not output[0].strip_edges()):
		printerr(
			"ERROR: Failed to execute the bash script '%s'.\n"%file +
			"The pid was '%s'.\n"%pid +
			"You should check:\n" +
			"- are you on windows or mac ?\n"+
			"  They have not even been tested yet. Might work, might not.\n" +
			"- the execution bit of the shell script ($ chmod a+x %s)\n"%file +
			"- your install of GIMP ($ gimp -v)\n" +
			"- your install of ImageMagick ($ montage)\n" +
			"- can you even bash ? ($ /bin/bash)\n" +
			"\n" +
			"To grab the stderr of the shell script, perhaps try running:\n" +
			"$ /bin/bash %s\n" % [join(options, ' ')]
		)
	else:
		print("==OUTPUT LOG==")
		for line in output:
			print("%s\n" % line)
		print("==============")
		print("Done generating spritesheets.")


### LOOP (FOR METHOD A) ########################################################

func _process(delta):
	if not __record_in_progress:
		return
	if not __record_started_at:
		__record_started_at = OS.get_ticks_msec()

	var now = OS.get_ticks_msec()
	var elapsed = now - __record_started_at

	if elapsed > __record_current_frame * __record_duration / __record_frames \
	   and elapsed < __record_duration:
		capture_image()
		__record_current_frame += 1

	if elapsed > __record_duration:
		__record_in_progress = false
		generate_spritesheet()


### PRIVATES ###################################################################

func __get_path_separator():
	return '/'  # sorry

func __get_output_path():
	var _output_path = output_path
	
	if _output_path == "":
		_output_path = OS.get_system_dir(OS.SYSTEM_DIR_DESKTOP)
	
	if not _output_path.is_abs_path():
		printerr("The output path MUST be absolute. Got '%s'." % _output_path)
		assert not "really friendly, this. How to make it better?"
	
	if _output_path.begins_with("res://"):
		printerr("Resource paths like '%s' are not supported." % _output_path)
		assert not "really friendly, this. How to make it better?"

	# List of nopes, trying to get abspath(res://) when in debug mode
#	var c = get_script().get_path().get_base_dir().get_base_dir().get_base_dir()
#	prints("CurrDir", c)
#	var executable_path = OS.get_executable_path()
#	prints("ExPath", executable_path)
#	var system_dir = OS.get_system_dir(OS.SYSTEM_DIR_PROJECT)
#	prints("SysDir", system_dir)
	
	var path_sep = __get_path_separator()
	if _output_path[-1] != path_sep:
		_output_path += path_sep
	return _output_path


### TOOLSHED ###################################################################

func join(array, glue=', '):
	"""
	Where is this? Seriously, where is it? I must have glue in the eyes.
	"""
	var s = ""
	for i in range(array.size()):
		if i > 0:
			s += glue
		s += "%s" % array[i] # str()? #benchmark #whatever
	return s

#func _ready():
#	__test()

func __test():
	output_path = "/home/oryx/code/godot/my_project"
	prints('A:', __get_output_path())
	assert __get_output_path() == "/home/oryx/code/godot/my_project/"
	output_path = ""
	prints('B:', __get_output_path())
	assert __get_output_path() == "/home/goutte/Desktop/"
	# How to support these when running interactively? Besides more shell hacks?
#	output_path = "res://data/graphics"
#	prints('C:', __get_output_path())
#	assert __get_output_path() == "???"