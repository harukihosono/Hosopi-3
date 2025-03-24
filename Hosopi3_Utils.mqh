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
   // 偶数/奇数時間エントリーが無効な場合はfalse
   if(!UseEvenOddHoursEntry)
      return false;
      
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
//| 曜日に応じた時間設定を取得する                                     |
//+------------------------------------------------------------------+
void GetDayTimeSettings(int dayOfWeek, int type, int &startHour, int &startMinute, int &endHour, int &endMinute)
{
   // type: 0 = Buy, 1 = Sell
   
   // 曜日別時間設定が無効な場合は共通設定を使用
   if(DayTimeControl_Active == OFF_MODE)
   {
      if(type == 0) // Buy
      {
         startHour = buy_StartHour;
         startMinute = buy_StartMinute;
         endHour = buy_EndHour;
         endMinute = buy_EndMinute;
      }
      else // Sell
      {
         startHour = sell_StartHour;
         startMinute = sell_StartMinute;
         endHour = sell_EndHour;
         endMinute = sell_EndMinute;
      }
      return;
   }
   
   // 曜日別設定を取得
   switch(dayOfWeek)
   {
      case 0: // 日曜日
         if(type == 0) // Buy
         {
            startHour = Sunday_Buy_StartHour;
            startMinute = Sunday_Buy_StartMinute;
            endHour = Sunday_Buy_EndHour;
            endMinute = Sunday_Buy_EndMinute;
         }
         else // Sell
         {
            startHour = Sunday_Sell_StartHour;
            startMinute = Sunday_Sell_StartMinute;
            endHour = Sunday_Sell_EndHour;
            endMinute = Sunday_Sell_EndMinute;
         }
         break;
         
      case 1: // 月曜日
         if(type == 0) // Buy
         {
            startHour = Monday_Buy_StartHour;
            startMinute = Monday_Buy_StartMinute;
            endHour = Monday_Buy_EndHour;
            endMinute = Monday_Buy_EndMinute;
         }
         else // Sell
         {
            startHour = Monday_Sell_StartHour;
            startMinute = Monday_Sell_StartMinute;
            endHour = Monday_Sell_EndHour;
            endMinute = Monday_Sell_EndMinute;
         }
         break;
         
      case 2: // 火曜日
         if(type == 0) // Buy
         {
            startHour = Tuesday_Buy_StartHour;
            startMinute = Tuesday_Buy_StartMinute;
            endHour = Tuesday_Buy_EndHour;
            endMinute = Tuesday_Buy_EndMinute;
         }
         else // Sell
         {
            startHour = Tuesday_Sell_StartHour;
            startMinute = Tuesday_Sell_StartMinute;
            endHour = Tuesday_Sell_EndHour;
            endMinute = Tuesday_Sell_EndMinute;
         }
         break;
         
      case 3: // 水曜日
         if(type == 0) // Buy
         {
            startHour = Wednesday_Buy_StartHour;
            startMinute = Wednesday_Buy_StartMinute;
            endHour = Wednesday_Buy_EndHour;
            endMinute = Wednesday_Buy_EndMinute;
         }
         else // Sell
         {
            startHour = Wednesday_Sell_StartHour;
            startMinute = Wednesday_Sell_StartMinute;
            endHour = Wednesday_Sell_EndHour;
            endMinute = Wednesday_Sell_EndMinute;
         }
         break;
         
      case 4: // 木曜日
         if(type == 0) // Buy
         {
            startHour = Thursday_Buy_StartHour;
            startMinute = Thursday_Buy_StartMinute;
            endHour = Thursday_Buy_EndHour;
            endMinute = Thursday_Buy_EndMinute;
         }
         else // Sell
         {
            startHour = Thursday_Sell_StartHour;
            startMinute = Thursday_Sell_StartMinute;
            endHour = Thursday_Sell_EndHour;
            endMinute = Thursday_Sell_EndMinute;
         }
         break;
         
      case 5: // 金曜日
         if(type == 0) // Buy
         {
            startHour = Friday_Buy_StartHour;
            startMinute = Friday_Buy_StartMinute;
            endHour = Friday_Buy_EndHour;
            endMinute = Friday_Buy_EndMinute;
         }
         else // Sell
         {
            startHour = Friday_Sell_StartHour;
            startMinute = Friday_Sell_StartMinute;
            endHour = Friday_Sell_EndHour;
            endMinute = Friday_Sell_EndMinute;
         }
         break;
         
      case 6: // 土曜日
         if(type == 0) // Buy
         {
            startHour = Saturday_Buy_StartHour;
            startMinute = Saturday_Buy_StartMinute;
            endHour = Saturday_Buy_EndHour;
            endMinute = Saturday_Buy_EndMinute;
         }
         else // Sell
         {
            startHour = Saturday_Sell_StartHour;
            startMinute = Saturday_Sell_StartMinute;
            endHour = Saturday_Sell_EndHour;
            endMinute = Saturday_Sell_EndMinute;
         }
         break;
         
      default: // 不明な曜日の場合は共通設定を使用
         if(type == 0) // Buy
         {
            startHour = buy_StartHour;
            startMinute = buy_StartMinute;
            endHour = buy_EndHour;
            endMinute = buy_EndMinute;
         }
         else // Sell
         {
            startHour = sell_StartHour;
            startMinute = sell_StartMinute;
            endHour = sell_EndHour;
            endMinute = sell_EndMinute;
         }
         break;
   }
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
   
   // 現在の時間と分を取得
   int hour = TimeHour(jpTime);
   int minute = TimeMinute(jpTime);
   int currentTimeInMinutes = hour * 60 + minute;
   
   // 曜日に応じた時間設定を取得
   int startHour, startMinute, endHour, endMinute;
   GetDayTimeSettings(dayOfWeek, type == OP_BUY ? 0 : 1, startHour, startMinute, endHour, endMinute);
   
   int startTimeInMinutes = startHour * 60 + startMinute;
   int endTimeInMinutes = endHour * 60 + endMinute;
   
   // 開始・終了時刻が同じ場合は24時間稼働と判断
   if(startHour == endHour && startMinute == endMinute)
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

//+------------------------------------------------------------------+
//| ロットテーブルの初期化                                             |
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
   
   // マーチンゲールモードが有効な場合、計算値と設定値の確認
   if(IndividualLotEnabled == OFF_MODE)
   {
      Print("マーチンゲール設定確認: ");
      Print("- 初期ロット: ", DoubleToString(InitialLot, 3));
      Print("- 倍率: ", DoubleToString(LotMultiplier, 2));
      
      // 計算例を表示
      double lot = InitialLot;
      string calcExample = "倍率計算例: " + DoubleToString(lot, 3);
      for(int i = 1; i < 5; i++) {
         lot = MathCeil(lot * LotMultiplier * 1000) / 1000;
         calcExample += " → " + DoubleToString(lot, 3);
      }
      Print(calcExample);
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