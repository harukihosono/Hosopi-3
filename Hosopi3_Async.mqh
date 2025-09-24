//+------------------------------------------------------------------+
//|                            Hosopi3_Async.mqh                     |
//|                     非同期処理機能 (ELDRAから移植)               |
//+------------------------------------------------------------------+
#ifndef HOSOPI3_ASYNC_H
#define HOSOPI3_ASYNC_H

//+------------------------------------------------------------------+
//| 非同期オーダー送信ラッパー（エラー処理・リトライ機能付き）       |
//+------------------------------------------------------------------+
bool SendOrderWithRetryAsync(MqlTradeRequest &request, MqlTradeResult &result,
                              int maxRetries = 3, bool useAsync = true)
{
   #ifdef __MQL5__

   // フィリングモード設定
   static ENUM_ORDER_TYPE_FILLING cachedFillingMode = ORDER_FILLING_FOK;
   static bool fillingModeInitialized = false;
   static int consecutiveFillingErrors = 0;

   // フィリングモード自動検出（初回のみ）
   if(request.action == TRADE_ACTION_DEAL) {
      if(!fillingModeInitialized) {
         cachedFillingMode = GetOptimalFillingModeForBroker(request.symbol);
         fillingModeInitialized = true;
      }
      request.type_filling = cachedFillingMode;
   }
   else if(request.action == TRADE_ACTION_PENDING) {
      request.type_filling = ORDER_FILLING_RETURN;
   }

   // フィリングモードの優先順位リスト
   ENUM_ORDER_TYPE_FILLING fillingModes[] = {
      cachedFillingMode,      // 最初に自動検出されたモード
      ORDER_FILLING_FOK,      // 次にFOK
      ORDER_FILLING_IOC,      // 次にIOC
      ORDER_FILLING_RETURN    // 最後にRETURN
   };

   // リトライループ
   for(int retry = 0; retry < maxRetries; retry++) {

      // 非同期/同期選択可能な送信
      bool orderResult = useAsync ? OrderSendAsync(request, result) : OrderSend(request, result);

      if(orderResult) {
         consecutiveFillingErrors = 0;  // 成功したらエラーカウントリセット
         return true;
      }

      // エラー処理
      uint errorCode = GetLastError();

      // フィリングモードエラー（4756 = INVALID_FILL）または無効なリクエスト（10030）の場合
      if(errorCode == 4756 || errorCode == 10030 || result.retcode == TRADE_RETCODE_INVALID_FILL) {
         consecutiveFillingErrors++;

         // 次のフィリングモードを試す
         int currentModeIndex = -1;
         for(int i = 0; i < ArraySize(fillingModes); i++) {
            if(fillingModes[i] == request.type_filling) {
               currentModeIndex = i;
               break;
            }
         }

         if(currentModeIndex >= 0 && currentModeIndex < ArraySize(fillingModes) - 1) {
            request.type_filling = fillingModes[currentModeIndex + 1];
            Print("フィリングモードを変更: ", EnumToString(fillingModes[currentModeIndex]),
                  " → ", EnumToString(request.type_filling));

            // キャッシュも更新
            if(request.action == TRADE_ACTION_DEAL) {
               cachedFillingMode = request.type_filling;
            }
            continue;  // リトライ
         }
      }

      // 流動性不足またはマーケットクローズドエラー
      if(errorCode == 4756 || result.retcode == TRADE_RETCODE_NO_MONEY ||
         result.retcode == TRADE_RETCODE_MARKET_CLOSED) {
         Print("エラー: 注文送信失敗 - ", errorCode, " retcode=", result.retcode);
         return false;  // リトライしない
      }

      // その他のエラーはリトライ
      if(retry < maxRetries - 1) {
         Sleep(100);  // 100ms待機
      }
   }

   Print("エラー: 注文送信が", maxRetries, "回失敗しました");
   return false;

   #else // MQL4の場合

   // MQL4では同期処理のみ
   if(OrderSend(request.symbol, request.type, request.volume, request.price,
                request.deviation, request.sl, request.tp, request.comment,
                request.magic, request.expiration, clrNONE) > 0) {
      return true;
   }

   return false;

   #endif
}

//+------------------------------------------------------------------+
//| 非同期ポジション決済関数                                         |
//+------------------------------------------------------------------+
bool ClosePositionAsync(ulong ticket, bool useAsync = true)
{
   #ifdef __MQL5__

   if(!PositionSelectByTicket(ticket)) {
      return false;
   }

   MqlTradeRequest request;
   MqlTradeResult result;

   ZeroMemory(request);
   request.action = TRADE_ACTION_DEAL;
   request.symbol = PositionGetString(POSITION_SYMBOL);
   request.volume = PositionGetDouble(POSITION_VOLUME);
   request.position = ticket;
   request.deviation = Slippage;
   request.magic = MagicNumber;

   // 決済価格と注文タイプを設定
   ENUM_POSITION_TYPE posType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
   if(posType == POSITION_TYPE_BUY) {
      request.type = ORDER_TYPE_SELL;
      request.price = SymbolInfoDouble(request.symbol, SYMBOL_BID);
   } else {
      request.type = ORDER_TYPE_BUY;
      request.price = SymbolInfoDouble(request.symbol, SYMBOL_ASK);
   }

   return SendOrderWithRetryAsync(request, result, 3, useAsync);

   #else // MQL4の場合

   if(OrderSelect(ticket, SELECT_BY_TICKET)) {
      if(OrderType() == OP_BUY) {
         return OrderClose(ticket, OrderLots(), Bid, Slippage, clrNONE);
      } else if(OrderType() == OP_SELL) {
         return OrderClose(ticket, OrderLots(), Ask, Slippage, clrNONE);
      }
   }

   return false;

   #endif
}

//+------------------------------------------------------------------+
//| 全ポジション非同期決済関数                                       |
//+------------------------------------------------------------------+
void CloseAllPositionsAsync(bool useAsync = true, bool useCloseBy = false)
{
   #ifdef __MQL5__

   // 相殺決済が有効な場合
   if(useCloseBy && IsCloseBySupported()) {
      CloseAllWithCloseByAsync(useAsync);
      return;
   }

   // 通常の非同期決済
   int totalPositions = PositionsTotal();
   for(int i = totalPositions - 1; i >= 0; i--) {
      ulong ticket = PositionGetTicket(i);
      if(ticket > 0) {
         if(PositionSelectByTicket(ticket)) {
            if(PositionGetInteger(POSITION_MAGIC) == MagicNumber) {
               ClosePositionAsync(ticket, useAsync);

               // 非同期の場合は間隔を空ける
               if(useAsync && i > 0) {
                  Sleep(10);  // 10ms間隔
               }
            }
         }
      }
   }

   #else // MQL4の場合

   for(int i = OrdersTotal() - 1; i >= 0; i--) {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
         if(OrderMagicNumber() == MagicNumber && OrderSymbol() == Symbol()) {
            if(OrderType() == OP_BUY || OrderType() == OP_SELL) {
               ClosePositionAsync(OrderTicket(), false);  // MQL4は同期のみ
            }
         }
      }
   }

   #endif
}

//+------------------------------------------------------------------+
//| 相殺決済を使った非同期全決済（MT5のみ）                         |
//+------------------------------------------------------------------+
#ifdef __MQL5__
void CloseAllWithCloseByAsync(bool useAsync = true)
{
   // 買いポジションと売りポジションを収集
   ulong buyTickets[];
   ulong sellTickets[];
   ArrayResize(buyTickets, 0);
   ArrayResize(sellTickets, 0);

   for(int i = 0; i < PositionsTotal(); i++) {
      ulong ticket = PositionGetTicket(i);
      if(PositionSelectByTicket(ticket)) {
         if(PositionGetInteger(POSITION_MAGIC) != MagicNumber) continue;
         if(PositionGetString(POSITION_SYMBOL) != Symbol()) continue;

         ENUM_POSITION_TYPE type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
         if(type == POSITION_TYPE_BUY) {
            int size = ArraySize(buyTickets);
            ArrayResize(buyTickets, size + 1);
            buyTickets[size] = ticket;
         } else if(type == POSITION_TYPE_SELL) {
            int size = ArraySize(sellTickets);
            ArrayResize(sellTickets, size + 1);
            sellTickets[size] = ticket;
         }
      }
   }

   // 相殺決済の実行
   int buyCount = ArraySize(buyTickets);
   int sellCount = ArraySize(sellTickets);
   int pairsToClose = MathMin(buyCount, sellCount);

   for(int i = 0; i < pairsToClose; i++) {
      MqlTradeRequest request;
      MqlTradeResult result;

      ZeroMemory(request);
      request.action = TRADE_ACTION_CLOSE_BY;
      request.position = buyTickets[i];
      request.position_by = sellTickets[i];
      request.symbol = Symbol();
      request.magic = MagicNumber;

      bool success = useAsync ? OrderSendAsync(request, result) : OrderSend(request, result);

      if(!success) {
         Print("相殺決済失敗: Buy#", buyTickets[i], " Sell#", sellTickets[i],
               " エラー=", GetLastError());
      } else {
         Print("相殺決済成功: Buy#", buyTickets[i], " ⇔ Sell#", sellTickets[i]);
      }

      if(useAsync) Sleep(10);  // 非同期の場合は間隔を空ける
   }

   // 残りのポジションを通常決済
   for(int i = pairsToClose; i < buyCount; i++) {
      ClosePositionAsync(buyTickets[i], useAsync);
      if(useAsync) Sleep(10);
   }

   for(int i = pairsToClose; i < sellCount; i++) {
      ClosePositionAsync(sellTickets[i], useAsync);
      if(useAsync) Sleep(10);
   }
}
#endif

//+------------------------------------------------------------------+
//| ポジションのTP/SL変更（非同期対応）                             |
//+------------------------------------------------------------------+
bool ModifyPositionAsync(ulong ticket, double sl, double tp, bool useAsync = true)
{
   #ifdef __MQL5__

   if(!PositionSelectByTicket(ticket)) {
      return false;
   }

   MqlTradeRequest request;
   MqlTradeResult result;

   ZeroMemory(request);
   request.action = TRADE_ACTION_SLTP;
   request.position = ticket;
   request.symbol = PositionGetString(POSITION_SYMBOL);
   request.sl = sl;
   request.tp = tp;
   request.magic = MagicNumber;

   // 非同期/同期選択可能
   if(useAsync) {
      return OrderSendAsync(request, result);
   } else {
      return OrderSend(request, result);
   }

   #else // MQL4の場合

   if(OrderSelect(ticket, SELECT_BY_TICKET)) {
      return OrderModify(ticket, OrderOpenPrice(), sl, tp, 0, clrNONE);
   }

   return false;

   #endif
}

//+------------------------------------------------------------------+
//| 待機注文の変更（非同期対応）                                     |
//+------------------------------------------------------------------+
bool ModifyOrderAsync(ulong ticket, double price, double sl, double tp,
                      datetime expiration = 0, bool useAsync = true)
{
   #ifdef __MQL5__

   if(!OrderSelect(ticket)) {
      return false;
   }

   MqlTradeRequest request;
   MqlTradeResult result;

   ZeroMemory(request);
   request.action = TRADE_ACTION_MODIFY;
   request.order = ticket;
   request.price = price;
   request.sl = sl;
   request.tp = tp;
   request.type_time = expiration > 0 ? ORDER_TIME_SPECIFIED : ORDER_TIME_GTC;
   request.expiration = expiration;
   request.magic = MagicNumber;

   // 非同期/同期選択可能
   if(useAsync) {
      return OrderSendAsync(request, result);
   } else {
      return OrderSend(request, result);
   }

   #else // MQL4の場合

   if(OrderSelect(ticket, SELECT_BY_TICKET)) {
      return OrderModify(ticket, price, sl, tp, expiration, clrNONE);
   }

   return false;

   #endif
}

//+------------------------------------------------------------------+
//| 全ポジションのTP/SLを一括変更（非同期対応）                    |
//+------------------------------------------------------------------+
void ModifyAllPositionsAsync(double sl = 0, double tp = 0, bool useAsync = true)
{
   #ifdef __MQL5__

   for(int i = 0; i < PositionsTotal(); i++) {
      ulong ticket = PositionGetTicket(i);
      if(PositionSelectByTicket(ticket)) {
         if(PositionGetInteger(POSITION_MAGIC) != MagicNumber) continue;
         if(PositionGetString(POSITION_SYMBOL) != Symbol()) continue;

         double newSL = sl;
         double newTP = tp;

         // 0の場合は現在の値を維持
         if(sl == 0) newSL = PositionGetDouble(POSITION_SL);
         if(tp == 0) newTP = PositionGetDouble(POSITION_TP);

         ModifyPositionAsync(ticket, newSL, newTP, useAsync);

         if(useAsync) Sleep(10);  // 非同期の場合は間隔を空ける
      }
   }

   #else // MQL4の場合

   for(int i = OrdersTotal() - 1; i >= 0; i--) {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
         if(OrderMagicNumber() != MagicNumber) continue;
         if(OrderSymbol() != Symbol()) continue;
         if(OrderType() > OP_SELL) continue;  // ポジションのみ

         double newSL = sl;
         double newTP = tp;

         // 0の場合は現在の値を維持
         if(sl == 0) newSL = OrderStopLoss();
         if(tp == 0) newTP = OrderTakeProfit();

         ModifyPositionAsync(OrderTicket(), newSL, newTP, false);  // MQL4は同期のみ
      }
   }

   #endif
}

//+------------------------------------------------------------------+
//| トレーリングストップ（非同期対応）                               |
//+------------------------------------------------------------------+
void TrailingStopAsync(double trailPoints, bool useAsync = true)
{
   #ifdef __MQL5__

   double trail = trailPoints * _Point;

   for(int i = 0; i < PositionsTotal(); i++) {
      ulong ticket = PositionGetTicket(i);
      if(!PositionSelectByTicket(ticket)) continue;

      if(PositionGetInteger(POSITION_MAGIC) != MagicNumber) continue;
      if(PositionGetString(POSITION_SYMBOL) != Symbol()) continue;

      ENUM_POSITION_TYPE type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      double currentSL = PositionGetDouble(POSITION_SL);
      double currentTP = PositionGetDouble(POSITION_TP);
      double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);

      if(type == POSITION_TYPE_BUY) {
         double newSL = Bid - trail;
         if(newSL > openPrice && (currentSL == 0 || newSL > currentSL)) {
            ModifyPositionAsync(ticket, newSL, currentTP, useAsync);
            if(useAsync) Sleep(10);
         }
      } else if(type == POSITION_TYPE_SELL) {
         double newSL = Ask + trail;
         if(newSL < openPrice && (currentSL == 0 || newSL < currentSL)) {
            ModifyPositionAsync(ticket, newSL, currentTP, useAsync);
            if(useAsync) Sleep(10);
         }
      }
   }

   #else // MQL4の場合

   double trail = trailPoints * Point;

   for(int i = OrdersTotal() - 1; i >= 0; i--) {
      if(!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;

      if(OrderMagicNumber() != MagicNumber) continue;
      if(OrderSymbol() != Symbol()) continue;

      if(OrderType() == OP_BUY) {
         double newSL = Bid - trail;
         if(newSL > OrderOpenPrice() && (OrderStopLoss() == 0 || newSL > OrderStopLoss())) {
            ModifyPositionAsync(OrderTicket(), newSL, OrderTakeProfit(), false);
         }
      } else if(OrderType() == OP_SELL) {
         double newSL = Ask + trail;
         if(newSL < OrderOpenPrice() && (OrderStopLoss() == 0 || newSL < OrderStopLoss())) {
            ModifyPositionAsync(OrderTicket(), newSL, OrderTakeProfit(), false);
         }
      }
   }

   #endif
}

//+------------------------------------------------------------------+
//| 非同期注文キャンセル関数                                         |
//+------------------------------------------------------------------+
bool CancelOrderAsync(ulong ticket, bool useAsync = true)
{
   #ifdef __MQL5__

   MqlTradeRequest request;
   MqlTradeResult result;

   ZeroMemory(request);
   request.action = TRADE_ACTION_REMOVE;
   request.order = ticket;

   return useAsync ? OrderSendAsync(request, result) : OrderSend(request, result);

   #else // MQL4の場合

   if(OrderSelect(ticket, SELECT_BY_TICKET)) {
      if(OrderType() > OP_SELL) {  // 待機注文のみ
         return OrderDelete(ticket, clrNONE);
      }
   }

   return false;

   #endif
}

//+------------------------------------------------------------------+
//| 全待機注文の非同期キャンセル                                     |
//+------------------------------------------------------------------+
void CancelAllOrdersAsync(bool useAsync = true)
{
   #ifdef __MQL5__

   for(int i = OrdersTotal() - 1; i >= 0; i--) {
      ulong ticket = OrderGetTicket(i);
      if(OrderSelect(ticket)) {
         if(OrderGetInteger(ORDER_MAGIC) == MagicNumber) {
            CancelOrderAsync(ticket, useAsync);
            if(useAsync) Sleep(10);  // 非同期の場合は間隔を空ける
         }
      }
   }

   #else // MQL4の場合

   for(int i = OrdersTotal() - 1; i >= 0; i--) {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
         if(OrderMagicNumber() == MagicNumber && OrderSymbol() == Symbol()) {
            if(OrderType() > OP_SELL) {  // 待機注文のみ
               CancelOrderAsync(OrderTicket(), false);  // MQL4は同期のみ
            }
         }
      }
   }

   #endif
}

//+------------------------------------------------------------------+
//| 非同期処理の状態管理構造体                                       |
//+------------------------------------------------------------------+
struct AsyncOrderState {
   ulong requestId;      // リクエストID
   datetime timestamp;   // タイムスタンプ
   int retryCount;       // リトライ回数
   bool completed;       // 完了フラグ
   bool success;         // 成功フラグ
   string comment;       // コメント
};

// グローバル非同期状態配列
AsyncOrderState g_AsyncOrders[];
int g_AsyncOrderCount = 0;

//+------------------------------------------------------------------+
//| 非同期注文の状態を追跡                                           |
//+------------------------------------------------------------------+
void TrackAsyncOrder(ulong requestId, string comment = "")
{
   int size = ArraySize(g_AsyncOrders);
   ArrayResize(g_AsyncOrders, size + 1);

   g_AsyncOrders[size].requestId = requestId;
   g_AsyncOrders[size].timestamp = TimeCurrent();
   g_AsyncOrders[size].retryCount = 0;
   g_AsyncOrders[size].completed = false;
   g_AsyncOrders[size].success = false;
   g_AsyncOrders[size].comment = comment;

   g_AsyncOrderCount++;
}

//+------------------------------------------------------------------+
//| 非同期注文の完了をチェック                                       |
//+------------------------------------------------------------------+
void CheckAsyncOrdersCompletion()
{
   datetime currentTime = TimeCurrent();

   for(int i = 0; i < ArraySize(g_AsyncOrders); i++) {
      if(!g_AsyncOrders[i].completed) {
         // タイムアウトチェック（5秒）
         if(currentTime - g_AsyncOrders[i].timestamp > 5) {
            g_AsyncOrders[i].completed = true;
            g_AsyncOrders[i].success = false;
            Print("非同期注文タイムアウト: ", g_AsyncOrders[i].comment);
         }
      }
   }

   // 古いエントリをクリーンアップ（10秒以上前のもの）
   for(int i = ArraySize(g_AsyncOrders) - 1; i >= 0; i--) {
      if(g_AsyncOrders[i].completed &&
         currentTime - g_AsyncOrders[i].timestamp > 10) {
         // 配列から削除
         for(int j = i; j < ArraySize(g_AsyncOrders) - 1; j++) {
            g_AsyncOrders[j] = g_AsyncOrders[j + 1];
         }
         ArrayResize(g_AsyncOrders, ArraySize(g_AsyncOrders) - 1);
      }
   }
}

//+------------------------------------------------------------------+
//| OnTradeTransactionイベント処理（MT5のみ）                        |
//+------------------------------------------------------------------+
#ifdef __MQL5__
void ProcessAsyncTradeTransaction(const MqlTradeTransaction& trans,
                                   const MqlTradeRequest& request,
                                   const MqlTradeResult& result)
{
   // 非同期注文の結果を処理
   if(trans.type == TRADE_TRANSACTION_REQUEST) {
      // リクエストIDで対応する非同期注文を検索
      for(int i = 0; i < ArraySize(g_AsyncOrders); i++) {
         if(g_AsyncOrders[i].requestId == result.request_id) {
            if(result.retcode == TRADE_RETCODE_DONE) {
               g_AsyncOrders[i].success = true;
               g_AsyncOrders[i].completed = true;
               Print("非同期注文成功: ", g_AsyncOrders[i].comment);
            } else if(result.retcode == TRADE_RETCODE_ERROR ||
                      result.retcode == TRADE_RETCODE_REJECT ||
                      result.retcode == TRADE_RETCODE_INVALID) {
               g_AsyncOrders[i].success = false;
               g_AsyncOrders[i].completed = true;
               Print("非同期注文失敗: ", g_AsyncOrders[i].comment,
                     " retcode=", result.retcode);
            }
            break;
         }
      }
   }
}
#endif

#endif // HOSOPI3_ASYNC_H