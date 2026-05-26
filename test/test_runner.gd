extends Node

# Loaded scenes for entity tests
const ENEMY_SCENE = preload("res://enemy.tscn")

# Manual test harness for GameState autoload (+ Enemy scene entity).
#
# Why no framework:
#   GdUnit4 v6.0.0 (latest on AssetLib as of 2026-05-26) fails to compile
#   against Godot 4.6.3 — its officially supported range only goes up to
#   4.6.2. Rather than block on framework version mismatch, we write tests
#   in plain GDScript with the same PASS/FAIL discipline.
#
# Usage:
#   Open test/test_runner.tscn → F6 to run.
#   Output panel shows ✓/✗ per test + summary.
#
# Adding a new test:
#   1. Write a func test_xxx() -> String that returns _expect(...) or _expect_true(...)
#   2. Add the function name to the test_names array in _ready()
#   3. F6 to verify

# ---------- Captured state for current test ----------

var _signal_log: Array[String] = []
var _connected := false


# ============================================================
# Test cases
# ============================================================

func test_take_damage_normal() -> String:
	_setup()
	GameState.take_damage(30)
	return _expect(GameState.player_hp, 50, "HP after take_damage(30) from full 80")


func test_take_damage_clamps_at_zero() -> String:
	_setup()
	GameState.take_damage(200)
	return _expect(GameState.player_hp, 0, "HP must clamp at 0 when damage exceeds current HP")


func test_take_damage_emits_player_died_signal() -> String:
	_setup()
	GameState.take_damage(200)
	return _expect_true("player_died" in _signal_log, "player_died signal must emit at 0 HP")


func test_take_damage_emits_damage_dealt_signal() -> String:
	_setup()
	GameState.take_damage(15)
	return _expect_true("damage_dealt" in _signal_log, "damage_dealt signal must emit on damage")


func test_heal_normal() -> String:
	_setup()
	GameState.take_damage(30)  # HP -> 50
	GameState.heal(15)           # HP -> 65
	return _expect(GameState.player_hp, 65, "HP after heal(15) from 50")


func test_heal_clamps_at_max_hp() -> String:
	_setup()
	GameState.take_damage(10)  # HP -> 70
	GameState.heal(50)           # 想加 50，但 max 是 80
	return _expect(GameState.player_hp, 80, "HP must clamp at max_hp (80)")


func test_spend_energy_sufficient() -> String:
	_setup()
	var ok = GameState.spend_energy(2)
	if not ok:
		return "FAIL: spend_energy(2) returned false (should be true with 3 energy)"
	return _expect(GameState.energy, 1, "Energy after spending 2 of 3")


func test_spend_energy_insufficient() -> String:
	_setup()
	var ok = GameState.spend_energy(5)
	if ok:
		return "FAIL: spend_energy(5) returned true (should be false with 3 energy)"
	return _expect(GameState.energy, 3, "Energy unchanged when spend fails")


func test_reset_increments_run_count_once() -> String:
	# Regression test for dup-body bug spotted in self-audit (commit 848f6cf).
	# Before fix: run_count incremented by 2 per call. This test ensures it stays at +1.
	_setup()
	var before = GameState.run_count
	GameState.reset_for_new_run()
	return _expect(GameState.run_count, before + 1, "reset_for_new_run must increment run_count by exactly 1 (regression for 848f6cf)")


# ============================================================
# Setup / teardown
# ============================================================

func _setup() -> void:
	_connect_signals()
	GameState.reset_for_new_run()  # 重置 state（會 emit signal）
	_signal_log.clear()              # 然後清 log，只 capture test action 觸發的 signal


func _connect_signals() -> void:
	if _connected:
		return
	EventBus.damage_dealt.connect(func(_a, _t): _signal_log.append("damage_dealt"))
	EventBus.healing_applied.connect(func(_a, _t): _signal_log.append("healing_applied"))
	EventBus.player_hp_changed.connect(func(_c, _m): _signal_log.append("player_hp_changed"))
	EventBus.energy_changed.connect(func(_c, _m): _signal_log.append("energy_changed"))
	EventBus.player_died.connect(func(): _signal_log.append("player_died"))
	EventBus.run_started.connect(func(_n): _signal_log.append("run_started"))
	_connected = true


# ============================================================
# Enemy test cases
# ============================================================
#
# Enemy 比 GameState 複雜，因為它是 scene 不是 autoload：
#   - 必須 instantiate(）拿到 Node tree
#   - 必須 add_child() 才會 _ready，UI children 才能用
#   - 每個 test 後 queue_free 清掉
#
# Helper _create_test_enemy() 統一處理建構流程。

# 用 Array 記住 enemy 的 died signal 觸發狀態（per-test reset）
var _enemy_died_count := 0


func _on_enemy_died_signal() -> void:
	_enemy_died_count += 1


func _create_test_enemy(max_hp: int = 20) -> Node:
	var enemy = ENEMY_SCENE.instantiate()
	enemy.max_hp = max_hp     # setter 在 add_child 前跑 → is_node_ready 為 false → 不 _refresh
	add_child(enemy)            # _ready 跑 → hp = max_hp → _refresh
	_enemy_died_count = 0       # 每個 test reset 計數
	enemy.died.connect(_on_enemy_died_signal)
	return enemy


func test_enemy_take_damage_normal() -> String:
	var enemy = _create_test_enemy(20)
	enemy.take_damage(5)
	var result = _expect(enemy.hp, 15, "Enemy HP after take_damage(5) from 20")
	enemy.queue_free()
	return result


func test_enemy_take_damage_clamps_at_zero() -> String:
	var enemy = _create_test_enemy(10)
	enemy.take_damage(50)   # 過殺
	var result = _expect(enemy.hp, 0, "Enemy HP should clamp at 0, not negative")
	enemy.queue_free()
	return result


func test_enemy_take_damage_emits_died_signal() -> String:
	var enemy = _create_test_enemy(10)
	enemy.take_damage(50)
	var result = _expect_true(_enemy_died_count == 1, "died signal must emit exactly once when HP reaches 0")
	enemy.queue_free()
	return result


func test_enemy_dead_ignores_further_damage() -> String:
	# Regression guard：死了之後不能再收傷害，避免重複 emit died
	var enemy = _create_test_enemy(5)
	enemy.take_damage(10)   # die
	enemy.take_damage(10)   # 應該被 if hp <= 0: return 擋掉
	var hp_ok = enemy.hp == 0
	var emit_ok = _enemy_died_count == 1   # 不能變 2
	var result = _expect_true(hp_ok and emit_ok, "Dead enemy should not take more damage nor re-emit died")
	enemy.queue_free()
	return result


# ============================================================
# Assertion helpers
# ============================================================

func _expect(actual, expected, description: String) -> String:
	if actual == expected:
		return "PASS: " + description
	return "FAIL: %s | expected %s, got %s" % [description, expected, actual]


func _expect_true(condition: bool, description: String) -> String:
	if condition:
		return "PASS: " + description
	return "FAIL: " + description


# ============================================================
# Runner
# ============================================================

func _ready() -> void:
	var line := "=".repeat(60)
	print(line)
	print(" GameState + Enemy test suite (manual harness, no framework)")
	print(line)

	var test_names := [
		# GameState autoload tests (9)
		"test_take_damage_normal",
		"test_take_damage_clamps_at_zero",
		"test_take_damage_emits_player_died_signal",
		"test_take_damage_emits_damage_dealt_signal",
		"test_heal_normal",
		"test_heal_clamps_at_max_hp",
		"test_spend_energy_sufficient",
		"test_spend_energy_insufficient",
		"test_reset_increments_run_count_once",
		# Enemy scene tests (4)
		"test_enemy_take_damage_normal",
		"test_enemy_take_damage_clamps_at_zero",
		"test_enemy_take_damage_emits_died_signal",
		"test_enemy_dead_ignores_further_damage",
	]

	var passed := 0
	var failed := 0
	var failures: Array[String] = []

	for test_name in test_names:
		var result: String = call(test_name)
		if result.begins_with("PASS"):
			passed += 1
			print("  ✓ ", test_name)
		else:
			failed += 1
			failures.append("%s — %s" % [test_name, result.trim_prefix("FAIL: ")])
			print("  ✗ ", test_name)

	print(line)
	print(" Result: %d passed, %d failed (total %d)" % [passed, failed, passed + failed])
	print(line)

	if failed > 0:
		print("\nFailed details:")
		for f in failures:
			print("  • " + f)
