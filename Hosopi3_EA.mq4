//+------------------------------------------------------------------+
//|                           Hosopi 3 - メインEAファイル(MT4)        |
//|                              Copyright 2025                      |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025"
#property link      ""
#property version   "3.1"
#property strict

// インクルードファイル
#include "Hosopi3_Defines.mqh"
#include "Hosopi3_Trading.mqh"
#include "Hosopi3_Utils.mqh"
#include "Hosopi3_GUI.mqh"
#include "Hosopi3_Table.mqh"
#include "Hosopi3_Ghost.mqh"
#include "Hosopi3_TakeProfit.mqh"  
#include "Hosopi3_Manager.mqh"
//+------------------------------------------------------------------+
//|                          入力パラメータ                          |
//+------------------------------------------------------------------+
// ======== ナンピンマーチン基本設定 ========
sinput string Comment_Martingale = ""; //+--- ナンピンマーチン基本設定 ---+
input NANPIN_SKIP NanpinSkipLevel = SKIP_5;  // ナンピンスキップレベル
input int NanpinSpread = 2000;               // ナンピン幅（Point）
// リアルエントリーでの初期ロット使用の設定
input bool UseInitialLotForRealEntry = false; // リアルエントリーは初期ロットを使う


input double InitialLot = 0.01;             // 初期LOT
input MAX_POSITIONS MaxPositions = POS_15;   // 最大ポジション数量
input double LotMultiplier = 1.8;           // LOT倍率（小数第三位で繰り上げ）

// ======== ナンピンインターバル設定 ========
sinput string Comment_Interval = ""; //+--- ナンピンインターバル設定 ---+
input int NanpinInterval = 0;             // ナンピンインターバル(Minutes)

// ======== 決済後インターバル設定 ========
sinput string Comment_CloseInterval = ""; //+--- 決済後インターバル設定 ---+
input bool EnableCloseInterval = false;     // 決済後インターバル機能を有効化
input int CloseInterval = 30;               // 決済後インターバル（Minutes）


//+------------------------------------------------------------------+
//| ポジション保護機能の定義                                         |
//+------------------------------------------------------------------+
enum POSITION_PROTECTION_MODE
{
   PROTECTION_OFF = 0,        // 両建て許可
   PROTECTION_ON = 1          // 単方向のみ許可
};

//+------------------------------------------------------------------+
//| 有効証拠金関連の設定                                              |
//+------------------------------------------------------------------+
sinput string Comment_Equity_Control = ""; //+--- 有効証拠金の設定 ---+
input ON_OFF EquityControl_Active = ON_MODE;   // 有効証拠金チェックを有効にする(ON/OFF)
input double MinimumEquity = 10000;          // 最低有効証拠金（この金額未満でエントリー停止）


// ======== ポジション保護設定 ========
sinput string Comment_Protection = ""; //+--- 両建て設定 ---+
input POSITION_PROTECTION_MODE PositionProtection = PROTECTION_OFF; // 両建て設定モード

//+------------------------------------------------------------------+
//| 平均取得単価計算方法の列挙型を追加                                |
//+------------------------------------------------------------------+
enum AVG_PRICE_CALCULATION_MODE
{
   REAL_POSITIONS_ONLY = 0,    // リアルポジションのみ
   REAL_AND_GHOST = 1          // リアルとゴースト両方
};

// ======== 平均取得単価計算設定 ========
sinput string Comment_AvgPriceCalc = ""; //+--- 平均取得単価計算設定 ---+
input AVG_PRICE_CALCULATION_MODE AvgPriceCalculationMode = REAL_AND_GHOST; // 平均取得単価計算方法



// リミット決済方式の列挙型を定義
enum TP_MODE {
   TP_OFF = 0,           // OFF
   TP_LIMIT = 1,         // 指値
   TP_MARKET = 2         // 成り行き
};

// ======== 決済利確条件設定 ========
sinput string Comment_RIGUITP_Conditions = ""; //+--- 利確条件設定 ---+
input TP_MODE TakeProfitMode = TP_OFF;       // 利確方式
input int TakeProfitPoints = 2000;            // 利確幅（Point）
input bool EnableTrailingStop = false;        // トレールストップを有効化
input int TrailingTrigger = 1000;             // トレールトリガー（Point）
input int TrailingOffset = 500;               // トレールオフセット（Point）

//+------------------------------------------------------------------+
//| ポジション数に応じた建値決済設定の追加                          |
//+------------------------------------------------------------------+

// ======== 建値決済機能設定 ========
sinput string Comment_BreakEven = ""; //+--- 建値決済機能設定 ---+
input bool EnableBreakEvenByPositions = false;   // ○ポジション以上なら建値で決済機能(ON/OFF)
input double BreakEvenProfit = 0.0;              // 建値価格（最低利益額）
input int BreakEvenMinPositions = 3;             // 最低ポジション数

// ======== 基本設定 ========
sinput string Comment_Basic = ""; //+--- 基本設定 ---+
input int MagicNumber = 99899;      // マジックナンバー
input string PanelTitle = "Hosopi 3 EA"; // パネルタイトル
input int PanelX = 20;     // パネルX座標
input int PanelY = 50;    // パネルY座標

//+------------------------------------------------------------------+
//| エントリーモード設定 - 基本パラメーター                           |
//+------------------------------------------------------------------+


// 基本設定セクションに追加するパラメーター
input ENTRY_MODE EntryMode = MODE_BOTH;   // エントリー方向

// ======== スプレッド設定 ========
sinput string Comment_Spread = ""; //+--- スプレッド設定 ---+
input int MaxSpreadPoints = 2000;    // 最大スプレッド（Point）
input int Slippage = 100;           // スリッページ（Point）

// ======== 機能制御設定 ========
sinput string Comment_Features = ""; //+--- 機能制御設定 ---+
input bool EnableNanpin = true;               // ナンピン機能を有効化
input bool EnableGhostEntry = true;           // ゴーストエントリー機能を有効化
input bool EnableAutomaticTrading = true;     // 自動売買を有効化
input bool EnablePositionTable = true;        // ポジションテーブル表示を有効化
input bool EnablePriceLabels = true;          // 価格ラベル表示を有効化


// ======== 時間設定 ========
sinput string Comment_Time = ""; //+--- 時間設定 ---+
input USE_TIMES set_time = GMT9;     // 時間取得方法
input int natu = 6;                  // 夏加算時間（バックテスト用）
input int huyu = 7;                  // 冬加算時間（バックテスト用）


// 共通時間設定（曜日別設定が無効の場合に使用）
sinput string Comment_Common_Time = ""; //+--- 共通時間設定 ---+
input ON_OFF DayTimeControl_Active = ON_MODE; // 共通時間設定を有効にする(ON/OFF)
input int buy_StartHour = 0;             // Buy取引開始時刻-時(日本時間)
input int buy_StartMinute = 0;          // Buy取引開始時刻-分(日本時間)
input int buy_EndHour = 24;              // Buy取引終了時刻-時(日本時間)
input int buy_EndMinute = 0;             // Buy取引終了時刻-分(日本時間)
input int sell_StartHour = 0;            // Sell取引開始時刻-時(日本時間)
input int sell_StartMinute = 00;         // Sell取引開始時刻-分(日本時間)
input int sell_EndHour = 24;             // Sell取引終了時刻-時(日本時間)
input int sell_EndMinute = 0;            // Sell取引終了時刻-分(日本時間)


// 日曜日の時間設定
sinput string Comment_Sunday_Time = ""; //+--- 日曜日の時間設定 ---+
input ON_OFF Sunday_Enable = ON_MODE;      // 日曜日を有効にする
input int Sunday_Buy_StartHour = 0;      // 日曜日Buy開始時刻-時
input int Sunday_Buy_StartMinute = 0;    // 日曜日Buy開始時刻-分
input int Sunday_Buy_EndHour = 24;       // 日曜日Buy終了時刻-時
input int Sunday_Buy_EndMinute = 0;      // 日曜日Buy終了時刻-分
input int Sunday_Sell_StartHour = 0;     // 日曜日Sell開始時刻-時
input int Sunday_Sell_StartMinute = 0;   // 日曜日Sell開始時刻-分
input int Sunday_Sell_EndHour = 24;      // 日曜日Sell終了時刻-時
input int Sunday_Sell_EndMinute = 0;     // 日曜日Sell終了時刻-分

// 月曜日の時間設定
sinput string Comment_Monday_Time = ""; //+--- 月曜日の時間設定 ---+
input ON_OFF Monday_Enable = ON_MODE;      // 月曜日を有効にする
input int Monday_Buy_StartHour = 0;      // 月曜日Buy開始時刻-時
input int Monday_Buy_StartMinute = 0;    // 月曜日Buy開始時刻-分
input int Monday_Buy_EndHour = 24;       // 月曜日Buy終了時刻-時
input int Monday_Buy_EndMinute = 0;      // 月曜日Buy終了時刻-分
input int Monday_Sell_StartHour = 0;     // 月曜日Sell開始時刻-時
input int Monday_Sell_StartMinute = 0;   // 月曜日Sell開始時刻-分
input int Monday_Sell_EndHour = 24;      // 月曜日Sell終了時刻-時
input int Monday_Sell_EndMinute = 0;     // 月曜日Sell終了時刻-分

// 火曜日の時間設定
sinput string Comment_Tuesday_Time = ""; //+--- 火曜日の時間設定 ---+
input ON_OFF Tuesday_Enable = ON_MODE;     // 火曜日を有効にする
input int Tuesday_Buy_StartHour = 0;      // 火曜日Buy開始時刻-時
input int Tuesday_Buy_StartMinute = 0;    // 火曜日Buy開始時刻-分
input int Tuesday_Buy_EndHour = 24;       // 火曜日Buy終了時刻-時
input int Tuesday_Buy_EndMinute = 0;      // 火曜日Buy終了時刻-分
input int Tuesday_Sell_StartHour = 0;     // 火曜日Sell開始時刻-時
input int Tuesday_Sell_StartMinute = 0;   // 火曜日Sell開始時刻-分
input int Tuesday_Sell_EndHour = 24;      // 火曜日Sell終了時刻-時
input int Tuesday_Sell_EndMinute = 0;     // 火曜日Sell終了時刻-分

// 水曜日の時間設定
sinput string Comment_Wednesday_Time = ""; //+--- 水曜日の時間設定 ---+
input ON_OFF Wednesday_Enable = ON_MODE;   // 水曜日を有効にする
input int Wednesday_Buy_StartHour = 0;      // 水曜日Buy開始時刻-時
input int Wednesday_Buy_StartMinute = 0;    // 水曜日Buy開始時刻-分
input int Wednesday_Buy_EndHour = 24;       // 水曜日Buy終了時刻-時
input int Wednesday_Buy_EndMinute = 0;      // 水曜日Buy終了時刻-分
input int Wednesday_Sell_StartHour = 0;     // 水曜日Sell開始時刻-時
input int Wednesday_Sell_StartMinute = 0;   // 水曜日Sell開始時刻-分
input int Wednesday_Sell_EndHour = 24;      // 水曜日Sell終了時刻-時
input int Wednesday_Sell_EndMinute = 0;     // 水曜日Sell終了時刻-分

// 木曜日の時間設定
sinput string Comment_Thursday_Time = ""; //+--- 木曜日の時間設定 ---+
input ON_OFF Thursday_Enable = ON_MODE;    // 木曜日を有効にする
input int Thursday_Buy_StartHour = 0;      // 木曜日Buy開始時刻-時
input int Thursday_Buy_StartMinute = 0;    // 木曜日Buy開始時刻-分
input int Thursday_Buy_EndHour = 24;       // 木曜日Buy終了時刻-時
input int Thursday_Buy_EndMinute = 0;      // 木曜日Buy終了時刻-分
input int Thursday_Sell_StartHour = 0;     // 木曜日Sell開始時刻-時
input int Thursday_Sell_StartMinute = 0;   // 木曜日Sell開始時刻-分
input int Thursday_Sell_EndHour = 24;      // 木曜日Sell終了時刻-時
input int Thursday_Sell_EndMinute = 0;     // 木曜日Sell終了時刻-分

// 金曜日の時間設定
sinput string Comment_Friday_Time = ""; //+--- 金曜日の時間設定 ---+
input ON_OFF Friday_Enable = ON_MODE;      // 金曜日を有効にする
input int Friday_Buy_StartHour = 0;      // 金曜日Buy開始時刻-時
input int Friday_Buy_StartMinute = 0;    // 金曜日Buy開始時刻-分
input int Friday_Buy_EndHour = 24;       // 金曜日Buy終了時刻-時
input int Friday_Buy_EndMinute = 0;      // 金曜日Buy終了時刻-分
input int Friday_Sell_StartHour = 0;     // 金曜日Sell開始時刻-時
input int Friday_Sell_StartMinute = 0;   // 金曜日Sell開始時刻-分
input int Friday_Sell_EndHour = 24;      // 金曜日Sell終了時刻-時
input int Friday_Sell_EndMinute = 0;     // 金曜日Sell終了時刻-分

// 土曜日の時間設定
sinput string Comment_Saturday_Time = ""; //+--- 土曜日の時間設定 ---+
input ON_OFF Saturday_Enable = ON_MODE;    // 土曜日を有効にする
input int Saturday_Buy_StartHour = 0;      // 土曜日Buy開始時刻-時
input int Saturday_Buy_StartMinute = 0;    // 土曜日Buy開始時刻-分
input int Saturday_Buy_EndHour = 24;       // 土曜日Buy終了時刻-時
input int Saturday_Buy_EndMinute = 0;      // 土曜日Buy終了時刻-分
input int Saturday_Sell_StartHour = 0;     // 土曜日Sell開始時刻-時
input int Saturday_Sell_StartMinute = 0;   // 土曜日Sell開始時刻-分
input int Saturday_Sell_EndHour = 24;      // 土曜日Sell終了時刻-時
input int Saturday_Sell_EndMinute = 0;     // 土曜日Sell終了時刻-分




// ======== 表示設定 ========
sinput string Comment_Display = ""; //+--- 表示設定 ---+
input ON_OFF GhostInfoDisplay = ON_MODE;    // Ghost情報表示(ON/OFF)
input ON_OFF PositionSignDisplay = ON_MODE; // ポジションサイン表示(ON/OFF)
input ON_OFF AveragePriceLine = ON_MODE;    // 平均取得価格ライン表示(ON/OFF)
input color AveragePriceLineColor = clrPaleTurquoise; // 平均取得価格ライン色
input color TakeProfitLineColor = clrYellow; // 利確ラインの色




// ポジションテーブル設定
input string TableSettingsTitle = ""; //+--- ポジションテーブル設定 ---+
input string GhostTableTitle = "Ghost Position Table"; // ゴーストテーブルタイトル
input int GhostTableX = 20;             // ゴーストテーブルX座標
input int GhostTableY = 400;            // ゴーストテーブルY座標
input int UpdateInterval = 1;           // テーブル更新間隔（秒）

// ゴーストエントリーポイント表示設定
input color GhostBuyColor = clrDeepSkyBlue;   // ゴーストBuyエントリー色
input color GhostSellColor = clrCrimson;      // ゴーストSellエントリー色
input int GhostArrowSize = 3;                 // ゴースト矢印サイズ


#include "Hosopi3_Strategy.mqh"


// ======== LOT数量の個別設定 ========
sinput string Comment_LotIndividual = ""; //+--- LOT数量の個別設定 ---+
input ON_OFF IndividualLotEnabled = OFF_MODE; // LOT個別指定を有効にする(ON/OFF)
input double Lot_1 = 0.01;   // 1段目 LOT
input double Lot_2 = 0.02;   // 2段目 LOT
input double Lot_3 = 0.04;   // 3段目 LOT
input double Lot_4 = 0.07;   // 4段目 LOT
input double Lot_5 = 0.13;   // 5段目 LOT
input double Lot_6 = 0.23;   // 6段目 LOT
input double Lot_7 = 0.41;   // 7段目 LOT
input double Lot_8 = 0.74;   // 8段目 LOT
input double Lot_9 = 1.33;   // 9段目 LOT
input double Lot_10 = 2.39;  // 10段目 LOT
input double Lot_11 = 4.3;   // 11段目 LOT
input double Lot_12 = 7.74;  // 12段目 LOT
input double Lot_13 = 13.93; // 13段目 LOT
input double Lot_14 = 25.07; // 14段目 LOT
input double Lot_15 = 45.13; // 15段目 LOT
input double Lot_16 = 81.23; // 16段目 LOT
input double Lot_17 = 99.0;  // 17段目 LOT
input double Lot_18 = 99.0;  // 18段目 LOT
input double Lot_19 = 99.0;  // 19段目 LOT
input double Lot_20 = 99.0;  // 20段目 LOT

// ======== ナンピン幅の個別設定 ========
sinput string Comment_SpreadIndividual = ""; //+--- ナンピン幅の個別設定 ---+
input ON_OFF IndividualSpreadEnabled = OFF_MODE; // ナンピン幅の個別指定を有効にする(ON/OFF)
input int Spread_1 = 888;   // 1段目 ナンピン幅
input int Spread_2 = 888;   // 2段目 ナンピン幅
input int Spread_3 = 888;   // 3段目 ナンピン幅
input int Spread_4 = 888;   // 4段目 ナンピン幅
input int Spread_5 = 888;   // 5段目 ナンピン幅
input int Spread_6 = 888;   // 6段目 ナンピン幅
input int Spread_7 = 888;   // 7段目 ナンピン幅
input int Spread_8 = 888;   // 8段目 ナンピン幅
input int Spread_9 = 888;   // 9段目 ナンピン幅
input int Spread_10 = 888;  // 10段目 ナンピン幅
input int Spread_11 = 888;  // 11段目 ナンピン幅
input int Spread_12 = 888;  // 12段目 ナンピン幅
input int Spread_13 = 888;  // 13段目 ナンピン幅
input int Spread_14 = 888;  // 14段目 ナンピン幅
input int Spread_15 = 888;  // 15段目 ナンピン幅
input int Spread_16 = 888;  // 16段目 ナンピン幅
input int Spread_17 = 888;  // 17段目 ナンピン幅
input int Spread_18 = 888;  // 18段目 ナンピン幅
input int Spread_19 = 888;  // 19段目 ナンピン幅
input int Spread_20 = 888;  // 20段目 ナンピン幅


// ======== ポジション数に応じた利確設定 ========
sinput string Comment_Position_TP = ""; //+--- ポジション数に応じた利確設定 ---+
input bool VariableTP_Enabled = false;   // ポジション数に応じた利確を有効にする
input int TP_Level1 = 2000;              // 1ポジション時の利確幅(ポイント)
input int TP_Level2 = 1500;              // 2ポジション時の利確幅(ポイント)
input int TP_Level3 = 1000;              // 3ポジション時の利確幅(ポイント)
input int TP_Level4 = 800;               // 4ポジション時の利確幅(ポイント)
input int TP_Level5 = 600;               // 5ポジション時の利確幅(ポイント)
input int TP_Level6 = 500;               // 6ポジション時の利確幅(ポイント)
input int TP_Level7 = 400;               // 7ポジション時の利確幅(ポイント)
input int TP_Level8 = 350;               // 8ポジション時の利確幅(ポイント)
input int TP_Level9 = 300;               // 9ポジション時の利確幅(ポイント)
input int TP_Level10 = 250;              // 10ポジション時の利確幅(ポイント)
input int TP_Level11 = 220;              // 11ポジション時の利確幅(ポイント)
input int TP_Level12 = 200;              // 12ポジション時の利確幅(ポイント)
input int TP_Level13 = 180;              // 13ポジション時の利確幅(ポイント)
input int TP_Level14 = 160;              // 14ポジション時の利確幅(ポイント)
input int TP_Level15 = 150;              // 15ポジション時の利確幅(ポイント)
input int TP_Level16 = 140;              // 16ポジション時の利確幅(ポイント)
input int TP_Level17 = 130;              // 17ポジション時の利確幅(ポイント)
input int TP_Level18 = 120;              // 18ポジション時の利確幅(ポイント)
input int TP_Level19 = 110;              // 19ポジション時の利確幅(ポイント)
input int TP_Level20 = 100;              // 20ポジション時の利確幅(ポイント)



//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   // 共通初期化処理の呼び出し
   return InitializeEA();
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   // 共通終了処理の呼び出し
   DeinitializeEA(reason);
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   // 共通Tick処理の呼び出し
   OnTickManager();
}

//+------------------------------------------------------------------+
//| ChartEvent function                                              |
//+------------------------------------------------------------------+
void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
{
   // 共通チャートイベント処理の呼び出し
   HandleChartEvent(id, lparam, dparam, sparam);
}
//+------------------------------------------------------------------+