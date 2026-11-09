extends Control

signal move_changed(value: Vector2)
signal camera_drag(dx: float, dy: float)
signal interact_pressed
signal exit_pressed
signal request_prayer_setup

var status_label: Label
var interact_button: Button
var exit_button: Button
var coins_label: Label
var joystick_center := Vector2.ZERO
var joystick_touch := -1
var camera_touch := -1
var camera_last := Vector2.ZERO
var prayer_panel: Panel
var reminder_panel: Panel
var selected_buttons: Dictionary = {}
var prayer_timer := 0.0
var reminder_active := false
var reminder_seconds := 600.0
var current_nearby := ""
var can_interact := false
var prayer_names := ["Sabah", "Öğle", "İkindi", "Akşam", "Yatsı"]

func _ready() -> void:
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _build_ui()
    _update_coins()
    if not GameState.prayer_enabled and GameState.selected_prayers.is_empty():
        call_deferred("open_prayer_setup")

func _build_ui() -> void:
    var top := Label.new()
    top.text = "STICKMAN WORLD"
    top.position = Vector2(24, 18)
    top.add_theme_font_size_override("font_size", 24)
    add_child(top)
    coins_label = Label.new()
    coins_label.position = Vector2(24, 52)
    coins_label.text = "Para: %d" % GameState.coins
    add_child(coins_label)
    status_label = Label.new()
    status_label.anchor_left = 0.5
    status_label.anchor_right = 0.5
    status_label.offset_left = -180
    status_label.offset_right = 180
    status_label.offset_top = 22
    status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    status_label.text = "Şehrini keşfet!"
    add_child(status_label)
    var joystick := Label.new()
    joystick.text = "◉"
    joystick.add_theme_font_size_override("font_size", 76)
    joystick.modulate = Color(1, 1, 1, 0.55)
    joystick.position = Vector2(38, size.y - 150)
    joystick.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
    add_child(joystick)
    var hint := Label.new()
    hint.text = "Sol alan: hareket   •   Sağ alan: kamera"
    hint.anchor_left = 0.5
    hint.anchor_right = 0.5
    hint.anchor_top = 1.0
    hint.anchor_bottom = 1.0
    hint.offset_left = -210
    hint.offset_right = 210
    hint.offset_top = -35
    hint.offset_bottom = -12
    hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    hint.add_theme_font_size_override("font_size", 14)
    add_child(hint)
    interact_button = Button.new()
    interact_button.text = "Giriş"
    interact_button.position = Vector2(0, 0)
    interact_button.anchor_left = 1
    interact_button.anchor_right = 1
    interact_button.anchor_top = 0.5
    interact_button.anchor_bottom = 0.5
    interact_button.offset_left = -145
    interact_button.offset_right = -25
    interact_button.offset_top = -28
    interact_button.offset_bottom = 28
    interact_button.visible = false
    interact_button.pressed.connect(func(): interact_pressed.emit())
    add_child(interact_button)
    exit_button = Button.new()
    exit_button.text = "Çık"
    exit_button.anchor_left = 1
    exit_button.anchor_right = 1
    exit_button.offset_left = -115
    exit_button.offset_right = -20
    exit_button.offset_top = 24
    exit_button.offset_bottom = 74
    exit_button.visible = false
    exit_button.pressed.connect(func(): exit_pressed.emit())
    add_child(exit_button)
    var prayer_button := Button.new()
    prayer_button.text = "Namaz ayarları"
    prayer_button.anchor_left = 1
    prayer_button.anchor_right = 1
    prayer_button.offset_left = -155
    prayer_button.offset_right = -20
    prayer_button.offset_top = 85
    prayer_button.offset_bottom = 130
    prayer_button.pressed.connect(open_prayer_setup)
    add_child(prayer_button)

func _input(event: InputEvent) -> void:
    if event is InputEventScreenTouch:
        if event.pressed:
            if event.position.x < get_viewport_rect().size.x * 0.43 and event.position.y > get_viewport_rect().size.y * 0.48:
                joystick_touch = event.index
                _update_joystick(event.position)
            elif event.position.x > get_viewport_rect().size.x * 0.45:
                camera_touch = event.index
                camera_last = event.position
        else:
            if event.index == joystick_touch:
                joystick_touch = -1
                move_changed.emit(Vector2.ZERO)
            if event.index == camera_touch:
                camera_touch = -1
    elif event is InputEventScreenDrag:
        if event.index == joystick_touch:
            _update_joystick(event.position)
        elif event.index == camera_touch:
            camera_drag.emit(event.relative.x, event.relative.y)
            camera_last = event.position
    elif event is InputEventMouseButton and event.pressed:
        if event.button_index == MOUSE_BUTTON_WHEEL_UP:
            camera_drag.emit(0, -18)
        elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
            camera_drag.emit(0, 18)

func _update_joystick(pos: Vector2) -> void:
    var center := Vector2(105, get_viewport_rect().size.y - 105)
    var v := (pos - center) / 70.0
    move_changed.emit(v.limit_length(1.0))

func set_nearby_building(name: String, allowed: bool) -> void:
    current_nearby = name
    can_interact = allowed
    interact_button.visible = allowed and not exit_button.visible
    if allowed:
        interact_button.text = "%s • Giriş" % name

func show_inside(name: String) -> void:
    status_label.text = name + " içindesin"
    interact_button.visible = false
    exit_button.visible = true

func show_outside() -> void:
    status_label.text = "Şehrini keşfet!"
    exit_button.visible = false

func open_prayer_setup() -> void:
    if prayer_panel:
        prayer_panel.queue_free()
    prayer_panel = Panel.new()
    prayer_panel.set_anchors_preset(Control.PRESET_CENTER)
    prayer_panel.position = Vector2(-190, -220)
    prayer_panel.size = Vector2(380, 440)
    add_child(prayer_panel)
    var vbox := VBoxContainer.new()
    vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    vbox.add_theme_constant_override("separation", 12)
    vbox.add_theme_constant_override("margin_left", 18)
    vbox.add_theme_constant_override("margin_right", 18)
    vbox.add_theme_constant_override("margin_top", 18)
    vbox.add_theme_constant_override("margin_bottom", 18)
    prayer_panel.add_child(vbox)
    var title := Label.new()
    title.text = "Namaz kılıyor musun?"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 22)
    vbox.add_child(title)
    var yes := Button.new()
    yes.text = "Evet"
    yes.pressed.connect(_show_prayer_choices)
    vbox.add_child(yes)
    var no := Button.new()
    no.text = "Hayır"
    no.pressed.connect(func():
        GameState.prayer_enabled = false
        GameState.selected_prayers.clear()
        GameState.save_data()
        prayer_panel.queue_free()
        prayer_panel = null
    )
    vbox.add_child(no)

func _show_prayer_choices() -> void:
    for child in prayer_panel.get_child(0).get_children():
        child.queue_free()
    var vbox: VBoxContainer = prayer_panel.get_child(0)
    var title := Label.new()
    title.text = "Hangi vakitleri seçmek istersin?"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    vbox.add_child(title)
    for p in prayer_names:
        var cb := CheckBox.new()
        cb.text = p
        cb.button_pressed = GameState.selected_prayers.has(p)
        cb.toggled.connect(func(on: bool):
            if on and not GameState.selected_prayers.has(p):
                GameState.selected_prayers.append(p)
            elif not on:
                GameState.selected_prayers.erase(p)
        )
        vbox.add_child(cb)
    var save := Button.new()
    save.text = "Kaydet"
    save.pressed.connect(func():
        GameState.prayer_enabled = true
        GameState.save_data()
        prayer_panel.queue_free()
        prayer_panel = null
    )
    vbox.add_child(save)

func _process(delta: float) -> void:
    if reminder_active:
        reminder_seconds -= delta
        if reminder_seconds <= 0:
            reminder_active = false
            if reminder_panel:
                reminder_panel.queue_free()
                reminder_panel = null
    _update_coins()

func _update_coins() -> void:
    if coins_label:
        coins_label.text = "Para: %d" % GameState.coins

func show_reminder_demo() -> void:
    reminder_active = true
    reminder_seconds = 600
    reminder_panel = Panel.new()
    reminder_panel.set_anchors_preset(Control.PRESET_CENTER)
    reminder_panel.position = Vector2(-160, -90)
    reminder_panel.size = Vector2(320, 180)
    add_child(reminder_panel)
    var label := Label.new()
    label.text = "Namaz vakti geldi.\nGit, namazını kıl.\n10:00"
    label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    reminder_panel.add_child(label)
