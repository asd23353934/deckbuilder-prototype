# Deckbuilder Prototype

> **🚧 Work In Progress** — 6 個月「前端轉 Godot」學習計畫的 W4。
> 整合 W1（GDScript 基礎）+ W2（場景 / 物理）+ W3（Resource / Autoload）所有觀念，做最小可玩卡牌戰鬥 prototype。

## 目標

```
玩家有 5 張手牌（不同 cost 跟 damage）
  ↓
拖卡到敵人 → 敵人扣 HP
  ↓
HP 歸零 → Game Over
```

**不求美觀，求機制能動**。後續才會接到 [DiceFateSurvivor](https://github.com/asd23353934/dice-fate-survivor) 主專案。

## 學習路徑紀錄

[godot-learning-path](https://github.com/asd23353934/godot-learning-path)
（PROGRESS.md / 面試 prep / 設計筆記）

## 目前進度

| 階段 | 狀態 |
|---|---|
| 1. 基礎建設（autoload + CardData + 5 卡 .tres） | ✅ 完成 |
| 2. Card.tscn 視覺場景 | 🚧 進行中 |
| 3. Hand.tscn 手牌容器 | ⏳ 待做 |
| 4. Enemy.tscn 敵人 + HP bar | ⏳ 待做 |
| 5. Drag-and-drop 拖拉系統 | ⏳ 待做 |
| 6. Main scene 整合 | ⏳ 待做 |
| 7. Tests + 收尾 | ⏳ 待做 |

## 已建立的結構（W3 pattern 複用）

```
deckbuilder-prototype/
├── autoload/
│   ├── event_bus.gd       # 全域 signal hub（11 個 signal）
│   └── game_state.gd      # 玩家狀態 + take_damage / heal / spend_energy API
├── cards/
│   ├── card_data.gd       # CardData class (extends Resource)
│   ├── strike.tres        # STRIKE cost 1 / dmg 6
│   ├── defend.tres        # DEFEND cost 1 / dmg 0
│   ├── focus.tres         # FOCUS  cost 2 / dmg 0
│   ├── heavy.tres         # HEAVY  cost 2 / dmg 10
│   └── quick.tres         # QUICK  cost 0 / dmg 3
└── test/
    └── test_runner.gd     # GameState 9 個單元測試（自製 harness）
```

## 5 張啟動卡

| 卡名 | Cost | Damage | 設計用意 |
|---|---|---|---|
| STRIKE | 1 | 6 | 標準攻擊（CP 值基準） |
| HEAVY | 2 | 10 | 高 cost 高傷害 |
| QUICK | 0 | 3 | 0 費填縫 |
| DEFEND | 1 | 0 | 防禦卡（待擴充 shield 機制） |
| FOCUS | 2 | 0 | Power 卡（待擴充 buff 機制） |

## Tech Stack

- **Engine**: Godot 4.6.3 (Standard)
- **語言**: GDScript
- **無 plugin dependency**（測試 harness 自寫，避開 GdUnit4 v6.0 vs 4.6.3 API drift）

## 執行方式（W4 完成後）

1. clone repo
2. Godot Project Manager → 匯入 → 選此資料夾的 `project.godot`
3. F5 跑 Main scene

## License

MIT
