//+------------------------------------------------------------------+
//|                Hosopi 3 - 決済機能専用ファイル (MQL4/MQL5共通)     |
//|                        Copyright 2025                            |
//+------------------------------------------------------------------+
#include "Hosopi3_Defines.mqh"
#include "Hosopi3_Trading.mqh"
#include "Hosopi3_Utils.mqh"
#include "Hosopi3_Ghost.mqh"

//+------------------------------------------------------------------+
//| ポジション数に応じた利確幅を取得                                  |
//+------------------------------------------------------------------+
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
//| トレールストップ条件のチェック (MQL4/MQL5共通)                    |
//+------------------------------------------------------------------+
void CheckTrailingStopConditions(int side)
{
   // トレールストップが無効な場合はスキップ
   if(!EnableTrailingStop)
      return;

   // 処理対象のオペレーションタイプを決定
   int operationType = (side == 0) ? OP_BUY : OP_SELL;

   // リアルポジションがない場合はスキップ
   int positionCount = position_count(operationType);
   if(positionCount <= 0)
      return;

   // 平均価格を計算
   double avgPrice = CalculateCombinedAveragePrice(operationType);
   if(avgPrice <= 0)
      return;

   // 現在価格を取得（BuyならBid、SellならAsk）
   double currentPrice = (side == 0) ? GetBidPrice() : GetAskPrice();

   // トレールトリガー価格とオフセット価格を計算
   double triggerPrice, stopPrice;
   
   if(side == 0) // Buy
   {
      // トレールトリガー: 平均価格 + トリガーポイント
      triggerPrice = avgPrice + TrailingTrigger * Point;
      
      // 現在価格がトリガー以上の場合のみトレーリング
      if(currentPrice >= triggerPrice)
      {
         // ストップ価格: 現在価格 - オフセット
         stopPrice = currentPrice - TrailingOffset * Point;
         
         // 各ポジションの決済条件をチェック
         UpdateTrailingStopForPositions(operationType, stopPrice, side);
      }
   }
   else // Sell
   {
      // トレールトリガー: 平均価格 - トリガーポイント
      triggerPrice = avgPrice - TrailingTrigger * Point;
      
      // 現在価格がトリガー以下の場合のみトレーリング
      if(currentPrice <= triggerPrice)
      {
         // ストップ価格: 現在価格 + オフセット
         stopPrice = currentPrice + TrailingOffset * Point;
         
         // 各ポジションの決済条件をチェック
         UpdateTrailingStopForPositions(operationType, stopPrice, side);
      }
   }
}

//+------------------------------------------------------------------+
//| トレーリングストップを更新 (MQL4/MQL5共通)                       |
//+------------------------------------------------------------------+
void UpdateTrailingStopForPositions(int operationType, double stopPrice, int side)
{
#ifdef __MQL5__
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(PositionSelectByTicket(ticket))
      {
         if(PositionGetString(POSITION_SYMBOL) == Symbol() &&
            PositionGetInteger(POSITION_MAGIC) == MagicNumber &&
            PositionGetInteger(POSITION_TYPE) == operationType)
         {
            double currentSL = PositionGetDouble(POSITION_SL);
            
            bool updateNeeded = false;
            if(side == 0) // Buy
               updateNeeded = (currentSL == 0 || stopPrice > currentSL);
            else // Sell
               updateNeeded = (currentSL == 0 || stopPrice < currentSL);
            
            if(updateNeeded)
            {
               MqlTradeRequest request = {};
               MqlTradeResult result = {};
               
               request.action = TRADE_ACTION_SLTP;
               request.position = ticket;
               request.sl = stopPrice;
               request.tp = PositionGetDouble(POSITION_TP);
               
               if(OrderSend(request, result))
               {
                  Print((side == 0 ? "Buy" : "Sell"), " トレールストップ更新成功: 新SL=", stopPrice);
               }
               else
               {
                  Print((side == 0 ? "Buy" : "Sell"), " トレールストップ更新エラー: ", GetLastError());
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
            double currentSL = OrderStopLoss();
            
            bool updateNeeded = false;
            if(side == 0) // Buy
               updateNeeded = (currentSL == 0 || stopPrice > currentSL);
            else // Sell
               updateNeeded = (currentSL == 0 || stopPrice < currentSL);
            
            if(updateNeeded)
            {
               bool result = OrderModify(OrderTicket(), OrderOpenPrice(), stopPrice, OrderTakeProfit(), 0, 
                                       (side == 0) ? clrGreen : clrRed);
               if(result)
               {
                  Print((side == 0 ? "Buy" : "Sell"), " トレールストップ更新成功: 新SL=", stopPrice);
               }
               else
               {
                  Print((side == 0 ? "Buy" : "Sell"), " トレールストップ更新エラー: ", GetLastError());
               }
            }
         }
      }
   }
#endif
}

//+------------------------------------------------------------------+
//| ゴーストポジションのトレーリングストップ更新                      |
//+------------------------------------------------------------------+
void CheckGhostTrailingStopConditions(int side)
{
   // トレールストップが無効な場合はスキップ
   if(!EnableTrailingStop)
      return;

   // 処理対象のオペレーションタイプを決定
   int operationType = (side == 0) ? OP_BUY : OP_SELL;

   // ゴーストポジションがない場合はスキップ
   int ghostCount = ghost_position_count(operationType);
   if(ghostCount <= 0)
      return;

   // 平均価格を計算
   double avgPrice = CalculateGhostAveragePrice(operationType);
   if(avgPrice <= 0)
      return;

   // 現在価格を取得（BuyならBid、SellならAsk）
   double currentPrice = (side == 0) ? GetBidPrice() : GetAskPrice();

   // トレールトリガー価格とオフセット価格を計算
   double triggerPrice, stopPrice;
   
   if(side == 0) // Buy
   {
      triggerPrice = avgPrice + TrailingTrigger * Point;
      
      if(currentPrice >= triggerPrice)
      {
         stopPrice = currentPrice - TrailingOffset * Point;
         
         // 各ゴーストポジションのストップロスを更新
         for(int i = 0; i < g_GhostBuyCount; i++)
         {
            if(g_GhostBuyPositions[i].isGhost)
            {
               double currentSL = g_GhostBuyPositions[i].stopLoss;
               
               if(currentSL == 0 || stopPrice > currentSL)
               {
                  g_GhostBuyPositions[i].stopLoss = stopPrice;
                  Print("ゴーストBuy トレールストップ更新: レベル=", g_GhostBuyPositions[i].level + 1, 
                       ", 新ストップ=", DoubleToString(stopPrice, Digits));
               }
            }
         }
         
         // ストップラインを表示
         UpdateGhostStopLine(side, stopPrice);
      }
   }
   else // Sell
   {
      triggerPrice = avgPrice - TrailingTrigger * Point;
      
      if(currentPrice <= triggerPrice)
      {
         stopPrice = currentPrice + TrailingOffset * Point;
         
         // 各ゴーストポジションのストップロスを更新
         for(int i = 0; i < g_GhostSellCount; i++)
         {
            if(g_GhostSellPositions[i].isGhost)
            {
               double currentSL = g_GhostSellPositions[i].stopLoss;
               
               if(currentSL == 0 || stopPrice < currentSL)
               {
                  g_GhostSellPositions[i].stopLoss = stopPrice;
                  Print("ゴーストSell トレールストップ更新: レベル=", g_GhostSellPositions[i].level + 1, 
                       ", 新ストップ=", DoubleToString(stopPrice, Digits));
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
//| 利確処理の統合関数 (MQL4/MQL5共通)                               |
//+------------------------------------------------------------------+
void ManageTakeProfit(int side)
{
   // 利確が無効な場合はスキップ
   if(TakeProfitMode == TP_OFF)
      return;

   // 処理対象のオペレーションタイプを決定
   int operationType = (side == 0) ? OP_BUY : OP_SELL;
   string direction = (side == 0) ? "Buy" : "Sell";

   // ポジションとゴーストカウントの取得
   int positionCount = position_count(operationType);
   int ghostCount = ghost_position_count(operationType);

   // ポジション・ゴーストどちらも無い場合はスキップ
   if(positionCount <= 0 && ghostCount <= 0)
      return;

   // 平均価格を計算
   double avgPrice = CalculateCombinedAveragePrice(operationType);
   if(avgPrice <= 0)
      return;

   // 現在価格を取得（BuyならBid、SellならAsk）
   double currentPrice = (side == 0) ? GetBidPrice() : GetAskPrice();

   // ポジション数に応じた利確幅を取得
   int totalPositions = positionCount + ghostCount;
   int tpPoints = GetTakeProfitPointsByPositionCount(totalPositions);

   // TP価格の計算
   double tpPrice = (side == 0) ? 
                  avgPrice + tpPoints * Point : 
                  avgPrice - tpPoints * Point;

   // 指値決済処理（LIMIT）
   if(TakeProfitMode == TP_LIMIT)
   {
      ProcessLimitTakeProfit(side, operationType, positionCount, ghostCount, avgPrice, tpPrice, currentPrice, direction);
   }
   // 成行決済処理（MARKET）
   else if(TakeProfitMode == TP_MARKET)
   {
      ProcessMarketTakeProfit(side, operationType, positionCount, ghostCount, avgPrice, tpPrice, currentPrice, direction);
   }

   // TP価格ラインの表示
   UpdateTPPriceLine(side, tpPrice, tpPoints);
}

//+------------------------------------------------------------------+
//| 指値決済処理 (MQL4/MQL5共通)                                     |
//+------------------------------------------------------------------+
void ProcessLimitTakeProfit(int side, int operationType, int positionCount, int ghostCount, 
                           double avgPrice, double tpPrice, double currentPrice, string direction)
{
   // 最小ストップレベルを取得
#ifdef __MQL5__
   int minStopLevel = (int)SymbolInfoInteger(Symbol(), SYMBOL_TRADE_STOPS_LEVEL);
#else
   int minStopLevel = (int)MarketInfo(Symbol(), MODE_STOPLEVEL);
#endif
   
   // 最小ストップレベルを考慮してTP価格を調整
   double minAllowedTPDistance = minStopLevel * Point;
   
   if(side == 0 && tpPrice - currentPrice < minAllowedTPDistance)
   {
      tpPrice = currentPrice + minAllowedTPDistance;
      Print("警告: リミットTP価格が最小ストップレベルに近すぎるため調整しました: ", DoubleToString(tpPrice, Digits));
   }
   else if(side == 1 && currentPrice - tpPrice < minAllowedTPDistance)
   {
      tpPrice = currentPrice - minAllowedTPDistance;
      Print("警告: リミットTP価格が最小ストップレベルに近すぎるため調整しました: ", DoubleToString(tpPrice, Digits));
   }
   
   // ゴーストポジションのみの場合の処理
   if(positionCount == 0 && ghostCount > 0)
   {
      bool tpCondition = false;
      if(side == 0) // Buy
         tpCondition = (currentPrice >= tpPrice);
      else // Sell
         tpCondition = (currentPrice <= tpPrice);

      if(tpCondition)
      {
         Print(direction, "ゴーストのみで利確条件成立");
         
         // 決済前に利益を計算
         double ghostProfit = CalculateGhostProfit(operationType);
         
         // ゴーストポジションをリセット
         ResetSpecificGhost(operationType);
         
         // ラインを削除
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
      UpdateLimitOrdersForPositions(operationType, tpPrice, side);
   }
}

//+------------------------------------------------------------------+
//| 成行決済処理 (MQL4/MQL5共通)                                     |
//+------------------------------------------------------------------+
void ProcessMarketTakeProfit(int side, int operationType, int positionCount, int ghostCount,
                            double avgPrice, double tpPrice, double currentPrice, string direction)
{
   // 利確条件の判定
   bool tpCondition = false;
   if(side == 0) // Buy
      tpCondition = (currentPrice >= tpPrice);
   else // Sell
      tpCondition = (currentPrice <= tpPrice);

   // 利確条件が満たされた場合
   if(tpCondition)
   {
      Print(direction, "利確条件成立: TP価格=", DoubleToString(tpPrice, Digits),
            ", 現在価格=", DoubleToString(currentPrice, Digits));
      
      // ゴーストポジションの処理
      double ghostProfit = 0;
      if(ghostCount > 0)
      {
         // 決済前に利益を計算
         ghostProfit = CalculateGhostProfit(operationType);
         
         // ゴーストポジションをリセット
         ResetSpecificGhost(operationType);
         
         // ラインを削除
         CleanupLinesOnClose(side);
         
         // テーブルを更新
         UpdatePositionTable();
         
         // ゴースト決済通知を送信
         NotifyGhostClosure(operationType, ghostProfit);
      }
      
      // リアルポジションの決済
      if(positionCount > 0)
      {
         bool closeResult = position_close(operationType);
         Print("リアル", direction, "ポジションを決済しました: 結果=", closeResult ? "成功" : "失敗");
      }
   }
}

//+------------------------------------------------------------------+
//| リミット注文の更新 (MQL4/MQL5共通)                               |
//+------------------------------------------------------------------+
void UpdateLimitOrdersForPositions(int operationType, double tpPrice, int side)
{
#ifdef __MQL5__
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(PositionSelectByTicket(ticket))
      {
         if(PositionGetString(POSITION_SYMBOL) == Symbol() &&
            PositionGetInteger(POSITION_MAGIC) == MagicNumber &&
            PositionGetInteger(POSITION_TYPE) == operationType)
         {
            double currentTP = PositionGetDouble(POSITION_TP);
            
            if(MathAbs(currentTP - tpPrice) >= Point * 2)
            {
               MqlTradeRequest request = {};
               MqlTradeResult result = {};
               
               request.action = TRADE_ACTION_SLTP;
               request.position = ticket;
               request.sl = PositionGetDouble(POSITION_SL);
               request.tp = tpPrice;
               
               if(OrderSend(request, result))
               {
                  Print("リミット決済を設定しました: TP=", DoubleToString(tpPrice, Digits));
               }
               else
               {
                  Print("リミット決済の設定に失敗: ", GetLastError());
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
            double currentTP = OrderTakeProfit();
            
            if(MathAbs(currentTP - tpPrice) >= Point * 2)
            {
               bool result = OrderModify(OrderTicket(), OrderOpenPrice(), OrderStopLoss(), tpPrice, 0,
                                       (side == 0) ? clrBlue : clrRed);
               
               if(result)
               {
                  Print("リミット決済を設定しました: TP=", DoubleToString(tpPrice, Digits));
               }
               else
               {
                  Print("リミット決済の設定に失敗: ", GetLastError());
               }
            }
         }
      }
   }
#endif
}

//+------------------------------------------------------------------+
//| TP価格ラインの更新 (MQL4/MQL5共通)                               |
//+------------------------------------------------------------------+
void UpdateTPPriceLine(int side, double tpPrice, int tpPoints)
{
   string lineName = g_ObjectPrefix + "TPLine" + ((side == 0) ? "Buy" : "Sell");
   if(ObjectFind(lineName) >= 0)
      ObjectDelete(lineName);
      
   CreateHorizontalLine(lineName, tpPrice, TakeProfitLineColor, STYLE_DASH, 1);
   
   // ラベルも表示
   string labelName = g_ObjectPrefix + "TPLabel" + ((side == 0) ? "Buy" : "Sell");
   if(ObjectFind(labelName) >= 0)
      ObjectDelete(labelName);
      
   string labelText = (TakeProfitMode == TP_LIMIT ? "Limit" : "Market") + " TP: " + 
                     DoubleToString(tpPrice, Digits) + " (" + 
                     (side == 0 ? "+" : "-") + IntegerToString(tpPoints) + "pt)";
   CreatePriceLabel(labelName, labelText, tpPrice, TakeProfitLineColor, side == 0);
}

//+------------------------------------------------------------------+
//| ポジション数に応じた建値決済の実行チェック (MQL4/MQL5共通)       |
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
   CheckBreakEvenBySide(0);
   
   // Sell側のチェック
   CheckBreakEvenBySide(1);
}

//+------------------------------------------------------------------+
//| 片側の建値決済チェック (MQL4/MQL5共通)                           |
//+------------------------------------------------------------------+
void CheckBreakEvenBySide(int side)
{
   int operationType = (side == 0) ? OP_BUY : OP_SELL;
   int positions = position_count(operationType);
   
   // 指定したポジション数以上あるか確認
   if(positions >= BreakEvenMinPositions)
   {
      // 現在の総損益を計算
      double totalProfit = CalculateTotalProfit(operationType);
      
      // 設定した建値以上なら決済
      if(totalProfit >= BreakEvenProfit)
      {
         Print((side == 0 ? "Buy" : "Sell"), "側建値決済条件成立: ポジション数=", positions, 
               ", 総利益=", DoubleToString(totalProfit, 2),
               ", 設定建値=", DoubleToString(BreakEvenProfit, 2));
               
         // ポジションをすべて決済
         position_close(operationType);
         
         // 関連するゴーストもリセット
         ResetSpecificGhost(operationType);
         
         // 関連するラインを削除
         CleanupLinesOnClose(side);
      }
   }
}

//+------------------------------------------------------------------+
//| 総損益を計算 (MQL4/MQL5共通)                                     |
//+------------------------------------------------------------------+
double CalculateTotalProfit(int operationType)
{
   double totalProfit = 0;
   
#ifdef __MQL5__
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(PositionSelectByTicket(PositionGetTicket(i)))
      {
         if(PositionGetString(POSITION_SYMBOL) == Symbol() &&
            PositionGetInteger(POSITION_MAGIC) == MagicNumber &&
            PositionGetInteger(POSITION_TYPE) == operationType)
         {
            totalProfit += PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
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
            totalProfit += OrderProfit() + OrderSwap() + OrderCommission();
         }
      }
   }
#endif
   
   return totalProfit;
}