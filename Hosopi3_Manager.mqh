//+------------------------------------------------------------------+
//|              Hosopi 3 - メイン管理用関数 (MQL4/MQL5共通)          |
//|                       Copyright 2025                             |
//+------------------------------------------------------------------+
#include "Hosopi3_Defines.mqh"
#include "Hosopi3_Trading.mqh"
#include "Hosopi3_Utils.mqh"
#include "Hosopi3_GUI.mqh"
#include "Hosopi3_Table.mqh"
#include "Hosopi3_Ghost.mqh"
#include "Hosopi3_TakeProfit.mqh"
#include "Hosopi3_Notification.mqh"

//+------------------------------------------------------------------+
//| エントリー原因を記録するためのヘルパー関数                        |
//+------------------------------------------------------------------+
void LogEntryReason(int type, string entryMethod, string reason)
{
   string typeStr = (type == OP_BUY) ? "Buy" : "Sell";
   string timestamp = TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS);
   
   // エントリーログフォーマット：[時間] [タイプ] [メソッド] [理由]
   string logMessage = StringFormat("[%s] %s エントリー: メソッド=%s, 理由=%s, 価格=%s", 
                      timestamp, typeStr, entryMethod, reason, 
                      DoubleToString(type == OP_BUY ? GetAskPrice() : GetBidPrice(), Digits));
   
   // ログを出力
   Print(logMessage);
   
   // 履歴ファイルにも保存（オプション）
   SaveEntryLogToFile(logMessage);
}

//+------------------------------------------------------------------+
//| ログを履歴ファイルに保存する                                     |
//+------------------------------------------------------------------+
void SaveEntryLogToFile(string logMessage)
{
   // ログファイル名を生成（EA名+シンボル+日付）
   string fileName = "Hosopi3_EntryLog_" + Symbol() + "_" + 
                    TimeToString(TimeCurrent(), TIME_DATE) + ".log";
   
   // ファイルオープン（追加モード）
   int fileHandle = FileOpen(fileName, FILE_WRITE|FILE_READ|FILE_TXT);
   
   if(fileHandle != INVALID_HANDLE)
   {
      // ファイルの最後に移動
      FileSeek(fileHandle, 0, SEEK_END);
      
      // ログを書き込み
      FileWriteString(fileHandle, logMessage + "\n");
      
      // ファイルを閉じる
      FileClose(fileHandle);
   }
   else
   {
      Print("ログファイルのオープンに失敗しました: ", GetLastError());
   }
}

//+------------------------------------------------------------------+
//| ExecuteRealEntry関数 (MQL4/MQL5共通)                             |
//+------------------------------------------------------------------+
void ExecuteRealEntry(int type, string entryReason)
{
   if(!EnableAutomaticTrading)
   {
      Print("自動売買が無効のため、リアルエントリーはスキップされました");
      return;
   }
      
   if((GetAskPrice() - GetBidPrice()) / Point > MaxSpreadPoints && MaxSpreadPoints > 0)
   {
      Print("スプレッドが大きすぎるため、リアルエントリーはスキップされました: ", 
            (GetAskPrice() - GetBidPrice()) / Point, " > ", MaxSpreadPoints);
      return;
   }
      
   int existingCount = position_count(type);
   if(existingCount > 0)
   {
      Print("既にリアルポジションが存在するため、リアルエントリーはスキップされました: ", 
            existingCount, "ポジション");
      return;
   }
   
   // 合計ポジション数（ゴースト+リアル）を取得
   int totalPositionCount = combined_position_count(type);
   
   // 初回エントリーの場合のみ時間チェック
   if(totalPositionCount == 0)
   {
      // 手動操作以外の時は、時間制限チェックを行う
      if(StringFind(entryReason, "手動") < 0 && !IsInitialEntryTimeAllowed(type))
      {
         Print("ExecuteRealEntry: 初回エントリー時間制限により", 
               type == OP_BUY ? "Buy" : "Sell", "側はスキップします");
         return;
      }
   }
   
   // エントリー理由が指定されていない場合は自動生成
   if(entryReason == "")
   {
      if(totalPositionCount > 0)
      {
         entryReason = "ナンピン発動 (合計ポジション数=" + IntegerToString(totalPositionCount) + ")";
      }
      else
      {
         entryReason = "通常エントリー";
      }
   }
   
   Print("ExecuteRealEntry呼び出し: 方向=", type == OP_BUY ? "Buy" : "Sell", 
         ", 合計ポジション数=", totalPositionCount);
   
   // ロットサイズの選択
   double lots = DetermineLotSize(type, totalPositionCount);
   
   Print("リアルエントリー実行: ", type == OP_BUY ? "Buy" : "Sell", 
         ", ロット=", DoubleToString(lots, 2));
   
   // エントリー理由をログに記録
   LogEntryReason(type, "自動エントリー", entryReason);
   
   // MQL4/MQL5互換のposition_entry関数を使用
   bool result = position_entry(type, lots, Slippage, MagicNumber, "Hosopi 3 EA");
   if(result)
   {
      Print("リアル", type == OP_BUY ? "Buy" : "Sell", "エントリー成功: ロット=", 
            DoubleToString(lots, 2), ", 価格=", 
            DoubleToString(type == OP_BUY ? GetAskPrice() : GetBidPrice(), 5));
      
      // ゴーストポジションは維持
      Print("リアルエントリー後もゴーストポジションは維持します");
      
      // エントリー通知
      NotifyRealEntry(type, lots, type == OP_BUY ? GetAskPrice() : GetBidPrice(), entryReason);
   }
   else
   {
      Print("リアル", type == OP_BUY ? "Buy" : "Sell", "エントリーエラー: ", GetLastError());
      NotifyError("リアルエントリー", GetLastError());
   }
}

//+------------------------------------------------------------------+
//| ロットサイズを決定 (MQL4/MQL5共通)                               |
//+------------------------------------------------------------------+
double DetermineLotSize(int type, int totalPositionCount)
{
   double lots;
   
   // UseInitialLotForRealEntryがONの場合は常に初期ロットを使用
   if(UseInitialLotForRealEntry)
   {
      lots = g_LotTable[0]; // 常に最初のロットを使用
      Print("初期ロット設定有効: 初期ロット", DoubleToString(lots, 2), "を使用");
   }
   // 合計ポジション数が0の場合も初期ロットを使用
   else if(totalPositionCount == 0)
   {
      lots = g_LotTable[0]; // 常に最初のロットを使用
      Print("初回エントリー: 初期ロット", DoubleToString(lots, 2), "を使用");
   }
   // 既存のポジションがある場合は最後のポジションのロットを参照
   else
   {
      // 最後のポジションのロットサイズを取得
      double lastLotSize = GetLastCombinedPositionLot(type);
      
      if(IndividualLotEnabled == ON_MODE)
      {
         // 個別指定モードの場合
         int lotIndex = totalPositionCount;
         
         // 配列の範囲をチェック
         if(lotIndex >= 0 && lotIndex < ArraySize(g_LotTable))
         {
            lots = g_LotTable[lotIndex];
            Print("個別指定ロットモード: 合計ポジション数", totalPositionCount + 1, 
                 "に対応するロット", DoubleToString(lots, 2), "を使用");
         }
         else
         {
            // 範囲外の場合は最後のロットを使用
            lots = g_LotTable[ArraySize(g_LotTable) - 1];
            Print("警告: 合計ポジション数が範囲外のため最大レベルのロット", 
                  DoubleToString(lots, 2), "を使用");
         }
      }
      else
      {
         // マーチンゲールモードの場合
         if(lastLotSize <= 0)
         {
            // 最後のロットサイズが取得できなかった場合
            lots = g_LotTable[0];
            Print("警告: 最後のポジションのロットサイズを取得できませんでした。初期ロット", 
                  DoubleToString(lots, 2), "を使用します");
         }
         else
         {
            // 0.01ロットの場合のみ、かつマーチン倍率が1.3より大きい場合のみ特別処理
            if(MathAbs(lastLotSize - 0.01) < 0.001 && LotMultiplier > 1.3)
            {
               lots = 0.02;
               Print("0.01ロット検出 + マーチン倍率>1.3: 次のロットを0.02に固定します");
            }
            else
            {
               // それ以外は通常のマーチンゲール計算
               lots = lastLotSize * LotMultiplier;
               lots = MathCeil(lots * 1000) / 1000; // 小数点以下3桁で切り上げ
               Print("通常マーチンゲール計算: ベースロット=", DoubleToString(lastLotSize, 3),
                   ", 倍率=", DoubleToString(LotMultiplier, 2),
                   ", 次のロット=", DoubleToString(lots, 3));
            }
         }
      }
   }
   
   return lots;
}

//+------------------------------------------------------------------+
//| ExecuteRealNanpin関数 (MQL4/MQL5共通)                            |
//+------------------------------------------------------------------+
void ExecuteRealNanpin(int typeOrder)
{
   // 自動売買が無効の場合は何もしない
   if(!EnableAutomaticTrading)
   {
      Print("自動売買が無効のため、リアルナンピンはスキップされました");
      return;
   }
   
   // スプレッドチェック
   if((GetAskPrice() - GetBidPrice()) / Point > MaxSpreadPoints && MaxSpreadPoints > 0)
   {
      Print("スプレッドが大きすぎるため、リアルナンピンはスキップされました: ", 
            (GetAskPrice() - GetBidPrice()) / Point, " > ", MaxSpreadPoints);
      return;
   }
   
   // 現在のポジション数を確認
   int posCount = position_count(typeOrder);
   if(posCount <= 0)
   {
      Print("リアルポジションが存在しないため、リアルナンピンはスキップされました");
      return;
   }
   
   if(posCount >= (int)MaxPositions)
   {
      Print("すでに最大ポジション数に達しているため、リアルナンピンはスキップされました");
      return;
   }
   
   // 合計ポジション数（ゴースト＋リアル）を取得
   int totalPositionCount = combined_position_count(typeOrder);
   
   // ロットサイズを決定
   double lotsToUse = DetermineLotSize(typeOrder, totalPositionCount);
   
   Print("リアルナンピン実行: タイプ=", typeOrder == OP_BUY ? "Buy" : "Sell",
         ", ロット=", DoubleToString(lotsToUse, 3));
   
   // MQL4/MQL5互換のposition_entry関数を使用
   bool entryResult = position_entry(typeOrder, lotsToUse, Slippage, MagicNumber, "Hosopi 3 EA Nanpin");
   
   if(entryResult)
   {
      Print("リアル", typeOrder == OP_BUY ? "Buy" : "Sell", "ナンピン成功: ", 
            "ロット=", DoubleToString(lotsToUse, 3), ", 価格=", 
            DoubleToString(typeOrder == OP_BUY ? GetAskPrice() : GetBidPrice(), 5));
            
      // ゴーストポジションは維持
      Print("リアルナンピン後もゴーストポジションは維持します");
      
      // ナンピン通知
      NotifyRealEntry(typeOrder, lotsToUse, typeOrder == OP_BUY ? GetAskPrice() : GetBidPrice(), 
                     "ナンピンエントリー (レベル " + IntegerToString(totalPositionCount + 1) + ")");
   }
   else
   {
      Print("リアル", typeOrder == OP_BUY ? "Buy" : "Sell", "ナンピンエラー: ", GetLastError());
      NotifyError("リアルナンピン", GetLastError());
   }
}

//+------------------------------------------------------------------+
//| ExecuteDiscretionaryEntry関数 (MQL4/MQL5共通)                    |
//+------------------------------------------------------------------+
void ExecuteDiscretionaryEntry(int typeOrder, double lotSize = 0)
{
   if(!EnableAutomaticTrading)
   {
      Print("自動売買が無効のため、裁量エントリーはスキップされました");
      return;
   }
      
   if((GetAskPrice() - GetBidPrice()) / Point > MaxSpreadPoints && MaxSpreadPoints > 0)
   {
      Print("スプレッドが大きすぎるため、裁量エントリーはスキップされました: ", 
            (GetAskPrice() - GetBidPrice()) / Point, " > ", MaxSpreadPoints);
      return;
   }
      
   int existingCount = position_count(typeOrder);
   if(existingCount > 0)
   {
      Print("既にリアルポジションが存在するため、裁量エントリーはスキップされました: ", 
            existingCount, "ポジション");
      return;
   }
   
   // 合計ポジション数（ゴースト+リアル）を取得
   int totalPositionCount = combined_position_count(typeOrder);
   
   double lotsToUse;
   
   if(lotSize > 0)
   {
      // 明示的に指定されたロットサイズを使用
      lotsToUse = lotSize;
   }
   else
   {
      // ロットサイズを決定
      lotsToUse = DetermineLotSize(typeOrder, totalPositionCount);
   }
   
   Print("裁量エントリー実行: ", typeOrder == OP_BUY ? "Buy" : "Sell", 
         ", ロット=", DoubleToString(lotsToUse, 2));
   
   // エントリー理由をログに記録
   LogEntryReason(typeOrder, "裁量エントリー", "手動ボタン操作によるエントリー");
   
   // MQL4/MQL5互換のposition_entry関数を使用
   bool entryResult = position_entry(typeOrder, lotsToUse, Slippage, MagicNumber, "Hosopi 3 EA Manual");
   
   if(entryResult)
   {
      Print("裁量", typeOrder == OP_BUY ? "Buy" : "Sell", "エントリー成功: ロット=", 
            DoubleToString(lotsToUse, 2), ", 価格=", 
            DoubleToString(typeOrder == OP_BUY ? GetAskPrice() : GetBidPrice(), 5));
      
      // ゴーストポジションは維持
      Print("裁量エントリー後もゴーストポジションは維持します");
      
      // エントリー通知
      NotifyRealEntry(typeOrder, lotsToUse, typeOrder == OP_BUY ? GetAskPrice() : GetBidPrice(), 
                     "手動エントリー");
   }
   else
   {
      Print("裁量", typeOrder == OP_BUY ? "Buy" : "Sell", "エントリーエラー: ", GetLastError());
      NotifyError("裁量エントリー", GetLastError());
   }
}

//+------------------------------------------------------------------+
//| ExecuteEntryFromLevel関数 (MQL4/MQL5共通)                        |
//+------------------------------------------------------------------+
void ExecuteEntryFromLevel(int type, int level)
{
   if(!EnableAutomaticTrading)
   {
      Print("自動売買が無効のため、レベル指定エントリーはスキップされました");
      return;
   }
      
   if((GetAskPrice() - GetBidPrice()) / Point > MaxSpreadPoints && MaxSpreadPoints > 0)
   {
      Print("スプレッドが大きすぎるため、レベル指定エントリーはスキップされました: ", 
            (GetAskPrice() - GetBidPrice()) / Point, " > ", MaxSpreadPoints);
      return;
   }
      
   int existingCount = position_count(type);
   if(existingCount > 0)
   {
      Print("既にリアルポジションが存在するため、レベル指定エントリーをスキップしました: ", 
            existingCount, "ポジション");
      return;
   }
   
   // 指定レベルが範囲内かチェック
   if(level < 1 || level > ArraySize(g_LotTable))
   {
      Print("指定レベルが範囲外のため、レベル指定エントリーはスキップされました: ", level);
      return;
   }
   
   // ロット選択を明確化 - レベルは1始まりだが配列は0始まりなので調整
   double lots = g_LotTable[level - 1];
   
   // ロット選択のログ出力を強化
   Print("レベル指定エントリー: レベル=", level, 
         ", インデックス=", level - 1,
         ", ロットサイズ=", DoubleToString(lots, 2),
         ", 個別指定モード=", IndividualLotEnabled == ON_MODE ? "有効" : "無効");
   
   Print("指定エントリー実行: ", type == OP_BUY ? "Buy" : "Sell", 
         ", ロット=", DoubleToString(lots, 2));
   
   // エントリー理由をログに記録
   LogEntryReason(type, "レベル指定エントリー", "手動選択: レベル" + IntegerToString(level));
   
   // MQL4/MQL5互換のposition_entry関数を使用
   bool result = position_entry(type, lots, Slippage, MagicNumber, 
                               "Hosopi 3 EA Level " + IntegerToString(level));
   
   if(result)
   {
      Print("レベル", level, "からの", type == OP_BUY ? "Buy" : "Sell", "エントリー成功: ロット=", 
            DoubleToString(lots, 2), ", 価格=", 
            DoubleToString(type == OP_BUY ? GetAskPrice() : GetBidPrice(), 5));
      
      // ゴーストポジションは維持
      Print("レベル指定エントリー後もゴーストポジションは維持します");
      
      // エントリー通知
      NotifyRealEntry(type, lots, type == OP_BUY ? GetAskPrice() : GetBidPrice(), 
                     "レベル指定エントリー (レベル " + IntegerToString(level) + ")");
   }
   else
   {
      Print("レベル", level, "からの", type == OP_BUY ? "Buy" : "Sell", "エントリーエラー: ", GetLastError());
      NotifyError("レベル指定エントリー", GetLastError());
   }
}

//+------------------------------------------------------------------+
//| OnTickManager関数 (MQL4/MQL5共通)                                |
//+------------------------------------------------------------------+
void OnTickManager()
{
   // バックテスト時の処理を最適化
   bool isTesting = IsTesting();
   
   // テーブル更新の処理
   if(TimeCurrent() >= g_LastUpdateTime + UpdateInterval)
   {
      // テーブル表示が有効な場合は更新
      if(EnablePositionTable)
      {
         UpdatePositionTable();
      }
      
      g_LastUpdateTime = TimeCurrent();
      
      // ポジションがない場合のライン削除チェック
      CheckAndDeleteLinesIfNoPositions();
      
      // 定期的にゴーストポジション情報を保存
      static datetime lastSaveTime = 0;
      int saveInterval = isTesting ? 300 : 60; // バックテスト時は5分間隔、通常時は1分間隔
      
      if(TimeCurrent() - lastSaveTime > saveInterval)
      {
         SaveGhostPositionsToGlobal();
         lastSaveTime = TimeCurrent();
      }
      
      // 定期的にゴーストオブジェクトの整合性チェックと再構築
      static datetime lastCheckTime = 0;
      int checkInterval = isTesting ? 1800 : 300; // バックテスト時は30分間隔、通常時は5分間隔
      
      if(TimeCurrent() - lastCheckTime > checkInterval)
      {
         CleanupAndRebuildGhostObjects();
         
         // リアルポジションとゴーストポジションがどちらもない場合は決済済みフラグをリセット
         if(position_count(OP_BUY) == 0 && position_count(OP_SELL) == 0 &&
            g_GhostBuyCount == 0 && g_GhostSellCount == 0)
         {
            if(g_BuyGhostClosed || g_SellGhostClosed)
            {
               g_BuyGhostClosed = false;
               g_SellGhostClosed = false;
               SaveGhostPositionsToGlobal();
            }
         }
         
         lastCheckTime = TimeCurrent();
      }
      
      // OnTimerの機能も呼び出し（バックテスト時は頻度を下げる）
      if(!isTesting || (isTesting && MathMod(Bars, 1000) == 0))
      {
         OnTimerHandler();
      }
   }

   // 戦略ロジックを処理
   ProcessStrategyLogic();

   // GUIを更新（バックテスト時は頻度を下げる）
   if(!isTesting || (isTesting && MathMod(Bars, 1000) == 0))
   {
      UpdateGUI();
   }

   // 平均取得価格ラインの表示更新
   UpdateAveragePriceLineDisplay(isTesting);
   
   // 利確条件の処理
   if(TakeProfitMode != TP_OFF)
   {
      ManageTakeProfit(0); // Buy側
      ManageTakeProfit(1); // Sell側
   }
   
   // トレールストップ条件のチェック
   if(EnableTrailingStop)
   {
      // リアルポジションのトレーリングストップ
      CheckTrailingStopConditions(0); // Buy側
      CheckTrailingStopConditions(1); // Sell側
      
      // ゴーストポジションのトレーリングストップ
      CheckGhostTrailingStopConditions(0); // Buy側
      CheckGhostTrailingStopConditions(1); // Sell側
   }

   // ポジション数に応じた建値決済機能を実行
   CheckBreakEvenByPositions();

   // リアルポジション数の変化をチェック
   CheckPositionChanges();

   // 指値決済の検出とゴーストリセット処理
   CheckLimitTakeProfitExecutions();
}

//+------------------------------------------------------------------+
//| 平均価格ラインの表示更新 (MQL4/MQL5共通)                         |
//+------------------------------------------------------------------+
void UpdateAveragePriceLineDisplay(bool isTesting)
{
   if(AveragePriceLine == ON_MODE && g_AvgPriceVisible)
   {
      // Buy/Sellポジションがあるかチェック
      int buyPositions = position_count(OP_BUY) + ghost_position_count(OP_BUY);
      int sellPositions = position_count(OP_SELL) + ghost_position_count(OP_SELL);
      
      // ポジションがない場合は強制的にラインを削除
      if(buyPositions == 0 && sellPositions == 0)
      {
         DeleteAllLines();
      }
      else
      {
         // 通常の更新処理
         static datetime lastAvgPriceUpdateTime = 0;
         int updateInterval = isTesting ? 60 : 1; // バックテスト時は60秒間隔、通常時は1秒間隔
         
         if(TimeCurrent() - lastAvgPriceUpdateTime > updateInterval)
         {
            if(buyPositions > 0)
               UpdateAveragePriceLines(0); // Buy側
            else
               DeleteSpecificLine(0); // Buy側のラインを削除
            
            if(sellPositions > 0)
               UpdateAveragePriceLines(1); // Sell側
            else
               DeleteSpecificLine(1); // Sell側のラインを削除
            
            lastAvgPriceUpdateTime = TimeCurrent();
         }
      }
   }
   else
   {
      // 表示設定オフの場合、すべてのラインを削除
      DeleteAllLines();
   }
}

//+------------------------------------------------------------------+
//| 特定方向のラインのみを削除 (MQL4/MQL5共通)                       |
//+------------------------------------------------------------------+
void DeleteSpecificLine(int side)
{
   string direction = (side == 0) ? "Buy" : "Sell";
   
   // 平均価格ライン関連のオブジェクトを削除
   string objects[6];
   
   // 各要素に個別に値を代入
   objects[0] = g_ObjectPrefix + "AvgPrice" + direction;
   objects[1] = g_ObjectPrefix + "TPLine" + direction;
   objects[2] = g_ObjectPrefix + "AvgPriceLabel" + direction;
   objects[3] = g_ObjectPrefix + "TPLabel" + direction;
   objects[4] = g_ObjectPrefix + "LimitTP" + direction;
   objects[5] = g_ObjectPrefix + "LimitTPLabel" + direction;
   
   for(int i = 0; i < ArraySize(objects); i++)
   {
      if(ObjectFind(objects[i]) >= 0)
      {
         ObjectDelete(objects[i]);
         Print("方向別オブジェクト削除: ", objects[i]);
      }
   }
   
   // チャートの再描画
   ChartRedraw();
}

//+------------------------------------------------------------------+
//| CheckNanpinConditions関数 (MQL4/MQL5共通)                        |
//+------------------------------------------------------------------+
void CheckNanpinConditions(int side)
{
   // 前回のチェックからの経過時間を確認
   static datetime lastCheckTime[2] = {0, 0}; // [0] = Buy, [1] = Sell
   int typeIndex = side;
   
   if(TimeCurrent() - lastCheckTime[typeIndex] < 10) // 10秒間隔でチェック
      return;
   
   lastCheckTime[typeIndex] = TimeCurrent();
   
   // 処理対象のオペレーションタイプを決定
   int operationType = (side == 0) ? OP_BUY : OP_SELL;
   
   // ポジションカウントを取得（リアルのみ - ゴーストは含めない）
   int realPositionCount = position_count(operationType);
   
   // ポジションがないか最大数に達している場合はスキップ
   if(realPositionCount <= 0 || realPositionCount >= (int)MaxPositions)
   {
      if(realPositionCount >= (int)MaxPositions)
         Print("CheckNanpinConditions: 最大ポジション数(", (int)MaxPositions, 
               ")に達しているため、ナンピンをスキップします");
      return;
   }
   
   // ナンピン機能が無効の場合はスキップ
   if(!EnableNanpin)
   {
      Print("CheckNanpinConditions: ナンピン機能が無効のため、スキップします");
      return;
   }
   
   // 最後のエントリー時間を取得
   datetime lastEntryTime = GetLastEntryTime(operationType);
   
   // 最後のエントリーがない場合はスキップ
   if(lastEntryTime == 0)
   {
      Print("CheckNanpinConditions: 最後のエントリー時間が取得できません");
      return;
   }
   
   // ナンピンインターバルの有効性をチェック
   bool intervalOK = true;
   
   if(NanpinInterval > 0)
   {
      intervalOK = (TimeCurrent() - lastEntryTime >= NanpinInterval * 60);
      
      if(!intervalOK)
      {
         Print("ナンピンインターバル待機中: ", 
               (TimeCurrent() - lastEntryTime) / 60, "分 / ", 
               NanpinInterval, "分");
         return;
      }
   }

   // 合計ポジション数（ゴースト＋リアル）を取得
   int totalPositionCount = combined_position_count(operationType);
   
   // 最後のポジション価格を取得
   double lastPrice = GetLastCombinedPositionPrice(operationType);
   if(lastPrice <= 0)
   {
      Print("CheckNanpinConditions: 最後のポジション価格が取得できません。スキップします。");
      return;
   }
   
   // 現在の価格を取得（BuyならBid、SellならAsk）
   double currentPrice = (side == 0) ? GetBidPrice() : GetAskPrice();
   
   // 現在のレベルに対応するナンピン幅を取得
   int nanpinSpread = g_NanpinSpreadTable[totalPositionCount - 1];
   
   // デバッグ出力
   string direction = (side == 0) ? "Buy" : "Sell";
   Print("CheckNanpinConditions 詳細: 方向=", direction, 
         ", リアルポジション数=", realPositionCount,
         ", 合計ポジション数=", totalPositionCount,
         ", 最後の価格=", DoubleToString(lastPrice, Digits),
         ", 現在価格=", DoubleToString(currentPrice, Digits),
         ", ナンピン幅=", nanpinSpread, "ポイント",
         ", 差=", MathAbs((side == 0) ? (lastPrice - currentPrice) : (currentPrice - lastPrice)) / Point, 
         "ポイント");
   
   // ナンピン条件の判定
   bool nanpinCondition = false;
   
   if(side == 0) // Buy
      nanpinCondition = (currentPrice < lastPrice - nanpinSpread * Point);
   else // Sell
      nanpinCondition = (currentPrice > lastPrice + nanpinSpread * Point);
   
   Print("CheckNanpinConditions 条件判定: ", nanpinCondition ? "成立" : "不成立");
   
   // ナンピン条件が満たされた場合
   if(nanpinCondition)
   {
      Print(direction, " リアルナンピン条件成立、実行を開始します");
      ExecuteRealNanpin(operationType);
   }
}

//+------------------------------------------------------------------+
//| InitializeEA関数 (MQL4/MQL5共通)                                 |
//+------------------------------------------------------------------+
int InitializeEA()
{
   // キャッシュをリセット（高速化のため）
   ResetTradingCaches();

   // アカウント番号を取得して保存
#ifdef __MQL5__
   g_AccountNumber = (int)AccountInfoInteger(ACCOUNT_LOGIN);
#else
   g_AccountNumber = AccountNumber();
#endif
   
   // グローバル変数のプレフィックスを設定
   g_GlobalVarPrefix = Symbol() + "_" + IntegerToString(MagicNumber) + "_" + 
                      IntegerToString(g_AccountNumber) + "_Ghost_";
   
   // オブジェクト名のプレフィックスを設定
   g_ObjectPrefix = IntegerToString(MagicNumber) + "_" + IntegerToString(g_AccountNumber) + "_";
   
   // レイアウトパターンを適用
   ApplyLayoutPattern();
   Print("レイアウトパターンを初期化しました: ", GetLayoutPatternText());
   
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

   // ゴーストモードは常に有効
   g_GhostMode = true;
   Print("ゴーストモードを有効化しました");
   
   // エントリーモードの確認と表示
   string entryModeStr = "";
   switch(EntryMode)
   {
      case MODE_BUY_ONLY:
         entryModeStr = "Buy Only";
         break;
      case MODE_SELL_ONLY:
         entryModeStr = "Sell Only";
         break;
      case MODE_BOTH:
         entryModeStr = "Buy & Sell Both";
         break;
      default:
         entryModeStr = "Unknown";
   }
   Print("現在のエントリーモード: ", entryModeStr);

   // ロットテーブルの内容をログに出力
   string lotTableStr = "LOTテーブル: ";
   for(int i = 0; i < MathMin(10, ArraySize(g_LotTable)); i++)
   {
      lotTableStr += DoubleToString(g_LotTable[i], 2) + ", ";
   }
   Print(lotTableStr);

   // リアルポジションがある場合のチェック
   int buyPositions = position_count(OP_BUY);
   int sellPositions = position_count(OP_SELL);

   if(buyPositions > 0 || sellPositions > 0)
   {
      Print("既にリアルポジションが存在します - Buy: ", buyPositions, ", Sell: ", sellPositions);
      
      // 既存のゴーストポジションをクリア
      ClearGhostPositionsFromGlobal();
      ResetGhost(OP_BUY);
      ResetGhost(OP_SELL);
      
      // 平均取得価格ラインは表示
      if(AveragePriceLine == ON_MODE)
      {
         g_AvgPriceVisible = true;
      }
   }
   else
   {
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

   // グローバル変数とinputの設定を同期
   g_EnableNanpin = EnableNanpin;
   g_EnableGhostEntry = EnableGhostEntry;
   g_EnableTrailingStop = EnableTrailingStop;
   g_AutoTrading = EnableAutomaticTrading;
   g_ShowPositionTable = EnablePositionTable;

   g_BuyClosedRecently = false;
   g_SellClosedRecently = false;
   g_BuyClosedTime = 0;
   g_SellClosedTime = 0;

   // GUI作成
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
      
      // キャッシュをリセット
      ResetTradingCaches();
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
      string name = ObjectName(0, i);
      if(StringFind(name, g_ObjectPrefix) == 0 && StringFind(name, "Ghost") >= 0)
      {
         ObjectDelete(0, name);
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
//| リアルエントリー用のGetLastPositionLot関数を追加                 |
//+------------------------------------------------------------------+
double GetLastPositionLot(int type)
{
   double lastLotSize = 0;
   datetime lastOpenTime = 0;
   
#ifdef __MQL5__
   // MQL5の場合
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(PositionSelectByIndex(i))
      {
         if(PositionGetInteger(POSITION_TYPE) == type && 
            PositionGetString(POSITION_SYMBOL) == Symbol() && 
            PositionGetInteger(POSITION_MAGIC) == MagicNumber)
         {
            datetime openTime = (datetime)PositionGetInteger(POSITION_TIME);
            if(openTime > lastOpenTime)
            {
               lastOpenTime = openTime;
               lastLotSize = PositionGetDouble(POSITION_VOLUME);
            }
         }
      }
   }
#else
   // MQL4の場合
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
#endif
   
   return lastLotSize;
}

//+------------------------------------------------------------------+
//| リアルポジション数変化を監視する関数 - 両建て強化対応版            |
//+------------------------------------------------------------------+
void CheckPositionChanges()
{
   // 前回カウントを保存する静的変数
   static int prevBuyCount = 0;
   static int prevSellCount = 0;
   
   // 現在のポジション数を取得
   int currentBuyCount = position_count(OP_BUY);
   int currentSellCount = position_count(OP_SELL);
   
   // Buy側でポジション数減少を検出
   if(currentBuyCount < prevBuyCount)
   {
      Print("Buy側ポジション減少検出: ", prevBuyCount, " -> ", currentBuyCount);
      
      // 完全に決済された場合
      if(currentBuyCount == 0)
      {
         // 決済時間を記録
         g_BuyClosedTime = TimeCurrent();
         // 最近決済されたフラグをON
         g_BuyClosedRecently = true;
         
         Print("Buy側完全決済検出: 時間=", TimeToString(g_BuyClosedTime));
         
         // 同方向のゴーストをリセット
         ResetSpecificGhost(OP_BUY);
         
         // 関連するラインを削除
         CleanupLinesOnClose(0);
      }
   }
   
   // Sell側でポジション数減少を検出
   if(currentSellCount < prevSellCount)
   {
      Print("Sell側ポジション減少検出: ", prevSellCount, " -> ", currentSellCount);
      
      // 完全に決済された場合
      if(currentSellCount == 0)
      {
         // 決済時間を記録
         g_SellClosedTime = TimeCurrent();
         // 最近決済されたフラグをON
         g_SellClosedRecently = true;
         
         Print("Sell側完全決済検出: 時間=", TimeToString(g_SellClosedTime));
         
         // 同方向のゴーストをリセット
         ResetSpecificGhost(OP_SELL);
         
         // 関連するラインを削除
         CleanupLinesOnClose(1);
      }
   }
   
   // 現在のカウントを保存
   prevBuyCount = currentBuyCount;
   prevSellCount = currentSellCount;
}

//+------------------------------------------------------------------+
//| ProcessRealEntries関数 - 初回エントリー時間制限対応版              |
//+------------------------------------------------------------------+
void ProcessRealEntries(int side)
{
   string direction = (side == 0) ? "Buy" : "Sell";
   Print("ProcessRealEntries: ", direction, " 処理開始");
   
   // 同方向のリアルポジション数をチェック
   int operationType = (side == 0) ? OP_BUY : OP_SELL;
   int existingCount = position_count(operationType);
   
   if(existingCount > 0) {
      Print("ProcessRealEntries: 既に", direction, "リアルポジションが存在するため、新規エントリーはスキップします");
      return;
   }
   
   // ポジション保護モードのチェック
   if(!IsEntryAllowedByProtectionMode(side))
   {
      Print("ProcessRealEntries: ポジション保護モードにより", direction, "側はスキップします");
      return;
   }
   
   // 決済後インターバルチェック
   if(!IsCloseIntervalElapsed(side))
   {
      Print("ProcessRealEntries: 決済後インターバル中のため", direction, "側はスキップします");
      return;
   }

   // ここに時間制限を追加（初回エントリーのみ）
   // ゴーストも含めた合計ポジション数を取得
   int totalPositionCount = combined_position_count(operationType);
   
   // 初回エントリーの場合のみ時間チェックを行う
   if(totalPositionCount == 0)
   {
      if(!IsInitialEntryTimeAllowed(operationType))
      {
         Print("ProcessRealEntries: 初回エントリー時間制限により", direction, "側はスキップします");
         return;
      }
   }

   // エントリーモードチェック
   bool modeAllowed = false;
   if(side == 0) // Buy
      modeAllowed = (EntryMode == MODE_BUY_ONLY || EntryMode == MODE_BOTH);
   else // Sell
      modeAllowed = (EntryMode == MODE_SELL_ONLY || EntryMode == MODE_BOTH);
   
   if(!modeAllowed) {
      return;
   }
   
   // 戦略シグナルチェック
   bool entrySignal = ShouldProcessRealEntry(side);
   
   if(entrySignal) {
      ExecuteRealEntry(operationType, "インジケーターシグナル");
   } 
}


