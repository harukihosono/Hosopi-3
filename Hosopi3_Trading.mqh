//+------------------------------------------------------------------+
//|                  Hosopi 3 - トレード関連関数                      |
//|                         Copyright 2025                           |
//+------------------------------------------------------------------+
#include "Hosopi3_Defines.mqh"

//+------------------------------------------------------------------+
//| MQL4/MQL5互換性のための価格取得関数                               |
//+------------------------------------------------------------------+
#ifdef __MQL5__
// MQL5でのAsk価格を取得
double GetAskPrice()
{
   MqlTick last_tick;
   SymbolInfoTick(Symbol(), last_tick);
   return last_tick.ask;
}

// MQL5でのBid価格を取得
double GetBidPrice()
{
   MqlTick last_tick;
   SymbolInfoTick(Symbol(), last_tick);
   return last_tick.bid;
}

#else
// MQL4での価格取得関数
double GetAskPrice()
{
   return Ask;
}

double GetBidPrice()
{
   return Bid;
}
#endif

//+------------------------------------------------------------------+
//| ポジションエントリー関数                                          |
//+------------------------------------------------------------------+
bool position_entry(int side, double lot = 0.1, int slippage = 10, int magic = 0, string comment = "")
{
   if(magic == 0) magic = MagicNumber;
   
   #ifdef __MQL5__
   // MQL5での注文処理
   MqlTradeRequest request = {};
   MqlTradeResult result = {};
   
   request.action = TRADE_ACTION_DEAL;
   request.symbol = Symbol();
   request.volume = lot;
   request.type = (side == 0) ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;
   request.price = (side == 0) ? GetAskPrice() : GetBidPrice();
   request.deviation = slippage;
   request.magic = magic;
   request.comment = comment;
   
   bool success = OrderSend(request, result);
   
   if(!success || result.retcode != TRADE_RETCODE_DONE)
   {
      Print("注文エラー: ", result.retcode, " - ", GetLastError());
      return false;
   }
   
   return true;
   
   #else
   // MQL4での注文処理
   int ticket = OrderSend(Symbol(), side, lot, (side == 0) ? GetAskPrice() : GetBidPrice(), 
                         slippage, 0, 0, comment, magic, 0, (side == 0) ? clrGreen : clrRed);
   
   if(ticket <= 0)
   {
      Print("注文エラー: ", GetLastError());
      return false;
   }
   
   return true;
   #endif
}

//+------------------------------------------------------------------+
//| ポジション決済関数                                                |
//+------------------------------------------------------------------+
bool position_close(int side, double lot = 0.0, int slippage = 10, int magic = 0)
{
   if(magic == 0) magic = MagicNumber;
   
   #ifdef __MQL5__
   // MQL5でのポジション決済
   bool found = false;
   
   // 該当するポジションを探す
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket > 0)
      {
         if(PositionGetString(POSITION_SYMBOL) == Symbol() &&
            PositionGetInteger(POSITION_MAGIC) == magic &&
            PositionGetInteger(POSITION_TYPE) == (side == 0 ? POSITION_TYPE_BUY : POSITION_TYPE_SELL))
         {
            double volume = (lot <= 0) ? PositionGetDouble(POSITION_VOLUME) : MathMin(lot, PositionGetDouble(POSITION_VOLUME));
            
            // ポジションを決済
            MqlTradeRequest request = {};
            MqlTradeResult result = {};
            
            request.action = TRADE_ACTION_DEAL;
            request.position = ticket;
            request.symbol = Symbol();
            request.volume = volume;
            request.type = (side == 0) ? ORDER_TYPE_SELL : ORDER_TYPE_BUY;
            request.price = (side == 0) ? GetBidPrice() : GetAskPrice();
            request.deviation = slippage;
            request.magic = magic;
            
            bool success = OrderSend(request, result);
            
            if(!success || result.retcode != TRADE_RETCODE_DONE)
            {
               Print("決済エラー: ", result.retcode, " - ", GetLastError());
               return false;
            }
            
            found = true;
            
            // lotが指定され、部分決済の場合はここで終了
            if(lot > 0 && lot < PositionGetDouble(POSITION_VOLUME))
               return true;
         }
      }
   }
   
   return found;
   
   #else
   // MQL4でのポジション決済
   bool result = false;
   
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
      {
         if(OrderType() == side && OrderSymbol() == Symbol() && 
            (magic == 0 || OrderMagicNumber() == magic))
         {
            double close_volume = (lot <= 0) ? OrderLots() : MathMin(lot, OrderLots());
            double close_price = (side == 0) ? GetBidPrice() : GetAskPrice();
            
            result = OrderClose(OrderTicket(), close_volume, close_price, slippage, (side == 0) ? clrRed : clrBlue);
            
            if(!result)
            {
               Print("決済エラー: ", GetLastError());
            }
            else if(lot > 0 && lot <= OrderLots())
            {
               // 部分決済が成功し、指定されたロットサイズ分を決済した場合
               return true;
            }
         }
      }
   }
   
   return result;
   #endif
}

//+------------------------------------------------------------------+
//| 全ポジション決済関数                                             |
//+------------------------------------------------------------------+
void position_all_close(int magic = 0)
{
   // BUYポジションをすべて決済
   position_close(0, 0.0, 10, magic);
   
   // SELLポジションをすべて決済
   position_close(1, 0.0, 10, magic);
}

//+------------------------------------------------------------------+
//| ポジションカウント関数                                            |
//+------------------------------------------------------------------+
int position_count(int side, int magic = 0)
{
   if(magic == 0) magic = MagicNumber;
   
   int count = 0;
   
   #ifdef __MQL5__
   // MQL5でのポジションカウント
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket > 0)
      {
         if(PositionGetString(POSITION_SYMBOL) == Symbol() &&
            (magic == 0 || PositionGetInteger(POSITION_MAGIC) == magic) &&
            PositionGetInteger(POSITION_TYPE) == (side == 0 ? POSITION_TYPE_BUY : POSITION_TYPE_SELL))
         {
            count++;
         }
      }
   }
   #else
   // MQL4でのポジションカウント
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
      {
         if(OrderType() == side && OrderSymbol() == Symbol() && 
            (magic == 0 || OrderMagicNumber() == magic))
         {
            count++;
         }
      }
   }
   #endif
   
   return count;
}

//+------------------------------------------------------------------+
//| オーダーカウント関数（保留注文のカウント）                       |
//+------------------------------------------------------------------+
int order_count(int magic = 0)
{
   if(magic == 0) magic = MagicNumber;
   
   int count = 0;
   
   #ifdef __MQL5__
   // MQL5での保留注文カウント
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      ulong ticket = OrderGetTicket(i);
      if(ticket > 0)
      {
         if(OrderGetString(ORDER_SYMBOL) == Symbol() &&
            (magic == 0 || OrderGetInteger(ORDER_MAGIC) == magic))
         {
            // 保留注文の場合のみカウント（成行注文は除外）
            ENUM_ORDER_TYPE order_type = (ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE);
            if(order_type != ORDER_TYPE_BUY && order_type != ORDER_TYPE_SELL)
            {
               count++;
            }
         }
      }
   }
   #else
   // MQL4での保留注文カウント
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
      {
         if(OrderSymbol() == Symbol() && 
            (magic == 0 || OrderMagicNumber() == magic))
         {
            int order_type = OrderType();
            if(order_type >= 2) // 2以上は保留注文（OP_BUYLIMIT, OP_BUYSTOP, OP_SELLLIMIT, OP_SELLSTOP）
            {
               count++;
            }
         }
      }
   }
   #endif
   
   return count;
}

//+------------------------------------------------------------------+
//| GetLastPositionPrice関数（修正版）- 最新ポジションの価格を確実に取得 |
//+------------------------------------------------------------------+
double GetLastPositionPrice(int type)
{
   double lastPrice = 0;
   datetime lastTime = 0;
   
   // このEAが管理するポジションのみを対象に
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
      {
         if(OrderType() == type && OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumber)
         {
            // 最も新しいポジションを探す
            if(OrderOpenTime() > lastTime)
            {
               lastTime = OrderOpenTime();
               lastPrice = OrderOpenPrice();
            }
         }
      }
   }
   
   // デバッグログ追加
   if(lastPrice > 0)
   {
      Print("最後の", type == OP_BUY ? "Buy" : "Sell", "ポジション価格: ", lastPrice, ", 時間: ", TimeToString(lastTime));
   }
   else
   {
      Print("警告: ", type == OP_BUY ? "Buy" : "Sell", "ポジションが見つかりません");
   }
   
   return lastPrice;
}

//+------------------------------------------------------------------+
//| MQL4/MQL5用の移動平均線取得関数                                  |
//+------------------------------------------------------------------+
double GetMA(string symbol, ENUM_TIMEFRAMES timeframe, int ma_period, int ma_shift,
             int ma_method, int applied_price, int shift)
{
   double ma_value = 0;
   
   #ifdef __MQL5__
   // MQL5での移動平均線取得
   int ma_handle = iMA(symbol, timeframe, ma_period, ma_shift, (ENUM_MA_METHOD)ma_method, applied_price);
   if(ma_handle != INVALID_HANDLE)
   {
      double buffer[];
      ArraySetAsSeries(buffer, true);
      if(CopyBuffer(ma_handle, 0, shift, 1, buffer) > 0)
      {
         ma_value = buffer[0];
      }
   }
   #else
   // MQL4での移動平均線取得
   ma_value = iMA(symbol, timeframe, ma_period, ma_shift, ma_method, applied_price, shift);
   #endif
   
   return ma_value;
}

//+------------------------------------------------------------------+
//| MQL4/MQL5互換のトレード許可確認関数                               |
//+------------------------------------------------------------------+
bool IsTradeAllowedCustom()
{
   #ifdef __MQL5__
   return (bool)MQLInfoInteger(MQL_TRADE_ALLOWED) && (bool)TerminalInfoInteger(TERMINAL_TRADE_ALLOWED);
   #else
   return IsTradeAllowed();
   #endif
}

//+------------------------------------------------------------------+
//| MQL4/MQL5互換のEA有効確認関数                                     |
//+------------------------------------------------------------------+
bool IsExpertEnabledCustom()
{
   #ifdef __MQL5__
   return (bool)MQLInfoInteger(MQL_TRADE_ALLOWED);
   #else
   return IsExpertEnabled();
   #endif
}