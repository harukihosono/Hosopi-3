//+------------------------------------------------------------------+
//|                                    Hosopi3_VolatilityFilter.mqh  |
//|                                     Copyright 2025               |
//|                                                                  |
//+------------------------------------------------------------------+

#ifndef HOSOPI3_VOLATILITY_FILTER_MQH
#define HOSOPI3_VOLATILITY_FILTER_MQH

//+------------------------------------------------------------------+
//| ボラティリティフィルター（ATRベース）                             |
//| ELDRA2から移植                                                   |
//+------------------------------------------------------------------+

#ifdef __MQL5__
// MQL5用ATRハンドル（ボラありフィルター）
int g_atrHandle = INVALID_HANDLE;
ENUM_TIMEFRAMES g_lastATRTimeframe = PERIOD_CURRENT;
int g_lastATRPeriod = 0;

// MQL5用ATRハンドル（高ボラティリティフィルター）
int g_highVolATRHandle = INVALID_HANDLE;
int g_lastHighVolATRPeriod = 0;
#endif

//+------------------------------------------------------------------+
//| ボラティリティフィルター初期化                                    |
//+------------------------------------------------------------------+
bool InitializeVolatilityFilter()
{
   if(!InpVolatilityFilterEnabled)
      return true;

#ifdef __MQL5__
   // MQL5: ATRハンドルを作成
   g_atrHandle = iATR(_Symbol, InpVolatilityATRTimeframe, InpVolatilityATRPeriod);
   if(g_atrHandle == INVALID_HANDLE)
   {
      Print("ボラティリティフィルター: ATRハンドル作成エラー");
      return false;
   }
   g_lastATRTimeframe = InpVolatilityATRTimeframe;
   g_lastATRPeriod = InpVolatilityATRPeriod;
#endif

   Print("ボラありフィルターを初期化しました (ATR期間:", InpVolatilityATRPeriod,
         " スプレッド倍率:", InpVolatilitySpreadMultiplier, ")");
   return true;
}

//+------------------------------------------------------------------+
//| 高ボラティリティフィルター初期化                                  |
//+------------------------------------------------------------------+
bool InitializeHighVolatilityFilter()
{
   if(!InpHighVolFilterEnabled)
      return true;

#ifdef __MQL5__
   g_highVolATRHandle = iATR(_Symbol, PERIOD_CURRENT, InpHighVolATRPeriod);
   if(g_highVolATRHandle == INVALID_HANDLE)
   {
      Print("高ボラフィルター: ATRハンドル作成エラー");
      return false;
   }
   g_lastHighVolATRPeriod = InpHighVolATRPeriod;
#endif

   Print("高ボラフィルターを初期化しました (ATR期間:", InpHighVolATRPeriod,
         " ATR倍率:", InpHighVolATRMultiplier, ")");
   return true;
}

//+------------------------------------------------------------------+
//| ボラティリティフィルター終了処理                                  |
//+------------------------------------------------------------------+
void DeinitializeVolatilityFilter()
{
#ifdef __MQL5__
   if(g_atrHandle != INVALID_HANDLE)
   {
      IndicatorRelease(g_atrHandle);
      g_atrHandle = INVALID_HANDLE;
   }
   if(g_highVolATRHandle != INVALID_HANDLE)
   {
      IndicatorRelease(g_highVolATRHandle);
      g_highVolATRHandle = INVALID_HANDLE;
   }
#endif
}

//+------------------------------------------------------------------+
//| ボラティリティフィルター判定（エントリー用）                      |
//| 戻り値: true = エントリー許可, false = エントリーブロック          |
//| 判定基準: ATR > (スプレッド × ボラティリティ倍率)                 |
//+------------------------------------------------------------------+
bool PassVolatilityEntryFilter()
{
   // フィルターが無効の場合は常にパス
   if(!InpVolatilityFilterEnabled)
      return true;

   double atr = 0.0;

#ifdef __MQL5__
   // パラメータが変更された場合はハンドルを再作成
   if(g_atrHandle == INVALID_HANDLE ||
      g_lastATRTimeframe != InpVolatilityATRTimeframe ||
      g_lastATRPeriod != InpVolatilityATRPeriod)
   {
      if(g_atrHandle != INVALID_HANDLE)
      {
         IndicatorRelease(g_atrHandle);
      }
      g_atrHandle = iATR(_Symbol, InpVolatilityATRTimeframe, InpVolatilityATRPeriod);
      if(g_atrHandle == INVALID_HANDLE)
      {
         Print("ボラありフィルター: ATRハンドル作成エラー");
         return false;
      }
      g_lastATRTimeframe = InpVolatilityATRTimeframe;
      g_lastATRPeriod = InpVolatilityATRPeriod;
   }

   // ATRバッファを取得
   double atrBuffer[];
   ArraySetAsSeries(atrBuffer, true);
   if(CopyBuffer(g_atrHandle, 0, 0, 1, atrBuffer) <= 0)
   {
      Print("ボラありフィルター: ATRバッファ取得エラー");
      return false;
   }
   atr = atrBuffer[0];
#else
   // MQL4: iATR関数を直接使用
   atr = iATR(_Symbol, (int)InpVolatilityATRTimeframe, InpVolatilityATRPeriod, 0);
#endif

   // スプレッドをBid-Askから計算（バックテスト対応）
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double spreadValue = ask - bid;

   // ATRがスプレッドの指定倍率を超えているかチェック
   double threshold = spreadValue * InpVolatilitySpreadMultiplier;
   bool result = (atr > threshold);

   // デバッグログ（30分に1回、状態変化時は即座に出力）
   static datetime lastLogTime = 0;
   static bool lastResult = true;
   bool logNow = false;

   // 状態が変わった時、または定期的にログ出力
   if(result != lastResult || TimeCurrent() - lastLogTime > 1800) {
      logNow = true;
      lastLogTime = TimeCurrent();
      lastResult = result;
   }

   if(logNow) {
      Print("ボラありフィルター: ATR=", DoubleToString(atr, 5),
            " Spread=", DoubleToString(spreadValue, 5),
            " Threshold(Spread×", InpVolatilitySpreadMultiplier, ")=", DoubleToString(threshold, 5),
            " → ", result ? "PASS(エントリー可)" : "BLOCK(ボラティリティ不足)");
   }

   // 5分に1回、フィルターによるブロックをログ出力
   if(!result)
   {
      static datetime lastNotifyTime = 0;
      if(TimeCurrent() - lastNotifyTime > 300)
      {
         Print("ボラありフィルター: ボラティリティ不足のためエントリーブロック (ATR=",
               DoubleToString(atr, 5), " < Threshold=", DoubleToString(threshold, 5), ")");
         lastNotifyTime = TimeCurrent();
      }
   }

   return result;  // ATR > (スプレッド × 倍率) ならtrue
}

//+------------------------------------------------------------------+
//| 高ボラティリティフィルター判定（ELDRA2 Grid Volatility Filterから移植）|
//| 戻り値: true = エントリー許可, false = エントリーブロック          |
//| 判定基準: 現在ATR ≤ (平均ATR × 倍率) なら許可                     |
//| ※ボラありフィルターの逆で、ボラティリティが高すぎる場合をブロック  |
//+------------------------------------------------------------------+
bool PassHighVolatilityFilter()
{
   // フィルターが無効の場合は常にパス
   if(!InpHighVolFilterEnabled)
      return true;

#ifdef __MQL5__
   // パラメータが変更された場合はハンドルを再作成
   if(g_highVolATRHandle == INVALID_HANDLE ||
      g_lastHighVolATRPeriod != InpHighVolATRPeriod)
   {
      if(g_highVolATRHandle != INVALID_HANDLE)
      {
         IndicatorRelease(g_highVolATRHandle);
      }
      g_highVolATRHandle = iATR(_Symbol, PERIOD_CURRENT, InpHighVolATRPeriod);
      if(g_highVolATRHandle == INVALID_HANDLE)
      {
         Print("高ボラフィルター: ATRハンドル作成エラー");
         return false;
      }
      g_lastHighVolATRPeriod = InpHighVolATRPeriod;
   }

   // ATRバッファを2本分取得
   double atr_buffer[];
   ArraySetAsSeries(atr_buffer, true);
   if(CopyBuffer(g_highVolATRHandle, 0, 0, 2, atr_buffer) <= 1)
   {
      Print("高ボラフィルター: ATRバッファ取得エラー");
      return true;  // 取得失敗時はフィルター無効
   }

   double atr = atr_buffer[0];
   double avgAtr = (atr_buffer[0] + atr_buffer[1]) / 2.0;

#else
   // MQL4の場合
   double atr = iATR(_Symbol, 0, InpHighVolATRPeriod, 0);
   double avgAtr = (iATR(_Symbol, 0, InpHighVolATRPeriod, 0) + iATR(_Symbol, 0, InpHighVolATRPeriod, 1)) / 2.0;
#endif

   double threshold = avgAtr * InpHighVolATRMultiplier;
   bool result = !(atr > threshold);  // ATRが閾値以下ならPASS

   // デバッグログ（30分に1回、状態変化時は即座に出力）
   static datetime lastHighVolLogTime = 0;
   static bool lastHighVolResult = true;

   if(result != lastHighVolResult || TimeCurrent() - lastHighVolLogTime > 1800) {
      Print("高ボラフィルター: ATR=", DoubleToString(atr, 5),
            " AvgATR=", DoubleToString(avgAtr, 5),
            " Threshold(AvgATR×", InpHighVolATRMultiplier, ")=", DoubleToString(threshold, 5),
            " → ", result ? "PASS(通常ボラティリティ)" : "BLOCK(ボラティリティ過大)");
      lastHighVolLogTime = TimeCurrent();
      lastHighVolResult = result;
   }

   // ブロック時は5分に1回通知
   if(!result)
   {
      static datetime lastHighVolNotifyTime = 0;
      if(TimeCurrent() - lastHighVolNotifyTime > 300)
      {
         Print("高ボラフィルター: ボラティリティ過大のためエントリーブロック (ATR=",
               DoubleToString(atr, 5), " > Threshold=", DoubleToString(threshold, 5), ")");
         lastHighVolNotifyTime = TimeCurrent();
      }
   }

   return result;
}

#endif // HOSOPI3_VOLATILITY_FILTER_MQH
