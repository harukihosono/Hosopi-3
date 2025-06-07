//+------------------------------------------------------------------+
//|                  Hosopi 3 - トレード関連関数 (最適化版)            |
//|                         Copyright 2025                           |
//|                    MQL4/MQL5 完全共通化バージョン                 |
//+------------------------------------------------------------------+
#include "Hosopi3_Defines.mqh"

//+------------------------------------------------------------------+
//| MQL4/MQL5互換性のための定義                                      |
//+------------------------------------------------------------------+
#ifdef __MQL5__
   // MQL5での定義
   #define OP_BUY  0
   #define OP_SELL 1
   #define MODE_TRADES 0
   #define SELECT_BY_POS 0
   #define MODE_TICKVALUE SYMBOL_TRADE_TICK_VALUE
   #define MODE_TICKSIZE SYMBOL_TRADE_TICK_SIZE
   #define MODE_DIGITS SYMBOL_DIGITS
   #define MODE_POINT SYMBOL_POINT
   #define MODE_BID SYMBOL_BID
   #define MODE_ASK SYMBOL_ASK
   #define MODE_SPREAD SYMBOL_SPREAD
#endif

//+------------------------------------------------------------------+
//| MQL4/MQL5互換性のための価格取得関数                               |
//+------------------------------------------------------------------+
#ifdef __MQL5__
// MQL5でのAsk価格を取得
double GetAskPrice()
{
   MqlTick last_tick;
   if(SymbolInfoTick(Symbol(), last_tick))
      return last_tick.ask;
   return 0;
}

// MQL5でのBid価格を取得
double GetBidPrice()
{
   MqlTick last_tick;
   if(SymbolInfoTick(Symbol(), last_tick))
      return last_tick.bid;
   return 0;
}

// MQL5での有効証拠金取得
double GetAccountEquity()
{
   return AccountInfoDouble(ACCOUNT_EQUITY);
}

// MQL5でのテスト中判定
bool IsTestingMode()
{
   return MQLInfoInteger(MQL_TESTER) || MQLInfoInteger(MQL_VISUAL_MODE);
}

// MQL5でのPoint取得
double GetPoint()
{
   return SymbolInfoDouble(Symbol(), SYMBOL_POINT);
}

// MQL5でのDigits取得
int GetDigits()
{
   return (int)SymbolInfoInteger(Symbol(), SYMBOL_DIGITS);
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

// MQL4での有効証拠金取得
double GetAccountEquity()
{
   return AccountEquity();
}

// MQL4でのテスト中判定
bool IsTestingMode()
{
   return IsTesting();
}

// MQL4でのPoint取得
double GetPoint()
{
   return Point;
}

// MQL4でのDigits取得
int GetDigits()
{
   return Digits;
}
#endif

// IsEquitySufficientCached 関数の高速化（バックテスト時のキャッシュ期間延長）
bool IsEquitySufficientCached()
{
   // 有効証拠金チェックが無効の場合は常にtrue
   if(EquityControl_Active == OFF_MODE) return true;
   
   // バックテスト時に毎回チェックせず、一定時間ごとにキャッシュを使用
   datetime currentTime = TimeCurrent();
   
   // バックテスト中の場合は、より長い間隔でキャッシュを利用
   int cacheInterval = IsTestingMode() ? 3600 : 60; // バックテスト中は1時間、通常は1分
   
   // 前回のチェックから一定時間経過していない場合はキャッシュを使用
   if(currentTime - g_LastEquityCheckTime < cacheInterval)
   {
      return g_EquitySufficientCache;
   }
   
   // 時間が経過したら再チェック
   g_LastEquityCheckTime = currentTime;
   
   // 現在の有効証拠金を取得
   double currentEquity = GetAccountEquity();
   
   // 最低有効証拠金チェック
   g_EquitySufficientCache = (currentEquity >= MinimumEquity);
   
   if(!g_EquitySufficientCache)
   {
      Print(StringFormat("エントリー停止: 有効証拠金 %.2f が最低基準 %.2f を下回りました", 
                         currentEquity, MinimumEquity));
   }
   
   return g_EquitySufficientCache;
}

//+------------------------------------------------------------------+
//| ポジションエントリー関数（最適化版・共通化）                      |
//+------------------------------------------------------------------+
bool position_entry(int side, double lot = 0.1, int slippage = 10, int magic = 0, string comment = "")
{
   // 高頻度呼び出し対策: キャッシュを使用したエントリー制限チェック
   if(!IsEquitySufficientCached())
   {
      return false;
   }

   if(magic == 0) magic = MagicNumber;
   
   #ifdef __MQL5__
   // MQL5での注文処理
   MqlTradeRequest request = {};
   MqlTradeResult result = {};
   
   request.action = TRADE_ACTION_DEAL;
   request.symbol = Symbol();
   request.volume = lot;
   request.type = (side == OP_BUY) ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;
   request.price = (side == OP_BUY) ? GetAskPrice() : GetBidPrice();
   request.deviation = slippage;
   request.magic = magic;
   request.comment = comment;
   request.type_filling = OrderFillingMode; // フィリングモードを使用
   
   bool success = OrderSend(request, result);
   
   if(!success || result.retcode != TRADE_RETCODE_DONE)
   {
      Print("注文エラー: ", result.retcode, " - ", GetLastError());
      return false;
   }
   
   return true;
   
   #else
   // MQL4での注文処理
   int ticket = OrderSend(Symbol(), side, lot, (side == OP_BUY) ? GetAskPrice() : GetBidPrice(), 
                         slippage, 0, 0, comment, magic, 0, (side == OP_BUY) ? clrGreen : clrRed);
   
   if(ticket <= 0)
   {
      Print("注文エラー: ", GetLastError());
      return false;
   }
   
   return true;
   #endif
}

//+------------------------------------------------------------------+
//| ポジション決済関数（共通化）                                      |
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
            PositionGetInteger(POSITION_TYPE) == (side == OP_BUY ? POSITION_TYPE_BUY : POSITION_TYPE_SELL))
         {
            double volume = (lot <= 0) ? PositionGetDouble(POSITION_VOLUME) : MathMin(lot, PositionGetDouble(POSITION_VOLUME));
            
            // ポジションを決済
            MqlTradeRequest request = {};
            MqlTradeResult result = {};
            
            request.action = TRADE_ACTION_DEAL;
            request.position = ticket;
            request.symbol = Symbol();
            request.volume = volume;
            request.type = (side == OP_BUY) ? ORDER_TYPE_SELL : ORDER_TYPE_BUY;
            request.price = (side == OP_BUY) ? GetBidPrice() : GetAskPrice();
            request.deviation = slippage;
            request.magic = magic;
            request.type_filling = OrderFillingMode; // フィリングモードを使用
            
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
            double close_price = (side == OP_BUY) ? GetBidPrice() : GetAskPrice();
            
            result = OrderClose(OrderTicket(), close_volume, close_price, slippage, (side == OP_BUY) ? clrRed : clrBlue);
            
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
//| 成行注文数カウント関数（MQL5専用）                                |
//+------------------------------------------------------------------+
#ifdef __MQL5__
int pending_order_count(int magic = 0)
{
   if(magic == 0) magic = MagicNumber;
   
   int count = 0;
   
   // すべての注文をチェック
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      ulong ticket = OrderGetTicket(i);
      if(ticket > 0)
      {
         if(OrderGetString(ORDER_SYMBOL) == Symbol() &&
            OrderGetInteger(ORDER_MAGIC) == magic)
         {
            // 成行注文タイプかチェック
            ENUM_ORDER_TYPE order_type = (ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE);
            if(order_type == ORDER_TYPE_BUY || order_type == ORDER_TYPE_SELL)
            {
               count++;
            }
         }
      }
   }
   
   return count;
}
#endif

//+------------------------------------------------------------------+
//| ポジションカウント関数（共通化）                                  |
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
            PositionGetInteger(POSITION_TYPE) == (side == OP_BUY ? POSITION_TYPE_BUY : POSITION_TYPE_SELL))
         {
            count++;
         }
      }
   }
   
   // MQL5では成行注文もカウントに含める
   count += pending_order_count(magic);
   
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
//| GetLastPositionPrice関数（共通化）                                |
//+------------------------------------------------------------------+
double GetLastPositionPrice(int type)
{
   double lastPrice = 0;
   datetime lastTime = 0;
   
   #ifdef __MQL5__
   // MQL5でのポジション価格取得
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket > 0)
      {
         if(PositionGetString(POSITION_SYMBOL) == Symbol() &&
            PositionGetInteger(POSITION_MAGIC) == MagicNumber &&
            PositionGetInteger(POSITION_TYPE) == (type == OP_BUY ? POSITION_TYPE_BUY : POSITION_TYPE_SELL))
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
   #else
   // MQL4でのポジション価格取得
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
   #endif
   
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

//+------------------------------------------------------------------+
//| 全ポジション決済関数（共通化）                                    |
//+------------------------------------------------------------------+
void position_all_close(int magic = 0)
{
   // BUYポジションをすべて決済
   position_close(OP_BUY, 0.0, 10, magic);
   
   // SELLポジションをすべて決済
   position_close(OP_SELL, 0.0, 10, magic);
}

// ResetTradingCaches関数を追加（各種キャッシュをリセット）
void ResetTradingCaches()
{
   // キャッシュをリセット
   g_EquitySufficientCache = true;
   g_LastEquityCheckTime = 0;
   g_TimeAllowedCache[0] = true;
   g_TimeAllowedCache[1] = true;
   g_LastTimeAllowedCheckTime[0] = 0;
   g_LastTimeAllowedCheckTime[1] = 0;
   g_InitialTimeAllowedCache[0] = true;
   g_InitialTimeAllowedCache[1] = true;
   g_LastInitialTimeAllowedCheckTime[0] = 0;
   g_LastInitialTimeAllowedCheckTime[1] = 0;
}