extends Control

# Main scene：把 Hand + Enemy 組合起來，串 signal 處理結局。
#
# 監聽：
#   - EventBus.energy_changed → 更新 EnergyLabel
#   - Enemy.died → 顯示勝利訊息


func _ready() -> void:
	_refresh_energy()
	EventBus.energy_changed.connect(_on_energy_changed)
	%Enemy.died.connect(_on_enemy_died)


func _refresh_energy() -> void:
	%EnergyLabel.text = "能量：%d / %d" % [GameState.energy, GameState.max_energy]


func _on_energy_changed(_current: int, _max: int) -> void:
	_refresh_energy()


func _on_enemy_died() -> void:
	print("[Main] 玩家勝利！")
	%MessageLabel.text = "VICTORY!"
	%MessageLabel.show()
