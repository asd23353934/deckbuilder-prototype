extends Node

# === 玩家狀態（會隨 run 變動）===
var player_hp: int = 80
var max_hp: int = 80
var energy: int = 3
var max_energy: int = 3
var gold: int = 0

# === Run 狀態 ===
var current_floor: int = 1
var run_count: int = 0


func _ready() -> void:
	print("[GameState] autoload ready，HP=%d/%d energy=%d/%d" % [player_hp, max_hp, energy, max_energy])


# === Public API ===

func take_damage(amount: int) -> void:
	player_hp = max(0, player_hp - amount)
	print("[GameState] 玩家受 %d 點傷害，剩 %d HP" % [amount, player_hp])

	# 通知全世界
	EventBus.damage_dealt.emit(amount, "Player")
	EventBus.player_hp_changed.emit(player_hp, max_hp)

	if player_hp == 0:
		print("[GameState] 玩家死亡")
		EventBus.player_died.emit()


func heal(amount: int) -> void:
	player_hp = min(max_hp, player_hp + amount)
	print("[GameState] 玩家回 %d 點，現 %d HP" % [amount, player_hp])

	EventBus.healing_applied.emit(amount, "Player")
	EventBus.player_hp_changed.emit(player_hp, max_hp)


func spend_energy(amount: int) -> bool:
	if energy < amount:
		print("[GameState] 能量不足（需 %d，剩 %d）" % [amount, energy])
		return false
	energy -= amount
	EventBus.energy_changed.emit(energy, max_energy)
	return true


func reset_for_new_run() -> void:
	player_hp = max_hp
	energy = max_energy
	gold = 0
	current_floor = 1
	run_count += 1
	print("[GameState] 開新 run #%d，狀態重置" % run_count)

	EventBus.run_started.emit(run_count)
	EventBus.player_hp_changed.emit(player_hp, max_hp)
	EventBus.energy_changed.emit(energy, max_energy)