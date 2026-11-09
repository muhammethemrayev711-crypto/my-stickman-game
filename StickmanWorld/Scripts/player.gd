extends CharacterBody3D
class_name StickmanPlayer

@export var move_speed := 4.0
@export var acceleration := 18.0
@export var jump_velocity := 4.0
var camera_yaw := 0.0
var camera_pitch := -0.48
var camera_distance := 6.0
var move_input := Vector2.ZERO
var camera_pivot: Node3D
var camera: Camera3D
var body_root: Node3D
var anim_time := 0.0
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready() -> void:
    _build_character()
    camera_pivot = Node3D.new()
    camera_pivot.position = Vector3(0, 1.35, 0)
    add_child(camera_pivot)
    camera = Camera3D.new()
    camera.position = Vector3(0, 0, camera_distance)
    camera.current = true
    camera_pivot.add_child(camera)
    _update_camera()

func _build_character() -> void:
    body_root = Node3D.new()
    add_child(body_root)
    _part(body_root, Vector3(0, 1.05, 0), Vector3(0.48, 0.72, 0.28), Color(0.22, 0.42, 0.72))
    _sphere(body_root, Vector3(0, 1.72, 0), 0.28, Color(0.88, 0.68, 0.52))
    _part(body_root, Vector3(-0.34, 1.08, 0), Vector3(0.16, 0.68, 0.17), Color(0.88, 0.68, 0.52))
    _part(body_root, Vector3(0.34, 1.08, 0), Vector3(0.16, 0.68, 0.17), Color(0.88, 0.68, 0.52))
    _part(body_root, Vector3(-0.14, 0.42, 0), Vector3(0.19, 0.72, 0.2), Color(0.16, 0.18, 0.22))
    _part(body_root, Vector3(0.14, 0.42, 0), Vector3(0.19, 0.72, 0.2), Color(0.16, 0.18, 0.22))
    _part(body_root, Vector3(-0.14, 0.06, -0.06), Vector3(0.25, 0.12, 0.38), Color(0.25, 0.16, 0.10))
    _part(body_root, Vector3(0.14, 0.06, -0.06), Vector3(0.25, 0.12, 0.38), Color(0.25, 0.16, 0.10))

func _part(parent: Node3D, pos: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
    var node := MeshInstance3D.new()
    var mesh := CapsuleMesh.new()
    mesh.radius = min(size.x, size.z) * 0.5
    mesh.height = max(size.y, mesh.radius * 2.0)
    node.mesh = mesh
    node.position = pos
    node.material_override = _mat(color)
    parent.add_child(node)
    return node

func _sphere(parent: Node3D, pos: Vector3, radius: float, color: Color) -> void:
    var node := MeshInstance3D.new()
    var mesh := SphereMesh.new()
    mesh.radius = radius
    mesh.height = radius * 2
    node.mesh = mesh
    node.position = pos
    node.material_override = _mat(color)
    parent.add_child(node)

func _mat(color: Color) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.roughness = 0.9
    return material

func _physics_process(delta: float) -> void:
    var keyboard := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
    var input_vec := move_input if move_input.length() > 0.08 else keyboard
    var forward := Vector3(sin(camera_yaw), 0, cos(camera_yaw))
    var right := Vector3(forward.z, 0, -forward.x)
    var direction := (right * input_vec.x + forward * input_vec.y).normalized()
    velocity.x = move_toward(velocity.x, direction.x * move_speed, acceleration * delta)
    velocity.z = move_toward(velocity.z, direction.z * move_speed, acceleration * delta)
    if not is_on_floor():
        velocity.y -= gravity * delta
    elif Input.is_action_just_pressed("jump"):
        velocity.y = jump_velocity
    move_and_slide()
    if direction.length() > 0.1:
        rotation.y = lerp_angle(rotation.y, atan2(direction.x, direction.z), delta * 10.0)
    anim_time += delta * Vector2(velocity.x, velocity.z).length()
    if body_root:
        var swing := sin(anim_time * 4.0) * 0.12
        body_root.position.y = abs(swing) * 0.15
        body_root.rotation.z = swing * 0.18

func rotate_camera(delta_x: float, delta_y: float) -> void:
    camera_yaw -= delta_x * 0.006
    camera_pitch = clamp(camera_pitch - delta_y * 0.004, -1.05, -0.18)
    _update_camera()

func zoom_camera(amount: float) -> void:
    camera_distance = clamp(camera_distance + amount, 3.2, 9.0)
    _update_camera()

func _update_camera() -> void:
    if not camera:
        return
    camera_pivot.rotation = Vector3(camera_pitch, camera_yaw, 0)
    camera.position = Vector3(0, 0, camera_distance)
    camera.look_at_from_position(camera.position, Vector3.ZERO, Vector3.UP)
