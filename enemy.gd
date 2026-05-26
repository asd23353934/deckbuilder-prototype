extends PanelContainer

# 敵人實體。
#   - 持有 HP 狀態
#   - 提供 take_damage 給外部 call
#   - 視覺隨 HP 變化（HPBar + HPLabel）
#   - HP 歸零 emit died signal

signal died
signal hp_changed(current: int, max_hp: int)


# === Inspector 可編輯 ===

@export var enemy_name: String = "敵人":
	set(value):
		enemy_name = value
		if is_node_ready():
			_refresh()

@export var max_hp: int = 20:
	set(value):
		max_hp = value
		if is_node_ready():
			_refresh()


# === Runtime state ===

var hp: int = 0


# === Lifecycle ===

func _ready() -> void:
	hp = max_hp     # 開場滿血
	_refresh()


# === Public API ===

func take_damage(amount: int) -> void:
	if hp <= 0:
		# 已經死了，傷害無效
		return

	hp = max(0, hp - amount)
	print("[Enemy] %s 受 %d 點傷害，剩 %d HP" % [enemy_name, amount, hp])
	_refresh()
	hp_changed.emit(hp, max_hp)

	if hp == 0:
		print("[Enemy] %s 死亡" % enemy_name)
		died.emit()


func reset() -> void:
	# 重新開始一場戰鬥時呼叫
	hp = max_hp
	_refresh()
	hp_changed.emit(hp, max_hp)


# === Internal ===

func _refresh() -> void:
	if not is_node_ready():
		return
	%NameLabel.text = enemy_name
	%HPBar.max_value = max_hp
	%HPBar.value = hp
	%HPLabel.text = "%d / %d" % [hp, max_hp]


# ===========================================================
# Drag-and-drop 接收端
# ===========================================================
#
# 玩家把 Card 拖到 Enemy 上時的處理：
#   _can_drop_data → 判斷這個 data 是不是 Card → 決定可不可以放
#   _drop_data → 真的放下 → 扣能量 + 受傷 + 卡牌 queue_free

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	# 死了不能再被打
	if hp <= 0:
		return false
	# 只接受 Card 物件
	return data is Card and data.data != null


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	var card: Card = data
	var card_data: CardData = card.data

	# 扣能量（理論上 _get_drag_data 已檢查過，這是雙保險）
	if not GameState.spend_energy(card_data.cost):
		print("[Enemy] 能量檢查失敗，drop 取消")
		return

	# 套用傷害
	take_damage(card_data.damage)

	# 通知 EventBus 卡牌打出（之後 AchievementSystem / AudioManager 可以聽）
	EventBus.card_played.emit(card_data, self)

	# 移除手牌
	card.queue_free()
