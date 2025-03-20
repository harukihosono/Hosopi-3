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
   STRATEGY_TIME = 0,        // 時間エントリー
   STRATEGY_MA_CROSS = 1,    // MA クロス
   STRATEGY_RSI = 2,         // RSI
   STRATEGY_BOLLINGER = 3,   // ボリンジャーバンド
   STRATEGY_RCI = 4,         // RCI
   STRATEGY_MACD = 5,        // MACD
   STRATEGY_STOCHASTIC = 6,  // ストキャスティクス
   STRATEGY_ICHIMOKU = 7,    // 一目均衡表
   STRATEGY_CCI = 8,         // CCI
   STRATEGY_PARABOLIC = 9,   // パラボリックSAR
   STRATEGY_ADX = 10,        // ADX / DMI
   STRATEGY_ATR = 11         // ATR
};

// 利確タイプの列挙型
enum TP_TYPE {
   TP_FIXED = 0,            // 固定利確
   TP_TRAILING = 1,         // トレーリングストップ
   TP_BOLLINGER = 2,        // ボリンジャーバンド
   TP_MA = 3,               // 移動平均線
   TP_PARABOLIC = 4,        // パラボリックSAR
   TP_ICHIMOKU = 5,         // 一目均衡表
   TP_FIBONACCI = 6,        // フィボナッチリトレースメント
   TP_ATR = 7               // ATR倍数
};

//+------------------------------------------------------------------+
//| 戦略関連の設定変数                                               |
//+------------------------------------------------------------------+
// ==== MA クロス設定 ====
input bool MA_Cross_Enabled = false;           // MA クロス戦略を有効化
input int MA_Fast_Period = 5;                 // 短期MA期間
input int MA_Slow_Period = 20;                // 長期MA期間
input int MA_Method = MODE_SMA;               // MA計算方法
input int MA_Price = PRICE_CLOSE;             // MA適用価格
input int MA_Cross_Shift = 1;                 // シグナル確認シフト

// ==== RSI設定 ====
input bool RSI_Enabled = false;                // RSI戦略を有効化
input int RSI_Period = 14;                    // RSI期間
input int RSI_Price = PRICE_CLOSE;            // RSI適用価格
input int RSI_Overbought = 70;                // 買われすぎレベル
input int RSI_Oversold = 30;                  // 売られすぎレベル
input int RSI_Signal_Shift = 1;               // シグナル確認シフト

// ==== ボリンジャーバンド設定 ====
input bool BB_Enabled = false;                 // ボリンジャーバンド戦略を有効化
input int BB_Period = 20;                     // ボリンジャーバンド期間
input double BB_Deviation = 2.0;              // 標準偏差
input int BB_Price = PRICE_CLOSE;             // 適用価格
input int BB_Signal_Shift = 1;                // シグナル確認シフト

// ==== RCI設定 ====
input bool RCI_Enabled = false;                // RCI戦略を有効化
input int RCI_Period = 9;                     // RCI期間
input int RCI_MidTerm_Period = 26;            // RCI中期期間
input int RCI_LongTerm_Period = 52;           // RCI長期期間
input int RCI_Threshold = 80;                 // RCIしきい値(±値)
input int RCI_Signal_Shift = 1;               // シグナル確認シフト

// ==== MACD設定 ====
input bool MACD_Enabled = false;               // MACD戦略を有効化
input int MACD_Fast_EMA = 12;                 // MACD短期EMA
input int MACD_Slow_EMA = 26;                 // MACD長期EMA
input int MACD_Signal_Period = 9;             // MACDシグナル期間
input int MACD_Price = PRICE_CLOSE;           // MACD適用価格
input int MACD_Signal_Shift = 1;              // シグナル確認シフト

// ==== ストキャスティクス設定 ====
input bool Stochastic_Enabled = false;         // ストキャスティクス戦略を有効化
input int Stochastic_K_Period = 5;            // %K期間
input int Stochastic_D_Period = 3;            // %D期間
input int Stochastic_Slowing = 3;             // スローイング
input int Stochastic_Method = MODE_SMA;       // 計算方法
input int Stochastic_Price_Field = 0;         // 価格フィールド
input int Stochastic_Overbought = 80;         // 買われすぎレベル
input int Stochastic_Oversold = 20;           // 売られすぎレベル
input int Stochastic_Signal_Shift = 1;        // シグナル確認シフト

// ==== 一目均衡表設定 ====
input bool Ichimoku_Enabled = false;           // 一目均衡表戦略を有効化
input int Ichimoku_Tenkan_Period = 9;         // 転換線期間
input int Ichimoku_Kijun_Period = 26;         // 基準線期間
input int Ichimoku_Senkou_Span_B_Period = 52; // 先行スパンB期間
input int Ichimoku_Signal_Shift = 1;          // シグナル確認シフト

// ==== CCI設定 ====
input bool CCI_Enabled = false;                // CCI戦略を有効化
input int CCI_Period = 14;                    // CCI期間
input int CCI_Price = PRICE_TYPICAL;          // CCI適用価格
input int CCI_Overbought = 100;               // 買われすぎレベル
input int CCI_Oversold = -100;                // 売られすぎレベル
input int CCI_Signal_Shift = 1;               // シグナル確認シフト

// ==== パラボリックSAR設定 ====
input bool Parabolic_SAR_Enabled = false;      // パラボリックSAR戦略を有効化
input double Parabolic_Step = 0.02;            // ステップ
input double Parabolic_Maximum = 0.2;          // 最大値
input int Parabolic_Signal_Shift = 1;          // シグナル確認シフト

// ==== ADX/DMI設定 ====
input bool ADX_Enabled = false;                // ADX/DMI戦略を有効化
input int ADX_Period = 14;                    // ADX期間
input int ADX_Threshold = 25;                 // ADXしきい値
input int ADX_Signal_Shift = 1;               // シグナル確認シフト

// ==== ATR戦略設定 ====
input bool ATR_Enabled = false;                // ATR戦略を有効化
input int ATR_Period = 14;                    // ATR期間
input double ATR_Multiplier = 2.0;            // ATR倍率
input int ATR_Signal_Shift = 1;               // シグナル確認シフト

// ==== 利確設定 ====
input bool Enable_TP = true;                 // 利確機能を有効化
input TP_TYPE TP_Mode = TP_FIXED;             // 利確タイプ

// ==== 固定利確設定 ====
input int Fixed_TP_Points = 2000;              // 固定利確幅（ポイント）

// ==== トレーリングストップ設定 ====
input bool Enable_Trailing_Stop = false;      // トレーリングストップを有効化
input int Trailing_Start = 200;               // トレーリング開始ポイント
input int Trailing_Step = 100;                // トレーリングステップ
input int Trailing_Stop = 100;                // トレーリングストップ幅

// ==== ATR利確設定 ====
input int ATR_TP_Period = 14;                // ATR期間（利確用）
input double ATR_TP_Multiplier = 2.0;         // ATR倍率（利確用）

// ==== MA利確設定 ====
input int MA_TP_Period = 20;                 // MA期間（利確用）
input int MA_TP_Method = MODE_SMA;            // MA計算方法（利確用）
input int MA_TP_Price = PRICE_CLOSE;          // MA適用価格（利確用）

// ==== ボリンジャーバンド利確設定 ====
input int BB_TP_Period = 20;                 // ボリンジャーバンド期間（利確用）
input double BB_TP_Deviation = 2.0;           // 標準偏差（利確用）
input int BB_TP_Price = PRICE_CLOSE;          // 適用価格（利確用）

// ==== パラボリックSAR利確設定 ====
input double Parabolic_TP_Step = 0.02;        // ステップ（利確用）
input double Parabolic_TP_Maximum = 0.2;      // 最大値（利確用）

// ==== 一目均衡表利確設定 ====
input int Ichimoku_TP_Tenkan_Period = 9;     // 転換線期間（利確用）
input int Ichimoku_TP_Kijun_Period = 26;     // 基準線期間（利確用）
input int Ichimoku_TP_Senkou_Span_B_Period = 52; // 先行スパンB期間（利確用）

// ==== フィボナッチリトレースメント利確設定 ====
input double Fibo_TP_Level = 0.618;           // フィボナッチレベル（利確用）

//+------------------------------------------------------------------+
//| 戦略評価 - 入口関数                                               |
//+------------------------------------------------------------------+
bool EvaluateStrategyForEntry(int side)
{
    // side: 0 = Buy, 1 = Sell
    bool entrySignal = false;
    
    // 時間戦略（基本戦略）は常に評価
    bool timeEntryAllowed = IsTimeEntryAllowed(side);
    
    // すべての有効戦略のシグナルを評価
    bool strategySignals = false;
    int enabledStrategies = 0;
    
    // MA クロス
    if(MA_Cross_Enabled) {
        enabledStrategies++;
        if(CheckMASignal(side)) strategySignals = true;
    }
    
    // RSI
    if(RSI_Enabled) {
        enabledStrategies++;
        if(CheckRSISignal(side)) strategySignals = true;
    }
    
    // ボリンジャーバンド
    if(BB_Enabled) {
        enabledStrategies++;
        if(CheckBollingerSignal(side)) strategySignals = true;
    }
    
    // RCI
    if(RCI_Enabled) {
        enabledStrategies++;
        if(CheckRCISignal(side)) strategySignals = true;
    }
    
    // MACD
    if(MACD_Enabled) {
        enabledStrategies++;
        if(CheckMACDSignal(side)) strategySignals = true;
    }
    
    // ストキャスティクス
    if(Stochastic_Enabled) {
        enabledStrategies++;
        if(CheckStochasticSignal(side)) strategySignals = true;
    }
    
    // 一目均衡表
    if(Ichimoku_Enabled) {
        enabledStrategies++;
        if(CheckIchimokuSignal(side)) strategySignals = true;
    }
    
    // CCI
    if(CCI_Enabled) {
        enabledStrategies++;
        if(CheckCCISignal(side)) strategySignals = true;
    }
    
    // パラボリックSAR
    if(Parabolic_SAR_Enabled) {
        enabledStrategies++;
        if(CheckParabolicSARSignal(side)) strategySignals = true;
    }
    
    // ADX/DMI
    if(ADX_Enabled) {
        enabledStrategies++;
        if(CheckADXSignal(side)) strategySignals = true;
    }
    
    // ATR
    if(ATR_Enabled) {
        enabledStrategies++;
        if(CheckATRSignal(side)) strategySignals = true;
    }
    
    // 最終判断
    // 時間条件が許可され、かつ有効化された戦略のうち少なくとも1つがシグナルを出した場合
    if(timeEntryAllowed && (enabledStrategies == 0 || strategySignals)) {
        entrySignal = true;
    }
    
    return entrySignal;
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
    // トレンド判断（過去のバーでMAクロスが発生したか）
    double fastMA_current = iMA(Symbol(), 0, MA_Fast_Period, 0, MA_Method, MA_Price, MA_Cross_Shift);
    double slowMA_current = iMA(Symbol(), 0, MA_Slow_Period, 0, MA_Method, MA_Price, MA_Cross_Shift);
    double fastMA_prev = iMA(Symbol(), 0, MA_Fast_Period, 0, MA_Method, MA_Price, MA_Cross_Shift + 1);
    double slowMA_prev = iMA(Symbol(), 0, MA_Slow_Period, 0, MA_Method, MA_Price, MA_Cross_Shift + 1);
    
    if(side == 0) // Buy
    {
        // 短期MAが長期MAを下から上へクロス
        return (fastMA_prev < slowMA_prev && fastMA_current > slowMA_current);
    }
    else // Sell
    {
        // 短期MAが長期MAを上から下へクロス
        return (fastMA_prev > slowMA_prev && fastMA_current < slowMA_current);
    }
}

//+------------------------------------------------------------------+
//| RSI戦略のシグナル判断                                           |
//+------------------------------------------------------------------+
bool CheckRSISignal(int side)
{
    double rsi_current = iRSI(Symbol(), 0, RSI_Period, RSI_Price, RSI_Signal_Shift);
    double rsi_prev = iRSI(Symbol(), 0, RSI_Period, RSI_Price, RSI_Signal_Shift + 1);
    
    if(side == 0) // Buy
    {
        // RSIが売られすぎレベルから上昇
        return (rsi_prev < RSI_Oversold && rsi_current >= RSI_Oversold);
    }
    else // Sell
    {
        // RSIが買われすぎレベルから下落
        return (rsi_prev > RSI_Overbought && rsi_current <= RSI_Overbought);
    }
}

//+------------------------------------------------------------------+
//| ボリンジャーバンド戦略のシグナル判断                               |
//+------------------------------------------------------------------+
bool CheckBollingerSignal(int side)
{
    double middle = iBands(Symbol(), 0, BB_Period, BB_Deviation, 0, BB_Price, MODE_MAIN, BB_Signal_Shift);
    double upper = iBands(Symbol(), 0, BB_Period, BB_Deviation, 0, BB_Price, MODE_UPPER, BB_Signal_Shift);
    double lower = iBands(Symbol(), 0, BB_Period, BB_Deviation, 0, BB_Price, MODE_LOWER, BB_Signal_Shift);
    
    double close_current = iClose(Symbol(), 0, BB_Signal_Shift);
    double close_prev = iClose(Symbol(), 0, BB_Signal_Shift + 1);
    
    if(side == 0) // Buy
    {
        // 価格が下限バンドに触れた後、上昇に転じた
        return (close_prev <= lower && close_current > close_prev);
    }
    else // Sell
    {
        // 価格が上限バンドに触れた後、下落に転じた
        return (close_prev >= upper && close_current < close_prev);
    }
}

//+------------------------------------------------------------------+
//| RCI戦略のシグナル判断                                           |
//+------------------------------------------------------------------+
bool CheckRCISignal(int side)
{
    // RCIの計算
    double rci_current = CalculateRCI(RCI_Period, RCI_Signal_Shift);
    double rci_prev = CalculateRCI(RCI_Period, RCI_Signal_Shift + 1);
    
    // 中期RCI
    double rci_mid_current = CalculateRCI(RCI_MidTerm_Period, RCI_Signal_Shift);
    
    // 長期RCI
    double rci_long_current = CalculateRCI(RCI_LongTerm_Period, RCI_Signal_Shift);
    
    if(side == 0) // Buy
    {
        // 短期RCIが-RCI_Thresholdを下回った後、上昇に転じた場合
        // かつ中期・長期RCIも-50を下回っている（トレンド方向の確認）
        return (rci_prev < -RCI_Threshold && rci_current > rci_prev && 
                rci_mid_current < -50 && rci_long_current < -50);
    }
    else // Sell
    {
        // 短期RCIがRCI_Thresholdを上回った後、下落に転じた場合
        // かつ中期・長期RCIも50を上回っている（トレンド方向の確認）
        return (rci_prev > RCI_Threshold && rci_current < rci_prev && 
                rci_mid_current > 50 && rci_long_current > 50);
    }
}

//+------------------------------------------------------------------+
//| RCI（ランク相関係数）の計算 - 代替修正版                          |
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
//| MACD戦略のシグナル判断                                           |
//+------------------------------------------------------------------+
bool CheckMACDSignal(int side)
{
    double macd_current = iMACD(Symbol(), 0, MACD_Fast_EMA, MACD_Slow_EMA, MACD_Signal_Period, MACD_Price, MODE_MAIN, MACD_Signal_Shift);
    double macd_prev = iMACD(Symbol(), 0, MACD_Fast_EMA, MACD_Slow_EMA, MACD_Signal_Period, MACD_Price, MODE_MAIN, MACD_Signal_Shift + 1);
    double signal_current = iMACD(Symbol(), 0, MACD_Fast_EMA, MACD_Slow_EMA, MACD_Signal_Period, MACD_Price, MODE_SIGNAL, MACD_Signal_Shift);
    double signal_prev = iMACD(Symbol(), 0, MACD_Fast_EMA, MACD_Slow_EMA, MACD_Signal_Period, MACD_Price, MODE_SIGNAL, MACD_Signal_Shift + 1);
    
    if(side == 0) // Buy
    {
        // MACDがシグナルラインを下から上へクロス
        return (macd_prev < signal_prev && macd_current > signal_current);
    }
    else // Sell
    {
        // MACDがシグナルラインを上から下へクロス
        return (macd_prev > signal_prev && macd_current < signal_current);
    }
}

//+------------------------------------------------------------------+
//| ストキャスティクス戦略のシグナル判断                              |
//+------------------------------------------------------------------+
bool CheckStochasticSignal(int side)
{
    double k_current = iStochastic(Symbol(), 0, Stochastic_K_Period, Stochastic_D_Period, Stochastic_Slowing, Stochastic_Method, Stochastic_Price_Field, MODE_MAIN, Stochastic_Signal_Shift);
    double k_prev = iStochastic(Symbol(), 0, Stochastic_K_Period, Stochastic_D_Period, Stochastic_Slowing, Stochastic_Method, Stochastic_Price_Field, MODE_MAIN, Stochastic_Signal_Shift + 1);
    double d_current = iStochastic(Symbol(), 0, Stochastic_K_Period, Stochastic_D_Period, Stochastic_Slowing, Stochastic_Method, Stochastic_Price_Field, MODE_SIGNAL, Stochastic_Signal_Shift);
    double d_prev = iStochastic(Symbol(), 0, Stochastic_K_Period, Stochastic_D_Period, Stochastic_Slowing, Stochastic_Method, Stochastic_Price_Field, MODE_SIGNAL, Stochastic_Signal_Shift + 1);
    
    if(side == 0) // Buy
    {
        // %Kが%Dを下から上へクロス（売られすぎ領域で）
        return (k_prev < d_prev && k_current > d_current && k_prev < Stochastic_Oversold);
    }
    else // Sell
    {
        // %Kが%Dを上から下へクロス（買われすぎ領域で）
        return (k_prev > d_prev && k_current < d_current && k_prev > Stochastic_Overbought);
    }
}

//+------------------------------------------------------------------+
//| 一目均衡表戦略のシグナル判断                                      |
//+------------------------------------------------------------------+
bool CheckIchimokuSignal(int side)
{
    double tenkan = iIchimoku(Symbol(), 0, Ichimoku_Tenkan_Period, Ichimoku_Kijun_Period, Ichimoku_Senkou_Span_B_Period, MODE_TENKANSEN, Ichimoku_Signal_Shift);
    double kijun = iIchimoku(Symbol(), 0, Ichimoku_Tenkan_Period, Ichimoku_Kijun_Period, Ichimoku_Senkou_Span_B_Period, MODE_KIJUNSEN, Ichimoku_Signal_Shift);
    double tenkan_prev = iIchimoku(Symbol(), 0, Ichimoku_Tenkan_Period, Ichimoku_Kijun_Period, Ichimoku_Senkou_Span_B_Period, MODE_TENKANSEN, Ichimoku_Signal_Shift + 1);
    double kijun_prev = iIchimoku(Symbol(), 0, Ichimoku_Tenkan_Period, Ichimoku_Kijun_Period, Ichimoku_Senkou_Span_B_Period, MODE_KIJUNSEN, Ichimoku_Signal_Shift + 1);
    
    double senkou_span_a = iIchimoku(Symbol(), 0, Ichimoku_Tenkan_Period, Ichimoku_Kijun_Period, Ichimoku_Senkou_Span_B_Period, MODE_SENKOUSPANA, Ichimoku_Signal_Shift);
    double senkou_span_b = iIchimoku(Symbol(), 0, Ichimoku_Tenkan_Period, Ichimoku_Kijun_Period, Ichimoku_Senkou_Span_B_Period, MODE_SENKOUSPANB, Ichimoku_Signal_Shift);
    double close = iClose(Symbol(), 0, Ichimoku_Signal_Shift);
    
    if(side == 0) // Buy
    {
        // 転換線が基準線を下から上へクロスし、価格が雲の上にある
        return (tenkan_prev < kijun_prev && tenkan > kijun && close > MathMax(senkou_span_a, senkou_span_b));
    }
    else // Sell
    {
        // 転換線が基準線を上から下へクロスし、価格が雲の下にある
        return (tenkan_prev > kijun_prev && tenkan < kijun && close < MathMin(senkou_span_a, senkou_span_b));
    }
}

//+------------------------------------------------------------------+
//| CCI戦略のシグナル判断                                            |
//+------------------------------------------------------------------+
bool CheckCCISignal(int side)
{
    double cci_current = iCCI(Symbol(), 0, CCI_Period, CCI_Price, CCI_Signal_Shift);
    double cci_prev = iCCI(Symbol(), 0, CCI_Period, CCI_Price, CCI_Signal_Shift + 1);
    
    if(side == 0) // Buy
    {
        // CCIが売られすぎレベルから上昇に転じた
        return (cci_prev < CCI_Oversold && cci_current > CCI_Oversold);
    }
    else // Sell
    {
        // CCIが買われすぎレベルから下落に転じた
        return (cci_prev > CCI_Overbought && cci_current < CCI_Overbought);
    }
}

//+------------------------------------------------------------------+
//| パラボリックSAR戦略のシグナル判断                                |
//+------------------------------------------------------------------+
bool CheckParabolicSARSignal(int side)
{
    double sar_current = iSAR(Symbol(), 0, Parabolic_Step, Parabolic_Maximum, Parabolic_Signal_Shift);
    double sar_prev = iSAR(Symbol(), 0, Parabolic_Step, Parabolic_Maximum, Parabolic_Signal_Shift + 1);
    double close_current = iClose(Symbol(), 0, Parabolic_Signal_Shift);
    double close_prev = iClose(Symbol(), 0, Parabolic_Signal_Shift + 1);
    
    if(side == 0) // Buy
    {
        // 価格がSARを上に抜けた（SARが価格の下に移動）
        return (close_prev < sar_prev && close_current > sar_current);
    }
    else // Sell
    {
        // 価格がSARを下に抜けた（SARが価格の上に移動）
        return (close_prev > sar_prev && close_current < sar_current);
    }
}

//+------------------------------------------------------------------+
//| ADX/DMI戦略のシグナル判断                                       |
//+------------------------------------------------------------------+
bool CheckADXSignal(int side)
{
    double adx = iADX(Symbol(), 0, ADX_Period, PRICE_CLOSE, MODE_MAIN, ADX_Signal_Shift);
    double plus_di = iADX(Symbol(), 0, ADX_Period, PRICE_CLOSE, MODE_PLUSDI, ADX_Signal_Shift);
    double minus_di = iADX(Symbol(), 0, ADX_Period, PRICE_CLOSE, MODE_MINUSDI, ADX_Signal_Shift);
    double plus_di_prev = iADX(Symbol(), 0, ADX_Period, PRICE_CLOSE, MODE_PLUSDI, ADX_Signal_Shift + 1);
    double minus_di_prev = iADX(Symbol(), 0, ADX_Period, PRICE_CLOSE, MODE_MINUSDI, ADX_Signal_Shift + 1);
    
    if(side == 0) // Buy
    {
        // ADXが閾値を上回り、+DIが-DIを下から上へクロス
        return (adx > ADX_Threshold && plus_di_prev < minus_di_prev && plus_di > minus_di);
    }
    else // Sell
    {
        // ADXが閾値を上回り、-DIが+DIを下から上へクロス
        return (adx > ADX_Threshold && minus_di_prev < plus_di_prev && minus_di > plus_di);
    }
}

//+------------------------------------------------------------------+
//| ATR戦略のシグナル判断                                           |
//+------------------------------------------------------------------+
bool CheckATRSignal(int side)
{
    // ATR値を取得
    double atr = iATR(Symbol(), 0, ATR_Period, ATR_Signal_Shift);
    double atr_prev = iATR(Symbol(), 0, ATR_Period, ATR_Signal_Shift + 1);
    
    // 平均ATRを計算（過去数バーの平均）
    double avg_atr = 0;
    for(int i = ATR_Signal_Shift; i < ATR_Signal_Shift + 10; i++)
    {
        avg_atr += iATR(Symbol(), 0, ATR_Period, i);
    }
    avg_atr /= 10;
    
    // 近接した高値・安値を取得
    double high = iHigh(Symbol(), 0, iHighest(Symbol(), 0, MODE_HIGH, 5, ATR_Signal_Shift));
    double low = iLow(Symbol(), 0, iLowest(Symbol(), 0, MODE_LOW, 5, ATR_Signal_Shift));
    double close = iClose(Symbol(), 0, ATR_Signal_Shift);
    double prev_close = iClose(Symbol(), 0, ATR_Signal_Shift + 1);
    
    // ボラティリティブレイクアウト判定
    bool volatility_increased = (atr > avg_atr * ATR_Multiplier);
    
    if(side == 0) // Buy
    {
        // ボラティリティ増加とともに、前回高値を上抜け
        return (volatility_increased && close > high - atr && close > prev_close);
    }
    else // Sell
    {
        // ボラティリティ増加とともに、前回安値を下抜け
        return (volatility_increased && close < low + atr && close < prev_close);
    }
}

//+------------------------------------------------------------------+
//| 利確条件のチェック - 新バージョン                                 |
//+------------------------------------------------------------------+
bool CheckTakeProfitCondition(int side, double avg_price)
{
    // 利確機能が無効の場合はスキップ
    if(!Enable_TP)
        return false;
    
    // 現在価格を取得（BuyならBid、SellならAsk）
    double current_price = (side == 0) ? GetBidPrice() : GetAskPrice();
    
    // 利確条件の判定
    bool tpCondition = false;
    
    // 利確タイプにより分岐
    switch(TP_Mode)
    {
        case TP_FIXED:
        {
            // 固定利確
            if(side == 0) // Buy
                tpCondition = (current_price > avg_price + Fixed_TP_Points * Point);
            else // Sell
                tpCondition = (current_price < avg_price - Fixed_TP_Points * Point);
            break;
        }
        
        case TP_TRAILING:
        {
            // トレーリングストップの条件チェックは別関数で実装
            tpCondition = CheckTrailingStopCondition(side, avg_price);
            break;
        }
        
        case TP_BOLLINGER:
        {
            // ボリンジャーバンド利確
            double bb_upper = iBands(Symbol(), 0, BB_TP_Period, BB_TP_Deviation, 0, BB_TP_Price, MODE_UPPER, 0);
            double bb_lower = iBands(Symbol(), 0, BB_TP_Period, BB_TP_Deviation, 0, BB_TP_Price, MODE_LOWER, 0);
            
            if(side == 0) // Buy
                tpCondition = (current_price >= bb_upper);
            else // Sell
                tpCondition = (current_price <= bb_lower);
            break;
        }
        
        case TP_MA:
        {
            // 移動平均線利確
            double ma = iMA(Symbol(), 0, MA_TP_Period, 0, MA_TP_Method, MA_TP_Price, 0);
            
            if(side == 0) // Buy
                tpCondition = (current_price >= ma && current_price > avg_price);
            else // Sell
                tpCondition = (current_price <= ma && current_price < avg_price);
            break;
        }
        
        case TP_PARABOLIC:
        {
            // パラボリックSAR利確
            double sar = iSAR(Symbol(), 0, Parabolic_TP_Step, Parabolic_TP_Maximum, 0);
            
            if(side == 0) // Buy
                tpCondition = (current_price <= sar && current_price > avg_price);
            else // Sell
                tpCondition = (current_price >= sar && current_price < avg_price);
            break;
        }
        
        case TP_ICHIMOKU:
        {
            // 一目均衡表利確
            double tenkan = iIchimoku(Symbol(), 0, Ichimoku_TP_Tenkan_Period, Ichimoku_TP_Kijun_Period, Ichimoku_TP_Senkou_Span_B_Period, MODE_TENKANSEN, 0);
            double kijun = iIchimoku(Symbol(), 0, Ichimoku_TP_Tenkan_Period, Ichimoku_TP_Kijun_Period, Ichimoku_TP_Senkou_Span_B_Period, MODE_KIJUNSEN, 0);
            
            if(side == 0) // Buy
                tpCondition = ((current_price >= kijun || current_price <= tenkan) && current_price > avg_price);
            else // Sell
                tpCondition = ((current_price <= kijun || current_price >= tenkan) && current_price < avg_price);
            break;
        }
        
        case TP_FIBONACCI:
        {
            // フィボナッチリトレースメント利確
            // トレンドの高値安値を取得
            double trend_high = iHigh(Symbol(), 0, iHighest(Symbol(), 0, MODE_HIGH, 20, 0));
            double trend_low = iLow(Symbol(), 0, iLowest(Symbol(), 0, MODE_LOW, 20, 0));
            
            // フィボナッチレベルを計算
            double fibo_level;
            
            if(side == 0) // Buy
            {
                // 上昇トレンドでのリトレースメント
                fibo_level = trend_low + (trend_high - trend_low) * Fibo_TP_Level;
                tpCondition = (current_price >= fibo_level && current_price > avg_price);
            }
            else // Sell
            {
                // 下降トレンドでのリトレースメント
                fibo_level = trend_high - (trend_high - trend_low) * Fibo_TP_Level;
                tpCondition = (current_price <= fibo_level && current_price < avg_price);
            }
            break;
        }
        
        case TP_ATR:
        {
            // ATRベースの利確
            double atr = iATR(Symbol(), 0, ATR_TP_Period, 0);
            
            if(side == 0) // Buy
                tpCondition = (current_price >= avg_price + atr * ATR_TP_Multiplier);
            else // Sell
                tpCondition = (current_price <= avg_price - atr * ATR_TP_Multiplier);
            break;
        }
    }
    
    return tpCondition;
}

//+------------------------------------------------------------------+
//| トレーリングストップ条件のチェック                                |
//+------------------------------------------------------------------+
bool CheckTrailingStopCondition(int side, double avg_price)
{
    // トレーリングストップが無効の場合はスキップ
    if(!Enable_Trailing_Stop)
        return false;
    
    // 現在価格を取得（BuyならBid、SellならAsk）
    double current_price = (side == 0) ? GetBidPrice() : GetAskPrice();
    
    // 利益（ピップ単位）
    double profit_points = 0;
    
    if(side == 0) // Buy
        profit_points = (current_price - avg_price) / Point;
    else // Sell
        profit_points = (avg_price - current_price) / Point;
    
    // トレーリング発動条件のチェック
    static bool trailing_activated = false;
    static double trailing_stop_level = 0;
    
    // 利益がトレーリング開始ポイントを超えたか
    if(profit_points >= Trailing_Start)
    {
        // トレーリング発動
        if(!trailing_activated)
        {
            trailing_activated = true;
            trailing_stop_level = (side == 0) ? 
                                avg_price + (Trailing_Start - Trailing_Stop) * Point : 
                                avg_price - (Trailing_Start - Trailing_Stop) * Point;
        }
        
        // トレーリングレベルを更新
        if(side == 0) // Buy
        {
            double new_stop = current_price - Trailing_Stop * Point;
            if(new_stop > trailing_stop_level)
                trailing_stop_level = new_stop;
            
            // 現在価格がトレーリングストップレベルを下回ったら決済
            return (current_price <= trailing_stop_level);
        }
        else // Sell
        {
            double new_stop = current_price + Trailing_Stop * Point;
            if(new_stop < trailing_stop_level || trailing_stop_level == 0)
                trailing_stop_level = new_stop;
            
            // 現在価格がトレーリングストップレベルを上回ったら決済
            return (current_price >= trailing_stop_level);
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
//| 戦略による利確条件評価 - CheckTakeProfitConditions関数用のインターフェース |
//+------------------------------------------------------------------+
bool ShouldTakeProfit(int side, double avg_price)
{
    // 利確条件の評価
    return CheckTakeProfitCondition(side, avg_price);
}

//+------------------------------------------------------------------+
//| OnTick関数内で呼び出す戦略評価マスター関数 - 修正版              |
//+------------------------------------------------------------------+
void ProcessStrategyLogic()
{
    // 自動売買が無効の場合は何もしない
    if(!g_AutoTrading)
    {
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
        
        // ゴーストモードがONの場合
        if(g_GhostMode && g_EnableGhostEntry)
        {
            // 時間とインジケーターの条件を確認してエントリー
            if(ShouldEnterPosition(0)) ProcessGhostEntries(0);
            if(ShouldEnterPosition(1)) ProcessGhostEntries(1);
        }
        else
        {
            // ゴーストモードがOFFの場合は直接リアルエントリーを処理
            if(ShouldEnterPosition(0)) ProcessRealEntries(0);
            if(ShouldEnterPosition(1)) ProcessRealEntries(1);
        }
    }
    
    // 利確条件のチェック
    if(g_EnableFixedTP || g_EnableIndicatorsTP) {
        // 新しい利確ロジックを使用
        ProcessTakeProfitLogic(0); // Buy側の利確条件チェック
        ProcessTakeProfitLogic(1); // Sell側の利確条件チェック
    }
}

//+------------------------------------------------------------------+
//| エントリー条件判断 - 修正版                                      |
//+------------------------------------------------------------------+
bool ShouldEnterPosition(int side)
{
    bool timeSignal = false;
    bool indicatorSignal = false;
    
    // 時間条件の評価
    if(g_EnableTimeEntry) {
        timeSignal = IsTimeEntryAllowed(side);
    } else {
        // 時間条件チェックがOFFの場合は常にtrue
        timeSignal = true;
    }
    
    // インジケーター条件の評価
    if(g_EnableIndicatorsEntry) {
        indicatorSignal = EvaluateIndicatorsForEntry(side);
    } else {
        // インジケーター条件チェックがOFFの場合は常にtrue
        indicatorSignal = true;
    }
    
    // 確認方法に応じた判断
    if(EntryConfirmation == 0) {
        // どちらか1つでも条件を満たせばOK
        return (timeSignal || indicatorSignal);
    } else {
        // すべての条件を満たす必要あり
        return (timeSignal && indicatorSignal);
    }
}

//+------------------------------------------------------------------+
//| インジケーターによるエントリー条件の評価                          |
//+------------------------------------------------------------------+
bool EvaluateIndicatorsForEntry(int side)
{
    // 有効な戦略のシグナルを評価
    bool strategySignals = false;
    int enabledStrategies = 0;
    
    // MA クロス
    if(MA_Cross_Enabled) {
        enabledStrategies++;
        if(CheckMASignal(side)) strategySignals = true;
    }
    
    // RSI
    if(RSI_Enabled) {
        enabledStrategies++;
        if(CheckRSISignal(side)) strategySignals = true;
    }
    
    // ボリンジャーバンド
    if(BB_Enabled) {
        enabledStrategies++;
        if(CheckBollingerSignal(side)) strategySignals = true;
    }
    
    // RCI
    if(RCI_Enabled) {
        enabledStrategies++;
        if(CheckRCISignal(side)) strategySignals = true;
    }
    
    // MACD
    if(MACD_Enabled) {
        enabledStrategies++;
        if(CheckMACDSignal(side)) strategySignals = true;
    }
    
    // ストキャスティクス
    if(Stochastic_Enabled) {
        enabledStrategies++;
        if(CheckStochasticSignal(side)) strategySignals = true;
    }
    
    // 一目均衡表
    if(Ichimoku_Enabled) {
        enabledStrategies++;
        if(CheckIchimokuSignal(side)) strategySignals = true;
    }
    
    // CCI
    if(CCI_Enabled) {
        enabledStrategies++;
        if(CheckCCISignal(side)) strategySignals = true;
    }
    
    // パラボリックSAR
    if(Parabolic_SAR_Enabled) {
        enabledStrategies++;
        if(CheckParabolicSARSignal(side)) strategySignals = true;
    }
    
    // ADX/DMI
    if(ADX_Enabled) {
        enabledStrategies++;
        if(CheckADXSignal(side)) strategySignals = true;
    }
    
    // ATR
    if(ATR_Enabled) {
        enabledStrategies++;
        if(CheckATRSignal(side)) strategySignals = true;
    }
    
    // 最終判断
    // 有効な戦略が1つもない場合はtrueを返す（デフォルト動作を維持）
    // それ以外は、少なくとも1つの戦略が条件を満たしている必要がある
    return (enabledStrategies == 0 || strategySignals);
}

//+------------------------------------------------------------------+
//| 拡張された利確処理ロジック - 修正版                               |
//+------------------------------------------------------------------+
void ProcessTakeProfitLogic(int side)
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
    
    // 固定利確とインジケーター利確の条件評価
    bool fixedTPCondition = false;
    bool indicatorTPCondition = false;
    
    // 固定利確の評価
    if(g_EnableFixedTP) {
        // 現在価格を取得（BuyならBid、SellならAsk）
        double current_price = (side == 0) ? GetBidPrice() : GetAskPrice();
        
        if(side == 0) // Buy
            fixedTPCondition = (current_price > avgPrice + Fixed_TP_Points * Point);
        else // Sell
            fixedTPCondition = (current_price < avgPrice - Fixed_TP_Points * Point);
    }
    
    // インジケーター利確の評価
    if(g_EnableIndicatorsTP) {
        indicatorTPCondition = CheckTakeProfitCondition(side, avgPrice);
    }
    
    // 確認方法に応じた判断
    bool takeProfitNow = false;
    
    if(TPConfirmation == 0) {
        // どちらか1つでも条件を満たせば利確
        takeProfitNow = (g_EnableFixedTP && fixedTPCondition) || 
                         (g_EnableIndicatorsTP && indicatorTPCondition);
    } else {
        // すべての有効な条件を満たす必要あり
        takeProfitNow = (!g_EnableFixedTP || fixedTPCondition) && 
                         (!g_EnableIndicatorsTP || indicatorTPCondition);
    }
    
    // トレーリングストップの処理
    if(g_EnableTrailingStop) {
        bool trailingStopTriggered = CheckTrailingStopCondition(side, avgPrice);
        if(trailingStopTriggered) {
            takeProfitNow = true;
        }
    }
    
    // 利確条件が満たされた場合の処理
    if(takeProfitNow) {
        string direction = (side == 0) ? "Buy" : "Sell";
        Print(direction, "利確条件成立: 平均価格=", DoubleToString(avgPrice, 5));
        
        // リアルポジションの決済
        if(positionCount > 0) {
            position_close(side);
            Print("リアル", direction, "ポジションを決済しました");
        }
        
        // 反対側のポジションとゴーストをチェック
        int oppositePositionCount = position_count(oppositeType);
        int oppositeGhostCount = ghost_position_count(oppositeType);
        
        // ゴーストポジションは決済時にのみリセット（反対側に何もなければ両方リセット）
        if(ghostCount > 0 && g_EnableGhostEntry)
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
                g_BuyGhostClosed = false; // falseに変更
                g_GhostBuyCount = 0;
                
                // Sell側ゴーストポジションの状態をリセット
                for(int i = 0; i < g_GhostSellCount; i++) {
                    g_GhostSellPositions[i].isGhost = false;  // ゴーストフラグをオフに
                    // 他の値は保持（矢印を残すため）
                }
                g_SellGhostClosed = false; // falseに変更
                g_GhostSellCount = 0;
                
                // グローバル変数を更新
                SaveGhostPositionsToGlobal();
            }
            
            Print(direction, "ポジション利確: ゴーストポジションをリセットしました（矢印とテキストは保持）");
        }
    }
}





//+------------------------------------------------------------------+
//| 戦略ベースの利確条件チェック                                      |
//+------------------------------------------------------------------+
void CheckTakeProfitConditionsWithStrategy(int side)
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
    
    // 戦略に基づく利確判定
    bool tpCondition = ShouldTakeProfit(side, avgPrice);
    
    // 利確条件が満たされた場合
    if(tpCondition)
    {
        string direction = (side == 0) ? "Buy" : "Sell";
        Print(direction, "利確条件成立: 平均価格=", DoubleToString(avgPrice, 5));
        
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
                g_BuyGhostClosed = false; // falseに変更
                g_GhostBuyCount = 0;
                
                // Sell側ゴーストポジションの状態をリセット
                for(int i = 0; i < g_GhostSellCount; i++) {
                    g_GhostSellPositions[i].isGhost = false;  // ゴーストフラグをオフに
                    // 他の値は保持（矢印を残すため）
                }
                g_SellGhostClosed = false; // falseに変更
                g_GhostSellCount = 0;
                
                // グローバル変数を更新
                SaveGhostPositionsToGlobal();
            }
            
            Print(direction, "ポジション利確: ゴーストポジションをリセットしました（矢印とテキストは保持）");
        }
    }
}