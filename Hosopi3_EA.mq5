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
#include "Hosopi3_Enums.mqh"        // 列挙型定義
#ifdef __MQL5__
   #include "Hosopi3_AllParams_MQL5.mqh"  // 全パラメータ（MQL5版）
#else
   #include "Hosopi3_AllParams_MQL4.mqh"  // 全パラメータ（MQL4版）
#endif
#include "Hosopi3_Trading.mqh"
#include "Hosopi3_Utils.mqh"
#include "Hosopi3_GUI.mqh"
#include "Hosopi3_Table.mqh"
#include "Hosopi3_Ghost.mqh"
#include "Hosopi3_TakeProfit.mqh"
#include "Hosopi3_Manager.mqh"
#include "Hosopi3_Notification.mqh"
#include "Hosopi3_Strategy.mqh"
#include "Hosopi3_Async.mqh"
#include "Hosopi3_CyberUI.mqh"
#include "Hosopi3_InfoPanel.mqh"
#include "Hosopi3_IndicatorEntry.mqh"
#include "Hosopi3_VolatilityFilter.mqh"

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
//| OnTradeTransaction function (MT5のみ)                          |
//+------------------------------------------------------------------+
#ifdef __MQL5__
void OnTradeTransaction(const MqlTradeTransaction& trans,
                        const MqlTradeRequest& request,
                        const MqlTradeResult& result)
{
   // 非同期注文の結果を処理
   ProcessAsyncTradeTransaction(trans, request, result);
}
#endif
//+------------------------------------------------------------------+