//+------------------------------------------------------------------+
//|                    Hosopi 3 - インジケーター計算                  |
//|                           Copyright 2025                          |
//+------------------------------------------------------------------+
#include "Hosopi3_Defines.mqh"
#include "Hosopi3_Compat.mqh"

// MQL4との互換性のためのモード定数
#ifdef __MQL5__
   #define MODE_SMA 0
   #define MODE_EMA 1
   #define MODE_SMMA 2
   #define MODE_LWMA 3
   
   #define MODE_MAIN 0
   #define MODE_UPPER 1
   #define MODE_LOWER 2
   
   #define MODE_SIGNAL 1
   
   #define MODE_PLUSDI 1
   #define MODE_MINUSDI 2
#endif

//+------------------------------------------------------------------+
//| インジケーターハンドル（MQL5用）                                  |
//+------------------------------------------------------------------+
#ifdef __MQL5__
// MA用ハンドル
int g_ma_buy_fast_handle = INVALID_HANDLE;
int g_ma_buy_slow_handle = INVALID_HANDLE;
int g_ma_sell_fast_handle = INVALID_HANDLE;
int g_ma_sell_slow_handle = INVALID_HANDLE;

// その他のインジケーターハンドル
int g_rsi_handle = INVALID_HANDLE;
int g_bb_handle = INVALID_HANDLE;
int g_stoch_handle = INVALID_HANDLE;
int g_cci_handle = INVALID_HANDLE;
int g_adx_handle = INVALID_HANDLE;
int g_envelope_handle = INVALID_HANDLE;

// インジケーター値バッファ
double g_ma_buy_fast_buffer[];
double g_ma_buy_slow_buffer[];
double g_ma_sell_fast_buffer[];
double g_ma_sell_slow_buffer[];
double g_rsi_buffer[];
double g_bb_main_buffer[];
double g_bb_upper_buffer[];
double g_bb_lower_buffer[];
double g_stoch_main_buffer[];
double g_stoch_signal_buffer[];
double g_cci_buffer[];
double g_adx_main_buffer[];
double g_adx_plusdi_buffer[];
double g_adx_minusdi_buffer[];
double g_envelope_upper_buffer[];
double g_envelope_lower_buffer[];

datetime g_last_indicator_update = 0;

//+------------------------------------------------------------------+
//| エラーハンドリング付きGetIndicatorValue関数                       |
//+------------------------------------------------------------------+
bool GetIndicatorValue(int handle, int buffer_index, int shift, double &value)
{
   if(handle == INVALID_HANDLE)
   {
      return false;
   }
   
   double buffer[1];
   if(CopyBuffer(handle, buffer_index, shift, 1, buffer) <= 0)
   {
      return false;
   }
   
   value = buffer[0];
   return true;
}
#endif

//+------------------------------------------------------------------+
//| インジケーターハンドル初期化                                      |
//+------------------------------------------------------------------+
bool InitializeIndicatorHandles()
{
#ifdef __MQL5__
    // MA戦略が有効な場合のハンドル作成
    if(MA_Entry_Strategy == MA_ENTRY_ENABLED)
    {
        g_ma_buy_fast_handle = iMA(Symbol(), MA_Timeframe, MA_Buy_Fast_Period, 0, MA_Method, MA_Price);
        g_ma_buy_slow_handle = iMA(Symbol(), MA_Timeframe, MA_Buy_Slow_Period, 0, MA_Method, MA_Price);
        g_ma_sell_fast_handle = iMA(Symbol(), MA_Timeframe, MA_Sell_Fast_Period, 0, MA_Method, MA_Price);
        g_ma_sell_slow_handle = iMA(Symbol(), MA_Timeframe, MA_Sell_Slow_Period, 0, MA_Method, MA_Price);
        
        if(g_ma_buy_fast_handle == INVALID_HANDLE || g_ma_buy_slow_handle == INVALID_HANDLE ||
           g_ma_sell_fast_handle == INVALID_HANDLE || g_ma_sell_slow_handle == INVALID_HANDLE)
        {
            Print("ERROR: MAハンドル作成失敗");
            return false;
        }
    }
    
    // RSI戦略が有効な場合のハンドル作成
    if(RSI_Entry_Strategy == RSI_ENTRY_ENABLED)
    {
        g_rsi_handle = iRSI(Symbol(), RSI_Timeframe, RSI_Period, RSI_Price);
        if(g_rsi_handle == INVALID_HANDLE)
        {
            Print("ERROR: RSIハンドル作成失敗");
            return false;
        }
    }
    
    // ボリンジャーバンド戦略が有効な場合のハンドル作成
    if(BB_Entry_Strategy == BB_ENTRY_ENABLED)
    {
        g_bb_handle = iBands(Symbol(), BB_Timeframe, BB_Period, 0, BB_Deviation, BB_Price);
        if(g_bb_handle == INVALID_HANDLE)
        {
            Print("ERROR: ボリンジャーバンドハンドル作成失敗");
            return false;
        }
    }
    
    // ストキャスティクス戦略が有効な場合のハンドル作成
    if(Stoch_Entry_Strategy == STOCH_ENTRY_ENABLED)
    {
        g_stoch_handle = iStochastic(Symbol(), Stoch_Timeframe, Stoch_K_Period, Stoch_D_Period, Stoch_Slowing, Stoch_Method, (ENUM_STO_PRICE)Stoch_Price_Field);
        if(g_stoch_handle == INVALID_HANDLE)
        {
            Print("ERROR: ストキャスティクスハンドル作成失敗");
            return false;
        }
    }
    
    // CCI戦略が有効な場合のハンドル作成
    if(CCI_Entry_Strategy == CCI_ENTRY_ENABLED)
    {
        g_cci_handle = iCCI(Symbol(), CCI_Timeframe, CCI_Period, CCI_Price);
        if(g_cci_handle == INVALID_HANDLE)
        {
            Print("ERROR: CCIハンドル作成失敗");
            return false;
        }
    }
    
    // ADX戦略が有効な場合のハンドル作成
    if(ADX_Entry_Strategy == ADX_ENTRY_ENABLED)
    {
        g_adx_handle = iADX(Symbol(), ADX_Timeframe, ADX_Period);
        if(g_adx_handle == INVALID_HANDLE)
        {
            Print("ERROR: ADXハンドル作成失敗");
            return false;
        }
    }
    
    // エンベロープハンドル作成
    if(FilterType == FILTER_ENVELOPE)
    {
        g_envelope_handle = iEnvelopes(Symbol(), FilterTimeframe, FilterPeriod, 0, FilterMethod, PRICE_CLOSE, EnvelopeDeviation);
        if(g_envelope_handle == INVALID_HANDLE)
        {
            Print("ERROR: エンベロープハンドル作成失敗");
            return false;
        }
    }
    
    // インジケーターハンドル初期化完了
    return true;
#else
    return true; // MQL4では不要
#endif
}

//+------------------------------------------------------------------+
//| エンベロープ値取得（互換性対応）                                  |
//+------------------------------------------------------------------+
double GetEnvelopeValue(int mode, int shift)
{
#ifdef __MQL4__
    return iEnvelopes(Symbol(), FilterTimeframe, FilterPeriod, 0, FilterMethod, PRICE_CLOSE, EnvelopeDeviation, mode, shift);
#else
    if(g_envelope_handle == INVALID_HANDLE)
        return 0;
    
    ArraySetAsSeries(g_envelope_upper_buffer, true);
    ArraySetAsSeries(g_envelope_lower_buffer, true);
    
    int copied_upper = CopyBuffer(g_envelope_handle, 0, shift, 1, g_envelope_upper_buffer);
    int copied_lower = CopyBuffer(g_envelope_handle, 1, shift, 1, g_envelope_lower_buffer);
    
    if(copied_upper <= 0 || copied_lower <= 0)
        return 0;
    
    switch(mode)
    {
        case MODE_UPPER:
            return g_envelope_upper_buffer[0];
        case MODE_LOWER:
            return g_envelope_lower_buffer[0];
        default:
            return 0;
    }
#endif
}

//+------------------------------------------------------------------+
//| ボリンジャーバンド値取得（互換性対応）                            |
//+------------------------------------------------------------------+
double GetBollingerValue(int mode, int shift)
{
#ifdef __MQL4__
    return iBands(Symbol(), FilterTimeframe, FilterPeriod, BollingerDeviation, 0, BollingerAppliedPrice, mode, shift);
#else
    if(g_bb_handle == INVALID_HANDLE)
        return 0;
    
    ArraySetAsSeries(g_bb_main_buffer, true);
    ArraySetAsSeries(g_bb_upper_buffer, true);
    ArraySetAsSeries(g_bb_lower_buffer, true);
    
    int copied_main = CopyBuffer(g_bb_handle, 0, shift, 1, g_bb_main_buffer);
    int copied_upper = CopyBuffer(g_bb_handle, 1, shift, 1, g_bb_upper_buffer);
    int copied_lower = CopyBuffer(g_bb_handle, 2, shift, 1, g_bb_lower_buffer);
    
    if(copied_main <= 0 || copied_upper <= 0 || copied_lower <= 0)
        return 0;
    
    switch(mode)
    {
        case MODE_MAIN:
            return g_bb_main_buffer[0];
        case MODE_UPPER:
            return g_bb_upper_buffer[0];
        case MODE_LOWER:
            return g_bb_lower_buffer[0];
        default:
            return 0;
    }
#endif
}

//+------------------------------------------------------------------+
//| インジケーター値更新（最適化版）                                  |
//+------------------------------------------------------------------+
void UpdateIndicatorValues()
{
#ifdef __MQL5__
    datetime currentTime = iTime(Symbol(), FilterTimeframe, 0);
    
    // 前回更新時刻と比較して、新しいバーの場合のみ更新
    if(g_last_indicator_update == currentTime)
        return;
    
    g_last_indicator_update = currentTime;
    
    // 必要なインジケーターのみ更新
    if(FilterType == FILTER_ENVELOPE && g_envelope_handle != INVALID_HANDLE)
    {
        ArraySetAsSeries(g_envelope_upper_buffer, true);
        ArraySetAsSeries(g_envelope_lower_buffer, true);
        
        CopyBuffer(g_envelope_handle, 0, 0, 3, g_envelope_upper_buffer);
        CopyBuffer(g_envelope_handle, 1, 0, 3, g_envelope_lower_buffer);
    }
    
    if(FilterType == FILTER_BOLLINGER && g_bb_handle != INVALID_HANDLE)
    {
        ArraySetAsSeries(g_bb_main_buffer, true);
        ArraySetAsSeries(g_bb_upper_buffer, true);
        ArraySetAsSeries(g_bb_lower_buffer, true);
        
        CopyBuffer(g_bb_handle, 0, 0, 3, g_bb_main_buffer);
        CopyBuffer(g_bb_handle, 1, 0, 3, g_bb_upper_buffer);
        CopyBuffer(g_bb_handle, 2, 0, 3, g_bb_lower_buffer);
    }
#endif
}

//+------------------------------------------------------------------+
//| インジケーターリソース解放                                        |
//+------------------------------------------------------------------+
void ReleaseIndicatorHandles()
{
#ifdef __MQL5__
    if(g_ma_buy_fast_handle != INVALID_HANDLE)
    {
        IndicatorRelease(g_ma_buy_fast_handle);
        g_ma_buy_fast_handle = INVALID_HANDLE;
    }
    if(g_ma_buy_slow_handle != INVALID_HANDLE)
    {
        IndicatorRelease(g_ma_buy_slow_handle);
        g_ma_buy_slow_handle = INVALID_HANDLE;
    }
    if(g_ma_sell_fast_handle != INVALID_HANDLE)
    {
        IndicatorRelease(g_ma_sell_fast_handle);
        g_ma_sell_fast_handle = INVALID_HANDLE;
    }
    if(g_ma_sell_slow_handle != INVALID_HANDLE)
    {
        IndicatorRelease(g_ma_sell_slow_handle);
        g_ma_sell_slow_handle = INVALID_HANDLE;
    }
    if(g_rsi_handle != INVALID_HANDLE)
    {
        IndicatorRelease(g_rsi_handle);
        g_rsi_handle = INVALID_HANDLE;
    }
    if(g_bb_handle != INVALID_HANDLE)
    {
        IndicatorRelease(g_bb_handle);
        g_bb_handle = INVALID_HANDLE;
    }
    if(g_stoch_handle != INVALID_HANDLE)
    {
        IndicatorRelease(g_stoch_handle);
        g_stoch_handle = INVALID_HANDLE;
    }
    if(g_cci_handle != INVALID_HANDLE)
    {
        IndicatorRelease(g_cci_handle);
        g_cci_handle = INVALID_HANDLE;
    }
    if(g_adx_handle != INVALID_HANDLE)
    {
        IndicatorRelease(g_adx_handle);
        g_adx_handle = INVALID_HANDLE;
    }
    if(g_envelope_handle != INVALID_HANDLE)
    {
        IndicatorRelease(g_envelope_handle);
        g_envelope_handle = INVALID_HANDLE;
    }
    
    if(g_ma_buy_fast_handle != INVALID_HANDLE)
    {
        IndicatorRelease(g_ma_buy_fast_handle);
        g_ma_buy_fast_handle = INVALID_HANDLE;
    }
    
    if(g_ma_buy_slow_handle != INVALID_HANDLE)
    {
        IndicatorRelease(g_ma_buy_slow_handle);
        g_ma_buy_slow_handle = INVALID_HANDLE;
    }
    
    if(g_ma_sell_fast_handle != INVALID_HANDLE)
    {
        IndicatorRelease(g_ma_sell_fast_handle);
        g_ma_sell_fast_handle = INVALID_HANDLE;
    }
    
    if(g_ma_sell_slow_handle != INVALID_HANDLE)
    {
        IndicatorRelease(g_ma_sell_slow_handle);
        g_ma_sell_slow_handle = INVALID_HANDLE;
    }
    
    if(g_rsi_handle != INVALID_HANDLE)
    {
        IndicatorRelease(g_rsi_handle);
        g_rsi_handle = INVALID_HANDLE;
    }
    
    if(g_stoch_handle != INVALID_HANDLE)
    {
        IndicatorRelease(g_stoch_handle);
        g_stoch_handle = INVALID_HANDLE;
    }
    
    if(g_cci_handle != INVALID_HANDLE)
    {
        IndicatorRelease(g_cci_handle);
        g_cci_handle = INVALID_HANDLE;
    }
    
    if(g_adx_handle != INVALID_HANDLE)
    {
        IndicatorRelease(g_adx_handle);
        g_adx_handle = INVALID_HANDLE;
    }
#endif
}