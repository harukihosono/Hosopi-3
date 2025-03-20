//+------------------------------------------------------------------+
//|                           Hosopi 3 - メインEAファイル(MT4)        |
//|                              Copyright 2025                      |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025"
#property link      ""
#property version   "3.0"
#property strict

// インクルードファイル
#include "Hosopi3_Defines.mqh"
#include "Hosopi3_Trading.mqh"
#include "Hosopi3_Utils.mqh"
#include "Hosopi3_GUI.mqh"
#include "Hosopi3_Table.mqh"
#include "Hosopi3_Ghost.mqh"
#include "Hosopi3_Manager.mqh"

//+------------------------------------------------------------------+
//|                          入力パラメータ                          |
//+------------------------------------------------------------------+

// ======== 基本設定 ========
sinput string Comment_Basic = ""; //+--- 基本設定 ---+
input int MagicNumber = 99899;      // マジックナンバー
input string PanelTitle = "Hosopi 3 EA"; // パネルタイトル
input int PanelX = 20;     // パネルX座標
input int PanelY = 100;    // パネルY座標

// ======== スプレッド設定 ========
sinput string Comment_Spread = ""; //+--- スプレッド設定 ---+
input int MaxSpreadPoints = 2000;    // 最大スプレッド（Point）
input int Slippage = 100;           // スリッページ（Point）

// ======== エントリー方向設定 ========
sinput string Comment_Entry = ""; //+--- エントリー方向設定 ---+
input ENTRY_DIRECTION buy_EntryDirection = EVEN_HOURS;  // Buy エントリー方向
input ENTRY_DIRECTION sell_EntryDirection = ODD_HOURS;  // Sell エントリー方向
input ENTRY_MODE EntryMode = MODE_BOTH;   // エントリー方向

// ======== 時間設定 ========
sinput string Comment_Time = ""; //+--- 時間設定 ---+
input USE_TIMES set_time = GMT9;     // 時間取得方法
input int natu = 6;                  // 夏加算時間（バックテスト用）
input int huyu = 7;                  // 冬加算時間（バックテスト用）

// エントリー可能時間設定
input ON_OFF TimeControl_Active = ON_MODE;    // 時間制御を有効にする(ON/OFF)
input int buy_StartHour = 0;             // Buy取引開始時刻-時(日本時間)
input int buy_StartMinute = 0;          // Buy取引開始時刻-分(日本時間)
input int buy_EndHour = 24;              // Buy取引終了時刻-時(日本時間)
input int buy_EndMinute = 0;             // Buy取引終了時刻-分(日本時間)
input int sell_StartHour = 0;            // Sell取引開始時刻-時(日本時間)
input int sell_StartMinute = 00;         // Sell取引開始時刻-分(日本時間)
input int sell_EndHour = 24;             // Sell取引終了時刻-時(日本時間)
input int sell_EndMinute = 0;            // Sell取引終了時刻-分(日本時間)

// ======== 曜日フィルター設定 ========
sinput string Comment_DayFilter = ""; //+--- 曜日フィルター設定 ---+
input ON_OFF Sunday_Enable = ON_MODE;      // 日曜日を有効にする
input ON_OFF Monday_Enable = ON_MODE;      // 月曜日を有効にする
input ON_OFF Tuesday_Enable = ON_MODE;     // 火曜日を有効にする
input ON_OFF Wednesday_Enable = ON_MODE;   // 水曜日を有効にする
input ON_OFF Thursday_Enable = ON_MODE;    // 木曜日を有効にする
input ON_OFF Friday_Enable = ON_MODE;      // 金曜日を有効にする
input ON_OFF Saturday_Enable = ON_MODE;    // 土曜日を有効にする


// ======== ナンピンマーチン基本設定 ========
sinput string Comment_Martingale = ""; //+--- ナンピンマーチン基本設定 ---+
input NANPIN_SKIP NanpinSkipLevel = SKIP_5;  // ナンピンスキップレベル
input int NanpinSpread = 2000;               // ナンピン幅（Point）
input int TakeProfitPoints = 2000;            // 利確幅（Point）

input double InitialLot = 0.01;             // 初期LOT
input MAX_POSITIONS MaxPositions = POS_15;   // 最大ポジション数量
input double LotMultiplier = 1.8;           // LOT倍率（小数第三位で繰り上げ）

// ======== ナンピンインターバル設定 ========
sinput string Comment_Interval = ""; //+--- ナンピンインターバル設定 ---+
input int NanpinInterval = 0;             // ナンピンインターバル(Minutes)

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