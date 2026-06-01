extends SceneTree

const SHIP_MODEL_SCENE: PackedScene = preload("res://assets/ships/models/hanse_cog_map_model.glb")
const OUTPUT_DIR := "res://assets/ships/directions"
const DIRECTIONS := [
	{"suffix": "e", "yaw": 0.0},
	{"suffix": "se", "yaw": PI * 0.25},
	{"suffix": "s", "yaw": PI * 0.5},
	{"suffix": "sw", "yaw": PI * 0.75},
	{"suffix": "w", "yaw": PI},
	{"suffix": "nw", "yaw": PI * 1.25},
	{"suffix": "n", "yaw": PI * 1.5},
	{"suffix": "ne", "yaw": PI * 1.75},
]

var viewport: SubViewport
var model_root: Node3D
var frame_count := 0
var direction_index := -1

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	_build_render_scene()

func _process(_delta: float) -> bool:
	frame_count += 1
	if frame_count < 6:
		return false

	if direction_index < 0:
		direction_index = 0
		_set_direction(direction_index)
		frame_count = 0
		return false

	_save_direction(direction_index)
	direction_index += 1
	if direction_index >= DIRECTIONS.size():
		return true

	_set_direction(direction_index)
	frame_count = 0
	return false

func _set_direction(index: int) -> void:
	var direction: Dictionary = DIRECTIONS[index]
	model_root.rotation.y = float(direction["yaw"])

func _save_direction(index: int) -> void:
	var direction: Dictionary = DIRECTIONS[index]
	var image := viewport.get_texture().get_image()
	image.convert(Image.FORMAT_RGBA8)
	var path := "%s/hanse_cog_dir_%02d_%s.png" % [OUTPUT_DIR, index, String(direction["suffix"])]
	var error := image.save_png(path)
	if error != OK:
		push_error("Could not save ship direction sprite: %s" % path)
		return
	print("Wrote ", path)

func _build_render_scene() -> void:
	viewport = SubViewport.new()
	viewport.size = Vector2i(256, 256)
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)

	var scene_root := Node3D.new()
	viewport.add_child(scene_root)

	model_root = Node3D.new()
	model_root.scale = Vector3(1.15, 1.15, 1.15)
	scene_root.add_child(model_root)

	var model := SHIP_MODEL_SCENE.instantiate()
	model_root.add_child(model)

	var light := DirectionalLight3D.new()
	light.light_energy = 2.4
	light.rotation_degrees = Vector3(-55.0, -35.0, 0.0)
	scene_root.add_child(light)

	var fill_light := DirectionalLight3D.new()
	fill_light.light_energy = 0.7
	fill_light.rotation_degrees = Vector3(-35.0, 145.0, 0.0)
	scene_root.add_child(fill_light)

	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 3.45
	camera.look_at_from_position(Vector3(0.0, 2.15, 2.95), Vector3(0.0, 0.0, 0.0), Vector3.UP)
	viewport.add_child(camera)
	camera.current = true
