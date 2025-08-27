//+------------------------------------------------------------------+
//|                  Hosopi 3 - テクニカル指標戦略                    |
//|                           Copyright 2025                          |
//+------------------------------------------------------------------+
#include "Hosopi3_Defines.mqh"
#include "Hosopi3_StrategyIndicators.mqh"

//+------------------------------------------------------------------+
//| クロスプラットフォーム対応のMA判定                                |
//+------------------------------------------------------------------+
bool CheckMASignal(int side)
{
   if(MA_Entry_Strategy == MA_ENTRY_DISABLED)
      return false;

   // MA値の取得
   double fastMA_current, slowMA_current, fastMA_prev, slowMA_prev;
   double price_current, price_prev;

#ifdef __MQL4__
   // MQL4での直接取得
   if(side == 0) // Buy
   {
      if(MA_Buy_Signal == 0)
         return false;

      fastMA_current = iMA(_Symbol, MA_Timeframe, MA_Buy_Fast_Period, 0, MA_Method, MA_Price, MA_Cross_Shift);
      slowMA_current = iMA(_Symbol, MA_Timeframe, MA_Buy_Slow_Period, 0, MA_Method, MA_Price, MA_Cross_Shift);
      fastMA_prev = iMA(_Symbol, MA_Timeframe, MA_Buy_Fast_Period, 0, MA_Method, MA_Price, MA_Cross_Shift + 1);
      slowMA_prev = iMA(_Symbol, MA_Timeframe, MA_Buy_Slow_Period, 0, MA_Method, MA_Price, MA_Cross_Shift + 1);
      price_current = iClose(_Symbol, MA_Timeframe, MA_Cross_Shift);
      price_prev = iClose(_Symbol, MA_Timeframe, MA_Cross_Shift + 1);
   }
   else // Sell
   {
      if(MA_Sell_Signal == 0)
         return false;

      fastMA_current = iMA(_Symbol, MA_Timeframe, MA_Sell_Fast_Period, 0, MA_Method, MA_Price, MA_Cross_Shift);
      slowMA_current = iMA(_Symbol, MA_Timeframe, MA_Sell_Slow_Period, 0, MA_Method, MA_Price, MA_Cross_Shift);
      fastMA_prev = iMA(_Symbol, MA_Timeframe, MA_Sell_Fast_Period, 0, MA_Method, MA_Price, MA_Cross_Shift + 1);
      slowMA_prev = iMA(_Symbol, MA_Timeframe, MA_Sell_Slow_Period, 0, MA_Method, MA_Price, MA_Cross_Shift + 1);
      price_current = iClose(_Symbol, MA_Timeframe, MA_Cross_Shift);
      price_prev = iClose(_Symbol, MA_Timeframe, MA_Cross_Shift + 1);
   }
#else
   // MQL5でのCopyBuffer使用
   if(side == 0) // Buy
   {
      if(MA_Buy_Signal == 0)
         return false;

      if(!GetIndicatorValue(g_ma_buy_fast_handle, 0, MA_Cross_Shift, fastMA_current) ||
         !GetIndicatorValue(g_ma_buy_slow_handle, 0, MA_Cross_Shift, slowMA_current) ||
         !GetIndicatorValue(g_ma_buy_fast_handle, 0, MA_Cross_Shift + 1, fastMA_prev) ||
         !GetIndicatorValue(g_ma_buy_slow_handle, 0, MA_Cross_Shift + 1, slowMA_prev))
         return false;
         
      double prices[];
      ArraySetAsSeries(prices, true);
      if(CopyClose(_Symbol, MA_Timeframe, MA_Cross_Shift, 2, prices) < 2)
         return false;
      price_current = prices[0];
      price_prev = prices[1];
   }
   else // Sell
   {
      if(MA_Sell_Signal == 0)
         return false;

      if(!GetIndicatorValue(g_ma_sell_fast_handle, 0, MA_Cross_Shift, fastMA_current) ||
         !GetIndicatorValue(g_ma_sell_slow_handle, 0, MA_Cross_Shift, slowMA_current) ||
         !GetIndicatorValue(g_ma_sell_fast_handle, 0, MA_Cross_Shift + 1, fastMA_prev) ||
         !GetIndicatorValue(g_ma_sell_slow_handle, 0, MA_Cross_Shift + 1, slowMA_prev))
         return false;
         
      double prices[];
      ArraySetAsSeries(prices, true);
      if(CopyClose(_Symbol, MA_Timeframe, MA_Cross_Shift, 2, prices) < 2)
         return false;
      price_current = prices[0];
      price_prev = prices[1];
   }
#endif

   // シグナル判定ロジック（プラットフォーム共通）
   bool signal = false;
   
   if(side == 0) // Buy
   {
      switch(MA_Buy_Signal)
      {
         case MA_GOLDEN_CROSS:
            signal = (fastMA_prev < slowMA_prev && fastMA_current > slowMA_current);
            break;
         case MA_PRICE_ABOVE_MA:
            signal = (price_current > fastMA_current);
            break;
         case MA_FAST_ABOVE_SLOW:
            signal = (fastMA_current > slowMA_current);
            break;
         case MA_DEAD_CROSS:
            signal = (fastMA_prev > slowMA_prev && fastMA_current < slowMA_current);
            break;
         case MA_PRICE_BELOW_MA:
            signal = (price_current < fastMA_current);
            break;
         case MA_FAST_BELOW_SLOW:
            signal = (fastMA_current < slowMA_current);
            break;
      }
      return (MA_Buy_Direction == TREND_FOLLOWING) ? signal : !signal;
   }
   else // Sell
   {
      switch(MA_Sell_Signal)
      {
         case MA_DEAD_CROSS:
            signal = (fastMA_prev > slowMA_prev && fastMA_current < slowMA_current);
            break;
         case MA_PRICE_BELOW_MA:
            signal = (price_current < fastMA_current);
            break;
         case MA_FAST_BELOW_SLOW:
            signal = (fastMA_current < slowMA_current);
            break;
         case MA_GOLDEN_CROSS:
            signal = (fastMA_prev < slowMA_prev && fastMA_current > slowMA_current);
            break;
         case MA_PRICE_ABOVE_MA:
            signal = (price_current > fastMA_current);
            break;
         case MA_FAST_ABOVE_SLOW:
            signal = (fastMA_current > slowMA_current);
            break;
      }
      return (MA_Sell_Direction == TREND_FOLLOWING) ? signal : !signal;
   }
}

//+------------------------------------------------------------------+
//| クロスプラットフォーム対応のRSI判定                               |
//+------------------------------------------------------------------+
bool CheckRSISignal(int side)
{
   if(RSI_Entry_Strategy == RSI_ENTRY_DISABLED)
      return false;

   double rsi_current, rsi_prev;

#ifdef __MQL4__
   // MQL4での直接取得
   rsi_current = iRSI(_Symbol, RSI_Timeframe, RSI_Period, RSI_Price, RSI_Signal_Shift);
   rsi_prev = iRSI(_Symbol, RSI_Timeframe, RSI_Period, RSI_Price, RSI_Signal_Shift + 1);
#else
   // MQL5でのCopyBuffer使用
   if(!GetIndicatorValue(g_rsi_handle, 0, RSI_Signal_Shift, rsi_current) ||
      !GetIndicatorValue(g_rsi_handle, 0, RSI_Signal_Shift + 1, rsi_prev))
      return false;
#endif

   // シグナル判定ロジック（プラットフォーム共通）
   bool signal = false;
   
   if(side == 0) // Buy
   {
      if(RSI_Buy_Signal == 0)
         return false;
         
      switch(RSI_Buy_Signal)
      {
         case RSI_OVERSOLD:
            signal = (rsi_current < RSI_Oversold);
            break;
         case RSI_OVERSOLD_EXIT:
            signal = (rsi_prev < RSI_Oversold && rsi_current >= RSI_Oversold);
            break;
         case RSI_OVERBOUGHT:
            signal = (rsi_current > RSI_Overbought);
            break;
         case RSI_OVERBOUGHT_EXIT:
            signal = (rsi_prev > RSI_Overbought && rsi_current <= RSI_Overbought);
            break;
      }
      return (RSI_Buy_Direction == TREND_FOLLOWING) ? signal : !signal;
   }
   else // Sell
   {
      if(RSI_Sell_Signal == 0)
         return false;
         
      switch(RSI_Sell_Signal)
      {
         case RSI_OVERBOUGHT:
            signal = (rsi_current > RSI_Overbought);
            break;
         case RSI_OVERBOUGHT_EXIT:
            signal = (rsi_prev > RSI_Overbought && rsi_current <= RSI_Overbought);
            break;
         case RSI_OVERSOLD:
            signal = (rsi_current < RSI_Oversold);
            break;
         case RSI_OVERSOLD_EXIT:
            signal = (rsi_prev < RSI_Oversold && rsi_current >= RSI_Oversold);
            break;
      }
      return (RSI_Sell_Direction == TREND_FOLLOWING) ? signal : !signal;
   }
}

//+------------------------------------------------------------------+
//| クロスプラットフォーム対応のボリンジャーバンド判定                |
//+------------------------------------------------------------------+
bool CheckBollingerSignal(int side)
{
   if(BB_Entry_Strategy == BB_ENTRY_DISABLED)
      return false;

   double middle, upper, lower, close_current, close_prev;

#ifdef __MQL4__
   // MQL4での直接取得
   middle = iBands(_Symbol, BB_Timeframe, BB_Period, BB_Deviation, 0, BB_Price, MODE_MAIN, BB_Signal_Shift);
   upper = iBands(_Symbol, BB_Timeframe, BB_Period, BB_Deviation, 0, BB_Price, MODE_UPPER, BB_Signal_Shift);
   lower = iBands(_Symbol, BB_Timeframe, BB_Period, BB_Deviation, 0, BB_Price, MODE_LOWER, BB_Signal_Shift);
   close_current = iClose(_Symbol, BB_Timeframe, BB_Signal_Shift);
   close_prev = iClose(_Symbol, BB_Timeframe, BB_Signal_Shift + 1);
#else
   // MQL5でのCopyBuffer使用
   if(!GetIndicatorValue(g_bb_handle, 0, BB_Signal_Shift, middle) ||
      !GetIndicatorValue(g_bb_handle, 1, BB_Signal_Shift, upper) ||
      !GetIndicatorValue(g_bb_handle, 2, BB_Signal_Shift, lower))
      return false;
      
   double prices[];
   ArraySetAsSeries(prices, true);
   if(CopyClose(_Symbol, BB_Timeframe, BB_Signal_Shift, 2, prices) < 2)
      return false;
   close_current = prices[0];
   close_prev = prices[1];
#endif

   // シグナル判定ロジック（プラットフォーム共通）
   bool signal = false;
   
   if(side == 0) // Buy
   {
      if(BB_Buy_Signal == 0)
         return false;
         
      switch(BB_Buy_Signal)
      {
         case BB_TOUCH_LOWER:
            signal = (close_prev <= lower && close_current > close_prev);
            break;
         case BB_BREAK_LOWER:
            signal = (close_prev > lower && close_current < lower);
            break;
         case BB_TOUCH_UPPER:
            signal = (close_prev >= upper && close_current < close_prev);
            break;
         case BB_BREAK_UPPER:
            signal = (close_prev < upper && close_current > upper);
            break;
      }
      return (BB_Buy_Direction == TREND_FOLLOWING) ? signal : !signal;
   }
   else // Sell
   {
      if(BB_Sell_Signal == 0)
         return false;
         
      switch(BB_Sell_Signal)
      {
         case BB_TOUCH_UPPER:
            signal = (close_prev >= upper && close_current < close_prev);
            break;
         case BB_BREAK_UPPER:
            signal = (close_prev < upper && close_current > upper);
            break;
         case BB_TOUCH_LOWER:
            signal = (close_prev <= lower && close_current > close_prev);
            break;
         case BB_BREAK_LOWER:
            signal = (close_prev > lower && close_current < lower);
            break;
      }
      return (BB_Sell_Direction == TREND_FOLLOWING) ? signal : !signal;
   }
}

//+------------------------------------------------------------------+
//| RCI（ランク相関係数）の計算 - クロスプラットフォーム対応          |
//+------------------------------------------------------------------+
double CalculateRCI(int period, int shift, ENUM_TIMEFRAMES timeframe)
{
   // 計算するために十分なヒストリカルデータがあることを確認
   int totalBars = iBars(_Symbol, timeframe);
   
   if(totalBars < period + shift)
      return 0;

   // サイズを確保した動的配列を使用
   double prices[];
   double price_ranks[];
   double time_ranks[];

   // 配列のサイズを設定
   ArrayResize(prices, period);
   ArrayResize(price_ranks, period);
   ArrayResize(time_ranks, period);

   // 配列を初期化
   ArrayInitialize(prices, 0);
   ArrayInitialize(price_ranks, 0);
   ArrayInitialize(time_ranks, 0);

   // 価格データを取得
#ifdef __MQL4__
   for(int i = 0; i < period; i++)
   {
      prices[i] = iClose(_Symbol, timeframe, i + shift);
   }
#else
   double temp_prices[];
   ArraySetAsSeries(temp_prices, true);
   if(CopyClose(_Symbol, timeframe, shift, period, temp_prices) < period)
      return 0;
   for(int i = 0; i < period; i++)
   {
      prices[i] = temp_prices[i];
   }
#endif

   // 価格ランクを計算
   for(int i = 0; i < period; i++)
   {
      double rank = 1;
      for(int j = 0; j < period; j++)
      {
         if(prices[j] > prices[i])
            rank++;
      }
      price_ranks[i] = rank;
   }

   // 時間ランクを計算（最新から過去への順）
   for(int i = 0; i < period; i++)
   {
      time_ranks[i] = i + 1;
   }

   // D^2を計算
   double d_squared_sum = 0;
   for(int i = 0; i < period; i++)
   {
      d_squared_sum += MathPow(price_ranks[i] - time_ranks[i], 2);
   }

   // RCIを計算
   double rci = (1.0 - (6.0 * d_squared_sum / (period * (period * period - 1)))) * 100;

   return rci;
}

//+------------------------------------------------------------------+
//| クロスプラットフォーム対応のRCI判定                               |
//+------------------------------------------------------------------+
bool CheckRCISignal(int side)
{
   if(RCI_Entry_Strategy == RCI_ENTRY_DISABLED)
      return false;

   // RCIの計算
   double rci_current = CalculateRCI(RCI_Period, RCI_Signal_Shift, RCI_Timeframe);
   double rci_prev = CalculateRCI(RCI_Period, RCI_Signal_Shift + 1, RCI_Timeframe);
   double rci_mid_current = CalculateRCI(RCI_MidTerm_Period, RCI_Signal_Shift, RCI_Timeframe);
   double rci_long_current = CalculateRCI(RCI_LongTerm_Period, RCI_Signal_Shift, RCI_Timeframe);

   // シグナル判定ロジック
   bool signal = false;
   
   if(side == 0) // Buy
   {
      if(RCI_Buy_Signal == 0)
         return false;
         
      switch(RCI_Buy_Signal)
      {
         case RCI_BELOW_MINUS_THRESHOLD:
            signal = (rci_current < -RCI_Threshold);
            break;
         case RCI_RISING_FROM_BOTTOM:
            signal = (rci_prev < -RCI_Threshold && rci_current > rci_prev &&
                     rci_mid_current < -50 && rci_long_current < -50);
            break;
         case RCI_ABOVE_PLUS_THRESHOLD:
            signal = (rci_current > RCI_Threshold);
            break;
         case RCI_FALLING_FROM_PEAK:
            signal = (rci_prev > RCI_Threshold && rci_current < rci_prev &&
                     rci_mid_current > 50 && rci_long_current > 50);
            break;
      }
      return (RCI_Buy_Direction == TREND_FOLLOWING) ? signal : !signal;
   }
   else // Sell
   {
      if(RCI_Sell_Signal == 0)
         return false;
         
      switch(RCI_Sell_Signal)
      {
         case RCI_ABOVE_PLUS_THRESHOLD:
            signal = (rci_current > RCI_Threshold);
            break;
         case RCI_FALLING_FROM_PEAK:
            signal = (rci_prev > RCI_Threshold && rci_current < rci_prev &&
                     rci_mid_current > 50 && rci_long_current > 50);
            break;
         case RCI_BELOW_MINUS_THRESHOLD:
            signal = (rci_current < -RCI_Threshold);
            break;
         case RCI_RISING_FROM_BOTTOM:
            signal = (rci_prev < -RCI_Threshold && rci_current > rci_prev &&
                     rci_mid_current < -50 && rci_long_current < -50);
            break;
      }
      return (RCI_Sell_Direction == TREND_FOLLOWING) ? signal : !signal;
   }
}

//+------------------------------------------------------------------+
//| クロスプラットフォーム対応のストキャスティクス判定                |
//+------------------------------------------------------------------+
bool CheckStochasticSignal(int side)
{
   if(Stoch_Entry_Strategy == STOCH_ENTRY_DISABLED)
      return false;

   double k_current, k_prev, d_current, d_prev;

#ifdef __MQL4__
   // MQL4での直接取得
   k_current = iStochastic(_Symbol, Stoch_Timeframe, Stoch_K_Period, Stoch_D_Period, Stoch_Slowing,
                          Stoch_Method, Stoch_Price_Field, MODE_MAIN, Stoch_Signal_Shift);
   k_prev = iStochastic(_Symbol, Stoch_Timeframe, Stoch_K_Period, Stoch_D_Period, Stoch_Slowing,
                       Stoch_Method, Stoch_Price_Field, MODE_MAIN, Stoch_Signal_Shift + 1);
   d_current = iStochastic(_Symbol, Stoch_Timeframe, Stoch_K_Period, Stoch_D_Period, Stoch_Slowing,
                          Stoch_Method, Stoch_Price_Field, MODE_SIGNAL, Stoch_Signal_Shift);
   d_prev = iStochastic(_Symbol, Stoch_Timeframe, Stoch_K_Period, Stoch_D_Period, Stoch_Slowing,
                       Stoch_Method, Stoch_Price_Field, MODE_SIGNAL, Stoch_Signal_Shift + 1);
#else
   // MQL5でのCopyBuffer使用
   if(!GetIndicatorValue(g_stoch_handle, 0, Stoch_Signal_Shift, k_current) ||
      !GetIndicatorValue(g_stoch_handle, 0, Stoch_Signal_Shift + 1, k_prev) ||
      !GetIndicatorValue(g_stoch_handle, 1, Stoch_Signal_Shift, d_current) ||
      !GetIndicatorValue(g_stoch_handle, 1, Stoch_Signal_Shift + 1, d_prev))
      return false;
#endif

   // シグナル判定ロジック（プラットフォーム共通）
   bool signal = false;
   
   if(side == 0) // Buy
   {
      if(Stoch_Buy_Signal == 0)
         return false;
         
      switch(Stoch_Buy_Signal)
      {
         case STOCH_OVERSOLD:
            signal = (k_current < Stoch_Oversold);
            break;
         case STOCH_K_CROSS_D_OVERSOLD:
            signal = (k_prev < d_prev && k_current > d_current && k_prev < Stoch_Oversold);
            break;
         case STOCH_OVERSOLD_EXIT:
            signal = (k_prev < Stoch_Oversold && k_current >= Stoch_Oversold);
            break;
         case STOCH_OVERBOUGHT:
            signal = (k_current > Stoch_Overbought);
            break;
         case STOCH_K_CROSS_D_OVERBOUGHT:
            signal = (k_prev > d_prev && k_current < d_current && k_prev > Stoch_Overbought);
            break;
         case STOCH_OVERBOUGHT_EXIT:
            signal = (k_prev > Stoch_Overbought && k_current <= Stoch_Overbought);
            break;
      }
      return (Stoch_Buy_Direction == TREND_FOLLOWING) ? signal : !signal;
   }
   else // Sell
   {
      if(Stoch_Sell_Signal == 0)
         return false;
         
      switch(Stoch_Sell_Signal)
      {
         case STOCH_OVERBOUGHT:
            signal = (k_current > Stoch_Overbought);
            break;
         case STOCH_K_CROSS_D_OVERBOUGHT:
            signal = (k_prev > d_prev && k_current < d_current && k_prev > Stoch_Overbought);
            break;
         case STOCH_OVERBOUGHT_EXIT:
            signal = (k_prev > Stoch_Overbought && k_current <= Stoch_Overbought);
            break;
         case STOCH_OVERSOLD:
            signal = (k_current < Stoch_Oversold);
            break;
         case STOCH_K_CROSS_D_OVERSOLD:
            signal = (k_prev < d_prev && k_current > d_current && k_prev < Stoch_Oversold);
            break;
         case STOCH_OVERSOLD_EXIT:
            signal = (k_prev < Stoch_Oversold && k_current >= Stoch_Oversold);
            break;
      }
      return (Stoch_Sell_Direction == TREND_FOLLOWING) ? signal : !signal;
   }
}

//+------------------------------------------------------------------+
//| クロスプラットフォーム対応のCCI判定                               |
//+------------------------------------------------------------------+
bool CheckCCISignal(int side)
{
   if(CCI_Entry_Strategy == CCI_ENTRY_DISABLED)
      return false;

   double cci_current, cci_prev;

#ifdef __MQL4__
   // MQL4での直接取得
   cci_current = iCCI(_Symbol, CCI_Timeframe, CCI_Period, CCI_Price, CCI_Signal_Shift);
   cci_prev = iCCI(_Symbol, CCI_Timeframe, CCI_Period, CCI_Price, CCI_Signal_Shift + 1);
#else
   // MQL5でのCopyBuffer使用
   if(!GetIndicatorValue(g_cci_handle, 0, CCI_Signal_Shift, cci_current) ||
      !GetIndicatorValue(g_cci_handle, 0, CCI_Signal_Shift + 1, cci_prev))
      return false;
#endif

   // シグナル判定ロジック（プラットフォーム共通）
   bool signal = false;
   
   if(side == 0) // Buy
   {
      if(CCI_Buy_Signal == 0)
         return false;
         
      switch(CCI_Buy_Signal)
      {
         case CCI_OVERSOLD:
            signal = (cci_current < CCI_Oversold);
            break;
         case CCI_OVERSOLD_EXIT:
            signal = (cci_prev < CCI_Oversold && cci_current >= CCI_Oversold);
            break;
         case CCI_OVERBOUGHT:
            signal = (cci_current > CCI_Overbought);
            break;
         case CCI_OVERBOUGHT_EXIT:
            signal = (cci_prev > CCI_Overbought && cci_current <= CCI_Overbought);
            break;
      }
      return (CCI_Buy_Direction == TREND_FOLLOWING) ? signal : !signal;
   }
   else // Sell
   {
      if(CCI_Sell_Signal == 0)
         return false;
         
      switch(CCI_Sell_Signal)
      {
         case CCI_OVERBOUGHT:
            signal = (cci_current > CCI_Overbought);
            break;
         case CCI_OVERBOUGHT_EXIT:
            signal = (cci_prev > CCI_Overbought && cci_current <= CCI_Overbought);
            break;
         case CCI_OVERSOLD:
            signal = (cci_current < CCI_Oversold);
            break;
         case CCI_OVERSOLD_EXIT:
            signal = (cci_prev < CCI_Oversold && cci_current >= CCI_Oversold);
            break;
      }
      return (CCI_Sell_Direction == TREND_FOLLOWING) ? signal : !signal;
   }
}

//+------------------------------------------------------------------+
//| クロスプラットフォーム対応のADX判定                               |
//+------------------------------------------------------------------+
bool CheckADXSignal(int side)
{
   if(ADX_Entry_Strategy == ADX_ENTRY_DISABLED)
      return false;

   double adx_current, plus_di_current, minus_di_current;
   double plus_di_prev, minus_di_prev;

#ifdef __MQL4__
   // MQL4での直接取得
   adx_current = iADX(_Symbol, ADX_Timeframe, ADX_Period, ADX_Price, MODE_MAIN, ADX_Signal_Shift);
   plus_di_current = iADX(_Symbol, ADX_Timeframe, ADX_Period, ADX_Price, MODE_PLUSDI, ADX_Signal_Shift);
   minus_di_current = iADX(_Symbol, ADX_Timeframe, ADX_Period, ADX_Price, MODE_MINUSDI, ADX_Signal_Shift);
   plus_di_prev = iADX(_Symbol, ADX_Timeframe, ADX_Period, ADX_Price, MODE_PLUSDI, ADX_Signal_Shift + 1);
   minus_di_prev = iADX(_Symbol, ADX_Timeframe, ADX_Period, ADX_Price, MODE_MINUSDI, ADX_Signal_Shift + 1);
#else
   // MQL5でのCopyBuffer使用
   if(!GetIndicatorValue(g_adx_handle, 0, ADX_Signal_Shift, adx_current) ||
      !GetIndicatorValue(g_adx_handle, 1, ADX_Signal_Shift, plus_di_current) ||
      !GetIndicatorValue(g_adx_handle, 2, ADX_Signal_Shift, minus_di_current) ||
      !GetIndicatorValue(g_adx_handle, 1, ADX_Signal_Shift + 1, plus_di_prev) ||
      !GetIndicatorValue(g_adx_handle, 2, ADX_Signal_Shift + 1, minus_di_prev))
      return false;
#endif

   // シグナル判定ロジック（プラットフォーム共通）
   bool signal = false;
   
   if(side == 0) // Buy
   {
      if(ADX_Buy_Signal == 0)
         return false;
         
      switch(ADX_Buy_Signal)
      {
         case ADX_PLUS_DI_CROSS_MINUS_DI:
            signal = (plus_di_prev <= minus_di_prev && plus_di_current > minus_di_current);
            break;
         case ADX_STRONG_TREND_PLUS_DI:
            signal = (adx_current > ADX_Threshold && plus_di_current > minus_di_current);
            break;
         case ADX_MINUS_DI_CROSS_PLUS_DI:
            signal = (minus_di_prev <= plus_di_prev && minus_di_current > plus_di_current);
            break;
         case ADX_STRONG_TREND_MINUS_DI:
            signal = (adx_current > ADX_Threshold && minus_di_current > plus_di_current);
            break;
      }
      return (ADX_Buy_Direction == TREND_FOLLOWING) ? signal : !signal;
   }
   else // Sell
   {
      if(ADX_Sell_Signal == 0)
         return false;
         
      switch(ADX_Sell_Signal)
      {
         case ADX_MINUS_DI_CROSS_PLUS_DI:
            signal = (minus_di_prev <= plus_di_prev && minus_di_current > plus_di_current);
            break;
         case ADX_STRONG_TREND_MINUS_DI:
            signal = (adx_current > ADX_Threshold && minus_di_current > plus_di_current);
            break;
         case ADX_PLUS_DI_CROSS_MINUS_DI:
            signal = (plus_di_prev <= minus_di_prev && plus_di_current > minus_di_current);
            break;
         case ADX_STRONG_TREND_PLUS_DI:
            signal = (adx_current > ADX_Threshold && plus_di_current > minus_di_current);
            break;
      }
      return (ADX_Sell_Direction == TREND_FOLLOWING) ? signal : !signal;
   }
}

//+------------------------------------------------------------------+
//| テクニカルフィルターチェック                                      |
//+------------------------------------------------------------------+
bool CheckTechnicalFilter(int operationType)
{
    if(FilterType == FILTER_NONE)
        return true;
    
    double currentPrice = (operationType == OP_BUY) ? GetAskPrice() : GetBidPrice();
    double targetValue = 0;
    bool conditionMet = false;
    
    // インジケーター値を更新
    UpdateIndicatorValues();
    
    switch(FilterType)
    {
        case FILTER_ENVELOPE:
            if(operationType == OP_BUY)
            {
                switch(BuyBandTarget)
                {
                    case TARGET_UPPER:
                        targetValue = GetEnvelopeValue(MODE_UPPER, FilterShift);
                        break;
                    case TARGET_LOWER:
                        targetValue = GetEnvelopeValue(MODE_LOWER, FilterShift);
                        break;
                }
                
                switch(BuyBandCondition)
                {
                    case PRICE_ABOVE:
                        conditionMet = (currentPrice > targetValue);
                        break;
                    case PRICE_BELOW:
                        conditionMet = (currentPrice < targetValue);
                        break;
                    case PRICE_TOUCH:
                        conditionMet = (MathAbs(currentPrice - targetValue) < (Point * 5));
                        break;
                }
            }
            else // SELL
            {
                switch(SellBandTarget)
                {
                    case TARGET_UPPER:
                        targetValue = GetEnvelopeValue(MODE_UPPER, FilterShift);
                        break;
                    case TARGET_LOWER:
                        targetValue = GetEnvelopeValue(MODE_LOWER, FilterShift);
                        break;
                }
                
                switch(SellBandCondition)
                {
                    case PRICE_ABOVE:
                        conditionMet = (currentPrice > targetValue);
                        break;
                    case PRICE_BELOW:
                        conditionMet = (currentPrice < targetValue);
                        break;
                    case PRICE_TOUCH:
                        conditionMet = (MathAbs(currentPrice - targetValue) < (Point * 5));
                        break;
                }
            }
            break;
            
        case FILTER_BOLLINGER:
            if(operationType == OP_BUY)
            {
                switch(BuyBandTarget)
                {
                    case TARGET_UPPER:
                        targetValue = GetBollingerValue(MODE_UPPER, FilterShift);
                        break;
                    case TARGET_LOWER:
                        targetValue = GetBollingerValue(MODE_LOWER, FilterShift);
                        break;
                }
                
                switch(BuyBandCondition)
                {
                    case PRICE_ABOVE:
                        conditionMet = (currentPrice > targetValue);
                        break;
                    case PRICE_BELOW:
                        conditionMet = (currentPrice < targetValue);
                        break;
                    case PRICE_TOUCH:
                        conditionMet = (MathAbs(currentPrice - targetValue) < (Point * 5));
                        break;
                }
            }
            else // SELL
            {
                switch(SellBandTarget)
                {
                    case TARGET_UPPER:
                        targetValue = GetBollingerValue(MODE_UPPER, FilterShift);
                        break;
                    case TARGET_LOWER:
                        targetValue = GetBollingerValue(MODE_LOWER, FilterShift);
                        break;
                }
                
                switch(SellBandCondition)
                {
                    case PRICE_ABOVE:
                        conditionMet = (currentPrice > targetValue);
                        break;
                    case PRICE_BELOW:
                        conditionMet = (currentPrice < targetValue);
                        break;
                    case PRICE_TOUCH:
                        conditionMet = (MathAbs(currentPrice - targetValue) < (Point * 5));
                        break;
                }
            }
            break;
            
        default:
            conditionMet = true;
            break;
    }
    
    return conditionMet;
}

//+------------------------------------------------------------------+
//| 統合エントリーシグナルチェック                                    |
//+------------------------------------------------------------------+
bool CheckEntrySignal(int operationType)
{
    // 基本的なマーケット条件チェック
    if(!IsMarketOpen())
        return false;
    
    // スプレッドチェック
    int currentSpread = (int)((GetAskPrice() - GetBidPrice()) / Point);
    if(currentSpread > MaxSpreadPoints)
        return false;
    
    // テクニカルフィルターチェック
    if(!CheckTechnicalFilter(operationType))
        return false;
    
    return true;
}

//+------------------------------------------------------------------+
//| マーケット開場チェック                                            |
//+------------------------------------------------------------------+
bool IsMarketOpen()
{
    // 基本的な市場時間チェック
    datetime currentTime = TimeCurrent();
    
    #ifdef __MQL4__
        int dayOfWeek = TimeDayOfWeek(currentTime);
    #else
        MqlDateTime dt;
        TimeToStruct(currentTime, dt);
        int dayOfWeek = dt.day_of_week;
    #endif
    
    // 土日は閉場
    if(dayOfWeek == 0 || dayOfWeek == 6)
        return false;
    
    return true;
}

//+------------------------------------------------------------------+
//| エントリー可否の総合判定                                          |
//+------------------------------------------------------------------+
bool CanEntry(int operationType)
{
    // 有効証拠金チェック
    if(EquityControl_Active == ON_MODE)
    {
        if(AccountEquity() < MinimumEquity)
        {
            Print("有効証拠金不足: ", AccountEquity(), " < ", MinimumEquity);
            return false;
        }
    }
    
    // エントリーシグナルチェック
    if(!CheckEntrySignal(operationType))
        return false;
    
    return true;
}