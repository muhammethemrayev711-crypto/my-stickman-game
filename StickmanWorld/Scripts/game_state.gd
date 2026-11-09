extends Node

var selected_prayers: Array[String] = []
var prayer_enabled := false
var player_name := "Oyuncu"
var coins := 100
var inside_building := false
var current_building := ""
var reminder_minutes := 10
var config := ConfigFile.new()

func _ready() -> void:
    var err = config.load("user://player.cfg")
    if err == OK:
        selected_prayers = config.get_value("prayer", "selected", [])
        prayer_enabled = config.get_value("prayer", "enabled", false)
        player_name = config.get_value("player", "name", "Oyuncu")
        coins = config.get_value("player", "coins", 100)

func save_data() -> void:
    config.set_value("prayer", "selected", selected_prayers)
    config.set_value("prayer", "enabled", prayer_enabled)
    config.set_value("player", "name", player_name)
    config.set_value("player", "coins", coins)
    config.save("user://player.cfg")

func add_coins(amount: int) -> void:
    coins += amount
    save_data()
