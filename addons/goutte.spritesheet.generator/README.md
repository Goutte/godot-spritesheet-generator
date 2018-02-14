
Spritesheet Generator for Godot
-------------------------------

[![MIT](https://img.shields.io/github/license/Goutte/godot-spritesheet-generator.svg)](https://github.com/Goutte/godot-spritesheet-generator)
[![Release](https://img.shields.io/github/release/Goutte/godot-spritesheet-generator.svg)](https://github.com/Goutte/godot-spritesheet-generator/releases)
[![Donate](https://img.shields.io/badge/%CE%9E-%E2%99%A5-blue.svg)](https://etherscan.io/address/0xB48C3B718a1FF3a280f574Ad36F04068d7EAf498)


An _experimental_ [Godot](https://godotengine.org/) `3.x` addon
that allows you to capture frames and turn them into a spritesheet
with a transparent background.


STABILITY DISCLAIMER
--------------------

This is a highly unstable and experimental plugin.
Do not expect it to work, or to become stable anytime soon.
Bloody edges are everywhere.


How it works
------------

1. Capture screenshots of your scene at regular intervals
2. Concatenate them together into a single long horizontal spritesheet
3. Apply multiple transparency schemes

Steps 2 and 3 are ran by a bash script.

The plugin generates multiple images, so you can choose which one renders best for your scene.


Dependencies
------------

- **Linux**, because porting to Windows is still ongoing. See [issue #1](https://github.com/Goutte/godot-spritesheet-generator/issues/1).
- **ImageMagick** (we could probably do it all with GIMP, PRs welcome)
- **GIMP**

### Ubuntu Flavors

```
apt install gimp imagemagick
```

### Windows

Looks a bit tricky.
[Chocolatey](https://chocolatey.org/install) goes a long way.

```
choco install gimp imagemagick
```


Install
-------

The installation is as usual, you can do it from the assets lib.
You can also copy the files of this repository in your project.

Then, enable the plugin in `Scene > Project Settings > Plugins`.


Demo
----

There's a test scene in the `test` branch :

```
git clone https://github.com/Goutte/godot-spritesheet-generator.git gsg_test
cd gsg_test
git checkout test
godot -e TestScene.tscn
```

Run the scene, and then look at your Desktop.


Usage
-----

Add a `SpritesheetGenerator` node to your scene, configure it.

Then, call it from somewhere, like so :

``` gdscript
onready var sg = $SpritesheetGenerator

func _ready():
    var duration_in_seconds = 3.0
    var frames_to_record = 12
    var window_size = Vector2(128,128)
	sg.record_for_a_while(duration_in_seconds, frames_to_record, window_size)

	# or simply
	sg.record_for_a_while()
```

Overall, the flow goes like this:

- Make your 3D scene
- Cook up an animation
- Set up a `SpritesheetGenerator` node, configure it
- Run your scene
- Inspect your generated spritesheet files
- Tune the background and shadow colors in the `SpritesheetGenerator`
- Run your scene again
- Enjoy your transparent spritesheets

Since this plugin has no resizing capabilities
_(did we mention that PRs are welcome?)_,
you should set your window size to a small value.


Caveats
-------

You *will* encounter bugs, run into incomplete features, and find this unusable.
Tweaking the gimp scripts goes a long way into improving results.
Share them so we can make better presets!

- No mask support yet, which would be the ideal solution for transparency.
- Recording is delayed by two frames before actually starting.


Pitfalls
--------

- Spaces in the output directory path. Not tested, not expected to work.


Thanks
------

- Adrenesis for porting this hell to Windows
- Sileo for his insights into gimp plumbings
- Inspiration: https://github.com/Maujoe/godot-simlpe-screenshot-script


Feedback and contributions are welcome!


