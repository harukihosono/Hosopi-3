//+------------------------------------------------------------------+
//|                  Hosopi 3 - 全パラメータ定義（MQL5版）           |
//|                              Copyright 2025                      |
//|               MQL5のグループ機能を使用した整理版                   |
//+------------------------------------------------------------------+

// 必要なenum定義をインクルード
#ifndef HOSOPI3_DEFINES_MQH
   #include "Hosopi3_Defines.mqh"
#endif
#ifndef HOSOPI3_ENUMS_MQH
   #include "Hosopi3_Enums.mqh"
#endif

//==================================================================
//                        基本設定
//==================================================================
sinput group "== 1. 基本設定 =="
input string BasicSettingsTitle = "1. 基本的なEA動作設定"; // 基本設定
input int MagicNumber = 99899;                      // マジックナンバー
input string EAComment = "Hosopi3";                 // コメント
input ENTRY_MODE EntryMode = MODE_BOTH;             // エントリー方向制御
input bool EnableAutomaticTrading = true;          // 自動売買を有効化
input int MaxSpreadPoints = 2000;                  // 最大スプレッド（Point）
input int Slippage = 100;                          // スリッページ許容値（Point）

//==================================================================
//                    ナンピンマーチン設定
//==================================================================
sinput group "== 2. ナンピン・マーチン設定 =="
input string NanpinSettingsTitle = "2. ナンピンマーチンゲール設定"; // ナンピン設定
input double InitialLot = 0.01;                    // 初期ロットサイズ
input MAX_POSITIONS MaxPositions = POS_15;         // 最大ポジション数
input double LotMultiplier = 1.8;                  // ロット倍率
input int NanpinSpread = 2000;                     // ナンピン間隔（Point）
input NANPIN_SKIP NanpinSkipLevel = SKIP_5;        // ナンピンスキップレベル
input bool UseInitialLotForRealEntry = false;     // リアルエントリー時は初期ロット使用
input bool Enable001LotFix = true;                 // 0.01ロット特別処理（0.01→0.02固定）
input bool UseAsyncOrders = true;                  // 非同期注文を使用（高速化）
input int NanpinInterval = 0;                      // ナンピン最小間隔（分）


//==================================================================
//                      利確設定
//==================================================================
sinput group "== 3. 利確・損切設定 =="
input string TakeProfitSettingsTitle = "3. 利確設定：LIMIT=MT標準TP MARKET=EA監視決済"; // 利確設定
input TP_MODE TakeProfitMode = TP_OFF;             // 利確方式：FIXED=固定pips LIMIT=指値 MARKET=成行決済
input int TakeProfitPoints = 2000;                 // 利確幅（Point）※FIXED/LIMIT/MARKET全てで使用
input bool EnableBreakEvenByPositions = false;    // ポジション数による建値決済
input int BreakEvenMinPositions = 3;               // 建値決済の最低ポジション数
input double BreakEvenProfit = 0.0;                // 建値決済の最低利益
input bool EnableMaxLossClose = false;            // 最大損失決済機能
input double MaxLossAmount = 10000.0;              // 最大損失額
input int FinalStopLossPoints = 10000;             // 最終損切り幅（Point）

//==================================================================
//                    トレーリング設定
//==================================================================
sinput group "== 4. トレーリング設定 =="
input string TrailingSettingsTitle = "4. トレーリングストップ設定"; // トレーリング設定
input bool EnableTrailingStop = false;            // トレーリングストップ有効化
input int TrailingTrigger = 1000;                  // トレール開始利益（Point）
input int TrailingOffset = 500;                    // トレールオフセット（Point）

//==================================================================
//                    資金管理設定
//==================================================================
sinput group "== 5. 資金管理設定 =="
input string RiskManagementTitle = "5. 資金管理・リスク制御設定"; // 資金管理設定
input ON_OFF EquityControl_Active = ON_MODE;       // 有効証拠金チェック有効化
input double MinimumEquity = 10000.0;              // 最低有効証拠金
input bool EnableCloseInterval = false;           // 決済後インターバル機能
input int CloseInterval = 30;                      // 決済後インターバル（分）

//==================================================================
//                    ゴーストエントリー設定
//==================================================================
sinput group "== 6. ゴーストエントリー設定 =="
input string GhostSettingsTitle = "6. ゴーストエントリー機能設定"; // ゴースト設定
input bool EnableGhostEntry = true;               // ゴーストエントリー機能有効化
input color GhostBuyColor = clrDeepSkyBlue;       // ゴーストBuy色
input color GhostSellColor = clrCrimson;          // ゴーストSell色
input int GhostArrowSize = 1;                      // ゴースト矢印サイズ

//==================================================================
//                    時間フィルター設定
//==================================================================
sinput group "== 7. 時間フィルター設定 =="
input string TimeFilterTitle = "7. 時間帯・曜日制御設定"; // 時間フィルター設定
input USE_TIMES set_time = GMT9;                   // 時間取得方法
input int natu = 6;                               // 夏時間オフセット（時間）
input int huyu = 7;                               // 冬時間オフセット（時間）
input ON_OFF EnablePositionByDay = OFF_MODE;      // 曜日別エントリー制御
input ON_OFF DayTimeControl_Active = OFF_MODE;    // 時間帯別エントリー制御

// 曜日別ポジション許可設定
input bool AllowSundayPosition = false;          // 日曜日のポジション許可
input bool AllowMondayPosition = true;           // 月曜日のポジション許可
input bool AllowTuesdayPosition = true;          // 火曜日のポジション許可
input bool AllowWednesdayPosition = true;        // 水曜日のポジション許可
input bool AllowThursdayPosition = true;         // 木曜日のポジション許可
input bool AllowFridayPosition = true;           // 金曜日のポジション許可
input bool AllowSaturdayPosition = false;        // 土曜日のポジション許可

// 共通時間設定
input int buy_StartHour = 0;                     // Buy取引開始時刻-時
input int buy_StartMinute = 0;                   // Buy取引開始時刻-分
input int buy_EndHour = 24;                      // Buy取引終了時刻-時
input int buy_EndMinute = 0;                     // Buy取引終了時刻-分
input int sell_StartHour = 0;                    // Sell取引開始時刻-時
input int sell_StartMinute = 0;                  // Sell取引開始時刻-分
input int sell_EndHour = 24;                     // Sell取引終了時刻-時
input int sell_EndMinute = 0;                    // Sell取引終了時刻-分

// 共通時間設定
input int CommonStartHour = 0;                     // 共通開始時間
input int CommonStartMinute = 0;                   // 共通開始分
input int CommonEndHour = 23;                      // 共通終了時間
input int CommonEndMinute = 59;                    // 共通終了分

//==================================================================
//                    偶数奇数戦略設定
//==================================================================
sinput group "== 8. 偶数奇数時間戦略 =="
input string EvenOddStrategyTitle = "8. 偶数奇数時間戦略設定"; // 偶数奇数戦略設定
input EVEN_ODD_STRATEGY EvenOdd_Entry_Strategy = EVEN_ODD_DISABLED; // 偶数奇数戦略
input bool EvenOdd_UseJPTime = true;                // 日本時間を使用する
input bool EvenOdd_IncludeWeekends = false;         // 週末も含める

//==================================================================
//                    テクニカル戦略設定
//==================================================================

// 戦略エントリー条件設定
sinput group "== 9. 戦略エントリー条件 =="
input string StrategyConditionTitle = "9. 戦略エントリー条件設定"; // 戦略エントリー条件
input STRATEGY_ENTRY_CONDITION Strategy_Entry_Condition = STRATEGY_NO_SAME_DIRECTION; // 戦略エントリー条件

// 移動平均線（MA）戦略設定
sinput group "== 10. 移動平均線戦略 =="
input string MAStrategyTitle = "10. 移動平均線戦略設定"; // MA戦略設定
input MA_ENTRY_TYPE MA_Entry_Strategy = MA_ENTRY_ENABLED;  // MA戦略の有効/無効
input MA_STRATEGY_TYPE MA_Buy_Signal = MA_GOLDEN_CROSS;     // MA買いシグナルタイプ
input MA_STRATEGY_TYPE MA_Sell_Signal = MA_DEAD_CROSS;      // MA売りシグナルタイプ
input ENUM_TIMEFRAMES MA_Timeframe = PERIOD_CURRENT;        // MA計算時間足
input int MA_Buy_Fast_Period = 5;                           // MA買い用短期期間
input int MA_Buy_Slow_Period = 20;                          // MA買い用長期期間
input int MA_Sell_Fast_Period = 5;                          // MA売り用短期期間
input int MA_Sell_Slow_Period = 20;                         // MA売り用長期期間
input ENUM_MA_METHOD MA_Method = MODE_SMA;                  // MA計算方法
input ENUM_APPLIED_PRICE MA_Price = PRICE_CLOSE;            // MA適用価格
input int MA_Cross_Shift = 1;                               // MAシグナル検出シフト
input STRATEGY_DIRECTION MA_Buy_Direction = TREND_FOLLOWING; // MA買い戦略方向
input STRATEGY_DIRECTION MA_Sell_Direction = TREND_FOLLOWING; // MA売り戦略方向

// RSI戦略設定
sinput group "== 11. RSI戦略 =="
input string RSIStrategyTitle = "11. RSI戦略設定"; // RSI戦略設定
input RSI_ENTRY_TYPE RSI_Entry_Strategy = RSI_ENTRY_DISABLED; // RSI戦略の有効/無効
input RSI_STRATEGY_TYPE RSI_Buy_Signal = RSI_OVERSOLD;      // RSI買いシグナルタイプ
input RSI_STRATEGY_TYPE RSI_Sell_Signal = RSI_OVERBOUGHT;   // RSI売りシグナルタイプ
input ENUM_TIMEFRAMES RSI_Timeframe = PERIOD_CURRENT;       // RSI計算時間足
input int RSI_Period = 14;                                  // RSI計算期間
input ENUM_APPLIED_PRICE RSI_Price = PRICE_CLOSE;           // RSI適用価格
input int RSI_Signal_Shift = 1;                             // RSIシグナル検出シフト
input int RSI_Oversold = 30;                                // RSI売られすぎレベル
input int RSI_Overbought = 70;                              // RSI買われすぎレベル
input STRATEGY_DIRECTION RSI_Buy_Direction = TREND_FOLLOWING; // RSI買い戦略方向
input STRATEGY_DIRECTION RSI_Sell_Direction = TREND_FOLLOWING; // RSI売り戦略方向

// ボリンジャーバンド戦略設定
sinput group "== 12. ボリンジャーバンド戦略 =="
input string BBStrategyTitle = "12. ボリンジャーバンド戦略設定"; // BB戦略設定
input BOLLINGER_ENTRY_TYPE BB_Entry_Strategy = BB_ENTRY_DISABLED; // BB戦略の有効/無効
input BB_STRATEGY_TYPE BB_Buy_Signal = BB_TOUCH_LOWER;       // BB買いシグナルタイプ
input BB_STRATEGY_TYPE BB_Sell_Signal = BB_TOUCH_UPPER;      // BB売りシグナルタイプ
input ENUM_TIMEFRAMES BB_Timeframe = PERIOD_CURRENT;         // BB計算時間足
input int BB_Period = 20;                                    // BB計算期間
input double BB_Deviation = 2.0;                             // BB標準偏差
input ENUM_APPLIED_PRICE BB_Price = PRICE_CLOSE;             // BB適用価格
input int BB_Signal_Shift = 1;                               // BBシグナル検出シフト
input STRATEGY_DIRECTION BB_Buy_Direction = TREND_FOLLOWING;  // BB買い戦略方向
input STRATEGY_DIRECTION BB_Sell_Direction = TREND_FOLLOWING; // BB売り戦略方向

// RCI戦略設定
sinput group "== 13. RCI戦略 =="
input string RCIStrategyTitle = "13. RCI戦略設定"; // RCI戦略設定
input RCI_ENTRY_TYPE RCI_Entry_Strategy = RCI_ENTRY_DISABLED; // RCI戦略の有効/無効
input RCI_STRATEGY_TYPE RCI_Buy_Signal = RCI_BELOW_MINUS_THRESHOLD; // RCI買いシグナルタイプ
input RCI_STRATEGY_TYPE RCI_Sell_Signal = RCI_ABOVE_PLUS_THRESHOLD; // RCI売りシグナルタイプ
input int RCI_Period = 9;                                    // RCI短期期間
input int RCI_MidTerm_Period = 26;                           // RCI中期期間
input int RCI_LongTerm_Period = 52;                          // RCI長期期間
input int RCI_Signal_Shift = 1;                              // RCIシグナル検出シフト
input ENUM_TIMEFRAMES RCI_Timeframe = PERIOD_CURRENT;        // RCI計算時間足
input int RCI_Threshold = 80;                                // RCIしきい値
input STRATEGY_DIRECTION RCI_Buy_Direction = TREND_FOLLOWING; // RCI買い戦略方向
input STRATEGY_DIRECTION RCI_Sell_Direction = TREND_FOLLOWING; // RCI売り戦略方向

// ストキャスティクス戦略設定
sinput group "== 14. ストキャスティクス戦略 =="
input string StochStrategyTitle = "14. ストキャスティクス戦略設定"; // Stoch戦略設定
input STOCH_ENTRY_TYPE Stoch_Entry_Strategy = STOCH_ENTRY_DISABLED; // Stoch戦略の有効/無効
input STOCH_STRATEGY_TYPE Stoch_Buy_Signal = STOCH_OVERSOLD;  // Stoch買いシグナルタイプ
input STOCH_STRATEGY_TYPE Stoch_Sell_Signal = STOCH_OVERBOUGHT; // Stoch売りシグナルタイプ
input ENUM_TIMEFRAMES Stoch_Timeframe = PERIOD_CURRENT;      // Stoch計算時間足
input int Stoch_K_Period = 5;                                // %K期間
input int Stoch_D_Period = 3;                                // %D期間
input int Stoch_Slowing = 3;                                 // スローイング期間
input ENUM_MA_METHOD Stoch_Method = MODE_SMA;                // Stoch平滑化方法
input int Stoch_Price_Field = 0;                             // Stoch価格フィールド
input int Stoch_Signal_Shift = 1;                            // Stochシグナル検出シフト
input int Stoch_Oversold = 20;                               // Stoch売られすぎレベル
input int Stoch_Overbought = 80;                             // Stoch買われすぎレベル
input STRATEGY_DIRECTION Stoch_Buy_Direction = TREND_FOLLOWING; // Stoch買い戦略方向
input STRATEGY_DIRECTION Stoch_Sell_Direction = TREND_FOLLOWING; // Stoch売り戦略方向

// CCI戦略設定
sinput group "== 15. CCI戦略 =="
input string CCIStrategyTitle = "15. CCI戦略設定"; // CCI戦略設定
input CCI_ENTRY_TYPE CCI_Entry_Strategy = CCI_ENTRY_DISABLED; // CCI戦略の有効/無効
input CCI_STRATEGY_TYPE CCI_Buy_Signal = CCI_OVERSOLD;       // CCI買いシグナルタイプ
input CCI_STRATEGY_TYPE CCI_Sell_Signal = CCI_OVERBOUGHT;    // CCI売りシグナルタイプ
input ENUM_TIMEFRAMES CCI_Timeframe = PERIOD_CURRENT;        // CCI計算時間足
input int CCI_Period = 14;                                   // CCI計算期間
input ENUM_APPLIED_PRICE CCI_Price = PRICE_CLOSE;            // CCI適用価格
input int CCI_Signal_Shift = 1;                              // CCIシグナル検出シフト
input int CCI_Oversold = -100;                               // CCI売られすぎレベル
input int CCI_Overbought = 100;                              // CCI買われすぎレベル
input STRATEGY_DIRECTION CCI_Buy_Direction = TREND_FOLLOWING; // CCI買い戦略方向
input STRATEGY_DIRECTION CCI_Sell_Direction = TREND_FOLLOWING; // CCI売り戦略方向

// ADX戦略設定
sinput group "== 16. ADX戦略 =="
input string ADXStrategyTitle = "16. ADX戦略設定"; // ADX戦略設定
input ADX_ENTRY_TYPE ADX_Entry_Strategy = ADX_ENTRY_DISABLED; // ADX戦略の有効/無効
input ADX_STRATEGY_TYPE ADX_Buy_Signal = ADX_PLUS_DI_CROSS_MINUS_DI; // ADX買いシグナルタイプ
input ADX_STRATEGY_TYPE ADX_Sell_Signal = ADX_MINUS_DI_CROSS_PLUS_DI; // ADX売りシグナルタイプ
input ENUM_TIMEFRAMES ADX_Timeframe = PERIOD_CURRENT;        // ADX計算時間足
input int ADX_Period = 14;                                   // ADX計算期間
input ENUM_APPLIED_PRICE ADX_Price = PRICE_CLOSE;            // ADX適用価格
input int ADX_Signal_Shift = 1;                              // ADXシグナル検出シフト
input int ADX_Threshold = 25;                                // ADXしきい値
input STRATEGY_DIRECTION ADX_Buy_Direction = TREND_FOLLOWING; // ADX買い戦略方向
input STRATEGY_DIRECTION ADX_Sell_Direction = TREND_FOLLOWING; // ADX売り戦略方向

// テクニカル指標条件判定設定
sinput group "== 17. 条件判定設定 =="
input string ConditionTitle = "17. 複数指標条件判定設定"; // 条件判定設定
input CONDITION_TYPE Indicator_Condition_Type = OR_CONDITION; // 複数指標の条件判定方法

//==================================================================
//                  常時エントリー戦略設定
//==================================================================
sinput group "== 18. 常時エントリー設定 =="
input string ConstantEntryTitle = "18. 常時エントリー戦略設定"; // 常時エントリー設定
input CONSTANT_ENTRY_STRATEGY_TYPE ConstantEntryStrategy = CONSTANT_ENTRY_DISABLED; // 常時エントリー戦略
input int ConstantEntryInterval = 0;                         // 常時エントリー間隔（分、0=無制限）

//==================================================================
//                  テクニカルフィルター設定
//==================================================================
sinput group "== 19. テクニカルフィルター設定 =="
input string TechnicalFilterTitle = "19. テクニカルフィルター設定"; // テクニカルフィルター設定
input FILTER_TYPE FilterType = FILTER_NONE;        // フィルタータイプ
input ENUM_TIMEFRAMES FilterTimeframe = PERIOD_CURRENT; // フィルター時間足
input int FilterPeriod = 14;                       // フィルター期間
input ENUM_MA_METHOD FilterMethod = MODE_SMA;      // 平均化方法
input int FilterShift = 0;                         // シフト

// エンベロープ設定
input double EnvelopeDeviation = 0.1;             // エンベロープ偏差(%)
input BAND_TARGET BuyBandTarget = TARGET_LOWER;   // Buyバンド対象
input BAND_CONDITION BuyBandCondition = PRICE_ABOVE; // Buyバンド条件
input BAND_TARGET SellBandTarget = TARGET_UPPER;  // Sellバンド対象
input BAND_CONDITION SellBandCondition = PRICE_BELOW; // Sellバンド条件

// ボリンジャーバンド設定
input double BollingerDeviation = 2.0;            // ボリンジャーバンド偏差
input ENUM_APPLIED_PRICE BollingerAppliedPrice = PRICE_CLOSE; // 適用価格

//==================================================================
//                        表示設定
//==================================================================
sinput group "== 20. 表示・GUI設定 =="
input string DisplaySettingsTitle = "20. 画面表示・GUI設定"; // 表示設定
input string PanelTitle = "Hosopi 3 EA";           // パネルタイトル
input int PanelX = 20;                             // パネルX座標
input int PanelY = 50;                             // パネルY座標
input bool EnablePositionTable = true;            // ポジションテーブル表示
input string GhostTableTitle = "Ghost Position Table"; // ゴーストテーブルタイトル
input int GhostTableX = 20;                        // ゴーストテーブルX座標
input int GhostTableY = 400;                       // ゴーストテーブルY座標
input ON_OFF GhostInfoDisplay = ON_MODE;           // Ghost情報表示
input ON_OFF PositionSignDisplay = ON_MODE;       // ポジションサイン表示
input ON_OFF AveragePriceLine = ON_MODE;           // 平均価格ライン表示
input color AveragePriceLineColor = clrPaleTurquoise; // 平均価格ライン色
input color TakeProfitLineColor = clrYellow;       // 利確ライン色
input bool EnablePriceLabels = true;              // 価格ラベル表示

//==================================================================
//                        通知設定
//==================================================================
sinput group "== 21. 通知設定 =="
input string NotificationTitle = "21. アラート・通知設定"; // 通知設定
input bool EnableGhostAlertNotification = false;  // ゴーストアラート通知
input bool EnableGhostPushNotification = false;   // ゴーストプッシュ通知
input bool NotifyGhostEntries = true;             // ゴーストエントリー通知
input bool NotifyGhostClosures = true;            // ゴースト決済通知

//==================================================================
//                      高度な設定
//==================================================================
sinput group "== 22. 高度な設定 =="
input string AdvancedSettingsTitle = "22. 高度な機能設定"; // 高度な設定
input bool EnableNanpin = true;                   // ナンピン機能有効化
input POSITION_PROTECTION_MODE PositionProtection = PROTECTION_OFF; // ポジション保護モード
input AVG_PRICE_CALCULATION_MODE AvgPriceCalculationMode = REAL_AND_GHOST; // 平均価格計算方法
input LAYOUT_PATTERN LayoutPattern = LAYOUT_SIDE_BY_SIDE; // レイアウトパターン
input int CustomPanelX = 20;                       // カスタム: パネルX座標
input int CustomPanelY = 50;                       // カスタム: パネルY座標
input int CustomTableX = 20;                       // カスタム: テーブルX座標
input int CustomTableY = 400;                      // カスタム: テーブルY座標
input int UpdateInterval = 1;                      // 更新間隔（秒）

// 可変利確設定（個別利確幅より優先）
input bool VariableTP_Enabled = false;            // ポジション数に応じた利確を有効（下記個別設定を使用）

// MQL5専用設定
#ifdef __MQL5__
input ENUM_ORDER_TYPE_FILLING OrderFillingType = ORDER_FILLING_FOK; // オーダーフィリングモード
#endif

//==================================================================
//                    個別指定パラメーター
//==================================================================

// 個別ロット設定
sinput group "== 23. 個別ロット指定 =="
input string IndividualLotTitle = "23. ポジション別個別ロット指定"; // 個別ロット設定
input ON_OFF IndividualLotEnabled = OFF_MODE;      // 個別ロット設定を有効化
input double Lot_1 = 0.01; input double Lot_2 = 0.02; input double Lot_3 = 0.04;
input double Lot_4 = 0.07; input double Lot_5 = 0.13; input double Lot_6 = 0.23;
input double Lot_7 = 0.41; input double Lot_8 = 0.74; input double Lot_9 = 1.33;
input double Lot_10 = 2.40; input double Lot_11 = 4.32; input double Lot_12 = 7.78;
input double Lot_13 = 14.00; input double Lot_14 = 25.20; input double Lot_15 = 45.36;
input double Lot_16 = 50.00; input double Lot_17 = 60.00; input double Lot_18 = 70.00;
input double Lot_19 = 80.00; input double Lot_20 = 90.00; input double Lot_21 = 99.00;
input double Lot_22 = 99.00; input double Lot_23 = 99.00; input double Lot_24 = 99.00;
input double Lot_25 = 99.00; input double Lot_26 = 99.00; input double Lot_27 = 99.00;
input double Lot_28 = 99.00; input double Lot_29 = 99.00; input double Lot_30 = 99.00;
input double Lot_31 = 99.00; input double Lot_32 = 99.00; input double Lot_33 = 99.00;
input double Lot_34 = 99.00; input double Lot_35 = 99.00; input double Lot_36 = 99.00;
input double Lot_37 = 99.00; input double Lot_38 = 99.00; input double Lot_39 = 99.00;
input double Lot_40 = 99.00;

// 個別ナンピン幅設定
sinput group "== 24. 個別ナンピン幅指定 =="
input string IndividualSpreadTitle = "24. ポジション別個別ナンピン幅指定"; // 個別ナンピン幅設定
input ON_OFF IndividualSpreadEnabled = OFF_MODE;   // 個別ナンピン幅設定を有効化
input int Spread_1 = 2000; input int Spread_2 = 2000; input int Spread_3 = 2000;
input int Spread_4 = 2000; input int Spread_5 = 2000; input int Spread_6 = 2000;
input int Spread_7 = 2000; input int Spread_8 = 2000; input int Spread_9 = 2000;
input int Spread_10 = 2000; input int Spread_11 = 2000; input int Spread_12 = 2000;
input int Spread_13 = 2000; input int Spread_14 = 2000; input int Spread_15 = 2000;
input int Spread_16 = 2000; input int Spread_17 = 2000; input int Spread_18 = 2000;
input int Spread_19 = 2000; input int Spread_20 = 2000; input int Spread_21 = 2000;
input int Spread_22 = 2000; input int Spread_23 = 2000; input int Spread_24 = 2000;
input int Spread_25 = 2000; input int Spread_26 = 2000; input int Spread_27 = 2000;
input int Spread_28 = 2000; input int Spread_29 = 2000; input int Spread_30 = 2000;
input int Spread_31 = 2000; input int Spread_32 = 2000; input int Spread_33 = 2000;
input int Spread_34 = 2000; input int Spread_35 = 2000; input int Spread_36 = 2000;
input int Spread_37 = 2000; input int Spread_38 = 2000; input int Spread_39 = 2000;
input int Spread_40 = 2000;

// 個別利確幅設定（VariableTP_Enabledをtrueにすると有効）
sinput group "== 25. 個別利確幅指定 =="
input string IndividualTPTitle = "25. ポジション別利確幅（上記可変利確ONで有効）"; // 個別利確設定
input int TP_Level1 = 2000; input int TP_Level2 = 1500; input int TP_Level3 = 1000;
input int TP_Level4 = 800; input int TP_Level5 = 600; input int TP_Level6 = 500;
input int TP_Level7 = 400; input int TP_Level8 = 350; input int TP_Level9 = 300;
input int TP_Level10 = 250; input int TP_Level11 = 220; input int TP_Level12 = 200;
input int TP_Level13 = 180; input int TP_Level14 = 160; input int TP_Level15 = 150;
input int TP_Level16 = 140; input int TP_Level17 = 130; input int TP_Level18 = 120;
input int TP_Level19 = 110; input int TP_Level20 = 100; input int TP_Level21 = 100;
input int TP_Level22 = 100; input int TP_Level23 = 100; input int TP_Level24 = 100;
input int TP_Level25 = 100; input int TP_Level26 = 100; input int TP_Level27 = 100;
input int TP_Level28 = 100; input int TP_Level29 = 100; input int TP_Level30 = 100;
input int TP_Level31 = 100; input int TP_Level32 = 100; input int TP_Level33 = 100;
input int TP_Level34 = 100; input int TP_Level35 = 100; input int TP_Level36 = 100;
input int TP_Level37 = 100; input int TP_Level38 = 100; input int TP_Level39 = 100;
input int TP_Level40 = 100;

//==================================================================
//                    曜日別時間指定パラメーター
//==================================================================

sinput group "== 曜日別時間指定 =="
input string DayTimeTitle = "曜日別詳細時間指定"; // 曜日別時間設定

// 日曜日設定
input ON_OFF Sunday_Enable = ON_MODE;              // 日曜日エントリー許可
input int Sunday_Buy_StartHour = 0; input int Sunday_Buy_StartMinute = 0;
input int Sunday_Buy_EndHour = 23; input int Sunday_Buy_EndMinute = 59;
input int Sunday_Sell_StartHour = 0; input int Sunday_Sell_StartMinute = 0;
input int Sunday_Sell_EndHour = 23; input int Sunday_Sell_EndMinute = 59;

// 月曜日設定
input ON_OFF Monday_Enable = ON_MODE;              // 月曜日エントリー許可
input int Monday_Buy_StartHour = 0; input int Monday_Buy_StartMinute = 0;
input int Monday_Buy_EndHour = 23; input int Monday_Buy_EndMinute = 59;
input int Monday_Sell_StartHour = 0; input int Monday_Sell_StartMinute = 0;
input int Monday_Sell_EndHour = 23; input int Monday_Sell_EndMinute = 59;

// 火曜日設定
input ON_OFF Tuesday_Enable = ON_MODE;             // 火曜日エントリー許可
input int Tuesday_Buy_StartHour = 0; input int Tuesday_Buy_StartMinute = 0;
input int Tuesday_Buy_EndHour = 23; input int Tuesday_Buy_EndMinute = 59;
input int Tuesday_Sell_StartHour = 0; input int Tuesday_Sell_StartMinute = 0;
input int Tuesday_Sell_EndHour = 23; input int Tuesday_Sell_EndMinute = 59;

// 水曜日設定
input ON_OFF Wednesday_Enable = ON_MODE;           // 水曜日エントリー許可
input int Wednesday_Buy_StartHour = 0; input int Wednesday_Buy_StartMinute = 0;
input int Wednesday_Buy_EndHour = 23; input int Wednesday_Buy_EndMinute = 59;
input int Wednesday_Sell_StartHour = 0; input int Wednesday_Sell_StartMinute = 0;
input int Wednesday_Sell_EndHour = 23; input int Wednesday_Sell_EndMinute = 59;

// 木曜日設定
input ON_OFF Thursday_Enable = ON_MODE;            // 木曜日エントリー許可
input int Thursday_Buy_StartHour = 0; input int Thursday_Buy_StartMinute = 0;
input int Thursday_Buy_EndHour = 23; input int Thursday_Buy_EndMinute = 59;
input int Thursday_Sell_StartHour = 0; input int Thursday_Sell_StartMinute = 0;
input int Thursday_Sell_EndHour = 23; input int Thursday_Sell_EndMinute = 59;

// 金曜日設定
input ON_OFF Friday_Enable = ON_MODE;              // 金曜日エントリー許可
input int Friday_Buy_StartHour = 0; input int Friday_Buy_StartMinute = 0;
input int Friday_Buy_EndHour = 23; input int Friday_Buy_EndMinute = 59;
input int Friday_Sell_StartHour = 0; input int Friday_Sell_StartMinute = 0;
input int Friday_Sell_EndHour = 23; input int Friday_Sell_EndMinute = 59;

// 土曜日設定
input ON_OFF Saturday_Enable = ON_MODE;            // 土曜日エントリー許可
input int Saturday_Buy_StartHour = 0; input int Saturday_Buy_StartMinute = 0;
input int Saturday_Buy_EndHour = 23; input int Saturday_Buy_EndMinute = 59;
input int Saturday_Sell_StartHour = 0; input int Saturday_Sell_StartMinute = 0;
input int Saturday_Sell_EndHour = 23; input int Saturday_Sell_EndMinute = 59;