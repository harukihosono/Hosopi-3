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
// MQL5用ATRハンドル
int g_atrHandle = INVALID_HANDLE;
ENUM_TIMEFRAMES g_lastATRTimeframe = PERIOD_CURRENT;
int g_lastATRPeriod = 0;
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

   Print("ボラティリティフィルターを初期化しました (ATR期間:", InpVolatilityATRPeriod,
         " スプレッド倍率:", InpVolatilitySpreadMultiplier, ")");
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

   // デバッグログ（必要に応じてコメント解除）
   // static datetime lastLogTime = 0;
   // if(TimeCurrent() - lastLogTime > 3600) {  // 1時間に1回ログ出力
   //    Print("ボラありフィルター: ATR=", DoubleToString(atr, 5),
   //          " Spread=", DoubleToString(spreadValue, 5),
   //          " Threshold=", DoubleToString(threshold, 5),
   //          " Result=", result ? "PASS" : "BLOCK");
   //    lastLogTime = TimeCurrent();
   // }

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

#endif // HOSOPI3_VOLATILITY_FILTER_MQH
