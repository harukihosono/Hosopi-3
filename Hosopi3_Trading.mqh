//+------------------------------------------------------------------+
//|                  Hosopi 3 - トレード関連関数 (最適化版)            |
//|                         Copyright 2025                           |
//|                    MQL4/MQL5 完全共通化バージョン                 |
//+------------------------------------------------------------------+
#include "Hosopi3_Defines.mqh"
#include "Hosopi3_Compat.mqh"

//+------------------------------------------------------------------+
//| MQL4/MQL5互換性のための定義                                      |
//+------------------------------------------------------------------+
#ifdef __MQL5__
   // MQL5での定義
   #define OP_BUY  0
   #define OP_SELL 1
   #define MODE_TRADES 0
   #define SELECT_BY_POS 0
   // MODE定数はCompat.mqhで定義済み
   #define MODE_BID SYMBOL_BID
   #define MODE_ASK SYMBOL_ASK
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

// トレードリターンコードの説明を取得
string GetTradeRetcodeDescription(uint retcode)
{
   switch(retcode)
   {
      case TRADE_RETCODE_REQUOTE: return "価格再提示";
      case TRADE_RETCODE_REJECT: return "リクエスト拒否";
      case TRADE_RETCODE_CANCEL: return "キャンセル";
      case TRADE_RETCODE_PLACED: return "注文配置";
      case TRADE_RETCODE_DONE: return "実行完了";
      case TRADE_RETCODE_DONE_PARTIAL: return "部分実行";
      case TRADE_RETCODE_ERROR: return "一般エラー";
      case TRADE_RETCODE_TIMEOUT: return "タイムアウト";
      case TRADE_RETCODE_INVALID: return "無効なリクエスト";
      case TRADE_RETCODE_INVALID_VOLUME: return "無効なボリューム";
      case TRADE_RETCODE_INVALID_PRICE: return "無効な価格";
      case TRADE_RETCODE_INVALID_STOPS: return "無効なストップ";
      case TRADE_RETCODE_TRADE_DISABLED: return "取引無効";
      case TRADE_RETCODE_MARKET_CLOSED: return "市場終了";
      case TRADE_RETCODE_NO_MONEY: return "証拠金不足";
      case TRADE_RETCODE_PRICE_CHANGED: return "価格変更";
      case TRADE_RETCODE_PRICE_OFF: return "価格オフ";
      case TRADE_RETCODE_INVALID_EXPIRATION: return "無効な有効期限";
      case TRADE_RETCODE_ORDER_CHANGED: return "注文変更";
      case TRADE_RETCODE_TOO_MANY_REQUESTS: return "リクエスト過多";
      case TRADE_RETCODE_NO_CHANGES: return "変更なし";
      case TRADE_RETCODE_SERVER_DISABLES_AT: return "自動売買無効";
      case TRADE_RETCODE_CLIENT_DISABLES_AT: return "クライアント自動売買無効";
      case TRADE_RETCODE_LOCKED: return "ロック";
      case TRADE_RETCODE_FROZEN: return "フリーズ";
      case TRADE_RETCODE_INVALID_FILL: return "無効なフィル";
      case TRADE_RETCODE_CONNECTION: return "接続エラー";
      case TRADE_RETCODE_ONLY_REAL: return "リアル口座のみ";
      case TRADE_RETCODE_LIMIT_ORDERS: return "注文制限";
      case TRADE_RETCODE_LIMIT_VOLUME: return "ボリューム制限";
      case TRADE_RETCODE_INVALID_ORDER: return "無効な注文";
      case TRADE_RETCODE_POSITION_CLOSED: return "ポジション決済済み";
      default: return "不明なエラー";
   }
}

// 価格の妥当性をチェック
bool IsPriceValid(double price, int orderType)
{
   if(price <= 0) 
   {
      Print("ERROR: 価格が0以下 - Price=", price);
      return false;
   }
   
   // 現在の市場価格と比較
   double ask = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
   double bid = SymbolInfoDouble(Symbol(), SYMBOL_BID);
   
   if(ask <= 0 || bid <= 0)
   {
      Print("ERROR: 無効な市場価格 - Ask=", ask, " Bid=", bid);
      return false;
   }
   
   // 買い注文の場合、Ask価格との乖離をチェック
   if(orderType == ORDER_TYPE_BUY)
   {
      double deviation = MathAbs(price - ask);
      double maxDeviation = ask * 0.001; // 0.1%の許容誤差
      
      if(deviation > maxDeviation)
      {
         Print("ERROR: BUY価格の乖離が大きすぎる - Price=", DoubleToString(price, 5), 
               " Ask=", DoubleToString(ask, 5), " Deviation=", DoubleToString(deviation, 5));
         return false;
      }
   }
   // 売り注文の場合、Bid価格との乖離をチェック
   else if(orderType == ORDER_TYPE_SELL)
   {
      double deviation = MathAbs(price - bid);
      double maxDeviation = bid * 0.001; // 0.1%の許容誤差
      
      if(deviation > maxDeviation)
      {
         Print("ERROR: SELL価格の乖離が大きすぎる - Price=", DoubleToString(price, 5), 
               " Bid=", DoubleToString(bid, 5), " Deviation=", DoubleToString(deviation, 5));
         return false;
      }
   }
   
   return true;
}

// エラーコードの回復可能性を判定
bool IsRecoverableError(uint retcode)
{
   switch(retcode)
   {
      // 回復可能エラー（リトライ推奨）
      case TRADE_RETCODE_REQUOTE:           // 価格再提示
      case TRADE_RETCODE_PRICE_CHANGED:     // 価格変更
      case TRADE_RETCODE_PRICE_OFF:         // 価格が無効
      case TRADE_RETCODE_TIMEOUT:           // タイムアウト
      case TRADE_RETCODE_CONNECTION:        // 接続エラー
      case TRADE_RETCODE_MARKET_CLOSED:     // 市場終了
      case TRADE_RETCODE_REJECT:            // リジェクト（一時的）
         return true;
      
      // 回復不可能エラー（即座に停止）
      case TRADE_RETCODE_INVALID:           // 無効なリクエスト
      case TRADE_RETCODE_INVALID_VOLUME:    // 無効なボリューム
      case TRADE_RETCODE_INVALID_PRICE:     // 無効な価格
      case TRADE_RETCODE_INVALID_STOPS:     // 無効なストップ
      case TRADE_RETCODE_TRADE_DISABLED:    // 取引禁止
      case TRADE_RETCODE_NO_MONEY:          // 証拠金不足
      case TRADE_RETCODE_INVALID_ORDER:     // 無効な注文
         return false;
      
      default:
         // 不明なエラーは安全のため回復不可能として扱う
         return false;
   }
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
//| ボリューム正規化関数（4807エラー対策）                            |
//+------------------------------------------------------------------+
double NormalizeVolume(double volume, string symbol = "")
{
   if(symbol == "") symbol = Symbol();
   
   #ifdef __MQL5__
   double minVolume = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
   double maxVolume = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MAX);
   double volumeStep = SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP);
   #else
   // MQL4での市場情報取得
   double minVolume = MarketInfo(symbol, MODE_MINLOT);
   double maxVolume = MarketInfo(symbol, MODE_MAXLOT);
   double volumeStep = MarketInfo(symbol, MODE_LOTSTEP);
   #endif
   
   // ボリューム正規化ログ（必要時のみ）
   
   // ボリュームが0以下の場合は最小ボリュームを返す
   if(volume <= 0) 
   {
      // Volume <= 0, returning min volume
      return minVolume;
   }
   
   // ボリュームステップが0の場合のエラー処理
   if(volumeStep <= 0)
   {
      Print("ERROR: Invalid volume step: ", volumeStep);
      return minVolume;
   }
   
   // ボリュームステップに合わせて正規化（より精密な計算）
   double steps = MathFloor(volume / volumeStep + 0.0000001);
   volume = steps * volumeStep;
   
   // 最小・最大ボリュームでクリップ
   if(volume < minVolume) volume = minVolume;
   if(volume > maxVolume) volume = maxVolume;
   
   // 最終的なボリューム検証
   if(volume < minVolume || volume > maxVolume)
   {
      Print("ERROR: Volume out of range after normalization: ", volume);
      return minVolume;
   }
   
   return volume;
}

//+------------------------------------------------------------------+
//| ポジションエントリー関数（最適化版・共通化）                      |
//+------------------------------------------------------------------+
bool position_entry(int side, double lot = 0.1, int slippage = 10, int magic = 0, string comment = "")
{
   // 高頻度呼び出し対策: キャッシュを使用したエントリー制限チェック

   if(magic == 0) magic = MagicNumber;
   
   #ifdef __MQL5__
   // MQL5での注文処理（シンプル版）
   MqlTradeRequest request = {};
   MqlTradeResult result = {};
   
   double normalizedVolume = NormalizeVolume(lot);

  
   // 基本設定
   request.action = TRADE_ACTION_DEAL;
   request.symbol = Symbol();
   request.volume = normalizedVolume;
   request.type = (side == OP_BUY) ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;
   request.price = (side == OP_BUY) ? SymbolInfoDouble(Symbol(), SYMBOL_ASK) : SymbolInfoDouble(Symbol(), SYMBOL_BID);
   request.deviation = slippage;
   request.magic = magic;
   request.comment = comment;
   request.type_filling = OrderFillingMode; // パラメーターで設定されたフィリングモード
   
   bool success = OrderSend(request, result);
   
   if(!success || result.retcode != TRADE_RETCODE_DONE)
   {
      Print("注文エラー: retcode=", result.retcode, " LastError=", GetLastError());
      return false;
   }
   
   // 注文成功
   return true;
   
   #else
   // MQL4での注文処理（リトライ機能付き）
   double normalizedLot = NormalizeVolume(lot);
   int maxRetries = 3;
   int ticket = -1;
   
   for(int retry = 0; retry < maxRetries; retry++)
   {
      if(retry > 0)
      {
         // リトライ時は価格を再取得
         RefreshRates();
         Sleep(100); // 100ms待機
         // リトライ処理
      }
      
      double currentPrice = (side == OP_BUY) ? Ask : Bid;
      ticket = OrderSend(Symbol(), side, normalizedLot, currentPrice, slippage * 2, 0, 0, comment, magic, 0, (side == OP_BUY) ? clrGreen : clrRed);
      
      if(ticket > 0)
      {
         // 注文成功
         break;
      }
      
      int error = GetLastError();
      // リクォートエラー以外なら即座に失敗として扱う
      if(error != 138 && error != 4202 && error != 3) // 138=Requote, 4202=Invalid price, 3=Common error
      {
         Print("注文エラー: ", error);
         break;
      }
   }
   
   if(ticket <= 0)
   {
      Print("注文失敗: ", GetLastError());
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
            volume = NormalizeVolume(volume);
            
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
            close_volume = NormalizeVolume(close_volume);
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

//+------------------------------------------------------------------+
//| 相殺決済関数（OrderCloseBy）- MQL4/MQL5共通化                     |
//+------------------------------------------------------------------+
bool position_close_by_opposite(int magic = 0)
{
   if(magic == 0) magic = MagicNumber;

   #ifdef __MQL5__
   // MQL5では相殺決済（netting）は自動的に行われるため、
   // 同じ通貨ペアの買い/売りポジションを同時に決済する
   bool buyFound = false, sellFound = false;
   ulong buyTicket = 0, sellTicket = 0;
   double buyVolume = 0, sellVolume = 0;

   // 買いポジションを探す
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket > 0)
      {
         if(PositionGetString(POSITION_SYMBOL) == Symbol() &&
            PositionGetInteger(POSITION_MAGIC) == magic &&
            PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
         {
            buyFound = true;
            buyTicket = ticket;
            buyVolume = PositionGetDouble(POSITION_VOLUME);
            break;
         }
      }
   }

   // 売りポジションを探す
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket > 0)
      {
         if(PositionGetString(POSITION_SYMBOL) == Symbol() &&
            PositionGetInteger(POSITION_MAGIC) == magic &&
            PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL)
         {
            sellFound = true;
            sellTicket = ticket;
            sellVolume = PositionGetDouble(POSITION_VOLUME);
            break;
         }
      }
   }

   // 両方のポジションが存在する場合、同時に決済
   if(buyFound && sellFound)
   {
      double closeVolume = MathMin(buyVolume, sellVolume);
      closeVolume = NormalizeVolume(closeVolume);

      Print("相殺決済実行: Buy=", DoubleToString(buyVolume, 2), " Sell=", DoubleToString(sellVolume, 2),
            " 決済量=", DoubleToString(closeVolume, 2));

      bool buyResult = position_close(OP_BUY, closeVolume, 10, magic);
      bool sellResult = position_close(OP_SELL, closeVolume, 10, magic);

      return buyResult && sellResult;
   }

   Print("相殺決済: 対象ポジションなし (Buy=", buyFound ? "有" : "無", " Sell=", sellFound ? "有" : "無", ")");
   return false;

   #else
   // MQL4での相殺決済（OrderCloseBy使用）
   bool found = false;
   int buyTicket = -1, sellTicket = -1;
   double buyLots = 0, sellLots = 0;

   // 買いポジションを探す
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
      {
         if(OrderType() == OP_BUY && OrderSymbol() == Symbol() &&
            (magic == 0 || OrderMagicNumber() == magic))
         {
            buyTicket = OrderTicket();
            buyLots = OrderLots();
            break;
         }
      }
   }

   // 売りポジションを探す
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
      {
         if(OrderType() == OP_SELL && OrderSymbol() == Symbol() &&
            (magic == 0 || OrderMagicNumber() == magic))
         {
            sellTicket = OrderTicket();
            sellLots = OrderLots();
            break;
         }
      }
   }

   // 両方のポジションが存在する場合、OrderCloseByで相殺決済
   if(buyTicket > 0 && sellTicket > 0)
   {
      Print("相殺決済実行: BuyTicket=", buyTicket, " SellTicket=", sellTicket,
            " BuyLots=", DoubleToString(buyLots, 2), " SellLots=", DoubleToString(sellLots, 2));

      // MQL4のOrderCloseByを使用して相殺決済
      found = OrderCloseBy(buyTicket, sellTicket);

      if(!found)
      {
         Print("相殺決済エラー: ", GetLastError());
      }
      else
      {
         Print("相殺決済成功");
      }
   }
   else
   {
      Print("相殺決済: 対象ポジションなし (Buy=", (buyTicket > 0) ? "有" : "無", " Sell=", (sellTicket > 0) ? "有" : "無", ")");
   }

   return found;
   #endif
}

//+------------------------------------------------------------------+
//| 指定ロット数での相殺決済関数                                      |
//+------------------------------------------------------------------+
bool position_close_by_lots(double lots, int magic = 0)
{
   if(magic == 0) magic = MagicNumber;
   lots = NormalizeVolume(lots);

   #ifdef __MQL5__
   // MQL5での指定ロット相殺決済
   bool buyResult = position_close(OP_BUY, lots, 10, magic);
   bool sellResult = position_close(OP_SELL, lots, 10, magic);

   if(buyResult && sellResult)
   {
      Print("指定ロット相殺決済成功: ", DoubleToString(lots, 2), " lots");
      return true;
   }
   else
   {
      Print("指定ロット相殺決済失敗: Buy=", buyResult ? "成功" : "失敗", " Sell=", sellResult ? "成功" : "失敗");
      return false;
   }

   #else
   // MQL4での指定ロット相殺決済
   // 指定ロット数で部分決済を行い、その後相殺決済を実行
   bool buyPartial = position_close(OP_BUY, lots, 10, magic);
   bool sellPartial = position_close(OP_SELL, lots, 10, magic);

   if(buyPartial && sellPartial)
   {
      Print("指定ロット相殺決済成功: ", DoubleToString(lots, 2), " lots");
      return true;
   }
   else
   {
      Print("指定ロット相殺決済失敗: Buy=", buyPartial ? "成功" : "失敗", " Sell=", sellPartial ? "成功" : "失敗");
      return false;
   }
   #endif
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