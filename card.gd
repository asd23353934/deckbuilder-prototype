class_name Card
extends PanelContainer

# 一張卡的視覺呈現。
# 接收 CardData，把欄位填到 Label 上。
#
# 使用方式（之後 Hand.gd 會這樣呼叫）：
#   var card_scene = preload("res://card.tscn")
#   var card_instance = card_scene.instantiate()
#   card_instance.data = strike_data    # ← setter 自動 _refresh
#   hand_container.add_child(card_instance)

# === Inspector 可編輯欄位 ===

@export var data: CardData:
	set(value):
		data = value
		# is_node_ready 保護：Inspector 設值時 _ready 還沒跑，此時 % 取不到 node
		if is_node_ready():
			_refresh()


# === Lifecycle ===

func _ready() -> void:
	_refresh()


# === Internal ===

func _refresh() -> void:
	if data == null:
		# 沒資料時用預設值顯示（編輯器預覽友善）
		return
	# 防呆：預覽 instance 可能 owner 不對，% 取不到 node
	if get_node_or_null("%NameLabel") == null:
		return
	%NameLabel.text = data.card_name
	%CostLabel.text = str(data.cost)
	# damage 0 的卡（防禦 / power）不顯示 DMG 行
	if data.damage > 0:
		%DamageLabel.text = "DMG: %d" % data.damage
		%DamageLabel.visible = true
	else:
		%DamageLabel.visible = false
	%DescriptionLabel.text = data.description


# ===========================================================
# Drag-and-drop（Godot 內建 UI drag-drop 三大 method）
# ===========================================================
#
# 流程：
#   1. 玩家在 Card 上開始拖（按住滑鼠左鍵移動）
#   2. Godot 自動 call _get_drag_data(mouse_pos)
#   3. 我們檢查能量、回傳 self（讓 Enemy 拿得到原 Card）
#   4. 設一個 drag preview（跟著滑鼠的視覺）
#   5. 玩家拖到 Enemy 上，Enemy._can_drop_data 回 true → 顯示可放
#   6. 放開 → Enemy._drop_data 處理
#   7. 沒放在有效目標（拖到背景）→ drag 取消，drag preview 消失

func _get_drag_data(_at_position: Vector2) -> Variant:
	if data == null:
		return null

	# 能量檢查：不夠的話 return null，drag 不會發生
	if GameState.energy < data.cost:
		print("[Card] 能量不足，無法打 %s（需 %d，剩 %d）" % [data.card_name, data.cost, GameState.energy])
		return null

	# Drag preview：另開一個 Card instance 跟著滑鼠
	# 用 preload + instantiate 而不是 duplicate()，避免 owner / unique_name 衝突
	var preview_scene: PackedScene = preload("res://card.tscn")
	var preview: Card = preview_scene.instantiate()
	preview.data = data
	set_drag_preview(preview)

	# Return self → Enemy._drop_data 收到的就是這個 Card node
	return self
