extends WorldEnvironment

onready var mesh = $TestMesh
onready var sg = $SpritesheetGenerator

var animation_duration = 3.0

func _ready():
	sg.record_for_a_while(animation_duration)

func _process(delta):
	var theta = OS.get_ticks_msec() * TAU / (animation_duration * 1000 * 4)
	mesh.rotation = Vector3(0, theta, 0)
