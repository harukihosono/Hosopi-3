//+------------------------------------------------------------------+
//|                            Hosopi3_Async.mqh                     |
//|                     非同期処理機能 (ELDRAから移植)               |
//+------------------------------------------------------------------+
#ifndef HOSOPI3_ASYNC_H
#define HOSOPI3_ASYNC_H
#ifdef __MQL4__
#ifndef HOSOPI3_MQL4_TRADE_STRUCTS
#define HOSOPI3_MQL4_TRADE_STRUCTS
struct MqlTradeRequest
{
   int      action;
   string   symbol;
   double   volume;
   int      type;
   double   price;
   int      deviation;
   double   sl;
   double   tp;
   string   comment;
   int      magic;
   datetime expiration;
};
struct MqlTradeResult
{
   uint     retcode;
   ulong    order;
   ulong    deal;
   ulong    request_id;
   double   volume;
   double   price;
   double   bid;
   double   ask;
   string   comment;
};
#endif // HOSOPI3_MQL4_TRADE_STRUCTS
#endif // __MQL4__


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
         cachedFillingMode = GetFillingMode();
         fillingModeInitialized = true;
      }
      request.type_filling = cachedFillingMode;
   }
   else if(request.action == TRADE_ACTION_PENDING) {
      request.type_filling = ORDER_FILLING_RETURN;
   }

   // フィリングモードの優先順位リスト（重複を除外）
   ENUM_ORDER_TYPE_FILLING fillingModes[];
   int fillingModeCount = 0;

   // 重複しないようにフィリングモードリストを構築
   ENUM_ORDER_TYPE_FILLING allModes[] = {
      cachedFillingMode,      // 最初に自動検出されたモード
      ORDER_FILLING_FOK,      // FOK
      ORDER_FILLING_IOC,      // IOC
      ORDER_FILLING_RETURN    // RETURN
   };

   for(int m = 0; m < ArraySize(allModes); m++) {
      bool isDuplicate = false;
      for(int n = 0; n < fillingModeCount; n++) {
         if(fillingModes[n] == allModes[m]) {
            isDuplicate = true;
            break;
         }
      }
      if(!isDuplicate) {
         ArrayResize(fillingModes, fillingModeCount + 1);
         fillingModes[fillingModeCount] = allModes[m];
         fillingModeCount++;
      }
   }

   // リトライループ（フィリングモード数分リトライ）
   int totalRetries = MathMax(maxRetries, fillingModeCount);
   int fillingModeIndex = 0;

   for(int retry = 0; retry < totalRetries; retry++) {

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
         fillingModeIndex++;

         // 次のフィリングモードを試す
         if(fillingModeIndex < fillingModeCount) {
            ENUM_ORDER_TYPE_FILLING prevMode = request.type_filling;
            request.type_filling = fillingModes[fillingModeIndex];
            Print("フィリングモードを変更: ", EnumToString(prevMode),
                  " → ", EnumToString(request.type_filling));

            // キャッシュも更新
            if(request.action == TRADE_ACTION_DEAL) {
               cachedFillingMode = request.type_filling;
            }
            continue;  // リトライ
         }

         // 全フィリングモードを試しても失敗
         Print("エラー: 全フィリングモード試行失敗 - errorCode=", errorCode, " retcode=", result.retcode);

         // 連続エラーが3回以上でキャッシュリセット
         if(consecutiveFillingErrors >= 3) {
            fillingModeInitialized = false;
            consecutiveFillingErrors = 0;
         }
         return false;
      }

      // 流動性不足またはマーケットクローズドエラー
      if(result.retcode == TRADE_RETCODE_NO_MONEY ||
         result.retcode == TRADE_RETCODE_MARKET_CLOSED) {
         Print("エラー: 注文送信失敗 - ", errorCode, " retcode=", result.retcode);
         return false;  // リトライしない
      }

      // その他のエラーはリトライ
      if(retry < totalRetries - 1) {
         Sleep(100);  // 100ms待機
      }
   }

   Print("エラー: 注文送信が", totalRetries, "回失敗しました");
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

   int ticket4 = (int)ticket;
   if(OrderSelect(ticket4, SELECT_BY_TICKET)) {
      if(OrderType() == OP_BUY) {
         return OrderClose(ticket4, OrderLots(), Bid, Slippage, clrNONE);
      } else if(OrderType() == OP_SELL) {
         return OrderClose(ticket4, OrderLots(), Ask, Slippage, clrNONE);
      }
   }

   return false;

   #endif
}

//+------------------------------------------------------------------+
//| 全ポジション非同期決済関数                                       |
//| 決済処理中はエントリーをブロック（g_ClosingInProgressUntil）      |
//+------------------------------------------------------------------+
void CloseAllPositionsAsync(bool useAsync = true, bool useCloseBy = false)
{
   // 決済処理中フラグ設定（エントリー割り込み防止）
   MarkClosingInProgress();

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
//| 相殺決済（CloseBy）がサポートされているか確認                   |
//+------------------------------------------------------------------+
bool IsCloseBySupported()
{
   #ifdef __MQL5__
   // アカウントタイプを取得
   ENUM_ACCOUNT_MARGIN_MODE marginMode = (ENUM_ACCOUNT_MARGIN_MODE)AccountInfoInteger(ACCOUNT_MARGIN_MODE);

   // ヘッジアカウントの場合のみCloseByが使用可能
   if(marginMode == ACCOUNT_MARGIN_MODE_RETAIL_HEDGING) {
      return true;
   }

   return false;

   #else // MQL4の場合

   // MQL4ではOrderCloseByが使用可能
   return true;

   #endif
}

//+------------------------------------------------------------------+
//| 単一チケット同期個別決済（CloseBy失敗フォールバック用）           |
//| ペア決済が割り込みや失敗で取りこぼした場合の安全網              |
//| 戻り値: true=決済成功 or 既に存在しない、false=決済失敗          |
//+------------------------------------------------------------------+
#ifdef __MQL5__
bool ClosePositionByTicketSync(ulong ticket)
{
   if(!PositionSelectByTicket(ticket)) {
      // 既にポジションが存在しない（CloseBy片側成功・別経路で決済済み等）
      return true;
   }

   MqlTradeRequest req;
   MqlTradeResult res;
   ZeroMemory(req);
   ZeroMemory(res);

   long posType = PositionGetInteger(POSITION_TYPE);
   req.action = TRADE_ACTION_DEAL;
   req.position = ticket;
   req.symbol = PositionGetString(POSITION_SYMBOL);
   req.volume = PositionGetDouble(POSITION_VOLUME);
   req.type = (posType == POSITION_TYPE_BUY) ? ORDER_TYPE_SELL : ORDER_TYPE_BUY;
   req.price = SymbolInfoDouble(req.symbol,
                                (posType == POSITION_TYPE_BUY) ? SYMBOL_BID : SYMBOL_ASK);
   req.deviation = Slippage;
   req.magic = (long)PositionGetInteger(POSITION_MAGIC);
   req.comment = "CloseBy Fallback";
   req.type_filling = GetFillingMode();

   bool ok = OrderSend(req, res);
   if(ok && (res.retcode == TRADE_RETCODE_DONE || res.retcode == TRADE_RETCODE_PLACED)) {
      return true;
   }

   Print("[CloseBy Fallback] 個別決済失敗: #", ticket,
         " retcode=", res.retcode, " LastError=", GetLastError());
   return false;
}
#endif

//+------------------------------------------------------------------+
//| 相殺決済を使った非同期全決済（MT5のみ）                         |
//| CloseBy失敗・取りこぼし対策:                                     |
//|   - CloseByは同期送信（retcode即時判定のため）                   |
//|   - retcode != DONE/PLACED → 個別決済へフォールバック            |
//|   - ペア決済後もチケット残存確認でセーフティネット               |
//+------------------------------------------------------------------+
#ifdef __MQL5__
void CloseAllWithCloseByAsync(bool useAsync = true)
{
   // 決済処理中フラグ設定（エントリー割り込み防止）
   MarkClosingInProgress();

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

   // CloseBy送信済みチケット記録（v3.48対策: 未コミット期間の重複close防止）
   // CloseByは accepted 応答後 数十ms かけて約定コミットするため、直後に
   // PositionSelectByTicket()でまだ残存して見える → 個別close重複送信で
   // 「Order to close this position already exists」エラーが発生する
   ulong closedByTickets[];
   int closedByCount = 0;
   ArrayResize(closedByTickets, 0);

   for(int i = 0; i < pairsToClose; i++) {
      MqlTradeRequest request;
      MqlTradeResult result;

      ZeroMemory(request);
      ZeroMemory(result);
      request.action = TRADE_ACTION_CLOSE_BY;
      request.position = buyTickets[i];
      request.position_by = sellTickets[i];
      request.symbol = Symbol();
      request.magic = MagicNumber;

      // CloseByは常に同期送信：retcodeを即座に判定してフォールバック判断
      // （非同期だとOrderSendAsyncの戻り値は「キューイング成功」のみで、
      //  実際の拒否をOnTradeTransactionまで待つ必要があり取りこぼし遅延が発生）
      bool success = OrderSend(request, result);
      bool retcodeOk = (result.retcode == TRADE_RETCODE_DONE ||
                        result.retcode == TRADE_RETCODE_PLACED);

      if(success && retcodeOk) {
         Print("相殺決済成功: Buy#", buyTickets[i], " ⇔ Sell#", sellTickets[i]);
         // 成功ペアを記録 → セーフティネットでの重複送信を回避
         ArrayResize(closedByTickets, closedByCount + 2);
         closedByTickets[closedByCount++] = buyTickets[i];
         closedByTickets[closedByCount++] = sellTickets[i];
      } else {
         // CloseBy失敗 → 個別決済フォールバック（ペア取りこぼし防止）
         Print("[CloseBy Fallback] 相殺決済失敗: Buy#", buyTickets[i],
               " Sell#", sellTickets[i],
               " retcode=", result.retcode, " LastError=", GetLastError(),
               " → 個別決済にフォールバック");
         ClosePositionByTicketSync(buyTickets[i]);
         ClosePositionByTicketSync(sellTickets[i]);
      }

      // 短い間隔で連続送信を抑制（ブローカー拒否防止）
      Sleep(10);
   }

   // 残りのポジション（ペア数の差分）を通常決済
   for(int i = pairsToClose; i < buyCount; i++) {
      ClosePositionAsync(buyTickets[i], useAsync);
      if(useAsync) Sleep(10);
   }

   for(int i = pairsToClose; i < sellCount; i++) {
      ClosePositionAsync(sellTickets[i], useAsync);
      if(useAsync) Sleep(10);
   }

   // セーフティネット: PositionsTotal()を再走査して残存チケットを個別決済
   // ただしCloseBy送信成功チケットはスキップ（未コミット期間の重複送信エラー回避）
   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0) continue;

      // CloseBy送信済みならスキップ（コミット中のため個別closeを送ると拒否される）
      bool alreadyClosedBy = false;
      for(int k = 0; k < closedByCount; k++) {
         if(closedByTickets[k] == ticket) {
            alreadyClosedBy = true;
            break;
         }
      }
      if(alreadyClosedBy) continue;

      if(!PositionSelectByTicket(ticket)) continue;
      if(PositionGetInteger(POSITION_MAGIC) != MagicNumber) continue;
      if(PositionGetString(POSITION_SYMBOL) != Symbol()) continue;

      // 残存ポジションを個別決済
      Print("[CloseBy Fallback] 残存ポジション検出: #", ticket, " → 個別決済");
      ClosePositionByTicketSync(ticket);
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

   int ticket4 = (int)ticket;
   if(OrderSelect(ticket4, SELECT_BY_TICKET)) {
      return OrderModify(ticket4, OrderOpenPrice(), sl, tp, 0, clrNONE);
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

   int ticket4 = (int)ticket;
   if(OrderSelect(ticket4, SELECT_BY_TICKET)) {
      return OrderModify(ticket4, price, sl, tp, expiration, clrNONE);
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
         double newSL = SymbolInfoDouble(_Symbol, SYMBOL_BID) - trail;
         if(newSL > openPrice && (currentSL == 0 || newSL > currentSL)) {
            ModifyPositionAsync(ticket, newSL, currentTP, useAsync);
            if(useAsync) Sleep(10);
         }
      } else if(type == POSITION_TYPE_SELL) {
         double newSL = SymbolInfoDouble(_Symbol, SYMBOL_ASK) + trail;
         if(newSL < openPrice && (currentSL == 0 || newSL < currentSL)) {
            ModifyPositionAsync(ticket, newSL, currentTP, useAsync);
            if(useAsync) Sleep(10);
         }
      }
   }

   #else // MQL4の場合

   double trail = trailPoints * _Point;

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

   int ticket4 = (int)ticket;
   if(OrderSelect(ticket4, SELECT_BY_TICKET)) {
      if(OrderType() > OP_SELL) {  // 待機注文のみ
         return OrderDelete(ticket4, clrNONE);
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
//| 非同期処理の状態管理構造体（レガシー・エントリー用）              |
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
//| ========== AsyncTracker（SL/TP変更用非同期追跡）========== |
//| eldra2から移植                                                   |
//+------------------------------------------------------------------+

#ifdef __MQL5__

enum ENUM_ASYNC_REQ_TYPE {
   ASYNC_REQ_SLTP_MODIFY = 0,   // SL/TP変更
   ASYNC_REQ_CLOSE_POSITION      // ポジション決済
};

struct AsyncPendingRequest {
   uint     request_id;        // OrderSendAsyncが返したID
   ENUM_ASYNC_REQ_TYPE type;   // リクエスト種別
   ulong    position_ticket;   // 対象ポジションチケット
   double   target_sl;         // SL変更時の目標SL値
   double   target_tp;         // SL変更時の目標TP値
   datetime send_time;         // 送信時刻
   string   source;            // "Trailing"等
   bool     isBuy;             // BUYポジションか
};

AsyncPendingRequest g_AsyncPending[];
int g_AsyncPendingCount = 0;
const int ASYNC_TIMEOUT_SECONDS = 10;
const int ASYNC_MAX_PENDING = 64;

//+------------------------------------------------------------------+
//| AsyncTracker: リクエスト登録                                      |
//+------------------------------------------------------------------+
bool AsyncTracker_Register(uint requestId, ENUM_ASYNC_REQ_TYPE type,
                           ulong ticket, double sl=0, double tp=0,
                           string source="", bool isBuy=true)
{
   if(requestId == 0) return false;

   // 同じticket+typeの古いエントリを更新
   for(int i = 0; i < g_AsyncPendingCount; i++) {
      if(g_AsyncPending[i].position_ticket == ticket &&
         g_AsyncPending[i].type == type) {
         g_AsyncPending[i].request_id = requestId;
         g_AsyncPending[i].target_sl = sl;
         g_AsyncPending[i].target_tp = tp;
         g_AsyncPending[i].send_time = TimeCurrent();
         g_AsyncPending[i].source = source;
         return true;
      }
   }

   if(g_AsyncPendingCount >= ASYNC_MAX_PENDING) {
      AsyncTracker_Cleanup();
      if(g_AsyncPendingCount >= ASYNC_MAX_PENDING) return false;
   }

   ArrayResize(g_AsyncPending, g_AsyncPendingCount + 1);
   g_AsyncPending[g_AsyncPendingCount].request_id = requestId;
   g_AsyncPending[g_AsyncPendingCount].type = type;
   g_AsyncPending[g_AsyncPendingCount].position_ticket = ticket;
   g_AsyncPending[g_AsyncPendingCount].target_sl = sl;
   g_AsyncPending[g_AsyncPendingCount].target_tp = tp;
   g_AsyncPending[g_AsyncPendingCount].send_time = TimeCurrent();
   g_AsyncPending[g_AsyncPendingCount].source = source;
   g_AsyncPending[g_AsyncPendingCount].isBuy = isBuy;
   g_AsyncPendingCount++;
   return true;
}

//+------------------------------------------------------------------+
//| AsyncTracker: ポジションが処理中かチェック                        |
//+------------------------------------------------------------------+
bool AsyncTracker_IsPositionBusy(ulong ticket, ENUM_ASYNC_REQ_TYPE type)
{
   datetime now = TimeCurrent();
   for(int i = 0; i < g_AsyncPendingCount; i++) {
      if(g_AsyncPending[i].position_ticket == ticket &&
         g_AsyncPending[i].type == type &&
         (now - g_AsyncPending[i].send_time) < ASYNC_TIMEOUT_SECONDS) {
         return true;
      }
   }
   return false;
}

//+------------------------------------------------------------------+
//| AsyncTracker: リクエストIDで検索・削除                            |
//+------------------------------------------------------------------+
bool AsyncTracker_FindAndRemove(uint requestId, AsyncPendingRequest &info)
{
   for(int i = 0; i < g_AsyncPendingCount; i++) {
      if(g_AsyncPending[i].request_id == requestId) {
         info = g_AsyncPending[i];
         for(int j = i; j < g_AsyncPendingCount - 1; j++)
            g_AsyncPending[j] = g_AsyncPending[j + 1];
         g_AsyncPendingCount--;
         return true;
      }
   }
   return false;
}

//+------------------------------------------------------------------+
//| AsyncTracker: タイムアウトしたエントリをクリーンアップ            |
//+------------------------------------------------------------------+
void AsyncTracker_Cleanup()
{
   datetime now = TimeCurrent();
   for(int i = g_AsyncPendingCount - 1; i >= 0; i--) {
      if((now - g_AsyncPending[i].send_time) > ASYNC_TIMEOUT_SECONDS * 2) {
         for(int j = i; j < g_AsyncPendingCount - 1; j++)
            g_AsyncPending[j] = g_AsyncPending[j + 1];
         g_AsyncPendingCount--;
      }
   }
}

#endif // __MQL5__

//+------------------------------------------------------------------+
//| ========== SLエラー分類（eldra2から移植）========== |
//+------------------------------------------------------------------+
bool IsSLFatalError(uint errorCode, uint retcode)
{
   switch(retcode) {
      case 10016:  // TRADE_RETCODE_INVALID_STOPS
      case 10023:  // ポジション閉鎖済み
      case 10024:  // 無効なオーダー
      case 10025:  // 注文数上限
         return true;
   }
   switch(errorCode) {
      case 4756:   // ERR_TRADE_INVALID_FILL
      case 130:    // MQL4 ERR_INVALID_STOPS（ブローカーSL不可 → 仮想SLへ）
      case 131:    // MQL4 ERR_INVALID_TRADE_VOLUME（Invalid stops系として扱う）
         return true;
   }
   return false;
}

bool IsSLRetryableError(uint errorCode, uint retcode)
{
   switch(retcode) {
      case 10004:  // リクォート
      case 10006:  // リジェクト（一時的）
      case 10012:  // タイムアウト
      case 10020:  // 価格変更
         return true;
   }
   switch(errorCode) {
      case 4752:   // 取引リクエスト失敗
      case 4753:   // 送信失敗
      case 4755:   // タイムアウト
         return true;
   }
   return false;
}

//+------------------------------------------------------------------+
//| ========== SLリトライキュー（eldra2から移植）========== |
//+------------------------------------------------------------------+

#ifdef __MQL5__

struct SLRetryItem {
   ulong    ticket;           // ポジションチケット
   double   newStopLoss;      // 目標SL値
   double   takeProfit;       // TP値
   int      retryCount;       // リトライ回数
   int      maxRetries;       // 最大リトライ回数
   datetime lastAttempt;      // 最終試行時刻
   datetime nextAttempt;      // 次回試行時刻
   int      retryIntervalMs;  // リトライ間隔（ミリ秒）
   uint     lastError;        // 最後のエラーコード
   uint     lastRetcode;      // 最後のリターンコード
   string   source;           // リトライ元
};

SLRetryItem g_SLRetryQueue[];
int g_SLRetryQueueSize = 0;

int    g_SLRetryMaxAttempts = 5;
int    g_SLRetryIntervalMs = 500;
int    g_SLRetryBackoffMultiplier = 2;
int    g_SLRetryMaxIntervalMs = 5000;

//+------------------------------------------------------------------+
//| SLリトライキューに追加                                            |
//+------------------------------------------------------------------+
bool AddSLRetry(ulong ticket, double newStopLoss, double takeProfit,
                uint errorCode, uint retcode, string source = "Trailing")
{
   if(IsSLFatalError(errorCode, retcode)) {
      PrintFormat("[SLRetry] 致命的エラーのためリトライ不可: #%I64u, Error=%d, Retcode=%d",
                  ticket, errorCode, retcode);
      return false;
   }
   if(!IsSLRetryableError(errorCode, retcode)) {
      PrintFormat("[SLRetry] リトライ対象外: #%I64u, Error=%d, Retcode=%d",
                  ticket, errorCode, retcode);
      return false;
   }

   // 既存エントリを更新
   for(int i = 0; i < g_SLRetryQueueSize; i++) {
      if(g_SLRetryQueue[i].ticket == ticket) {
         g_SLRetryQueue[i].newStopLoss = newStopLoss;
         g_SLRetryQueue[i].takeProfit = takeProfit;
         g_SLRetryQueue[i].lastError = errorCode;
         g_SLRetryQueue[i].lastRetcode = retcode;
         g_SLRetryQueue[i].source = source;
         return true;
      }
   }

   // 新規追加
   ArrayResize(g_SLRetryQueue, g_SLRetryQueueSize + 1);

   SLRetryItem item;
   item.ticket = ticket;
   item.newStopLoss = newStopLoss;
   item.takeProfit = takeProfit;
   item.retryCount = 0;
   item.maxRetries = g_SLRetryMaxAttempts;
   item.lastAttempt = TimeCurrent();
   item.nextAttempt = TimeCurrent() + (g_SLRetryIntervalMs / 1000) + 1;
   item.retryIntervalMs = g_SLRetryIntervalMs;
   item.lastError = errorCode;
   item.lastRetcode = retcode;
   item.source = source;

   g_SLRetryQueue[g_SLRetryQueueSize] = item;
   g_SLRetryQueueSize++;

   PrintFormat("[SLRetry] キューに追加: #%I64u, SL=%.5f, Error=%d, Retcode=%d",
               ticket, newStopLoss, errorCode, retcode);
   return true;
}

//+------------------------------------------------------------------+
//| SLリトライキューから削除                                          |
//+------------------------------------------------------------------+
void RemoveSLRetry(int index)
{
   if(index < 0 || index >= g_SLRetryQueueSize) return;
   for(int i = index; i < g_SLRetryQueueSize - 1; i++)
      g_SLRetryQueue[i] = g_SLRetryQueue[i + 1];
   g_SLRetryQueueSize--;
   ArrayResize(g_SLRetryQueue, g_SLRetryQueueSize);
}

//+------------------------------------------------------------------+
//| SLリトライ処理（指数バックオフ）                                  |
//+------------------------------------------------------------------+
void ProcessSLRetries()
{
   if(g_SLRetryQueueSize == 0) return;

   datetime currentTime = TimeCurrent();

   for(int i = g_SLRetryQueueSize - 1; i >= 0; i--) {
      SLRetryItem item = g_SLRetryQueue[i];

      // 次回試行時刻まで待機
      if(currentTime < item.nextAttempt) continue;

      // ポジション存在チェック
      if(!PositionSelectByTicket(item.ticket)) {
         PrintFormat("[SLRetry] ポジション消失: #%I64u", item.ticket);
         RemoveSLRetry(i);
         continue;
      }

      // SLが既に有利な値に設定されているか確認
      double currentSL = PositionGetDouble(POSITION_SL);
      bool isBuy = (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY);

      if(currentSL != 0) {
         bool slAlreadyBetter = isBuy ?
            (currentSL >= item.newStopLoss) :
            (currentSL <= item.newStopLoss);
         if(slAlreadyBetter) {
            PrintFormat("[SLRetry] SL既に設定済み: #%I64u, Current=%.5f, Target=%.5f",
                        item.ticket, currentSL, item.newStopLoss);
            RemoveSLRetry(i);
            continue;
         }
      }

      // リトライ実行
      item.retryCount++;
      item.lastAttempt = currentTime;

      PrintFormat("[SLRetry] リトライ: #%I64u, SL=%.5f, Attempt=%d/%d",
                  item.ticket, item.newStopLoss, item.retryCount, item.maxRetries);

      MqlTradeRequest req;
      MqlTradeResult res;
      ZeroMemory(req);
      ZeroMemory(res);
      req.action = TRADE_ACTION_SLTP;
      req.symbol = PositionGetString(POSITION_SYMBOL);
      req.magic = MagicNumber;
      req.sl = item.newStopLoss;
      req.tp = item.takeProfit;
      req.position = item.ticket;

      bool success = OrderSend(req, res);

      if(success && (res.retcode == TRADE_RETCODE_DONE || res.retcode == 10009)) {
         PrintFormat("[SLRetry] 成功: #%I64u, SL=%.5f, Attempts=%d",
                     item.ticket, item.newStopLoss, item.retryCount);
         RemoveSLRetry(i);
         continue;
      }

      uint newError = GetLastError();
      uint newRetcode = res.retcode;

      // 致命的エラー → 仮想SL（成行決済フォールバック）
      if(IsSLFatalError(newError, newRetcode)) {
         PrintFormat("[SLRetry] 致命的エラー → 仮想SLモードへ: #%I64u, Error=%d, Retcode=%d",
                     item.ticket, newError, newRetcode);
         RemoveSLRetry(i);
         continue;
      }

      // 最大リトライ超過
      if(item.retryCount >= item.maxRetries) {
         PrintFormat("[SLRetry] 最大リトライ超過 → 仮想SLモードへ: #%I64u, Attempts=%d",
                     item.ticket, item.retryCount);
         RemoveSLRetry(i);
         continue;
      }

      // 指数バックオフで次回スケジュール
      item.retryIntervalMs = MathMin(item.retryIntervalMs * g_SLRetryBackoffMultiplier, g_SLRetryMaxIntervalMs);
      item.nextAttempt = currentTime + (item.retryIntervalMs / 1000) + 1;
      item.lastError = newError;
      item.lastRetcode = newRetcode;
      g_SLRetryQueue[i] = item;

      PrintFormat("[SLRetry] 次回リトライ: #%I64u, Interval=%dms",
                  item.ticket, item.retryIntervalMs);
   }
}

#endif // __MQL5__

//+------------------------------------------------------------------+
//| SL変更（非同期追跡・エラーハンドリング付き）                      |
//| eldra2のModifyStopLossから移植                                    |
//+------------------------------------------------------------------+
void ModifyStopLossAsync(ulong ticket, double newStopLoss, string source = "Trailing")
{
#ifdef __MQL5__
   if(!PositionSelectByTicket(ticket)) return;

   // 現在のSLと同値なら重複送信しない
   double currentSL = PositionGetDouble(POSITION_SL);
   if(MathAbs(currentSL - newStopLoss) < _Point) return;

   double takeProfit = PositionGetDouble(POSITION_TP);
   bool isBuy = (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY);

   // 既に処理中なら二重送信しない
   if(AsyncTracker_IsPositionBusy(ticket, ASYNC_REQ_SLTP_MODIFY)) return;

   // SL変更リクエスト送信
   MqlTradeRequest req;
   MqlTradeResult res;
   ZeroMemory(req);
   ZeroMemory(res);
   req.action = TRADE_ACTION_SLTP;
   req.symbol = _Symbol;
   req.magic = MagicNumber;
   req.sl = newStopLoss;
   req.tp = takeProfit;
   req.position = ticket;

   bool orderResult = OrderSendAsync(req, res);
   uint errorCode = GetLastError();
   uint retcode = res.retcode;
   uint requestId = res.request_id;

   if(orderResult) {
      // 非同期送信成功: AsyncTrackerに登録
      if(requestId > 0) {
         AsyncTracker_Register(requestId, ASYNC_REQ_SLTP_MODIFY,
                               ticket, newStopLoss, takeProfit, source, isBuy);
      }
   } else {
      // 致命的エラー → 仮想SL（成行決済フォールバック）に任せる
      if(IsSLFatalError(errorCode, retcode)) {
         PrintFormat("[ModifySL] 致命的エラー → 仮想SLで監視継続: #%I64u, Error=%d, Retcode=%d",
                     ticket, errorCode, retcode);
      }
      // リトライ可能なエラー → SLリトライキューに追加
      else if(IsSLRetryableError(errorCode, retcode)) {
         AddSLRetry(ticket, newStopLoss, takeProfit, errorCode, retcode, source);
      }
      else {
         PrintFormat("[ModifySL] SL変更失敗（リトライ対象外）: #%I64u, Error=%d, Retcode=%d",
                     ticket, errorCode, retcode);
      }
   }

#else // MQL4
   int ticket4 = (int)ticket;
   if(OrderSelect(ticket4, SELECT_BY_TICKET)) {
      if(!OrderModify(ticket4, OrderOpenPrice(), newStopLoss, OrderTakeProfit(), 0, clrNONE)) {
         uint errorCode = (uint)GetLastError();
         // 致命的エラー（130/131 Invalid stops 等）→ ブローカーSLが付かないため、
         // 仮想トレールSL（TSMの成行決済監視）へフォールバックして保護を継続する。
         // ※呼び出し元のトレーリングが TSM_Activate() 済みなので TSM が確実に決済する
         if(IsSLFatalError(errorCode, 0)) {
            PrintFormat("[ModifySL] MQL4 SL設定不可(致命) → 仮想SLで監視継続: #%d, Error=%d", ticket4, errorCode);
         } else {
            PrintFormat("[ModifySL] MQL4 SL変更失敗: #%d, Error=%d", ticket4, errorCode);
         }
      }
   }
#endif
}

//+------------------------------------------------------------------+
//| OnTradeTransactionイベント処理（MT5のみ）                        |
//| AsyncTracker対応版                                                |
//+------------------------------------------------------------------+
#ifdef __MQL5__
void ProcessAsyncTradeTransaction(const MqlTradeTransaction& trans,
                                   const MqlTradeRequest& request,
                                   const MqlTradeResult& result)
{
   if(trans.type != TRADE_TRANSACTION_REQUEST) return;

   // === AsyncTracker（SL/TP変更追跡）===
   AsyncPendingRequest info;
   if(AsyncTracker_FindAndRemove(result.request_id, info)) {
      bool success = (result.retcode == TRADE_RETCODE_DONE ||
                      result.retcode == TRADE_RETCODE_DONE_PARTIAL);

      if(info.type == ASYNC_REQ_SLTP_MODIFY) {
         if(!success) {
            PrintFormat("[AsyncTracker] SL変更失敗: #%I64u, retcode=%u, source=%s",
                        info.position_ticket, result.retcode, info.source);
            uint errCode = (uint)GetLastError();
            AddSLRetry(info.position_ticket, info.target_sl, info.target_tp,
                       errCode, result.retcode, info.source);
         }
      }
      else if(info.type == ASYNC_REQ_CLOSE_POSITION) {
         if(!success) {
            PrintFormat("[AsyncTracker] 決済失敗: #%I64u, retcode=%u, source=%s",
                        info.position_ticket, result.retcode, info.source);
         } else {
            PrintFormat("[AsyncTracker] 決済成功: #%I64u, source=%s",
                        info.position_ticket, info.source);
         }
      }
      return;
   }

   // === レガシー追跡（エントリー等）===
   for(int i = 0; i < ArraySize(g_AsyncOrders); i++) {
      if(g_AsyncOrders[i].requestId == result.request_id) {
         if(result.retcode == TRADE_RETCODE_DONE) {
            g_AsyncOrders[i].success = true;
            g_AsyncOrders[i].completed = true;
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
#endif

#endif // HOSOPI3_ASYNC_H