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
   g_LastBuyNanpinTime = 0;
   g_LastSellNanpinTime = 0;
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
//| エントリーが許可されているかチェック                              |
//+------------------------------------------------------------------+
bool IsEntryAllowed(int side)
{
   // 偶数/奇数時間エントリーが無効な場合は常に許可
   if(!g_UseEvenOddHoursEntry)
      return true;
      
   // side: 0 = Buy, 1 = Sell
   int entryDirection = (side == 0) ? buy_EntryDirection : sell_EntryDirection;
   int hour;
   
   switch(entryDirection)
   {
      case ALWAYS:
         return true;
      
      case EVEN_HOURS:
         {
            hour = TimeHour(calculate_time());
            return (hour % 2 == 0); // 偶数時間
         }
      
      case ODD_HOURS:
         {
            hour = TimeHour(calculate_time());
            return (hour % 2 == 1); // 奇数時間
         }
      
      case OFF:
         return false;
   }
   
   return false; // デフォルト戻り値
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
//| エントリー可能時間かどうかをチェック                              |
//+------------------------------------------------------------------+
bool IsTimeAllowed(int type)
{
   // 時間制御が無効の場合はいつでも可能
   if(TimeControl_Active == OFF_MODE)
      return true;
      
   // 日本時間を取得
   datetime jpTime = calculate_time();
   
   // 曜日チェック
   int dayOfWeek = TimeDayOfWeek(jpTime);
   
   if((dayOfWeek == 0 && Sunday_Enable == OFF_MODE) ||
      (dayOfWeek == 1 && Monday_Enable == OFF_MODE) ||
      (dayOfWeek == 2 && Tuesday_Enable == OFF_MODE) ||
      (dayOfWeek == 3 && Wednesday_Enable == OFF_MODE) ||
      (dayOfWeek == 4 && Thursday_Enable == OFF_MODE) ||
      (dayOfWeek == 5 && Friday_Enable == OFF_MODE) ||
      (dayOfWeek == 6 && Saturday_Enable == OFF_MODE))
   {
      return false;
   }
   
   // 時間帯チェック
   int hour = TimeHour(jpTime);
   int minute = TimeMinute(jpTime);
   int currentTimeInMinutes = hour * 60 + minute;
   
   if(type == OP_BUY)
   {
      int startTimeInMinutes = buy_StartHour * 60 + buy_StartMinute;
      int endTimeInMinutes = buy_EndHour * 60 + buy_EndMinute;
      
      // 開始・終了時刻が同じ場合は24時間稼働と判断
      if(buy_StartHour == buy_EndHour && buy_StartMinute == buy_EndMinute)
         return true;
      
      // 日をまたがない場合 (開始時間 < 終了時間)
      if(startTimeInMinutes < endTimeInMinutes)
      {
         // 現在時刻が開始時刻以上、終了時刻未満であればtrue
         return (currentTimeInMinutes >= startTimeInMinutes && currentTimeInMinutes < endTimeInMinutes);
      }
      // 日をまたぐ場合 (開始時間 > 終了時間)
      else
      {
         // 現在時刻が開始時刻以上、または終了時刻未満であればtrue
         return (currentTimeInMinutes >= startTimeInMinutes || currentTimeInMinutes < endTimeInMinutes);
      }
   }
   else // OP_SELL
   {
      int startTimeInMinutes = sell_StartHour * 60 + sell_StartMinute;
      int endTimeInMinutes = sell_EndHour * 60 + sell_EndMinute;
      
      // 開始・終了時刻が同じ場合は24時間稼働と判断
      if(sell_StartHour == sell_EndHour && sell_StartMinute == sell_EndMinute)
         return true;
      
      // 日をまたがない場合 (開始時間 < 終了時間)
      if(startTimeInMinutes < endTimeInMinutes)
      {
         // 現在時刻が開始時刻以上、終了時刻未満であればtrue
         return (currentTimeInMinutes >= startTimeInMinutes && currentTimeInMinutes < endTimeInMinutes);
      }
      // 日をまたぐ場合 (開始時間 > 終了時間)
      else
      {
         // 現在時刻が開始時刻以上、または終了時刻未満であればtrue
         return (currentTimeInMinutes >= startTimeInMinutes || currentTimeInMinutes < endTimeInMinutes);
      }
   }
}

//+------------------------------------------------------------------+
//| ロットテーブルの初期化                                             |
//+------------------------------------------------------------------+
void InitializeLotTable()
{
   // 個別指定が有効な場合
   if(IndividualLotEnabled == ON_MODE)
   {
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