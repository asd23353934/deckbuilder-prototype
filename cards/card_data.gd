class_name CardData
extends Resource

# 卡牌的基本資料
@export var card_name: String = ""
@export var cost: int = 1
@export var damage: int = 0
@export_multiline var description: String = ""


func describe() -> String:
	return "%s (cost: %d, dmg: %d) — %s" % [card_name, cost, damage, description]