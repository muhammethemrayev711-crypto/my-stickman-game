extends Node3D

const PlayerScript = preload("res://Scripts/player.gd")
const UIScript = preload("res://UI/game_ui.gd")
var player: StickmanPlayer
var ui: Control
var buildings: Array[Dictionary] = []
var interior_nodes: Node3D
var is_inside := false
var active_building := ""

func _ready() -> void:
    _setup_environment()
    _make_ground()
    _make_city()
    player = PlayerScript.new()
    player.name = "Player"
    player.position = Vector3(0, 0.05, 5)
    add_child(player)
    ui = UIScript.new()
    add_child(ui)
    ui.move_changed.connect(_on_move_changed)
    ui.camera_drag.connect(_on_camera_drag)
    ui.interact_pressed.connect(_interact)
    ui.exit_pressed.connect(_exit_building)
    ui.request_prayer_setup.connect(_show_prayer_setup)

func _setup_environment() -> void:
    var env_node := WorldEnvironment.new()
    var env := Environment.new()
    env.background_mode = Environment.BG_SKY
    env.sky = Sky.new()
    env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color = Color(0.72, 0.78, 0.88)
    env.ambient_light_energy = 0.8
    env_node.environment = env
    add_child(env_node)
    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-48, -25, 0)
    sun.light_energy = 1.1
    add_child(sun)

func _make_ground() -> void:
    _box("Ground", Vector3(0, -0.25, 0), Vector3(90, 0.5, 90), Color(0.36, 0.52, 0.34), self)
    _box("Road", Vector3(0, 0.02, 0), Vector3(9, 0.08, 85), Color(0.20, 0.21, 0.23), self)
    for z in range(-38, 40, 8):
        _box("RoadMark", Vector3(0, 0.075, z), Vector3(0.18, 0.02, 3.2), Color(0.92, 0.86, 0.62), self)

func _make_city() -> void:
    _building("Cami", Vector3(-9, 0, -5), Vector3(7, 4.5, 7), Color(0.86, 0.82, 0.69), true)
    _building("Hayalhanem", Vector3(10, 0, -5), Vector3(8, 4.0, 7), Color(0.76, 0.70, 0.60), true)
    _building("Ev", Vector3(-12, 0, 12), Vector3(6, 3.5, 6), Color(0.76, 0.58, 0.48), true)
    _building("Kafe", Vector3(12, 0, 12), Vector3(7, 3.8, 6), Color(0.62, 0.72, 0.78), true)
    _building("Dükkan", Vector3(0, 0, -24), Vector3(7, 3.6, 6), Color(0.73, 0.72, 0.56), true)
    _building("Arsa", Vector3(22, 0, -20), Vector3(8, 0.2, 8), Color(0.42, 0.60, 0.36), false)
    _box("Minaret", Vector3(-9, 6.5, -5), Vector3(0.8, 5, 0.8), Color(0.83, 0.78, 0.64), self)
    _cone("Dome", Vector3(-9, 5.3, -5), 2.2, 1.4, Color(0.28, 0.52, 0.47), self)
    _label("CAMİ", Vector3(-9, 5.2, -1.2))
    _label("HAYALHANEM", Vector3(10, 4.7, -1.2))
    _label("EV", Vector3(-12, 4.1, 15.2))
    _label("KAFE", Vector3(12, 4.4, 15.2))

func _building(title: String, pos: Vector3, size: Vector3, color: Color, enterable: bool) -> void:
    var group := Node3D.new()
    group.name = title
    add_child(group)
    _box(title + "Body", pos + Vector3(0, size.y / 2.0, 0), size, color, group)
    _box(title + "Door", pos + Vector3(0, 1.0, size.z / 2.0 + 0.06), Vector3(1.2, 2.0, 0.12), Color(0.28, 0.18, 0.12), group)
    if enterable:
        var marker := _box(title + "Entry", pos + Vector3(0, 0.06, size.z / 2.0 + 1.4), Vector3(2.0, 0.12, 2.0), Color(0.95, 0.80, 0.25, 0.65), group)
        marker.material_override.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
        buildings.append({"name": title, "position": pos + Vector3(0, 0, size.z / 2.0 + 1.4)})

func _box(n: String, pos: Vector3, size: Vector3, color: Color, parent: Node) -> MeshInstance3D:
    var m := MeshInstance3D.new()
    m.name = n
    var mesh := BoxMesh.new()
    mesh.size = size
    m.mesh = mesh
    m.position = pos
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    mat.roughness = 0.95
    m.material_override = mat
    parent.add_child(m)
    return m

func _cone(n: String, pos: Vector3, radius: float, height: float, color: Color, parent: Node) -> void:
    var m := MeshInstance3D.new()
    m.name = n
    var mesh := CylinderMesh.new()
    mesh.top_radius = 0.05
    mesh.bottom_radius = radius
    mesh.height = height
    m.mesh = mesh
    m.position = pos
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    m.material_override = mat
    parent.add_child(m)

func _label(text_value: String, pos: Vector3) -> void:
    var label := Label3D.new()
    label.text = text_value
    label.position = pos
    label.font_size = 48
    label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    label.modulate = Color(0.16, 0.15, 0.13)
    add_child(label)

func _process(_delta: float) -> void:
    if is_inside:
        ui.set_nearby_building(active_building, true)
        return
    var nearest := ""
    var nearest_dist := 999.0
    for b in buildings:
        var d: float = player.global_position.distance_to(b.position)
        if d < nearest_dist:
            nearest_dist = d
            nearest = b.name
    ui.set_nearby_building(nearest, nearest_dist < 3.3)

func _on_move_changed(value: Vector2) -> void:
    player.move_input = value

func _on_camera_drag(dx: float, dy: float) -> void:
    player.rotate_camera(dx, dy)

func _interact() -> void:
    if is_inside:
        return
    var nearest := ""
    var nearest_dist := 999.0
    for b in buildings:
        var d: float = player.global_position.distance_to(b.position)
        if d < nearest_dist:
            nearest_dist = d
            nearest = b.name
    if nearest != "" and nearest_dist < 3.3:
        _enter_building(nearest)

func _enter_building(building_name: String) -> void:
    is_inside = true
    active_building = building_name
    GameState.inside_building = true
    GameState.current_building = building_name
    player.position = Vector3(0, 0.05, 0)
    player.camera_pitch = -0.12
    player.camera_distance = 4.2
    player._update_camera()
    if interior_nodes:
        interior_nodes.queue_free()
    interior_nodes = Node3D.new()
    add_child(interior_nodes)
    _box("InteriorFloor", Vector3(0, -0.1, 0), Vector3(18, 0.2, 18), Color(0.72, 0.67, 0.57), interior_nodes)
    _box("InteriorBack", Vector3(0, 2.2, -8), Vector3(18, 4.5, 0.3), Color(0.84, 0.79, 0.69), interior_nodes)
    if building_name == "Hayalhanem":
        _box("Stage", Vector3(0, 0.35, -5.8), Vector3(7, 0.7, 2), Color(0.40, 0.27, 0.18), interior_nodes)
        _box("Screen", Vector3(0, 3.0, -7.6), Vector3(5.8, 3.0, 0.15), Color(0.12, 0.15, 0.18), interior_nodes)
        for i in range(3):
            _box("Chair", Vector3(-2 + i * 2, 0.55, 1.0), Vector3(1.0, 1.0, 1.0), Color(0.32, 0.22, 0.15), interior_nodes)
    elif building_name == "Cami":
        _box("Carpet", Vector3(0, 0.03, 0), Vector3(14, 0.08, 14), Color(0.24, 0.43, 0.35), interior_nodes)
        for i in range(4):
            _box("CarpetLine", Vector3(0, 0.09, -5 + i * 3), Vector3(13, 0.02, 0.05), Color(0.86, 0.77, 0.56), interior_nodes)
        _box("Ablution", Vector3(-5, 0.55, 4), Vector3(2.5, 1.0, 1.0), Color(0.35, 0.62, 0.72), interior_nodes)
    else:
        for i in range(3):
            _box("Furniture", Vector3(-3 + i * 3, 0.55, -1), Vector3(1.4, 1.0, 1.2), Color(0.35, 0.24, 0.17), interior_nodes)
    ui.show_inside(building_name)

func _exit_building() -> void:
    if not is_inside:
        return
    is_inside = false
    GameState.inside_building = false
    if interior_nodes:
        interior_nodes.queue_free()
    player.position = Vector3(0, 0.05, 4)
    player.camera_pitch = -0.48
    player.camera_distance = 6.0
    player._update_camera()
    ui.show_outside()

func _show_prayer_setup() -> void:
    ui.open_prayer_setup()
