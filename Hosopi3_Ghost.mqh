//+------------------------------------------------------------------+
//|                Hosopi 3 - ゴーストロジック関数                    |
//|                        Copyright 2025                            |
//+------------------------------------------------------------------+
#include "Hosopi3_Defines.mqh"
#include "Hosopi3_Trading.mqh"
#include "Hosopi3_Utils.mqh"

// 点線オブジェクトの種類を定義
#define LINE_TYPE_GHOST      0  // ゴーストポジションの水平線
#define LINE_TYPE_AVG_PRICE  1  // 平均価格ライン
#define LINE_TYPE_TP         2  // 利確ライン
//+------------------------------------------------------------------+
//| 決済後の再エントリー問題を修正する関数                           |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| CheckTakeProfitConditions関数の修正部分                          |
//+------------------------------------------------------------------+
void CheckTakeProfitConditions(int side)
{
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

   // 利確条件の判定
   bool tpCondition = false;

   if(side == 0) // Buy
      tpCondition = (currentPrice > avgPrice + TakeProfitPoints * Point);
   else // Sell
      tpCondition = (currentPrice < avgPrice - TakeProfitPoints * Point);

   // 利確条件が満たされた場合
   if(tpCondition)
   {
      string direction = (side == 0) ? "Buy" : "Sell";
      Print(direction, "利確条件成立: 平均価格=", DoubleToString(avgPrice, 5), ", 現在価格=", DoubleToString(currentPrice, 5));
      
      // リアルポジションの決済
      if(positionCount > 0) {
         position_close(side);
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
            g_BuyGhostClosed = false; // 修正: ここをfalseに変更
            g_GhostBuyCount = 0;
            
            // Sell側ゴーストポジションの状態をリセット
            for(int i = 0; i < g_GhostSellCount; i++) {
               g_GhostSellPositions[i].isGhost = false;  // ゴーストフラグをオフに
               // 他の値は保持（矢印を残すため）
            }
            g_SellGhostClosed = false; // 修正: ここをfalseに変更
            g_GhostSellCount = 0;
            
            // グローバル変数を更新
            SaveGhostPositionsToGlobal();
         }
         
         Print(direction, "ポジション利確: ゴーストポジションをリセットしました（矢印とテキストは保持）");
      }
   }
}

//+------------------------------------------------------------------+
//| 特定方向のゴーストポジションだけをリセットする関数 - 修正版      |
//+------------------------------------------------------------------+
void ResetSpecificGhost(int type)
{
   if(type == OP_BUY)
   {
      // ゴーストBuyポジションのカウントをログに出力
      Print("ゴーストBuyポジションのみリセット開始: カウント=", g_GhostBuyCount);
      
      // BUY側のゴーストオブジェクトを削除 - 矢印とテキストは残す
      DeleteGhostLinesAndPreventRecreation(OP_BUY);
      
      // ゴーストBuyポジションカウントをリセット
      g_GhostBuyCount = 0;
      
      // 構造体配列を初期化 - ただし矢印とテキストは残すため完全リセットしない
      for(int i = 0; i < ArraySize(g_GhostBuyPositions); i++)
      {
         g_GhostBuyPositions[i].isGhost = false;  // ゴーストフラグをオフに
         // 他のプロパティは維持（矢印のために必要なデータ）
      }
      
      // 決済済みフラグをセット - ここでtrueのままにしておく
      g_BuyGhostClosed = true;
      
      Print("ゴーストBuyポジションのみリセット完了（矢印とテキストは保持）");
   }
   else // OP_SELL
   {
      // ゴーストSellポジションのカウントをログに出力
      Print("ゴーストSellポジションのみリセット開始: カウント=", g_GhostSellCount);
      
      // SELL側のゴーストオブジェクトを削除 - 矢印とテキストは残す
      DeleteGhostLinesAndPreventRecreation(OP_SELL);
      
      // ゴーストSellポジションカウントをリセット
      g_GhostSellCount = 0;
      
      // 構造体配列を初期化 - ただし矢印とテキストは残すため完全リセットしない
      for(int i = 0; i < ArraySize(g_GhostSellPositions); i++)
      {
         g_GhostSellPositions[i].isGhost = false;  // ゴーストフラグをオフに
         // 他のプロパティは維持（矢印のために必要なデータ）
      }
      
      // 決済済みフラグをセット - ここでtrueのままにしておく
      g_SellGhostClosed = true;
      
      Print("ゴーストSellポジションのみリセット完了（矢印とテキストは保持）");
   }
   
   // グローバル変数の最新状態を保存
   SaveGhostPositionsToGlobal();
   
   // ポジションテーブルを更新
   UpdatePositionTable();
   
   // 平均取得価格ラインは更新しない（削除されたまま）
   
   // チャートを再描画して変更を反映
   ChartRedraw();
}

//+------------------------------------------------------------------+
//| ResetGhost関数 - ゴーストポジションをリセットする - 修正版       |
//+------------------------------------------------------------------+
void ResetGhost(int type)
{
   if(type == OP_BUY)
   {
      // ゴーストBuyポジションのカウントをログに出力
      Print("ゴーストBuyポジションリセット開始: カウント=", g_GhostBuyCount);
      
      // 重要: 先にオブジェクトを削除（強化版）
      Print("Buy関連のゴーストオブジェクト削除開始");
      
      // 全てのゴーストBuyオブジェクトを削除
      DeleteAllGhostObjectsByType(OP_BUY);
      
      // 特に点線に関連するオブジェクトを明示的に削除
      DeleteGhostLinesByType(OP_BUY, LINE_TYPE_GHOST);
      
      // ゴーストBuyポジションカウントをリセット
      g_GhostBuyCount = 0;
      
      // 構造体配列を初期化
      for(int i = 0; i < ArraySize(g_GhostBuyPositions); i++)
      {
         g_GhostBuyPositions[i].type = 0;
         g_GhostBuyPositions[i].lots = 0;
         g_GhostBuyPositions[i].symbol = "";
         g_GhostBuyPositions[i].price = 0;
         g_GhostBuyPositions[i].profit = 0;
         g_GhostBuyPositions[i].ticket = 0;
         g_GhostBuyPositions[i].openTime = 0;
         g_GhostBuyPositions[i].isGhost = false;
         g_GhostBuyPositions[i].level = 0;
      }
      
      // フラグをリセット - ここをfalseに修正
      g_BuyGhostClosed = false;
      
      Print("ゴーストBuyポジションをリセットしました");
   }
   else // OP_SELL
   {
      // 同様の処理をSell側にも追加
      Print("ゴーストSellポジションリセット開始: カウント=", g_GhostSellCount);
      
      // 重要: 先にオブジェクトを削除（強化版）
      Print("Sell関連のゴーストオブジェクト削除開始");
      
      // 全てのゴーストSellオブジェクトを削除
      DeleteAllGhostObjectsByType(OP_SELL);
      
      // 特に点線に関連するオブジェクトを明示的に削除
      DeleteGhostLinesByType(OP_SELL, LINE_TYPE_GHOST);
      
      g_GhostSellCount = 0;
      for(int i = 0; i < ArraySize(g_GhostSellPositions); i++)
      {
         g_GhostSellPositions[i].type = 0;
         g_GhostSellPositions[i].lots = 0;
         g_GhostSellPositions[i].symbol = "";
         g_GhostSellPositions[i].price = 0;
         g_GhostSellPositions[i].profit = 0;
         g_GhostSellPositions[i].ticket = 0;
         g_GhostSellPositions[i].openTime = 0;
         g_GhostSellPositions[i].isGhost = false;
         g_GhostSellPositions[i].level = 0;
      }
      
      // フラグをリセット - ここをfalseに修正
      g_SellGhostClosed = false;
      
      Print("ゴーストSellポジションをリセットしました");
   }
   
   // 最後に明示的にDeleteAllEntryPointsを呼び出し
   DeleteAllEntryPoints();
   
   // グローバル変数の最新状態を保存
   SaveGhostPositionsToGlobal();
   
   // ポジションテーブルを更新
   UpdatePositionTable();
   
   // 平均取得価格ラインを更新 (必要に応じて)
   if(AveragePriceLine == ON_MODE && g_AvgPriceVisible)
   {
      UpdateAveragePriceLines(0); // Buy側
      UpdateAveragePriceLines(1); // Sell側
   }
   
   // チャートを再描画して変更を反映
   ChartRedraw();
   
   // 最後に強制的に残りのゴーストオブジェクトを確認
   int remainingCount = 0;
   for(int i = ObjectsTotal() - 1; i >= 0; i--)
   {
      string name = ObjectName(i);
      // 現在のEAのプレフィックスを持つオブジェクトのみカウント（複数チャート対策）
      if(StringFind(name, g_ObjectPrefix) == 0 && 
         StringFind(name, "Ghost") >= 0 && 
         StringFind(name, "Table") < 0 && 
         StringFind(name, "btnGhost") < 0)
      {
         remainingCount++;
      }
   }
   
   if(remainingCount > 0)
   {
      Print("警告: まだ", remainingCount, "個のゴースト関連オブジェクトが残っています。強制削除を試みます。");
      DeleteAllGhostObjectsByType(0);
      DeleteAllGhostObjectsByType(1);
   }
}


//+------------------------------------------------------------------+
//| ProcessGhostEntries関数の修正 - 決済済みフラグチェック改善      |
//+------------------------------------------------------------------+
void ProcessGhostEntries(int side)
{
   // リアルポジションがある場合はリターン（複数チャート対策）
   if(position_count(OP_BUY) > 0 || position_count(OP_SELL) > 0) {
      return;
   }

   if(!g_GhostMode)
      return;

   // ナンピンスキップレベルがSKIP_NONEの場合はゴーストモードを使用しない
   if(NanpinSkipLevel == SKIP_NONE)
   {
      // 通常のエントリー処理を行う（ゴーストなし）
      ProcessRealEntries(side);
      return;
   }

   // 処理対象のオペレーションタイプを決定
   int operationType = (side == 0) ? OP_BUY : OP_SELL;
   
   // 方向によって変数をセット
   bool closedFlag = (operationType == OP_BUY) ? g_BuyGhostClosed : g_SellGhostClosed;
   
   // 決済済みフラグが立っている場合の処理
   if(closedFlag) {
      // デバッグ出力
      static datetime lastClosedFlagTime = 0;
      if(TimeCurrent() - lastClosedFlagTime > 60) // 1分ごとに出力
      {
         string direction = (side == 0) ? "Buy" : "Sell";
         Print("ゴースト", direction, "は決済済み状態のため、新規エントリーをスキップします");
         lastClosedFlagTime = TimeCurrent();
      }
      return;
   }

   // エントリーモードに基づくチェック
   bool modeAllowed = false;
   if(side == 0) // Buy
      modeAllowed = (EntryMode == MODE_BUY_ONLY || EntryMode == MODE_BOTH);
   else // Sell
      modeAllowed = (EntryMode == MODE_SELL_ONLY || EntryMode == MODE_BOTH);

   if(!modeAllowed)
      return;

   // エントリー可能時間かチェック
   if(!IsTimeAllowed(operationType))
      return;

   // 現在の時間を取得
   datetime currentTime = TimeCurrent();

   // デバッグ情報（毎分1回のみ出力するためにチェック）
   static datetime lastDebugTime = 0;
   if(currentTime - lastDebugTime > 60) // 1分ごとに出力
   {
      lastDebugTime = currentTime;
      string direction = (side == 0) ? "Buy" : "Sell";
      Print("時間チェック: ", direction, "許可=", IsTimeAllowed(operationType) ? "はい" : "いいえ");
   }

   // エントリー方向チェック
   if(!IsEntryAllowed(side))
      return;

   // ゴーストポジションの最大数はナンピンスキップレベルの値までに制限
   int maxGhostPositions = (int)NanpinSkipLevel;

   // ゴーストポジションのカウントを取得
   int ghostCount = ghost_position_count(operationType);

   // ゴーストポジションがない場合は新規エントリー
   if(ghostCount == 0 && position_count(operationType) == 0)
   {
      string direction = (side == 0) ? "Buy" : "Sell";
      Print("新規ゴースト", direction, "エントリー条件が揃いました");
      InitializeGhostPosition(operationType);
   }
   // ナンピン条件チェック（ゴーストポジション数が最大数未満の場合のみ）
   else if(ghostCount > 0 && ghostCount < maxGhostPositions)
   {
      CheckGhostNanpinCondition(operationType);
   }
}

//+------------------------------------------------------------------+
//| OnTimer関数を追加 - 定期的なフラグチェックとクリア               |
//+------------------------------------------------------------------+
void OnTimerHandler()
{
   // 10分ごとにゴースト状態をチェック
   static datetime lastGhostCheckTime = 0;
   if(TimeCurrent() - lastGhostCheckTime > 600)
   {
      // リアルポジションがない場合
      if(position_count(OP_BUY) == 0 && position_count(OP_SELL) == 0)
      {
         // ゴーストポジションもない場合は、決済済みフラグをリセット
         if(g_GhostBuyCount == 0 && g_GhostSellCount == 0)
         {
            bool needsUpdate = false;
            
            if(g_BuyGhostClosed)
            {
               g_BuyGhostClosed = false;
               Print("定期チェック: Buyゴースト決済済みフラグをリセットしました");
               needsUpdate = true;
            }
            
            if(g_SellGhostClosed)
            {
               g_SellGhostClosed = false;
               Print("定期チェック: Sellゴースト決済済みフラグをリセットしました");
               needsUpdate = true;
            }
            
            if(needsUpdate)
            {
               SaveGhostPositionsToGlobal();
            }
         }
      }
      
      lastGhostCheckTime = TimeCurrent();
   }
}


//+------------------------------------------------------------------+
//| オブジェクト名生成のためのヘルパー関数                           |
//+------------------------------------------------------------------+
string GenerateGhostObjectName(string baseType, int operationType, int level, datetime time = 0)
{
   if(time == 0) time = TimeCurrent();
   string timeStr = IntegerToString(time);
   string typeStr = IntegerToString(operationType);
   string levelStr = IntegerToString(level);
   
   return g_ObjectPrefix + baseType + "_" + timeStr + "_" + typeStr + "_" + levelStr;
}

//+------------------------------------------------------------------+
//| 特定タイプの点線オブジェクトのみを削除する関数                   |
//+------------------------------------------------------------------+
void DeleteGhostLinesByType(int operationType, int lineType)
{
   string typeStr = (operationType == OP_BUY) ? "Buy" : "Sell";
   string lineTypeStr = "";
   
   switch(lineType) {
      case LINE_TYPE_GHOST:
         lineTypeStr = "GhostLine";
         break;
      case LINE_TYPE_AVG_PRICE:
         lineTypeStr = "AvgPrice" + typeStr;
         break;
      case LINE_TYPE_TP:
         lineTypeStr = "TpLine" + typeStr;
         break;
      default:
         lineTypeStr = "*";
   }
   
   Print("DeleteGhostLinesByType: ", typeStr, " 関連の ", lineTypeStr, " を削除します");
   
   // 削除したオブジェクトの数をカウント
   int deletedCount = 0;
   
   // チャート上のすべてのオブジェクトをスキャン
   for(int i = ObjectsTotal() - 1; i >= 0; i--)
   {
      if(i >= ObjectsTotal()) continue; // 安全チェック
      
      string name = ObjectName(i);
      
      // 現在のEAのプレフィックスを持つオブジェクトのみ処理（複数チャート対策）
      if(StringFind(name, g_ObjectPrefix) != 0)
         continue;
      
      bool shouldDelete = false;
      
      // 適切なオブジェクトタイプを特定
      if(lineType == LINE_TYPE_GHOST)
      {
         if(StringFind(name, "GhostLine_") >= 0)
         {
            if((operationType == OP_BUY && StringFind(name, "_0_") >= 0) ||
               (operationType == OP_SELL && StringFind(name, "_1_") >= 0))
            {
               shouldDelete = true;
            }
         }
      }
      else if(lineType == LINE_TYPE_AVG_PRICE)
      {
         if((operationType == OP_BUY && StringFind(name, "AvgPriceBuy") >= 0) ||
            (operationType == OP_SELL && StringFind(name, "AvgPriceSell") >= 0))
         {
            shouldDelete = true;
         }
      }
      else if(lineType == LINE_TYPE_TP)
      {
         if((operationType == OP_BUY && StringFind(name, "TpLineBuy") >= 0) ||
            (operationType == OP_SELL && StringFind(name, "TpLineSell") >= 0))
         {
            shouldDelete = true;
         }
      }
      
      // 削除条件に合致する場合は削除
      if(shouldDelete)
      {
         if(ObjectFind(name) >= 0) // 存在確認
         {
            if(ObjectDelete(name))
            {
               deletedCount++;
            }
            else
            {
               Print("オブジェクト削除エラー: ", name, ", エラーコード: ", GetLastError());
            }
         }
      }
   }
   
   Print("DeleteGhostLinesByType: ", typeStr, "タイプの", deletedCount, "個の", lineTypeStr, "オブジェクトを削除しました");
}

//+------------------------------------------------------------------+
//| 決済時に点線と関連ラインを完全に削除する関数                      |
//+------------------------------------------------------------------+
void DeleteGhostLinesAndPreventRecreation(int type)
{
   string typeStr = (type == OP_BUY) ? "Buy" : "Sell";
   Print("DeleteGhostLinesAndPreventRecreation: ", typeStr, " 関連の点線を削除し再生成を防止します");
   
   // 各種タイプの点線を削除
   DeleteGhostLinesByType(type, LINE_TYPE_GHOST);    // ゴースト水平線
   DeleteGhostLinesByType(type, LINE_TYPE_AVG_PRICE); // 平均価格ライン
   DeleteGhostLinesByType(type, LINE_TYPE_TP);        // 利確ライン
   
   // ラベルも削除
   for(int i = ObjectsTotal() - 1; i >= 0; i--)
   {
      if(i >= ObjectsTotal()) continue; // 安全チェック
      
      string name = ObjectName(i);
      
      // 現在のEAのプレフィックスを持つオブジェクトのみ処理
      if(StringFind(name, g_ObjectPrefix) != 0)
         continue;
         
      // 平均価格ラベルと利確ラベルを削除
      if((type == OP_BUY && 
          (StringFind(name, "AvgPriceLabelBuy") >= 0 || 
           StringFind(name, "TpLabelBuy") >= 0)) ||
         (type == OP_SELL && 
          (StringFind(name, "AvgPriceLabelSell") >= 0 || 
           StringFind(name, "TpLabelSell") >= 0)))
      {
         ObjectDelete(name);
      }
   }
   
   // チャートを再描画
   ChartRedraw();
}


//+------------------------------------------------------------------+
//| 平均取得価格ラインを更新 - 修正版                                |
//+------------------------------------------------------------------+
void UpdateAveragePriceLines(int side)
{
   // 処理対象のオペレーションタイプを決定
   int operationType = (side == 0) ? OP_BUY : OP_SELL;

   // 決済済みの方向は処理しない
   if((side == 0 && g_BuyGhostClosed) || (side == 1 && g_SellGhostClosed))
      return;

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

   // 合計損益を計算
   double combinedProfit = CalculateCombinedProfit(operationType);

   // 方向によって異なる変数を設定
   string direction = (side == 0) ? "BUY" : "SELL";
   string lineName = "AvgPrice" + ((side == 0) ? "Buy" : "Sell");
   string tpLineName = "TpLine" + ((side == 0) ? "Buy" : "Sell");
   string labelName = "AvgPriceLabel" + ((side == 0) ? "Buy" : "Sell");
   string tpLabelName = "TpLabel" + ((side == 0) ? "Buy" : "Sell");

   // 既存のラインを削除して再作成する
   DeleteGhostLinesByType(operationType, LINE_TYPE_AVG_PRICE); // 平均価格ライン削除
   DeleteGhostLinesByType(operationType, LINE_TYPE_TP);        // TP価格ライン削除
   
   // ラベルも削除
   if(ObjectFind(g_ObjectPrefix + labelName) >= 0)
      ObjectDelete(g_ObjectPrefix + labelName);
   if(ObjectFind(g_ObjectPrefix + tpLabelName) >= 0)
      ObjectDelete(g_ObjectPrefix + tpLabelName);

   // ライン色の決定
   color lineColor;
   if(side == 0) // Buy
      lineColor = combinedProfit >= 0 ? clrDeepSkyBlue : clrCrimson;
   else // Sell
      lineColor = combinedProfit >= 0 ? clrLime : clrRed;

   // TP価格の計算
   double tpPrice = (side == 0) ? 
                  avgPrice + TakeProfitPoints * Point : 
                  avgPrice - TakeProfitPoints * Point;

   // 平均取得価格ライン（カスタムデザイン）
   CreateHorizontalLine(g_ObjectPrefix + lineName, avgPrice, lineColor, STYLE_SOLID, 2);

   // 利確ライン（カスタムデザイン）
   CreateHorizontalLine(g_ObjectPrefix + tpLineName, tpPrice, TakeProfitLineColor, STYLE_DASH, 1);

   // 平均価格のラベル表示（見やすく）
   string labelText = direction + " AVG: " + DoubleToString(avgPrice, Digits) + 
                  " P/L: " + DoubleToStr(combinedProfit, 2) + "$";
   CreatePriceLabel(g_ObjectPrefix + labelName, labelText, avgPrice, lineColor, side == 0);

   // 利確価格のラベル表示
   string tpLabelText = "TP: " + DoubleToString(tpPrice, Digits);
   CreatePriceLabel(g_ObjectPrefix + tpLabelName, tpLabelText, tpPrice, TakeProfitLineColor, side == 0);
}



//+------------------------------------------------------------------+
//| 初期化時にも決済済みフラグをリセット - InitializeEAの中で呼ぶ    |
//+------------------------------------------------------------------+
void ResetGhostClosedFlags()
{
   g_BuyGhostClosed = false;
   g_SellGhostClosed = false;
}

//+------------------------------------------------------------------+
//| ゴーストポジションの数を取得する関数                              |
//+------------------------------------------------------------------+
int ghost_position_count(int type)
{
   // タイプ（OP_BUY/OP_SELL）に応じて適切なゴーストカウントを返す
   if(type == OP_BUY)
      return g_GhostBuyCount;
   else if(type == OP_SELL)
      return g_GhostSellCount;
   else
      return 0; // 不明なタイプの場合は0を返す
}

//+------------------------------------------------------------------+
//| 全てのゴーストポジションの数を取得する関数                       |
//+------------------------------------------------------------------+
int ghost_positions_total()
{
   // Buy側とSell側のゴーストポジション数の合計を返す
   return g_GhostBuyCount + g_GhostSellCount;
}

//+------------------------------------------------------------------+
//| リアルとゴーストを合わせたポジション数を取得する関数              |
//+------------------------------------------------------------------+
int combined_position_count(int type)
{
   // リアルポジション数
   int realCount = position_count(type);
   
   // ゴーストポジション数
   int ghostCount = ghost_position_count(type);
   
   // 合計を返す
   return realCount + ghostCount;
}

//+------------------------------------------------------------------+
//| ゴーストポジションの最後の価格を取得する関数                      |
//+------------------------------------------------------------------+
double ghost_position_last_price(int type)
{
   double lastPrice = 0;
   
   if(type == OP_BUY)
   {
      // ゴーストBuyポジションが存在する場合
      if(g_GhostBuyCount > 0)
      {
         // 最後のBuyゴーストポジションの価格を返す
         lastPrice = g_GhostBuyPositions[g_GhostBuyCount - 1].price;
         Print("最後のBuyゴーストポジション価格: ", DoubleToString(lastPrice, 5), ", レベル: ", g_GhostBuyCount);
      }
      else
      {
         Print("Buyゴーストポジションが存在しません");
      }
   }
   else // OP_SELL
   {
      // ゴーストSellポジションが存在する場合
      if(g_GhostSellCount > 0)
      {
         // 最後のSellゴーストポジションの価格を返す
         lastPrice = g_GhostSellPositions[g_GhostSellCount - 1].price;
         Print("最後のSellゴーストポジション価格: ", DoubleToString(lastPrice, 5), ", レベル: ", g_GhostSellCount);
      }
      else
      {
         Print("Sellゴーストポジションが存在しません");
      }
   }
   
   return lastPrice;
}

//+------------------------------------------------------------------+
//| リアルまたはゴーストの最後のポジション価格を取得                 |
//+------------------------------------------------------------------+
double combined_position_last_price(int type)
{
   // リアルポジションを優先して取得
   double realPrice = GetLastPositionPrice(type);
   
   // リアルポジションがなければゴーストポジションの価格を返す
   if(realPrice > 0)
   {
      return realPrice;
   }
   else
   {
      return ghost_position_last_price(type);
   }
}

//+------------------------------------------------------------------+
//| 特定タイプのゴーストオブジェクトをすべて削除 - テーブル保護強化版  |
//+------------------------------------------------------------------+
void DeleteAllGhostObjectsByType(int type)
{
   string typeStr = (type == OP_BUY) ? "Buy" : "Sell";
   Print("DeleteAllGhostObjectsByType: ", typeStr, " 関連オブジェクトの削除を開始");
   
   // 削除したオブジェクトの数をカウント
   int deletedCount = 0;
   
   // チャート上のすべてのオブジェクトをスキャン
   for(int i = ObjectsTotal() - 1; i >= 0; i--)
   {
      if(i >= ObjectsTotal()) continue; // 安全チェック
      
      string name = ObjectName(i);
      
      // 現在のEAのプレフィックスを持つオブジェクトのみ処理（複数チャート対策）
      if(StringFind(name, g_ObjectPrefix) != 0)
         continue;
      
      // GUI要素の保護（ボタン、パネル、テーブル）
      if(StringFind(name, "btn") >= 0 ||          // ボタン
         StringFind(name, "Panel") >= 0 ||        // パネル
         StringFind(name, "Title") >= 0 ||        // タイトル
         StringFind(name, "GhostTable_") >= 0 ||  // テーブル本体
         StringFind(name, "Table_") >= 0)         // テーブル要素
      {
         continue; // これらのオブジェクトは保護
      }
      
      bool shouldDelete = false;
      
      // 追加: 点線関連のオブジェクトを明示的にチェック
      if(StringFind(name, "GhostLine_") >= 0)
      {
         if((type == OP_BUY && StringFind(name, "_0_") >= 0) ||
            (type == OP_SELL && StringFind(name, "_1_") >= 0))
         {
            shouldDelete = true;
         }
      }
      
      // ゴーストエントリーオブジェクト検出条件
      if(StringFind(name, "Ghost") >= 0)
      {
         // タイプ固有の検出
         if((type == OP_BUY && 
             (StringFind(name, "Buy") >= 0 || 
              StringFind(name, "_0_") >= 0)) ||
            (type == OP_SELL && 
             (StringFind(name, "Sell") >= 0 || 
              StringFind(name, "_1_") >= 0)))
         {
            // テーブル関連は除外 - "GhostTable" が含まれる名前は保護
            if(StringFind(name, "GhostTable") < 0 && StringFind(name, "Table") < 0)
            {
               shouldDelete = true;
            }
         }
      }
      
      // 平均価格ラインやその他のゴースト関連オブジェクト
      if((type == OP_BUY && 
          (StringFind(name, "AvgPriceBuy") >= 0 || 
           StringFind(name, "TpLineBuy") >= 0 || 
           StringFind(name, "TpLabelBuy") >= 0 ||
           StringFind(name, "AvgPriceLabelBuy") >= 0)) ||
         (type == OP_SELL && 
          (StringFind(name, "AvgPriceSell") >= 0 || 
           StringFind(name, "TpLineSell") >= 0 || 
           StringFind(name, "TpLabelSell") >= 0 ||
           StringFind(name, "AvgPriceLabelSell") >= 0)))
      {
         shouldDelete = true;
      }
      
      // "Ghost Buy" or "Ghost Sell" というテキストパターンを持つオブジェクト
      if((type == OP_BUY && StringFind(name, "Ghost Buy") >= 0) ||
         (type == OP_SELL && StringFind(name, "Ghost Sell") >= 0))
      {
         shouldDelete = true;
      }
      
      // エントリーポイントとライン関連のオブジェクト (修正版)
      if(
         (type == OP_BUY && (
            (StringFind(name, "GhostEntry_") >= 0 && StringFind(name, "_0_") >= 0) ||
            (StringFind(name, "GhostInfo_") >= 0 && StringFind(name, "_0_") >= 0) ||
            (StringFind(name, "GhostLine_") >= 0 && StringFind(name, "_0_") >= 0)
         )) ||
         (type == OP_SELL && (
            (StringFind(name, "GhostEntry_") >= 0 && StringFind(name, "_1_") >= 0) ||
            (StringFind(name, "GhostInfo_") >= 0 && StringFind(name, "_1_") >= 0) ||
            (StringFind(name, "GhostLine_") >= 0 && StringFind(name, "_1_") >= 0)
         ))
      )
      {
         shouldDelete = true;
      }
      
      // 削除条件に合致する場合は削除
      if(shouldDelete)
      {
         if(ObjectFind(name) >= 0) // 存在確認
         {
            if(ObjectDelete(name))
            {
               deletedCount++;
            }
            else
            {
               Print("オブジェクト削除エラー: ", name, ", エラーコード: ", GetLastError());
            }
         }
      }
   }
   
   Print("DeleteAllGhostObjectsByType: ", typeStr, "タイプの", deletedCount, "個のオブジェクトを削除しました");
   
   // チャートを再描画
   ChartRedraw();
}



//+------------------------------------------------------------------+
//| ゴーストエントリーポイントを作成                                  |
//+------------------------------------------------------------------+
void CreateGhostEntryPoint(int type, double price, double lots, int level)
{
   if(!PositionSignDisplay)
      return;
      
   datetime time = TimeCurrent();
   
   // 一意のオブジェクト名を生成
   string arrowName = GenerateGhostObjectName("GhostEntry", type, level, time);
   string infoName = GenerateGhostObjectName("GhostInfo", type, level, time);
   string lineName = GenerateGhostObjectName("GhostLine", type, level, time);
   
   // 矢印の作成
   ObjectCreate(arrowName, OBJ_ARROW, 0, time, price);
   ObjectSet(arrowName, OBJPROP_ARROWCODE, type == OP_BUY ? 233 : 234); // Buy: 上向き矢印, Sell: 下向き矢印
   ObjectSet(arrowName, OBJPROP_COLOR, type == OP_BUY ? GhostBuyColor : GhostSellColor);
   ObjectSet(arrowName, OBJPROP_WIDTH, GhostArrowSize);
   ObjectSet(arrowName, OBJPROP_SELECTABLE, false);
   
   // 情報テキストの作成
   string infoText = "Ghost " + (type == OP_BUY ? "Buy" : "Sell") + " " + DoubleToString(lots, 2);
   ObjectCreate(infoName, OBJ_TEXT, 0, time, price + (type == OP_BUY ? 20*Point : -20*Point));
   ObjectSetText(infoName, infoText, 8, "Arial", type == OP_BUY ? GhostBuyColor : GhostSellColor);
   ObjectSet(infoName, OBJPROP_SELECTABLE, false);
   
   // 水平線の作成 (点線からチャート全体に広がる水平線に変更)
   ObjectCreate(lineName, OBJ_HLINE, 0, 0, price);
   ObjectSet(lineName, OBJPROP_COLOR, type == OP_BUY ? GhostBuyColor : GhostSellColor);
   ObjectSet(lineName, OBJPROP_STYLE, STYLE_DOT);
   ObjectSet(lineName, OBJPROP_WIDTH, 1);
   ObjectSet(lineName, OBJPROP_BACK, true);
   ObjectSet(lineName, OBJPROP_SELECTABLE, false);
   
   // オブジェクト名を保存
   SaveObjectName(arrowName, g_EntryNames, g_EntryObjectCount);
   SaveObjectName(infoName, g_EntryNames, g_EntryObjectCount);
   SaveObjectName(lineName, g_EntryNames, g_EntryObjectCount);
}

//+------------------------------------------------------------------+
//| すべてのエントリーポイントを削除                                  |
//+------------------------------------------------------------------+
void DeleteAllEntryPoints()
{
   int deletedCount = 0;
   
   // すべてのゴーストエントリー関連オブジェクトを検索して削除
   for(int i = ObjectsTotal() - 1; i >= 0; i--)
   {
      string name = ObjectName(i);
      
      // 現在のEAのプレフィックスを持つオブジェクトのみ削除（複数チャート対策）
      if(StringFind(name, g_ObjectPrefix) == 0 &&
         (StringFind(name, "GhostEntry_") >= 0 || 
          StringFind(name, "GhostInfo_") >= 0 || 
          StringFind(name, "GhostLine_") >= 0))
      {
         if(ObjectDelete(name))
         {
            deletedCount++;
         }
      }
   }
   
   // エントリーオブジェクト名配列をクリア
   for(int i = 0; i < g_EntryObjectCount; i++)
   {
      g_EntryNames[i] = "";
   }
   
   g_EntryObjectCount = 0;
   
   Print("DeleteAllEntryPoints: ", deletedCount, "個のゴーストエントリーポイントオブジェクトを削除");
}

//+------------------------------------------------------------------+
//| 有効なゴーストポジションに対してのみ点線を再作成                   |
//+------------------------------------------------------------------+
void RecreateValidGhostLines()
{
   Print("RecreateValidGhostLines: 有効なゴーストポジションに対してのみ点線を再作成");
   
   // 先に既存の点線を全て削除
   DeleteGhostLinesByType(OP_BUY, LINE_TYPE_GHOST);
   DeleteGhostLinesByType(OP_SELL, LINE_TYPE_GHOST);
   
   // BUY側のゴーストポジションに対して点線を作成
   for(int i = 0; i < g_GhostBuyCount; i++)
   {
      if(g_GhostBuyPositions[i].isGhost) // 有効なゴーストのみ
      {
         string lineName = GenerateGhostObjectName("GhostLine", OP_BUY, g_GhostBuyPositions[i].level, g_GhostBuyPositions[i].openTime);
         
         // 水平線の作成
         ObjectCreate(lineName, OBJ_HLINE, 0, 0, g_GhostBuyPositions[i].price);
         ObjectSet(lineName, OBJPROP_COLOR, GhostBuyColor);
         ObjectSet(lineName, OBJPROP_STYLE, STYLE_DOT);
         ObjectSet(lineName, OBJPROP_WIDTH, 1);
         ObjectSet(lineName, OBJPROP_BACK, true);
         ObjectSet(lineName, OBJPROP_SELECTABLE, false);
      }
   }
   
   // SELL側のゴーストポジションに対して点線を作成
   for(int i = 0; i < g_GhostSellCount; i++)
   {
      if(g_GhostSellPositions[i].isGhost) // 有効なゴーストのみ
      {
         string lineName = GenerateGhostObjectName("GhostLine", OP_SELL, g_GhostSellPositions[i].level, g_GhostSellPositions[i].openTime);
         
         // 水平線の作成
         ObjectCreate(lineName, OBJ_HLINE, 0, 0, g_GhostSellPositions[i].price);
         ObjectSet(lineName, OBJPROP_COLOR, GhostSellColor);
         ObjectSet(lineName, OBJPROP_STYLE, STYLE_DOT);
         ObjectSet(lineName, OBJPROP_WIDTH, 1);
         ObjectSet(lineName, OBJPROP_BACK, true);
         ObjectSet(lineName, OBJPROP_SELECTABLE, false);
      }
   }
   
   // チャートを再描画
   ChartRedraw();
}

//+------------------------------------------------------------------+
//| ゴーストエントリーポイントを再作成                                |
//+------------------------------------------------------------------+
void RecreateGhostEntryPoints()
{
   // 既存のエントリーポイントをクリア
   DeleteAllEntryPoints();
   g_EntryObjectCount = 0;
   
   // Buy ゴーストポジションのエントリーポイントを再作成
   for(int i = 0; i < g_GhostBuyCount; i++)
   {
      if(g_GhostBuyPositions[i].isGhost) // 有効なゴーストのみ
      {
         CreateGhostEntryPoint(OP_BUY, g_GhostBuyPositions[i].price, g_GhostBuyPositions[i].lots, g_GhostBuyPositions[i].level);
      }
   }
   
   // Sell ゴーストポジションのエントリーポイントを再作成
   for(int i = 0; i < g_GhostSellCount; i++)
   {
      if(g_GhostSellPositions[i].isGhost) // 有効なゴーストのみ
      {
         CreateGhostEntryPoint(OP_SELL, g_GhostSellPositions[i].price, g_GhostSellPositions[i].lots, g_GhostSellPositions[i].level);
      }
   }
   
   Print("ゴーストエントリーポイントを再作成しました - 有効Buy: ", CountValidGhosts(OP_BUY), ", 有効Sell: ", CountValidGhosts(OP_SELL));
}

//+------------------------------------------------------------------+
//| 有効なゴーストポジション数を取得                                   |
//+------------------------------------------------------------------+
int CountValidGhosts(int type)
{
   int validCount = 0;
   
   if(type == OP_BUY)
   {
      for(int i = 0; i < g_GhostBuyCount; i++)
      {
         if(g_GhostBuyPositions[i].isGhost)
            validCount++;
      }
   }
   else // OP_SELL
   {
      for(int i = 0; i < g_GhostSellCount; i++)
      {
         if(g_GhostSellPositions[i].isGhost)
            validCount++;
      }
   }
   
   return validCount;
}

//+------------------------------------------------------------------+
//| グローバル変数からゴーストポジション情報を削除                     |
//+------------------------------------------------------------------+
void ClearGhostPositionsFromGlobal()
{
   // 複数チャート対策: アカウント番号とマジックナンバーを含むプレフィックスを使用
   int deletedCount = 0;  // 削除したグローバル変数のカウンター変数を追加
   
   // すべてのグローバル変数をチェック
   for(int i = GlobalVariablesTotal() - 1; i >= 0; i--)
   {
      string name = GlobalVariableName(i);
      // プレフィックスが一致するものを削除
      if(StringFind(name, g_GlobalVarPrefix) == 0)
      {
         GlobalVariableDel(name);
         deletedCount++; // 削除したグローバル変数をカウント
      }
   }
   
   Print("グローバル変数からゴーストポジション情報を削除しました - ", deletedCount, "個の変数を削除");
}

//+------------------------------------------------------------------+
//| グローバル変数からゴーストポジション情報を読み込み                 |
//+------------------------------------------------------------------+
bool LoadGhostPositionsFromGlobal()
{
   // 複数チャート対策: アカウント番号とマジックナンバーを含むプレフィックスを使用
   
   // データが存在するか確認
   if(!GlobalVariableCheck(g_GlobalVarPrefix + "SaveTime"))
   {
      Print("グローバル変数にゴーストポジション情報が見つかりませんでした");
      return false;
   }
   
   // リアルポジションがある場合は読み込みをスキップ
   if(position_count(OP_BUY) > 0 || position_count(OP_SELL) > 0) {
      Print("リアルポジションが存在するため、ゴーストポジション情報の読み込みをスキップします");
      return false;
   }
   
   // カウンター読み込み
   int buyCount = (int)GlobalVariableGet(g_GlobalVarPrefix + "BuyCount");
   int sellCount = (int)GlobalVariableGet(g_GlobalVarPrefix + "SellCount");
   
   // 最後のナンピン時間読み込み
   g_LastBuyNanpinTime = (datetime)GlobalVariableGet(g_GlobalVarPrefix + "LastBuyNanpinTime");
   g_LastSellNanpinTime = (datetime)GlobalVariableGet(g_GlobalVarPrefix + "LastSellNanpinTime");
   
   
   // Buy ゴーストポジション読み込み
   for(int i = 0; i < buyCount; i++)
   {
      string posPrefix = g_GlobalVarPrefix + "Buy_" + IntegerToString(i) + "_";
      
      if(i < ArraySize(g_GhostBuyPositions))
      {
         g_GhostBuyPositions[i].type = (int)GlobalVariableGet(posPrefix + "Type");
         g_GhostBuyPositions[i].lots = GlobalVariableGet(posPrefix + "Lots");
         g_GhostBuyPositions[i].symbol = Symbol(); // シンボルは現在のチャートから取得
         g_GhostBuyPositions[i].price = GlobalVariableGet(posPrefix + "Price");
         g_GhostBuyPositions[i].profit = GlobalVariableGet(posPrefix + "Profit");
         g_GhostBuyPositions[i].ticket = (int)GlobalVariableGet(posPrefix + "Ticket");
         g_GhostBuyPositions[i].openTime = (datetime)GlobalVariableGet(posPrefix + "OpenTime");
         g_GhostBuyPositions[i].isGhost = GlobalVariableGet(posPrefix + "IsGhost") > 0;
         g_GhostBuyPositions[i].level = (int)GlobalVariableGet(posPrefix + "Level");
      }
   }
   g_GhostBuyCount = buyCount;
   
   // Sell ゴーストポジション読み込み
   for(int i = 0; i < sellCount; i++)
   {
      string posPrefix = g_GlobalVarPrefix + "Sell_" + IntegerToString(i) + "_";
      
      if(i < ArraySize(g_GhostSellPositions))
      {
         g_GhostSellPositions[i].type = (int)GlobalVariableGet(posPrefix + "Type");
         g_GhostSellPositions[i].lots = GlobalVariableGet(posPrefix + "Lots");
         g_GhostSellPositions[i].symbol = Symbol(); // シンボルは現在のチャートから取得
         g_GhostSellPositions[i].price = GlobalVariableGet(posPrefix + "Price");
         g_GhostSellPositions[i].profit = GlobalVariableGet(posPrefix + "Profit");
         g_GhostSellPositions[i].ticket = (int)GlobalVariableGet(posPrefix + "Ticket");
         g_GhostSellPositions[i].openTime = (datetime)GlobalVariableGet(posPrefix + "OpenTime");
         g_GhostSellPositions[i].isGhost = GlobalVariableGet(posPrefix + "IsGhost") > 0;
         g_GhostSellPositions[i].level = (int)GlobalVariableGet(posPrefix + "Level");
      }
   }
   g_GhostSellCount = sellCount;
   
   // フラグ読み込み
   g_GhostMode = GlobalVariableGet(g_GlobalVarPrefix + "GhostMode") > 0;
   g_AvgPriceVisible = GlobalVariableGet(g_GlobalVarPrefix + "AvgPriceVisible") > 0;
   g_BuyGhostClosed = GlobalVariableGet(g_GlobalVarPrefix + "BuyGhostClosed") > 0;
   g_SellGhostClosed = GlobalVariableGet(g_GlobalVarPrefix + "SellGhostClosed") > 0;
   
   Print("グローバル変数からゴーストポジション情報を読み込みました - Buy: ", buyCount, ", Sell: ", sellCount);
   
   // 読み込み成功
   return true;
}

//+------------------------------------------------------------------+
//| ゴーストポジション情報をグローバル変数に保存                       |
//+------------------------------------------------------------------+
void SaveGhostPositionsToGlobal()
{
   // 複数チャート対策: アカウント番号とマジックナンバーを含むプレフィックスを使用
   
   // カウンター保存
   GlobalVariableSet(g_GlobalVarPrefix + "BuyCount", g_GhostBuyCount);
   GlobalVariableSet(g_GlobalVarPrefix + "SellCount", g_GhostSellCount);
   
   // 最後のナンピン時間保存
   GlobalVariableSet(g_GlobalVarPrefix + "LastBuyNanpinTime", g_LastBuyNanpinTime);
   GlobalVariableSet(g_GlobalVarPrefix + "LastSellNanpinTime", g_LastSellNanpinTime);

   
   // Buy ゴーストポジション保存
   for(int i = 0; i < g_GhostBuyCount; i++)
   {
      string posPrefix = g_GlobalVarPrefix + "Buy_" + IntegerToString(i) + "_";
      GlobalVariableSet(posPrefix + "Type", g_GhostBuyPositions[i].type);
      GlobalVariableSet(posPrefix + "Lots", g_GhostBuyPositions[i].lots);
      GlobalVariableSet(posPrefix + "Price", g_GhostBuyPositions[i].price);
      GlobalVariableSet(posPrefix + "Profit", g_GhostBuyPositions[i].profit);
      GlobalVariableSet(posPrefix + "Ticket", g_GhostBuyPositions[i].ticket);
      GlobalVariableSet(posPrefix + "OpenTime", g_GhostBuyPositions[i].openTime);
      GlobalVariableSet(posPrefix + "IsGhost", g_GhostBuyPositions[i].isGhost ? 1 : 0);
      GlobalVariableSet(posPrefix + "Level", g_GhostBuyPositions[i].level);
   }

   // Sell ゴーストポジション保存
   for(int i = 0; i < g_GhostSellCount; i++)
   {
      string posPrefix = g_GlobalVarPrefix + "Sell_" + IntegerToString(i) + "_";
      GlobalVariableSet(posPrefix + "Type", g_GhostSellPositions[i].type);
      GlobalVariableSet(posPrefix + "Lots", g_GhostSellPositions[i].lots);
      GlobalVariableSet(posPrefix + "Price", g_GhostSellPositions[i].price);
      GlobalVariableSet(posPrefix + "Profit", g_GhostSellPositions[i].profit);
      GlobalVariableSet(posPrefix + "Ticket", g_GhostSellPositions[i].ticket);
      GlobalVariableSet(posPrefix + "OpenTime", g_GhostSellPositions[i].openTime);
      GlobalVariableSet(posPrefix + "IsGhost", g_GhostSellPositions[i].isGhost ? 1 : 0);
      GlobalVariableSet(posPrefix + "Level", g_GhostSellPositions[i].level);
   }

   // フラグ設定（ゴーストモード状態を保存）
   GlobalVariableSet(g_GlobalVarPrefix + "GhostMode", g_GhostMode ? 1 : 0);
   GlobalVariableSet(g_GlobalVarPrefix + "AvgPriceVisible", g_AvgPriceVisible ? 1 : 0);
   GlobalVariableSet(g_GlobalVarPrefix + "BuyGhostClosed", g_BuyGhostClosed ? 1 : 0);
   GlobalVariableSet(g_GlobalVarPrefix + "SellGhostClosed", g_SellGhostClosed ? 1 : 0);

   // 保存時間を記録
   GlobalVariableSet(g_GlobalVarPrefix + "SaveTime", TimeCurrent());

   Print("ゴーストポジション情報をグローバル変数に保存しました - 有効Buy: ", CountValidGhosts(OP_BUY), ", 有効Sell: ", CountValidGhosts(OP_SELL));
}

//+------------------------------------------------------------------+
//| ゴーストの平均取得価格を計算                                      |
//+------------------------------------------------------------------+
double CalculateGhostAveragePrice(int type)
{
   double totalLots = 0;
   double weightedPrice = 0;

   if(type == OP_BUY)
   {
      for(int i = 0; i < g_GhostBuyCount; i++)
      {
         if(g_GhostBuyPositions[i].isGhost) // 有効なゴーストのみ計算
         {
            totalLots += g_GhostBuyPositions[i].lots;
            weightedPrice += g_GhostBuyPositions[i].price * g_GhostBuyPositions[i].lots;
         }
      }
   }
   else
   {
      for(int i = 0; i < g_GhostSellCount; i++)
      {
         if(g_GhostSellPositions[i].isGhost) // 有効なゴーストのみ計算
         {
            totalLots += g_GhostSellPositions[i].lots;
            weightedPrice += g_GhostSellPositions[i].price * g_GhostSellPositions[i].lots;
         }
      }
   }

   // 平均取得価格を計算
   if(totalLots > 0)
      return weightedPrice / totalLots;
   else
      return 0;
}

//+------------------------------------------------------------------+
//| ゴーストとリアルポジションを合算した平均取得価格を計算           |
//+------------------------------------------------------------------+
double CalculateCombinedAveragePrice(int type)
{
   double totalLots = 0;
   double weightedPrice = 0;

   // ゴーストポジションの合計 (有効なゴーストのみ)
   if(type == OP_BUY)
   {
      for(int i = 0; i < g_GhostBuyCount; i++)
      {
         if(g_GhostBuyPositions[i].isGhost) // 有効なゴーストのみ
         {
            totalLots += g_GhostBuyPositions[i].lots;
            weightedPrice += g_GhostBuyPositions[i].price * g_GhostBuyPositions[i].lots;
         }
      }
   }
   else
   {
      for(int i = 0; i < g_GhostSellCount; i++)
      {
         if(g_GhostSellPositions[i].isGhost) // 有効なゴーストのみ
         {
            totalLots += g_GhostSellPositions[i].lots;
            weightedPrice += g_GhostSellPositions[i].price * g_GhostSellPositions[i].lots;

         }
      }
   }

   // リアルポジションの合計
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
      {
         if(OrderType() == type && OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumber)
         {
            totalLots += OrderLots();
            weightedPrice += OrderOpenPrice() * OrderLots();
         }
      }
   }

   // 平均取得価格を計算
   if(totalLots > 0)
      return weightedPrice / totalLots;
   else
      return 0;
}

//+------------------------------------------------------------------+
//| ポジションの合計損益を計算                                        |
//+------------------------------------------------------------------+
double CalculateCombinedProfit(int type)
{
   double totalProfit = 0;

   // リアルポジションの損益を合計
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
      {
         if(OrderType() == type && OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumber)
         {
            totalProfit += OrderProfit() + OrderSwap() + OrderCommission();
         }
      }
   }

   // ゴーストポジションの仮想損益を計算 (有効なゴーストのみ)
   if(type == OP_BUY)
   {
      for(int i = 0; i < g_GhostBuyCount; i++)
      {
         if(g_GhostBuyPositions[i].isGhost) // 有効なゴーストのみ
         {
            double currentProfit = (GetBidPrice() - g_GhostBuyPositions[i].price) * g_GhostBuyPositions[i].lots * MarketInfo(Symbol(), MODE_TICKVALUE) / Point;
            totalProfit += currentProfit;
         }
      }
   }
   else // OP_SELL
   {
      for(int i = 0; i < g_GhostSellCount; i++)
      {
         if(g_GhostSellPositions[i].isGhost) // 有効なゴーストのみ
         {
            double currentProfit = (g_GhostSellPositions[i].price - GetAskPrice()) * g_GhostSellPositions[i].lots * MarketInfo(Symbol(), MODE_TICKVALUE) / Point;
            totalProfit += currentProfit;
         }
      }
   }

   return totalProfit;
}

//+------------------------------------------------------------------+
//| ゴーストナンピン条件のチェック（修正版）                           |
//+------------------------------------------------------------------+
void CheckGhostNanpinCondition(int type)
{
   // リアルポジションがある場合は処理をスキップ（複数チャート対策）
   if(position_count(OP_BUY) > 0 || position_count(OP_SELL) > 0) {
      return;
   }

   // ゴーストが有効化されていない場合はスキップ
   if(!g_GhostMode) {
      return;
   }

   // 決済済みフラグが立っている場合はスキップ
   if((type == OP_BUY && g_BuyGhostClosed) || (type == OP_SELL && g_SellGhostClosed)) {
      return;
   }

   double currentPrice = (type == OP_BUY) ? GetBidPrice() : GetAskPrice();
   
   // 最後のゴーストポジション価格を取得
   double lastPrice = ghost_position_last_price(type);
   if(lastPrice <= 0) {
      // ゴーストポジションがない場合
      return;
   }
   
   // ゴーストポジション数を取得
   int ghostCount = ghost_position_count(type);
   int currentLevel = ghostCount; // レベルは1-indexedだが配列は0-indexed
   
   // 前回のナンピン時間を取得
   datetime lastNanpinTime = (type == OP_BUY) ? g_LastBuyNanpinTime : g_LastSellNanpinTime;
   
   // ナンピンインターバルチェック
   if(TimeCurrent() - lastNanpinTime < NanpinInterval * 60)
   {
      // デバッグログの追加（1分に1回のみ出力）
      static datetime lastIntervalDebugTime = 0;
      if(TimeCurrent() - lastIntervalDebugTime > 60)
      {
         Print("ナンピンインターバルが経過していません: ", 
              (TimeCurrent() - lastNanpinTime) / 60, "分 / ", 
              NanpinInterval, "分");
         lastIntervalDebugTime = TimeCurrent();
      }
      return;
   }
   
   // 計算に使用するナンピン幅を取得 (修正：正しいインデックスを使用)
   // currentLevelはポジション数（1から始まる）なので、配列インデックス（0から始まる）に変換
   int nanpinSpread = g_NanpinSpreadTable[currentLevel - 1];
   
   // デバッグログの追加
   string direction = (type == OP_BUY) ? "Buy" : "Sell";
   Print(direction, " ゴーストナンピン条件チェック: 現在価格=", currentPrice, 
         ", 前回価格=", lastPrice, 
         ", ナンピン幅=", nanpinSpread, 
         " ポイント, 差=", (type == OP_BUY ? (lastPrice - currentPrice) : (currentPrice - lastPrice)) / Point);
   
   // ナンピン条件判定
   bool nanpinCondition = false;
   
   if(type == OP_BUY) // Buy
   {
      // Buyナンピン条件: 現在価格が前回ポジション価格 - ナンピン幅 より低い
      nanpinCondition = (currentPrice < lastPrice - nanpinSpread * Point);
   }
   else // OP_SELL
   {
      // Sellナンピン条件: 現在価格が前回ポジション価格 + ナンピン幅 より高い
      nanpinCondition = (currentPrice > lastPrice + nanpinSpread * Point);
   }
   
   // ナンピン条件が満たされた場合
   if(nanpinCondition)
   {
      AddGhostNanpin(type);
      
      // ナンピン時間を更新
      if(type == OP_BUY)
         g_LastBuyNanpinTime = TimeCurrent();
      else
         g_LastSellNanpinTime = TimeCurrent();
         
      Print(direction, " ゴーストナンピン条件成立、ゴーストナンピン追加");
   }
}

//+------------------------------------------------------------------+
//| ゴーストナンピンの追加（修正版）                                   |
//+------------------------------------------------------------------+
void AddGhostNanpin(int type)
{
   if(position_count(OP_BUY) > 0 || position_count(OP_SELL) > 0) {
      Print("リアルポジションが存在するため、ゴーストナンピン追加をスキップします");
      return;
   }

   if((GetAskPrice() - GetBidPrice()) / Point > MaxSpreadPoints && MaxSpreadPoints > 0)
   {
      Print("スプレッドが大きすぎるため、ゴーストナンピン追加をスキップします: ", 
            (GetAskPrice() - GetBidPrice()) / Point, " > ", MaxSpreadPoints);
      return;
   }
      
   int maxGhostPositions = (int)NanpinSkipLevel;
   int currentLevel = ghost_position_count(type);
   
   if(currentLevel >= maxGhostPositions)
   {
      Print("ゴーストポジション数が最大数(", maxGhostPositions, ")に達しているため、ゴーストナンピンをスキップします");
      return;
   }
   
   // 重要：ここで実際のレベル (0-indexed) を設定
   int level = currentLevel;  // 現在のカウントがレベル（0から始まる）
   
   PositionInfo newPosition;
   newPosition.type = type;
   // g_LotTableのインデックスとしてレベル（0から始まる）を使用
   newPosition.lots = g_LotTable[level];
   newPosition.symbol = Symbol();
   newPosition.price = (type == OP_BUY) ? GetAskPrice() : GetBidPrice();
   newPosition.profit = 0;
   newPosition.ticket = 0;
   newPosition.openTime = TimeCurrent();
   newPosition.isGhost = true;
   newPosition.level = level;  // 0-indexedのレベルを設定
   
   if(type == OP_BUY)
   {
      g_GhostBuyPositions[g_GhostBuyCount] = newPosition;
      g_GhostBuyCount++;
      CreateGhostEntryPoint(type, newPosition.price, newPosition.lots, newPosition.level);
      
      if(g_GhostBuyCount >= (int)NanpinSkipLevel)
      {
         Print("ナンピンスキップレベル条件達成: Level=", NanpinSkipLevel, ", 現在のゴーストカウント=", g_GhostBuyCount);
         ExecuteRealEntry(OP_BUY); // リアルエントリー実行
         g_LastBuyNanpinTime = TimeCurrent();
      }
      else
      {
         Print("ゴーストBuyカウント=", g_GhostBuyCount, ", スキップレベル=", (int)NanpinSkipLevel, "のためまだリアルエントリーしません");
         g_LastBuyNanpinTime = TimeCurrent();
      }
   }
   else
   {
      g_GhostSellPositions[g_GhostSellCount] = newPosition;
      g_GhostSellCount++;
      CreateGhostEntryPoint(type, newPosition.price, newPosition.lots, newPosition.level);
      
      if(g_GhostSellCount >= (int)NanpinSkipLevel)
      {
         Print("ナンピンスキップレベル条件達成: Level=", NanpinSkipLevel, ", 現在のゴーストカウント=", g_GhostSellCount);
         ExecuteRealEntry(OP_SELL); // リアルエントリー実行
         g_LastSellNanpinTime = TimeCurrent();
      }
      else
      {
         Print("ゴーストSellカウント=", g_GhostSellCount, ", スキップレベル=", (int)NanpinSkipLevel, "のためまだリアルエントリーしません");
         g_LastSellNanpinTime = TimeCurrent();
      }
   }
   
   // ここでは表示用に1-indexedのレベルを使用（ユーザーには1始まりで表示）
   Print("ゴーストナンピン追加: ", type == OP_BUY ? "Buy" : "Sell", ", レベル: ", level + 1, ", 価格: ", DoubleToString(newPosition.price, 5));
   
   // グローバル変数に保存
   SaveGhostPositionsToGlobal();
   
   // 有効なゴーストのみ点線を表示するように再設定
   RecreateValidGhostLines();
}

//+------------------------------------------------------------------+
//| 全チャートオブジェクトの整理と再構築                             |
//+------------------------------------------------------------------+
void RebuildAllGhostObjects()
{
   Print("RebuildAllGhostObjects: すべてのゴーストオブジェクトを整理して再構築します");
   
   // 1. 古いオブジェクトをすべて削除
   DeleteAllGhostObjectsByType(OP_BUY);
   DeleteAllGhostObjectsByType(OP_SELL);
   
   // 2. ゴーストポジションの状態を確認
   int validBuy = CountValidGhosts(OP_BUY);
   int validSell = CountValidGhosts(OP_SELL);
   
   Print("有効なゴーストポジション - Buy: ", validBuy, ", Sell: ", validSell);
   
   // 3. ゴーストエントリーポイントを再作成
   RecreateGhostEntryPoints();
   
   // 4. 平均価格ラインを更新
   if(AveragePriceLine == ON_MODE && g_AvgPriceVisible)
   {
      UpdateAveragePriceLines(0); // Buy側
      UpdateAveragePriceLines(1); // Sell側
   }
   
   // 5. チャートを再描画
   ChartRedraw();
}

//+------------------------------------------------------------------+
//| タイマーイベントで定期的に実行する関数                           |
//+------------------------------------------------------------------+
void CleanupAndRebuildGhostObjects()
{
   // この関数はOnTimerイベントで呼び出すことができます
   // 定期的なゴーストオブジェクトの整理と再構築

   // カウンターの一貫性をチェック
   int buyCount = 0;
   int sellCount = 0;
   
   for(int i = 0; i < ArraySize(g_GhostBuyPositions); i++)
   {
      if(g_GhostBuyPositions[i].isGhost)
         buyCount++;
   }
   
   for(int i = 0; i < ArraySize(g_GhostSellPositions); i++)
   {
      if(g_GhostSellPositions[i].isGhost)
         sellCount++;
   }
   
   bool needsFixing = false;
   
   // カウンターと実際のゴーストポジション数が一致しない場合
   if(buyCount != g_GhostBuyCount || sellCount != g_GhostSellCount)
   {
      Print("警告: ゴーストカウンターの不一致を検出 - 内部Buy: ", buyCount, ", カウンター: ", g_GhostBuyCount, 
            ", 内部Sell: ", sellCount, ", カウンター: ", g_GhostSellCount);
      
      // カウンターを修正
      g_GhostBuyCount = buyCount;
      g_GhostSellCount = sellCount;
      
      needsFixing = true;
   }
   
   // オブジェクトの数を確認
   int ghostLineCount = 0;
   int validLineCount = 0;
   
   for(int i = ObjectsTotal() - 1; i >= 0; i--)
   {
      string name = ObjectName(i);
      if(StringFind(name, g_ObjectPrefix) == 0 && StringFind(name, "GhostLine_") >= 0)
      {
         ghostLineCount++;
         
         // 対応するゴーストポジションが有効かをチェック
         bool validLine = false;
         
         if(StringFind(name, "_0_") >= 0) // Buy
         {
            for(int j = 0; j < g_GhostBuyCount; j++)
            {
               if(g_GhostBuyPositions[j].isGhost)
               {
                  // 価格が一致するかチェック
                  double linePrice = ObjectGet(name, OBJPROP_PRICE1);
                  if(MathAbs(linePrice - g_GhostBuyPositions[j].price) < 0.00001)
                  {
                     validLine = true;
                     break;
                  }
               }
            }
         }
         else if(StringFind(name, "_1_") >= 0) // Sell
         {
            for(int j = 0; j < g_GhostSellCount; j++)
            {
               if(g_GhostSellPositions[j].isGhost)
               {
                  // 価格が一致するかチェック
                  double linePrice = ObjectGet(name, OBJPROP_PRICE1);
                  if(MathAbs(linePrice - g_GhostSellPositions[j].price) < 0.00001)
                  {
                     validLine = true;
                     break;
                  }
               }
            }
         }
         
         if(validLine)
            validLineCount++;
         else
            needsFixing = true;
      }
   }
   
   // 有効なゴーストポジション数と有効な線の数が一致しない場合
   if(validLineCount != buyCount + sellCount)
   {
      Print("警告: 有効なゴースト線の数が一致しません - 有効なゴースト: ", buyCount + sellCount, 
            ", 有効な線: ", validLineCount, ", 全線: ", ghostLineCount);
      needsFixing = true;
   }
   
   // 修正が必要な場合
   if(needsFixing)
   {
      Print("ゴーストオブジェクトの不整合を検出したため、すべて再構築します");
      RebuildAllGhostObjects();
   }
}