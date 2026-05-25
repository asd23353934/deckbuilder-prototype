extends Node

# Manual test harness for GameState autoload.
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
	print(" GameState test suite (manual harness, no framework)")
	print(line)

	var test_names := [
		"test_take_damage_normal",
		"test_take_damage_clamps_at_zero",
		"test_take_damage_emits_player_died_signal",
		"test_take_damage_emits_damage_dealt_signal",
		"test_heal_normal",
		"test_heal_clamps_at_max_hp",
		"test_spend_energy_sufficient",
		"test_spend_energy_insufficient",
		"test_reset_increments_run_count_once",
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
