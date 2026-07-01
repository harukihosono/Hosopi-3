//+------------------------------------------------------------------+
//|                                          Hosopi3_TimeClose.mqh    |
//|              時間決済 ＋ 週末クローズ（ELDRA2移植）              |
//|                                                                   |
//| ・時間決済: サイドの最古建玉が指定分経過したら、そのサイドを全決済 |
//| ・週末クローズ: JST土曜の指定時刻に全ポジション決済               |
//|   （Hosopi-3の GetBrokerGMTOffset() で broker 時間へDST考慮変換）  |
//|                                                                   |
//| 入力は Hosopi3_AllParams_MQL5/MQL4.mqh「41. 時間決済・週末クローズ」|
//+------------------------------------------------------------------+
#ifndef HOSOPI3_TIMECLOSE_MQH
#define HOSOPI3_TIMECLOSE_MQH

// --- 内部状態 ---
datetime g_LastWeekendCloseCheck = 0;
datetime g_LastWeekendCloseFired = 0;
datetime g_LastTimeCloseCheck = 0;

//+------------------------------------------------------------------+
//| 指定サイドを全決済（リアル＋ゴースト）                            |
//+------------------------------------------------------------------+
void TimeClose_CloseSide(int side)
{
   MarkClosingInProgress();  // エントリー割り込み防止
   if(position_count(side) > 0)
      position_close(side);
   if(ghost_position_count(side) > 0)
      ResetSpecificGhost(side);
   CleanupLinesOnClose(side == OP_BUY ? 0 : 1);
}

//+------------------------------------------------------------------+
//| このEAの指定サイドの最古ポジション建玉時刻（無ければ0）           |
//+------------------------------------------------------------------+
datetime TimeClose_OldestOpenTime(int side)
{
   datetime oldest = 0;
#ifdef __MQL5__
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket <= 0) continue;
      if(PositionGetString(POSITION_SYMBOL) != Symbol()) continue;
      if(PositionGetInteger(POSITION_MAGIC) != MagicNumber) continue;
      int pt = (int)PositionGetInteger(POSITION_TYPE);
      if(side == OP_BUY  && pt != POSITION_TYPE_BUY)  continue;
      if(side == OP_SELL && pt != POSITION_TYPE_SELL) continue;
      datetime ot = (datetime)PositionGetInteger(POSITION_TIME);
      if(oldest == 0 || ot < oldest) oldest = ot;
   }
#else
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if(!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;
      if(OrderSymbol() != Symbol() || OrderMagicNumber() != MagicNumber) continue;
      if(OrderType() != side) continue;
      datetime ot = OrderOpenTime();
      if(oldest == 0 || ot < oldest) oldest = ot;
   }
#endif
   return oldest;
}

//+------------------------------------------------------------------+
//| 時間決済: 一定時間経過したサイドを全決済（毎tick、1秒スロットル） |
//+------------------------------------------------------------------+
void ProcessTimeClose()
{
   if(!EnableTimeClose || TimeCloseMinutes <= 0) return;

   datetime now = TimeCurrent();
   if(now - g_LastTimeCloseCheck < 1) return;
   g_LastTimeCloseCheck = now;

   long limitSec = (long)TimeCloseMinutes * 60;

   datetime oBuy = TimeClose_OldestOpenTime(OP_BUY);
   if(oBuy > 0 && now - oBuy >= limitSec)
   {
      Print("[TimeClose] Buy: 経過 ", (int)((now - oBuy) / 60), "分 >= ", TimeCloseMinutes, "分 → 全決済");
      TimeClose_CloseSide(OP_BUY);
   }

   datetime oSell = TimeClose_OldestOpenTime(OP_SELL);
   if(oSell > 0 && now - oSell >= limitSec)
   {
      Print("[TimeClose] Sell: 経過 ", (int)((now - oSell) / 60), "分 >= ", TimeCloseMinutes, "分 → 全決済");
      TimeClose_CloseSide(OP_SELL);
   }
}

//+------------------------------------------------------------------+
//| 週末クローズ: JST土曜の指定時刻に全ポジション決済                 |
//| 入力時刻は JST。GetBrokerGMTOffset() で broker 曜日/時刻へ変換    |
//+------------------------------------------------------------------+
void ProcessWeekendClose()
{
   if(!EnableWeekendClose) return;

   datetime now = TimeCurrent();  // broker time
   if(now - g_LastWeekendCloseCheck < 60) return;
   g_LastWeekendCloseCheck = now;

   // JST 入力(HHMM)をパース
   string s = WeekendCloseTime;
   if(StringLen(s) != 4) return;
   int jstHH = (int)StringToInteger(StringSubstr(s, 0, 2));
   int jstMM = (int)StringToInteger(StringSubstr(s, 2, 2));

   // JST → broker 変換（GetBrokerGMTOffset は broker のGMTオフセット。DST自動反映）
   int brokerGMT = GetBrokerGMTOffset();
   int jstToBrokerH = 9 - brokerGMT;  // 7(冬) / 6(夏)

   int jstTotalMin = jstHH * 60 + jstMM;
   int brokerTotalMin = jstTotalMin - jstToBrokerH * 60;
   int dayOffset = 0;
   while(brokerTotalMin < 0)     { brokerTotalMin += 1440; dayOffset--; }
   while(brokerTotalMin >= 1440) { brokerTotalMin -= 1440; dayOffset++; }
   int targetDOW = (6 + dayOffset + 7) % 7;  // JST土曜=6, +dayOffset
   int targetMin = brokerTotalMin;

   MqlDateTime dt;
   TimeToStruct(now, dt);
   if(dt.day_of_week != targetDOW) return;

   int nowMin = dt.hour * 60 + dt.min;
   if(nowMin < targetMin) return;

   // 同日二重発火防止
   MqlDateTime firedDt;
   TimeToStruct(g_LastWeekendCloseFired, firedDt);
   if(g_LastWeekendCloseFired > 0 &&
      firedDt.year == dt.year && firedDt.mon == dt.mon && firedDt.day == dt.day)
      return;

   Print("[WeekendClose] JST土曜 ", WeekendCloseTime, " 到達 (broker dow=", dt.day_of_week,
         " ", dt.hour, ":", dt.min, "): 全ポジション決済");

   MarkClosingInProgress();
   if(position_count(OP_BUY) > 0)  position_close(OP_BUY);
   if(position_count(OP_SELL) > 0) position_close(OP_SELL);
   ResetSpecificGhost(OP_BUY);
   ResetSpecificGhost(OP_SELL);
   CleanupLinesOnClose(0);
   CleanupLinesOnClose(1);

   g_LastWeekendCloseFired = now;
}

#endif // HOSOPI3_TIMECLOSE_MQH
