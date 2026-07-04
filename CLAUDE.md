# Hosopi-3 EA 開発メモ

## コンパイルについて
- **ClaudeがMetaEditor CLIでコンパイルを実行する**（変更後は必ずコンパイルして 0 errors を確認する）
- このTerminal(53785E…)の本体は **MetaTrader 5 EXNESS**（`origin.txt` 参照）
- MT5コンパイル:
  ```
  & "C:\Program Files\MetaTrader 5 EXNESS\metaeditor64.exe" "/compile:<abs .mq5>" "/log:<abs log>"
  ```
- MT4構文チェック:
  ```
  & "C:\Program Files (x86)\MetaTrader 4 EXNESS\metaeditor.exe" "/compile:<abs .mq4>" "/log:<abs log>"
  ```
- ログは UTF-16。PowerShellで `Get-Content <log> -Encoding Unicode` で読む
- metaeditorの終了コードは成功時でも 1 を返すことがある。**判定はログ末尾の `Result: N errors, M warnings` で行う**

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

## 2026-04-18 連打・ロット暴走・CloseBy取りこぼし対策 v3.3 (ELDRA2 v3.47移植)

### 背景
ELDRA2で発生したXAUUSDc連打事象（15分で296注文、ロット暴走）の根本原因：
**非同期close中にポジション数0を誤検知 → エントリー関数が連続起動 → OrderSend連打**

### 対策概要（3層防御）
1. **決済処理中フラグ（`g_ClosingInProgressUntil`）**: タイムアウト式（3秒自動解除）で永続ブロックを防止
2. **エントリーOrderSend送信前ガード（`BlockEntryOrderIfClosing`）**: 主要エントリー関数全てで割り込みブロック
3. **CloseByペア決済の失敗フォールバック**: 個別決済にフォールバックして取りこぼし防止

### 変更ファイル
- **`Hosopi3_Defines.mqh`**: `IsClosingInProgress()`, `BlockEntryOrderIfClosing()`, `MarkClosingInProgress()` 追加
- **`Hosopi3_Async.mqh`**:
  - `CloseAllPositionsAsync` / `CloseAllWithCloseByAsync` の開始時に `MarkClosingInProgress()` セット
  - `ClosePositionByTicketSync()` 個別決済フォールバック関数を新設
  - CloseByを非同期→同期に変更してretcode即時判定、失敗時は個別決済へフォールバック
  - ペア決済後のセーフティネット（残存チケット個別処理）
- **`Hosopi3_TakeProfit.mqh`**: TSM一括close、CheckMaxLossClose、TP決済、トレール仮想SL、MQL4建値決済 に `MarkClosingInProgress()` 追加
- **`Hosopi3_Manager.mqh`**: `ExecuteRealEntry`, `ExecuteRealNanpin`, `ExecuteDiscretionaryEntry`, `ExecuteEntryFromLevel` に `BlockEntryOrderIfClosing` ガード追加
- **`Hosopi3_Trading.mqh`**: `position_entry` に `BlockEntryOrderIfClosing` ガード追加
- **`Hosopi3_Utils.mqh`**: `ProcessConstantEntry` に `BlockEntryOrderIfClosing` ガード追加
- **`Hosopi3_EA.mq5` / `.mq4`**: バージョン `3.2` → `3.3`

### 除外（該当機能なし）
ELDRA2 v3.47に含まれるがHosopi-3に該当機能がないため未移植：
- Pyramid（ナンピンが相当だが仕様が異なり lot×倍率^level 化は見送り）
- Grid、WickSniper、BO、PositionCache、OrderQueue、Amount TP/SL、残高%損失

## 2026-04-18 CloseBy未コミット期間の重複送信回避 v3.4 (ELDRA2 v3.48移植)

### 背景
v3.3で実装したCloseByセーフティネットは、**CloseBy accepted→約定コミット間の数十ms**に
PositionsTotal()でチケットが残存して見えるため、個別closeを重複送信して
「Order to close this position already exists」エラーを引き起こしていた。

### 対策
- **`Hosopi3_Async.mqh::CloseAllWithCloseByAsync`**: CloseBy送信成功ペアを `closedByTickets[]` に記録
- セーフティネットの残存ポジション走査でCloseBy送信済みチケットをスキップ
- **`Hosopi3_GUI.mqh::btnCloseAll`**: `CloseAllPositionsAsync(false, true)` で同期化（CloseBy未コミット中の重複送信防止）
- バージョン `3.3` → `3.4`

## 2026-07-01 矢印コードエントリー + パラメータ差分HTML v3.5 (ELDRA2移植)

### 1. インジケーターの矢印コード判定を追加（ELDRA2 ELDRA_IndicatorEntry.mqh 相当）
**ファイル**: `Hosopi3_IndicatorEntry.mqh`, `Hosopi3_AllParams_MQL5.mqh`, `Hosopi3_AllParams_MQL4.mqh`

- **矢印コード判定**: オブジェクト名ではなく `OBJPROP_ARROWCODE`（Wingdings番号）でシグナル検出する `CheckArrowCodeSignal()` を新設。
  - 入力: `InpEnableBuySignalArrow` / `InpBuySignalArrowCode`(既定233) / `InpEnableSellSignalArrow` / `InpSellSignalArrowCode`(既定234)、決済用に `InpEnableBuyExitArrow` / `InpBuyExitArrowCode`(234) / `InpEnableSellExitArrow` / `InpSellExitArrowCode`(233)
  - `ShouldBuy/ShouldSell/ShouldExitBuy/ShouldExitSell` に OR 合成で組込み。`HasAnyEnabledCondition()` / `IndicatorEntryHasConfiguration()` にもフラグ追加
- **オブジェクト名マッチングを部分一致化**: `CheckObjectSignal()` を `StringFind()==0`（前方一致）→ `>=0`（含む/部分一致）に変更。`BuySignalPrefix` 等のコメントを「含まれる文字列（部分一致）」に更新
- **`NeedsIndicatorHandle()` 新設**: オブジェクト名／矢印コード判定のみの場合は iCustom ハンドル不要とし、`Initialize()`（ハンドル取得失敗で `INIT_FAILED` になる問題を回避）と `CheckConditions()` のガードに統合。チャートに手貼りしたインジの矢印だけを読む用途を許可

### 2. パラメータ差分HTMLレポート（Δボタン）を追加（ELDRA2 v3.95相当）
**新規**: `ParamReport/Hosopi3_ParamReport.mqh`, `ParamReport/Hosopi3_ParamTable.mqh`(自動生成), `tools/paramgen/gen_paramtable.ps1`
**変更**: `Hosopi3_EA.mq5`/`.mq4`（include追加）, `Hosopi3_GUI.mqh`（`btnParamDiff` ボタン＋`ProcessButtonClick` ハンドラ）

- 初期input(宣言時デフォルト)と現在値の差分を HTML 出力し、`<Common>\Files\Hosopi3\Hosopi3_params.html` に保存してブラウザで開く（変更のみ/全体トグル付き）
- **`gen_paramtable.ps1`**: `Hosopi3_AllParams_MQL5.mqh`(セクション=`sinput group`) と `_MQL4.mqh`(セクション=`*Title`/`_..`/`COMMENT_..` 文字列input)をパースし、各行を `#ifdef __MQL5__`/`__MQL4__` でガードして `Hosopi3_ParamTable.mqh` を生成。**inputを増減したら再実行が必要**
  - 実行: `powershell -ExecutionPolicy Bypass -File tools\paramgen\gen_paramtable.ps1`
- **注意**: `#import "shell32.dll"` を使用（ブラウザ起動）のため、EA設定で「DLLの使用を許可」が必要

### バージョン `3.4` → `3.5`

## 2026-07-01 資金不足ガード v3.6 (ELDRA2 v3.96 移植)

### 概要
証拠金不足時に新規/ナンピンエントリーを **OrderSend 送信前にブロック**する。資金枯渇口座でEAが発注を繰り返しサーバーへ過剰送信するのを防止（口座抹消対策）。

### 新規ファイル
- **`Hosopi3_FundsGuard.mqh`**: 資金不足ガード本体（ELDRA2 `Risk/ELDRA_FundsGuard.mqh` 移植。pending注文削除はHosopi-3が成行注文モデルのため除外）
  - `UpdateFundsGuard()`（毎tick・1秒スロットルでクライアント側評価）, `FundsGuardBlocked()`, `FundsGuardOnNoMoneyError()`, 警告ラベル表示

### 作動条件（すべてクライアント側計算、サーバー負荷なし）
1. 有効証拠金 ≤ 0 / 2. 有効証拠金 < 最小ロット必要証拠金 / 3. 余剰証拠金 < 最小ロット必要証拠金 / 4. 有効証拠金 < `FundsGuardMinEquity`（0=無効） / 5. サーバーが NO_MONEY(10019)/エラー134 → 即時ラッチ（300秒）
- 解除: 余剰証拠金が最小ロット必要証拠金の1.5倍以上に回復（ヒステリシス）

### 入力（`AllParams_MQL5/MQL4.mqh` セクション38）
- `EnableFundsGuard`（既定 true） / `FundsGuardMinEquity`（既定 0.0）

### 統合
- **`Hosopi3_Defines.mqh::BlockEntryOrderIfClosing`**: 先頭で `FundsGuardBlocked()` を判定 → **全エントリー/ナンピン経路を一括ガード**（ゴーストエントリーは対象外）
- **`Hosopi3_Manager.mqh`**: `OnTickManager` 冒頭で `UpdateFundsGuard()`、`DeinitializeEA` で `FundsGuardHideLabel()`
- **`Hosopi3_Trading.mqh::position_entry`**: OrderSend が NO_MONEY(MQL5)/134(MQL4) を返したら `FundsGuardOnNoMoneyError()` でラッチ
- **`Hosopi3_EA.mq5/.mq4`**: include追加＋バージョン `3.5` → `3.6`

### コンパイル
- MT5(EXNESS metaeditor64)・MT4(EXNESS metaeditor) ともに **0 errors, 0 warnings** で確認済み

## 2026-07-01 トレーリングSL拒否時の仮想SLフォールバック（MQL4完成）v3.7 (ELDRA2 v4.05 移植)

### 背景
ELDRA2 v4.05「SL拒否時にトレーリング/建値が仮想SLへ確実フォールバック」の移植確認。
Hosopi-3の **MQL5版 `ModifyStopLossAsync` は既にELDRA相当**を実装済みだった：
- `AsyncTracker_IsPositionBusy` 二重送信ガード
- 同期致命エラー(`IsSLFatalError`: 10016/4756等)→ 仮想SL(TSM成行決済監視)で継続
- 非同期成功→`AsyncTracker_Register`、サーバー側拒否→`ProcessAsyncTradeTransaction`→`AddSLRetry`
- トレーリングは常に `TSM_Activate()` で仮想監視を起動するため、ブローカーSL拒否でも保護される

### 修正（MQL4側の取りこぼしを解消）
- **`Hosopi3_Async.mqh::IsSLFatalError`**: MQL4の `130`(ERR_INVALID_STOPS)/`131` を致命エラーに追加
- **`Hosopi3_Async.mqh::ModifyStopLossAsync` MQL4分岐**: OrderModify失敗時にエラー分類を追加。
  致命(130/131 Invalid stops)は「仮想SLで監視継続」（TSMがフォールバック決済）、それ以外は従来ログ
- バージョン `3.6` → `3.7`

### 除外（該当機能なし）
ELDRA2 v4.05のうち PropFirm遅延SLTP / Chandelierトレール はHosopi-3に該当機能がないため未移植

## 2026-07-01 ELDRA2汎用機能を4件移植 v3.8

ELDRA2(54機能)とHosopi-3(38機能)を突き合わせ、Hosopi-3に無い汎用リスク機能を移植。

### 1. 注文レートガード（ELDRA v3.97/v4.04 移植）
- **新規 `Hosopi3_OrderRateGuard.mqh`**: 連続注文失敗ブレーカー＋レート制限＋自動復帰。連打・ロット暴走(v3.3/v3.4)の最終防衛線
- 入力（セクション39）: `EnableOrderRateGuard`/`OrderFailStopCount`(10)/`OrderFailHardStopTrips`(5)/`OrderFailAutoRecoverMin`(30)/`OrderRateMaxPerMin`(300)/`OrderRateCooldownSec`(60)
- 統合: `OnTickManager`で`OrderRateGuard_Update()`、`BlockEntryOrderIfClosing`で`OrderRateGuard_Blocked()`、`position_entry`(MQL5/MQL4)と`ExecuteRealNanpin`(MQL5直送分)で`RecordResult`/`Record`/`OnServerRateLimit`、deinitでラベル削除

### 2. ナンピンインターバル（ELDRA section14 移植）
- 前回ナンピンから指定時間が経過するまで次のナンピンをスキップ（急変時の高速積み増し抑制）
- 入力（セクション40）: `EnableNanpinInterval`/`NanpinIntervalMinutes`(60)
- グローバル `g_LastNanpinTimeBuy/Sell`(Defines)、`ExecuteRealNanpin`冒頭でインターバル判定・成功時に時刻記録

### 3. 時間決済＋週末クローズ（ELDRA v3.83-3.85/section28 移植）
- **新規 `Hosopi3_TimeClose.mqh`**:
  - 時間決済: サイドの最古建玉が指定分経過したらそのサイドを全決済
  - 週末クローズ: JST土曜の指定時刻に全決済（`GetBrokerGMTOffset()`でbroker時間へDST考慮変換）
- 入力（セクション41）: `EnableTimeClose`/`TimeCloseMinutes`(120)/`EnableWeekendClose`/`WeekendCloseTime`("0545")
- `OnTickManager`で`ProcessTimeClose()`/`ProcessWeekendClose()`

### 4. 残高%損失限度（ELDRA section7 移植）
- 合計含み損（両サイド、スワップ・手数料込み）が 残高×限度% に達したら全決済。既存の金額損切り(`EnableMaxLossClose`)の%版
- 入力（セクション3内）: `EnablePercentLossClose`/`PercentLossLimit`(5.0%)
- **`Hosopi3_TakeProfit.mqh::CheckPercentLossClose()`**、`OnTickManager`(CheckMaxLossClose隣)で呼び出し

### 除外（該当機能なし・設計不一致）
PropFirm / グリッド / ピラミッド / ヒゲとり / モンテカルロ/リトリーバル / OCO/指値追従 / ナンピン救済 / 部分決済(DDR) / 追加ストラテジー(MACD・三尊・SuperTrend等) / ストップレベル自動調整

### バージョン `3.7` → `3.8` / MT5・MT4とも 0 errors, 0 warnings 確認

## 2026-07-04 パラメータHTMLレポートをELDRA2最新版(v4.18-4.23相当)へ全面更新 v3.9

ELDRA2で進化したHTML生成まわり（v3.95→v4.23の全改善）をそのまま移植。

### 移植した機能（ELDRA2コミット順）
- **検索/目次/折りたたみ/バージョン表示**（d9d57cc）: 検索ボックス、セクションジャンプ目次、見出しクリックで折りたたみ、vバッジ
- **.setファイル生成**（677675b/0cb3185）: 「💾 setで保存（全体）」ボタンでUTF-16LE+BOMの.setをダウンロード（MT5パラメータダイアログでそのままロード可）。セクション区切りは `; ==== タイトル ====` コメントで出力
- **HTML上で値を編集して.set保存**（0cb3185）: 値列が編集可能（編集済み=黄ハイライト、↩リセットボタン）
- **enumドロップダウン/bool select/小数整形**（44e8152）: enum型は「番号: 日本語ラベル」のセレクト（158項目）、bool型はtrue/falseセレクト、doubleは末尾ゼロ整形（`Hosopi3_NumStr`）
- **1列表示・中央600px寄せ**（f2e770d/b73798b）: 値列のみの2カラム、`max-width:600px` 中央寄せで目線移動を軽減
- **ホバーツールチップ＋FX初心者向け解説**（a7861e7/2a6d155）: 項目名ホバーで「解説＋変数名＋初期値＋enum選択肢」を表示
- **セット説明メモ `input_set_memo`**（b0cb2b4）: 新input（両AllParams先頭、セクション0）。非空ならレポート上部に📝メモとして大きく表示、.setにも出力

### ファイル
- **`ParamReport/Hosopi3_ParamReport.mqh`**: ELDRA_ParamReport.mqh 最新版ベースで全面書き換え
- **新規 `ParamReport/Hosopi3_ParamHelp.mqh`**: FX初心者向け解説。`Hosopi3_ParamHelp(input名)` ＋ セクション見出し用 `Hosopi3_SectionHelp(ラベル)`（Hosopi-3はMQL5=sinput group/MQL4=Title文字列でセクション名が無いため、ラベル先頭の「番号.」で判定する方式に適応）。ナンピンマーチン/ゴースト等Hosopi-3の機能に合わせて書き起こし。随時追記可
- **`tools/paramgen/gen_paramtable.ps1`**: enum定義プリスキャン（`Hosopi3_Defines.mqh`/`Hosopi3_Enums.mqh`からメンバーの`//コメント`をラベル化）＋ 行に `setVal`/`exportable`/`enumOpts` を追加。**inputを増減したら再実行が必要**（従来どおり）
- **`Hosopi3_Defines.mqh`**: `#define HOSOPI3_VERSION "3.9"` 追加（**バージョンアップ時は .mq5/.mq4 の #property version と両方更新**）
- **`Hosopi3_AllParams_MQL5.mqh` / `_MQL4.mqh`**: 先頭に `input_set_memo` 追加

### 追補: デフォルトset書き出し（ELDRA 8cf1abc 移植）
- **`defSetVal`**（宣言デフォルトのset形式値）を生成器・構造体に追加
- **Δボタン押下時に `<Common>\Files\Hosopi3\Hosopi3_default.set` を自動書き出し**: 全input のデフォルト値をEA自身が実行時計算（enum/colorも正確な整数）するため、外部ツールのテキストパースに起因する誤変換が原理的に起きない。配布用クリーンset生成のベースに使える

### 除外
- ELDRA2 `tools/paramgen/gen_full_default_sets.ps1`（757c67c）/ `gen_default_sets.py`（64081ae）/ `gen_from_default.py`（8cf1abc）はELDRAの戦略セット量産用ワンオフのため未移植（Hosopi-3に戦略セットカタログができたら `gen_from_default.py` 方式＝MT5保存setベースの行置換を推奨）

### バージョン `3.8` → `3.9` / MT5・MT4とも 0 errors, 0 warnings 確認

## 2026-07-04 インジケーターシグナルのゴーストエントリー開始オプション v4.0

### 背景
`ProcessRealEntries`（`Hosopi3_Manager.mqh`）は、バックテスト時・自動売買OFF時のみ
NanpinSkipLevelベースのゴースト→リアル振り分けを行い、**ライブ＋自動売買ONでは
戦略/インジケーターシグナルが1段目から即リアルエントリー**されていた（バックテストと挙動が不一致）。

### 変更
- **新input `EnableIndicatorGhostEntry`**（既定 false、セクション6 ゴースト設定、両AllParams）:
  ONにするとライブ＋自動売買ONでも戦略/インジケーターシグナルの初回エントリーがゴーストから開始
  （NanpinSkipLevelまで仮想→超えたらリアル。バックテストと同じ挙動）
- **`Hosopi3_Manager.mqh::ProcessRealEntries`**: ゴースト分岐条件を
  `IsTesting() || !g_AutoTrading || (EnableIndicatorGhostEntry && EnableGhostEntry)` に変更
  （`EnableGhostEntry=false` 時は従来どおり即リアルにフォールバック）
- **`ParamReport/Hosopi3_ParamHelp.mqh`**: 解説追加 / **ParamTable再生成**（gen_paramtable.ps1）
- 注意: `NanpinSkipLevel = SKIP_NONE` の場合はONにしてもゴーストは発生しない（従来仕様どおり即リアル）

### バージョン `3.9` → `4.0` / MT5・MT4とも 0 errors, 0 warnings 確認
