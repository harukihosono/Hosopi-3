//+------------------------------------------------------------------+
//|              Hosopi 3 - メイン管理用関数                           |
//|                       Copyright 2025                             |
//+------------------------------------------------------------------+
#include "Hosopi3_Compat.mqh"
#include "Hosopi3_Defines.mqh"
#include "Hosopi3_Compat.mqh"
#include "Hosopi3_Trading.mqh"
#include "Hosopi3_Utils.mqh"
#include "Hosopi3_GUI.mqh"
#include "Hosopi3_Table.mqh"
#include "Hosopi3_Ghost.mqh"

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
                      DoubleToString(type == OP_BUY ? GetAskPrice() : GetBidPrice(), GetDigits()));
   
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
//| ExecuteRealEntry関数 - 初回エントリー時間制限対応版               |
//+------------------------------------------------------------------+
void ExecuteRealEntry(int type, string entryReason)
{
   if(!g_AutoTrading)
   {
      Print("自動売買が無効のため、リアルエントリーはスキップされました");
      return;
   }
      
   if((GetAskPrice() - GetBidPrice()) / GetPointValue() > MaxSpreadPoints && MaxSpreadPoints > 0)
   {
      Print("スプレッドが大きすぎるため、リアルエントリーはスキップされました: ", (GetAskPrice() - GetBidPrice()) / GetPointValue(), " > ", MaxSpreadPoints);
      return;
   }
      
   int existingCount = position_count(type);
   if(existingCount > 0)
   {
      Print("既にリアルポジションが存在するため、リアルエントリーはスキップされました: ", existingCount, "ポジション");
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
         Print("ExecuteRealEntry: 初回エントリー時間制限により", type == OP_BUY ? "Buy" : "Sell", "側はスキップします");
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
   
   
   // ===== ロットサイズの選択ロジックを修正 =====
   double lots;
   
   // UseInitialLotForRealEntryがONの場合は真の初回エントリーのみ初期ロットを使用（ゴーストも無い場合）
   if(UseInitialLotForRealEntry && totalPositionCount == 0) {
      lots = g_LotTable[0]; // 真の初回エントリーのみ初期ロットを使用
      Print("真の初回エントリー: 初期ロット", DoubleToString(lots, 2), "を使用");
   } 
   // 合計ポジション数が0の場合も初期ロットを使用
   else if(totalPositionCount == 0) {
      lots = g_LotTable[0]; // 常に最初のロットを使用
   } 
   // 既存のポジションがある場合は最後のポジションのロットを参照
   else {
      // 最後のポジションのロットサイズを取得
      double lastLotSize = GetLastCombinedPositionLot(type);
      
      if(IndividualLotEnabled == ON_MODE) {
         // 個別指定モードの場合、合計ポジション数に対応したロットを使用
         // ポジション数は1から始まるので、配列インデックスには-1が必要
         int lotIndex = totalPositionCount;
         
         // 配列の範囲をチェック
         if(lotIndex >= 0 && lotIndex < ArraySize(g_LotTable)) {
            lots = g_LotTable[lotIndex];
         } else {
            // 範囲外の場合は最後のロットを使用
            lots = g_LotTable[ArraySize(g_LotTable) - 1];
            Print("警告: 合計ポジション数が範囲外のため最大レベルのロット", DoubleToString(lots, 2), "を使用");
         }
      } else {
         // マーチンゲールモードの場合
         if(lastLotSize <= 0) {
            // 最後のロットサイズが取得できなかった場合
            lots = g_LotTable[0];
            Print("警告: 最後のポジションのロットサイズを取得できませんでした。初期ロット", DoubleToString(lots, 2), "を使用します");
         } else {
            // 0.01ロット特別処理（パラメータで有効/無効を選択可能）
            if(Enable001LotFix && MathAbs(lastLotSize - 0.01) < 0.001) {
               lots = 0.02;
               Print("0.01ロット検出: 次のロットを0.02に強制固定します (Enable001LotFix=true)");
            } else {
               // それ以外は通常のマーチンゲール計算
               lots = lastLotSize * LotMultiplier;
            }
         }
      }
   }

   // ロットをブローカーのステップに合わせて正規化
   double lotStep = MarketInfo(_Symbol, MODE_LOTSTEP);
   double lotMin = MarketInfo(_Symbol, MODE_MINLOT);
   double lotMax = MarketInfo(_Symbol, MODE_MAXLOT);

   lots = MathRound(lots / lotStep) * lotStep;
   if(lots < lotMin) lots = lotMin;
   if(lots > lotMax) lots = lotMax;

   // エントリー理由をログに記録
   LogEntryReason(type, "自動エントリー", entryReason);
   
   // 非同期注文を使用してエントリー
   #ifdef __MQL5__
   MqlTradeRequest request;
   MqlTradeResult resultAsync;
   ZeroMemory(request);

   request.action = TRADE_ACTION_DEAL;
   request.symbol = _Symbol;
   request.volume = lots;
   request.type = (ENUM_ORDER_TYPE)type;
   request.price = (type == OP_BUY) ? SymbolInfoDouble(_Symbol, SYMBOL_ASK) : SymbolInfoDouble(_Symbol, SYMBOL_BID);
   request.deviation = Slippage;
   request.magic = MagicNumber;
   request.comment = "Hosopi 3 EA";

   bool result = SendOrderWithRetryAsync(request, resultAsync, 3, UseAsyncOrders);
   #else
   // MQL4では従来の関数を使用
   bool result = position_entry(type, lots, Slippage, MagicNumber, "Hosopi 3 EA");
   #endif

   if(result)
   {
      
      // 修正: ゴーストポジションはリセットしない
      // ここでのリセット処理を削除し、コメントに置き換え
   }
   else
   {
      Print("リアル", type == OP_BUY ? "Buy" : "Sell", "エントリーエラー: ", GetLastError());
   }
}

//+------------------------------------------------------------------+
//| ExecuteRealNanpin関数 - ナンピンレベル廃止版                     |
//+------------------------------------------------------------------+
void ExecuteRealNanpin(int typeOrder)
{
   // 自動売買が無効の場合は何もしない
   if(!g_AutoTrading)
   {
      Print("自動売買が無効のため、リアルナンピンはスキップされました");
      return;
   }
   
   // スプレッドチェック
   if((GetAskPrice() - GetBidPrice()) / GetPointValue() > MaxSpreadPoints && MaxSpreadPoints > 0)
   {
      Print("スプレッドが大きすぎるため、リアルナンピンはスキップされました: ", (GetAskPrice() - GetBidPrice()) / GetPointValue(), " > ", MaxSpreadPoints);
      return;
   }
   
   // 現在のポジション数を確認（ゴースト含む）
   int realPosCount = position_count(typeOrder);
   int totalPosCount = combined_position_count(typeOrder);

   if(totalPosCount <= 0)
   {
      // ポジションがない場合は何もしない
      return;
   }
   
   if(totalPosCount >= (int)MaxPositions)
   {
      Print("すでに最大ポジション数に達しているため、リアルナンピンはスキップされました");
      return;
   }
   
   
   // ===== ロットサイズの選択ロジックを修正 =====
   double lotsToUse = InitialLot; // 初期値で初期化

   // UseInitialLotForRealEntryがONの場合は真の初回エントリーのみ初期ロットを使用（ゴーストからの移行はマーチン継続）
   if(UseInitialLotForRealEntry && realPosCount == 0 && totalPosCount == 0) {
      // 真の初回エントリーのみ初期ロットを使用（ゴーストも無い場合）
      lotsToUse = g_LotTable[0];
      Print("真の初回エントリー: 初期ロット", DoubleToString(lotsToUse, 2), "を使用");
   }
   // ゴーストからリアルへの移行時はマーチンゲール継続
   else if(UseInitialLotForRealEntry && realPosCount == 0 && totalPosCount > 0) {
      Print("ゴーストからリアルへの移行: マーチンゲール継続");
      // マーチンゲール処理に進む
   }
   // 個別指定モードが有効な場合（初回リアルエントリーでない場合）
   else if(IndividualLotEnabled == ON_MODE) {
      // 合計ポジション数に対応する次のレベルのロットを使用
      int nextLevel = totalPosCount; // 次のポジションレベル
      
      // 配列の範囲を超えないようにチェック
      if(nextLevel >= 0 && nextLevel < ArraySize(g_LotTable)) {
         lotsToUse = g_LotTable[nextLevel];
      } else {
         // 範囲外の場合は最後のロットを使用
         lotsToUse = g_LotTable[ArraySize(g_LotTable)-1];
         Print("警告: ナンピンレベルが範囲外のため最大レベルのロット", DoubleToString(lotsToUse, 2), "を使用");
      }
   }
   else {
      // マーチンゲールモードの場合は直前のポジションのロットに倍率を掛ける
      // 最後のポジションのロットサイズを取得（リアル、ゴースト同方含む）
      double lastLotSize = GetLastCombinedPositionLot(typeOrder);
      
      // ロットサイズが取得できなかった場合
      if(lastLotSize <= 0) {
         Print("警告: 最後のポジションのロットサイズを取得できませんでした。デフォルトロットを使用します。");
         lastLotSize = InitialLot;
      }
      
      // 0.01ロット特別処理（パラメータで有効/無効を選択可能）
      if(Enable001LotFix && MathAbs(lastLotSize - 0.01) < 0.001) {
         lotsToUse = 0.02;
         Print("0.01ロット検出:次のロットを0.02に強制固定します (Enable001LotFix=true)");
      }
      else {
         // それ以外は通常のマーチンゲール計算
         lotsToUse = lastLotSize * LotMultiplier;
      }
   }

   // ロットをブローカーのステップに合わせて正規化
   double lotStep = MarketInfo(_Symbol, MODE_LOTSTEP);
   double lotMin = MarketInfo(_Symbol, MODE_MINLOT);
   double lotMax = MarketInfo(_Symbol, MODE_MAXLOT);

   // ロットステップに合わせて丸める
   lotsToUse = MathRound(lotsToUse / lotStep) * lotStep;

   // 最小ロット・最大ロットの範囲内に収める
   if(lotsToUse < lotMin) lotsToUse = lotMin;
   if(lotsToUse > lotMax) lotsToUse = lotMax;

   // ナンピンロット計算のデバッグ情報を表示
   Print("ナンピン実行: ", (typeOrder == OP_BUY) ? "Buy" : "Sell",
         " | 現在ポジション数: リアル=", realPosCount, " 合計=", totalPosCount,
         " | ロット=", DoubleToString(lotsToUse, 2),
         " (ステップ=", lotStep, ")");

   // 非同期注文を使用してナンピンエントリー
   #ifdef __MQL5__
   MqlTradeRequest request;
   MqlTradeResult resultAsync;
   ZeroMemory(request);

   request.action = TRADE_ACTION_DEAL;
   request.symbol = _Symbol;
   request.volume = lotsToUse;
   request.type = (ENUM_ORDER_TYPE)typeOrder;
   request.price = (typeOrder == OP_BUY) ? SymbolInfoDouble(_Symbol, SYMBOL_ASK) : SymbolInfoDouble(_Symbol, SYMBOL_BID);
   request.deviation = Slippage;
   request.magic = MagicNumber;
   request.comment = "Hosopi 3 EA Nanpin";

   bool entryResult = SendOrderWithRetryAsync(request, resultAsync, 3, UseAsyncOrders);
   #else
   // MQL4では従来の関数を使用
   Print("ナンピンエントリー実行: position_entry(", typeOrder, ", ", lotsToUse, ")");
   bool entryResult = position_entry(typeOrder, lotsToUse, Slippage, MagicNumber, "Hosopi 3 EA Nanpin");
   #endif

   if(entryResult) {
      Print("ナンピンエントリー成功: ", (typeOrder == OP_BUY) ? "Buy" : "Sell",
            " ロット=", DoubleToString(lotsToUse, 2));
      // 修正: ゴーストポジションはリセットしない
   }
   else {
      Print("リアル", typeOrder == OP_BUY ? "Buy" : "Sell", "ナンピンエラー: ", GetLastError());
   }
}

//+------------------------------------------------------------------+
//| ExecuteDiscretionaryEntry関数 - 初回エントリー時間制限対応版      |
//+------------------------------------------------------------------+
void ExecuteDiscretionaryEntry(int typeOrder, double lotSize = 0)
{
   if(!g_AutoTrading)
   {
      Print("自動売買が無効のため、裁量エントリーはスキップされました");
      return;
   }
      
   if((GetAskPrice() - GetBidPrice()) / GetPointValue() > MaxSpreadPoints && MaxSpreadPoints > 0)
   {
      Print("スプレッドが大きすぎるため、裁量エントリーはスキップされました: ", (GetAskPrice() - GetBidPrice()) / GetPointValue(), " > ", MaxSpreadPoints);
      return;
   }
      
   int existingCount = position_count(typeOrder);
   if(existingCount > 0)
   {
      Print("既にリアルポジションが存在するため、裁量エントリーはスキップされました: ", existingCount, "ポジション");
      return;
   }
   
   // 合計ポジション数（ゴースト+リアル）を取得
   int totalPositionCount = combined_position_count(typeOrder);
   
   // 初回エントリーの場合は時間チェックを行う - ただし手動操作のため、常に許可する
   // 手動操作による裁量エントリーなので、時間制限は適用しない
   
   double lotsToUse;
   
   if(lotSize > 0) {
      // 明示的に指定されたロットサイズを使用
      lotsToUse = lotSize;
   } else if(totalPositionCount > 0) {
      // ポジションがある場合、次のレベルに対応するロットサイズを使用
      if(IndividualLotEnabled == ON_MODE) {
         // 個別指定モードの場合
         int nextLevel = totalPositionCount;
         if(nextLevel < ArraySize(g_LotTable)) {
            lotsToUse = g_LotTable[nextLevel];
         } else {
            lotsToUse = g_LotTable[ArraySize(g_LotTable)-1];
         }
      } else {
         // マーチンゲールモードの場合
         double lastLotSize = GetLastCombinedPositionLot(typeOrder);
         if(lastLotSize <= 0) {
            lotsToUse = InitialLot;
         } else {
            lotsToUse = lastLotSize * LotMultiplier;
         }
      }
   } else {
      // ポジションがない場合は初期ロットを使用
      lotsToUse = g_LotTable[0];
   }

   // ロットをブローカーのステップに合わせて正規化
   double lotStep = MarketInfo(_Symbol, MODE_LOTSTEP);
   double lotMin = MarketInfo(_Symbol, MODE_MINLOT);
   double lotMax = MarketInfo(_Symbol, MODE_MAXLOT);

   lotsToUse = MathRound(lotsToUse / lotStep) * lotStep;
   if(lotsToUse < lotMin) lotsToUse = lotMin;
   if(lotsToUse > lotMax) lotsToUse = lotMax;

   // エントリー理由をログに記録
   LogEntryReason(typeOrder, "裁量エントリー", "手動ボタン操作によるエントリー");
   
   // 非同期注文を使用して手動エントリー
   #ifdef __MQL5__
   MqlTradeRequest request;
   MqlTradeResult resultAsync;
   ZeroMemory(request);

   request.action = TRADE_ACTION_DEAL;
   request.symbol = _Symbol;
   request.volume = lotsToUse;
   request.type = (ENUM_ORDER_TYPE)typeOrder;
   request.price = (typeOrder == OP_BUY) ? SymbolInfoDouble(_Symbol, SYMBOL_ASK) : SymbolInfoDouble(_Symbol, SYMBOL_BID);
   request.deviation = Slippage;
   request.magic = MagicNumber;
   request.comment = "Hosopi 3 EA Manual";

   bool entryResult = SendOrderWithRetryAsync(request, resultAsync, 3, UseAsyncOrders);
   #else
   // MQL4では従来の関数を使用
   bool entryResult = position_entry(typeOrder, lotsToUse, Slippage, MagicNumber, "Hosopi 3 EA Manual");
   #endif
   
   if(entryResult)
   {
      
      // 修正: ゴーストポジションをリセットしない
   }
   else
   {
      Print("裁量", typeOrder == OP_BUY ? "Buy" : "Sell", "エントリーエラー: ", GetLastError());
   }
}

//+------------------------------------------------------------------+
//| ExecuteEntryFromLevel関数 - 初回エントリー時間制限対応版          |
//+------------------------------------------------------------------+
void ExecuteEntryFromLevel(int type, int level)
{
   if(!g_AutoTrading)
   {
      Print("自動売買が無効のため、レベル指定エントリーはスキップされました");
      return;
   }
      
   if((GetAskPrice() - GetBidPrice()) / GetPointValue() > MaxSpreadPoints && MaxSpreadPoints > 0)
   {
      Print("スプレッドが大きすぎるため、レベル指定エントリーはスキップされました: ", (GetAskPrice() - GetBidPrice()) / GetPointValue(), " > ", MaxSpreadPoints);
      return;
   }
      
   int existingCount = position_count(type);
   if(existingCount > 0)
   {
      Print("既にリアルポジションが存在するため、レベル指定エントリーをスキップしました: ", existingCount, "ポジション");
      return;
   }
   
   // 指定レベルが範囲内かチェック
   if(level < 1 || level > ArraySize(g_LotTable))
   {
      Print("指定レベルが範囲外のため、レベル指定エントリーはスキップされました: ", level);
      return;
   }
   
   // 合計ポジション数を取得
   int totalPositionCount = combined_position_count(type);
   
   // 初回エントリーの場合のみ時間チェック
   if(totalPositionCount == 0)
   {
      // レベル指定エントリーは手動操作なので、時間制限は適用しない
      // ただし、念のため処理は残しておく（コメントアウト）
      /*
      if(!IsInitialEntryTimeAllowed(type))
      {
         Print("ExecuteEntryFromLevel: 初回エントリー時間制限により", type == OP_BUY ? "Buy" : "Sell", "側はスキップします");
         return;
      }
      */
   }
   
   // ロット選択を明確化 - レベルは1始まりだが配列は0始まりなので調整
   double lots = g_LotTable[level - 1];
   
   // ロット選択のログ出力を強化
   
   
   // エントリー理由をログに記録
   LogEntryReason(type, "レベル指定エントリー", "手動選択: レベル" + IntegerToString(level));
   
   // 非同期注文を使用してレベル指定エントリー
   #ifdef __MQL5__
   MqlTradeRequest request;
   MqlTradeResult resultAsync;
   ZeroMemory(request);

   request.action = TRADE_ACTION_DEAL;
   request.symbol = _Symbol;
   request.volume = lots;
   request.type = (ENUM_ORDER_TYPE)type;
   request.price = (type == OP_BUY) ? SymbolInfoDouble(_Symbol, SYMBOL_ASK) : SymbolInfoDouble(_Symbol, SYMBOL_BID);
   request.deviation = Slippage;
   request.magic = MagicNumber;
   request.comment = "Hosopi 3 EA Level " + IntegerToString(level);

   bool result = SendOrderWithRetryAsync(request, resultAsync, 3, UseAsyncOrders);
   #else
   // MQL4では従来の関数を使用
   bool result = position_entry(type, lots, Slippage, MagicNumber, "Hosopi 3 EA Level " + IntegerToString(level));
   #endif
   
   if(result)
   {
      
      // 修正: ゴーストポジションをリセットしない
   }
   else
   {
      Print("レベル", level, "からの", type == OP_BUY ? "Buy" : "Sell", "エントリーエラー: ", GetLastError());
   }
}

//+------------------------------------------------------------------+
//| 戦略エントリー条件チェック関数                                    |
//+------------------------------------------------------------------+
bool CheckStrategyEntryCondition(int operationType)
{
   // 現在のローソク足時間を取得
   datetime currentCandleTime = iTime(Symbol(), PERIOD_CURRENT, 0);
   
   switch(Strategy_Entry_Condition)
   {
      case STRATEGY_NO_SAME_DIRECTION:
         {
            // 同方向のポジション（リアル＋ゴースト）数をチェック
            int realCount = position_count(operationType);
            int ghostCount = ghost_position_count(operationType);
            return (realCount + ghostCount == 0);
         }
         
      case STRATEGY_NO_POSITIONS:
         {
            // 全ポジション（リアル＋ゴースト）数をチェック
            int totalBuy = position_count(OP_BUY) + ghost_position_count(OP_BUY);
            int totalSell = position_count(OP_SELL) + ghost_position_count(OP_SELL);
            return (totalBuy + totalSell == 0);
         }
         
      case STRATEGY_ALWAYS_ALLOW:
         {
            // 常にエントリー許可
            return true;
         }
         
      case STRATEGY_DIFFERENT_CANDLE:
         {
            // 異なるローソク足でのみエントリー許可
            datetime lastEntryTime = (operationType == OP_BUY) ? g_LastBuyEntryTime : g_LastSellEntryTime;
            return (lastEntryTime != currentCandleTime);
         }

      case STRATEGY_CONSTANT_ENTRY:
         {
            // 常時エントリー戦略のチェック
            if(!IsConstantEntryEnabled())
               return false;

            // 戦略タイプに基づくチェック
            if(ConstantEntryStrategy == CONSTANT_ENTRY_LONG && operationType != OP_BUY)
               return false;
            if(ConstantEntryStrategy == CONSTANT_ENTRY_SHORT && operationType != OP_SELL)
               return false;

            // 間隔制御（分単位、0=無制限）
            if(ConstantEntryInterval > 0)
            {
               datetime lastEntryTime = GetLastEntryTime(operationType);
               if(lastEntryTime > 0)
               {
                  int elapsedMinutes = (int)((TimeCurrent() - lastEntryTime) / 60);
                  if(elapsedMinutes < ConstantEntryInterval)
                     return false;
               }
            }
            return true;
         }

      default:
         return false;
   }
}

// Hosopi3_Manager.mqh の OnTickManager関数内の最初の部分を修正 (バックテスト高速化対応)
void OnTickManager()
{
   // バックテスト時の処理を最適化
   bool isTesting = IsTesting();
   
   // テーブル更新の処理
   if(TimeCurrent() >= g_LastUpdateTime + UpdateInterval)
   {
      // テーブル表示が有効な場合は更新（バックテスト時も表示する）
      if(EnablePositionTable)
      {
         UpdatePositionTable();
      }
      
      g_LastUpdateTime = TimeCurrent();
      
      // ポジションがない場合のライン削除チェック
      CheckAndDeleteLinesIfNoPositions();
      
      // 定期的にゴーストポジション情報を保存 (バックテスト時は頻度を下げる)
      static datetime lastSaveTime = 0;
      int saveInterval = isTesting ? 300 : 60; // バックテスト時は5分間隔、通常時は1分間隔
      
      if(TimeCurrent() - lastSaveTime > saveInterval)
      {
         SaveGhostPositionsToGlobal();
         lastSaveTime = TimeCurrent();
      }
      
      // 定期的にゴーストオブジェクトの整合性チェックと再構築
      // バックテスト時は頻度を大幅に下げる
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
      static int callCounter = 0;
      callCounter++;
      if(!isTesting || (isTesting && callCounter % 1000 == 0)) // バックテスト時は1000回毎に実行
      {
         OnTimerHandler();
      }
   }

   // 戦略ロジックを処理 - これは常に必要なので実行
   ProcessStrategyLogic();

   // GUIを更新（バックテスト時は頻度を下げる）
   static int guiUpdateCounter = 0;
   guiUpdateCounter++;
   if(!isTesting || (isTesting && guiUpdateCounter % 1000 == 0)) // バックテスト時は1000回毎に実行
   {
      UpdateGUI();
      UpdateInfoPanel(); // InfoPanel更新
      // UpdateCyberUI(); // 現在無効化
   }

   // 平均取得価格ラインの表示更新（バックテスト時は頻度を下げる）
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
      {// 通常の更新処理
         static datetime lastAvgPriceUpdateTime = 0;
         int updateInterval = isTesting ? 60 : 1; // バックテスト時は60秒間隔、通常時は1秒間隔
         
         if(TimeCurrent() - lastAvgPriceUpdateTime > updateInterval)
         {
            int buyGhosts = ghost_position_count(OP_BUY);
            int sellGhosts = ghost_position_count(OP_SELL);

            if(buyPositions > 0 || buyGhosts > 0)
               UpdateAveragePriceLines(0); // Buy側
            else
               DeleteSpecificLine(0); // Buy側のラインを削除（リアル・ゴースト共に0）

            if(sellPositions > 0 || sellGhosts > 0)
               UpdateAveragePriceLines(1); // Sell側
            else
               DeleteSpecificLine(1); // Sell側のラインを削除（リアル・ゴースト共に0）

            lastAvgPriceUpdateTime = TimeCurrent();
         }
      }
   }
   else
   {
      // 表示設定オフの場合、すべてのラインを削除
      DeleteAllLines();
   }
   
   // 利確条件の処理（統合関数を使用）
   if(EnableTakeProfit) // TPが有効なときだけ処理
   {
      ManageTakeProfit(0); // Buy側
      ManageTakeProfit(1); // Sell側
   }
   
   // ナンピン機能が有効な場合、常にナンピン条件をチェック（初回エントリーも含めて）
   if(EnableNanpin)
   {
      // 最大ポジション数をチェック
      int buyTotal = combined_position_count(OP_BUY);
      int sellTotal = combined_position_count(OP_SELL);
      int totalAllPositions = buyTotal + sellTotal;

      // Buy側のナンピン条件チェック（ポジションがなくても実行）
      if(buyTotal < (int)MaxPositions && totalAllPositions < (int)MaxPositions * 2)
      {
         CheckNanpinConditions(0); // Buy側のナンピン条件チェック
      }

      // Sell側のナンピン条件チェック（ポジションがなくても実行）
      if(sellTotal < (int)MaxPositions && totalAllPositions < (int)MaxPositions * 2)
      {
         CheckNanpinConditions(1); // Sell側のナンピン条件チェック
      }
   }
   
   // トレールストップ条件のチェック（独立して動作）
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
   
   // 損失額による決済機能を実行
   CheckMaxLossClose();

   // リアルポジション数の変化をチェック
   CheckPositionChanges();

   // 指値決済の検出とゴーストリセット処理
   CheckLimitTakeProfitExecutions();
}

//+------------------------------------------------------------------+
//| 特定方向のラインのみを削除                                        |
//+------------------------------------------------------------------+
void DeleteSpecificLine(int side)
{
   string direction = (side == 0) ? "Buy" : "Sell";
   
   // 平均価格ライン関連のオブジェクトを削除
   string objects[6]; // 配列サイズを宣言
   
   // 各要素に個別に値を代入
   objects[0] = g_ObjectPrefix + "AvgPrice" + direction;
   objects[1] = g_ObjectPrefix + "TPLine" + direction;
   objects[2] = g_ObjectPrefix + "AvgPriceLabel" + direction;
   objects[3] = g_ObjectPrefix + "TPLabel" + direction;
   objects[4] = g_ObjectPrefix + "LimitTP" + direction;
   objects[5] = g_ObjectPrefix + "LimitTPLabel" + direction;
   
   for(int i = 0; i < ArraySize(objects); i++)
   {
      if(ObjectExists(objects[i]))
      {
         ObjectDeleteMQL(objects[i]);
      }
   }
   
   // チャートの再描画
   ChartRedraw();
}

//+------------------------------------------------------------------+
//| CheckNanpinConditions関数 - ナンピンレベル廃止版                   |
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
   // マジックナンバー0の場合は全ポジションをチェック
   int realPositionCount = position_count(operationType);
   
   // マジックナンバーが0の場合、手動ポジションも含めてカウント
   if(MagicNumber == 0)
   {
      realPositionCount = position_count_all(operationType);
   }
   
   // ゴーストポジションも含めた合計カウントを取得
   int totalPositionCount = combined_position_count(operationType);
   int ghostPositionCount = ghost_position_count(operationType);
   
   
   // デバッグログ用の静的変数（60秒に1回のみ出力）
   static datetime lastDebugTime = 0;
   bool shouldDebug = (TimeCurrent() - lastDebugTime > 60);
   string direction = (side == 0) ? "Buy" : "Sell";

   // 最大ポジション数に達している場合のみスキップ（ポジションが0でも初回エントリーは実行）
   if(totalPositionCount >= (int)MaxPositions)
   {
      if(shouldDebug) Print("ナンピン[", direction, "]: 最大ポジション数到達 (", totalPositionCount, "/", (int)MaxPositions, ")");
      return;
   }

   // ポジションがない場合は初回エントリーとして処理
   if(totalPositionCount == 0)
   {
      if(shouldDebug) Print("ナンピン[", direction, "]: 初回エントリー実行");
      // 初回エントリーを実行
      ExecuteRealNanpin(operationType);
      return;
   }

   // ナンピン機能が無効の場合はスキップ
   if(!EnableNanpin)
   {
      if(shouldDebug) Print("ナンピン[", direction, "]: ナンピン機能無効");
      return;
   }

   // 最後のエントリー時間を取得（改良版）
   datetime lastEntryTime = GetLastEntryTime(operationType);

   // 最後のエントリーがない場合はスキップ
   if(lastEntryTime == 0)
   {
      if(shouldDebug) Print("ナンピン[", direction, "]: 最後のエントリー時間取得失敗");
      return;
   }
   
   // ナンピンインターバルの有効性をチェック
   bool intervalOK = true; // デフォルトでOK
   
   if(NanpinInterval > 0) // インターバルが設定されている場合のみチェック
   {
      intervalOK = (TimeCurrent() - lastEntryTime >= NanpinInterval * 60);

      if(!intervalOK)
      {
         if(shouldDebug) Print("ナンピン[", direction, "]: インターバル待機中");
         return;
      }
   }

   // 合計ポジション数は既に上で取得済み

   // 最後のポジション価格を取得
   double lastPrice = GetLastCombinedPositionPrice(operationType);
   if(lastPrice <= 0)
   {
      if(shouldDebug) Print("ナンピン[", direction, "]: 最後のポジション価格取得失敗");
      return;
   }

   // 現在の価格を取得（BuyならBid、SellならAsk）
   double currentPrice = (side == 0) ? GetBidPrice() : GetAskPrice();

   // 現在のレベルに対応するナンピン幅を取得
   // 合計ポジション数を使用
   int nanpinSpread = g_NanpinSpreadTable[totalPositionCount - 1];

   // ナンピン条件の判定
   bool nanpinCondition = false;

   if(side == 0) // Buy
      nanpinCondition = (currentPrice < lastPrice - nanpinSpread * GetPointValue());
   else // Sell
      nanpinCondition = (currentPrice > lastPrice + nanpinSpread * GetPointValue());

   // デバッグ情報（60秒毎）
   if(shouldDebug)
   {
      double priceDiff = (side == 0) ? (lastPrice - currentPrice) : (currentPrice - lastPrice);
      double requiredDiff = nanpinSpread * GetPointValue();
      Print("ナンピン[", direction, "]: ポジ=", totalPositionCount,
            " 現在価格=", currentPrice, " 最後=", lastPrice,
            " 差=", (priceDiff / GetPointValue()), "pt",
            " 必要=", nanpinSpread, "pt",
            " 条件=", nanpinCondition ? "成立" : "未成立");
      lastDebugTime = TimeCurrent();
   }

   // ナンピン条件が満たされた場合
   if(nanpinCondition)
   {
      Print("ナンピン[", direction, "]: 条件成立 - ナンピン実行");

      // ナンピンスキップレベルのチェック
      int nextLevel = totalPositionCount + 1; // 次のポジションレベル

      // スキップレベル以下の場合はゴーストナンピン、それ以外はリアルナンピン
      if(NanpinSkipLevel != SKIP_NONE && nextLevel <= (int)NanpinSkipLevel)
      {
         Print("ナンピン[", direction, "]: ゴーストナンピン実行 (レベル ", nextLevel, " <= ", (int)NanpinSkipLevel, ")");

         // ゴーストナンピンを実行
         double price = (operationType == OP_BUY) ? GetAskPrice() : GetBidPrice();
         
         // ロットサイズを決定
         double lot;
         if(IndividualLotEnabled == ON_MODE)
         {
            // 個別指定モードの場合、テーブルから取得
            if(nextLevel - 1 < ArraySize(g_LotTable))
            {
               lot = g_LotTable[nextLevel - 1]; // 個別指定ロット
               
               // 個別指定モードでも、前のロットとの比率を確認
               double lastLot = GetLastCombinedPositionLot(operationType);
               if(lastLot > 0)
               {
                  double actualMultiplier = lot / lastLot;
               }
            }
            else
            {
               lot = g_LotTable[ArraySize(g_LotTable) - 1]; // 最大レベルのロット
            }
         }
         else
         {
            // マーチンゲールモード（自動計算）
            
            double lastLot = GetLastCombinedPositionLot(operationType);
            
            if(lastLot > 0)
            {
               // 0.01ロット特別処理（パラメータで有効/無効を選択可能）
               if(Enable001LotFix && MathAbs(lastLot - 0.01) < 0.001)
               {
                  lot = 0.02;
               }
               else
               {
                  // 通常のマーチンゲール計算
                  double calculatedLot = lastLot * LotMultiplier;
                  lot = NormalizeVolume(calculatedLot);
                  
               }
            }
            else
            {
               // 最初のエントリー
               lot = InitialLot;
            }
         }
         
         string comment = "ゴーストナンピン Lv" + IntegerToString(nextLevel);
         
         // EnableGhostEntryのチェック
         if(!EnableGhostEntry)
         {
            Print("【エラー】 EnableGhostEntry=false のためゴーストナンピンできません");
            return;
         }
         
         bool ghostResult = ExecuteGhostEntry(operationType, price, lot, comment, nextLevel);
      }
      else
      {
         Print("ナンピン[", direction, "]: リアルナンピン実行 (レベル ", nextLevel, " > ", (int)NanpinSkipLevel, ")");
         ExecuteRealNanpin(operationType);
      }
   }
}

//+------------------------------------------------------------------+
//| InitializeEA関数 - レイアウトパターン対応版                        |
//+------------------------------------------------------------------+
int InitializeEA()
{
   // デバッグモード無効
   
   // キャッシュをリセット（高速化のため）
   ResetTradingCaches();

   // フィリングモードを初期化
   InitFillingMode();

   // アカウント番号を取得して保存
   g_AccountNumber = GetAccountNumber();
   
   // グローバル変数のプレフィックスを設定（通貨ペア＋マジックナンバー＋アカウント番号）
   g_GlobalVarPrefix = Symbol() + "_" + IntegerToString(MagicNumber) + "_" + IntegerToString(g_AccountNumber) + "_Ghost_";
   
   // オブジェクト名のプレフィックスを設定
   g_ObjectPrefix = IntegerToString(MagicNumber) + "_" + IntegerToString(g_AccountNumber) + "_";
   
   // レイアウトパターンを適用 - 追加
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
      ResetGhostPositions(OP_BUY);
      ResetGhostPositions(OP_SELL);
      ClearGhostGlobalVariables();
   }

   // ゴーストモードは常に有効
   g_GhostMode = true;
   Print("ゴーストモードを有効化しました");

   // 自動売買設定の初期化と表示
   Print("自動売買設定: ", g_AutoTrading ? "有効" : "無効");
   if(g_AutoTrading)
   {
      Print("【重要】自動売買が有効です。戦略シグナルでリアルエントリーが実行されます。");
   }
   else
   {
      Print("【重要】自動売買が無効です。戦略シグナルではゴーストエントリーのみ実行されます。");
   }

   // エントリーモードの確認と表示
   string entryModeStr = "";
   switch(EntryMode) {
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

   // リアルポジションがある場合のチェック（複数チャート対策）
   int buyPositions = position_count(OP_BUY);
   int sellPositions = position_count(OP_SELL);

   if(buyPositions > 0 || sellPositions > 0) {
      Print("既にリアルポジションが存在します - Buy: ", buyPositions, ", Sell: ", sellPositions);
      
      // 既存のゴーストポジションをクリア
      ClearGhostGlobalVariables();
      ResetGhostPositions(OP_BUY);
      ResetGhostPositions(OP_SELL);
      
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

   // 戦略システムを初期化
   if(!InitializeStrategySystem())
   {
      Print("戦略システム初期化に失敗しました");
      return(INIT_FAILED);
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

   CreateGUI();

   // ポジションテーブルを作成
   CreatePositionTable();

   // InfoPanelを初期化
   InitializeInfoPanel();

   // CyberUIシステムを初期化（現在無効化）
   // InitializeCyberUI();

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
      ResetGhostPositions(OP_BUY);
      ResetGhostPositions(OP_SELL);
      ClearGhostGlobalVariables();
      
      // キャッシュをリセット
      ResetTradingCaches();
   }
   // チャートの時間足変更などの場合はゴーストポジション情報を保存
   else if(reason == REASON_CHARTCHANGE || reason == REASON_PARAMETERS || reason == REASON_RECOMPILE)
   {
      SaveGhostPositionsToGlobal();
      Print("チャート時間足変更・再コンパイルのためゴーストポジション情報を保存しました");
   }
   
   // 戦略システムを終了
   DeinitializeStrategySystem();
   
   // GUIを削除
   DeleteGUI();
   
   // テーブルを削除
   DeletePositionTable();

   // InfoPanelを終了
   DeinitializeInfoPanel();

   // CyberUIシステムを終了（現在無効化）
   // DeinitializeCyberUI();

   // ラインを削除
   DeleteAllLines();
   
   // エントリーポイントを削除
   DeleteAllEntryPoints();
   
   // 全てのゴーストオブジェクトの削除を追加
   DeleteAllGhostObjectsByType(OP_BUY);
   DeleteAllGhostObjectsByType(OP_SELL);
   
   // 最後に明示的にすべてのゴースト関連オブジェクトを検索して削除 (追加)
   for(int i = ObjectsTotalMQL() - 1; i >= 0; i--)
   {
      string name = ObjectNameMQL(i);
      if(StringFind(name, g_ObjectPrefix) == 0 && StringFind(name, "Ghost") >= 0)
      {
         ObjectDeleteMQL(name);
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
   
   #ifdef __MQL4__
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
   
   #ifdef __MQL5__
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(PositionSelectByTicket(ticket))
      {
         if((int)PositionGetInteger(POSITION_TYPE) == type && 
            PositionGetString(POSITION_SYMBOL) == Symbol() && 
            PositionGetInteger(POSITION_MAGIC) == MagicNumber)
         {
            // 最新のポジションを探す
            datetime openTime = (datetime)PositionGetInteger(POSITION_TIME);
            if(openTime > lastOpenTime)
            {
               lastOpenTime = openTime;
               lastLotSize = PositionGetDouble(POSITION_VOLUME);
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

      // 完全に決済された場合
      if(currentBuyCount == 0)
      {
         // 決済時間を記録
         g_BuyClosedTime = TimeCurrent();
         // 最近決済されたフラグをON
         g_BuyClosedRecently = true;

         // リセット前のゴーストカウントを保存
         int ghostCountBeforeReset = ghost_position_count(OP_BUY);

         // 同方向のゴーストをリセット
         ResetSpecificGhost(OP_BUY);

         // ゴーストもチェック：リアルもゴーストも両方0の場合のみライン削除
         if(ghostCountBeforeReset == 0)
         {
            CleanupLinesOnClose(0);
         }
      }
   }
   
   // Sell側でポジション数減少を検出
   if(currentSellCount < prevSellCount)
   {

      // 完全に決済された場合
      if(currentSellCount == 0)
      {
         // 決済時間を記録
         g_SellClosedTime = TimeCurrent();
         // 最近決済されたフラグをON
         g_SellClosedRecently = true;

         // リセット前のゴーストカウントを保存
         int ghostCountBeforeReset = ghost_position_count(OP_SELL);

         // 同方向のゴーストをリセット
         ResetSpecificGhost(OP_SELL);

         // ゴーストもチェック：リアルもゴーストも両方0の場合のみライン削除
         if(ghostCountBeforeReset == 0)
         {
            CleanupLinesOnClose(1);
         }
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
   
   // 同方向のリアルポジション数をチェック
   int operationType = (side == 0) ? OP_BUY : OP_SELL;
   int existingCount = position_count(operationType);
   
   // 戦略エントリー条件をチェック  
   if(!CheckStrategyEntryCondition(operationType)) {
      return;
   }
   
   // 決済後インターバルチェック
   if(!IsCloseIntervalElapsed(side))
   {
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
      
      // バックテスト時または自動売買が無効な場合はゴーストエントリーを実行
      if(IsTesting() || !g_AutoTrading)
      {
         
         // ナンピンスキップレベルのチェック
         int currentLevel = combined_position_count(operationType) + 1; // 現在のレベル（リアル+ゴースト）
         
         // ナンピンスキップレベル以下の場合、ゴーストエントリーを実行（SKIP_NONEの場合は実行しない）
         if(NanpinSkipLevel != SKIP_NONE && currentLevel <= (int)NanpinSkipLevel)
         {
            
            // ゴーストエントリーを実行
            double price = (operationType == OP_BUY) ? GetAskPrice() : GetBidPrice();
            double lot = g_LotTable[currentLevel - 1]; // 現在レベルのロット使用
            string comment = "戦略シグナル: " + (side == 0 ? "Buy" : "Sell") + " Lv" + IntegerToString(currentLevel);
            int entryPoint = currentLevel;
            
            bool ghostResult = ExecuteGhostEntry(operationType, price, lot, comment, entryPoint);
            
            // エントリー成功時にローソク足時間を記録
            if(ghostResult) {
               datetime currentCandleTime = iTime(Symbol(), PERIOD_CURRENT, 0);
               if(operationType == OP_BUY) {
                  g_LastBuyEntryTime = currentCandleTime;
               } else {
                  g_LastSellEntryTime = currentCandleTime;
               }
            }
         }
         else
         {
            if(NanpinSkipLevel == SKIP_NONE) {
            } else {
            }
            // スキップレベルを超えた場合またはSKIP_NONEの場合はリアルエントリーを実行
            ExecuteRealEntry(operationType, "戦略シグナル（スキップ後）");
         }
      }
      else
      {
         ExecuteRealEntry(operationType, "インジケーターシグナル");
      }
   } 
}