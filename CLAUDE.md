# Hosopi-3 EA 開発メモ

## コンパイルについて
- コンパイルはユーザーが手動で行う
- ClaudeはMetaEditorでのコンパイルを実行しない

## 2025-12-21 時間指定システム修正

### 修正1: 時間フィルターのロジック修正
**ファイル**: `Hosopi3_Utils.mqh`
- `IsInitialEntryTimeAllowed()`: `DayTimeControl_Active = OFF_MODE`時は時間フィルター無効化、`ON_MODE`時は共通時間設定をチェック

**ファイル**: `Hosopi3_StrategyTime.mqh`
- `IsTimeAllowed()`: 火曜日～土曜日（case 2-6）の処理を追加

### 修正2: ブローカー別タイムゾーン自動検出システム移植
Gotobi_Ultimate_EAより移植

**新規ファイル**:
- `Hosopi3_BrokerTimeZone.mqh` - ブローカー別タイムゾーン自動検出システム

**変更ファイル**:
- `Hosopi3_Defines.mqh`: `USE_TIMES`に`GMT_AUTO`追加
- `Hosopi3_Utils.mqh`: `calculate_time()`新システム対応、`InitializeTimeSystem()`追加
- `Hosopi3_Manager.mqh`: `InitializeEA()`に`InitializeTimeSystem()`呼び出し追加
- `Hosopi3_AllParams*.mqh`, `Hosopi3_Params.mqh`: `set_time`デフォルト値を`GMT_AUTO`に変更

### 使い方
**時間フィルターを使う場合**:
1. `DayTimeControl_Active = ON`に設定
2. `buy_StartHour`, `buy_EndHour`等を設定

**時間取得方法**:
- `GMT_AUTO`（推奨）: ブローカー名から自動でタイムゾーン検出
- `GMT9`: PC時間（TimeGMT）使用
- `GMT9_BACKTEST`: 手動オフセット設定（natu/huyu）
- `GMT_KOTEI`: GMT+0固定
