//+------------------------------------------------------------------+
//|                Hosopi 3 - 決済機能専用ファイル                    |
//|                        Copyright 2025                            |
//+------------------------------------------------------------------+
#include "Hosopi3_Defines.mqh"
#include "Hosopi3_Compat.mqh"
#include "Hosopi3_Trading.mqh"
#include "Hosopi3_Utils.mqh"
#include "Hosopi3_Ghost.mqh"


int GetTakeProfitPointsByPositionCount(int positionCount)
{
   // ポジション数に応じた利確設定が無効の場合は固定値を返す
   if(!VariableTP_Enabled)
      return TakeProfitPoints;
   
   // ポジション数に基づいて利確幅を返す
   switch(positionCount)
   {
      case 1:  return TP_Level1;
      case 2:  return TP_Level2;
      case 3:  return TP_Level3;
      case 4:  return TP_Level4;
      case 5:  return TP_Level5;
      case 6:  return TP_Level6;
      case 7:  return TP_Level7;
      case 8:  return TP_Level8;
      case 9:  return TP_Level9;
      case 10: return TP_Level10;
      case 11: return TP_Level11;
      case 12: return TP_Level12;
      case 13: return TP_Level13;
      case 14: return TP_Level14;
      case 15: return TP_Level15;
      case 16: return TP_Level16;
      case 17: return TP_Level17;
      case 18: return TP_Level18;
      case 19: return TP_Level19;
      case 20: return TP_Level20;
      case 21: return TP_Level21;
      case 22: return TP_Level22;
      case 23: return TP_Level23;
      case 24: return TP_Level24;
      case 25: return TP_Level25;
      case 26: return TP_Level26;
      case 27: return TP_Level27;
      case 28: return TP_Level28;
      case 29: return TP_Level29;
      case 30: return TP_Level30;
      case 31: return TP_Level31;
      case 32: return TP_Level32;
      case 33: return TP_Level33;
      case 34: return TP_Level34;
      case 35: return TP_Level35;
      case 36: return TP_Level36;
      case 37: return TP_Level37;
      case 38: return TP_Level38;
      case 39: return TP_Level39;
      case 40: return TP_Level40;
      default: return TP_Level40; // 40ポジション以上は最後のレベルを使用
   }
}


//+------------------------------------------------------------------+
//| トレールストップ条件のチェック                                    |
//+------------------------------------------------------------------+
void CheckTrailingStopConditions(int side)
{
   // トレールストップが無効な場合はスキップ
   if(!EnableTrailingStop)
   {
      return;
   }

   // 処理対象のオペレーションタイプを決定
   int operationType = (side == 0) ? OP_BUY : OP_SELL;

   // リアルポジションがない場合はスキップ
   int positionCount = position_count(operationType);
   if(positionCount <= 0)
      return;

   // 平均価格を計算 - ナンピンレベル廃止対応
   double avgPrice = CalculateCombinedAveragePrice(operationType);
   if(avgPrice <= 0)
      return;

   // 現在価格を取得（BuyならBid、SellならAsk）
   double currentPrice = (side == 0) ? GetBidPrice() : GetAskPrice();

   // トレールトリガー価格とオフセット価格を計算
   double triggerPrice, stopPrice;
   
   // Point値を取得
   double pointValue = GetPointValue();
   
   if(side == 0) // Buy
   {
      // トレールトリガー: 平均価格 + トリガーポイント
      triggerPrice = avgPrice + TrailingTrigger * pointValue;
      
      // 現在価格がトリガー以上の場合のみトレーリング
      if(currentPrice >= triggerPrice)
      {
         // ストップ価格: 現在価格 - オフセット
         stopPrice = currentPrice - TrailingOffset * pointValue;
         
         // 各ポジションの決済条件をチェック
#ifdef __MQL5__
         for(int i = PositionsTotal() - 1; i >= 0; i--)
         {
            ulong ticket = PositionGetTicket(i);
            if(ticket > 0)
            {
               if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY && 
                  PositionGetString(POSITION_SYMBOL) == Symbol() && 
                  PositionGetInteger(POSITION_MAGIC) == MagicNumber)
               {
                  // 現在のストップロスを確認
                  double currentSL = PositionGetDouble(POSITION_SL);
                  
                  // ストップロスが設定されていないか、または新しいストップが現在より高い場合
                  if(currentSL == 0 || stopPrice > currentSL)
                  {
                     // ストップロスを修正
                     MqlTradeRequest request;
                     MqlTradeResult result;
                     ZeroMemory(request);
                     ZeroMemory(result);
                     
                     request.action = TRADE_ACTION_SLTP;
                     request.position = ticket;
                     request.symbol = Symbol();
                     request.sl = stopPrice;
                     request.tp = PositionGetDouble(POSITION_TP);
                     request.type_filling = (ENUM_ORDER_TYPE_FILLING)OrderFillingType;
                     
                     if(OrderSend(request, result))
                     {
                        // 成功
                     }
                     else
                     {
                        Print("Buy トレールストップ更新エラー: ", result.retcode);
                     }
                  }
               }
            }
         }
#else // MQL4
         for(int i = OrdersTotal() - 1; i >= 0; i--)
         {
            if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
            {
               if(OrderType() == operationType && OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumber)
               {
                  // 現在のストップロスを確認
                  double currentSL = OrderStopLoss();
                  
                  // ストップロスが設定されていないか、または新しいストップが現在より高い場合
                  if(currentSL == 0 || stopPrice > currentSL)
                  {
                     // ストップロスを修正
                     bool result = OrderModify(OrderTicket(), OrderOpenPrice(), stopPrice, OrderTakeProfit(), 0, clrGreen);
                     if(result)
                     {
                       
                     }
                     else
                     {
                        Print("Buy トレールストップ更新エラー: ", GetLastError());
                     }
                  }
               }
            }
         }
#endif
      }
   }
   else // Sell
   {
      // トレールトリガー: 平均価格 - トリガーポイント
      triggerPrice = avgPrice - TrailingTrigger * pointValue;
      
      // 現在価格がトリガー以下の場合のみトレーリング
      if(currentPrice <= triggerPrice)
      {
         // ストップ価格: 現在価格 + オフセット
         stopPrice = currentPrice + TrailingOffset * pointValue;
         
         // 各ポジションの決済条件をチェック
#ifdef __MQL5__
         for(int i = PositionsTotal() - 1; i >= 0; i--)
         {
            ulong ticket = PositionGetTicket(i);
            if(ticket > 0)
            {
               if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL && 
                  PositionGetString(POSITION_SYMBOL) == Symbol() && 
                  PositionGetInteger(POSITION_MAGIC) == MagicNumber)
               {
                  // 現在のストップロスを確認
                  double currentSL = PositionGetDouble(POSITION_SL);
                  
                  // ストップロスが設定されていないか、または新しいストップが現在より低い場合
                  if(currentSL == 0 || stopPrice < currentSL)
                  {
                     // ストップロスを修正
                     MqlTradeRequest request;
                     MqlTradeResult result;
                     ZeroMemory(request);
                     ZeroMemory(result);
                     
                     request.action = TRADE_ACTION_SLTP;
                     request.position = ticket;
                     request.symbol = Symbol();
                     request.sl = stopPrice;
                     request.tp = PositionGetDouble(POSITION_TP);
                     request.type_filling = (ENUM_ORDER_TYPE_FILLING)OrderFillingType;
                     
                     if(OrderSend(request, result))
                     {
                        // 成功
                     }
                     else
                     {
                        Print("Sell トレールストップ更新エラー: ", result.retcode);
                     }
                  }
               }
            }
         }
#else // MQL4
         for(int i = OrdersTotal() - 1; i >= 0; i--)
         {
            if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
            {
               if(OrderType() == operationType && OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumber)
               {
                  // 現在のストップロスを確認
                  double currentSL = OrderStopLoss();
                  
                  // ストップロスが設定されていないか、または新しいストップが現在より低い場合
                  if(currentSL == 0 || stopPrice < currentSL)
                  {
                     // ストップロスを修正
                     bool result = OrderModify(OrderTicket(), OrderOpenPrice(), stopPrice, OrderTakeProfit(), 0, clrRed);
                     if(result)
                     {
                        
                     }
                     else
                     {
                        Print("Sell トレールストップ更新エラー: ", GetLastError());
                     }
                  }
               }
            }
         }
#endif
      }
   }
}

//+------------------------------------------------------------------+
//| ゴーストポジションのトレーリングストップを計算・更新する関数      |
//+------------------------------------------------------------------+
void CheckGhostTrailingStopConditions(int side)
{
   // トレールストップが無効な場合はスキップ
   if(!EnableTrailingStop)
   {
      return;
   }

   // 処理対象のオペレーションタイプを決定
   int operationType = (side == 0) ? OP_BUY : OP_SELL;

   // ゴーストポジションがない場合はスキップ
   int ghostCount = ghost_position_count(operationType);
   if(ghostCount <= 0)
      return;

   // 平均価格を計算 - ナンピンレベル廃止対応
   double avgPrice = CalculateGhostAveragePrice(operationType);
   if(avgPrice <= 0)
      return;

   // 現在価格を取得（BuyならBid、SellならAsk）
   double currentPrice = (side == 0) ? GetBidPrice() : GetAskPrice();

   // トレールトリガー価格とオフセット価格を計算
   double triggerPrice, stopPrice;
   
   // Point値を取得
   double pointValue = GetPointValue();
   
   if(side == 0) // Buy
   {
      // トレールトリガー: 平均価格 + トリガーポイント
      triggerPrice = avgPrice + TrailingTrigger * pointValue;
      
      // 現在価格がトリガー以上の場合のみトレーリング
      if(currentPrice >= triggerPrice)
      {
         // ストップ価格: 現在価格 - オフセット
         stopPrice = currentPrice - TrailingOffset * pointValue;
         
         // 各ゴーストポジションのストップロスを更新
         int buyMaxIndex = MathMin(g_GhostBuyCount, 40);
         for(int i = 0; i < buyMaxIndex; i++)
         {
            if(g_GhostBuyPositions[i].isGhost) // 有効なゴーストのみ
            {
               // 現在のストップロスを確認
               double currentSL = g_GhostBuyPositions[i].stopLoss;
               
               // ストップロスが設定されていないか、または新しいストップが現在より高い場合
               if(currentSL == 0 || stopPrice > currentSL)
               {
                  // ストップロスを更新
                  g_GhostBuyPositions[i].stopLoss = stopPrice;
                  // ゴーストBuy トレールストップ更新
               }
            }
         }
         
         // ストップラインを表示
         UpdateGhostStopLine(side, stopPrice);
      }
   }
   else // Sell
   {
      // トレールトリガー: 平均価格 - トリガーポイント
      triggerPrice = avgPrice - TrailingTrigger * pointValue;
      
      // 現在価格がトリガー以下の場合のみトレーリング
      if(currentPrice <= triggerPrice)
      {
         // ストップ価格: 現在価格 + オフセット
         stopPrice = currentPrice + TrailingOffset * pointValue;
         
         // 各ゴーストポジションのストップロスを更新
         int sellMaxIndex = MathMin(g_GhostSellCount, 40);
         for(int i = 0; i < sellMaxIndex; i++)
         {
            if(g_GhostSellPositions[i].isGhost) // 有効なゴーストのみ
            {
               // 現在のストップロスを確認
               double currentSL = g_GhostSellPositions[i].stopLoss;
               
               // ストップロスが設定されていないか、または新しいストップが現在より低い場合
               if(currentSL == 0 || stopPrice < currentSL)
               {
                  // ストップロスを更新
                  g_GhostSellPositions[i].stopLoss = stopPrice;
                  // ゴーストSell トレールストップ更新
               }
            }
         }
         
         // ストップラインを表示
         UpdateGhostStopLine(side, stopPrice);
      }
   }
   
   // グローバル変数に保存
   SaveGhostPositionsToGlobal();
   
   // ストップロス発動チェック
   CheckGhostStopLossHit(side);
}



//+------------------------------------------------------------------+
//| 利確処理の統合関数 - 決済方法に応じて処理 (通知機能対応版)         |
//+------------------------------------------------------------------+
void ManageTakeProfit(int side)
{
   // 利確が無効な場合はスキップ
   if(TakeProfitMode == TP_OFF)
      return;

   // 処理対象のオペレーションタイプを決定
   int operationType = (side == 0) ? OP_BUY : OP_SELL;
   int oppositeType = (side == 0) ? OP_SELL : OP_BUY;
   string direction = (side == 0) ? "Buy" : "Sell";

   // ポジションとゴーストカウントの取得 - ナンピンレベル廃止対応
   int positionCount = position_count(operationType);
   int ghostCount = ghost_position_count(operationType);

   // ポジション・ゴーストどちらも無い場合はスキップ
   if(positionCount <= 0 && ghostCount <= 0)
      return;

   // 平均価格を計算 - ナンピンレベル廃止対応
   double avgPrice = CalculateCombinedAveragePrice(operationType);
   if(avgPrice <= 0)
      return;

   // 現在価格を取得（BuyならBid、SellならAsk）
   double currentPrice = (side == 0) ? GetBidPrice() : GetAskPrice();

   // ポジション数に応じた利確幅を取得 - ナンピンレベル廃止対応
   int totalPositions = positionCount + ghostCount;
   int tpPoints = GetTakeProfitPointsByPositionCount(totalPositions);

   // Point値を取得
   double pointValue = GetPointValue();

   // TP価格の計算（ロット加重平均の価格から指定ポイント離れた価格）
   double tpPrice = (side == 0) ? 
                  avgPrice + tpPoints * pointValue : 
                  avgPrice - tpPoints * pointValue;

   // ======== 指値決済処理（LIMIT） ========
   if(TakeProfitMode == TP_LIMIT)
   {
      // シンボルの最小ストップレベルを取得
      int minStopLevel = GetMinStopLevel();
      
      // 最小ストップレベルを考慮してTP価格を調整
      double minAllowedTPDistance = minStopLevel * pointValue;
      
      // Buy注文の場合、TPは現在Bid価格より十分高くなければならない
      if(side == 0 && tpPrice - currentPrice < minAllowedTPDistance)
      {
         tpPrice = currentPrice + minAllowedTPDistance;
         // 警告: リミットTP価格が最小ストップレベルに近すぎるため調整
      }
      // Sell注文の場合、TPは現在Ask価格より十分低くなければならない
      else if(side == 1 && currentPrice - tpPrice < minAllowedTPDistance)
      {
         tpPrice = currentPrice - minAllowedTPDistance;
         // 警告: リミットTP価格が最小ストップレベルに近すぎるため調整
      }
      
      // ゴーストポジションのみの場合の処理
      if(positionCount == 0 && ghostCount > 0)
      {
         // 利確条件の判定（ゴーストの場合も同じ条件でチェック）
         bool tpCondition = false;

         if(side == 0) // Buy
         {
            // Buy側の利確条件: 現在価格が平均価格+TPポイント以上
            tpCondition = (currentPrice >= tpPrice);
         }
         else // Sell
         {
            // Sell側の利確条件: 現在価格が平均価格-TPポイント以下
            tpCondition = (currentPrice <= tpPrice);
         }

         // 利確条件が満たされた場合
         if(tpCondition)
         {
            // ゴーストのみで利確条件成立
            
            // 決済前に利益を計算
            double ghostProfit = CalculateGhostProfit(operationType);
            
            // ゴーストポジションをリセット
            if(operationType == OP_BUY) {
               // ゴーストポジションの状態をリセット
               int buyMaxIndex = MathMin(g_GhostBuyCount, 40);
               for(int i = 0; i < buyMaxIndex; i++) {
                  g_GhostBuyPositions[i].isGhost = false;  // ゴーストフラグをオフに
               }
               // 決済済みフラグを設定
               g_BuyGhostClosed = true;
               g_GhostBuyCount = 0;
            } else {
               // ゴーストポジションの状態をリセット
               int sellMaxIndex = MathMin(g_GhostSellCount, 40);
               for(int i = 0; i < sellMaxIndex; i++) {
                  g_GhostSellPositions[i].isGhost = false;  // ゴーストフラグをオフに
               }
               // 決済済みフラグを設定
               g_SellGhostClosed = true;
               g_GhostSellCount = 0;
            }
            
            // 点線オブジェクトを削除
            DeleteGhostLinesAndPreventRecreation(operationType);
            
            // グローバル変数を更新
            SaveGhostPositionsToGlobal();
            
            // ゴーストポジション利確完了
            
            // 平均価格ラインとTPラインを削除
            CleanupLinesOnClose(side);
            
            // テーブルを更新
            UpdatePositionTable();
            
            // ゴースト決済通知を送信
            NotifyGhostClosure(operationType, ghostProfit);
         }
      }
      
      // リアルポジションがある場合は通常の指値設定
      if(positionCount > 0)
      {
#ifdef __MQL5__
         // MQL5用の処理
         for(int i = PositionsTotal() - 1; i >= 0; i--)
         {
            ulong ticket = PositionGetTicket(i);
            if(ticket > 0)
            {
               if(PositionGetInteger(POSITION_TYPE) == ((operationType == OP_BUY) ? POSITION_TYPE_BUY : POSITION_TYPE_SELL) && 
                  PositionGetString(POSITION_SYMBOL) == Symbol() && 
                  PositionGetInteger(POSITION_MAGIC) == MagicNumber)
               {
                  // 現在のストップロス価格を取得
                  double currentSL = PositionGetDouble(POSITION_SL);
                  
                  // 現在のテイクプロフィット価格を取得
                  double currentTP = PositionGetDouble(POSITION_TP);
                  
                  // 新しいTPとの差が小さい場合はスキップ
                  if(MathAbs(currentTP - tpPrice) < pointValue * 2)
                     continue;
                  
                  // リミット価格を更新
                  MqlTradeRequest request;
                  MqlTradeResult result;
                  ZeroMemory(request);
                  ZeroMemory(result);
                  
                  request.action = TRADE_ACTION_SLTP;
                  request.position = ticket;
                  request.symbol = Symbol();
                  request.sl = currentSL;
                  request.tp = tpPrice;
                  request.type_filling = (ENUM_ORDER_TYPE_FILLING)OrderFillingType;
                  
                  if(OrderSend(request, result))
                  {
                     // リミット決済設定完了
                  }
                  else
                  {
                     Print("リミット決済の設定に失敗: ", ticket, 
                           ", エラー=", result.retcode, 
                           ", 最小ストップレベル=", minStopLevel);
                  }
               }
            }
         }
#else // MQL4
         // 各ポジションにリミット注文を設定
         for(int i = OrdersTotal() - 1; i >= 0; i--)
         {
            if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
            {
               if(OrderType() == operationType && OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumber)
               {
                  // 現在のストップロス価格を取得
                  double currentSL = OrderStopLoss();
                  
                  // 現在のテイクプロフィット価格を取得
                  double currentTP = OrderTakeProfit();
                  
                  // 新しいTPとの差が小さい場合はスキップ
                  if(MathAbs(currentTP - tpPrice) < pointValue * 2)
                     continue;
                  
                  // リミット価格を更新（ストップロスはそのまま）
                  bool result = OrderModify(
                     OrderTicket(),        // チケット番号
                     OrderOpenPrice(),     // オープン価格
                     currentSL,            // 現在のストップロス
                     tpPrice,              // 新しいテイクプロフィット
                     0,                    // 有効期限
                     (side == 0) ? clrBlue : clrRed
                  );
                  
                  if(result)
                  {
                     // リミット決済設定完了
                  }
                  else
                  {
                     Print("リミット決済の設定に失敗: ", OrderTicket(), 
                           ", エラー=", GetLastError(), 
                           ", 最小ストップレベル=", minStopLevel);
                  }
               }
            }
         }
#endif
      }
   }
   // ======== 成行決済処理（MARKET） ========
   else if(TakeProfitMode == TP_MARKET)
   {
      // 利確条件の判定
      bool tpCondition = false;

      if(side == 0) // Buy
      {
         // Buy側の利確条件: 現在価格が平均価格+TPポイント以上
         tpCondition = (currentPrice >= tpPrice);
      }
      else // Sell
      {
         // Sell側の利確条件: 現在価格が平均価格-TPポイント以下
         tpCondition = (currentPrice <= tpPrice);
      }

      // 利確条件が満たされた場合
      if(tpCondition)
      {
         // 利確条件成立
         
         // ゴーストポジションの処理
         double ghostProfit = 0;
         if(ghostCount > 0)
         {
            // ゴーストポジション決済処理
            
            // 決済前に利益を計算
            ghostProfit = CalculateGhostProfit(operationType);
            
            // ゴーストポジションをリセット（リアルポジションの有無に関わらず）
            if(operationType == OP_BUY) {
               // ゴーストポジションの状態をリセット
               int buyMaxIndex = MathMin(g_GhostBuyCount, 40);
               for(int i = 0; i < buyMaxIndex; i++) {
                  g_GhostBuyPositions[i].isGhost = false;  // ゴーストフラグをオフに
               }
               // 決済済みフラグを設定
               g_BuyGhostClosed = true;
               g_GhostBuyCount = 0;
            } else {
               // ゴーストポジションの状態をリセット
               int sellMaxIndex = MathMin(g_GhostSellCount, 40);
               for(int i = 0; i < sellMaxIndex; i++) {
                  g_GhostSellPositions[i].isGhost = false;  // ゴーストフラグをオフに
               }
               // 決済済みフラグを設定
               g_SellGhostClosed = true;
               g_GhostSellCount = 0;
            }
            
            // 点線オブジェクトを削除
            DeleteGhostLinesAndPreventRecreation(operationType);
            
            // グローバル変数を更新
            SaveGhostPositionsToGlobal();
            
            
            // 平均価格ラインとTPラインを削除
            CleanupLinesOnClose(side);
            
            // テーブルを更新
            UpdatePositionTable();
            
            // ゴースト決済通知を送信
            NotifyGhostClosure(operationType, ghostProfit);
         }
         
         // リアルポジションの決済
         if(positionCount > 0) {
            bool closeResult = position_close(operationType);
            if(!closeResult) Print("エラー: リアル", direction, "ポジション決済に失敗");
         }
      }
   }

   // TP価格ラインの表示 (利確が有効な場合のみ)
   if(TakeProfitMode != TP_OFF)
   {
      string lineName = "TPLine" + ((side == 0) ? "Buy" : "Sell");
#ifdef __MQL5__
      if(ObjectFind(0, g_ObjectPrefix + lineName) >= 0)
         ObjectDelete(0, g_ObjectPrefix + lineName);
#else
      if(ObjectFind(g_ObjectPrefix + lineName) >= 0)
         ObjectDelete(g_ObjectPrefix + lineName);
#endif

      CreateHorizontalLine(g_ObjectPrefix + lineName, tpPrice, TakeProfitLineColor, STYLE_DASH, 1);

      // ラベルも表示
      string labelName = "TPLabel" + ((side == 0) ? "Buy" : "Sell");
#ifdef __MQL5__
      if(ObjectFind(0, g_ObjectPrefix + labelName) >= 0)
         ObjectDelete(0, g_ObjectPrefix + labelName);
#else
      if(ObjectFind(g_ObjectPrefix + labelName) >= 0)
         ObjectDelete(g_ObjectPrefix + labelName);
#endif

      string labelText = (TakeProfitMode == TP_LIMIT ? "Limit" : "Market") + " TP: " +
                        DoubleToString(tpPrice, GetDigitsValue()) + " (" +
                        (side == 0 ? "+" : "-") + IntegerToString(tpPoints) + "pt)";
      CreatePriceLabel(g_ObjectPrefix + labelName, labelText, tpPrice, TakeProfitLineColor, side == 0);
   }
}





//+------------------------------------------------------------------+
//| ポジション数に応じた建値決済の実行チェック                         |
//+------------------------------------------------------------------+
void CheckBreakEvenByPositions()
{
   // 機能が無効な場合はスキップ
   if(!EnableBreakEvenByPositions)
      return;
      
   // 最低ポジション数が0以下なら機能を無効とみなす
   if(BreakEvenMinPositions <= 0)
      return;
      
   // Buy側のチェック
   int buyPositions = position_count(OP_BUY);
   
   // 指定したポジション数以上あるか確認
   if(buyPositions >= BreakEvenMinPositions)
   {
      // 現在の総損益を計算
      double totalBuyProfit = 0;
      
#ifdef __MQL5__
      // MQL5用の処理
      for(int i = PositionsTotal() - 1; i >= 0; i--)
      {
         ulong ticket = PositionGetTicket(i);
         if(ticket > 0)
         {
            if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY && 
               PositionGetString(POSITION_SYMBOL) == Symbol() && 
               PositionGetInteger(POSITION_MAGIC) == MagicNumber)
            {
               // 損益 + スワップを合計（手数料は直接計算）
               totalBuyProfit += PositionGetDouble(POSITION_PROFIT) + 
                               PositionGetDouble(POSITION_SWAP);
               
               // 手数料を別途計算（オープン時とクローズ時の両方を考慮）
               double commission = 0;
               if(HistorySelectByPosition(PositionGetInteger(POSITION_IDENTIFIER)))
               {
                  int dealsTotal = HistoryDealsTotal();
                  for(int j = 0; j < dealsTotal; j++)
                  {
                     ulong dealTicket = HistoryDealGetTicket(j);
                     if(dealTicket > 0)
                     {
                        commission += HistoryDealGetDouble(dealTicket, DEAL_COMMISSION);
                     }
                  }
               }
               totalBuyProfit += commission;
            }
         }
      }
#else // MQL4
      // すべてのBuyポジションの損益を合計
      for(int i = OrdersTotal() - 1; i >= 0; i--)
      {
         if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
         {
            if(OrderType() == OP_BUY && OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumber)
            {
               // 損益 + スワップ + 手数料を合計
               totalBuyProfit += OrderProfit() + OrderSwap() + OrderCommission();
            }
         }
      }
#endif
      
      // 設定した建値以上なら決済
      if(totalBuyProfit >= BreakEvenProfit)
      {
         // Buy側建値決済実行
               
         // Buy側のポジションをすべて決済
         position_close(OP_BUY);
         
         // 関連するゴーストもリセット
         ResetSpecificGhost(OP_BUY);
         
         // 関連するラインを削除
         CleanupLinesOnClose(0);
      }
   }
   
   // Sell側のチェック
   int sellPositions = position_count(OP_SELL);
   
   // 指定したポジション数以上あるか確認
   if(sellPositions >= BreakEvenMinPositions)
   {
      // 現在の総損益を計算
      double totalSellProfit = 0;
      
#ifdef __MQL5__
      // MQL5用の処理
      for(int i = PositionsTotal() - 1; i >= 0; i--)
      {
         ulong ticket = PositionGetTicket(i);
         if(ticket > 0)
         {
            if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL && 
               PositionGetString(POSITION_SYMBOL) == Symbol() && 
               PositionGetInteger(POSITION_MAGIC) == MagicNumber)
            {
               // 損益 + スワップを合計（手数料は直接計算）
               totalSellProfit += PositionGetDouble(POSITION_PROFIT) + 
                                PositionGetDouble(POSITION_SWAP);
               
               // 手数料を別途計算（オープン時とクローズ時の両方を考慮）
               double commission = 0;
               if(HistorySelectByPosition(PositionGetInteger(POSITION_IDENTIFIER)))
               {
                  int dealsTotal = HistoryDealsTotal();
                  for(int j = 0; j < dealsTotal; j++)
                  {
                     ulong dealTicket = HistoryDealGetTicket(j);
                     if(dealTicket > 0)
                     {
                        commission += HistoryDealGetDouble(dealTicket, DEAL_COMMISSION);
                     }
                  }
               }
               totalSellProfit += commission;
            }
         }
      }
#else // MQL4
      // すべてのSellポジションの損益を合計
      for(int i = OrdersTotal() - 1; i >= 0; i--)
      {
         if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
         {
            if(OrderType() == OP_SELL && OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumber)
            {
               // 損益 + スワップ + 手数料を合計
               totalSellProfit += OrderProfit() + OrderSwap() + OrderCommission();
            }
         }
      }
#endif
      
      // 設定した建値以上なら決済
      if(totalSellProfit >= BreakEvenProfit)
      {
         // Sell側建値決済実行
               
         // Sell側のポジションをすべて決済
         position_close(OP_SELL);
         
         // 関連するゴーストもリセット
         ResetSpecificGhost(OP_SELL);
         
         // 関連するラインを削除
         CleanupLinesOnClose(1);
      }
   }
}

//+------------------------------------------------------------------+
//| 損失額による決済チェック関数                                      |
//+------------------------------------------------------------------+
void CheckMaxLossClose()
{
   // 機能が無効な場合はスキップ
   if(!EnableMaxLossClose)
      return;
      
   // 最大損失額が0以下なら機能を無効とみなす
   if(MaxLossAmount <= 0)
      return;
      
   // Buy側ポジションの損失チェック
   int buyPositions = position_count(OP_BUY);
   if(buyPositions > 0)
   {
      // 現在の総損益を計算
      double totalBuyProfit = 0;
      
#ifdef __MQL5__
      // MQL5用の処理
      for(int i = PositionsTotal() - 1; i >= 0; i--)
      {
         ulong ticket = PositionGetTicket(i);
         if(ticket > 0)
         {
            if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY && 
               PositionGetString(POSITION_SYMBOL) == Symbol() && 
               PositionGetInteger(POSITION_MAGIC) == MagicNumber)
            {
               // 損益 + スワップを合計
               totalBuyProfit += PositionGetDouble(POSITION_PROFIT) + 
                               PositionGetDouble(POSITION_SWAP);
               
               // 手数料を別途計算
               double commission = 0;
               if(HistorySelectByPosition(PositionGetInteger(POSITION_IDENTIFIER)))
               {
                  int dealsTotal = HistoryDealsTotal();
                  for(int j = 0; j < dealsTotal; j++)
                  {
                     ulong dealTicket = HistoryDealGetTicket(j);
                     if(dealTicket > 0)
                     {
                        commission += HistoryDealGetDouble(dealTicket, DEAL_COMMISSION);
                     }
                  }
               }
               totalBuyProfit += commission;
            }
         }
      }
#else // MQL4
      // すべてのBuyポジションの損益を合計
      for(int i = OrdersTotal() - 1; i >= 0; i--)
      {
         if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
         {
            if(OrderType() == OP_BUY && OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumber)
            {
               // 損益 + スワップ + 手数料を合計
               totalBuyProfit += OrderProfit() + OrderSwap() + OrderCommission();
            }
         }
      }
#endif
      
      // 損失が最大損失額を超えたら決済
      if(totalBuyProfit <= -MaxLossAmount)
      {
         Print("警告: Buy側最大損失額に到達 - 緊急決済実行");
               
         // Buy側のポジションをすべて決済
         position_close(OP_BUY, 0.0, 10, MagicNumber);
         
         // ゴーストポジションもリセット
         ResetSpecificGhost(OP_BUY);
         
         // 関連するラインを削除
         CleanupLinesOnClose(0);
      }
   }
   
   // Sell側ポジションの損失チェック
   int sellPositions = position_count(OP_SELL);
   if(sellPositions > 0)
   {
      // 現在の総損益を計算
      double totalSellProfit = 0;
      
#ifdef __MQL5__
      // MQL5用の処理
      for(int i = PositionsTotal() - 1; i >= 0; i--)
      {
         ulong ticket = PositionGetTicket(i);
         if(ticket > 0)
         {
            if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL && 
               PositionGetString(POSITION_SYMBOL) == Symbol() && 
               PositionGetInteger(POSITION_MAGIC) == MagicNumber)
            {
               // 損益 + スワップを合計
               totalSellProfit += PositionGetDouble(POSITION_PROFIT) + 
                               PositionGetDouble(POSITION_SWAP);
               
               // 手数料を別途計算
               double commission = 0;
               if(HistorySelectByPosition(PositionGetInteger(POSITION_IDENTIFIER)))
               {
                  int dealsTotal = HistoryDealsTotal();
                  for(int j = 0; j < dealsTotal; j++)
                  {
                     ulong dealTicket = HistoryDealGetTicket(j);
                     if(dealTicket > 0)
                     {
                        commission += HistoryDealGetDouble(dealTicket, DEAL_COMMISSION);
                     }
                  }
               }
               totalSellProfit += commission;
            }
         }
      }
#else // MQL4
      // すべてのSellポジションの損益を合計
      for(int i = OrdersTotal() - 1; i >= 0; i--)
      {
         if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
         {
            if(OrderType() == OP_SELL && OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumber)
            {
               // 損益 + スワップ + 手数料を合計
               totalSellProfit += OrderProfit() + OrderSwap() + OrderCommission();
            }
         }
      }
#endif
      
      // 損失が最大損失額を超えたら決済
      if(totalSellProfit <= -MaxLossAmount)
      {
         Print("警告: Sell側最大損失額に到達 - 緊急決済実行");
               
         // Sell側のポジションをすべて決済
         position_close(OP_SELL, 0.0, 10, MagicNumber);
         
         // ゴーストポジションもリセット
         ResetSpecificGhost(OP_SELL);
         
         // 関連するラインを削除
         CleanupLinesOnClose(1);
      }
   }
}

//+------------------------------------------------------------------+
//| Point値を取得する関数                                             |
//+------------------------------------------------------------------+
double GetPointValue()
{
#ifdef __MQL5__
   return SymbolInfoDouble(Symbol(), SYMBOL_POINT);
#else
   return Point;
#endif
}

//+------------------------------------------------------------------+
//| Digits値を取得する関数                                            |
//+------------------------------------------------------------------+
int GetDigitsValue()
{
#ifdef __MQL5__
   return (int)SymbolInfoInteger(Symbol(), SYMBOL_DIGITS);
#else
   return Digits;
#endif
}

//+------------------------------------------------------------------+
//| 最小ストップレベルを取得する関数                                  |
//+------------------------------------------------------------------+
int GetMinStopLevel()
{
#ifdef __MQL5__
   return (int)SymbolInfoInteger(Symbol(), SYMBOL_TRADE_STOPS_LEVEL);
#else
   return (int)MarketInfo(Symbol(), MODE_STOPLEVEL);
#endif
}