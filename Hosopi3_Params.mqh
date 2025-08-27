//+------------------------------------------------------------------+
//|                     Hosopi 3 - パラメータ定義ファイル              |
//|                              Copyright 2025                      |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025"
#property link      ""
#property strict

//+------------------------------------------------------------------+
//|                          入力パラメータ定義                       |
//+------------------------------------------------------------------+

// ======== ナンピンマーチン基本設定 ========
sinput string Comment_Martingale = ""; //+--- ナンピンマーチン基本設定 ---+
input NANPIN_SKIP NanpinSkipLevel = SKIP_5;  // ナンピンスキップレベル
input int NanpinSpread = 2000;               // ナンピン幅（Point）
input bool UseInitialLotForRealEntry = false; // リアルエントリーは初期ロットを使う
input double InitialLot = 0.01;              // 初期LOT
input MAX_POSITIONS MaxPositions = POS_15;   // 最大ポジション数量
input double LotMultiplier = 1.8;            // LOT倍率（小数第三位で繰り上げ）

// ======== ナンピンインターバル設定 ========
sinput string Comment_Interval = ""; //+--- ナンピンインターバル設定 ---+
input int NanpinInterval = 0;                // ナンピンインターバル(Minutes)

// ======== 決済後インターバル設定 ========
sinput string Comment_CloseInterval = ""; //+--- 決済後インターバル設定 ---+
input bool EnableCloseInterval = false;      // 決済後インターバル機能を有効化
input int CloseInterval = 30;                // 決済後インターバル（Minutes）

// ======== 有効証拠金関連の設定 ========
sinput string Comment_Equity_Control = ""; //+--- 有効証拠金の設定 ---+
input ON_OFF EquityControl_Active = ON_MODE; // 有効証拠金チェックを有効にする(ON/OFF)
input double MinimumEquity = 10000;          // 最低有効証拠金（この金額未満でエントリー停止）

// ======== ポジション保護設定 ========
sinput string Comment_Protection = ""; //+--- 両建て設定 ---+
input POSITION_PROTECTION_MODE PositionProtection = PROTECTION_OFF; // 両建て設定モード

// ======== 平均取得単価計算設定 ========
sinput string Comment_AvgPriceCalc = ""; //+--- 平均取得単価計算設定 ---+
input AVG_PRICE_CALCULATION_MODE AvgPriceCalculationMode = REAL_AND_GHOST; // 平均取得単価計算方法

// ======== 決済利確条件設定 ========
sinput string Comment_RIGUITP_Conditions = ""; //+--- 利確条件設定 ---+
input TP_MODE TakeProfitMode = TP_OFF;       // 利確方式
input int TakeProfitPoints = 2000;            // 利確幅（Point）
input bool EnableTrailingStop = false;        // トレールストップを有効化
input int TrailingTrigger = 1000;             // トレールトリガー（Point）
input int TrailingOffset = 500;               // トレールオフセット（Point）

// ======== 建値決済機能設定 ========
sinput string Comment_BreakEven = ""; //+--- 建値決済機能設定 ---+
input bool EnableBreakEvenByPositions = false;   // ○ポジション以上なら建値で決済機能(ON/OFF)
input double BreakEvenProfit = 0.0;              // 建値価格（最低利益額）
input int BreakEvenMinPositions = 3;             // 最低ポジション数

// ======== 損失額決済機能設定 ========
sinput string Comment_MaxLoss = ""; //+--- 損失額決済機能設定 ---+
input bool EnableMaxLossClose = false;           // 損失額決済機能を有効化(ON/OFF)
input double MaxLossAmount = 10000.0;            // 最大損失額（この金額以上の損失で全決済）

// ======== 基本設定 ========
sinput string Comment_Basic = ""; //+--- 基本設定 ---+
input int MagicNumber = 99899;                // マジックナンバー
input string PanelTitle = "Hosopi 3 EA";      // パネルタイトル
input int PanelX = 20;                        // パネルX座標
input int PanelY = 50;                        // パネルY座標
input ENTRY_MODE EntryMode = MODE_BOTH;       // エントリー方向

// ======== スプレッド設定 ========
sinput string Comment_Spread = ""; //+--- スプレッド設定 ---+
input int MaxSpreadPoints = 2000;             // 最大スプレッド（Point）
input int Slippage = 100;                     // スリッページ（Point）

// ======== 機能制御設定 ========
sinput string Comment_Features = ""; //+--- 機能制御設定 ---+
input bool EnableNanpin = true;               // ナンピン機能を有効化
input bool EnableGhostEntry = true;           // ゴーストエントリー機能を有効化
input bool EnableAutomaticTrading = true;     // 自動売買を有効化
input bool EnablePositionTable = true;        // ポジションテーブル表示を有効化
input bool EnablePriceLabels = true;          // 価格ラベル表示を有効化

// ======== 時間設定 ========
sinput string Comment_Time = ""; //+--- 時間設定 ---+
input USE_TIMES set_time = GMT9;              // 時間取得方法
input int natu = 6;                           // 夏加算時間（バックテスト用）
input int huyu = 7;                           // 冬加算時間（バックテスト用）

// ======== 表示設定 ========
sinput string Comment_Display = ""; //+--- 表示設定 ---+
input ON_OFF GhostInfoDisplay = ON_MODE;      // Ghost情報表示(ON/OFF)
input ON_OFF PositionSignDisplay = ON_MODE;   // ポジションサイン表示(ON/OFF)
input ON_OFF AveragePriceLine = ON_MODE;      // 平均取得価格ライン表示(ON/OFF)
input color AveragePriceLineColor = clrPaleTurquoise; // 平均取得価格ライン色
input color TakeProfitLineColor = clrYellow;  // 利確ラインの色

// ======== ポジションテーブル設定 ========
input string TableSettingsTitle = ""; //+--- ポジションテーブル設定 ---+
input string GhostTableTitle = "Ghost Position Table"; // ゴーストテーブルタイトル
input int GhostTableX = 20;                   // ゴーストテーブルX座標
input int GhostTableY = 400;                  // ゴーストテーブルY座標
input int UpdateInterval = 1;                 // テーブル更新間隔（秒）

// ======== ゴーストエントリー設定 ========
input color GhostBuyColor = clrDeepSkyBlue;   // ゴーストBuyエントリー色
input color GhostSellColor = clrCrimson;      // ゴーストSellエントリー色
input int GhostArrowSize = 3;                 // ゴースト矢印サイズ

// ======== テクニカルフィルター設定 ========
sinput string Comment_Filter = ""; //+--- テクニカルフィルター設定 ---+
input FILTER_TYPE FilterType = FILTER_NONE;   // フィルタータイプ
input ENUM_TIMEFRAMES FilterTimeframe = PERIOD_CURRENT; // フィルター時間足
input int FilterPeriod = 14;                  // 期間
input ENUM_MA_METHOD FilterMethod = MODE_SMA; // 平均化方法
input int FilterShift = 0;                    // シフト（何足前と比較するか）

// Buy用フィルター設定
input BAND_TARGET BuyBandTarget = TARGET_LOWER;      // Buyバンド対象
input BAND_CONDITION BuyBandCondition = PRICE_ABOVE; // Buyバンド条件

// Sell用フィルター設定
input BAND_TARGET SellBandTarget = TARGET_UPPER;     // Sellバンド対象
input BAND_CONDITION SellBandCondition = PRICE_BELOW; // Sellバンド条件

// エンベロープ専用設定
input double EnvelopeDeviation = 0.1;         // エンベロープ偏差(%)

// ボリンジャーバンド専用設定
input double BollingerDeviation = 2.0;        // ボリンジャーバンド偏差（標準偏差倍率）
input ENUM_APPLIED_PRICE BollingerAppliedPrice = PRICE_CLOSE; // ボリンジャー適用価格

// 共通設定
input int FinalStopLossPoints = 10000;        // 最終損切り幅（Point）

// ======== ゴースト通知設定 ========
sinput string Comment_GhostNotification = ""; //+--- ゴースト通知設定 ---+
input bool EnableGhostAlertNotification = false;  // ゴーストアラート通知を有効にする
input bool EnableGhostPushNotification = false;   // ゴーストプッシュ通知を有効にする
input bool NotifyGhostEntries = true;             // ゴーストエントリー通知
input bool NotifyGhostClosures = true;            // ゴースト決済通知

// ======== レイアウト設定 ========
sinput string Comment_Layout = ""; //+--- レイアウト設定 ---+
input LAYOUT_PATTERN LayoutPattern = LAYOUT_DEFAULT; // レイアウトパターン
input int CustomPanelX = 20;                  // カスタム: パネルX座標
input int CustomPanelY = 50;                  // カスタム: パネルY座標
input int CustomTableX = 20;                  // カスタム: テーブルX座標
input int CustomTableY = 400;                 // カスタム: テーブルY座標