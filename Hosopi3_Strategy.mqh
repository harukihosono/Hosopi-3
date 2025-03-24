//+------------------------------------------------------------------+
//|                 Hosopi 3 - 戦略管理関数                         |
//|                        Copyright 2025                            |
//+------------------------------------------------------------------+
#include "Hosopi3_Defines.mqh"
#include "Hosopi3_Trading.mqh"
#include "Hosopi3_Utils.mqh"

// ======== 戦略関連の定義 ========
// 戦略タイプの列挙型
enum STRATEGY_TYPE {
   STRATEGY_DISABLED = 0,        // 無効
   STRATEGY_TIME = 1,            // 時間エントリー
   STRATEGY_MA_CROSS = 2,        // MA クロス
   STRATEGY_RSI = 3,             // RSI
   STRATEGY_BOLLINGER = 4,       // ボリンジャーバンド
   STRATEGY_RCI = 5,             // RCI
   STRATEGY_STOCHASTIC = 6,      // ストキャスティクス
   STRATEGY_CCI = 7,             // CCI
   STRATEGY_ADX = 8              // ADX / DMI
};

// MAシグナルタイプのenum定義
enum MA_STRATEGY_TYPE {
   MA_DISABLED = 0,               // 無効
   MA_GOLDEN_CROSS = 1,           // ゴールデンクロスでエントリー(逆張り)
   MA_PRICE_ABOVE_MA = 2,         // 価格がMA上でエントリー(順張り)
   MA_FAST_ABOVE_SLOW = 3,        // 短期MAが長期MA上でエントリー(順張り)
   MA_DEAD_CROSS = 4,             // デッドクロスでエントリー(順張り)
   MA_PRICE_BELOW_MA = 5          // 価格がMA下でエントリー(逆張り)
};

// RSIシグナルタイプのenum定義
enum RSI_STRATEGY_TYPE {
   RSI_DISABLED = 0,              // 無効
   RSI_OVERSOLD = 1,              // 売られすぎ（RSI<30）でエントリー(逆張り)
   RSI_OVERSOLD_EXIT = 2,         // 売られすぎから回復でエントリー(逆張り)
   RSI_OVERBOUGHT = 3,            // 買われすぎ（RSI>70）でエントリー(順張り)
   RSI_OVERBOUGHT_EXIT = 4        // 買われすぎから下落でエントリー(順張り)
};

// ボリンジャーバンドシグナルタイプ
enum BB_STRATEGY_TYPE {
   BB_DISABLED = 0,               // 無効
   BB_TOUCH_LOWER = 1,            // 下限バンドタッチでエントリー(逆張り)
   BB_BREAK_UPPER = 2,            // 上限バンド突破でエントリー(順張り)
   BB_TOUCH_UPPER = 3,            // 上限バンドタッチでエントリー(順張り)
   BB_BREAK_LOWER = 4             // 下限バンド突破でエントリー(逆張り)
};

// ストキャスティクスシグナルタイプ
enum STOCH_STRATEGY_TYPE {
   STOCH_DISABLED = 0,                 // 無効
   STOCH_OVERSOLD = 1,                 // 売られすぎでエントリー(逆張り)
   STOCH_K_CROSS_D_OVERSOLD = 2,       // %Kが%Dを上抜け（売られすぎ）(逆張り)
   STOCH_OVERSOLD_EXIT = 3,            // 売られすぎから脱出(逆張り)
   STOCH_OVERBOUGHT = 4,               // 買われすぎでエントリー(順張り)
   STOCH_K_CROSS_D_OVERBOUGHT = 5,     // %Kが%Dを下抜け（買われすぎ）(順張り)
   STOCH_OVERBOUGHT_EXIT = 6           // 買われすぎから脱出(順張り)
};

// CCIシグナルタイプ
enum CCI_STRATEGY_TYPE {
   CCI_DISABLED = 0,              // 無効
   CCI_OVERSOLD = 1,              // 売られすぎでエントリー(逆張り)
   CCI_OVERSOLD_EXIT = 2,         // 売られすぎから回復(逆張り)
   CCI_OVERBOUGHT = 3,            // 買われすぎでエントリー(順張り)
   CCI_OVERBOUGHT_EXIT = 4        // 買われすぎから下落(順張り)
};

// ADXシグナルタイプ
enum ADX_STRATEGY_TYPE {
   ADX_DISABLED = 0,                    // 無効
   ADX_PLUS_DI_CROSS_MINUS_DI = 1,      // +DIが-DIを上抜け(順張り)
   ADX_STRONG_TREND_PLUS_DI = 2,        // 強いトレンドで+DI > -DI(順張り)
   ADX_MINUS_DI_CROSS_PLUS_DI = 3,      // -DIが+DIを上抜け(逆張り)
   ADX_STRONG_TREND_MINUS_DI = 4        // 強いトレンドで-DI > +DI(逆張り)
};

// RCIシグナルタイプ
enum RCI_STRATEGY_TYPE {
   RCI_DISABLED = 0,                    // 無効
   RCI_BELOW_MINUS_THRESHOLD = 1,       // -しきい値以下でエントリー(逆張り)
   RCI_RISING_FROM_BOTTOM = 2,          // -しきい値から上昇(逆張り)
   RCI_ABOVE_PLUS_THRESHOLD = 3,        // +しきい値以上でエントリー(順張り)
   RCI_FALLING_FROM_PEAK = 4            // +しきい値から下落(順張り)
};

//+------------------------------------------------------------------+
//| 戦略関連の設定変数                                               |
//+------------------------------------------------------------------+
// ==== MA クロス設定 ====
sinput string Comment_MA_Cross_Entry = ""; //+--- MAクロスエントリー設定 ---+
input STRATEGY_TYPE MA_Cross_Strategy = STRATEGY_DISABLED; // MAクロス戦略
input MA_STRATEGY_TYPE MA_Buy_Signal = MA_GOLDEN_CROSS; // MA Buy シグナル
input MA_STRATEGY_TYPE MA_Sell_Signal = MA_DEAD_CROSS; // MA Sell シグナル
input int MA_Buy_Fast_Period = 5;               // Buy: 短期MA期間
input int MA_Buy_Slow_Period = 20;              // Buy: 長期MA期間
input int MA_Sell_Fast_Period = 5;              // Sell: 短期MA期間
input int MA_Sell_Slow_Period = 20;             // Sell: 長期MA期間
input int MA_Method = MODE_SMA;                 // MA計算方法
input int MA_Price = PRICE_CLOSE;               // MA適用価格
input int MA_Cross_Shift = 1;                   // シグナル確認シフト

// ==== RSI設定 ====
sinput string Comment_RSI_Entry = ""; //+--- RSIエントリー設定 ---+
input STRATEGY_TYPE RSI_Strategy = STRATEGY_DISABLED; // RSI戦略
input RSI_STRATEGY_TYPE RSI_Buy_Signal = RSI_OVERSOLD; // RSI Buy シグナル
input RSI_STRATEGY_TYPE RSI_Sell_Signal = RSI_OVERBOUGHT; // RSI Sell シグナル
input int RSI_Period = 14;                      // RSI期間
input int RSI_Price = PRICE_CLOSE;              // RSI適用価格
input int RSI_Overbought = 70;                  // 買われすぎレベル
input int RSI_Oversold = 30;                    // 売られすぎレベル
input int RSI_Signal_Shift = 1;                 // シグナル確認シフト

// ==== ボリンジャーバンド設定 ====
sinput string Comment_BB_Entry = ""; //+--- ボリンジャーバンドエントリー設定 ---+
input STRATEGY_TYPE BB_Strategy = STRATEGY_DISABLED; // ボリンジャーバンド戦略
input BB_STRATEGY_TYPE BB_Buy_Signal = BB_TOUCH_LOWER; // BB Buy シグナル
input BB_STRATEGY_TYPE BB_Sell_Signal = BB_TOUCH_UPPER; // BB Sell シグナル
input int BB_Period = 20;                       // ボリンジャーバンド期間
input double BB_Deviation = 2.0;                // 標準偏差
input int BB_Price = PRICE_CLOSE;               // 適用価格
input int BB_Signal_Shift = 1;                  // シグナル確認シフト

// ==== ストキャスティクス設定 ====
sinput string Comment_Stochastic_Entry = ""; //+--- ストキャスティクスエントリー設定 ---+
input STRATEGY_TYPE Stochastic_Strategy = STRATEGY_DISABLED; // ストキャスティクス戦略
input STOCH_STRATEGY_TYPE Stochastic_Buy_Signal = STOCH_OVERSOLD; // Stoch Buy シグナル
input STOCH_STRATEGY_TYPE Stochastic_Sell_Signal = STOCH_OVERBOUGHT; // Stoch Sell シグナル
input int Stochastic_K_Period = 5;             // %K期間
input int Stochastic_D_Period = 3;             // %D期間
input int Stochastic_Slowing = 3;              // スローイング
input int Stochastic_Method = MODE_SMA;        // 計算方法
input int Stochastic_Price_Field = 0;          // 価格フィールド
input int Stochastic_Overbought = 80;          // 買われすぎレベル
input int Stochastic_Oversold = 20;            // 売られすぎレベル
input int Stochastic_Signal_Shift = 1;         // シグナル確認シフト

// ==== CCI設定 ====
sinput string Comment_CCI_Entry = ""; //+--- CCIエントリー設定 ---+
input STRATEGY_TYPE CCI_Strategy = STRATEGY_DISABLED; // CCI戦略
input CCI_STRATEGY_TYPE CCI_Buy_Signal = CCI_OVERSOLD; // CCI Buy シグナル
input CCI_STRATEGY_TYPE CCI_Sell_Signal = CCI_OVERBOUGHT; // CCI Sell シグナル
input int CCI_Period = 14;                     // CCI期間
input int CCI_Price = PRICE_TYPICAL;           // CCI適用価格
input int CCI_Overbought = 100;                // 買われすぎレベル
input int CCI_Oversold = -100;                 // 売られすぎレベル
input int CCI_Signal_Shift = 1;                // シグナル確認シフト

// ==== ADX/DMI設定 ====
sinput string Comment_ADX_Entry = ""; //+--- ADX/DMIエントリー設定 ---+
input STRATEGY_TYPE ADX_Strategy = STRATEGY_DISABLED; // ADX/DMI戦略
input ADX_STRATEGY_TYPE ADX_Buy_Signal = ADX_PLUS_DI_CROSS_MINUS_DI; // ADX Buy シグナル
input ADX_STRATEGY_TYPE ADX_Sell_Signal = ADX_MINUS_DI_CROSS_PLUS_DI; // ADX Sell シグナル
input int ADX_Period = 14;                     // ADX期間
input int ADX_Threshold = 25;                  // ADXしきい値
input int ADX_Signal_Shift = 1;                // シグナル確認シフト

// ==== RCI設定 ====
sinput string Comment_RCI_Entry = ""; //+--- RCIエントリー設定 ---+
input STRATEGY_TYPE RCI_Strategy = STRATEGY_DISABLED; // RCI戦略
input RCI_STRATEGY_TYPE RCI_Buy_Signal = RCI_BELOW_MINUS_THRESHOLD; // RCI Buy シグナル
input RCI_STRATEGY_TYPE RCI_Sell_Signal = RCI_ABOVE_PLUS_THRESHOLD; // RCI Sell シグナル
input int RCI_Period = 9;                      // RCI期間
input int RCI_MidTerm_Period = 26;             // RCI中期期間
input int RCI_LongTerm_Period = 52;            // RCI長期期間
input int RCI_Threshold = 80;                  // RCIしきい値(±値)
input int RCI_Signal_Shift = 1;                // シグナル確認シフト

//+------------------------------------------------------------------+
//| 指定された時間足でインジケーター値を取得する関数                   |
//+------------------------------------------------------------------+
double GetIndicatorValueOnTimeframe(int indicator, int symbol, ENUM_TIMEFRAMES timeframe, int param1, int param2, int param3, double param4, int param5, int param6, int shift)
{
   // 指定された時間足でインジケーター値を取得
   double value = 0;
   
   // ストラテジーの時間足が現在のチャート時間足と同じ場合は通常の計算
   if(timeframe == PERIOD_CURRENT || timeframe == Period())
   {
      return iCustom(symbol, 0, indicator, param1, param2, param3, param4, param5, param6, shift);
   }
   
   // 時間足が異なる場合、その時間足でのインジケーター値を計算
   return iCustom(symbol, timeframe, indicator, param1, param2, param3, param4, param5, param6, shift);
}

//+------------------------------------------------------------------+
//| 時間戦略のシグナル判断                                           |
//+------------------------------------------------------------------+
bool IsTimeEntryAllowed(int side)
{
    // 時間エントリー条件をチェック
    // IsEntryAllowed関数を使用して時間帯チェック
    return IsEntryAllowed(side);
}

//+------------------------------------------------------------------+
//| MAクロス戦略のシグナル判断                                        |
//+------------------------------------------------------------------+
bool CheckMASignal(int side)
{
    if(MA_Cross_Strategy == STRATEGY_DISABLED)
        return false;
    
    // MA値の取得 - 時間足を考慮
    double fastMA_current, slowMA_current, fastMA_prev, slowMA_prev;
    
    if(side == 0) // Buy
    {
        if(MA_Buy_Signal == MA_DISABLED)
            return false;
            
        fastMA_current = iMA(Symbol(), Strategy_Timeframe, MA_Buy_Fast_Period, 0, MA_Method, MA_Price, MA_Cross_Shift);
        slowMA_current = iMA(Symbol(), Strategy_Timeframe, MA_Buy_Slow_Period, 0, MA_Method, MA_Price, MA_Cross_Shift);
        fastMA_prev = iMA(Symbol(), Strategy_Timeframe, MA_Buy_Fast_Period, 0, MA_Method, MA_Price, MA_Cross_Shift + 1);
        slowMA_prev = iMA(Symbol(), Strategy_Timeframe, MA_Buy_Slow_Period, 0, MA_Method, MA_Price, MA_Cross_Shift + 1);
        
        // 価格データの取得
        double price_current = iClose(Symbol(), Strategy_Timeframe, MA_Cross_Shift);
        double price_prev = iClose(Symbol(), Strategy_Timeframe, MA_Cross_Shift + 1);
        
        switch(MA_Buy_Signal)
        {
            case MA_GOLDEN_CROSS: // ゴールデンクロス(逆張り)
                return (fastMA_prev < slowMA_prev && fastMA_current > slowMA_current);
                
            case MA_PRICE_ABOVE_MA: // 価格がMA上(順張り)
                return (price_current > fastMA_current);
                
            case MA_FAST_ABOVE_SLOW: // 短期MAが長期MA上(順張り)
                return (fastMA_current > slowMA_current);
                
            case MA_DEAD_CROSS: // デッドクロス(順張り)
                return (fastMA_prev > slowMA_prev && fastMA_current < slowMA_current);
                
            case MA_PRICE_BELOW_MA: // 価格がMA下(逆張り)
                return (price_current < fastMA_current);
        }
    }
    else // Sell
    {
        if(MA_Sell_Signal == MA_DISABLED)
            return false;
            
        fastMA_current = iMA(Symbol(), Strategy_Timeframe, MA_Sell_Fast_Period, 0, MA_Method, MA_Price, MA_Cross_Shift);
        slowMA_current = iMA(Symbol(), Strategy_Timeframe, MA_Sell_Slow_Period, 0, MA_Method, MA_Price, MA_Cross_Shift);
        fastMA_prev = iMA(Symbol(), Strategy_Timeframe, MA_Sell_Fast_Period, 0, MA_Method, MA_Price, MA_Cross_Shift + 1);
        slowMA_prev = iMA(Symbol(), Strategy_Timeframe, MA_Sell_Slow_Period, 0, MA_Method, MA_Price, MA_Cross_Shift + 1);
        
        // 価格データの取得
        double price_current = iClose(Symbol(), Strategy_Timeframe, MA_Cross_Shift);
        double price_prev = iClose(Symbol(), Strategy_Timeframe, MA_Cross_Shift + 1);
        
        switch(MA_Sell_Signal)
        {
            case MA_DEAD_CROSS: // デッドクロス(逆張り)
                return (fastMA_prev > slowMA_prev && fastMA_current < slowMA_current);
                
            case MA_PRICE_BELOW_MA: // 価格がMA下(順張り)
                return (price_current < fastMA_current);
                
            case MA_FAST_ABOVE_SLOW: // 短期MAが長期MA下(順張り)
                return (fastMA_current < slowMA_current);
                
            case MA_GOLDEN_CROSS: // ゴールデンクロス(順張り)
                return (fastMA_prev < slowMA_prev && fastMA_current > slowMA_current);
                
            case MA_PRICE_ABOVE_MA: // 価格がMA上(逆張り)
                return (price_current > fastMA_current);
        }
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| RSI戦略のシグナル判断                                           |
//+------------------------------------------------------------------+
bool CheckRSISignal(int side)
{
    if(RSI_Strategy == STRATEGY_DISABLED)
        return false;
    
    // RSI値の取得 - 時間足を考慮
    double rsi_current = iRSI(Symbol(), Strategy_Timeframe, RSI_Period, RSI_Price, RSI_Signal_Shift);
    double rsi_prev = iRSI(Symbol(), Strategy_Timeframe, RSI_Period, RSI_Price, RSI_Signal_Shift + 1);
    
    // BUYシグナル
    if(side == 0)
    {
        if(RSI_Buy_Signal == RSI_DISABLED)
            return false;
            
        switch(RSI_Buy_Signal)
        {
            case RSI_OVERSOLD: // 売られすぎ(逆張り)
                return (rsi_current < RSI_Oversold);
                
            case RSI_OVERSOLD_EXIT: // 売られすぎから回復(逆張り)
                return (rsi_prev < RSI_Oversold && rsi_current >= RSI_Oversold);
                
            case RSI_OVERBOUGHT: // 買われすぎ(順張り)
                return (rsi_current > RSI_Overbought);
                
            case RSI_OVERBOUGHT_EXIT: // 買われすぎから下落(順張り)
                return (rsi_prev > RSI_Overbought && rsi_current <= RSI_Overbought);
        }
    }
    // SELLシグナル
    else
    {
        if(RSI_Sell_Signal == RSI_DISABLED)
            return false;
            
        switch(RSI_Sell_Signal)
        {
            case RSI_OVERBOUGHT: // 買われすぎ(逆張り)
                return (rsi_current > RSI_Overbought);
                
            case RSI_OVERBOUGHT_EXIT: // 買われすぎから下落(逆張り)
                return (rsi_prev > RSI_Overbought && rsi_current <= RSI_Overbought);
                
            case RSI_OVERSOLD: // 売られすぎ(順張り)
                return (rsi_current < RSI_Oversold);
                
            case RSI_OVERSOLD_EXIT: // 売られすぎから回復(順張り)
                return (rsi_prev < RSI_Oversold && rsi_current >= RSI_Oversold);
        }
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| ボリンジャーバンド戦略のシグナル判断                              |
//+------------------------------------------------------------------+
bool CheckBollingerSignal(int side)
{
    if(BB_Strategy == STRATEGY_DISABLED)
        return false;
    
    // 時間足を考慮したボリンジャーバンド値の取得
    double middle = iBands(Symbol(), Strategy_Timeframe, BB_Period, BB_Deviation, 0, BB_Price, MODE_MAIN, BB_Signal_Shift);
    double upper = iBands(Symbol(), Strategy_Timeframe, BB_Period, BB_Deviation, 0, BB_Price, MODE_UPPER, BB_Signal_Shift);
    double lower = iBands(Symbol(), Strategy_Timeframe, BB_Period, BB_Deviation, 0, BB_Price, MODE_LOWER, BB_Signal_Shift);
    
    double close_current = iClose(Symbol(), Strategy_Timeframe, BB_Signal_Shift);
    double close_prev = iClose(Symbol(), Strategy_Timeframe, BB_Signal_Shift + 1);
    
    // BUYシグナル
    if(side == 0)
    {
        if(BB_Buy_Signal == BB_DISABLED)
            return false;
            
        switch(BB_Buy_Signal)
        {
            case BB_TOUCH_LOWER: // 下限バンドタッチ後反発(逆張り)
                return (close_prev <= lower && close_current > close_prev);
                
            case BB_BREAK_UPPER: // 上限バンド突破(順張り)
                return (close_prev < upper && close_current > upper);
                
            case BB_TOUCH_UPPER: // 上限バンドタッチ後反落(順張り)
                return (close_prev >= upper && close_current < close_prev);
                
            case BB_BREAK_LOWER: // 下限バンド突破(逆張り)
                return (close_prev > lower && close_current < lower);
        }
    }
    // SELLシグナル
    else
    {
        if(BB_Sell_Signal == BB_DISABLED)
            return false;
            
        switch(BB_Sell_Signal)
        {
            case BB_TOUCH_UPPER: // 上限バンドタッチ後反落(逆張り)
                return (close_prev >= upper && close_current < close_prev);
                
            case BB_BREAK_LOWER: // 下限バンド突破(順張り)
                return (close_prev > lower && close_current < lower);
                
            case BB_TOUCH_LOWER: // 下限バンドタッチ後反発(順張り)
                return (close_prev <= lower && close_current > close_prev);
                
            case BB_BREAK_UPPER: // 上限バンド突破(逆張り)
                return (close_prev < upper && close_current > upper);
        }
    }
    
    return false;
}
    
//+------------------------------------------------------------------+
//| RCI（ランク相関係数）の計算                                      |
//+------------------------------------------------------------------+
double CalculateRCI(int period, int shift)
{
    // 計算するために十分なヒストリカルデータがあることを確認
    if(Bars < period + shift)
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
    
    // 価格データを取得 - 時間足を考慮
    for(int i = 0; i < period; i++)
    {
        prices[i] = iClose(Symbol(), Strategy_Timeframe, i + shift);
    }
    
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
//| RCI戦略のシグナル判断                                            |
//+------------------------------------------------------------------+
bool CheckRCISignal(int side)
{
    if(RCI_Strategy == STRATEGY_DISABLED)
        return false;
    
    // RCIの計算 - 時間足を考慮
    double rci_current = CalculateRCI(RCI_Period, RCI_Signal_Shift);
    double rci_prev = CalculateRCI(RCI_Period, RCI_Signal_Shift + 1);
    
    // 中期RCI
    double rci_mid_current = CalculateRCI(RCI_MidTerm_Period, RCI_Signal_Shift);
    
    // 長期RCI
    double rci_long_current = CalculateRCI(RCI_LongTerm_Period, RCI_Signal_Shift);
    
    // BUYシグナル
    if(side == 0)
    {
        if(RCI_Buy_Signal == RCI_DISABLED)
            return false;
        
        switch(RCI_Buy_Signal)
        {
            case RCI_BELOW_MINUS_THRESHOLD: // -しきい値以下(逆張り)
                return (rci_current < -RCI_Threshold);
                
            case RCI_RISING_FROM_BOTTOM: // -しきい値から上昇(逆張り)
                return (rci_prev < -RCI_Threshold && rci_current > rci_prev && 
                        rci_mid_current < -50 && rci_long_current < -50);
                
            case RCI_ABOVE_PLUS_THRESHOLD: // +しきい値以上(順張り)
                return (rci_current > RCI_Threshold);
                
            case RCI_FALLING_FROM_PEAK: // +しきい値から下落(順張り)
                return (rci_prev > RCI_Threshold && rci_current < rci_prev && 
                        rci_mid_current > 50 && rci_long_current > 50);
        }
    }
    // SELLシグナル
    else
    {
        if(RCI_Sell_Signal == RCI_DISABLED)
            return false;
            
        switch(RCI_Sell_Signal)
        {
            case RCI_ABOVE_PLUS_THRESHOLD: // +しきい値以上(逆張り)
                return (rci_current > RCI_Threshold);
                
            case RCI_FALLING_FROM_PEAK: // +しきい値から下落(逆張り)
                return (rci_prev > RCI_Threshold && rci_current < rci_prev && 
                        rci_mid_current > 50 && rci_long_current > 50);
                
            case RCI_BELOW_MINUS_THRESHOLD: // -しきい値以下(順張り)
                return (rci_current < -RCI_Threshold);
                
            case RCI_RISING_FROM_BOTTOM: // -しきい値から上昇(順張り)
            return (rci_prev < -RCI_Threshold && rci_current > rci_prev && 
                rci_mid_current < -50 && rci_long_current < -50);
}
}

return false;
}

//+------------------------------------------------------------------+
//| ストキャスティクス戦略のシグナル判断                              |
//+------------------------------------------------------------------+
bool CheckStochasticSignal(int side)
{
if(Stochastic_Strategy == STRATEGY_DISABLED)
return false;

// 時間足を考慮したストキャスティクス値の取得
double k_current = iStochastic(Symbol(), Strategy_Timeframe, Stochastic_K_Period, Stochastic_D_Period, Stochastic_Slowing, Stochastic_Method, Stochastic_Price_Field, MODE_MAIN, Stochastic_Signal_Shift);
double k_prev = iStochastic(Symbol(), Strategy_Timeframe, Stochastic_K_Period, Stochastic_D_Period, Stochastic_Slowing, Stochastic_Method, Stochastic_Price_Field, MODE_MAIN, Stochastic_Signal_Shift + 1);
double d_current = iStochastic(Symbol(), Strategy_Timeframe, Stochastic_K_Period, Stochastic_D_Period, Stochastic_Slowing, Stochastic_Method, Stochastic_Price_Field, MODE_SIGNAL, Stochastic_Signal_Shift);
double d_prev = iStochastic(Symbol(), Strategy_Timeframe, Stochastic_K_Period, Stochastic_D_Period, Stochastic_Slowing, Stochastic_Method, Stochastic_Price_Field, MODE_SIGNAL, Stochastic_Signal_Shift + 1);

// BUYシグナル
if(side == 0)
{
if(Stochastic_Buy_Signal == STOCH_DISABLED)
    return false;
    
switch(Stochastic_Buy_Signal)
{
    case STOCH_OVERSOLD: // 売られすぎ(逆張り)
        return (k_current < Stochastic_Oversold);
        
    case STOCH_K_CROSS_D_OVERSOLD: // %Kが%Dを上抜け（売られすぎ）(逆張り)
        return (k_prev < d_prev && k_current > d_current && k_prev < Stochastic_Oversold);
        
    case STOCH_OVERSOLD_EXIT: // 売られすぎから脱出(逆張り)
        return (k_prev < Stochastic_Oversold && k_current >= Stochastic_Oversold);
        
    case STOCH_OVERBOUGHT: // 買われすぎ(順張り)
        return (k_current > Stochastic_Overbought);
        
    case STOCH_K_CROSS_D_OVERBOUGHT: // %Kが%Dを下抜け（買われすぎ）(順張り)
        return (k_prev > d_prev && k_current < d_current && k_prev > Stochastic_Overbought);
        
    case STOCH_OVERBOUGHT_EXIT: // 買われすぎから脱出(順張り)
        return (k_prev > Stochastic_Overbought && k_current <= Stochastic_Overbought);
}
}
// SELLシグナル
else
{
if(Stochastic_Sell_Signal == STOCH_DISABLED)
    return false;
    
switch(Stochastic_Sell_Signal)
{
    case STOCH_OVERBOUGHT: // 買われすぎ(逆張り)
        return (k_current > Stochastic_Overbought);
        
    case STOCH_K_CROSS_D_OVERBOUGHT: // %Kが%Dを下抜け（買われすぎ）(逆張り)
        return (k_prev > d_prev && k_current < d_current && k_prev > Stochastic_Overbought);
        
    case STOCH_OVERBOUGHT_EXIT: // 買われすぎから脱出(逆張り)
        return (k_prev > Stochastic_Overbought && k_current <= Stochastic_Overbought);
        
    case STOCH_OVERSOLD: // 売られすぎ(順張り)
        return (k_current < Stochastic_Oversold);
        
    case STOCH_K_CROSS_D_OVERSOLD: // %Kが%Dを上抜け（売られすぎ）(順張り)
        return (k_prev < d_prev && k_current > d_current && k_prev < Stochastic_Oversold);
        
    case STOCH_OVERSOLD_EXIT: // 売られすぎから脱出(順張り)
        return (k_prev < Stochastic_Oversold && k_current >= Stochastic_Oversold);
}
}

return false;
}

//+------------------------------------------------------------------+
//| CCI戦略のシグナル判断                                            |
//+------------------------------------------------------------------+
bool CheckCCISignal(int side)
{
if(CCI_Strategy == STRATEGY_DISABLED)
return false;

// 時間足を考慮したCCI値の取得
double cci_current = iCCI(Symbol(), Strategy_Timeframe, CCI_Period, CCI_Price, CCI_Signal_Shift);
double cci_prev = iCCI(Symbol(), Strategy_Timeframe, CCI_Period, CCI_Price, CCI_Signal_Shift + 1);

// BUYシグナル
if(side == 0)
{
if(CCI_Buy_Signal == CCI_DISABLED)
    return false;
    
switch(CCI_Buy_Signal)
{
    case CCI_OVERSOLD: // 売られすぎ(逆張り)
        return (cci_current < CCI_Oversold);
        
    case CCI_OVERSOLD_EXIT: // 売られすぎから回復(逆張り)
        return (cci_prev < CCI_Oversold && cci_current >= CCI_Oversold);
        
    case CCI_OVERBOUGHT: // 買われすぎ(順張り)
        return (cci_current > CCI_Overbought);
        
    case CCI_OVERBOUGHT_EXIT: // 買われすぎから下落(順張り)
        return (cci_prev > CCI_Overbought && cci_current <= CCI_Overbought);
}
}
// SELLシグナル
else
{
if(CCI_Sell_Signal == CCI_DISABLED)
    return false;
    
switch(CCI_Sell_Signal)
{
    case CCI_OVERBOUGHT: // 買われすぎ(逆張り)
        return (cci_current > CCI_Overbought);
        
    case CCI_OVERBOUGHT_EXIT: // 買われすぎから下落(逆張り)
        return (cci_prev > CCI_Overbought && cci_current <= CCI_Overbought);
        
    case CCI_OVERSOLD: // 売られすぎ(順張り)
        return (cci_current < CCI_Oversold);
        
    case CCI_OVERSOLD_EXIT: // 売られすぎから回復(順張り)
        return (cci_prev < CCI_Oversold && cci_current >= CCI_Oversold);
}
}

return false;
}

//+------------------------------------------------------------------+
//| ADX/DMI戦略のシグナル判断                                        |
//+------------------------------------------------------------------+
bool CheckADXSignal(int side)
{
if(ADX_Strategy == STRATEGY_DISABLED)
return false;

// 時間足を考慮したADX値の取得
double adx = iADX(Symbol(), Strategy_Timeframe, ADX_Period, PRICE_CLOSE, MODE_MAIN, ADX_Signal_Shift);
double plus_di = iADX(Symbol(), Strategy_Timeframe, ADX_Period, PRICE_CLOSE, MODE_PLUSDI, ADX_Signal_Shift);
double minus_di = iADX(Symbol(), Strategy_Timeframe, ADX_Period, PRICE_CLOSE, MODE_MINUSDI, ADX_Signal_Shift);
double plus_di_prev = iADX(Symbol(), Strategy_Timeframe, ADX_Period, PRICE_CLOSE, MODE_PLUSDI, ADX_Signal_Shift + 1);
double minus_di_prev = iADX(Symbol(), Strategy_Timeframe, ADX_Period, PRICE_CLOSE, MODE_MINUSDI, ADX_Signal_Shift + 1);

// BUYシグナル
if(side == 0)
{
if(ADX_Buy_Signal == ADX_DISABLED)
    return false;
    
switch(ADX_Buy_Signal)
{
    case ADX_PLUS_DI_CROSS_MINUS_DI: // +DIが-DIを上抜け(順張り)
        return (plus_di_prev < minus_di_prev && plus_di > minus_di);
        
    case ADX_STRONG_TREND_PLUS_DI: // 強いトレンドで+DI > -DI(順張り)
        return (adx > ADX_Threshold && plus_di > minus_di);
        
    case ADX_MINUS_DI_CROSS_PLUS_DI: // -DIが+DIを上抜け(逆張り)
        return (minus_di_prev < plus_di_prev && minus_di > plus_di);
        
    case ADX_STRONG_TREND_MINUS_DI: // 強いトレンドで-DI > +DI(逆張り)
        return (adx > ADX_Threshold && minus_di > plus_di);
}
}
// SELLシグナル
else
{
if(ADX_Sell_Signal == ADX_DISABLED)
    return false;
    
switch(ADX_Sell_Signal)
{
    case ADX_MINUS_DI_CROSS_PLUS_DI: // -DIが+DIを上抜け(順張り)
        return (minus_di_prev < plus_di_prev && minus_di > plus_di);
        
    case ADX_STRONG_TREND_MINUS_DI: // 強いトレンドで-DI > +DI(順張り)
        return (adx > ADX_Threshold && minus_di > plus_di);
        
    case ADX_PLUS_DI_CROSS_MINUS_DI: // +DIが-DIを上抜け(逆張り)
        return (plus_di_prev < minus_di_prev && plus_di > minus_di);
        
    case ADX_STRONG_TREND_PLUS_DI: // 強いトレンドで+DI > -DI(逆張り)
        return (adx > ADX_Threshold && plus_di > minus_di);
}
}

return false;
}

//+------------------------------------------------------------------+
//| 戦略評価 - ProcessGhostEntries関数用のインターフェース            |
//+------------------------------------------------------------------+
bool ShouldProcessGhostEntry(int side)
{
// ProcessGhostEntries関数から呼び出されるエントリー評価関数
return EvaluateStrategyForEntry(side);
}

//+------------------------------------------------------------------+
//| 戦略評価 - ProcessRealEntries関数用のインターフェース             |
//+------------------------------------------------------------------+
bool ShouldProcessRealEntry(int side)
{
// ProcessRealEntries関数から呼び出されるエントリー評価関数
return EvaluateStrategyForEntry(side);
}


//+------------------------------------------------------------------+
//| EvaluateIndicatorsForEntry関数 - 修正版                           |
//+------------------------------------------------------------------+
bool EvaluateIndicatorsForEntry(int side)
{
Print("EvaluateIndicatorsForEntry 開始 - side=", side);

// 有効な戦略のシグナルを評価
bool strategySignals = false;
int enabledStrategies = 0;

// MA クロス
if(MA_Cross_Strategy != STRATEGY_DISABLED) {
enabledStrategies++;
if(CheckMASignal(side)) {
    strategySignals = true;
    Print("MAクロス: シグナル成立");
} else {
    Print("MAクロス: シグナル不成立");
}
}

// RSI
if(RSI_Strategy != STRATEGY_DISABLED) {
enabledStrategies++;
if(CheckRSISignal(side)) {
    strategySignals = true;
    Print("RSI: シグナル成立");
} else {
    Print("RSI: シグナル不成立");
}
}

// ボリンジャーバンド
if(BB_Strategy != STRATEGY_DISABLED) {
enabledStrategies++;
if(CheckBollingerSignal(side)) {
    strategySignals = true;
    Print("ボリンジャーバンド: シグナル成立");
} else {
    Print("ボリンジャーバンド: シグナル不成立");
}
}

// RCI
if(RCI_Strategy != STRATEGY_DISABLED) {
enabledStrategies++;
if(CheckRCISignal(side)) {
    strategySignals = true;
    Print("RCI: シグナル成立");
} else {
    Print("RCI: シグナル不成立");
}
}

// ストキャスティクス
if(Stochastic_Strategy != STRATEGY_DISABLED) {
enabledStrategies++;
if(CheckStochasticSignal(side)) {
    strategySignals = true;
    Print("ストキャスティクス: シグナル成立");
} else {
    Print("ストキャスティクス: シグナル不成立");
}
}

// CCI
if(CCI_Strategy != STRATEGY_DISABLED) {
enabledStrategies++;
if(CheckCCISignal(side)) {
    strategySignals = true;
    Print("CCI: シグナル成立");
} else {
    Print("CCI: シグナル不成立");
}
}

// ADX/DMI
if(ADX_Strategy != STRATEGY_DISABLED) {
enabledStrategies++;
if(CheckADXSignal(side)) {
    strategySignals = true;
    Print("ADX/DMI: シグナル成立");
} else {
    Print("ADX/DMI: シグナル不成立");
}
}

// 最終判断: 重要な修正
Print("有効なインジケーター数: ", enabledStrategies, ", シグナル成立状況: ", strategySignals ? "あり" : "なし");

// 修正: 有効な戦略が1つもない場合はfalseを返す
if(enabledStrategies == 0) {
Print("EvaluateIndicatorsForEntry: 有効なインジケーターが0のため false を返します");
return false;
}

// 修正: 有効な戦略があり、少なくとも1つがシグナルを出した場合にのみtrueを返す
Print("EvaluateIndicatorsForEntry 最終結果: ", strategySignals ? "成立" : "不成立");
return strategySignals;
}

//+------------------------------------------------------------------+
//| 戦略シグナルの詳細をログに記録                                    |
//+------------------------------------------------------------------+
string GetStrategyDetails(int side)
{
// side: 0 = Buy, 1 = Sell
string typeStr = (side == 0) ? "Buy" : "Sell";
string strategyDetails = "【" + typeStr + " 戦略シグナル詳細】\n";

// 時間戦略
bool timeEntryAllowed = IsTimeEntryAllowed(side);
strategyDetails += "時間条件: " + (timeEntryAllowed ? "許可" : "不許可") + "\n";

// MA クロス
if(MA_Cross_Strategy != STRATEGY_DISABLED) {
bool maSignal = CheckMASignal(side);

// MA値の取得
double fastMA_current, slowMA_current;
if(side == 0) {
    fastMA_current = iMA(Symbol(), Strategy_Timeframe, MA_Buy_Fast_Period, 0, MA_Method, MA_Price, MA_Cross_Shift);
    slowMA_current = iMA(Symbol(), Strategy_Timeframe, MA_Buy_Slow_Period, 0, MA_Method, MA_Price, MA_Cross_Shift);
} else {
    fastMA_current = iMA(Symbol(), Strategy_Timeframe, MA_Sell_Fast_Period, 0, MA_Method, MA_Price, MA_Cross_Shift);
    slowMA_current = iMA(Symbol(), Strategy_Timeframe, MA_Sell_Slow_Period, 0, MA_Method, MA_Price, MA_Cross_Shift);
}

strategyDetails += "MAクロス: " + (maSignal ? "シグナルあり" : "シグナルなし") + 
                 " (短期MA=" + DoubleToString(fastMA_current, Digits) + 
                 ", 長期MA=" + DoubleToString(slowMA_current, Digits) + ")\n";
}

// RSI
if(RSI_Strategy != STRATEGY_DISABLED) {
bool rsiSignal = CheckRSISignal(side);

// RSI値の取得
double rsi_current = iRSI(Symbol(), Strategy_Timeframe, RSI_Period, RSI_Price, RSI_Signal_Shift);
strategyDetails += "RSI: " + (rsiSignal ? "シグナルあり" : "シグナルなし") + 
                 " (値=" + DoubleToString(rsi_current, 2) + 
                 ", 買われすぎ=" + IntegerToString(RSI_Overbought) + 
                 ", 売られすぎ=" + IntegerToString(RSI_Oversold) + ")\n";
}

// ボリンジャーバンド
if(BB_Strategy != STRATEGY_DISABLED) {
bool bbSignal = CheckBollingerSignal(side);

// ボリンジャーバンド値の取得
double middle = iBands(Symbol(), Strategy_Timeframe, BB_Period, BB_Deviation, 0, BB_Price, MODE_MAIN, BB_Signal_Shift);
double upper = iBands(Symbol(), Strategy_Timeframe, BB_Period, BB_Deviation, 0, BB_Price, MODE_UPPER, BB_Signal_Shift);
double lower = iBands(Symbol(), Strategy_Timeframe, BB_Period, BB_Deviation, 0, BB_Price, MODE_LOWER, BB_Signal_Shift);
double close = iClose(Symbol(), Strategy_Timeframe, BB_Signal_Shift);

strategyDetails += "ボリンジャーバンド: " + (bbSignal ? "シグナルあり" : "シグナルなし") + 
                 " (上=" + DoubleToString(upper, Digits) + 
                 ", 中=" + DoubleToString(middle, Digits) + 
                 ", 下=" + DoubleToString(lower, Digits) + 
                 ", 終値=" + DoubleToString(close, Digits) + ")\n";
}

// RCI
if(RCI_Strategy != STRATEGY_DISABLED) {
bool rciSignal = CheckRCISignal(side);

// RCI値の取得
double rci_current = CalculateRCI(RCI_Period, RCI_Signal_Shift);
strategyDetails += "RCI: " + (rciSignal ? "シグナルあり" : "シグナルなし") + 
                 " (値=" + DoubleToString(rci_current, 2) + 
                 ", しきい値=" + IntegerToString(RCI_Threshold) + ")\n";
}

// ストキャスティクス
if(Stochastic_Strategy != STRATEGY_DISABLED) {
bool stochSignal = CheckStochasticSignal(side);

// ストキャスティクス値の取得
double k_current = iStochastic(Symbol(), Strategy_Timeframe, Stochastic_K_Period, Stochastic_D_Period, 
                      Stochastic_Slowing, Stochastic_Method, Stochastic_Price_Field, 
                      MODE_MAIN, Stochastic_Signal_Shift);
double d_current = iStochastic(Symbol(), Strategy_Timeframe, Stochastic_K_Period, Stochastic_D_Period, 
                      Stochastic_Slowing, Stochastic_Method, Stochastic_Price_Field, 
                      MODE_SIGNAL, Stochastic_Signal_Shift);

strategyDetails += "ストキャスティクス: " + (stochSignal ? "シグナルあり" : "シグナルなし") + 
                 " (K=" + DoubleToString(k_current, 2) + 
                 ", D=" + DoubleToString(d_current, 2) + 
                 ", 買われすぎ=" + IntegerToString(Stochastic_Overbought) + 
                 ", 売られすぎ=" + IntegerToString(Stochastic_Oversold) + ")\n";
}

// CCI
if(CCI_Strategy != STRATEGY_DISABLED) {
bool cciSignal = CheckCCISignal(side);

// CCI値の取得
double cci_current = iCCI(Symbol(), Strategy_Timeframe, CCI_Period, CCI_Price, CCI_Signal_Shift);
strategyDetails += "CCI: " + (cciSignal ? "シグナルあり" : "シグナルなし") + 
                 " (値=" + DoubleToString(cci_current, 2) + 
                 ", 買われすぎ=" + IntegerToString(CCI_Overbought) + 
                 ", 売られすぎ=" + IntegerToString(CCI_Oversold) + ")\n";
}

// ADX/DMI
if(ADX_Strategy != STRATEGY_DISABLED) {
bool adxSignal = CheckADXSignal(side);

// ADX値の取得
double adx = iADX(Symbol(), Strategy_Timeframe, ADX_Period, PRICE_CLOSE, MODE_MAIN, ADX_Signal_Shift);
double plus_di = iADX(Symbol(), Strategy_Timeframe, ADX_Period, PRICE_CLOSE, MODE_PLUSDI, ADX_Signal_Shift);
double minus_di = iADX(Symbol(), Strategy_Timeframe, ADX_Period, PRICE_CLOSE, MODE_MINUSDI, ADX_Signal_Shift);

strategyDetails += "ADX/DMI: " + (adxSignal ? "シグナルあり" : "シグナルなし") + 
                 " (ADX=" + DoubleToString(adx, 2) + 
                 ", +DI=" + DoubleToString(plus_di, 2) + 
                 ", -DI=" + DoubleToString(minus_di, 2) + 
                 ", しきい値=" + IntegerToString(ADX_Threshold) + ")\n";
}

return strategyDetails;
}

//+------------------------------------------------------------------+
//| 戦略評価を拡張 - エントリー理由ログ付き                          |
//+------------------------------------------------------------------+
bool EvaluateStrategyForEntry(int side)
{
// side: 0 = Buy, 1 = Sell
bool entrySignal = false;

// 時間条件のチェック
bool timeEntryAllowed = IsTimeEntryAllowed(side);

// すべての有効戦略のシグナルを評価
bool strategySignals = false;
int enabledStrategies = 0;

// 有効な戦略名のリスト
string activeStrategies = "";

// MA クロス
if(MA_Cross_Strategy != STRATEGY_DISABLED) {
enabledStrategies++;
if(CheckMASignal(side)) {
    strategySignals = true;
    if(activeStrategies != "") activeStrategies += ", ";
    activeStrategies += "MAクロス";
}
}

// RSI
if(RSI_Strategy != STRATEGY_DISABLED) {
enabledStrategies++;
if(CheckRSISignal(side)) {
    strategySignals = true;
    if(activeStrategies != "") activeStrategies += ", ";
    activeStrategies += "RSI";
}
}

// ボリンジャーバンド
if(BB_Strategy != STRATEGY_DISABLED) {
enabledStrategies++;
if(CheckBollingerSignal(side)) {
    strategySignals = true;
    if(activeStrategies != "") activeStrategies += ", ";
    activeStrategies += "ボリンジャーバンド";
}
}

// RCI
if(RCI_Strategy != STRATEGY_DISABLED) {
enabledStrategies++;
if(CheckRCISignal(side)) {
    strategySignals = true;
    if(activeStrategies != "") activeStrategies += ", ";
    activeStrategies += "RCI";
}
}

// ストキャスティクス
if(Stochastic_Strategy != STRATEGY_DISABLED) {
enabledStrategies++;
if(CheckStochasticSignal(side)) {
   strategySignals = true;
   if(activeStrategies != "") activeStrategies += ", ";
   activeStrategies += "ストキャスティクス";
}
}

// CCI
if(CCI_Strategy != STRATEGY_DISABLED) {
enabledStrategies++;
if(CheckCCISignal(side)) {
   strategySignals = true;
   if(activeStrategies != "") activeStrategies += ", ";
   activeStrategies += "CCI";
}
}

// ADX/DMI
if(ADX_Strategy != STRATEGY_DISABLED) {
enabledStrategies++;
if(CheckADXSignal(side)) {
   strategySignals = true;
   if(activeStrategies != "") activeStrategies += ", ";
   activeStrategies += "ADX/DMI";
}
}

// 最終判断
// 時間条件が許可され、かつ有効化された戦略のうち少なくとも1つがシグナルを出した場合
if(timeEntryAllowed && (enabledStrategies == 0 || strategySignals)) {
entrySignal = true;

// 戦略シグナルの詳細ログを出力
if(enabledStrategies > 0) {
   string typeStr = (side == 0) ? "Buy" : "Sell";
   string reason;
   
   if(activeStrategies == "") {
       reason = "時間条件のみ (有効な戦略シグナルなし)";
   } else {
       reason = "シグナル: " + activeStrategies;
   }
   
   // 詳細情報を取得
   string details = GetStrategyDetails(side);
   
   // エントリー理由をログに記録
   LogEntryReason(side == 0 ? OP_BUY : OP_SELL, "戦略シグナル", reason);
   
   // 詳細情報もログに出力
   Print(details);
} else {
   LogEntryReason(side == 0 ? OP_BUY : OP_SELL, "時間エントリー", "時間条件のみ (戦略なし)");
}
}

return entrySignal;
}

//+------------------------------------------------------------------+
//| インジケーターのシグナルをまとめてチェックする                     |
//+------------------------------------------------------------------+
bool CheckIndicatorSignals(int side)
{
// どれか1つでもシグナルがあればtrue
return (MA_Cross_Strategy != STRATEGY_DISABLED && CheckMASignal(side)) ||
  (RSI_Strategy != STRATEGY_DISABLED && CheckRSISignal(side)) ||
  (BB_Strategy != STRATEGY_DISABLED && CheckBollingerSignal(side)) ||
  (RCI_Strategy != STRATEGY_DISABLED && CheckRCISignal(side)) ||
  (Stochastic_Strategy != STRATEGY_DISABLED && CheckStochasticSignal(side)) ||
  (CCI_Strategy != STRATEGY_DISABLED && CheckCCISignal(side)) ||
  (ADX_Strategy != STRATEGY_DISABLED && CheckADXSignal(side));
}

//+------------------------------------------------------------------+
//| アクティブなインジケーターシグナルの名前を取得                     |
//+------------------------------------------------------------------+
string GetActiveIndicatorSignals(int side)
{
   string activeSignals = "";
   
   // MA クロス
   if(MA_Cross_Strategy != STRATEGY_DISABLED) {
      if(CheckMASignal(side)) {
         if(activeSignals != "") activeSignals += ", ";
         activeSignals += "MAクロス";
      }
   }
   
   // RSI
   if(RSI_Strategy != STRATEGY_DISABLED) {
      if(CheckRSISignal(side)) {
         if(activeSignals != "") activeSignals += ", ";
         activeSignals += "RSI";
      }
   }
   
   // ボリンジャーバンド
   if(BB_Strategy != STRATEGY_DISABLED) {
      if(CheckBollingerSignal(side)) {
         if(activeSignals != "") activeSignals += ", ";
         activeSignals += "ボリンジャー";
      }
   }
   
   // RCI
   if(RCI_Strategy != STRATEGY_DISABLED) {
      if(CheckRCISignal(side)) {
         if(activeSignals != "") activeSignals += ", ";
         activeSignals += "RCI";
      }
   }
   
   // ストキャスティクス
   if(Stochastic_Strategy != STRATEGY_DISABLED) {
      if(CheckStochasticSignal(side)) {
         if(activeSignals != "") activeSignals += ", ";
         activeSignals += "ストキャスティクス";
      }
   }
   
   // CCI
   if(CCI_Strategy != STRATEGY_DISABLED) {
      if(CheckCCISignal(side)) {
         if(activeSignals != "") activeSignals += ", ";
         activeSignals += "CCI";
      }
   }
   
   // ADX/DMI
   if(ADX_Strategy != STRATEGY_DISABLED) {
      if(CheckADXSignal(side)) {
         if(activeSignals != "") activeSignals += ", ";
         activeSignals += "ADX/DMI";
      }
   }
   
   return (activeSignals == "") ? "なし" : activeSignals;
}

//+------------------------------------------------------------------+
//| Hosopi3_Manager.mqh の ProcessStrategyLogic関数 - 修正版          |
//+------------------------------------------------------------------+
void ProcessStrategyLogic()
{
   // 自動売買が無効の場合は何もしない
   if(!EnableAutomaticTrading)
   {
      Print("ProcessStrategyLogic: 自動売買が無効のためスキップします");
      return;
   }
   
   // リアルポジション有無を判定
   bool hasRealBuy = position_count(OP_BUY) > 0;
   bool hasRealSell = position_count(OP_SELL) > 0;
   
   // ゴーストモードの設定（NanpinSkipLevel に基づく）
   bool useGhostMode = (NanpinSkipLevel != SKIP_NONE) && g_GhostMode;
   
   // ゴーストエントリー機能がOFFの場合はゴーストモードを無効化
   if(!EnableGhostEntry) {
      useGhostMode = false;
   }
   
   Print("ProcessStrategyLogic: リアルポジション状況 - Buy=", hasRealBuy, ", Sell=", hasRealSell);
   Print("ProcessStrategyLogic: ゴーストモード=", useGhostMode ? "有効" : "無効", ", NanpinSkipLevel=", EnumToString(NanpinSkipLevel));

   // リアルポジションがある場合
   if(hasRealBuy || hasRealSell)
   {
      // ナンピン機能が有効な場合のみナンピン条件をチェック
      if(EnableNanpin)
      {
         Print("ProcessStrategyLogic: リアルポジションあり、ナンピン条件チェック開始");
         // リアルポジションのナンピン条件をチェック
         CheckNanpinConditions(0); // Buy側のナンピン条件チェック
         CheckNanpinConditions(1); // Sell側のナンピン条件チェック
      }
   }
   else
   {
      // リアルポジションがない場合
      Print("ProcessStrategyLogic: リアルポジションなし、エントリー条件チェック開始");

      // エントリーモード表示
      Print("ProcessStrategyLogic: 現在のエントリーモード=", 
           (EntryMode == MODE_BUY_ONLY) ? "BUYのみ" : 
           (EntryMode == MODE_SELL_ONLY) ? "SELLのみ" : "両方");

      // ゴーストモードがONの場合
      if(useGhostMode && EnableGhostEntry)
      {
         Print("ProcessStrategyLogic: ゴーストエントリー処理を実行");
         // エントリーモードに基づいてゴーストエントリー処理
         if(EntryMode == MODE_BUY_ONLY || EntryMode == MODE_BOTH) {
            ProcessGhostEntries(0); // Buy側
         }
         
         if(EntryMode == MODE_SELL_ONLY || EntryMode == MODE_BOTH) {
            ProcessGhostEntries(1); // Sell側
         }
      }
      else
      {
         Print("ProcessStrategyLogic: リアルエントリー処理を実行");
         // エントリーモードに基づいてリアルエントリー処理
         if(EntryMode == MODE_BUY_ONLY || EntryMode == MODE_BOTH) {
            ProcessRealEntries(0); // Buy側
         }
         
         if(EntryMode == MODE_SELL_ONLY || EntryMode == MODE_BOTH) {
            ProcessRealEntries(1); // Sell側
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Hosopi3_Manager.mqh の ProcessRealEntries関数 - 修正版            |
//+------------------------------------------------------------------+
void ProcessRealEntries(int side)
{
   string direction = (side == 0) ? "Buy" : "Sell";
   Print("ProcessRealEntries: ", direction, " 処理開始");
   
   // リアルポジションがある場合はスキップ - 変数名を修正（type -> operationType）
   int operationType = (side == 0) ? OP_BUY : OP_SELL;
   int existingCount = position_count(operationType);
   
   if(existingCount > 0)
   {
      Print("既に", direction, "リアルポジションが存在するため、リアルエントリーはスキップされました: ", existingCount, "ポジション");
      return;
   }

   // 以下は既存のコードを変更せずに継続
   // エントリーモードに基づくチェック
   bool modeAllowed = false;
   if(side == 0) // Buy
      modeAllowed = (EntryMode == MODE_BUY_ONLY || EntryMode == MODE_BOTH);
   else // Sell
      modeAllowed = (EntryMode == MODE_SELL_ONLY || EntryMode == MODE_BOTH);

   if(!modeAllowed) {
      Print("ProcessRealEntries: エントリーモードにより", direction, "側はスキップします");
      return;
   }
   
   Print("ProcessRealEntries: ", direction, " エントリーモードチェック通過");

   // 時間条件とインジケーター条件をチェック
   bool timeSignal = false;
   bool indicatorSignal = false;
   string entryReason = "";
   
   // 時間条件のチェック
   if(UseEvenOddHoursEntry) {
      timeSignal = IsTimeEntryAllowed(side);
      Print("ProcessRealEntries: 時間条件=", timeSignal ? "成立" : "不成立");
      if(timeSignal) {
         entryReason += "時間条件OK ";
      } else {
         entryReason += "時間条件NG ";
      }
   } else {
      // 時間条件が無効の場合
      bool hasActiveIndicators = (MA_Cross_Strategy != STRATEGY_DISABLED || 
                                RSI_Strategy != STRATEGY_DISABLED || 
                                BB_Strategy != STRATEGY_DISABLED || 
                                RCI_Strategy != STRATEGY_DISABLED || 
                                Stochastic_Strategy != STRATEGY_DISABLED || 
                                CCI_Strategy != STRATEGY_DISABLED || 
                                ADX_Strategy != STRATEGY_DISABLED);
      
      if(!hasActiveIndicators) {
         // 両方無効の場合は特別処理
         timeSignal = false;
         Print("ProcessRealEntries: 時間条件とインジケーターの両方が無効のため、エントリーしません");
         entryReason += "両方の条件が無効 ";
      } else {
         // インジケーター条件が有効なら時間条件はスキップ
         timeSignal = true;
         Print("ProcessRealEntries: 時間条件チェック無効");
         entryReason += "時間条件チェック無効 ";
      }
   }
   
   // インジケーター条件のチェック
   bool hasActiveIndicators = (MA_Cross_Strategy != STRATEGY_DISABLED || 
                              RSI_Strategy != STRATEGY_DISABLED || 
                              BB_Strategy != STRATEGY_DISABLED || 
                              RCI_Strategy != STRATEGY_DISABLED || 
                              Stochastic_Strategy != STRATEGY_DISABLED || 
                              CCI_Strategy != STRATEGY_DISABLED || 
                              ADX_Strategy != STRATEGY_DISABLED);
   
   if(hasActiveIndicators) {
      // インジケーターが有効な場合、詳細なログを出力
      int enabledCount = 0;
      if(MA_Cross_Strategy != STRATEGY_DISABLED) enabledCount++;
      if(RSI_Strategy != STRATEGY_DISABLED) enabledCount++;
      if(BB_Strategy != STRATEGY_DISABLED) enabledCount++;
      if(RCI_Strategy != STRATEGY_DISABLED) enabledCount++;
      if(Stochastic_Strategy != STRATEGY_DISABLED) enabledCount++;
      if(CCI_Strategy != STRATEGY_DISABLED) enabledCount++;
      if(ADX_Strategy != STRATEGY_DISABLED) enabledCount++;
      
      Print("ProcessRealEntries: 有効なインジケーター数: ", enabledCount);
      
      if(enabledCount == 0) {
         indicatorSignal = false;
         Print("ProcessRealEntries: インジケーターが1つも有効になっていないため、インジケーター条件は不成立とします");
         entryReason += "インジケーター無効 ";
      } else {
         // インジケーターのチェック結果
         indicatorSignal = EvaluateIndicatorsForEntry(side);
         
         if(indicatorSignal) {
            // どのインジケーターがシグナルを出したか確認
            string activeSignals = GetActiveIndicatorSignals(side);
            entryReason += "インジケーター条件OK(" + activeSignals + ") ";
         } else {
            entryReason += "インジケーター条件NG ";
         }
      }
      
      Print("ProcessRealEntries: インジケーター条件=", indicatorSignal ? "成立" : "不成立");
   } else {
      // インジケーター条件が無効の場合
      if(!UseEvenOddHoursEntry) {
         // 両方無効の場合は特別処理
         indicatorSignal = false;
         Print("ProcessRealEntries: 時間条件とインジケーターの両方が無効のため、エントリーしません");
         entryReason += "両方の条件が無効 ";
      } else {
         // 時間条件が有効ならインジケーター条件はスキップ
         indicatorSignal = true;
         Print("ProcessRealEntries: インジケーター条件チェック無効");
         entryReason += "インジケーター条件チェック無効 ";
      }
   }
   
   // エントリー確認方法に応じた判断
   bool shouldEnter = false;
   
   if(!UseEvenOddHoursEntry && !hasActiveIndicators) {
      // 両方無効の場合は特別処理
      Print("ProcessRealEntries: 警告: 時間とインジケーターの両方の条件が無効です");
      shouldEnter = false; // デフォルトでエントリーしない
      entryReason += "（両方の条件が無効のためエントリーしません）";
   } else {
      shouldEnter = (timeSignal || indicatorSignal);
      if(shouldEnter) entryReason += "（いずれかの条件OK）";
      else entryReason += "（すべての条件がNG）";
   }
   
   Print("ProcessRealEntries: 最終エントリー判断: ", shouldEnter ? "エントリー実行" : "エントリーなし");
   
   // リアルポジションがない場合は新規エントリー
   if(shouldEnter)
   {
      // スプレッドチェック
      double spreadPoints = (GetAskPrice() - GetBidPrice()) / Point;
      if(spreadPoints <= MaxSpreadPoints || MaxSpreadPoints <= 0)
      {
         Print("ProcessRealEntries: リアル", direction, "エントリー実行 - 理由: ", entryReason);
         
         // 直接リアルエントリーを実行
         ExecuteRealEntry(operationType, entryReason);
      }
      else
      {
         Print("ProcessRealEntries: スプレッドが大きすぎるため、リアル", direction, "エントリーをスキップしました: ", 
               spreadPoints, " > ", MaxSpreadPoints);
      }
   } else {
      Print("ProcessRealEntries: リアル", direction, "エントリー条件不成立のためスキップします: ", entryReason);
   }
}