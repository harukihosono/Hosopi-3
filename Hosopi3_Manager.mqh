//+------------------------------------------------------------------+
//|              Hosopi 3 - メイン管理用関数                           |
//|                       Copyright 2025                             |
//+------------------------------------------------------------------+
#include "Hosopi3_Defines.mqh"
#include "Hosopi3_Trading.mqh"
#include "Hosopi3_Utils.mqh"
#include "Hosopi3_GUI.mqh"
#include "Hosopi3_Table.mqh"
#include "Hosopi3_Ghost.mqh"

//+------------------------------------------------------------------+
//| Expert initialization function - バックテスト用修正                |
//+------------------------------------------------------------------+
int InitializeEA()
{
   // アカウント番号を取得して保存
   g_AccountNumber = AccountNumber();
   
   // グローバル変数のプレフィックスを設定（通貨ペア＋マジックナンバー＋アカウント番号）
   g_GlobalVarPrefix = Symbol() + "_" + IntegerToString(MagicNumber) + "_" + IntegerToString(g_AccountNumber) + "_Ghost_";
   
   // オブジェクト名のプレフィックスを設定
   g_ObjectPrefix = IntegerToString(MagicNumber) + "_" + IntegerToString(g_AccountNumber) + "_";
   
   // ロットテーブルの初期化
   InitializeLotTable();
   
   // ナンピン幅テーブルの初期化
   InitializeNanpinSpreadTable();
   
   // 決済済みフラグをリセット
   ResetGhostClosedFlags();

   // バックテスト時はゴーストポジションをリセット
   if(IsTesting())
   {
      Print("バックテスト検出: ゴーストポジションをリセットします");
      ResetGhost(OP_BUY);
      ResetGhost(OP_SELL);
      ClearGhostPositionsFromGlobal();
   }

   // ナンピンスキップレベルに基づいてゴーストモードを設定
   if(NanpinSkipLevel == SKIP_NONE) {
      g_GhostMode = false; // ゴーストモード無効
      Print("ナンピンスキップレベルがSKIP_NONEのため、ゴーストモードを無効化しました");
   } else {
      g_GhostMode = true; // ゴーストモード有効
   }
   
   // ロットテーブルの内容をログに出力
   string lotTableStr = "LOTテーブル: ";
   for(int i = 0; i < MathMin(10, ArraySize(g_LotTable)); i++)
   {
      lotTableStr += DoubleToString(g_LotTable[i], 2) + ", ";
   }
   Print(lotTableStr);
   
   // リアルポジションがある場合のチェック（複数チャート対策）
   int buyPositions = position_count(OP_BUY);
   int sellPositions = position_count(OP_SELL);
   
   if(buyPositions > 0 || sellPositions > 0) {
      Print("既にリアルポジションが存在します - Buy: ", buyPositions, ", Sell: ", sellPositions);
      
      // 既存のゴーストポジションをクリア
      ClearGhostPositionsFromGlobal();
      ResetGhost(OP_BUY);
      ResetGhost(OP_SELL);
      
      // 平均取得価格ラインは表示
      if(AveragePriceLine == ON_MODE) {
         g_AvgPriceVisible = true;
      }
   } else {
      // バックテストでなければグローバル変数からゴーストポジション情報を読み込み
      if(!IsTesting())
      {
         bool loadResult = LoadGhostPositionsFromGlobal();
         if(!loadResult)
         {
            Print("グローバル変数にゴーストポジション情報がないため、新規初期化します");
         }
         else
         {
            // ゴーストエントリーポイントを再表示
            RecreateGhostEntryPoints();
            
            // 有効なゴーストのみ点線を表示
            RecreateValidGhostLines();
         }
      }
   }
// OnInit関数内で追加
g_EnableNanpin = EnableNanpin;
g_EnableGhostEntry = EnableGhostEntry;
g_EnableIndicatorsEntry = EnableIndicatorsEntry;
g_EnableTimeEntry = EnableTimeEntry;
g_EnableFixedTP = EnableFixedTP;
g_EnableIndicatorsTP = EnableIndicatorsTP;
g_EnableTrailingStop = EnableTrailingStop;
g_AutoTrading = EnableAutomaticTrading;
   // GUIを作成
   CreateGUI();
   
   // ポジションテーブルを作成
   CreatePositionTable();
   
   // ゴーストモード初期状態のログ出力
   Print("ゴーストモード: ", g_GhostMode ? "ON" : "OFF");
   
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function - バックテスト用修正             |
//+------------------------------------------------------------------+
void DeinitializeEA(const int reason)
{
   // バックテスト時はゴーストポジションをリセット
   if(IsTesting())
   {
      Print("バックテスト終了: ゴーストポジションをリセットします");
      ResetGhost(OP_BUY);
      ResetGhost(OP_SELL);
      ClearGhostPositionsFromGlobal();
   }
   // チャートの時間足変更などの場合はゴーストポジション情報を保存
   else if(reason == REASON_CHARTCHANGE || reason == REASON_PARAMETERS || reason == REASON_RECOMPILE)
   {
      SaveGhostPositionsToGlobal();
      Print("チャート時間足変更・再コンパイルのためゴーストポジション情報を保存しました");
   }
   
   // GUIを削除
   DeleteGUI();
   
   // テーブルを削除
   DeletePositionTable();
   
   // ラインを削除
   DeleteAllLines();
   
   // エントリーポイントを削除
   DeleteAllEntryPoints();
   
   // 全てのゴーストオブジェクトの削除を追加
   DeleteAllGhostObjectsByType(OP_BUY);
   DeleteAllGhostObjectsByType(OP_SELL);
   
   // 最後に明示的にすべてのゴースト関連オブジェクトを検索して削除 (追加)
   for(int i = ObjectsTotal() - 1; i >= 0; i--)
   {
      string name = ObjectName(i);
      if(StringFind(name, g_ObjectPrefix) == 0 && StringFind(name, "Ghost") >= 0)
      {
         ObjectDelete(name);
      }
   }
   
   // チャートを再描画
   ChartRedraw();
}

//+------------------------------------------------------------------+
//| チャートイベント関数                                               |
//+------------------------------------------------------------------+
void HandleChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
{
   // ボタンクリックイベント
   if(id == CHARTEVENT_OBJECT_CLICK)
   {
      ProcessButtonClick(sparam);
   }
}



//+------------------------------------------------------------------+
//| ゴーストポジションの初期化（修正版）                              |
//+------------------------------------------------------------------+
void InitializeGhostPosition(int type)
{
   // リアルポジションがある場合は処理をスキップ（複数チャート対策）
   if(position_count(OP_BUY) > 0 || position_count(OP_SELL) > 0) {
      Print("リアルポジションが存在するため、ゴーストポジション初期化をスキップします");
      return;
   }

   // ナンピンスキップレベルがSKIP_NONEの場合は、ゴーストポジションを発動させない
   if(NanpinSkipLevel == SKIP_NONE)
   {
      Print("ナンピンスキップレベルがSKIP_NONEのため、ゴーストポジションは発動しません。直接リアルエントリーします。");
      // 直接リアルエントリーを実行
      ExecuteRealEntry(type);
      return;
   }
   
   // ゴーストポジションの最大数はナンピンスキップレベルの値までに制限
   int maxGhostPositions = (int)NanpinSkipLevel;
   int currentGhostCount = ghost_position_count(type);
   
   // 既にゴーストポジション数が最大数に達している場合
   if(currentGhostCount >= maxGhostPositions)
   {
      Print("ゴーストポジション数が最大数(", maxGhostPositions, ")に達しているため、新規ゴーストエントリーをスキップします");
      return;
   }
   
   // スプレッドチェック
   double spreadPoints = (GetAskPrice() - GetBidPrice()) / Point;
   if(spreadPoints > MaxSpreadPoints && MaxSpreadPoints > 0)
   {
      Print("スプレッドが大きすぎるため、ゴーストエントリーをスキップします: ", spreadPoints, " > ", MaxSpreadPoints);
      return;
   }
      
   // ポジション情報の作成 - 重要：level は 0 から開始（配列インデックス）
   PositionInfo newPosition;
   newPosition.type = type;
   newPosition.lots = g_LotTable[0];  // 最初のポジションは g_LotTable[0]
   newPosition.symbol = Symbol();
   newPosition.price = (type == OP_BUY) ? GetAskPrice() : GetBidPrice();
   newPosition.profit = 0;
   newPosition.ticket = 0; // ゴーストはチケット番号なし
   newPosition.openTime = TimeCurrent();
   newPosition.isGhost = true;
   newPosition.level = 0;  // 最初のポジションはレベル0
   
   if(type == OP_BUY)
   {
      // Buyゴーストポジションの追加
      g_GhostBuyPositions[g_GhostBuyCount] = newPosition;
      g_GhostBuyCount++;
      
      // ナンピン時間を初期化
      g_LastBuyNanpinTime = TimeCurrent();
      
      // エントリーポイントを表示
      CreateGhostEntryPoint(type, newPosition.price, newPosition.lots, newPosition.level);
      
      // 決済済みフラグをリセット
      g_BuyGhostClosed = false;
      
      // ナンピンスキップレベルに達したらリアルエントリー
      if(g_GhostBuyCount >= (int)NanpinSkipLevel)
      {
         Print("初回エントリーでナンピンスキップレベル条件達成: Level=", NanpinSkipLevel, ", ゴーストカウント=", g_GhostBuyCount);

         ExecuteRealEntry(OP_BUY); // リアルエントリー実行
      }
      else
      {
         Print("初回エントリー: ゴーストBuyカウント=", g_GhostBuyCount, ", スキップレベル=", (int)NanpinSkipLevel, "のためまだリアルエントリーしません");
      }
   }
   else
   {
      // Sellゴーストポジションの追加
      g_GhostSellPositions[g_GhostSellCount] = newPosition;
      g_GhostSellCount++;
      
      // ナンピン時間を初期化
      g_LastSellNanpinTime = TimeCurrent();
      
      // エントリーポイントを表示
      CreateGhostEntryPoint(type, newPosition.price, newPosition.lots, newPosition.level);
      
      // 決済済みフラグをリセット
      g_SellGhostClosed = false;
      
      // ナンピンスキップレベルに達したらリアルエントリー
      if(g_GhostSellCount >= (int)NanpinSkipLevel)
      {
         Print("初回エントリーでナンピンスキップレベル条件達成: Level=", NanpinSkipLevel, ", ゴーストカウント=", g_GhostSellCount);
         ExecuteRealEntry(OP_SELL);
      }
      else
      {
         Print("初回エントリー: ゴーストSellカウント=", g_GhostSellCount, ", スキップレベル=", (int)NanpinSkipLevel, "のためまだリアルエントリーしません");
      }
   }
   
   // ユーザー表示用にはレベル+1を表示（1-indexed）
   Print("ゴーストポジション作成: ", type == OP_BUY ? "Buy" : "Sell", ", レベル: 1, 価格: ", DoubleToString(newPosition.price, 5));
   
   // グローバル変数へ保存
   SaveGhostPositionsToGlobal();
   
   // 有効なゴーストのみ点線を表示するように再設定
   RecreateValidGhostLines();
}

//+------------------------------------------------------------------+
//| 実際のエントリー処理 - リアルエントリー時のロット選択ロジックを修正 |
//+------------------------------------------------------------------+
void ExecuteRealEntry(int type)
{
   if(!g_AutoTrading)
   {
      Print("自動売買が無効のため、リアルエントリーはスキップされました");
      return;
   }
      
   if((GetAskPrice() - GetBidPrice()) / Point > MaxSpreadPoints && MaxSpreadPoints > 0)
   {
      Print("スプレッドが大きすぎるため、リアルエントリーはスキップされました: ", (GetAskPrice() - GetBidPrice()) / Point, " > ", MaxSpreadPoints);
      return;
   }
      
   int existingCount = position_count(type);
   if(existingCount > 0)
   {
      Print("既にリアルポジションが存在するため、リアルエントリーはスキップされました: ", existingCount, "ポジション");
      return;
   }
   
   // ゴーストポジション数を取得
   int ghostCount = ghost_position_count(type);
   
   Print("ExecuteRealEntry呼び出し: 方向=", type == OP_BUY ? "Buy" : "Sell", 
         ", ゴーストカウント=", ghostCount, 
         ", スキップレベル=", (int)NanpinSkipLevel);
   
   // ===== ロットサイズの選択ロジックを修正 =====
   double lots;
   
   // ナンピンスキップレベルを使用して常に一貫したロットを使う
   if(NanpinSkipLevel == SKIP_NONE) {
      // スキップなしの場合は最初のロット
      lots = g_LotTable[0];
      Print("スキップなしのため初期ロット使用: ロット=", DoubleToString(lots, 2));
   } else {
      // スキップレベルに合わせたロットを使用
      // NanpinSkipLevelは1から始まるため、配列インデックスに変換
      int levelIndex = (int)NanpinSkipLevel - 1;
      
      // 配列の範囲を超えないように制御
      if(levelIndex >= 0 && levelIndex < ArraySize(g_LotTable)) {
         lots = g_LotTable[levelIndex];
      } else {
         // 範囲外の場合は初期ロットを使用
         lots = g_LotTable[0];
         Print("警告: スキップレベルが範囲外のため初期ロット使用");
      }
      
      Print("スキップレベルに基づくロット選択: レベル=", NanpinSkipLevel, 
            ", インデックス=", levelIndex, ", ロット=", DoubleToString(lots, 2));
   }
   
   Print("リアルエントリー実行: ", type == OP_BUY ? "Buy" : "Sell", 
         ", ロット=", DoubleToString(lots, 2), 
         " (ゴーストレベル: ", ghostCount, ")");
   
   // MQL4/MQL5互換のposition_entry関数を使用
   bool result = position_entry(type, lots, Slippage, MagicNumber, "Hosopi 3 EA");
   
   if(result)
   {
      Print("リアル", type == OP_BUY ? "Buy" : "Sell", "エントリー成功: ロット=", 
            DoubleToString(lots, 2), ", 価格=", 
            DoubleToString(type == OP_BUY ? GetAskPrice() : GetBidPrice(), 5));
      
      // 重要な変更: 反対側のゴーストが存在する場合、それは保持する
      int oppositeType = (type == OP_BUY) ? OP_SELL : OP_BUY;
      int oppositeGhostCount = ghost_position_count(oppositeType);
      
      if(oppositeGhostCount > 0) {
         Print("反対側(", oppositeType == OP_BUY ? "Buy" : "Sell", ")にゴーストポジションが", 
               oppositeGhostCount, "個あるため、そちらは保持します");
               
         // 現在のタイプのゴーストのみリセット
         ResetSpecificGhost(type);
      } else {
         // 反対側にゴーストがない場合は通常通りリセット
         ResetGhost(type);
      }
   }
   else
   {
      Print("リアル", type == OP_BUY ? "Buy" : "Sell", "エントリーエラー: ", GetLastError());
   }
}
//+------------------------------------------------------------------+
//| ナンピン条件のチェック（修正版）                                  |
//+------------------------------------------------------------------+
void CheckNanpinConditions(int side)
{
   // 処理対象のオペレーションタイプを決定
   int operationType = (side == 0) ? OP_BUY : OP_SELL;
   
   // ポジションカウントを取得
   int positionCount = position_count(operationType);
   
   // ポジションがないか最大数に達している場合はスキップ
   if(positionCount <= 0 || positionCount >= (int)MaxPositions)
      return;
   
   // 最後のナンピン時間を取得
   datetime lastNanpinTime = (side == 0) ? g_LastBuyNanpinTime : g_LastSellNanpinTime;
   
   // 最後のナンピン時間からのインターバルチェック
   if(TimeCurrent() - lastNanpinTime < NanpinInterval * 60)
   {
      // デバッグログの追加（1分に1回のみ出力）
      static datetime lastIntervalDebugTime = 0;
      if(TimeCurrent() - lastIntervalDebugTime > 60)
      {
         Print("リアルナンピンインターバルが経過していません: ", 
              (TimeCurrent() - lastNanpinTime) / 60, "分 / ", 
              NanpinInterval, "分");
         lastIntervalDebugTime = TimeCurrent();
      }
      return;
   }
   
   // 最後のポジション価格を取得
   double lastPrice = GetLastPositionPrice(operationType);
   if(lastPrice <= 0)
   {
      Print("最後のポジション価格が取得できません。ナンピン条件チェックをスキップします。");
      return;
   }
   
   // 現在の価格を取得（BuyならBid、SellならAsk）
   double currentPrice = (side == 0) ? GetBidPrice() : GetAskPrice();
   
   // 現在のレベルに対応するナンピン幅を取得
   // positionCountは1から始まるので、配列インデックスに変換するために1を引く
   int nanpinSpread = g_NanpinSpreadTable[positionCount - 1];
   
   // 方向に基づいた価格差を計算
   double priceDifference = (side == 0) ? 
                           (lastPrice - currentPrice) / Point : 
                           (currentPrice - lastPrice) / Point;
   
   // デバッグ出力
   string direction = (side == 0) ? "Buy" : "Sell";
   Print(direction, " リアルナンピン条件チェック: 現在価格=", currentPrice, 
         ", 前回価格=", lastPrice, 
         ", ナンピン幅=", nanpinSpread, 
         " ポイント, 差=", priceDifference);
   
   // ナンピン条件の判定
   bool nanpinCondition = false;
   
   if(side == 0) // Buy
      nanpinCondition = (currentPrice < lastPrice - nanpinSpread * Point);
   else // Sell
      nanpinCondition = (currentPrice > lastPrice + nanpinSpread * Point);
   
   // ナンピン条件が満たされた場合
   if(nanpinCondition)
   {
      Print(direction, " リアルナンピン条件成立、実行を開始します");
      ExecuteRealNanpin(operationType);
      
      // ナンピン時間を更新
      if(side == 0)
         g_LastBuyNanpinTime = TimeCurrent();
      else
         g_LastSellNanpinTime = TimeCurrent();
   }
}

//+------------------------------------------------------------------+
//| リアルナンピンの実行 - 最後のリアルポジションのロットサイズを基に計算 |
//+------------------------------------------------------------------+
void ExecuteRealNanpin(int type)
{
   // 自動売買が無効の場合は何もしない
   if(!g_AutoTrading)
   {
      Print("自動売買が無効のため、リアルナンピンはスキップされました");
      return;
   }
   
   // スプレッドチェック
   if((GetAskPrice() - GetBidPrice()) / Point > MaxSpreadPoints && MaxSpreadPoints > 0)
   {
      Print("スプレッドが大きすぎるため、リアルナンピンはスキップされました: ", (GetAskPrice() - GetBidPrice()) / Point, " > ", MaxSpreadPoints);
      return;
   }
   
   // 現在のポジション数を確認
   int positionCount = position_count(type);
   if(positionCount <= 0)
   {
      Print("リアルポジションが存在しないため、リアルナンピンはスキップされました");
      return;
   }
   
   if(positionCount >= (int)MaxPositions)
   {
      Print("すでに最大ポジション数に達しているため、リアルナンピンはスキップされました");
      return;
   }
   
   // エントリー方向が許可されているかチェック
   if(!IsEntryAllowed(type == OP_BUY ? 0 : 1))
   {
      Print("エントリー方向が許可されていないため、リアルナンピンはスキップされました");
      return;
   }
   
   // エントリー時間が許可されているかチェック
   if(!IsTimeAllowed(type))
   {
      Print("エントリー時間が許可されていないため、リアルナンピンはスキップされました");
      return;
   }
   
   // ===== ロット選択ロジックの修正 =====
   // 最後のリアルポジションのロットサイズを取得
   double lastLotSize = 0;
   datetime lastOpenTime = 0;
   
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
      {
         if(OrderType() == type && OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumber)
         {
            // 最新のポジションを探す
            if(OrderOpenTime() > lastOpenTime)
            {
               lastOpenTime = OrderOpenTime();
               lastLotSize = OrderLots();
            }
         }
      }
   }
   
   // ロットサイズが取得できなかった場合（通常ありえない）
   if(lastLotSize <= 0)
   {
      Print("警告: 最後のポジションのロットサイズを取得できませんでした。デフォルトロットを使用します。");
      lastLotSize = g_LotTable[0];
   }
   
   // 次のナンピンロットを計算
   double lots = lastLotSize * LotMultiplier;
   
   // 小数点以下3桁で切り上げ（ロットテーブルと同様の計算）
   lots = MathCeil(lots * 1000) / 1000;
   
   // ロットサイズのログ出力
   Print("リアルナンピン実行: ", type == OP_BUY ? "Buy" : "Sell", 
         ", ベースロット=", DoubleToString(lastLotSize, 2),
         ", 倍率=", DoubleToString(LotMultiplier, 2),
         ", 次のロット=", DoubleToString(lots, 2));
   
   // MQL4/MQL5互換のposition_entry関数を使用
   bool result = position_entry(type, lots, Slippage, MagicNumber, "Hosopi 3 EA Nanpin");
   
   if(result)
   {
      Print("リアル", type == OP_BUY ? "Buy" : "Sell", "ナンピン成功: ", 
            "ロット=", DoubleToString(lots, 2), ", 価格=", 
            DoubleToString(type == OP_BUY ? GetAskPrice() : GetBidPrice(), 5));
   }
   else
   {
      Print("リアル", type == OP_BUY ? "Buy" : "Sell", "ナンピンエラー: ", GetLastError());
   }
}

//+------------------------------------------------------------------+
//| リアルエントリー用のGetLastPositionLot関数を追加                 |
//+------------------------------------------------------------------+
double GetLastPositionLot(int type)
{
   double lastLotSize = 0;
   datetime lastOpenTime = 0;
   
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
      {
         if(OrderType() == type && OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumber)
         {
            // 最新のポジションを探す
            if(OrderOpenTime() > lastOpenTime)
            {
               lastOpenTime = OrderOpenTime();
               lastLotSize = OrderLots();
            }
         }
      }
   }
   
   return lastLotSize;
}
//+------------------------------------------------------------------+
//| リアルエントリーの処理（ゴーストなしの場合）                      |
//+------------------------------------------------------------------+
void ProcessRealEntries(int side)
{
   // リアルポジションがある場合はスキップ
   if(position_count(OP_BUY) > 0 || position_count(OP_SELL) > 0) {
      return;
   }

   // 処理対象のオペレーションタイプを決定
   int operationType = (side == 0) ? OP_BUY : OP_SELL;

   // エントリーモードに基づくチェック
   bool modeAllowed = false;
   if(side == 0) // Buy
      modeAllowed = (EntryMode == MODE_BUY_ONLY || EntryMode == MODE_BOTH);
   else // Sell
      modeAllowed = (EntryMode == MODE_SELL_ONLY || EntryMode == MODE_BOTH);

   if(!modeAllowed)
      return;

   // リアルポジションがない場合は新規エントリー
   if(position_count(operationType) == 0)
   {
      string direction = (side == 0) ? "Buy" : "Sell";
      
      // スプレッドチェック
      if((GetAskPrice() - GetBidPrice()) / Point <= MaxSpreadPoints || MaxSpreadPoints <= 0)
      {
         // 直接リアルエントリーを実行
         bool result = position_entry(operationType, g_LotTable[0], Slippage, MagicNumber, "Hosopi 3 EA Direct");
         
         if(result)
         {
            Print("リアル", direction, "エントリー成功: ロット=", 
                  DoubleToString(g_LotTable[0], 2), ", 価格=", 
                  DoubleToString((side == 0) ? GetAskPrice() : GetBidPrice(), 5));
            
            // ナンピン時間を更新
            if(side == 0)
               g_LastBuyNanpinTime = TimeCurrent();
            else
               g_LastSellNanpinTime = TimeCurrent();
         }
         else
         {
            Print("リアル", direction, "エントリーエラー: ", GetLastError());
         }
      }
      else
      {
         Print("スプレッドが大きすぎるため、リアル", direction, "エントリーをスキップしました: ", 
               (GetAskPrice() - GetBidPrice()) / Point, " > ", MaxSpreadPoints);
      }
   }
}
//+------------------------------------------------------------------+
//| OnTick関数に定期フラグチェック機能を追加 - 戦略統合版            |
//+------------------------------------------------------------------+
void OnTickManager()
{
   // 一定間隔でテーブルを更新
   if(TimeCurrent() >= g_LastUpdateTime + UpdateInterval)
   {
      UpdatePositionTable();
      g_LastUpdateTime = TimeCurrent();
      
      // 定期的にゴーストポジション情報を保存 (1分ごと)
      static datetime lastSaveTime = 0;
      if(TimeCurrent() - lastSaveTime > 60)
      {
         SaveGhostPositionsToGlobal();
         lastSaveTime = TimeCurrent();
      }
      
      // 定期的にゴーストオブジェクトの整合性チェックと再構築 (5分ごと)
      static datetime lastCheckTime = 0;
      if(TimeCurrent() - lastCheckTime > 300)
      {
         CleanupAndRebuildGhostObjects();
         
         // リアルポジションとゴーストポジションがどちらもない場合は決済済みフラグをリセット
         if(position_count(OP_BUY) == 0 && position_count(OP_SELL) == 0 &&
            g_GhostBuyCount == 0 && g_GhostSellCount == 0)
         {
            if(g_BuyGhostClosed || g_SellGhostClosed)
            {
               Print("チェック時: ポジションが存在しないため決済済みフラグをリセットします");
               g_BuyGhostClosed = false;
               g_SellGhostClosed = false;
               SaveGhostPositionsToGlobal();
            }
         }
         
         lastCheckTime = TimeCurrent();
      }
      
      // OnTimerの機能も呼び出し
      OnTimerHandler();
   }

   // 戦略ロジックを処理
   ProcessStrategyLogic();

   // GUIを更新
   UpdateGUI();

   // 平均取得価格ラインの表示更新
   if(AveragePriceLine == ON_MODE && g_AvgPriceVisible)
   {
      UpdateAveragePriceLines(0); // Buy側
      UpdateAveragePriceLines(1); // Sell側
   }
   else
   {
      DeleteAllLines();
   }
}