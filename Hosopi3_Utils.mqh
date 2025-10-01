//+------------------------------------------------------------------+
//|                 Hosopi 3 - ユーティリティ関数                     |
//|                         Copyright 2025                           |
//|                    MQL4/MQL5 共通化バージョン                     |
//+------------------------------------------------------------------+
#include "Hosopi3_Defines.mqh"
#include "Hosopi3_Compat.mqh"

//+------------------------------------------------------------------+
//| MQL4/MQL5 互換性のための定義                                      |
//+------------------------------------------------------------------+
#ifdef __MQL5__
   #include <Trade\Trade.mqh>
   #include <Trade\PositionInfo.mqh>
   #include <Trade\OrderInfo.mqh>
   CTrade         g_trade;
   CPositionInfo  g_position;
   COrderInfo     g_order;
#endif

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
//| Manager.mqhで使用される関数実装                                   |
//+------------------------------------------------------------------+

// アクティブなリアルポジション数を取得
int GetActivePositionCount(int type)
{
   int count = 0;
   #ifdef __MQL5__
      for(int i = PositionsTotal() - 1; i >= 0; i--)
      {
         if(PositionGetTicket(i) > 0)
         {
            if(PositionGetString(POSITION_SYMBOL) == Symbol() &&
               PositionGetInteger(POSITION_MAGIC) == MagicNumber)
            {
               int posType = (int)PositionGetInteger(POSITION_TYPE);
               if(posType == type) count++;
            }
         }
      }
   #else
      for(int i = OrdersTotal() - 1; i >= 0; i--)
      {
         if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
         {
            if(OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumber)
            {
               if(OrderType() == type) count++;
            }
         }
      }
   #endif
   return count;
}

// アクティブなゴーストポジション数を取得
int GetActiveGhostPositionCount(int type)
{
   int count = 0;
   int maxIndex = MathMin(MAX_GHOST_POSITIONS, 40); // 安全な上限設定
   
   if(type == OP_BUY)
   {
      for(int i = 0; i < maxIndex; i++)
      {
         if(g_GhostBuyPositions[i].isGhost) count++;
      }
   }
   else if(type == OP_SELL)
   {
      for(int i = 0; i < maxIndex; i++)
      {
         if(g_GhostSellPositions[i].isGhost) count++;
      }
   }
   return count;
}

// Manager.mqhで使用される関数
int combined_position_count(int type) 
{
   int realCount = GetActivePositionCount(type);
   int ghostCount = GetActiveGhostPositionCount(type);
   return realCount + ghostCount;
}

double GetLastCombinedPositionLot(int type) 
{
   // 最後のポジションのロットサイズを取得（リアルとゴーストの両方から）
   double lastLot = 0.0;
   datetime lastTime = 0;
   string debugInfo = "GetLastCombinedPositionLot(" + IntegerToString(type) + "):";
   
   // リアルポジションから最後のロットを確認
   #ifdef __MQL5__
      for(int i = PositionsTotal() - 1; i >= 0; i--)
      {
         if(PositionGetTicket(i) > 0)
         {
            if(PositionGetString(POSITION_SYMBOL) == Symbol() &&
               PositionGetInteger(POSITION_MAGIC) == MagicNumber)
            {
               int posType = (int)PositionGetInteger(POSITION_TYPE);
               if(posType == type)
               {
                  datetime openTime = (datetime)PositionGetInteger(POSITION_TIME);
                  if(openTime > lastTime)
                  {
                     lastTime = openTime;
                     lastLot = PositionGetDouble(POSITION_VOLUME);
                     // リアルポジションの最終ロットを取得
                  }
               }
            }
         }
      }
   #else
      for(int i = OrdersTotal() - 1; i >= 0; i--)
      {
         if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
         {
            if(OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumber)
            {
               if(OrderType() == type)
               {
                  datetime openTime = OrderOpenTime();
                  if(openTime > lastTime)
                  {
                     lastTime = openTime;
                     lastLot = OrderLots();
                  }
               }
            }
         }
      }
   #endif
   
   // ゴーストポジションからも最後のロットを確認
   if(type == OP_BUY)
   {
      int maxIndex = MathMin(MAX_GHOST_POSITIONS, 40);
      for(int i = 0; i < maxIndex; i++)
      {
         if(g_GhostBuyPositions[i].isGhost)
         {
            if(g_GhostBuyPositions[i].openTime > lastTime)
            {
               lastTime = g_GhostBuyPositions[i].openTime;
               lastLot = g_GhostBuyPositions[i].lot;
               // ゴーストBUYの最終ロットを取得
            }
         }
      }
   }
   else
   {
      int maxIndex = MathMin(MAX_GHOST_POSITIONS, 40);
      for(int i = 0; i < maxIndex; i++)
      {
         if(g_GhostSellPositions[i].isGhost)
         {
            if(g_GhostSellPositions[i].openTime > lastTime)
            {
               lastTime = g_GhostSellPositions[i].openTime;
               lastLot = g_GhostSellPositions[i].lot;
               // ゴーストSELLの最終ロットを取得
            }
         }
      }
   }
   
   return lastLot > 0 ? lastLot : 0.01;
}

double GetLastCombinedPositionPrice(int type) 
{
   // 最後のポジションの価格を取得（リアルとゴーストの両方から）
   double lastPrice = 0.0;
   datetime lastTime = 0;
   
   // リアルポジションから最後の価格を確認
   #ifdef __MQL5__
      for(int i = PositionsTotal() - 1; i >= 0; i--)
      {
         if(PositionGetTicket(i) > 0)
         {
            if(PositionGetString(POSITION_SYMBOL) == Symbol() &&
               PositionGetInteger(POSITION_MAGIC) == MagicNumber)
            {
               int posType = (int)PositionGetInteger(POSITION_TYPE);
               if(posType == type)
               {
                  datetime openTime = (datetime)PositionGetInteger(POSITION_TIME);
                  if(openTime > lastTime)
                  {
                     lastTime = openTime;
                     lastPrice = PositionGetDouble(POSITION_PRICE_OPEN);
                  }
               }
            }
         }
      }
   #else
      for(int i = OrdersTotal() - 1; i >= 0; i--)
      {
         if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
         {
            if(OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumber)
            {
               if(OrderType() == type)
               {
                  datetime openTime = OrderOpenTime();
                  if(openTime > lastTime)
                  {
                     lastTime = openTime;
                     lastPrice = OrderOpenPrice();
                  }
               }
            }
         }
      }
   #endif
   
   // ゴーストポジションからも最後の価格を確認
   if(type == OP_BUY)
   {
      int maxIndex = MathMin(MAX_GHOST_POSITIONS, 40);
      for(int i = 0; i < maxIndex; i++)
      {
         if(g_GhostBuyPositions[i].isGhost)
         {
            if(g_GhostBuyPositions[i].openTime > lastTime)
            {
               lastTime = g_GhostBuyPositions[i].openTime;
               lastPrice = g_GhostBuyPositions[i].openPrice;
            }
         }
      }
   }
   else
   {
      int maxIndex = MathMin(MAX_GHOST_POSITIONS, 40);
      for(int i = 0; i < maxIndex; i++)
      {
         if(g_GhostSellPositions[i].isGhost)
         {
            if(g_GhostSellPositions[i].openTime > lastTime)
            {
               lastTime = g_GhostSellPositions[i].openTime;
               lastPrice = g_GhostSellPositions[i].openPrice;
            }
         }
      }
   }
   
   return lastPrice;
}
void CleanupAndRebuildGhostObjects() 
{
    ClearGhostObjects();
    DisplayAllGhostEntryPoints();
    DisplayGhostInfo();
}

void OnTimerHandler() 
{
    // タイマーイベントの処理（必要に応じて実装）
}

void ProcessStrategyLogic()
{
    // インジケーター戦略が有効でない場合でも、常時エントリーが有効なら処理を継続
    if(!g_EnableIndicatorsEntry && !IsConstantEntryEnabled())
        return;
    
    // バックテスト時は頻度を下げる
    static datetime lastProcessTime = 0;
    bool isTesting = IsTesting();
    int processInterval = isTesting ? 60 : 1; // バックテスト時は60秒間隔
    
    if(TimeCurrent() - lastProcessTime < processInterval)
        return;
    
    lastProcessTime = TimeCurrent();
    
    // 戦略システムの更新
    UpdateStrategySystem();
    
    // Buy側とSell側のエントリー判定
    // インジケーター戦略が有効な場合のみ処理
    if(g_EnableIndicatorsEntry)
    {
        ProcessRealEntries(0); // Buy
        ProcessRealEntries(1); // Sell
    }

    // 常時エントリー戦略が有効な場合の処理
    if(IsConstantEntryEnabled())
    {
        ProcessConstantEntries();
    }
}

void CheckLimitTakeProfitExecutions() 
{
    // 利確処理のチェック（TakeProfit.mqhで実装済み）
}

void ResetGhostClosedFlags() 
{
    g_BuyGhostClosed = false;
    g_SellGhostClosed = false;
    g_BuyClosedRecently = false;
    g_SellClosedRecently = false;
}

void RecreateGhostEntryPoints() 
{
    DisplayAllGhostEntryPoints();
}

void RecreateValidGhostLines() 
{
    // 有効なゴーストラインの再作成
    DisplayAllGhostEntryPoints();
}

void DeleteAllEntryPoints() 
{
    DeleteObjectsByPrefix(g_ObjectPrefix + "GhostArrow_");
}

void ResetSpecificGhost(int type) 
{
    ResetGhostPositions(type);
}
bool IsConstantEntryEnabled()
{
    return (ConstantEntryStrategy != CONSTANT_ENTRY_DISABLED);
}

// 常時エントリー用ポジション存在チェック（指定した側のポジションがあるかどうか）
bool HasPositions(int operationType)
{
    // リアルポジションをチェック
    int realCount = position_count(operationType);

    // ゴーストポジションをチェック
    int ghostCount = ghost_position_count(operationType);

    // 指定した側のポジションがある場合はtrueを返す
    return (realCount > 0 || ghostCount > 0);
}

// ローソク足チェック関数を削除（ノーポジならどんどんエントリーに変更）
bool ShouldProcessRealEntry(int side)
{
    // インジケーター戦略が有効な場合のみチェック
    if(!g_EnableIndicatorsEntry)
        return false;

    // 戦略評価関数を呼び出し
    return EvaluateStrategyForEntry(side);
}

// 常時エントリー処理関数
void ProcessConstantEntries()
{
    // 常時エントリーが有効でない場合は終了
    if(!IsConstantEntryEnabled())
        return;

    // 自動売買が有効でない場合は終了
    if(!g_AutoTrading)
        return;

    // ロングエントリーの処理
    if(ConstantEntryStrategy == CONSTANT_ENTRY_LONG || ConstantEntryStrategy == CONSTANT_ENTRY_BOTH)
    {
        ProcessConstantEntry(OP_BUY);
    }

    // ショートエントリーの処理
    if(ConstantEntryStrategy == CONSTANT_ENTRY_SHORT || ConstantEntryStrategy == CONSTANT_ENTRY_BOTH)
    {
        ProcessConstantEntry(OP_SELL);
    }
}

// 常時エントリー個別処理関数
void ProcessConstantEntry(int operationType)
{
    // ★ 重要：Buy側はBuyポジションのみチェック、Sell側はSellポジションのみチェック
    if(HasPositions(operationType))
    {
        return;
    }

    // ローソク足チェックは削除 - ノーポジならどんどんエントリー

    // 時間制限チェック（初回エントリーのみ）
    if(!IsInitialEntryTimeAllowed(operationType))
        return;

    // ポジション保護モードチェック
    int side = (operationType == OP_BUY) ? 0 : 1;
    if(!IsEntryAllowedByProtectionMode(side))
        return;

    // 決済後インターバルチェック
    if(!IsCloseIntervalElapsed(side))
        return;

    // 常時エントリー間隔チェック（無効化、ローソク足チェックで代替）
    // if(ConstantEntryInterval > 0) { ... }

    // エントリー実行
    double price = (operationType == OP_BUY) ? SymbolInfoDouble(Symbol(), SYMBOL_ASK) : SymbolInfoDouble(Symbol(), SYMBOL_BID);
    double lot = InitialLot;
    string comment = "常時エントリー_" + ((operationType == OP_BUY) ? "BUY" : "SELL");

    // ゴーストモードが有効な場合はゴーストエントリー
    if(g_GhostMode)
    {
        ExecuteGhostEntry(operationType, price, lot, comment, -1);
    }
    else
    {
        // リアルエントリー処理はManager.mqhの関数を使用
        ExecuteRealEntry(operationType, comment);
    }
}

// Table.mqhで使用される関数
double CalculateCombinedProfit(int type) 
{
   double totalProfit = 0.0;
   double realProfit = 0.0;
   double ghostProfit = 0.0;
   
   // リアルポジションの利益を計算
   #ifdef __MQL5__
      for(int i = PositionsTotal() - 1; i >= 0; i--)
      {
         if(PositionSelectByTicket(PositionGetTicket(i)))
         {
            if(PositionGetSymbol(i) == Symbol() && PositionGetInteger(POSITION_MAGIC) == MagicNumber)
            {
               if((int)PositionGetInteger(POSITION_TYPE) == type)
               {
                  double posProfit = PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
                  realProfit += posProfit;
               }
            }
         }
      }
   #else
      for(int i = OrdersTotal() - 1; i >= 0; i--)
      {
         if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
         {
            if(OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumber)
            {
               if(OrderType() == type)
               {
                  double orderProfit = OrderProfit() + OrderSwap() + OrderCommission();
                  realProfit += orderProfit;
               }
            }
         }
      }
   #endif
   
   // ゴーストポジションの利益を追加
   ghostProfit = CalculateGhostProfit(type);
   totalProfit = realProfit + ghostProfit;
   
   // 合計利益計算完了
   
   return totalProfit;
}

// TakeProfit.mqhで使用される関数
void DeleteGhostLinesAndPreventRecreation(int operationType) 
{
    string prefix = (operationType == OP_BUY) ? "GhostLineBuy" : "GhostLineSell";
    DeleteObjectsByPrefix(g_ObjectPrefix + prefix);
}

// Ghost関数は各専用ファイルで実装済み

void DeleteAllGhostObjectsByType(int type) 
{
    string typeStr = (type == OP_BUY) ? "0" : "1";
    DeleteObjectsByPrefix(g_ObjectPrefix + "GhostArrow_" + typeStr);
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
   
#ifdef __MQL5__
   MqlDateTime dt;
   TimeToStruct(now, dt);
   int month = dt.mon;
   int day = dt.day;
   int year = dt.year;
   int dayOfWeek = dt.day_of_week;
#else
   int month = TimeMonth(now);
   int day = TimeDay(now);
   int year = TimeYear(now);
   int dayOfWeek = TimeDayOfWeek(now);
#endif
   
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
      string dateStr = StringFormat("%d.%d.1", year, month);
      datetime firstDay = StringToTime(dateStr);
      
#ifdef __MQL5__
      MqlDateTime firstDayDt;
      TimeToStruct(firstDay, firstDayDt);
      int firstDayOfWeek = firstDayDt.day_of_week;
#else
      int firstDayOfWeek = TimeDayOfWeek(firstDay);
#endif
      
      int firstSunday = (7 - firstDayOfWeek) % 7 + 1;
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
      string dateStr = StringFormat("%d.%d.1", year, month);
      datetime firstDay = StringToTime(dateStr);
      
#ifdef __MQL5__
      MqlDateTime firstDayDt;
      TimeToStruct(firstDay, firstDayDt);
      int firstDayOfWeek = firstDayDt.day_of_week;
#else
      int firstDayOfWeek = TimeDayOfWeek(firstDay);
#endif
      
      int firstSunday = (7 - firstDayOfWeek) % 7 + 1;
      
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
   // 色を分解・合成するための関数
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
//| IsInitialEntryTimeAllowed関数を高速化（キャッシュ対応版）        |
//+------------------------------------------------------------------+
bool IsInitialEntryTimeAllowed(int type)
{
   // 処理対象のインデックスを決定
   int typeIndex = (type == OP_BUY) ? 0 : 1;
   
   // 現在時刻を取得
   datetime currentTime = TimeCurrent();
   
   // バックテスト中の場合は、より長い間隔でキャッシュを利用
#ifdef __MQL5__
   int cacheInterval = (bool)MQLInfoInteger(MQL_TESTER) ? 3600 : 60;
#else
   int cacheInterval = IsTesting() ? 3600 : 60;
#endif
   
   // 前回のチェックから一定時間経過していない場合はキャッシュを使用
   if(currentTime - g_LastInitialTimeAllowedCheckTime[typeIndex] < cacheInterval)
   {
      return g_InitialTimeAllowedCache[typeIndex];
   }
   
   // 時間が経過したら再チェック
   g_LastInitialTimeAllowedCheckTime[typeIndex] = currentTime;
   
   // 日本時間取得
   datetime jpTime = calculate_time();
   
#ifdef __MQL5__
   MqlDateTime dt;
   TimeToStruct(jpTime, dt);
   int dayOfWeek = dt.day_of_week;
   int hour = dt.hour;
   int minute = dt.min;
#else
   int dayOfWeek = TimeDayOfWeek(jpTime);
   int hour = TimeHour(jpTime);
   int minute = TimeMinute(jpTime);
#endif
   
   // 曜日別ポジション制御が有効な場合のみ曜日チェック
   if(EnablePositionByDay) {
      // 曜日別ポジション許可チェック
      bool dayAllowed = false;
      switch(dayOfWeek) {
         case 0: dayAllowed = AllowSundayPosition; break;
         case 1: dayAllowed = AllowMondayPosition; break;
         case 2: dayAllowed = AllowTuesdayPosition; break;
         case 3: dayAllowed = AllowWednesdayPosition; break;
         case 4: dayAllowed = AllowThursdayPosition; break;
         case 5: dayAllowed = AllowFridayPosition; break;
         case 6: dayAllowed = AllowSaturdayPosition; break;
      }
      
      if(!dayAllowed) {
         g_InitialTimeAllowedCache[typeIndex] = false;
         return false;
      }
   }
   
   // 曜日の有効/無効チェック（既存の時間帯設定）
   switch(dayOfWeek) {
      case 0: if(Sunday_Enable == OFF_MODE) { g_InitialTimeAllowedCache[typeIndex] = false; return false; } break;
      case 1: if(Monday_Enable == OFF_MODE) { g_InitialTimeAllowedCache[typeIndex] = false; return false; } break;
      case 2: if(Tuesday_Enable == OFF_MODE) { g_InitialTimeAllowedCache[typeIndex] = false; return false; } break;
      case 3: if(Wednesday_Enable == OFF_MODE) { g_InitialTimeAllowedCache[typeIndex] = false; return false; } break;
      case 4: if(Thursday_Enable == OFF_MODE) { g_InitialTimeAllowedCache[typeIndex] = false; return false; } break;
      case 5: if(Friday_Enable == OFF_MODE) { g_InitialTimeAllowedCache[typeIndex] = false; return false; } break;
      case 6: if(Saturday_Enable == OFF_MODE) { g_InitialTimeAllowedCache[typeIndex] = false; return false; } break;
   }
   
   // 現在時刻（分換算）
   int currentMinutes = hour * 60 + minute;
   
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
   
   // 結果をキャッシュに保存して返す
   g_InitialTimeAllowedCache[typeIndex] = isCommonOK || isDayOK;
   
   return g_InitialTimeAllowedCache[typeIndex];
}

//+------------------------------------------------------------------+
//| ロットテーブルの初期化                                            |
//+------------------------------------------------------------------+
void InitializeLotTable()
{
   // 個別指定が有効な場合
   if(IndividualLotEnabled == ON_MODE)
   {
      // 個別指定ロットモードが有効
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
      // 追加の20-40のロットを設定
      g_LotTable[20] = Lot_21;
      g_LotTable[21] = Lot_22;
      g_LotTable[22] = Lot_23;
      g_LotTable[23] = Lot_24;
      g_LotTable[24] = Lot_25;
      g_LotTable[25] = Lot_26;
      g_LotTable[26] = Lot_27;
      g_LotTable[27] = Lot_28;
      g_LotTable[28] = Lot_29;
      g_LotTable[29] = Lot_30;
      g_LotTable[30] = Lot_31;
      g_LotTable[31] = Lot_32;
      g_LotTable[32] = Lot_33;
      g_LotTable[33] = Lot_34;
      g_LotTable[34] = Lot_35;
      g_LotTable[35] = Lot_36;
      g_LotTable[36] = Lot_37;
      g_LotTable[37] = Lot_38;
      g_LotTable[38] = Lot_39;
      g_LotTable[39] = Lot_40;
   }
   else
   {
      // マーチンゲール方式でロット計算
      double lotStep = MarketInfo(_Symbol, MODE_LOTSTEP);
      double lotMin = MarketInfo(_Symbol, MODE_MINLOT);
      double lotMax = MarketInfo(_Symbol, MODE_MAXLOT);

      g_LotTable[0] = InitialLot;
      for(int i = 1; i < 40; i++) // 40に拡張
      {
         double nextLot = g_LotTable[i-1] * LotMultiplier;

         // ブローカーのロットステップに合わせて正規化
         nextLot = MathRound(nextLot / lotStep) * lotStep;
         if(nextLot < lotMin) nextLot = lotMin;
         if(nextLot > lotMax) nextLot = lotMax;

         g_LotTable[i] = nextLot;
      }
   }
   
   // ロットテーブル初期化完了
   
   // ロット使用ポリシー設定完了
}

//+------------------------------------------------------------------+
//| ナンピン幅テーブルの初期化                                        |
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
      // 追加の20-40のナンピン幅を設定
      g_NanpinSpreadTable[20] = Spread_21;
      g_NanpinSpreadTable[21] = Spread_22;
      g_NanpinSpreadTable[22] = Spread_23;
      g_NanpinSpreadTable[23] = Spread_24;
      g_NanpinSpreadTable[24] = Spread_25;
      g_NanpinSpreadTable[25] = Spread_26;
      g_NanpinSpreadTable[26] = Spread_27;
      g_NanpinSpreadTable[27] = Spread_28;
      g_NanpinSpreadTable[28] = Spread_29;
      g_NanpinSpreadTable[29] = Spread_30;
      g_NanpinSpreadTable[30] = Spread_31;
      g_NanpinSpreadTable[31] = Spread_32;
      g_NanpinSpreadTable[32] = Spread_33;
      g_NanpinSpreadTable[33] = Spread_34;
      g_NanpinSpreadTable[34] = Spread_35;
      g_NanpinSpreadTable[35] = Spread_36;
      g_NanpinSpreadTable[36] = Spread_37;
      g_NanpinSpreadTable[37] = Spread_38;
      g_NanpinSpreadTable[38] = Spread_39;
      g_NanpinSpreadTable[39] = Spread_40;
   }
   else
   {
      // 全て同じナンピン幅
      for(int i = 0; i < 40; i++) // 40に拡張
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
#ifdef __MQL5__
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(g_position.SelectByIndex(i))
      {
         // マジックナンバーが0の場合は全ポジションをチェック
         bool shouldCheck = (MagicNumber == 0) ? 
            (g_position.PositionType() == (ENUM_POSITION_TYPE)type && g_position.Symbol() == Symbol()) :
            (g_position.PositionType() == (ENUM_POSITION_TYPE)type && g_position.Symbol() == Symbol() && g_position.Magic() == MagicNumber);
         
         if(shouldCheck)
         {
            if(g_position.Time() > lastTime)
               lastTime = g_position.Time();
         }
      }
   }
#else
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
      {
         // マジックナンバーが0の場合は全ポジションをチェック
         bool shouldCheck = (MagicNumber == 0) ?
            (OrderType() == type && OrderSymbol() == Symbol()) :
            (OrderType() == type && OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumber);
         
         if(shouldCheck)
         {
            if(OrderOpenTime() > lastTime)
               lastTime = OrderOpenTime();
         }
      }
   }
#endif

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
#ifdef __MQL5__
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(g_position.SelectByIndex(i))
      {
         if(g_position.PositionType() == (ENUM_POSITION_TYPE)type && 
            g_position.Symbol() == Symbol() && 
            g_position.Magic() == MagicNumber)
         {
            totalLots += g_position.Volume();
            weightedPrice += g_position.PriceOpen() * g_position.Volume();
         }
      }
   }
#else
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
#endif

   // 平均取得価格を計算
   if(totalLots > 0)
      return weightedPrice / totalLots;
   else
      return 0;
}

//+------------------------------------------------------------------+
//| ポジション保護モードの確認関数                                    |
//+------------------------------------------------------------------+
bool IsEntryAllowedByProtectionMode(int side)
{
   // 保護モードがOFFの場合は常に許可
   if(PositionProtection == PROTECTION_OFF)
      return true;

   // 保護モードがONの場合、反対側のポジションがあれば禁止
   int oppositeType = (side == 0) ? OP_SELL : OP_BUY;
   
   // リアルポジションのチェック
   int realCount = position_count(oppositeType);
   
   // ゴーストポジションのチェック
   int ghostCount = ghost_position_count(oppositeType);
   
   // 反対側にポジションがある場合は禁止
   if(realCount > 0 || ghostCount > 0)
   {
      return false;
   }
   
   return true;
}

//+------------------------------------------------------------------+
//| 決済後インターバルチェック関数                                    |
//+------------------------------------------------------------------+
bool IsCloseIntervalElapsed(int side)
{
   // 決済後インターバル機能が無効の場合は常に許可
   if(!EnableCloseInterval || CloseInterval <= 0)
      return true;
      
   datetime currentTime = TimeCurrent();
   
   if(side == 0) // Buy側のチェック
   {
      // 最近Buy側が決済されたフラグがONの場合
      if(g_BuyClosedRecently)
      {
         // 経過時間を計算
         int elapsedMinutes = (int)((currentTime - g_BuyClosedTime) / 60);
         
         // インターバル時間が経過していない場合
         if(elapsedMinutes < CloseInterval)
         {
            // Buy側決済後インターバル中
            return false;
         }
         
         // インターバル時間が経過したのでフラグをリセット
         g_BuyClosedRecently = false;
      }
   }
   else // Sell側のチェック
   {
      // 最近Sell側が決済されたフラグがONの場合
      if(g_SellClosedRecently)
      {
         // 経過時間を計算
         int elapsedMinutes = (int)((currentTime - g_SellClosedTime) / 60);
         
         // インターバル時間が経過していない場合
         if(elapsedMinutes < CloseInterval)
         {
            // Sell側決済後インターバル中
            return false;
         }
         
         // インターバル時間が経過したのでフラグをリセット
         g_SellClosedRecently = false;
      }
   }
   
   return true;
}

//+------------------------------------------------------------------+
//| ポジション保護モードのテキスト取得関数                             |
//+------------------------------------------------------------------+
string GetProtectionModeText()
{
   if(PositionProtection == PROTECTION_OFF)
      return "両建て許可";
   else
      return "単方向のみ許可";
}

//+------------------------------------------------------------------+
//| 平均取得価格計算関数                                              |
//+------------------------------------------------------------------+
double CalculateCombinedAveragePrice(int type)
{
   // リアルポジションがある場合
   int realPositionCount = position_count(type);
   if(realPositionCount > 0)
   {
      // 計算モードに基づいて処理
      if(AvgPriceCalculationMode == REAL_POSITIONS_ONLY)
      {
         // リアルポジションのみの平均価格を計算
         return CalculateRealAveragePrice(type);
      }
   }

   // 以下は元の実装と同じ（ゴーストも含めた計算）
   double totalLots = 0;
   double weightedPrice = 0;

   // リアルポジションの合計
#ifdef __MQL5__
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(g_position.SelectByIndex(i))
      {
         if(g_position.PositionType() == (ENUM_POSITION_TYPE)type && 
            g_position.Symbol() == Symbol() && 
            g_position.Magic() == MagicNumber)
         {
            totalLots += g_position.Volume();
            weightedPrice += g_position.PriceOpen() * g_position.Volume();
         }
      }
   }
#else
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
#endif

   // リアルポジションがない場合はゴーストポジションのみで計算
   if(realPositionCount == 0)
   {
      // ゴーストポジションの合計 (有効なゴーストのみ)
      if(type == OP_BUY)
      {
         for(int i = 0; i < g_GhostBuyCount; i++)
         {
            if(g_GhostBuyPositions[i].isGhost) // 有効なゴーストのみ
            {
               totalLots += g_GhostBuyPositions[i].lots;
               weightedPrice += g_GhostBuyPositions[i].price * g_GhostBuyPositions[i].lots;
            }
         }
      }
      else // OP_SELL
      {
         for(int i = 0; i < g_GhostSellCount; i++)
         {
            if(g_GhostSellPositions[i].isGhost) // 有効なゴーストのみ
            {
               totalLots += g_GhostSellPositions[i].lots;
               weightedPrice += g_GhostSellPositions[i].price * g_GhostSellPositions[i].lots;
            }
         }
      }
   }
   // リアルポジションがあり、かつREAL_AND_GHOSTモードの場合はゴーストも含める
   else if(AvgPriceCalculationMode == REAL_AND_GHOST)
   {
      if(type == OP_BUY)
      {
         for(int i = 0; i < g_GhostBuyCount; i++)
         {
            if(g_GhostBuyPositions[i].isGhost) // 有効なゴーストのみ
            {
               totalLots += g_GhostBuyPositions[i].lots;
               weightedPrice += g_GhostBuyPositions[i].price * g_GhostBuyPositions[i].lots;
            }
         }
      }
      else // OP_SELL
      {
         for(int i = 0; i < g_GhostSellCount; i++)
         {
            if(g_GhostSellPositions[i].isGhost) // 有効なゴーストのみ
            {
               totalLots += g_GhostSellPositions[i].lots;
               weightedPrice += g_GhostSellPositions[i].price * g_GhostSellPositions[i].lots;
            }
         }
      }
   }

   // 平均取得価格を計算
   if(totalLots > 0)
      return weightedPrice / totalLots;
   else
      return 0;
}

//+------------------------------------------------------------------+
//| ポジション数をカウントする関数（position_count用）               |
//+------------------------------------------------------------------+
int position_count(int type)
{
   int count = 0;
   
#ifdef __MQL5__
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(g_position.SelectByIndex(i))
      {
         if(g_position.PositionType() == (ENUM_POSITION_TYPE)type && 
            g_position.Symbol() == Symbol() && 
            g_position.Magic() == MagicNumber)
         {
            count++;
         }
      }
   }
#else
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
      {
         if(OrderType() == type && OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumber)
         {
            count++;
         }
      }
   }
#endif
   
   return count;
}

//+------------------------------------------------------------------+
//| マジックナンバーに関係なく全ポジション数をカウントする関数         |
//+------------------------------------------------------------------+
int position_count_all(int type)
{
   int count = 0;
   
#ifdef __MQL5__
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(g_position.SelectByIndex(i))
      {
         if(g_position.PositionType() == (ENUM_POSITION_TYPE)type && 
            g_position.Symbol() == Symbol())
         {
            count++;
         }
      }
   }
#else
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
      {
         if(OrderType() == type && OrderSymbol() == Symbol())
         {
            count++;
         }
      }
   }
#endif
   
   return count;
}

//+------------------------------------------------------------------+
//| ゴーストポジション数をカウントする関数                            |
//+------------------------------------------------------------------+
int ghost_position_count(int type)
{
   int count = 0;
   
   if(type == OP_BUY)
   {
      int maxIndex = MathMin(g_GhostBuyCount, 40);
      for(int i = 0; i < maxIndex; i++)
      {
         if(g_GhostBuyPositions[i].isGhost)
            count++;
      }
   }
   else if(type == OP_SELL)
   {
      int maxIndex = MathMin(g_GhostSellCount, 40);
      for(int i = 0; i < maxIndex; i++)
      {
         if(g_GhostSellPositions[i].isGhost)
            count++;
      }
   }
   
   return count;
}