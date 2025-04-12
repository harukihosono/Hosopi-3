//+------------------------------------------------------------------+
//|                Hosopi 3 - 決済機能専用ファイル                    |
//|                        Copyright 2025                            |
//+------------------------------------------------------------------+
#include "Hosopi3_Defines.mqh"
#include "Hosopi3_Trading.mqh"
#include "Hosopi3_Utils.mqh"
#include "Hosopi3_Ghost.mqh"

// ポジション数に応じた利確幅を取得する関数
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
      default: return TP_Level20; // 20ポジション以上は最後のレベルを使用
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
                        Print("Buy トレールストップ更新: チケット=", OrderTicket(), 
                             ", 平均価格=", DoubleToString(avgPrice, Digits),
                             ", 現在価格=", DoubleToString(currentPrice, Digits),
                             ", 新ストップ=", DoubleToString(stopPrice, Digits));
                     }
                     else
                     {
                        Print("Buy トレールストップ更新エラー: ", GetLastError());
                     }
                  }
               }
            }
         }
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
                        Print("Sell トレールストップ更新: チケット=", OrderTicket(), 
                             ", 平均価格=", DoubleToString(avgPrice, Digits),
                             ", 現在価格=", DoubleToString(currentPrice, Digits),
                             ", 新ストップ=", DoubleToString(stopPrice, Digits));
                     }
                     else
                     {
                        Print("Sell トレールストップ更新エラー: ", GetLastError());
                     }
                  }
               }
            }
         }
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
   
   if(side == 0) // Buy
   {
      // トレールトリガー: 平均価格 + トリガーポイント
      triggerPrice = avgPrice + TrailingTrigger * Point;
      
      // 現在価格がトリガー以上の場合のみトレーリング
      if(currentPrice >= triggerPrice)
      {
         // ストップ価格: 現在価格 - オフセット
         stopPrice = currentPrice - TrailingOffset * Point;
         
         // 各ゴーストポジションのストップロスを更新
         for(int i = 0; i < g_GhostBuyCount; i++)
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
                  Print("ゴーストBuy トレールストップ更新: レベル=", g_GhostBuyPositions[i].level + 1, 
                       ", 平均価格=", DoubleToString(avgPrice, Digits),
                       ", 現在価格=", DoubleToString(currentPrice, Digits),
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
      // トレールトリガー: 平均価格 - トリガーポイント
      triggerPrice = avgPrice - TrailingTrigger * Point;
      
      // 現在価格がトリガー以下の場合のみトレーリング
      if(currentPrice <= triggerPrice)
      {
         // ストップ価格: 現在価格 + オフセット
         stopPrice = currentPrice + TrailingOffset * Point;
         
         // 各ゴーストポジションのストップロスを更新
         for(int i = 0; i < g_GhostSellCount; i++)
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
                  Print("ゴーストSell トレールストップ更新: レベル=", g_GhostSellPositions[i].level + 1, 
                       ", 平均価格=", DoubleToString(avgPrice, Digits),
                       ", 現在価格=", DoubleToString(currentPrice, Digits),
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
//| 利確処理の統合関数 - 決済方法に応じて処理                         |
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

   // TP価格の計算（ロット加重平均の価格から指定ポイント離れた価格）
   double tpPrice = (side == 0) ? 
                  avgPrice + tpPoints * Point : 
                  avgPrice - tpPoints * Point;

   // ======== 指値決済処理（LIMIT） ========
   if(TakeProfitMode == TP_LIMIT)
   {
      // シンボルの最小ストップレベルを取得
      int minStopLevel = (int)MarketInfo(Symbol(), MODE_STOPLEVEL);
      
      // 最小ストップレベルを考慮してTP価格を調整
      double minAllowedTPDistance = minStopLevel * Point;
      
      // Buy注文の場合、TPは現在Bid価格より十分高くなければならない
      if(side == 0 && tpPrice - currentPrice < minAllowedTPDistance)
      {
         tpPrice = currentPrice + minAllowedTPDistance;
         Print("警告: リミットTP価格が最小ストップレベルに近すぎるため調整しました: ",
               DoubleToString(tpPrice, Digits));
      }
      // Sell注文の場合、TPは現在Ask価格より十分低くなければならない
      else if(side == 1 && currentPrice - tpPrice < minAllowedTPDistance)
      {
         tpPrice = currentPrice - minAllowedTPDistance;
         Print("警告: リミットTP価格が最小ストップレベルに近すぎるため調整しました: ",
               DoubleToString(tpPrice, Digits));
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
            Print(direction, "ゴーストのみで利確条件成立: 平均価格=", DoubleToString(avgPrice, Digits),
                  ", TP価格=", DoubleToString(tpPrice, Digits),
                  ", 現在価格=", DoubleToString(currentPrice, Digits));
            
            // ゴーストポジションをリセット
            if(operationType == OP_BUY) {
               // ゴーストポジションの状態をリセット
               for(int i = 0; i < g_GhostBuyCount; i++) {
                  g_GhostBuyPositions[i].isGhost = false;  // ゴーストフラグをオフに
               }
               // 決済済みフラグを設定
               g_BuyGhostClosed = true;
               g_GhostBuyCount = 0;
            } else {
               // ゴーストポジションの状態をリセット
               for(int i = 0; i < g_GhostSellCount; i++) {
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
            
            Print(direction, "ゴーストポジション利確: リセットしました");
            
            // 平均価格ラインとTPラインを削除
            CleanupLinesOnClose(side);
            
            // テーブルを更新
            UpdatePositionTable();
         }
      }
      
      // リアルポジションがある場合は通常の指値設定
      if(positionCount > 0)
      {
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
                  if(MathAbs(currentTP - tpPrice) < Point * 2)
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
                     Print("リミット決済を設定しました: ", OrderTicket(), 
                           ", 方向=", direction, 
                           ", TP=", DoubleToString(tpPrice, Digits));
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
         Print(direction, "利確条件成立: 平均価格=", DoubleToString(avgPrice, Digits),
               ", TP価格=", DoubleToString(tpPrice, Digits),
               ", 現在価格=", DoubleToString(currentPrice, Digits));
         
         // リアルポジションの決済
         if(positionCount > 0) {
            bool closeResult = position_close(operationType);
            Print("リアル", direction, "ポジションを決済しました: 結果=", closeResult ? "成功" : "失敗");
         }
         
         // ゴーストポジションの処理 - ゴーストがある場合は必ず処理する
         if(ghostCount > 0)
         {
            Print("ゴースト", direction, "ポジション(", ghostCount, "個)が存在します");
            
            // ゴーストポジションをリセット（リアルポジションの有無に関わらず）
            if(operationType == OP_BUY) {
               // ゴーストポジションの状態をリセット
               for(int i = 0; i < g_GhostBuyCount; i++) {
                  g_GhostBuyPositions[i].isGhost = false;  // ゴーストフラグをオフに
               }
               // 決済済みフラグを設定
               g_BuyGhostClosed = true;
               g_GhostBuyCount = 0;
            } else {
               // ゴーストポジションの状態をリセット
               for(int i = 0; i < g_GhostSellCount; i++) {
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
            
            Print(direction, "ゴーストポジション利確: リセットしました");
            
            // 平均価格ラインとTPラインを削除
            CleanupLinesOnClose(side);
            
            // テーブルを更新
            UpdatePositionTable();
         }
      }
   }

   // TP価格ラインの表示 (どの利確モードでも表示)
   string lineName = "TPLine" + ((side == 0) ? "Buy" : "Sell");
   if(ObjectFind(g_ObjectPrefix + lineName) >= 0)
      ObjectDelete(g_ObjectPrefix + lineName);
      
   CreateHorizontalLine(g_ObjectPrefix + lineName, tpPrice, TakeProfitLineColor, STYLE_DASH, 1);
   
   // ラベルも表示
   string labelName = "TPLabel" + ((side == 0) ? "Buy" : "Sell");
   if(ObjectFind(g_ObjectPrefix + labelName) >= 0)
      ObjectDelete(g_ObjectPrefix + labelName);
      
   string labelText = (TakeProfitMode == TP_LIMIT ? "Limit" : "Market") + " TP: " + 
                     DoubleToString(tpPrice, Digits) + " (" + 
                     (side == 0 ? "+" : "-") + IntegerToString(tpPoints) + "pt)";
   CreatePriceLabel(g_ObjectPrefix + labelName, labelText, tpPrice, TakeProfitLineColor, side == 0);
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
      
      // 設定した建値以上なら決済
      if(totalBuyProfit >= BreakEvenProfit)
      {
         Print("Buy側建値決済条件成立: ポジション数=", buyPositions, 
               ", 総利益=", DoubleToString(totalBuyProfit, 2),
               ", 設定建値=", DoubleToString(BreakEvenProfit, 2));
               
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
      
      // 設定した建値以上なら決済
      if(totalSellProfit >= BreakEvenProfit)
      {
         Print("Sell側建値決済条件成立: ポジション数=", sellPositions, 
               ", 総利益=", DoubleToString(totalSellProfit, 2),
               ", 設定建値=", DoubleToString(BreakEvenProfit, 2));
               
         // Sell側のポジションをすべて決済
         position_close(OP_SELL);
         
         // 関連するゴーストもリセット
         ResetSpecificGhost(OP_SELL);
         
         // 関連するラインを削除
         CleanupLinesOnClose(1);
      }
   }
}