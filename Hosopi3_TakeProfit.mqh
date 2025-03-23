//+------------------------------------------------------------------+
//|                Hosopi 3 - 決済機能専用ファイル                    |
//|                        Copyright 2025                            |
//+------------------------------------------------------------------+
#include "Hosopi3_Defines.mqh"
#include "Hosopi3_Trading.mqh"
#include "Hosopi3_Utils.mqh"
#include "Hosopi3_Ghost.mqh"

//+------------------------------------------------------------------+
//| 平均取得単価からの固定利確条件のチェック                          |
//+------------------------------------------------------------------+
void CheckTakeProfitConditions(int side)
{
   // EnableFixedTPとEnableTakeProfitPointsがどちらもオフの場合はスキップ
   if(!EnableTakeProfitPoints)
   {
      return;
   }

   // 処理対象のオペレーションタイプを決定
   int operationType = (side == 0) ? OP_BUY : OP_SELL;
   int oppositeType = (side == 0) ? OP_SELL : OP_BUY;

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

   // TP価格の計算（ロット加重平均の価格から指定ポイント離れた価格）
   double tpPrice = (side == 0) ? 
                  avgPrice + TakeProfitPoints * Point : 
                  avgPrice - TakeProfitPoints * Point;

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
      string direction = (side == 0) ? "Buy" : "Sell";
      Print(direction, "利確条件成立: 平均価格=", DoubleToString(avgPrice, Digits),
            ", TP価格=", DoubleToString(tpPrice, Digits),
            ", 現在価格=", DoubleToString(currentPrice, Digits));
      
      // リアルポジションの決済
      if(positionCount > 0) {
         position_close(operationType);
         Print("リアル", direction, "ポジションを決済しました");
      }
      
      // 反対側のポジションとゴーストをチェック
      int oppositePositionCount = position_count(oppositeType);
      int oppositeGhostCount = ghost_position_count(oppositeType);
      
      // ゴーストポジションは決済時にのみリセット（反対側に何もなければ両方リセット）
      if(ghostCount > 0)
      {
         // 反対側にリアルポジションやゴーストがある場合は現在の方向のみリセット
         if(oppositePositionCount > 0 || oppositeGhostCount > 0) {
            Print("反対側に", oppositePositionCount, "個のリアルポジションと", 
                  oppositeGhostCount, "個のゴーストがあるため、", direction, "側のみリセットします");
            
            // 点線を削除し再生成を防止
            DeleteGhostLinesAndPreventRecreation(operationType);
            
            // ゴーストポジションの状態はリセット - ただし特殊フラグを立てる
            if(operationType == OP_BUY) {
               // ゴーストポジションの状態をリセット
               for(int i = 0; i < g_GhostBuyCount; i++) {
                  g_GhostBuyPositions[i].isGhost = false;  // ゴーストフラグをオフに
                  // 他の値は保持（矢印を残すため）
               }
               // 決済済みフラグを設定
               g_BuyGhostClosed = true;
               g_GhostBuyCount = 0;
            } else {
               // ゴーストポジションの状態をリセット
               for(int i = 0; i < g_GhostSellCount; i++) {
                  g_GhostSellPositions[i].isGhost = false;  // ゴーストフラグをオフに
                  // 他の値は保持（矢印を残すため）
               }
               // 決済済みフラグを設定
               g_SellGhostClosed = true;
               g_GhostSellCount = 0;
            }
            
            // グローバル変数を更新
            SaveGhostPositionsToGlobal();
         } else {
            // 反対側に何もなければ両方のゴーストをリセット
            Print("反対側に何もないため、すべてのゴーストポジションをリセットします");
            // 点線を削除し再生成を防止
            DeleteGhostLinesAndPreventRecreation(OP_BUY);
            DeleteGhostLinesAndPreventRecreation(OP_SELL);
            
            // Buy側ゴーストポジションの状態をリセット
            for(int i = 0; i < g_GhostBuyCount; i++) {
               g_GhostBuyPositions[i].isGhost = false;  // ゴーストフラグをオフに
               // 他の値は保持（矢印を残すため）
            }
            g_BuyGhostClosed = false; // ここをfalseに変更
            g_GhostBuyCount = 0;
            
            // Sell側ゴーストポジションの状態をリセット
            for(int i = 0; i < g_GhostSellCount; i++) {
               g_GhostSellPositions[i].isGhost = false;  // ゴーストフラグをオフに
               // 他の値は保持（矢印を残すため）
            }
            g_SellGhostClosed = false; // ここをfalseに変更
            g_GhostSellCount = 0;
            
            // グローバル変数を更新
            SaveGhostPositionsToGlobal();
         }
         
         Print(direction, "ポジション利確: ゴーストポジションをリセットしました（矢印とテキストは保持）");
      }
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
//| ポジションにリミット決済を設定する                                 |
//+------------------------------------------------------------------+
void SetupLimitTakeProfit(int side)
{
   // リミット決済が無効な場合はスキップ
   if(!EnableLimitTP)
      return;

   // 処理対象のオペレーションタイプを決定
   int operationType = (side == 0) ? OP_BUY : OP_SELL;
   
   // ポジションの確認
   int positionCount = position_count(operationType);
   if(positionCount <= 0)
      return;
   
   // 平均価格の計算
   double avgPrice = CalculateCombinedAveragePrice(operationType);
   if(avgPrice <= 0)
      return;
   
   // TP価格の計算
   double tpPrice = (side == 0) ? 
                  avgPrice + LimitTPPoints * Point : 
                  avgPrice - LimitTPPoints * Point;
   
   // シンボルの最小ストップレベルを取得
   int minStopLevel = (int)MarketInfo(Symbol(), MODE_STOPLEVEL);
   
   // 現在価格を取得
   double currentPrice = (side == 0) ? GetBidPrice() : GetAskPrice();
   
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
                     ", 方向=", (side == 0) ? "Buy" : "Sell", 
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
   
   // リミットラインはデフォルトのテイクプロフィットラインカラーを使用
   string lineName = "LimitTP" + ((side == 0) ? "Buy" : "Sell");
   if(ObjectFind(g_ObjectPrefix + lineName) >= 0)
      ObjectDelete(g_ObjectPrefix + lineName);
      
   CreateHorizontalLine(g_ObjectPrefix + lineName, tpPrice, TakeProfitLineColor, STYLE_DASH, 1);
   
   // ラベルも表示
   string labelName = "LimitTPLabel" + ((side == 0) ? "Buy" : "Sell");
   if(ObjectFind(g_ObjectPrefix + labelName) >= 0)
      ObjectDelete(g_ObjectPrefix + labelName);
      
   string labelText = "Limit TP: " + DoubleToString(tpPrice, Digits) + " (+" + IntegerToString(LimitTPPoints) + "pt)";
   CreatePriceLabel(g_ObjectPrefix + labelName, labelText, tpPrice, TakeProfitLineColor, side == 0);
}