class_name UtilityCrawlerInteractable
extends InteractableBase

## Interaction Proxy for Municipal Utility Crawler
## Participates in player target arbitration, tactical scrap interception, and harvest state tracking

@onready var crawler: Node = get_parent()
var _current_player: CharacterBody3D = null

func _ready() -> void:
	interaction_priority = 1.9
	interaction_radius = 2.5
	sensory_radius = 5.0
	is_powered = true

func set_player_reference(player: CharacterBody3D) -> void:
	_current_player = player

func get_action_verb() -> String:
	if not crawler:
		return "INTERCEPT"
	if "is_rammed" in crawler and crawler.is_rammed:
		return "WRECKED"
	if "is_harvested" in crawler and crawler.is_harvested:
		return "HARVESTED"
	if "current_durability" in crawler and crawler.current_durability <= 0:
		return "DISABLED"
	return "INTERCEPT"

func can_interact(_player_pos: Vector3) -> bool:
	if not crawler:
		return false
	if "is_rammed" in crawler and crawler.is_rammed:
		return false
	if "is_harvested" in crawler and crawler.is_harvested:
		return false
	if "current_durability" in crawler and crawler.current_durability <= 0:
		return false
	return is_player_in_range and is_powered

func begin_interaction(_player_pos: Vector3) -> bool:
	if not can_interact(_player_pos):
		return false
	if crawler.has_method("intercept_crawler"):
		var res: int = crawler.intercept_crawler()
		interaction_completed.emit()
		return res > 0
	return false

func get_interaction_priority() -> float:
	return interaction_priority
