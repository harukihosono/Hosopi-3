//+------------------------------------------------------------------+
//|                 Hosopi 3 - ユーティリティ関数                     |
//|                         Copyright 2025                           |
//+------------------------------------------------------------------+
#include "Hosopi3_Defines.mqh"

//+------------------------------------------------------------------+
//| グローバル変数初期化                                              |
//+------------------------------------------------------------------+
void InitializeGlobalVariables()
{
   // フラグ初期化
   g_AutoTrading = true;
   g_GhostMode = true;
   g_ArrowsVisible = true;
   g_AvgPriceVisible = true;
   
   // カウンター初期化
   g_GhostBuyCount = 0;
   g_GhostSellCount = 0;
   g_LineObjectCount = 0;
   g_EntryObjectCount = 0;
   g_TableObjectCount = 0;
   g_PanelObjectCount = 0;
   
   // 時間関連初期化
   g_LastUpdateTime = 0;
}

//+------------------------------------------------------------------+
//| 時間計算関数                                                      |
//+------------------------------------------------------------------+
datetime calculate_time()
{
   if(set_time == GMT9)
   {
      return TimeGMT() + 60 * 60 * 9;
   }
   if(set_time == GMT9_BACKTEST)
   {
      return GetJapanTime();
   }
   if(set_time == GMT_KOTEI)
   {
      return TimeCurrent() + 60 * 60 * 9;
   }
   return 0;
}

//+------------------------------------------------------------------+
//| 日本時間取得関数                                                  |
//+------------------------------------------------------------------+
datetime GetJapanTime()
{
   datetime now = TimeCurrent();
   datetime summer = now + 60 * 60 * natu;
   datetime winter = now + 60 * 60 * huyu;
   
   if(is_summer())
   {
      return summer;
   }
   return winter;
}

//+------------------------------------------------------------------+
//| サマータイムチェック関数                                           |
//+------------------------------------------------------------------+
bool is_summer()
{
   datetime now = TimeCurrent();
   int month = TimeMonth(now);
   int day = TimeDay(now);
   
   if(month < 3 || month > 11)
   {
      return false;
   }
   if(month > 3 && month < 11)
   {
      return true;
   }
   
   // アメリカのサマータイムは3月の第2日曜日から11月の第1日曜日まで
   if(month == 3)
   {
      // 3月の第2日曜日を計算
      int firstSunday = (7 - TimeDay(StringToTime(StringFormat("%d.%d.1", TimeYear(now), month))) % 7) % 7 + 1;
      int secondSunday = firstSunday + 7;
      
      if(day >= secondSunday)
      {
         return true;
      }
      return false;
   }
   if(month == 11)
   {
      // 11月の第1日曜日を計算
      int firstSunday = (7 - TimeDay(StringToTime(StringFormat("%d.%d.1", TimeYear(now), month))) % 7) % 7 + 1;
      
      if(day < firstSunday)
      {
         return true;
      }
      return false;
   }
   
   return false;
}



//+------------------------------------------------------------------+
//| オブジェクト名を保存                                               |
//+------------------------------------------------------------------+
void SaveObjectName(string name, string &nameArray[], int &counter)
{
   if(counter < ArraySize(nameArray))
   {
      nameArray[counter] = name;
      counter++;
   }
}

//+------------------------------------------------------------------+
//| 色を暗くする                                                      |
//+------------------------------------------------------------------+
color ColorDarken(color clr, int percent)
{
   // MQL4で色を分解・合成するための関数
   int r = (clr & 0xFF0000) >> 16;
   int g = (clr & 0x00FF00) >> 8;
   int b = (clr & 0x0000FF);
   
   // 各色成分を暗く
   r = MathMax(0, r - percent);
   g = MathMax(0, g - percent);
   b = MathMax(0, b - percent);
   
   // 色を再構成
   return((color)((r << 16) + (g << 8) + b));
}

//+------------------------------------------------------------------+
//| 時間範囲内かをチェック                                           |
//+------------------------------------------------------------------+
bool IsInTimeRange(int current, int start, int end)
{
   // 開始・終了が同じ = 24時間有効
   if(start == end) return true;
   
   // 通常パターン (開始 < 終了)
   if(start < end) return (current >= start && current < end);
   
   // 日をまたぐパターン (開始 > 終了)
   return (current >= start || current < end);
}

//+------------------------------------------------------------------+
//| 取引可能時間かチェック                                            |
//+------------------------------------------------------------------+
bool IsTimeAllowed(int type)
{
   // 日本時間取得
   datetime jpTime = calculate_time();
   int dayOfWeek = TimeDayOfWeek(jpTime);
   
   // 曜日の有効/無効チェック
   switch(dayOfWeek) {
      case 0: if(Sunday_Enable == OFF_MODE) return false; break;
      case 1: if(Monday_Enable == OFF_MODE) return false; break;
      case 2: if(Tuesday_Enable == OFF_MODE) return false; break;
      case 3: if(Wednesday_Enable == OFF_MODE) return false; break;
      case 4: if(Thursday_Enable == OFF_MODE) return false; break;
      case 5: if(Friday_Enable == OFF_MODE) return false; break;
      case 6: if(Saturday_Enable == OFF_MODE) return false; break;
   }
   
   // 現在時刻（分換算）
   int currentMinutes = TimeHour(jpTime) * 60 + TimeMinute(jpTime);
   
   // 共通設定の時間範囲
   int commonStart = 0, commonEnd = 0;
   if(type == OP_BUY) {
      commonStart = buy_StartHour * 60 + buy_StartMinute;
      commonEnd = buy_EndHour * 60 + buy_EndMinute;
   } else {
      commonStart = sell_StartHour * 60 + sell_StartMinute;
      commonEnd = sell_EndHour * 60 + sell_EndMinute;
   }
   
   // 曜日別設定の時間範囲
   int dayStart = 0, dayEnd = 0;
   if(type == OP_BUY) {
      switch(dayOfWeek) {
         case 0: dayStart = Sunday_Buy_StartHour * 60 + Sunday_Buy_StartMinute;
                 dayEnd = Sunday_Buy_EndHour * 60 + Sunday_Buy_EndMinute; break;
         case 1: dayStart = Monday_Buy_StartHour * 60 + Monday_Buy_StartMinute;
                 dayEnd = Monday_Buy_EndHour * 60 + Monday_Buy_EndMinute; break;
         case 2: dayStart = Tuesday_Buy_StartHour * 60 + Tuesday_Buy_StartMinute;
                 dayEnd = Tuesday_Buy_EndHour * 60 + Tuesday_Buy_EndMinute; break;
         case 3: dayStart = Wednesday_Buy_StartHour * 60 + Wednesday_Buy_StartMinute;
                 dayEnd = Wednesday_Buy_EndHour * 60 + Wednesday_Buy_EndMinute; break;
         case 4: dayStart = Thursday_Buy_StartHour * 60 + Thursday_Buy_StartMinute;
                 dayEnd = Thursday_Buy_EndHour * 60 + Thursday_Buy_EndMinute; break;
         case 5: dayStart = Friday_Buy_StartHour * 60 + Friday_Buy_StartMinute;
                 dayEnd = Friday_Buy_EndHour * 60 + Friday_Buy_EndMinute; break;
         case 6: dayStart = Saturday_Buy_StartHour * 60 + Saturday_Buy_StartMinute;
                 dayEnd = Saturday_Buy_EndHour * 60 + Saturday_Buy_EndMinute; break;
      }
   } else {
      switch(dayOfWeek) {
         case 0: dayStart = Sunday_Sell_StartHour * 60 + Sunday_Sell_StartMinute;
                 dayEnd = Sunday_Sell_EndHour * 60 + Sunday_Sell_EndMinute; break;
         case 1: dayStart = Monday_Sell_StartHour * 60 + Monday_Sell_StartMinute;
                 dayEnd = Monday_Sell_EndHour * 60 + Monday_Sell_EndMinute; break;
         case 2: dayStart = Tuesday_Sell_StartHour * 60 + Tuesday_Sell_StartMinute;
                 dayEnd = Tuesday_Sell_EndHour * 60 + Tuesday_Sell_EndMinute; break;
         case 3: dayStart = Wednesday_Sell_StartHour * 60 + Wednesday_Sell_StartMinute;
                 dayEnd = Wednesday_Sell_EndHour * 60 + Wednesday_Sell_EndMinute; break;
         case 4: dayStart = Thursday_Sell_StartHour * 60 + Thursday_Sell_StartMinute;
                 dayEnd = Thursday_Sell_EndHour * 60 + Thursday_Sell_EndMinute; break;
         case 5: dayStart = Friday_Sell_StartHour * 60 + Friday_Sell_StartMinute;
                 dayEnd = Friday_Sell_EndHour * 60 + Friday_Sell_EndMinute; break;
         case 6: dayStart = Saturday_Sell_StartHour * 60 + Saturday_Sell_StartMinute;
                 dayEnd = Saturday_Sell_EndHour * 60 + Saturday_Sell_EndMinute; break;
      }
   }
   
   // 共通設定と曜日別設定のどちらかがOKならOK（OR条件）
   bool isCommonOK = (DayTimeControl_Active == ON_MODE) && IsInTimeRange(currentMinutes, commonStart, commonEnd);
   bool isDayOK = (DayTimeControl_Active == OFF_MODE) && IsInTimeRange(currentMinutes, dayStart, dayEnd);
   
   return isCommonOK || isDayOK;
}

//+------------------------------------------------------------------+
//| ロットテーブルの初期化 - 個別指定モードをより明確に処理            |
//+------------------------------------------------------------------+
void InitializeLotTable()
{
   // 個別指定が有効な場合
   if(IndividualLotEnabled == ON_MODE)
   {
      Print("個別指定ロットモードが有効です - 設定された個別ロット値を使用します");
      g_LotTable[0] = Lot_1;
      g_LotTable[1] = Lot_2;
      g_LotTable[2] = Lot_3;
      g_LotTable[3] = Lot_4;
      g_LotTable[4] = Lot_5;
      g_LotTable[5] = Lot_6;
      g_LotTable[6] = Lot_7;
      g_LotTable[7] = Lot_8;
      g_LotTable[8] = Lot_9;
      g_LotTable[9] = Lot_10;
      g_LotTable[10] = Lot_11;
      g_LotTable[11] = Lot_12;
      g_LotTable[12] = Lot_13;
      g_LotTable[13] = Lot_14;
      g_LotTable[14] = Lot_15;
      g_LotTable[15] = Lot_16;
      g_LotTable[16] = Lot_17;
      g_LotTable[17] = Lot_18;
      g_LotTable[18] = Lot_19;
      g_LotTable[19] = Lot_20;
   }
   else
   {
      Print("マーチンゲール方式でロット計算します - 初期ロット: ", InitialLot, ", 倍率: ", LotMultiplier);
      // マーチンゲール方式でロット計算
      g_LotTable[0] = InitialLot;
      for(int i = 1; i < 20; i++)
      {
         double nextLot = g_LotTable[i-1] * LotMultiplier;
         // 小数点以下3桁で切り上げ
         nextLot = MathCeil(nextLot * 1000) / 1000;
         g_LotTable[i] = nextLot;
      }
   }
   
   // ロットテーブルの内容をログ出力（詳細版）
   string lotTableStr = "LOTテーブル詳細: \n";
   for(int i = 0; i < ArraySize(g_LotTable); i++)
   {
      lotTableStr += "レベル " + IntegerToString(i+1) + ": " + DoubleToString(g_LotTable[i], 3) + "\n";
   }
   Print(lotTableStr);
   
   // 追加: ロット使用ポリシーの明確化
   if(IndividualLotEnabled == ON_MODE)
   {
      Print("個別指定ロット使用ポリシー:");
      Print("- 初回エントリー: レベル1のロット (", DoubleToString(g_LotTable[0], 2), ")");
      Print("- ナンピン: 対応するレベルのロット (レベルに基づいて選択)");
   }
   else
   {
      Print("マーチンゲールロット使用ポリシー:");
      Print("- 初回エントリー: 初期ロット (", DoubleToString(InitialLot, 2), ")");
      Print("- ナンピン: 前回ロット x 倍率 (", DoubleToString(LotMultiplier, 2), ")");
   }
}


//+------------------------------------------------------------------+
//| ナンピン幅テーブルの初期化                                         |
//+------------------------------------------------------------------+
void InitializeNanpinSpreadTable()
{
   // 個別指定が有効な場合
   if(IndividualSpreadEnabled == ON_MODE)
   {
      g_NanpinSpreadTable[0] = Spread_1;
      g_NanpinSpreadTable[1] = Spread_2;
      g_NanpinSpreadTable[2] = Spread_3;
      g_NanpinSpreadTable[3] = Spread_4;
      g_NanpinSpreadTable[4] = Spread_5;
      g_NanpinSpreadTable[5] = Spread_6;
      g_NanpinSpreadTable[6] = Spread_7;
      g_NanpinSpreadTable[7] = Spread_8;
      g_NanpinSpreadTable[8] = Spread_9;
      g_NanpinSpreadTable[9] = Spread_10;
      g_NanpinSpreadTable[10] = Spread_11;
      g_NanpinSpreadTable[11] = Spread_12;
      g_NanpinSpreadTable[12] = Spread_13;
      g_NanpinSpreadTable[13] = Spread_14;
      g_NanpinSpreadTable[14] = Spread_15;
      g_NanpinSpreadTable[15] = Spread_16;
      g_NanpinSpreadTable[16] = Spread_17;
      g_NanpinSpreadTable[17] = Spread_18;
      g_NanpinSpreadTable[18] = Spread_19;
      g_NanpinSpreadTable[19] = Spread_20;
   }
   else
   {
      // 全て同じナンピン幅
      for(int i = 0; i < 20; i++)
      {
         g_NanpinSpreadTable[i] = NanpinSpread;
      }
   }
}


//+------------------------------------------------------------------+
//| 最後の有効なエントリー時間を取得する関数                          |
//+------------------------------------------------------------------+
datetime GetLastEntryTime(int type)
{
   datetime lastTime = 0;
   
   // まずリアルポジションの最終エントリー時間を確認
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
      {
         if(OrderType() == type && OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumber)
         {
            if(OrderOpenTime() > lastTime)
               lastTime = OrderOpenTime();
         }
      }
   }
   
   // リアルポジションがない場合や、ゴーストポジションがある場合は、ゴーストポジションの時間も確認
   if(type == OP_BUY)
   {
      for(int i = 0; i < g_GhostBuyCount; i++)
      {
         if(g_GhostBuyPositions[i].isGhost && g_GhostBuyPositions[i].openTime > lastTime)
            lastTime = g_GhostBuyPositions[i].openTime;
      }
   }
   else // OP_SELL
   {
      for(int i = 0; i < g_GhostSellCount; i++)
      {
         if(g_GhostSellPositions[i].isGhost && g_GhostSellPositions[i].openTime > lastTime)
            lastTime = g_GhostSellPositions[i].openTime;
      }
   }
   
   return lastTime;
}

//+------------------------------------------------------------------+
//| リアルポジションの平均取得価格を計算                               |
//+------------------------------------------------------------------+
double CalculateRealAveragePrice(int type)
{
   double totalLots = 0;
   double weightedPrice = 0;

   // リアルポジションの合計
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
      {
         if(OrderType() == type && OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumber)
         {
            totalLots += OrderLots();
            weightedPrice += OrderOpenPrice() * OrderLots();
         }
      }
   }

   // 平均取得価格を計算
   if(totalLots > 0)
      return weightedPrice / totalLots;
   else
      return 0;
}