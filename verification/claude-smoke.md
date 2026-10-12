# Claude agent 教學 smoke 紀錄（2D 01-movement 副本）

- 執行者：Claude（Opus），教材撰寫 session
- 工作範圍：只在 `.tools/agent-smoke/2d/01-movement/` 操作；正式 `examples/2d/01-movement/` 只讀未改。
- **結論先講：Claude 這個 session 沒有 shell／命令執行工具（只有檔案讀寫、搜尋工具），從頭到尾沒有執行過任何 Godot 命令。** 本紀錄中的 Godot 輸出全部由主代理實際執行後提供，以下用兩種標記區分：
  - 【Claude 檔案操作】Claude 用 Read／Write／Edit 工具做的事。
  - 【主代理執行證據】主代理實際執行命令並貼給 Claude 的原始輸出。

## 1. 複製副本【Claude 檔案操作】

來源：`examples/2d/01-movement/`（不含 `.godot/` 快取）。用 Read → Write 逐檔複製，內容逐字相同：

| 檔案 | 狀態 |
| --- | --- |
| `project.godot`、`main.tscn`、`export_presets.cfg` | 已複製 |
| `scripts/main.gd`、`scripts/item.gd`、`scripts/player.gd` | 已複製（player.gd 之後有功能修改，見第 3 節） |
| `scripts/*.gd.uid`（3 個） | 已複製 |
| `audio/collect.wav.import` | 已複製 |
| `AGENTS.md`、`CLAUDE.md`、`README.md`、`LICENSE`、`.gitignore` | 已複製 |
| `audio/collect.wav` | **未複製**：二進位檔，無法用文字 Write 工具忠實複製 |
| `.godot/` | 依指示不複製 |

**影響**：`scripts/main.gd` 第 40 行 `preload("res://audio/collect.wav")`。缺少 wav 時，副本在匯入／執行時預期會出現資源載入錯誤，`main.gd` 可能因 preload 失敗而無法載入。

**更新（第二輪）**：主代理表示已補上 `audio/collect.wav`，副本現在完整。Claude 沒有驗證這個二進位檔的內容。

## 2. 閱讀 `scripts/player.gd` 的解說

```gdscript
var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
velocity = direction * speed if enabled else Vector2.ZERO
move_and_slide()
```

- **輸入動作從哪來**：`project.godot` 中沒有 `[input]` 區塊；動作是在 `main.gd` 的 `configure_input()` 中於執行時用 `InputMap.add_action` 建立的（WASD＋方向鍵、R）。
- **`Input.get_vector(neg_x, pos_x, neg_y, pos_y)`**：依四個動作的強度組成一個 `Vector2`，X = 右 − 左、Y = 下 − 上（2D 的 Y 向下為正）。結果長度被限制在 1 以內，因此斜向移動不會比直線快；同時按相反方向會抵消為 0。未設定 deadzone 參數時使用各動作的預設 deadzone。
- **`velocity = direction * speed`**：`velocity` 是 `CharacterBody2D` 內建屬性，單位是像素／秒；`enabled` 為 false（勝負結束時由 `main.gd` 設定）時直接歸零。
- **`move_and_slide()`**：依 `velocity` 移動本體，內部已使用物理影格的 delta，所以不需要再乘 `delta`；碰到碰撞體時沿表面滑動並更新 `velocity`。此階段場上沒有牆體，邊界由下一行 `position.clamp(...)` 硬性限制在 `(28,74)`–`(932,572)`。
- 這些寫在 `_physics_process` 中，以固定物理頻率執行。

## 3. 功能修改：speed 260 → 300【Claude 檔案操作】

- 檔案：`.tools/agent-smoke/2d/01-movement/scripts/player.gd` 第 3 行
- 修改前：`@export var speed: float = 260.0`
- 修改後：`@export var speed: float = 300.0`
- 範圍：只改這一行；`main.tscn` 沒有覆寫 `speed`（玩家是在 `main.gd` 中以程式建立的），所以新預設值會直接生效。
- 驗證狀態：**只做了檔案層級確認**（Edit 工具回報成功）；沒有執行 Godot，所以沒有驗證遊戲中的速度。

## 4. 刻意型別錯誤 → 依真實 log 修復（第二輪）

第一輪 Claude 沒有製造錯誤，因為拿不到真實 log。第二輪改由主代理分工：

### 4.1 主代理引入錯誤【主代理執行證據】

主代理在 speed = 300 的副本中刻意引入一個 bool 型別錯誤，然後實際執行：

```bash
Godot_v4.7.2-stable_linux.x86_64 --headless --path <副本> --check-only --script scripts/player.gd
```

主代理提供的原始輸出（逐字）：

```text
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

SCRIPT ERROR: Parse Error: Cannot assign a value of type "String" as "bool".
          at: GDScript::reload (res://scripts/player.gd:4)
SCRIPT ERROR: Parse Error: Cannot assign a value of type String to variable "enabled" with specified type bool.
          at: GDScript::reload (res://scripts/player.gd:4)
ERROR: Failed to load script "res://scripts/player.gd" with error "Parse error".
   at: load (modules/gdscript/gdscript_resource_format.cpp:46)
```

（主代理沒有提供 exit code，本紀錄不推測它的值。）

### 4.2 依 log 定位與修復【Claude 檔案操作】

1. log 指向 `res://scripts/player.gd:4`，變數是 `enabled`，宣告型別 `bool`，卻被指定為 `String`。
2. Claude 讀取副本，第 4 行實際內容是：`var enabled: bool = "broken"`。和 log 一致。
3. 決定修正值為 `true`，理由：
   - 正式範例 `examples/2d/01-movement/scripts/player.gd` 的原值是 `true`；
   - `main.gd` 只在勝負結束時設 `player.enabled = false`；玩家必須預設可移動，第 10 行 `velocity = direction * speed if enabled else Vector2.ZERO` 才會讓角色動起來。
4. 用 Edit 工具只改第 4 行：
   - 修改前：`var enabled: bool = "broken"`
   - 修改後：`var enabled: bool = true`
5. 第 3 行 `@export var speed: float = 300.0` 保留不動；其他行沒有變更。

修復後的檔案和正式範例相比，只差 speed 260 → 300 這一行（Claude 以讀檔比對，未用 diff 工具）。

### 4.3 尚待主代理驗證

Claude 無法確認修復後能否通過解析。請主代理依序執行並把輸出補到第 6 節：

1. `--check-only --script scripts/player.gd`：預期沒有 `SCRIPT ERROR`。
2. `--import`：預期沒有載入錯誤（含 `collect.wav`）。
3. `--quit-after 10`：預期沒有 `SCRIPT ERROR`／`ERROR:` 行。這只能證明能載入、能執行，**不能**證明速度 300 的手感或畫面正確。

### 4.4 第一輪留下的參考命令

第一輪寫給有 shell 的執行者的參考步驟（其中「刪除冒號」的錯誤設計最後沒有使用，主代理改用 bool 型別錯誤）：

```bash
G=.tools/godot/Godot_v4.7.2-stable_linux.x86_64
P=.tools/agent-smoke/2d/01-movement
L=.tools/agent-smoke/logs
mkdir -p "$L"

# 0) 補上 wav，然後做乾淨的匯入作為基準
cp examples/2d/01-movement/audio/collect.wav "$P/audio/"
"$G" --headless --path "$P" --import --log-file "$L/00-import-clean.log"

# 1) 先備份，再刻意製造錯誤：刪掉 _physics_process 那行結尾的冒號
cp "$P/scripts/player.gd" "$L/player.gd.bak"
sed -i 's/^func _physics_process(delta: float) -> void:$/func _physics_process(delta: float) -> void/' "$P/scripts/player.gd"

# 2) 產生真實錯誤 log（兩種方式擇一或都跑）
"$G" --headless --path "$P" --check-only --script res://scripts/player.gd > "$L/01-check-broken.log" 2>&1; echo "exit=$?" >> "$L/01-check-broken.log"
"$G" --headless --path "$P" --import --log-file "$L/02-import-broken.log"

# 3) 依 log 指出的行號修回（或還原備份），再檢查一次
cp "$L/player.gd.bak" "$P/scripts/player.gd"
"$G" --headless --path "$P" --check-only --script res://scripts/player.gd > "$L/03-check-fixed.log" 2>&1; echo "exit=$?" >> "$L/03-check-fixed.log"

# 4) 最後的執行檢查
"$G" --headless --path "$P" --quit-after 10 --log-file "$L/04-run.log"
grep -n "speed" "$P/scripts/player.gd"
```

判讀方式（實際執行後再補上真實結果，不要沿用這裡的預期）：

- `01`／`02` 應該指出 `res://scripts/player.gd` 第 7 行附近的 parse error；`01` 的 exit code 預期不是 0。
- `03` 應該沒有 parse error。
- `04` 應該沒有 `SCRIPT ERROR` 或 `ERROR:` 行。headless 跑 10 個迭代只能證明能載入、能執行，**不能**證明速度或畫面正確。
- `grep` 應該顯示 `speed: float = 300.0`。

## 5. 狀態總表

| 步驟 | 誰做的 | 狀態 |
| --- | --- | --- |
| 複製副本（排除 `.godot/`） | Claude | 完成 |
| 補上 `audio/collect.wav` | 主代理 | 主代理表示已完成 |
| 閱讀並解說 `Input.get_vector`、`move_and_slide` | Claude | 完成（第 2 節） |
| speed 260 → 300 | Claude | 完成（檔案層級） |
| 引入 bool 型別錯誤並執行 `--check-only` | 主代理 | 已執行，原始輸出見 4.1 |
| 依 log 修復第 4 行為 `true` | Claude | 完成（檔案層級） |
| 修復後的 `--check-only`／`--import`／`--quit-after 10` | 主代理 | **待執行** |
| 正式 `examples/` 被修改 | — | 否（Claude 只讀） |

## 6. 修復後驗證結果【主代理執行證據】

（待主代理執行後填入原始輸出。Claude 不會自行填寫或推測這一節。）


## 最終驗證（主代理實際執行）

- `check`: exit 0; no SCRIPT ERROR / ERROR lines.
- `import`: exit 0; no SCRIPT ERROR / ERROR lines.
- `run`: exit 0; no SCRIPT ERROR / ERROR lines.

Claude 根據主代理提供的真實錯誤紀錄完成修復；主代理執行以上三個命令驗證修復結果。speed仍為300。命令紀錄保存在claude-relay-check.log、claude-relay-import.log、claude-relay-run.log。未聲稱Claude子session具有shell工具，也未驗證速度300的視覺手感。
