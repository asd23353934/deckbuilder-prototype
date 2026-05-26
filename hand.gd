extends HBoxContainer

# 手牌容器。負責 instantiate N 張 Card 進來排版。
#
# Inspector 設定：
#   - card_scene: 拖 card.tscn 進來
#   - cards: 拖 .tres 卡牌資料（Array[CardData]）
#
# 之後玩家抽牌、棄牌邏輯都會透過 add_card_to_hand() / remove_card() 操作。

@export var card_scene: PackedScene
@export var cards: Array[CardData] = []


func _ready() -> void:
	# 加點間距讓卡牌之間有呼吸感
	add_theme_constant_override("separation", 12)
	rebuild_hand(cards)


# === Public API ===

func rebuild_hand(card_list: Array[CardData]) -> void:
	# 1. 清掉現有手牌（rebuild 時用）
	for child in get_children():
		child.queue_free()

	# 2. 重新 instantiate 每張卡
	for card_data in card_list:
		var card_instance = card_scene.instantiate()
		card_instance.data = card_data
		add_child(card_instance)

	print("[Hand] 手牌建立完成，共 %d 張" % card_list.size())


func add_card_to_hand(card_data: CardData) -> void:
	# 之後玩家抽牌時用
	var card_instance = card_scene.instantiate()
	card_instance.data = card_data
	add_child(card_instance)
