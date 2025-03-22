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
enum MA_BUY_TYPE {
   MA_BUY_OFF = 0,               // 無効
   MA_BUY_GOLDEN_CROSS = 1,      // ゴールデンクロスでエントリー(逆張り)
   MA_BUY_PRICE_ABOVE_MA = 2,    // 価格がMA上でエントリー(順張り)
   MA_BUY_FAST_ABOVE_SLOW = 3,   // 短期MAが長期MA上でエントリー(順張り)
   MA_BUY_DEAD_CROSS = 4,        // デッドクロスでエントリー(順張り)
   MA_BUY_PRICE_BELOW_MA = 5     // 価格がMA下でエントリー(逆張り)
};

enum MA_SELL_TYPE {
   MA_SELL_OFF = 0,              // 無効
   MA_SELL_DEAD_CROSS = 1,       // デッドクロスでエントリー(逆張り)
   MA_SELL_PRICE_BELOW_MA = 2,   // 価格がMA下でエントリー(順張り)
   MA_SELL_FAST_BELOW_SLOW = 3,  // 短期MAが長期MA下でエントリー(順張り)
   MA_SELL_GOLDEN_CROSS = 4,     // ゴールデンクロスでエントリー(順張り)
   MA_SELL_PRICE_ABOVE_MA = 5    // 価格がMA上でエントリー(逆張り)
};

// RSIシグナルタイプのenum定義
enum RSI_BUY_TYPE {
   RSI_BUY_OFF = 0,              // 無効
   RSI_BUY_OVERSOLD = 1,         // 売られすぎ（RSI<30）でエントリー(逆張り)
   RSI_BUY_OVERSOLD_EXIT = 2,    // 売られすぎから回復でエントリー(逆張り)
   RSI_BUY_OVERBOUGHT = 3,       // 買われすぎ（RSI>70）でエントリー(順張り)
   RSI_BUY_OVERBOUGHT_EXIT = 4   // 買われすぎから下落でエントリー(順張り)
};

enum RSI_SELL_TYPE {
   RSI_SELL_OFF = 0,             // 無効
   RSI_SELL_OVERBOUGHT = 1,      // 買われすぎ（RSI>70）でエントリー(逆張り)
   RSI_SELL_OVERBOUGHT_EXIT = 2, // 買われすぎから下落でエントリー(逆張り)
   RSI_SELL_OVERSOLD = 3,        // 売られすぎ（RSI<30）でエントリー(順張り)
   RSI_SELL_OVERSOLD_EXIT = 4    // 売られすぎから回復でエントリー(順張り)
};

// ボリンジャーバンドシグナルタイプ
enum BB_BUY_TYPE {
   BB_BUY_OFF = 0,               // 無効
   BB_BUY_TOUCH_LOWER = 1,       // 下限バンドタッチでエントリー(逆張り)
   BB_BUY_BREAK_UPPER = 2,       // 上限バンド突破でエントリー(順張り)
   BB_BUY_TOUCH_UPPER = 3,       // 上限バンドタッチでエントリー(順張り)
   BB_BUY_BREAK_LOWER = 4        // 下限バンド突破でエントリー(逆張り)
};

enum BB_SELL_TYPE {
   BB_SELL_OFF = 0,              // 無効
   BB_SELL_TOUCH_UPPER = 1,      // 上限バンドタッチでエントリー(逆張り)
   BB_SELL_BREAK_LOWER = 2,      // 下限バンド突破でエントリー(順張り)
   BB_SELL_TOUCH_LOWER = 3,      // 下限バンドタッチでエントリー(順張り)
   BB_SELL_BREAK_UPPER = 4       // 上限バンド突破でエントリー(逆張り)
};

// ストキャスティクスシグナルタイプ
enum STOCH_BUY_TYPE {
   STOCH_BUY_OFF = 0,                 // 無効
   STOCH_BUY_OVERSOLD = 1,            // 売られすぎでエントリー(逆張り)
   STOCH_BUY_K_CROSS_D_OVERSOLD = 2,  // %Kが%Dを上抜け（売られすぎ）(逆張り)
   STOCH_BUY_OVERSOLD_EXIT = 3,       // 売られすぎから脱出(逆張り)
   STOCH_BUY_OVERBOUGHT = 4,          // 買われすぎでエントリー(順張り)
   STOCH_BUY_K_CROSS_D_OVERBOUGHT = 5,// %Kが%Dを下抜け（買われすぎ）(順張り)
   STOCH_BUY_OVERBOUGHT_EXIT = 6      // 買われすぎから脱出(順張り)
};

enum STOCH_SELL_TYPE {
   STOCH_SELL_OFF = 0,                  // 無効
   STOCH_SELL_OVERBOUGHT = 1,           // 買われすぎでエントリー(逆張り)
   STOCH_SELL_K_CROSS_D_OVERBOUGHT = 2, // %Kが%Dを下抜け（買われすぎ）(逆張り)
   STOCH_SELL_OVERBOUGHT_EXIT = 3,      // 買われすぎから脱出(逆張り)
   STOCH_SELL_OVERSOLD = 4,             // 売られすぎでエントリー(順張り)
   STOCH_SELL_K_CROSS_D_OVERSOLD = 5,   // %Kが%Dを上抜け（売られすぎ）(順張り)
   STOCH_SELL_OVERSOLD_EXIT = 6         // 売られすぎから脱出(順張り)
};

// CCIシグナルタイプ
enum CCI_BUY_TYPE {
   CCI_BUY_OFF = 0,              // 無効
   CCI_BUY_OVERSOLD = 1,         // 売られすぎでエントリー(逆張り)
   CCI_BUY_OVERSOLD_EXIT = 2,    // 売られすぎから回復(逆張り)
   CCI_BUY_OVERBOUGHT = 3,       // 買われすぎでエントリー(順張り)
   CCI_BUY_OVERBOUGHT_EXIT = 4   // 買われすぎから下落(順張り)
};

enum CCI_SELL_TYPE {
   CCI_SELL_OFF = 0,             // 無効
   CCI_SELL_OVERBOUGHT = 1,      // 買われすぎでエントリー(逆張り)
   CCI_SELL_OVERBOUGHT_EXIT = 2, // 買われすぎから下落(逆張り)
   CCI_SELL_OVERSOLD = 3,        // 売られすぎでエントリー(順張り)
   CCI_SELL_OVERSOLD_EXIT = 4    // 売られすぎから回復(順張り)
};

// ADXシグナルタイプ
enum ADX_BUY_TYPE {
   ADX_BUY_OFF = 0,                    // 無効
   ADX_BUY_PLUS_DI_CROSS_MINUS_DI = 1, // +DIが-DIを上抜け(順張り)
   ADX_BUY_STRONG_TREND_PLUS_DI = 2,   // 強いトレンドで+DI > -DI(順張り)
   ADX_BUY_MINUS_DI_CROSS_PLUS_DI = 3, // -DIが+DIを上抜け(逆張り)
   ADX_BUY_STRONG_TREND_MINUS_DI = 4   // 強いトレンドで-DI > +DI(逆張り)
};

enum ADX_SELL_TYPE {
   ADX_SELL_OFF = 0,                   // 無効
   ADX_SELL_MINUS_DI_CROSS_PLUS_DI = 1,// -DIが+DIを上抜け(順張り)
   ADX_SELL_STRONG_TREND_MINUS_DI = 2, // 強いトレンドで-DI > +DI(順張り)
   ADX_SELL_PLUS_DI_CROSS_MINUS_DI = 3,// +DIが-DIを上抜け(逆張り)
   ADX_SELL_STRONG_TREND_PLUS_DI = 4   // 強いトレンドで+DI > -DI(逆張り)
};

// RCIシグナルタイプ
enum RCI_BUY_TYPE {
   RCI_BUY_OFF = 0,                    // 無効
   RCI_BUY_BELOW_MINUS_THRESHOLD = 1,  // -しきい値以下でエントリー(逆張り)
   RCI_BUY_RISING_FROM_BOTTOM = 2,     // -しきい値から上昇(逆張り)
   RCI_BUY_ABOVE_PLUS_THRESHOLD = 3,   // +しきい値以上でエントリー(順張り)
   RCI_BUY_FALLING_FROM_PEAK = 4       // +しきい値から下落(順張り)
};

enum RCI_SELL_TYPE {
   RCI_SELL_OFF = 0,                   // 無効
   RCI_SELL_ABOVE_PLUS_THRESHOLD = 1,  // +しきい値以上でエントリー(逆張り)
   RCI_SELL_FALLING_FROM_PEAK = 2,     // +しきい値から下落(逆張り)
   RCI_SELL_BELOW_MINUS_THRESHOLD = 3, // -しきい値以下でエントリー(順張り)
   RCI_SELL_RISING_FROM_BOTTOM = 4     // -しきい値から上昇(順張り)
};

//+------------------------------------------------------------------+
//| 戦略関連の設定変数                                               |
//+------------------------------------------------------------------+
// ==== MA クロス設定 ====
sinput string Comment_MA_Cross_Entry = ""; //+--- MAクロスエントリー設定 ---+
input STRATEGY_TYPE MA_Cross_Strategy = STRATEGY_DISABLED; // MAクロス戦略
input MA_BUY_TYPE MA_Buy_Signal = MA_BUY_GOLDEN_CROSS; // MA Buy シグナル
input MA_SELL_TYPE MA_Sell_Signal = MA_SELL_DEAD_CROSS; // MA Sell シグナル
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
input RSI_BUY_TYPE RSI_Buy_Signal = RSI_BUY_OVERSOLD; // RSI Buy シグナル
input RSI_SELL_TYPE RSI_Sell_Signal = RSI_SELL_OVERBOUGHT; // RSI Sell シグナル
input int RSI_Period = 14;                      // RSI期間
input int RSI_Price = PRICE_CLOSE;              // RSI適用価格
input int RSI_Overbought = 70;                  // 買われすぎレベル
input int RSI_Oversold = 30;                    // 売られすぎレベル
input int RSI_Signal_Shift = 1;                 // シグナル確認シフト

// ==== ボリンジャーバンド設定 ====
sinput string Comment_BB_Entry = ""; //+--- ボリンジャーバンドエントリー設定 ---+
input STRATEGY_TYPE BB_Strategy = STRATEGY_DISABLED; // ボリンジャーバンド戦略
input BB_BUY_TYPE BB_Buy_Signal = BB_BUY_TOUCH_LOWER; // BB Buy シグナル
input BB_SELL_TYPE BB_Sell_Signal = BB_SELL_TOUCH_UPPER; // BB Sell シグナル
input int BB_Period = 20;                       // ボリンジャーバンド期間
input double BB_Deviation = 2.0;                // 標準偏差
input int BB_Price = PRICE_CLOSE;               // 適用価格
input int BB_Signal_Shift = 1;                  // シグナル確認シフト

// ==== ストキャスティクス設定 ====
sinput string Comment_Stochastic_Entry = ""; //+--- ストキャスティクスエントリー設定 ---+
input STRATEGY_TYPE Stochastic_Strategy = STRATEGY_DISABLED; // ストキャスティクス戦略
input STOCH_BUY_TYPE Stochastic_Buy_Signal = STOCH_BUY_OVERSOLD; // Stoch Buy シグナル
input STOCH_SELL_TYPE Stochastic_Sell_Signal = STOCH_SELL_OVERBOUGHT; // Stoch Sell シグナル
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
input CCI_BUY_TYPE CCI_Buy_Signal = CCI_BUY_OVERSOLD; // CCI Buy シグナル
input CCI_SELL_TYPE CCI_Sell_Signal = CCI_SELL_OVERBOUGHT; // CCI Sell シグナル
input int CCI_Period = 14;                     // CCI期間
input int CCI_Price = PRICE_TYPICAL;           // CCI適用価格
input int CCI_Overbought = 100;                // 買われすぎレベル
input int CCI_Oversold = -100;                 // 売られすぎレベル
input int CCI_Signal_Shift = 1;                // シグナル確認シフト

// ==== ADX/DMI設定 ====
sinput string Comment_ADX_Entry = ""; //+--- ADX/DMIエントリー設定 ---+
input STRATEGY_TYPE ADX_Strategy = STRATEGY_DISABLED; // ADX/DMI戦略
input ADX_BUY_TYPE ADX_Buy_Signal = ADX_BUY_PLUS_DI_CROSS_MINUS_DI; // ADX Buy シグナル
input ADX_SELL_TYPE ADX_Sell_Signal = ADX_SELL_MINUS_DI_CROSS_PLUS_DI; // ADX Sell シグナル
input int ADX_Period = 14;                     // ADX期間
input int ADX_Threshold = 25;                  // ADXしきい値
input int ADX_Signal_Shift = 1;                // シグナル確認シフト

// ==== RCI設定 ====
sinput string Comment_RCI_Entry = ""; //+--- RCIエントリー設定 ---+
input STRATEGY_TYPE RCI_Strategy = STRATEGY_DISABLED; // RCI戦略
input RCI_BUY_TYPE RCI_Buy_Signal = RCI_BUY_BELOW_MINUS_THRESHOLD; // RCI Buy シグナル
input RCI_SELL_TYPE RCI_Sell_Signal = RCI_SELL_ABOVE_PLUS_THRESHOLD; // RCI Sell シグナル
input int RCI_Period = 9;                      // RCI期間
input int RCI_MidTerm_Period = 26;             // RCI中期期間
input int RCI_LongTerm_Period = 52;            // RCI長期期間
input int RCI_Threshold = 80;                  // RCIしきい値(±値)
input int RCI_Signal_Shift = 1;                // シグナル確認シフト


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
    
    // MA値の取得
    double fastMA_current, slowMA_current, fastMA_prev, slowMA_prev;
    
    if(side == 0) // Buy
    {
        if(MA_Buy_Signal == MA_BUY_OFF)
            return false;
            
        fastMA_current = iMA(Symbol(), 0, MA_Buy_Fast_Period, 0, MA_Method, MA_Price, MA_Cross_Shift);
        slowMA_current = iMA(Symbol(), 0, MA_Buy_Slow_Period, 0, MA_Method, MA_Price, MA_Cross_Shift);
        fastMA_prev = iMA(Symbol(), 0, MA_Buy_Fast_Period, 0, MA_Method, MA_Price, MA_Cross_Shift + 1);
        slowMA_prev = iMA(Symbol(), 0, MA_Buy_Slow_Period, 0, MA_Method, MA_Price, MA_Cross_Shift + 1);
        
        // 価格データの取得
        double price_current = iClose(Symbol(), 0, MA_Cross_Shift);
        double price_prev = iClose(Symbol(), 0, MA_Cross_Shift + 1);
        
        switch(MA_Buy_Signal)
        {
            case MA_BUY_GOLDEN_CROSS: // ゴールデンクロス(逆張り)
                return (fastMA_prev < slowMA_prev && fastMA_current > slowMA_current);
                
            case MA_BUY_PRICE_ABOVE_MA: // 価格がMA上(順張り)
                return (price_current > fastMA_current);
                
            case MA_BUY_FAST_ABOVE_SLOW: // 短期MAが長期MA上(順張り)
                return (fastMA_current > slowMA_current);
                
            case MA_BUY_DEAD_CROSS: // デッドクロス(順張り)
                return (fastMA_prev > slowMA_prev && fastMA_current < slowMA_current);
                
            case MA_BUY_PRICE_BELOW_MA: // 価格がMA下(逆張り)
                return (price_current < fastMA_current);
        }
    }
    else // Sell
    {
        if(MA_Sell_Signal == MA_SELL_OFF)
            return false;
            
        fastMA_current = iMA(Symbol(), 0, MA_Sell_Fast_Period, 0, MA_Method, MA_Price, MA_Cross_Shift);
        slowMA_current = iMA(Symbol(), 0, MA_Sell_Slow_Period, 0, MA_Method, MA_Price, MA_Cross_Shift);
        fastMA_prev = iMA(Symbol(), 0, MA_Sell_Fast_Period, 0, MA_Method, MA_Price, MA_Cross_Shift + 1);
        slowMA_prev = iMA(Symbol(), 0, MA_Sell_Slow_Period, 0, MA_Method, MA_Price, MA_Cross_Shift + 1);
        
        // 価格データの取得
        double price_current = iClose(Symbol(), 0, MA_Cross_Shift);
        double price_prev = iClose(Symbol(), 0, MA_Cross_Shift + 1);
        
        switch(MA_Sell_Signal)
        {
            case MA_SELL_DEAD_CROSS: // デッドクロス(逆張り)
                return (fastMA_prev > slowMA_prev && fastMA_current < slowMA_current);
                
            case MA_SELL_PRICE_BELOW_MA: // 価格がMA下(順張り)
                return (price_current < fastMA_current);
                
            case MA_SELL_FAST_BELOW_SLOW: // 短期MAが長期MA下(順張り)
                return (fastMA_current < slowMA_current);
                
            case MA_SELL_GOLDEN_CROSS: // ゴールデンクロス(順張り)
                return (fastMA_prev < slowMA_prev && fastMA_current > slowMA_current);
                
            case MA_SELL_PRICE_ABOVE_MA: // 価格がMA上(逆張り)
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
    
    // RSI値の取得
    double rsi_current = iRSI(Symbol(), 0, RSI_Period, RSI_Price, RSI_Signal_Shift);
    double rsi_prev = iRSI(Symbol(), 0, RSI_Period, RSI_Price, RSI_Signal_Shift + 1);
    
    // BUYシグナル
    if(side == 0)
    {
        if(RSI_Buy_Signal == RSI_BUY_OFF)
            return false;
            
        switch(RSI_Buy_Signal)
        {
            case RSI_BUY_OVERSOLD: // 売られすぎ(逆張り)
                return (rsi_current < RSI_Oversold);
                
            case RSI_BUY_OVERSOLD_EXIT: // 売られすぎから回復(逆張り)
                return (rsi_prev < RSI_Oversold && rsi_current >= RSI_Oversold);
                
            case RSI_BUY_OVERBOUGHT: // 買われすぎ(順張り)
                return (rsi_current > RSI_Overbought);
                
            case RSI_BUY_OVERBOUGHT_EXIT: // 買われすぎから下落(順張り)
                return (rsi_prev > RSI_Overbought && rsi_current <= RSI_Overbought);
        }
    }
    // SELLシグナル
    else
    {
        if(RSI_Sell_Signal == RSI_SELL_OFF)
            return false;
            
        switch(RSI_Sell_Signal)
        {
            case RSI_SELL_OVERBOUGHT: // 買われすぎ(逆張り)
                return (rsi_current > RSI_Overbought);
                
            case RSI_SELL_OVERBOUGHT_EXIT: // 買われすぎから下落(逆張り)
                return (rsi_prev > RSI_Overbought && rsi_current <= RSI_Overbought);
                
            case RSI_SELL_OVERSOLD: // 売られすぎ(順張り)
                return (rsi_current < RSI_Oversold);
                
            case RSI_SELL_OVERSOLD_EXIT: // 売られすぎから回復(順張り)
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
    
        double middle = iBands(Symbol(), 0, BB_Period, BB_Deviation, 0, BB_Price, MODE_MAIN, BB_Signal_Shift);
        double upper = iBands(Symbol(), 0, BB_Period, BB_Deviation, 0, BB_Price, MODE_UPPER, BB_Signal_Shift);
        double lower = iBands(Symbol(), 0, BB_Period, BB_Deviation, 0, BB_Price, MODE_LOWER, BB_Signal_Shift);
        
        double close_current = iClose(Symbol(), 0, BB_Signal_Shift);
        double close_prev = iClose(Symbol(), 0, BB_Signal_Shift + 1);
        
        // BUYシグナル
        if(side == 0)
        {
            if(BB_Buy_Signal == BB_BUY_OFF)
                return false;
                
            switch(BB_Buy_Signal)
            {
                case BB_BUY_TOUCH_LOWER: // 下限バンドタッチ後反発(逆張り)
                    return (close_prev <= lower && close_current > close_prev);
                    
                case BB_BUY_BREAK_UPPER: // 上限バンド突破(順張り)
                    return (close_prev < upper && close_current > upper);
                    
                case BB_BUY_TOUCH_UPPER: // 上限バンドタッチ後反落(順張り)
                    return (close_prev >= upper && close_current < close_prev);
                    
                case BB_BUY_BREAK_LOWER: // 下限バンド突破(逆張り)
                    return (close_prev > lower && close_current < lower);
            }
        }
        // SELLシグナル
        else
        {
            if(BB_Sell_Signal == BB_SELL_OFF)
                return false;
                
            switch(BB_Sell_Signal)
            {
                case BB_SELL_TOUCH_UPPER: // 上限バンドタッチ後反落(逆張り)
                    return (close_prev >= upper && close_current < close_prev);
                    
                case BB_SELL_BREAK_LOWER: // 下限バンド突破(順張り)
                    return (close_prev > lower && close_current < lower);
                    
                case BB_SELL_TOUCH_LOWER: // 下限バンドタッチ後反発(順張り)
                    return (close_prev <= lower && close_current > close_prev);
                    
                case BB_SELL_BREAK_UPPER: // 上限バンド突破(逆張り)
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
        
        // 価格データを取得
        for(int i = 0; i < period; i++)
        {
            prices[i] = iClose(Symbol(), 0, i + shift);
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
        
        // RCIの計算
        double rci_current = CalculateRCI(RCI_Period, RCI_Signal_Shift);
        double rci_prev = CalculateRCI(RCI_Period, RCI_Signal_Shift + 1);
        
        // 中期RCI
        double rci_mid_current = CalculateRCI(RCI_MidTerm_Period, RCI_Signal_Shift);
        
        // 長期RCI
        double rci_long_current = CalculateRCI(RCI_LongTerm_Period, RCI_Signal_Shift);
        
        // BUYシグナル
        if(side == 0)
        {
            if(RCI_Buy_Signal == RCI_BUY_OFF)
                return false;
            
            switch(RCI_Buy_Signal)
            {
                case RCI_BUY_BELOW_MINUS_THRESHOLD: // -しきい値以下(逆張り)
                    return (rci_current < -RCI_Threshold);
                    
                case RCI_BUY_RISING_FROM_BOTTOM: // -しきい値から上昇(逆張り)
                    return (rci_prev < -RCI_Threshold && rci_current > rci_prev && 
                            rci_mid_current < -50 && rci_long_current < -50);
                    
                case RCI_BUY_ABOVE_PLUS_THRESHOLD: // +しきい値以上(順張り)
                    return (rci_current > RCI_Threshold);
                    
                case RCI_BUY_FALLING_FROM_PEAK: // +しきい値から下落(順張り)
                    return (rci_prev > RCI_Threshold && rci_current < rci_prev && 
                            rci_mid_current > 50 && rci_long_current > 50);
            }
        }
        // SELLシグナル
        else
        {
            if(RCI_Sell_Signal == RCI_SELL_OFF)
                return false;
                
            switch(RCI_Sell_Signal)
            {
                case RCI_SELL_ABOVE_PLUS_THRESHOLD: // +しきい値以上(逆張り)
                    return (rci_current > RCI_Threshold);
                    
                case RCI_SELL_FALLING_FROM_PEAK: // +しきい値から下落(逆張り)
                    return (rci_prev > RCI_Threshold && rci_current < rci_prev && 
                            rci_mid_current > 50 && rci_long_current > 50);
                    
                case RCI_SELL_BELOW_MINUS_THRESHOLD: // -しきい値以下(順張り)
                    return (rci_current < -RCI_Threshold);
                    
                case RCI_SELL_RISING_FROM_BOTTOM: // -しきい値から上昇(順張り)
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
        
        double k_current = iStochastic(Symbol(), 0, Stochastic_K_Period, Stochastic_D_Period, Stochastic_Slowing, Stochastic_Method, Stochastic_Price_Field, MODE_MAIN, Stochastic_Signal_Shift);
        double k_prev = iStochastic(Symbol(), 0, Stochastic_K_Period, Stochastic_D_Period, Stochastic_Slowing, Stochastic_Method, Stochastic_Price_Field, MODE_MAIN, Stochastic_Signal_Shift + 1);
        double d_current = iStochastic(Symbol(), 0, Stochastic_K_Period, Stochastic_D_Period, Stochastic_Slowing, Stochastic_Method, Stochastic_Price_Field, MODE_SIGNAL, Stochastic_Signal_Shift);
        double d_prev = iStochastic(Symbol(), 0, Stochastic_K_Period, Stochastic_D_Period, Stochastic_Slowing, Stochastic_Method, Stochastic_Price_Field, MODE_SIGNAL, Stochastic_Signal_Shift + 1);
        
        // BUYシグナル
        if(side == 0)
        {
            if(Stochastic_Buy_Signal == STOCH_BUY_OFF)
                return false;
                
            switch(Stochastic_Buy_Signal)
            {
                case STOCH_BUY_OVERSOLD: // 売られすぎ(逆張り)
                    return (k_current < Stochastic_Oversold);
                    
                case STOCH_BUY_K_CROSS_D_OVERSOLD: // %Kが%Dを上抜け（売られすぎ）(逆張り)
                    return (k_prev < d_prev && k_current > d_current && k_prev < Stochastic_Oversold);
                    
                case STOCH_BUY_OVERSOLD_EXIT: // 売られすぎから脱出(逆張り)
                    return (k_prev < Stochastic_Oversold && k_current >= Stochastic_Oversold);
                    
                case STOCH_BUY_OVERBOUGHT: // 買われすぎ(順張り)
                    return (k_current > Stochastic_Overbought);
                    
                case STOCH_BUY_K_CROSS_D_OVERBOUGHT: // %Kが%Dを下抜け（買われすぎ）(順張り)
                    return (k_prev > d_prev && k_current < d_current && k_prev > Stochastic_Overbought);
                    
                case STOCH_BUY_OVERBOUGHT_EXIT: // 買われすぎから脱出(順張り)
                    return (k_prev > Stochastic_Overbought && k_current <= Stochastic_Overbought);
            }
        }
        // SELLシグナル
        else
        {
            if(Stochastic_Sell_Signal == STOCH_SELL_OFF)
                return false;
                
            switch(Stochastic_Sell_Signal)
            {
                case STOCH_SELL_OVERBOUGHT: // 買われすぎ(逆張り)
                    return (k_current > Stochastic_Overbought);
                    
                case STOCH_SELL_K_CROSS_D_OVERBOUGHT: // %Kが%Dを下抜け（買われすぎ）(逆張り)
                    return (k_prev > d_prev && k_current < d_current && k_prev > Stochastic_Overbought);
                    
                case STOCH_SELL_OVERBOUGHT_EXIT: // 買われすぎから脱出(逆張り)
                    return (k_prev > Stochastic_Overbought && k_current <= Stochastic_Overbought);
                    
                case STOCH_SELL_OVERSOLD: // 売られすぎ(順張り)
                    return (k_current < Stochastic_Oversold);
                    
                case STOCH_SELL_K_CROSS_D_OVERSOLD: // %Kが%Dを上抜け（売られすぎ）(順張り)
                    return (k_prev < d_prev && k_current > d_current && k_prev < Stochastic_Oversold);
                    
                case STOCH_SELL_OVERSOLD_EXIT: // 売られすぎから脱出(順張り)
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
        
        double cci_current = iCCI(Symbol(), 0, CCI_Period, CCI_Price, CCI_Signal_Shift);
        double cci_prev = iCCI(Symbol(), 0, CCI_Period, CCI_Price, CCI_Signal_Shift + 1);
        
        // BUYシグナル
        if(side == 0)
        {
            if(CCI_Buy_Signal == CCI_BUY_OFF)
                return false;
                
            switch(CCI_Buy_Signal)
            {
                case CCI_BUY_OVERSOLD: // 売られすぎ(逆張り)
                    return (cci_current < CCI_Oversold);
                    
                case CCI_BUY_OVERSOLD_EXIT: // 売られすぎから回復(逆張り)
                    return (cci_prev < CCI_Oversold && cci_current >= CCI_Oversold);
                    
                case CCI_BUY_OVERBOUGHT: // 買われすぎ(順張り)
                    return (cci_current > CCI_Overbought);
                    
                case CCI_BUY_OVERBOUGHT_EXIT: // 買われすぎから下落(順張り)
                    return (cci_prev > CCI_Overbought && cci_current <= CCI_Overbought);
            }
        }
        // SELLシグナル
        else
        {
            if(CCI_Sell_Signal == CCI_SELL_OFF)
                return false;
                
            switch(CCI_Sell_Signal)
            {
                case CCI_SELL_OVERBOUGHT: // 買われすぎ(逆張り)
                    return (cci_current > CCI_Overbought);
                    
                case CCI_SELL_OVERBOUGHT_EXIT: // 買われすぎから下落(逆張り)
                    return (cci_prev > CCI_Overbought && cci_current <= CCI_Overbought);
                    
                case CCI_SELL_OVERSOLD: // 売られすぎ(順張り)
                    return (cci_current < CCI_Oversold);
                    
                case CCI_SELL_OVERSOLD_EXIT: // 売られすぎから回復(順張り)
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
        
        double adx = iADX(Symbol(), 0, ADX_Period, PRICE_CLOSE, MODE_MAIN, ADX_Signal_Shift);
        double plus_di = iADX(Symbol(), 0, ADX_Period, PRICE_CLOSE, MODE_PLUSDI, ADX_Signal_Shift);
        double minus_di = iADX(Symbol(), 0, ADX_Period, PRICE_CLOSE, MODE_MINUSDI, ADX_Signal_Shift);
        double plus_di_prev = iADX(Symbol(), 0, ADX_Period, PRICE_CLOSE, MODE_PLUSDI, ADX_Signal_Shift + 1);
        double minus_di_prev = iADX(Symbol(), 0, ADX_Period, PRICE_CLOSE, MODE_MINUSDI, ADX_Signal_Shift + 1);
        
        // BUYシグナル
        if(side == 0)
        {
            if(ADX_Buy_Signal == ADX_BUY_OFF)
                return false;
                
            switch(ADX_Buy_Signal)
            {
                case ADX_BUY_PLUS_DI_CROSS_MINUS_DI: // +DIが-DIを上抜け(順張り)
                    return (plus_di_prev < minus_di_prev && plus_di > minus_di);
                    
                case ADX_BUY_STRONG_TREND_PLUS_DI: // 強いトレンドで+DI > -DI(順張り)
                    return (adx > ADX_Threshold && plus_di > minus_di);
                    
                case ADX_BUY_MINUS_DI_CROSS_PLUS_DI: // -DIが+DIを上抜け(逆張り)
                    return (minus_di_prev < plus_di_prev && minus_di > plus_di);
                    
                case ADX_BUY_STRONG_TREND_MINUS_DI: // 強いトレンドで-DI > +DI(逆張り)
                    return (adx > ADX_Threshold && minus_di > plus_di);
            }
        }
        // SELLシグナル
        else
        {
            if(ADX_Sell_Signal == ADX_SELL_OFF)
                return false;
                
            switch(ADX_Sell_Signal)
            {
                case ADX_SELL_MINUS_DI_CROSS_PLUS_DI: // -DIが+DIを上抜け(順張り)
                    return (minus_di_prev < plus_di_prev && minus_di > plus_di);
                    
                case ADX_SELL_STRONG_TREND_MINUS_DI: // 強いトレンドで-DI > +DI(順張り)
                    return (adx > ADX_Threshold && minus_di > plus_di);
                    
                case ADX_SELL_PLUS_DI_CROSS_MINUS_DI: // +DIが-DIを上抜け(逆張り)
                    return (plus_di_prev < minus_di_prev && plus_di > minus_di);
                    
                case ADX_SELL_STRONG_TREND_PLUS_DI: // 強いトレンドで+DI > -DI(逆張り)
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
//| Hosopi3_Strategy.mqh の ShouldEnterPosition関数                   |
//+------------------------------------------------------------------+
bool ShouldEnterPosition(int side)
{
    bool timeSignal = false;
    bool indicatorSignal = false;
    
    string direction = (side == 0) ? "Buy" : "Sell";
    Print("ShouldEnterPosition 開始 - direction=", direction);
    
    // 時間条件の評価
    if(g_EnableTimeEntry) {
        timeSignal = IsTimeEntryAllowed(side);
        Print("時間条件: ", timeSignal ? "成立" : "不成立");
    } else {
        // 時間条件チェックがOFFの場合
        timeSignal = false;
        Print("時間条件チェックはOFF");
        // 両方の条件が無効の場合の警告を追加
        if(!g_EnableIndicatorsEntry) {
            Print("警告: 時間とインジケーターの両方の条件が無効です");
        }
    }
    
    // インジケーター条件の評価
    if(g_EnableIndicatorsEntry) {
        // インジケーターが1つも有効でない場合のチェックを追加
        int enabledCount = 0;
        if(MA_Cross_Strategy != STRATEGY_DISABLED) enabledCount++;
        if(RSI_Strategy != STRATEGY_DISABLED) enabledCount++;
        if(BB_Strategy != STRATEGY_DISABLED) enabledCount++;
        if(RCI_Strategy != STRATEGY_DISABLED) enabledCount++;
        if(Stochastic_Strategy != STRATEGY_DISABLED) enabledCount++;
        if(CCI_Strategy != STRATEGY_DISABLED) enabledCount++;
        if(ADX_Strategy != STRATEGY_DISABLED) enabledCount++;
        
        Print("有効なインジケーター数: ", enabledCount);
        
        if(enabledCount == 0) {
            // 有効なインジケーターがない場合は明示的に false を返す
            indicatorSignal = false;
            Print("インジケーターが1つも有効になっていないため、条件は不成立");
        } else {
            // 個別にインジケーターを確認して詳細ログを出力
            bool ma_signal = (MA_Cross_Strategy != STRATEGY_DISABLED) ? CheckMASignal(side) : false;
            bool rsi_signal = (RSI_Strategy != STRATEGY_DISABLED) ? CheckRSISignal(side) : false;
            bool bb_signal = (BB_Strategy != STRATEGY_DISABLED) ? CheckBollingerSignal(side) : false;
            bool rci_signal = (RCI_Strategy != STRATEGY_DISABLED) ? CheckRCISignal(side) : false;
            bool stoch_signal = (Stochastic_Strategy != STRATEGY_DISABLED) ? CheckStochasticSignal(side) : false;
            bool cci_signal = (CCI_Strategy != STRATEGY_DISABLED) ? CheckCCISignal(side) : false;
            bool adx_signal = (ADX_Strategy != STRATEGY_DISABLED) ? CheckADXSignal(side) : false;
            
            Print("MA信号=", ma_signal, ", RSI信号=", rsi_signal, ", BB信号=", bb_signal,
                  ", RCI信号=", rci_signal, ", Stochastic信号=", stoch_signal,
                  ", CCI信号=", cci_signal, ", ADX信号=", adx_signal);
                  
            // インジケーターのチェック結果
            indicatorSignal = false; // デフォルトでfalse
            
            // 各インジケーターのシグナルを個別にチェック
            if(MA_Cross_Strategy != STRATEGY_DISABLED && ma_signal) indicatorSignal = true;
            if(RSI_Strategy != STRATEGY_DISABLED && rsi_signal) indicatorSignal = true;
            if(BB_Strategy != STRATEGY_DISABLED && bb_signal) indicatorSignal = true;
            if(RCI_Strategy != STRATEGY_DISABLED && rci_signal) indicatorSignal = true;
            if(Stochastic_Strategy != STRATEGY_DISABLED && stoch_signal) indicatorSignal = true;
            if(CCI_Strategy != STRATEGY_DISABLED && cci_signal) indicatorSignal = true;
            if(ADX_Strategy != STRATEGY_DISABLED && adx_signal) indicatorSignal = true;
            
            Print("インジケーター条件の最終結果: ", indicatorSignal ? "成立" : "不成立");
        }
    } else {
        // インジケーター条件チェックがOFFの場合
        if(!g_EnableTimeEntry) {
            // 両方無効の場合
            indicatorSignal = false;
            Print("インジケーター条件チェックはOFF（両方の条件が無効のため、エントリーしません）");
        } else {
            indicatorSignal = true;
            Print("インジケーター条件チェックはOFF");
        }
    }
    
    // 確認方法に応じた判断
    bool result;
    
    // 特殊ケース：両方の条件が無効の場合
    if(!g_EnableTimeEntry && !g_EnableIndicatorsEntry) {
        Print("警告: 時間条件とインジケーター条件が両方とも無効です");
        result = false; // デフォルトでfalseを返す
    } else if(1) {
        // どちらか1つでも条件を満たせばOK
        result = (timeSignal || indicatorSignal);
        Print("エントリー確認方法: いずれかの条件OK, 結果: ", result ? "成立" : "不成立");
    } else {
        // すべての条件を満たす必要あり
        result = (timeSignal && indicatorSignal);
        Print("エントリー確認方法: すべての条件必要, 結果: ", result ? "成立" : "不成立");
    }
    
    Print("ShouldEnterPosition 最終結果: ", result ? "エントリー条件成立" : "エントリー条件不成立");
    return result;
}
//+------------------------------------------------------------------+
//| Hosopi3_Strategy.mqh の ProcessStrategyLogic関数                  |
//+------------------------------------------------------------------+
void ProcessStrategyLogic()
{
   // 自動売買が無効の場合は何もしない
   if(!g_AutoTrading)
   {
      return;
   }
   
   // 時間条件とインジケーター条件が両方とも無効の場合はエントリーしない
   if(!g_EnableTimeEntry && !g_EnableIndicatorsEntry) {
      Print("警告: 時間条件とインジケーター条件が両方とも無効のため、エントリー処理をスキップします");
      return;
   }
   
   // リアルポジション有無を判定
   bool hasRealBuy = position_count(OP_BUY) > 0;
   bool hasRealSell = position_count(OP_SELL) > 0;
   
   // ゴーストモードの設定（NanpinSkipLevel に基づく）
   if(NanpinSkipLevel == SKIP_NONE) {
      g_GhostMode = false; // ゴーストモードは常に無効
   }
   
   // ゴーストエントリー機能がOFFの場合はゴーストモードを無効化
   if(!g_EnableGhostEntry) {
      g_GhostMode = false;
   }
   
   // リアルポジションがある場合
   if(hasRealBuy || hasRealSell)
   {
// ナンピン機能が有効な場合のみナンピン条件をチェック
if(g_EnableNanpin)
{
   // リアルポジションのナンピン条件をチェック
   CheckNanpinConditions(0); // Buy側のナンピン条件チェック
   CheckNanpinConditions(1); // Sell側のナンピン条件チェック
}
}
else
{
// リアルポジションがない場合

// 時間条件とインジケーター条件が両方とも無効の場合はエントリーしない
// 警告メッセージを削除（Printを削除）
if(!g_EnableTimeEntry && !g_EnableIndicatorsEntry) {
   return;
}

// ゴーストモードがONの場合
if(g_GhostMode && g_EnableGhostEntry)
{
   // 各方向のエントリー条件を確認
   bool buyCondition = ShouldEnterPosition(0);
   bool sellCondition = ShouldEnterPosition(1);
   
   // 条件を確認してエントリー
   if(buyCondition) {
      ProcessGhostEntries(0);
   }
   
   if(sellCondition) {
      ProcessGhostEntries(1);
   }
}
else
{
   // 各方向のエントリー条件を確認
   bool buyCondition = ShouldEnterPosition(0);
   bool sellCondition = ShouldEnterPosition(1);
   
   // ゴーストモードがOFFの場合は直接リアルエントリーを処理
   if(buyCondition) {
      ProcessRealEntries(0);
   }
   
   if(sellCondition) {
      ProcessRealEntries(1);
   }
}
}
}