
//+------------------------------------------------------------------+
//|                    Hosopi 3 - 偶数/奇数時間エントリー戦略          |
//|                           Copyright 2025                          |
//+------------------------------------------------------------------+
#include "Hosopi3_Defines.mqh"
#include "Hosopi3_Trading.mqh"
#include "Hosopi3_Utils.mqh"

//+------------------------------------------------------------------+
//| 偶数/奇数時間エントリー戦略のタイプ定義                            |
//+------------------------------------------------------------------+
enum EVEN_ODD_STRATEGY_TYPE
{
   EVEN_ODD_DISABLED = 0,       // 無効
   EVEN_HOUR_BUY_ODD_HOUR_SELL = 1,  // 偶数時間Buy・奇数時間Sell
   ODD_HOUR_BUY_EVEN_HOUR_SELL = 2   // 奇数時間Buy・偶数時間Sell
};

//+------------------------------------------------------------------+
//| 偶数/奇数時間エントリー戦略パラメータ                              |
//+------------------------------------------------------------------+
// ======== 偶数/奇数時間エントリー戦略設定 ========
sinput string Comment_EvenOdd = ""; //+--- 偶数/奇数時間エントリー設定 ---+
input EVEN_ODD_STRATEGY_TYPE EvenOdd_Entry_Strategy = EVEN_ODD_DISABLED; // 偶数/奇数時間エントリー
input bool EvenOdd_UseJPTime = true;  // 日本時間を使用
input bool EvenOdd_IncludeWeekends = false; // 週末も含める

//+------------------------------------------------------------------+
//| 現在の時間が偶数か奇数かをチェック                                |
//+------------------------------------------------------------------+
bool IsEvenHour()
{
   // 現在の時間を取得 (設定に応じて日本時間または取引サーバー時間)
   datetime current_time;
   
   if(EvenOdd_UseJPTime)
      current_time = calculate_time();  // 日本時間を取得
   else
      current_time = TimeCurrent();     // サーバー時間を取得
   
   // 週末判定（土日）
   if(!EvenOdd_IncludeWeekends)
   {
      int day_of_week = TimeDayOfWeek(current_time);
      if(day_of_week == 0 || day_of_week == 6)  // 0=日曜日, 6=土曜日
         return false;  // 週末は取引しない
   }
   
   // 現在の時間（時）を取得
   int current_hour = TimeHour(current_time);
   
   // 偶数時間かどうかを判定して返す
   return (current_hour % 2 == 0);
}

//+------------------------------------------------------------------+
//| 偶数/奇数時間エントリー戦略の判定                                  |
//+------------------------------------------------------------------+
bool CheckEvenOddStrategy(int side)
{
   // 戦略が無効の場合はすぐに false を返す
   if(EvenOdd_Entry_Strategy == EVEN_ODD_DISABLED)
      return false;
      
   // 現在時間が偶数時間かどうか
   bool is_even_hour = IsEvenHour();
   
   // BUYシグナル判定
   if(side == 0)  // Buy
   {
      if(EvenOdd_Entry_Strategy == EVEN_HOUR_BUY_ODD_HOUR_SELL)
         return is_even_hour;  // 偶数時間ならBuy
      else if(EvenOdd_Entry_Strategy == ODD_HOUR_BUY_EVEN_HOUR_SELL)
         return !is_even_hour;  // 奇数時間ならBuy
   }
   // SELLシグナル判定
   else  // Sell
   {
      if(EvenOdd_Entry_Strategy == EVEN_HOUR_BUY_ODD_HOUR_SELL)
         return !is_even_hour;  // 奇数時間ならSell
      else if(EvenOdd_Entry_Strategy == ODD_HOUR_BUY_EVEN_HOUR_SELL)
         return is_even_hour;  // 偶数時間ならSell
   }
   
   return false;
}

//+------------------------------------------------------------------+
//| 現在の偶数/奇数時間戦略の状態をテキストで取得                      |
//+------------------------------------------------------------------+
string GetEvenOddStrategyState()
{
   if(EvenOdd_Entry_Strategy == EVEN_ODD_DISABLED)
      return "無効";
      
   string timeBase = EvenOdd_UseJPTime ? "日本時間" : "サーバー時間";
   string weekendStatus = EvenOdd_IncludeWeekends ? "週末含む" : "平日のみ";
   
   string state = "";
   if(EvenOdd_Entry_Strategy == EVEN_HOUR_BUY_ODD_HOUR_SELL)
      state = "偶数時間Buy・奇数時間Sell";
   else if(EvenOdd_Entry_Strategy == ODD_HOUR_BUY_EVEN_HOUR_SELL)
      state = "奇数時間Buy・偶数時間Sell";
      
   return state + " (" + timeBase + ", " + weekendStatus + ")";
}
//+------------------------------------------------------------------+
//| 各テクニカル指標のエントリータイプ定義                            |
//+------------------------------------------------------------------+
enum TIME_ENTRY_TYPE
  {
   TIME_ENTRY_DISABLED = 0,      // 無効
   TIME_ENTRY_ENABLED = 1        // 有効
  };

enum MA_ENTRY_TYPE
  {
   MA_ENTRY_DISABLED = 0,        // 無効
   MA_ENTRY_ENABLED = 1          // 有効
  };

enum RSI_ENTRY_TYPE
  {
   RSI_ENTRY_DISABLED = 0,       // 無効
   RSI_ENTRY_ENABLED = 1         // 有効
  };

enum BOLLINGER_ENTRY_TYPE
  {
   BB_ENTRY_DISABLED = 0,        // 無効
   BB_ENTRY_ENABLED = 1          // 有効
  };

enum RCI_ENTRY_TYPE
  {
   RCI_ENTRY_DISABLED = 0,       // 無効
   RCI_ENTRY_ENABLED = 1         // 有効
  };

enum STOCH_ENTRY_TYPE
  {
   STOCH_ENTRY_DISABLED = 0,     // 無効
   STOCH_ENTRY_ENABLED = 1       // 有効
  };

enum CCI_ENTRY_TYPE
  {
   CCI_ENTRY_DISABLED = 0,       // 無効
   CCI_ENTRY_ENABLED = 1         // 有効
  };

enum ADX_ENTRY_TYPE
  {
   ADX_ENTRY_DISABLED = 0,       // 無効
   ADX_ENTRY_ENABLED = 1         // 有効
  };

enum STRATEGY_DIRECTION
  {
   TREND_FOLLOWING = 0,          // 順張り
   COUNTER_TREND = 1             // 逆張り
  };

//+------------------------------------------------------------------+
//| MA戦略定義                                                       |
//+------------------------------------------------------------------+
enum MA_STRATEGY_TYPE
  {
   MA_GOLDEN_CROSS = 1,          // ゴールデンクロス
   MA_DEAD_CROSS = 2,            // デッドクロス
   MA_PRICE_ABOVE_MA = 3,        // 価格がMA上
   MA_PRICE_BELOW_MA = 4,        // 価格がMA下
   MA_FAST_ABOVE_SLOW = 5,       // 短期MAが長期MA上
   MA_FAST_BELOW_SLOW = 6        // 短期MAが長期MA下
  };

//+------------------------------------------------------------------+
//| RSI戦略定義                                                      |
//+------------------------------------------------------------------+
enum RSI_STRATEGY_TYPE
  {
   RSI_OVERSOLD = 1,             // 売られすぎ
   RSI_OVERSOLD_EXIT = 2,        // 売られすぎから回復
   RSI_OVERBOUGHT = 3,           // 買われすぎ
   RSI_OVERBOUGHT_EXIT = 4       // 買われすぎから下落
  };

//+------------------------------------------------------------------+
//| ボリンジャーバンド戦略定義                                        |
//+------------------------------------------------------------------+
enum BB_STRATEGY_TYPE
  {
   BB_TOUCH_LOWER = 1,           // 下限バンドタッチ
   BB_BREAK_LOWER = 2,           // 下限バンド突破
   BB_TOUCH_UPPER = 3,           // 上限バンドタッチ
   BB_BREAK_UPPER = 4            // 上限バンド突破
  };

//+------------------------------------------------------------------+
//| RCI戦略定義                                                      |
//+------------------------------------------------------------------+
enum RCI_STRATEGY_TYPE
  {
   RCI_BELOW_MINUS_THRESHOLD = 1,    // -しきい値以下
   RCI_RISING_FROM_BOTTOM = 2,       // -しきい値から上昇
   RCI_ABOVE_PLUS_THRESHOLD = 3,     // +しきい値以上
   RCI_FALLING_FROM_PEAK = 4         // +しきい値から下落
  };

//+------------------------------------------------------------------+
//| ストキャスティクス戦略定義                                        |
//+------------------------------------------------------------------+
enum STOCH_STRATEGY_TYPE
  {
   STOCH_OVERSOLD = 1,                 // 売られすぎ
   STOCH_K_CROSS_D_OVERSOLD = 2,       // %Kが%Dを上抜け（売られすぎ）
   STOCH_OVERSOLD_EXIT = 3,            // 売られすぎから脱出
   STOCH_OVERBOUGHT = 4,               // 買われすぎ
   STOCH_K_CROSS_D_OVERBOUGHT = 5,     // %Kが%Dを下抜け（買われすぎ）
   STOCH_OVERBOUGHT_EXIT = 6           // 買われすぎから脱出
  };

//+------------------------------------------------------------------+
//| CCI戦略定義                                                      |
//+------------------------------------------------------------------+
enum CCI_STRATEGY_TYPE
  {
   CCI_OVERSOLD = 1,             // 売られすぎ
   CCI_OVERSOLD_EXIT = 2,        // 売られすぎから回復
   CCI_OVERBOUGHT = 3,           // 買われすぎ
   CCI_OVERBOUGHT_EXIT = 4       // 買われすぎから下落
  };

//+------------------------------------------------------------------+
//| ADX戦略定義                                                      |
//+------------------------------------------------------------------+
enum ADX_STRATEGY_TYPE
  {
   ADX_PLUS_DI_CROSS_MINUS_DI = 1,     // +DIが-DIを上抜け
   ADX_STRONG_TREND_PLUS_DI = 2,       // 強いトレンドで+DI > -DI
   ADX_MINUS_DI_CROSS_PLUS_DI = 3,     // -DIが+DIを上抜け
   ADX_STRONG_TREND_MINUS_DI = 4       // 強いトレンドで-DI > +DI
  };
// インジケータータイプの定数
#define INDICATOR_MA 1        // 移動平均
#define INDICATOR_RSI 2       // RSI
#define INDICATOR_BOLLINGER 3 // ボリンジャーバンド
#define INDICATOR_STOCHASTIC 4 // ストキャスティクス
#define INDICATOR_CCI 5       // CCI
#define INDICATOR_ADX 6       // ADX

// 条件判定タイプ
enum CONDITION_TYPE
  {
   OR_CONDITION = 0,          // いずれかの条件が成立（OR条件）
   AND_CONDITION = 1          // すべての条件が成立（AND条件）
  };

// 時間エントリー戦略
sinput string Comment_Time_Entry = ""; //+--- 時間エントリー設定 ---+
input TIME_ENTRY_TYPE Time_Entry_Strategy = TIME_ENTRY_DISABLED; // 時間条件
input bool EvenHoursBuy = true;     // 偶数時間に買い
input bool OddHoursSell = true;     // 奇数時間に売り

// MA戦略パラメータ
sinput string Comment_MA = ""; //+--- 移動平均線戦略設定 ---+
input MA_ENTRY_TYPE MA_Entry_Strategy = MA_ENTRY_DISABLED;  // MAクロス戦略
input MA_STRATEGY_TYPE MA_Buy_Signal = MA_GOLDEN_CROSS;    // MA買いシグナルタイプ
input MA_STRATEGY_TYPE MA_Sell_Signal = MA_DEAD_CROSS;     // MA売りシグナルタイプ
input ENUM_TIMEFRAMES MA_Timeframe = PERIOD_CURRENT;       // MA時間足
input int MA_Buy_Fast_Period = 5;                          // MA買い短期期間
input int MA_Buy_Slow_Period = 20;                         // MA買い長期期間
input int MA_Sell_Fast_Period = 5;                         // MA売り短期期間
input int MA_Sell_Slow_Period = 20;                        // MA売り長期期間
input ENUM_MA_METHOD MA_Method = MODE_SMA;                 // MA計算方法
input ENUM_APPLIED_PRICE MA_Price = PRICE_CLOSE;           // MA価格タイプ
input int MA_Cross_Shift = 1;                              // MAシグナルシフト
input STRATEGY_DIRECTION MA_Buy_Direction = TREND_FOLLOWING; // MA買い取引方向
input STRATEGY_DIRECTION MA_Sell_Direction = TREND_FOLLOWING; // MA売り取引方向

// RSI戦略パラメータ
sinput string Comment_RSI = ""; //+--- RSI戦略設定 ---+
input RSI_ENTRY_TYPE RSI_Entry_Strategy = RSI_ENTRY_DISABLED; // RSI戦略
input RSI_STRATEGY_TYPE RSI_Buy_Signal = RSI_OVERSOLD;      // RSI買いシグナルタイプ
input RSI_STRATEGY_TYPE RSI_Sell_Signal = RSI_OVERBOUGHT;   // RSI売りシグナルタイプ
input ENUM_TIMEFRAMES RSI_Timeframe = PERIOD_CURRENT;       // RSI時間足
input int RSI_Period = 14;                                  // RSI期間
input ENUM_APPLIED_PRICE RSI_Price = PRICE_CLOSE;           // RSI価格タイプ
input int RSI_Signal_Shift = 1;                             // RSIシグナルシフト
input int RSI_Oversold = 30;                                // RSI売られすぎレベル
input int RSI_Overbought = 70;                              // RSI買われすぎレベル
input STRATEGY_DIRECTION RSI_Buy_Direction = TREND_FOLLOWING; // RSI買い取引方向
input STRATEGY_DIRECTION RSI_Sell_Direction = TREND_FOLLOWING; // RSI売り取引方向

// ボリンジャーバンド戦略パラメータ
sinput string Comment_BB = ""; //+--- ボリンジャーバンド戦略設定 ---+
input BOLLINGER_ENTRY_TYPE BB_Entry_Strategy = BB_ENTRY_DISABLED; // ボリンジャー戦略
input BB_STRATEGY_TYPE BB_Buy_Signal = BB_TOUCH_LOWER;       // BB買いシグナルタイプ
input BB_STRATEGY_TYPE BB_Sell_Signal = BB_TOUCH_UPPER;      // BB売りシグナルタイプ
input ENUM_TIMEFRAMES BB_Timeframe = PERIOD_CURRENT;         // BB時間足
input int BB_Period = 20;                                    // BB期間
input double BB_Deviation = 2.0;                             // BB標準偏差
input ENUM_APPLIED_PRICE BB_Price = PRICE_CLOSE;             // BB価格タイプ
input int BB_Signal_Shift = 1;                               // BBシグナルシフト
input STRATEGY_DIRECTION BB_Buy_Direction = TREND_FOLLOWING;  // BB買い取引方向
input STRATEGY_DIRECTION BB_Sell_Direction = TREND_FOLLOWING; // BB売り取引方向

// RCI戦略パラメータ
sinput string Comment_RCI = ""; //+--- RCI戦略設定 ---+
input RCI_ENTRY_TYPE RCI_Entry_Strategy = RCI_ENTRY_DISABLED; // RCI戦略
input RCI_STRATEGY_TYPE RCI_Buy_Signal = RCI_BELOW_MINUS_THRESHOLD; // RCI買いシグナルタイプ
input RCI_STRATEGY_TYPE RCI_Sell_Signal = RCI_ABOVE_PLUS_THRESHOLD; // RCI売りシグナルタイプ
input int RCI_Period = 9;                                    // RCI短期期間
input int RCI_MidTerm_Period = 26;                           // RCI中期期間
input int RCI_LongTerm_Period = 52;                          // RCI長期期間
input int RCI_Signal_Shift = 1;                              // RCIシグナルシフト
input ENUM_TIMEFRAMES RCI_Timeframe = PERIOD_CURRENT;        // RCI時間足
input int RCI_Threshold = 80;                                // RCIしきい値
input STRATEGY_DIRECTION RCI_Buy_Direction = TREND_FOLLOWING; // RCI買い取引方向
input STRATEGY_DIRECTION RCI_Sell_Direction = TREND_FOLLOWING; // RCI売り取引方向

// ストキャスティクス戦略パラメータ
sinput string Comment_Stoch = ""; //+--- ストキャスティクス戦略設定 ---+
input STOCH_ENTRY_TYPE Stoch_Entry_Strategy = STOCH_ENTRY_DISABLED; // ストキャスティクス戦略
input STOCH_STRATEGY_TYPE Stoch_Buy_Signal = STOCH_OVERSOLD;  // ストキャスティクス買いシグナルタイプ
input STOCH_STRATEGY_TYPE Stoch_Sell_Signal = STOCH_OVERBOUGHT; // ストキャスティクス売りシグナルタイプ
input ENUM_TIMEFRAMES Stoch_Timeframe = PERIOD_CURRENT;      // ストキャスティクス時間足
input int Stoch_K_Period = 5;                                // %K期間
input int Stoch_D_Period = 3;                                // %D期間
input int Stoch_Slowing = 3;                                 // スローイング
input ENUM_MA_METHOD Stoch_Method = MODE_SMA;                // 平滑化方法
input int Stoch_Price_Field = 0;                             // 価格フィールド
input int Stoch_Signal_Shift = 1;                            // シグナルシフト
input int Stoch_Oversold = 20;                               // 売られすぎレベル
input int Stoch_Overbought = 80;                             // 買われすぎレベル
input STRATEGY_DIRECTION Stoch_Buy_Direction = TREND_FOLLOWING; // 買い取引方向
input STRATEGY_DIRECTION Stoch_Sell_Direction = TREND_FOLLOWING; // 売り取引方向

// CCI戦略パラメータ
sinput string Comment_CCI = ""; //+--- CCI戦略設定 ---+
input CCI_ENTRY_TYPE CCI_Entry_Strategy = CCI_ENTRY_DISABLED; // CCI戦略
input CCI_STRATEGY_TYPE CCI_Buy_Signal = CCI_OVERSOLD;       // CCI買いシグナルタイプ
input CCI_STRATEGY_TYPE CCI_Sell_Signal = CCI_OVERBOUGHT;    // CCI売りシグナルタイプ
input ENUM_TIMEFRAMES CCI_Timeframe = PERIOD_CURRENT;        // CCI時間足
input int CCI_Period = 14;                                   // CCI期間
input ENUM_APPLIED_PRICE CCI_Price = PRICE_CLOSE;            // CCI価格タイプ
input int CCI_Signal_Shift = 1;                              // CCIシグナルシフト
input int CCI_Oversold = -100;                               // CCI売られすぎレベル
input int CCI_Overbought = 100;                              // CCI買われすぎレベル
input STRATEGY_DIRECTION CCI_Buy_Direction = TREND_FOLLOWING; // CCI買い取引方向
input STRATEGY_DIRECTION CCI_Sell_Direction = TREND_FOLLOWING; // CCI売り取引方向

// ADX戦略パラメータ
sinput string Comment_ADX = ""; //+--- ADX戦略設定 ---+
input ADX_ENTRY_TYPE ADX_Entry_Strategy = ADX_ENTRY_DISABLED; // ADX戦略
input ADX_STRATEGY_TYPE ADX_Buy_Signal = ADX_PLUS_DI_CROSS_MINUS_DI; // ADX買いシグナルタイプ
input ADX_STRATEGY_TYPE ADX_Sell_Signal = ADX_MINUS_DI_CROSS_PLUS_DI; // ADX売りシグナルタイプ
input ENUM_TIMEFRAMES ADX_Timeframe = PERIOD_CURRENT;        // ADX時間足
input int ADX_Period = 14;                                   // ADX期間
input int ADX_Signal_Shift = 1;                              // ADXシグナルシフト
input int ADX_Threshold = 25;                                // ADXしきい値
input STRATEGY_DIRECTION ADX_Buy_Direction = TREND_FOLLOWING; // ADX買い取引方向
input STRATEGY_DIRECTION ADX_Sell_Direction = TREND_FOLLOWING; // ADX売り取引方向

// インジケーター条件判定タイプ
sinput string Comment_Condition = ""; //+--- 条件判定設定 ---+
input CONDITION_TYPE Indicator_Condition_Type = OR_CONDITION; // インジケーター条件判定（OR/AND）
//+------------------------------------------------------------------+
//| EvaluateIndicatorsForEntry関数 - インジケーター評価（セクション追加）|
//+------------------------------------------------------------------+
bool EvaluateIndicatorsForEntry(int side)
{
   Print("【インジケーターシグナル評価】 開始 - side=", side);

// 有効な戦略のシグナルを評価
   bool strategySignals = false;
   int enabledStrategies = 0;
   int validSignals = 0;

// 【セクション: MAクロス】
   if(MA_Entry_Strategy == MA_ENTRY_ENABLED)
   {
      enabledStrategies++;
      if(CheckMASignal(side))
      {
         validSignals++;
         Print("【MAクロス】: シグナル成立");
      }
      else
      {
         Print("【MAクロス】: シグナル不成立");
      }
   }

// 【セクション: RSI】
   if(RSI_Entry_Strategy == RSI_ENTRY_ENABLED)
   {
      enabledStrategies++;
      if(CheckRSISignal(side))
      {
         validSignals++;
         Print("【RSI】: シグナル成立");
      }
      else
      {
         Print("【RSI】: シグナル不成立");
      }
   }

// 【セクション: ボリンジャーバンド】
   if(BB_Entry_Strategy == BB_ENTRY_ENABLED)
   {
      enabledStrategies++;
      if(CheckBollingerSignal(side))
      {
         validSignals++;
         Print("【ボリンジャーバンド】: シグナル成立");
      }
      else
      {
         Print("【ボリンジャーバンド】: シグナル不成立");
      }
   }

// 【セクション: RCI】
   if(RCI_Entry_Strategy == RCI_ENTRY_ENABLED)
   {
      enabledStrategies++;
      if(CheckRCISignal(side))
      {
         validSignals++;
         Print("【RCI】: シグナル成立");
      }
      else
      {
         Print("【RCI】: シグナル不成立");
      }
   }

// 【セクション: ストキャスティクス】
   if(Stoch_Entry_Strategy == STOCH_ENTRY_ENABLED)
   {
      enabledStrategies++;
      if(CheckStochasticSignal(side))
      {
         validSignals++;
         Print("【ストキャスティクス】: シグナル成立");
      }
      else
      {
         Print("【ストキャスティクス】: シグナル不成立");
      }
   }

// 【セクション: CCI】
   if(CCI_Entry_Strategy == CCI_ENTRY_ENABLED)
   {
      enabledStrategies++;
      if(CheckCCISignal(side))
      {
         validSignals++;
         Print("【CCI】: シグナル成立");
      }
      else
      {
         Print("【CCI】: シグナル不成立");
      }
   }

// 【セクション: ADX/DMI】
   if(ADX_Entry_Strategy == ADX_ENTRY_ENABLED)
   {
      enabledStrategies++;
      if(CheckADXSignal(side))
      {
         validSignals++;
         Print("【ADX/DMI】: シグナル成立");
      }
      else
      {
         Print("【ADX/DMI】: シグナル不成立");
      }
   }

// 【セクション: 偶数/奇数時間】
   if(EvenOdd_Entry_Strategy != EVEN_ODD_DISABLED)
   {
      enabledStrategies++;
      if(CheckEvenOddStrategy(side))
      {
         validSignals++;
         Print("【偶数/奇数時間】: シグナル成立");
      }
      else
      {
         Print("【偶数/奇数時間】: シグナル不成立");
      }
   }

// 【セクション: 最終判断】
   Print("【最終判断】 有効なインジケーター数: ", enabledStrategies, ", シグナル成立数: ", validSignals);

// 有効な戦略が1つもない場合はfalseを返す
   if(enabledStrategies == 0)
   {
      Print("【最終判断】: 有効なインジケーターが0のため false を返します");
      return false;
   }

// 条件タイプに基づいて評価
   if(Indicator_Condition_Type == AND_CONDITION)
   {
      // AND条件: すべての有効なインジケーターがシグナルを出した場合のみtrue
      strategySignals = (validSignals == enabledStrategies);
      Print("【最終判断】 AND条件で評価: ", strategySignals ? "すべてのシグナルが成立" : "一部のシグナルが不成立");
   }
   else
   {
      // OR条件: 少なくとも1つのインジケーターがシグナルを出した場合にtrue
      strategySignals = (validSignals > 0);
      Print("【最終判断】 OR条件で評価: ", strategySignals ? "1つ以上のシグナルが成立" : "シグナル不成立");
   }

   Print("【最終判断】 結果: ", strategySignals ? "成立" : "不成立");
   return strategySignals;
}



//+------------------------------------------------------------------+
//| EvaluateStrategyForEntry関数 - 戦略評価修正版                     |
//+------------------------------------------------------------------+
bool EvaluateStrategyForEntry(int side)
{
// side: 0 = Buy, 1 = Sell
   bool entrySignal = false;

// 【セクション: 時間条件チェック】
   bool timeEntryAllowed = IsTimeEntryAllowed(side);

// 【セクション: インジケーター評価】
   bool strategySignals = false;
   int enabledStrategies = 0;
   int validSignals = 0;

// 【セクション: 有効な戦略名収集】
   string activeStrategies = "";

// 各インジケーターのシグナルチェック - タイトル付き
// 【セクション: MAクロス】
   if(MA_Entry_Strategy == MA_ENTRY_ENABLED)
   {
      enabledStrategies++;
      if(CheckMASignal(side))
      {
         validSignals++;
         if(activeStrategies != "")
            activeStrategies += ", ";
         activeStrategies += "MAクロス";
      }
   }

// 【セクション: RSI】
   if(RSI_Entry_Strategy == RSI_ENTRY_ENABLED)
   {
      enabledStrategies++;
      if(CheckRSISignal(side))
      {
         validSignals++;
         if(activeStrategies != "")
            activeStrategies += ", ";
         activeStrategies += "RSI";
      }
   }

// 【セクション: ボリンジャーバンド】
   if(BB_Entry_Strategy == BB_ENTRY_ENABLED)
   {
      enabledStrategies++;
      if(CheckBollingerSignal(side))
      {
         validSignals++;
         if(activeStrategies != "")
            activeStrategies += ", ";
         activeStrategies += "ボリンジャーバンド";
      }
   }

// 【セクション: RCI】
   if(RCI_Entry_Strategy == RCI_ENTRY_ENABLED)
   {
      enabledStrategies++;
      if(CheckRCISignal(side))
      {
         validSignals++;
         if(activeStrategies != "")
            activeStrategies += ", ";
         activeStrategies += "RCI";
      }
   }

// 【セクション: ストキャスティクス】
   if(Stoch_Entry_Strategy == STOCH_ENTRY_ENABLED)
   {
      enabledStrategies++;
      if(CheckStochasticSignal(side))
      {
         validSignals++;
         if(activeStrategies != "")
            activeStrategies += ", ";
         activeStrategies += "ストキャスティクス";
      }
   }

// 【セクション: CCI】
   if(CCI_Entry_Strategy == CCI_ENTRY_ENABLED)
   {
      enabledStrategies++;
      if(CheckCCISignal(side))
      {
         validSignals++;
         if(activeStrategies != "")
            activeStrategies += ", ";
         activeStrategies += "CCI";
      }
   }

// 【セクション: ADX/DMI】
   if(ADX_Entry_Strategy == ADX_ENTRY_ENABLED)
   {
      enabledStrategies++;
      if(CheckADXSignal(side))
      {
         validSignals++;
         if(activeStrategies != "")
            activeStrategies += ", ";
         activeStrategies += "ADX/DMI";
      }
   }

// 【セクション: 偶数/奇数時間】
   if(EvenOdd_Entry_Strategy != EVEN_ODD_DISABLED)
   {
      enabledStrategies++;
      if(CheckEvenOddStrategy(side))
      {
         validSignals++;
         if(activeStrategies != "")
            activeStrategies += ", ";
         activeStrategies += "偶数/奇数時間";
      }
   }

// 【セクション: インジケーター条件評価】
   bool indicatorSignalsValid = false;

   if(enabledStrategies > 0)
   {
      if(Indicator_Condition_Type == AND_CONDITION)
      {
         // AND条件: すべての有効なインジケーターがシグナルを出した場合のみtrue
         indicatorSignalsValid = (validSignals == enabledStrategies);
      }
      else
      {
         // OR条件: 少なくとも1つのインジケーターがシグナルを出した場合にtrue
         indicatorSignalsValid = (validSignals > 0);
      }
   }

// 【セクション: 最終判断】
// 時間条件が許可され、かつインジケーター条件もOKかチェック
   bool needTime = (Time_Entry_Strategy == TIME_ENTRY_ENABLED);
   bool needIndicators = (enabledStrategies > 0);

// 時間条件のみが設定されている場合
   if(needTime && !needIndicators)
   {
      entrySignal = timeEntryAllowed;
   }
// インジケーター条件のみが設定されている場合
   else if(!needTime && needIndicators)
   {
      entrySignal = indicatorSignalsValid;
   }
// 両方の条件が設定されている場合
   else if(needTime && needIndicators)
   {
      // 両方の条件を満たすか
      entrySignal = timeEntryAllowed && indicatorSignalsValid;
   }
// 両方設定されていない場合はエントリーしない
   else
   {
      entrySignal = false;
   }

// 【セクション: エントリー理由記録】
// エントリーシグナルがある場合、理由を記録
   if(entrySignal)
   {
      string typeStr = (side == 0) ? "Buy" : "Sell";
      string reason;
      string conditionType = (Indicator_Condition_Type == AND_CONDITION) ? "AND条件" : "OR条件";

      if(needTime && needIndicators)
      {
         reason = "時間条件 + " + conditionType + "(" + (activeStrategies != "" ? activeStrategies : "なし") + ")";
      }
      else if(needTime)
      {
         reason = "時間条件のみ";
      }
      else if(needIndicators)
      {
         reason = conditionType + "(" + activeStrategies + ")";
      }

      // 詳細情報を取得
      string details = GetStrategyDetails(side);

      // エントリー理由をログに記録
      LogEntryReason(side == 0 ? OP_BUY : OP_SELL, "戦略シグナル", reason);

      // 詳細情報もログに出力
      Print(details);
   }

   return entrySignal;
}


  //+------------------------------------------------------------------+
//| 指定された時間足でインジケーター値を取得する関数                   |
//+------------------------------------------------------------------+
double GetIndicatorValueOnTimeframe(string symbol, ENUM_TIMEFRAMES timeframe, int indicator_type,
                                    int period, double deviation, ENUM_APPLIED_PRICE price_type,
                                    int shift, int mode = 0)
  {
// 指定された時間足でインジケーター値を取得
   double value = 0;

   switch(indicator_type)
     {
      // 移動平均
      case INDICATOR_MA:
         value = iMA(symbol, timeframe, period, 0, MODE_SMA, price_type, shift);
         break;

      // RSI
      case INDICATOR_RSI:
         value = iRSI(symbol, timeframe, period, price_type, shift);
         break;

      // ボリンジャーバンド
      case INDICATOR_BOLLINGER:
         value = iBands(symbol, timeframe, period, deviation, 0, price_type, mode, shift);
         break;

      // ストキャスティクス
      case INDICATOR_STOCHASTIC:
         value = iStochastic(symbol, timeframe, period, 3, 3, MODE_SMA, 0, mode, shift);
         break;

      // CCI
      case INDICATOR_CCI:
         value = iCCI(symbol, timeframe, period, price_type, shift);
         break;

      // ADX
      case INDICATOR_ADX:
         value = iADX(symbol, timeframe, period, price_type, mode, shift);
         break;
     }

   return value;
  }

//+------------------------------------------------------------------+
//| 時間戦略のシグナル判断                                           |
//+------------------------------------------------------------------+
bool IsTimeEntryAllowed(int side)
  {
   if(Time_Entry_Strategy == TIME_ENTRY_DISABLED)
      return false;

// 現在の時間を取得
   datetime current_time = TimeCurrent();
   int current_hour = TimeHour(current_time);

// 偶数時間かどうか判定
   bool is_even_hour = (current_hour % 2 == 0);

   if(side == 0) // Buy
     {
      // 偶数時間にBuyを許可する設定の場合
      if(EvenHoursBuy && is_even_hour)
         return true;

      // 奇数時間にBuyを許可する設定の場合
      if(!EvenHoursBuy && !is_even_hour)
         return true;
     }
   else // Sell
     {
      // 奇数時間にSellを許可する設定の場合
      if(OddHoursSell && !is_even_hour)
         return true;

      // 偶数時間にSellを許可する設定の場合
      if(!OddHoursSell && is_even_hour)
         return true;
     }

   return false;
  }

//+------------------------------------------------------------------+
//| MAクロス戦略のシグナル判断                                        |
//+------------------------------------------------------------------+
bool CheckMASignal(int side)
  {
   if(MA_Entry_Strategy == MA_ENTRY_DISABLED)
      return false;

// MA値の取得 - 時間足を考慮
   double fastMA_current, slowMA_current, fastMA_prev, slowMA_prev;

   if(side == 0) // Buy
     {
      if(MA_Buy_Signal == 0)
         return false;

      fastMA_current = iMA(Symbol(), MA_Timeframe, MA_Buy_Fast_Period, 0, MA_Method, MA_Price, MA_Cross_Shift);
      slowMA_current = iMA(Symbol(), MA_Timeframe, MA_Buy_Slow_Period, 0, MA_Method, MA_Price, MA_Cross_Shift);
      fastMA_prev = iMA(Symbol(), MA_Timeframe, MA_Buy_Fast_Period, 0, MA_Method, MA_Price, MA_Cross_Shift + 1);
      slowMA_prev = iMA(Symbol(), MA_Timeframe, MA_Buy_Slow_Period, 0, MA_Method, MA_Price, MA_Cross_Shift + 1);

      // 価格データの取得
      double price_current = iClose(Symbol(), MA_Timeframe, MA_Cross_Shift);
      double price_prev = iClose(Symbol(), MA_Timeframe, MA_Cross_Shift + 1);

      // 順張り/逆張りの方向に基づいて判断
      bool signal = false;

      switch(MA_Buy_Signal)
        {
         case MA_GOLDEN_CROSS: // ゴールデンクロス
            signal = (fastMA_prev < slowMA_prev && fastMA_current > slowMA_current);
            break;

         case MA_PRICE_ABOVE_MA: // 価格がMA上
            signal = (price_current > fastMA_current);
            break;

         case MA_FAST_ABOVE_SLOW: // 短期MAが長期MA上
            signal = (fastMA_current > slowMA_current);
            break;

         case MA_DEAD_CROSS: // デッドクロス
            signal = (fastMA_prev > slowMA_prev && fastMA_current < slowMA_current);
            break;

         case MA_PRICE_BELOW_MA: // 価格がMA下
            signal = (price_current < fastMA_current);
            break;

         case MA_FAST_BELOW_SLOW: // 短期MAが長期MA下
            signal = (fastMA_current < slowMA_current);
            break;
        }

      // 取引方向に基づいて判断
      return (MA_Buy_Direction == TREND_FOLLOWING) ? signal : !signal;
     }
   else // Sell
     {
      if(MA_Sell_Signal == 0)
         return false;

      fastMA_current = iMA(Symbol(), MA_Timeframe, MA_Sell_Fast_Period, 0, MA_Method, MA_Price, MA_Cross_Shift);
      slowMA_current = iMA(Symbol(), MA_Timeframe, MA_Sell_Slow_Period, 0, MA_Method, MA_Price, MA_Cross_Shift);
      fastMA_prev = iMA(Symbol(), MA_Timeframe, MA_Sell_Fast_Period, 0, MA_Method, MA_Price, MA_Cross_Shift + 1);
      slowMA_prev = iMA(Symbol(), MA_Timeframe, MA_Sell_Slow_Period, 0, MA_Method, MA_Price, MA_Cross_Shift + 1);

      // 価格データの取得
      double price_current = iClose(Symbol(), MA_Timeframe, MA_Cross_Shift);
      double price_prev = iClose(Symbol(), MA_Timeframe, MA_Cross_Shift + 1);

      // 順張り/逆張りの方向に基づいて判断
      bool signal = false;

      switch(MA_Sell_Signal)
        {
         case MA_DEAD_CROSS: // デッドクロス
            signal = (fastMA_prev > slowMA_prev && fastMA_current < slowMA_current);
            break;

         case MA_PRICE_BELOW_MA: // 価格がMA下
            signal = (price_current < fastMA_current);
            break;

         case MA_FAST_BELOW_SLOW: // 短期MAが長期MA下
            signal = (fastMA_current < slowMA_current);
            break;

         case MA_GOLDEN_CROSS: // ゴールデンクロス
            signal = (fastMA_prev < slowMA_prev && fastMA_current > slowMA_current);
            break;

         case MA_PRICE_ABOVE_MA: // 価格がMA上
            signal = (price_current > fastMA_current);
            break;

         case MA_FAST_ABOVE_SLOW: // 短期MAが長期MA上
            signal = (fastMA_current > slowMA_current);
            break;
        }

      // 取引方向に基づいて判断
      return (MA_Sell_Direction == TREND_FOLLOWING) ? signal : !signal;
     }

   return false;
  }

//+------------------------------------------------------------------+
//| RSI戦略のシグナル判断                                           |
//+------------------------------------------------------------------+
bool CheckRSISignal(int side)
  {
   if(RSI_Entry_Strategy == RSI_ENTRY_DISABLED)
      return false;

// RSI値の取得 - 時間足を考慮
   double rsi_current = iRSI(Symbol(), RSI_Timeframe, RSI_Period, RSI_Price, RSI_Signal_Shift);
   double rsi_prev = iRSI(Symbol(), RSI_Timeframe, RSI_Period, RSI_Price, RSI_Signal_Shift + 1);

// BUYシグナル
   if(side == 0)
     {
      if(RSI_Buy_Signal == 0)
         return false;

      bool signal = false;

      switch(RSI_Buy_Signal)
        {
         case RSI_OVERSOLD: // 売られすぎ
            signal = (rsi_current < RSI_Oversold);
            break;

         case RSI_OVERSOLD_EXIT: // 売られすぎから回復
            signal = (rsi_prev < RSI_Oversold && rsi_current >= RSI_Oversold);
            break;

         case RSI_OVERBOUGHT: // 買われすぎ
            signal = (rsi_current > RSI_Overbought);
            break;

         case RSI_OVERBOUGHT_EXIT: // 買われすぎから下落
            signal = (rsi_prev > RSI_Overbought && rsi_current <= RSI_Overbought);
            break;
        }

      // 取引方向に基づいて判断
      return (RSI_Buy_Direction == TREND_FOLLOWING) ? signal : !signal;
     }
// SELLシグナル
   else
     {
      if(RSI_Sell_Signal == 0)
         return false;

      bool signal = false;

      switch(RSI_Sell_Signal)
        {
         case RSI_OVERBOUGHT: // 買われすぎ
            signal = (rsi_current > RSI_Overbought);
            break;

         case RSI_OVERBOUGHT_EXIT: // 買われすぎから下落
            signal = (rsi_prev > RSI_Overbought && rsi_current <= RSI_Overbought);
            break;

         case RSI_OVERSOLD: // 売られすぎ
            signal = (rsi_current < RSI_Oversold);
            break;

         case RSI_OVERSOLD_EXIT: // 売られすぎから回復
            signal = (rsi_prev < RSI_Oversold && rsi_current >= RSI_Oversold);
            break;
        }

      // 取引方向に基づいて判断
      return (RSI_Sell_Direction == TREND_FOLLOWING) ? signal : !signal;
     }

   return false;
  }

//+------------------------------------------------------------------+
//| ボリンジャーバンド戦略のシグナル判断                              |
//+------------------------------------------------------------------+
bool CheckBollingerSignal(int side)
  {
   if(BB_Entry_Strategy == BB_ENTRY_DISABLED)
      return false;

// 時間足を考慮したボリンジャーバンド値の取得
   double middle = iBands(Symbol(), BB_Timeframe, BB_Period, BB_Deviation, 0, BB_Price, MODE_MAIN, BB_Signal_Shift);
   double upper = iBands(Symbol(), BB_Timeframe, BB_Period, BB_Deviation, 0, BB_Price, MODE_UPPER, BB_Signal_Shift);
   double lower = iBands(Symbol(), BB_Timeframe, BB_Period, BB_Deviation, 0, BB_Price, MODE_LOWER, BB_Signal_Shift);

   double close_current = iClose(Symbol(), BB_Timeframe, BB_Signal_Shift);
   double close_prev = iClose(Symbol(), BB_Timeframe, BB_Signal_Shift + 1);

// BUYシグナル
   if(side == 0)
     {
      if(BB_Buy_Signal == 0)
         return false;

      bool signal = false;

      switch(BB_Buy_Signal)
        {
         case BB_TOUCH_LOWER: // 下限バンドタッチ後反発
            signal = (close_prev <= lower && close_current > close_prev);
            break;

         case BB_BREAK_LOWER: // 下限バンド突破
            signal = (close_prev > lower && close_current < lower);
            break;

         case BB_TOUCH_UPPER: // 上限バンドタッチ後反落
            signal = (close_prev >= upper && close_current < close_prev);
            break;

         case BB_BREAK_UPPER: // 上限バンド突破
            signal = (close_prev < upper && close_current > upper);
            break;
        }

      // 取引方向に基づいて判断
      return (BB_Buy_Direction == TREND_FOLLOWING) ? signal : !signal;
     }
// SELLシグナル
   else
     {
      if(BB_Sell_Signal == 0)
         return false;

      bool signal = false;

      switch(BB_Sell_Signal)
        {
         case BB_TOUCH_UPPER: // 上限バンドタッチ後反落
            signal = (close_prev >= upper && close_current < close_prev);
            break;

         case BB_BREAK_UPPER: // 上限バンド突破
            signal = (close_prev < upper && close_current > upper);
            break;

         case BB_TOUCH_LOWER: // 下限バンドタッチ後反発
            signal = (close_prev <= lower && close_current > close_prev);
            break;

         case BB_BREAK_LOWER: // 下限バンド突破
            signal = (close_prev > lower && close_current < lower);
            break;
        }

      // 取引方向に基づいて判断
      return (BB_Sell_Direction == TREND_FOLLOWING) ? signal : !signal;
     }

   return false;
  }

//+------------------------------------------------------------------+
//| RCI（ランク相関係数）の計算                                      |
//+------------------------------------------------------------------+
double CalculateRCI(int period, int shift, ENUM_TIMEFRAMES timeframe)
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
      prices[i] = iClose(Symbol(), timeframe, i + shift);
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
   if(RCI_Entry_Strategy == RCI_ENTRY_DISABLED)
      return false;

// RCIの計算 - 時間足を考慮
   double rci_current = CalculateRCI(RCI_Period, RCI_Signal_Shift, RCI_Timeframe);
   double rci_prev = CalculateRCI(RCI_Period, RCI_Signal_Shift + 1, RCI_Timeframe);

// 中期RCI
   double rci_mid_current = CalculateRCI(RCI_MidTerm_Period, RCI_Signal_Shift, RCI_Timeframe);

// 長期RCI
   double rci_long_current = CalculateRCI(RCI_LongTerm_Period, RCI_Signal_Shift, RCI_Timeframe);

// BUYシグナル
   if(side == 0)
     {
      if(RCI_Buy_Signal == 0)
         return false;

      bool signal = false;

      switch(RCI_Buy_Signal)
        {
         case RCI_BELOW_MINUS_THRESHOLD: // -しきい値以下
            signal = (rci_current < -RCI_Threshold);
            break;

         case RCI_RISING_FROM_BOTTOM: // -しきい値から上昇
            signal = (rci_prev < -RCI_Threshold && rci_current > rci_prev &&
                      rci_mid_current < -50 && rci_long_current < -50);
            break;

         case RCI_ABOVE_PLUS_THRESHOLD: // +しきい値以上
            signal = (rci_current > RCI_Threshold);
            break;

         case RCI_FALLING_FROM_PEAK: // +しきい値から下落
            signal = (rci_prev > RCI_Threshold && rci_current < rci_prev &&
                      rci_mid_current > 50 && rci_long_current > 50);
            break;
        }

      // 取引方向に基づいて判断
      return (RCI_Buy_Direction == TREND_FOLLOWING) ? signal : !signal;
     }
// SELLシグナル
   else
     {
      if(RCI_Sell_Signal == 0)
         return false;

      bool signal = false;

      switch(RCI_Sell_Signal)
        {
         case RCI_ABOVE_PLUS_THRESHOLD: // +しきい値以上
            signal = (rci_current > RCI_Threshold);
            break;

         case RCI_FALLING_FROM_PEAK: // +しきい値から下落
            signal = (rci_prev > RCI_Threshold && rci_current < rci_prev &&
                      rci_mid_current > 50 && rci_long_current > 50);
            break;

         case RCI_BELOW_MINUS_THRESHOLD: // -しきい値以下
            signal = (rci_current < -RCI_Threshold);
            break;

         case RCI_RISING_FROM_BOTTOM: // -しきい値から上昇
            signal = (rci_prev < -RCI_Threshold && rci_current > rci_prev &&
                      rci_mid_current < -50 && rci_long_current < -50);
            break;
        }

      // 取引方向に基づいて判断
      return (RCI_Sell_Direction == TREND_FOLLOWING) ? signal : !signal;
     }

   return false;
  }

//+------------------------------------------------------------------+
//| ストキャスティクス戦略のシグナル判断                              |
//+------------------------------------------------------------------+
bool CheckStochasticSignal(int side)
  {
   if(Stoch_Entry_Strategy == STOCH_ENTRY_DISABLED)
      return false;

// 時間足を考慮したストキャスティクス値の取得
   double k_current = iStochastic(Symbol(), Stoch_Timeframe, Stoch_K_Period, Stoch_D_Period, Stoch_Slowing,
                                  Stoch_Method, Stoch_Price_Field, MODE_MAIN, Stoch_Signal_Shift);
   double k_prev = iStochastic(Symbol(), Stoch_Timeframe, Stoch_K_Period, Stoch_D_Period, Stoch_Slowing,
                               Stoch_Method, Stoch_Price_Field, MODE_MAIN, Stoch_Signal_Shift + 1);
   double d_current = iStochastic(Symbol(), Stoch_Timeframe, Stoch_K_Period, Stoch_D_Period, Stoch_Slowing,
                                  Stoch_Method, Stoch_Price_Field, MODE_SIGNAL, Stoch_Signal_Shift);
   double d_prev = iStochastic(Symbol(), Stoch_Timeframe, Stoch_K_Period, Stoch_D_Period, Stoch_Slowing,
                               Stoch_Method, Stoch_Price_Field, MODE_SIGNAL, Stoch_Signal_Shift + 1);

// BUYシグナル
   if(side == 0)
     {
      if(Stoch_Buy_Signal == 0)
         return false;

      bool signal = false;

      switch(Stoch_Buy_Signal)
        {
         case STOCH_OVERSOLD: // 売られすぎ
            signal = (k_current < Stoch_Oversold);
            break;

         case STOCH_K_CROSS_D_OVERSOLD: // %Kが%Dを上抜け（売られすぎ）
            signal = (k_prev < d_prev && k_current > d_current && k_prev < Stoch_Oversold);
            break;

         case STOCH_OVERSOLD_EXIT: // 売られすぎから脱出
            signal = (k_prev < Stoch_Oversold && k_current >= Stoch_Oversold);
            break;

         case STOCH_OVERBOUGHT: // 買われすぎ
            signal = (k_current > Stoch_Overbought);
            break;

         case STOCH_K_CROSS_D_OVERBOUGHT: // %Kが%Dを下抜け（買われすぎ）
            signal = (k_prev > d_prev && k_current < d_current && k_prev > Stoch_Overbought);
            break;

         case STOCH_OVERBOUGHT_EXIT: // 買われすぎから脱出
            signal = (k_prev > Stoch_Overbought && k_current <= Stoch_Overbought);
            break;
        }

      // 取引方向に基づいて判断
      return (Stoch_Buy_Direction == TREND_FOLLOWING) ? signal : !signal;
     }
// SELLシグナル
   else
     {
      if(Stoch_Sell_Signal == 0)
         return false;

      bool signal = false;

      switch(Stoch_Sell_Signal)
        {
         case STOCH_OVERBOUGHT: // 買われすぎ
            signal = (k_current > Stoch_Overbought);
            break;

         case STOCH_K_CROSS_D_OVERBOUGHT: // %Kが%Dを下抜け（買われすぎ）
            signal = (k_prev > d_prev && k_current < d_current && k_prev > Stoch_Overbought);
            break;

         case STOCH_OVERBOUGHT_EXIT: // 買われすぎから脱出
            signal = (k_prev > Stoch_Overbought && k_current <= Stoch_Overbought);
            break;

         case STOCH_OVERSOLD: // 売られすぎ
            signal = (k_current < Stoch_Oversold);
            break;

         case STOCH_K_CROSS_D_OVERSOLD: // %Kが%Dを上抜け（売られすぎ）
            signal = (k_prev < d_prev && k_current > d_current && k_prev < Stoch_Oversold);
            break;

         case STOCH_OVERSOLD_EXIT: // 売られすぎから脱出
            signal = (k_prev < Stoch_Oversold && k_current >= Stoch_Oversold);
            break;
        }

      // 取引方向に基づいて判断
      return (Stoch_Sell_Direction == TREND_FOLLOWING) ? signal : !signal;
     }

   return false;
  }

//+------------------------------------------------------------------+
//| CCI戦略のシグナル判断                                            |
//+------------------------------------------------------------------+
bool CheckCCISignal(int side)
  {
   if(CCI_Entry_Strategy == CCI_ENTRY_DISABLED)
      return false;

// 時間足を考慮したCCI値の取得
   double cci_current = iCCI(Symbol(), CCI_Timeframe, CCI_Period, CCI_Price, CCI_Signal_Shift);
   double cci_prev = iCCI(Symbol(), CCI_Timeframe, CCI_Period, CCI_Price, CCI_Signal_Shift + 1);

// BUYシグナル
   if(side == 0)
     {
      if(CCI_Buy_Signal == 0)
         return false;

      bool signal = false;

      switch(CCI_Buy_Signal)
        {
         case CCI_OVERSOLD: // 売られすぎ
            signal = (cci_current < CCI_Oversold);
            break;

         case CCI_OVERSOLD_EXIT: // 売られすぎから回復
            signal = (cci_prev < CCI_Oversold && cci_current >= CCI_Oversold);
            break;

         case CCI_OVERBOUGHT: // 買われすぎ
            signal = (cci_current > CCI_Overbought);
            break;

         case CCI_OVERBOUGHT_EXIT: // 買われすぎから下落
            signal = (cci_prev > CCI_Overbought && cci_current <= CCI_Overbought);
            break;
        }

      // 取引方向に基づいて判断
      return (CCI_Buy_Direction == TREND_FOLLOWING) ? signal : !signal;
     }
// SELLシグナル
   else
     {
      if(CCI_Sell_Signal == 0)
         return false;

      bool signal = false;

      switch(CCI_Sell_Signal)
        {
         case CCI_OVERBOUGHT: // 買われすぎ
            signal = (cci_current > CCI_Overbought);
            break;

         case CCI_OVERBOUGHT_EXIT: // 買われすぎから下落
            signal = (cci_prev > CCI_Overbought && cci_current <= CCI_Overbought);
            break;

         case CCI_OVERSOLD: // 売られすぎ
            signal = (cci_current < CCI_Oversold);
            break;

         case CCI_OVERSOLD_EXIT: // 売られすぎから回復
            signal = (cci_prev < CCI_Oversold && cci_current >= CCI_Oversold);
            break;
        }

      // 取引方向に基づいて判断
      return (CCI_Sell_Direction == TREND_FOLLOWING) ? signal : !signal;
     }

   return false;
  }

//+------------------------------------------------------------------+
//| ADX/DMI戦略のシグナル判断                                        |
//+------------------------------------------------------------------+
bool CheckADXSignal(int side)
  {
   if(ADX_Entry_Strategy == ADX_ENTRY_DISABLED)
      return false;

// 時間足を考慮したADX値の取得
   double adx = iADX(Symbol(), ADX_Timeframe, ADX_Period, PRICE_CLOSE, MODE_MAIN, ADX_Signal_Shift);
   double plus_di = iADX(Symbol(), ADX_Timeframe, ADX_Period, PRICE_CLOSE, MODE_PLUSDI, ADX_Signal_Shift);
   double minus_di = iADX(Symbol(), ADX_Timeframe, ADX_Period, PRICE_CLOSE, MODE_MINUSDI, ADX_Signal_Shift);
   double plus_di_prev = iADX(Symbol(), ADX_Timeframe, ADX_Period, PRICE_CLOSE, MODE_PLUSDI, ADX_Signal_Shift + 1);
   double minus_di_prev = iADX(Symbol(), ADX_Timeframe, ADX_Period, PRICE_CLOSE, MODE_MINUSDI, ADX_Signal_Shift + 1);

// BUYシグナル
   if(side == 0)
     {
      if(ADX_Buy_Signal == 0)
         return false;

      bool signal = false;

      switch(ADX_Buy_Signal)
        {
         case ADX_PLUS_DI_CROSS_MINUS_DI: // +DIが-DIを上抜け
            signal = (plus_di_prev < minus_di_prev && plus_di > minus_di);
            break;

         case ADX_STRONG_TREND_PLUS_DI: // 強いトレンドで+DI > -DI
            signal = (adx > ADX_Threshold && plus_di > minus_di);
            break;

         case ADX_MINUS_DI_CROSS_PLUS_DI: // -DIが+DIを上抜け
            signal = (minus_di_prev < plus_di_prev && minus_di > plus_di);
            break;

         case ADX_STRONG_TREND_MINUS_DI: // 強いトレンドで-DI > +DI
            signal = (adx > ADX_Threshold && minus_di > plus_di);
            break;
        }

      // 取引方向に基づいて判断
      return (ADX_Buy_Direction == TREND_FOLLOWING) ? signal : !signal;
     }
// SELLシグナル
   else
     {
      if(ADX_Sell_Signal == 0)
         return false;

      bool signal = false;

      switch(ADX_Sell_Signal)
        {
         case ADX_MINUS_DI_CROSS_PLUS_DI: // -DIが+DIを上抜け
            signal = (minus_di_prev < plus_di_prev && minus_di > plus_di);
            break;

         case ADX_STRONG_TREND_MINUS_DI: // 強いトレンドで-DI > +DI
            signal = (adx > ADX_Threshold && minus_di > plus_di);
            break;

         case ADX_PLUS_DI_CROSS_MINUS_DI: // +DIが-DIを上抜け
            signal = (plus_di_prev < minus_di_prev && plus_di > minus_di);
            break;

         case ADX_STRONG_TREND_PLUS_DI: // 強いトレンドで+DI > +DI
            signal = (adx > ADX_Threshold && plus_di > minus_di);
            break;
        }

      // 取引方向に基づいて判断
      return (ADX_Sell_Direction == TREND_FOLLOWING) ? signal : !signal;
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
//| CheckIndicatorSignals関数 - 更新版                               |
//+------------------------------------------------------------------+
bool CheckIndicatorSignals(int side)
{
// どれか1つでもシグナルがあればtrue
   return (MA_Entry_Strategy == MA_ENTRY_ENABLED && CheckMASignal(side)) ||
          (RSI_Entry_Strategy == RSI_ENTRY_ENABLED && CheckRSISignal(side)) ||
          (BB_Entry_Strategy == BB_ENTRY_ENABLED && CheckBollingerSignal(side)) ||
          (RCI_Entry_Strategy == RCI_ENTRY_ENABLED && CheckRCISignal(side)) ||
          (Stoch_Entry_Strategy == STOCH_ENTRY_ENABLED && CheckStochasticSignal(side)) ||
          (CCI_Entry_Strategy == CCI_ENTRY_ENABLED && CheckCCISignal(side)) ||
          (ADX_Entry_Strategy == ADX_ENTRY_ENABLED && CheckADXSignal(side)) ||
          (EvenOdd_Entry_Strategy != EVEN_ODD_DISABLED && CheckEvenOddStrategy(side));
}








//+------------------------------------------------------------------+
//| GetStrategyDetails関数 - 更新版                                   |
//+------------------------------------------------------------------+
string GetStrategyDetails(int side)
{
// side: 0 = Buy, 1 = Sell
   string typeStr = (side == 0) ? "Buy" : "Sell";
   string strategyDetails = "【" + typeStr + " 戦略シグナル詳細】\n";

// 【セクション: 時間戦略】
   bool timeEntryAllowed = IsTimeEntryAllowed(side);
   strategyDetails += "【時間条件】: " + (timeEntryAllowed ? "許可" : "不許可") + "\n";

// 【セクション: MAクロス】
   if(MA_Entry_Strategy == MA_ENTRY_ENABLED)
   {
      bool maSignal = CheckMASignal(side);

      // MA値の取得
      double fastMA_current, slowMA_current;
      if(side == 0)
      {
         fastMA_current = iMA(Symbol(), MA_Timeframe, MA_Buy_Fast_Period, 0, MA_Method, MA_Price, MA_Cross_Shift);
         slowMA_current = iMA(Symbol(), MA_Timeframe, MA_Buy_Slow_Period, 0, MA_Method, MA_Price, MA_Cross_Shift);
      }
      else
      {
         fastMA_current = iMA(Symbol(), MA_Timeframe, MA_Sell_Fast_Period, 0, MA_Method, MA_Price, MA_Cross_Shift);
         slowMA_current = iMA(Symbol(), MA_Timeframe, MA_Sell_Slow_Period, 0, MA_Method, MA_Price, MA_Cross_Shift);
      }

      strategyDetails += "【MAクロス】: " + (maSignal ? "シグナルあり" : "シグナルなし") +
                       " (短期MA=" + DoubleToString(fastMA_current, Digits) +
                       ", 長期MA=" + DoubleToString(slowMA_current, Digits) + ")\n";
   }

// 【セクション: RSI】
   if(RSI_Entry_Strategy == RSI_ENTRY_ENABLED)
   {
      bool rsiSignal = CheckRSISignal(side);

      // RSI値の取得
      double rsi_current = iRSI(Symbol(), RSI_Timeframe, RSI_Period, RSI_Price, RSI_Signal_Shift);
      strategyDetails += "【RSI】: " + (rsiSignal ? "シグナルあり" : "シグナルなし") +
                       " (値=" + DoubleToString(rsi_current, 2) +
                       ", 買われすぎ=" + IntegerToString(RSI_Overbought) +
                       ", 売られすぎ=" + IntegerToString(RSI_Oversold) + ")\n";
   }

// 【セクション: ボリンジャーバンド】
   if(BB_Entry_Strategy == BB_ENTRY_ENABLED)
   {
      bool bbSignal = CheckBollingerSignal(side);

      // ボリンジャーバンド値の取得
      double middle = iBands(Symbol(), BB_Timeframe, BB_Period, BB_Deviation, 0, BB_Price, MODE_MAIN, BB_Signal_Shift);
      double upper = iBands(Symbol(), BB_Timeframe, BB_Period, BB_Deviation, 0, BB_Price, MODE_UPPER, BB_Signal_Shift);
      double lower = iBands(Symbol(), BB_Timeframe, BB_Period, BB_Deviation, 0, BB_Price, MODE_LOWER, BB_Signal_Shift);
      double close = iClose(Symbol(), BB_Timeframe, BB_Signal_Shift);

      strategyDetails += "【ボリンジャーバンド】: " + (bbSignal ? "シグナルあり" : "シグナルなし") +
                       " (上=" + DoubleToString(upper, Digits) +
                       ", 中=" + DoubleToString(middle, Digits) +
                       ", 下=" + DoubleToString(lower, Digits) +
                       ", 終値=" + DoubleToString(close, Digits) + ")\n";
   }

// 【セクション: RCI】
   if(RCI_Entry_Strategy == RCI_ENTRY_ENABLED)
   {
      bool rciSignal = CheckRCISignal(side);

      // RCI値の取得
      double rci_current = CalculateRCI(RCI_Period, RCI_Signal_Shift, RCI_Timeframe);
      strategyDetails += "【RCI】: " + (rciSignal ? "シグナルあり" : "シグナルなし") +
                       " (値=" + DoubleToString(rci_current, 2) +
                       ", しきい値=" + IntegerToString(RCI_Threshold) + ")\n";
   }

// 【セクション: ストキャスティクス】
   if(Stoch_Entry_Strategy == STOCH_ENTRY_ENABLED)
   {
      bool stochSignal = CheckStochasticSignal(side);

      // ストキャスティクス値の取得
      double k_current = iStochastic(Symbol(), Stoch_Timeframe, Stoch_K_Period, Stoch_D_Period,
                                   Stoch_Slowing, Stoch_Method, Stoch_Price_Field,
                                   MODE_MAIN, Stoch_Signal_Shift);
      double d_current = iStochastic(Symbol(), Stoch_Timeframe, Stoch_K_Period, Stoch_D_Period,
                                   Stoch_Slowing, Stoch_Method, Stoch_Price_Field,
                                   MODE_SIGNAL, Stoch_Signal_Shift);

      strategyDetails += "【ストキャスティクス】: " + (stochSignal ? "シグナルあり" : "シグナルなし") +
                       " (K=" + DoubleToString(k_current, 2) +
                       ", D=" + DoubleToString(d_current, 2) +
                       ", 買われすぎ=" + IntegerToString(Stoch_Overbought) +
                       ", 売られすぎ=" + IntegerToString(Stoch_Oversold) + ")\n";
   }

// 【セクション: CCI】
   if(CCI_Entry_Strategy == CCI_ENTRY_ENABLED)
   {
      bool cciSignal = CheckCCISignal(side);

      // CCI値の取得
      double cci_current = iCCI(Symbol(), CCI_Timeframe, CCI_Period, CCI_Price, CCI_Signal_Shift);
      strategyDetails += "【CCI】: " + (cciSignal ? "シグナルあり" : "シグナルなし") +
                       " (値=" + DoubleToString(cci_current, 2) +
                       ", 買われすぎ=" + IntegerToString(CCI_Overbought) +
                       ", 売られすぎ=" + IntegerToString(CCI_Oversold) + ")\n";
   }

// 【セクション: ADX/DMI】
   if(ADX_Entry_Strategy == ADX_ENTRY_ENABLED)
   {
      bool adxSignal = CheckADXSignal(side);

      // ADX値の取得
      double adx = iADX(Symbol(), ADX_Timeframe, ADX_Period, PRICE_CLOSE, MODE_MAIN, ADX_Signal_Shift);
      double plus_di = iADX(Symbol(), ADX_Timeframe, ADX_Period, PRICE_CLOSE, MODE_PLUSDI, ADX_Signal_Shift);
      double minus_di = iADX(Symbol(), ADX_Timeframe, ADX_Period, PRICE_CLOSE, MODE_MINUSDI, ADX_Signal_Shift);

      strategyDetails += "【ADX/DMI】: " + (adxSignal ? "シグナルあり" : "シグナルなし") +
                       " (ADX=" + DoubleToString(adx, 2) +
                       ", +DI=" + DoubleToString(plus_di, 2) +
                       ", -DI=" + DoubleToString(minus_di, 2) +
                       ", しきい値=" + IntegerToString(ADX_Threshold) + ")\n";
   }

// 【セクション: 偶数/奇数時間】
   if(EvenOdd_Entry_Strategy != EVEN_ODD_DISABLED)
   {
      bool evenOddSignal = CheckEvenOddStrategy(side);
      
      // 現在の時間情報を取得
      datetime current_time = EvenOdd_UseJPTime ? calculate_time() : TimeCurrent();
      int current_hour = TimeHour(current_time);
      bool is_even_hour = (current_hour % 2 == 0);
      
      strategyDetails += "【偶数/奇数時間】: " + (evenOddSignal ? "シグナルあり" : "シグナルなし") +
                       " (現在時間=" + IntegerToString(current_hour) + "時" +
                       ", " + (is_even_hour ? "偶数時間" : "奇数時間") + 
                       ", モード=" + GetEvenOddStrategyState() + ")\n";
   }

   return strategyDetails;
}








//+------------------------------------------------------------------+
//| ProcessStrategyLogic関数 - 戦略ロジックのメイン処理（更新版）      |
//+------------------------------------------------------------------+
void ProcessStrategyLogic()
{
// 【セクション: 自動売買チェック】
   if(!EnableAutomaticTrading)
   {
      Print("【自動売買チェック】: 自動売買が無効のためスキップします");
      return;
   }

// 【セクション: ポジション状態確認】
   bool hasRealBuy = position_count(OP_BUY) > 0;
   bool hasRealSell = position_count(OP_SELL) > 0;

// 【セクション: ゴーストモード設定】
   bool useGhostMode = (NanpinSkipLevel != SKIP_NONE) && g_GhostMode;

// ゴーストエントリー機能がOFFの場合はゴーストモードを無効化
   if(!EnableGhostEntry)
   {
      useGhostMode = false;
   }

   Print("【ポジション状態】: リアルポジション状況 - Buy=", hasRealBuy, ", Sell=", hasRealSell);
   Print("【ゴーストモード】: 設定=", useGhostMode ? "有効" : "無効", ", NanpinSkipLevel=", EnumToString(NanpinSkipLevel));

// 【セクション: 既存ポジションの管理】
   if(hasRealBuy || hasRealSell)
   {
      // ナンピン機能が有効な場合のみナンピン条件をチェック
      if(EnableNanpin)
      {
         Print("【ナンピン管理】: リアルポジションあり、ナンピン条件チェック開始");
         // リアルポジションのナンピン条件をチェック
         CheckNanpinConditions(0); // Buy側のナンピン条件チェック
         CheckNanpinConditions(1); // Sell側のナンピン条件チェック
      }
   }
   else
   {
      // 【セクション: 新規エントリー管理】
      Print("【新規エントリー】: リアルポジションなし、エントリー条件チェック開始");

      // エントリーモード表示
      Print("【エントリーモード】: 現在のエントリーモード=",
            (EntryMode == MODE_BUY_ONLY) ? "BUYのみ" :
            (EntryMode == MODE_SELL_ONLY) ? "SELLのみ" : "両方");

      // 【セクション: 偶数/奇数時間戦略チェック】
      if(EvenOdd_Entry_Strategy != EVEN_ODD_DISABLED)
      {
         datetime current_time = EvenOdd_UseJPTime ? calculate_time() : TimeCurrent();
         int current_hour = TimeHour(current_time);
         bool is_even_hour = (current_hour % 2 == 0);
         
         string strategyType = (EvenOdd_Entry_Strategy == EVEN_HOUR_BUY_ODD_HOUR_SELL) ? 
                             "偶数時間Buy・奇数時間Sell" : 
                             "奇数時間Buy・偶数時間Sell";
         
         Print("【偶数/奇数時間戦略】: 現在時間=", current_hour, "時", 
               ", 時間タイプ=", is_even_hour ? "偶数時間" : "奇数時間", 
               ", 戦略タイプ=", strategyType);
         
         // 変数にフラグを設定（g_UseEvenOddHoursEntryフラグの更新）
         g_UseEvenOddHoursEntry = true;
      }
      else
      {
         g_UseEvenOddHoursEntry = false;
      }

      // ゴーストモードがONの場合
      if(useGhostMode && EnableGhostEntry)
      {
         Print("【ゴーストエントリー】: ゴーストエントリー処理を実行");
         // エントリーモードに基づいてゴーストエントリー処理
         if(EntryMode == MODE_BUY_ONLY || EntryMode == MODE_BOTH)
         {
            ProcessGhostEntries(0); // Buy側
         }

         if(EntryMode == MODE_SELL_ONLY || EntryMode == MODE_BOTH)
         {
            ProcessGhostEntries(1); // Sell側
         }
      }
      else
      {
         Print("【リアルエントリー】: リアルエントリー処理を実行");
         // エントリーモードに基づいてリアルエントリー処理
         if(EntryMode == MODE_BUY_ONLY || EntryMode == MODE_BOTH)
         {
            ProcessRealEntries(0); // Buy側
         }

         if(EntryMode == MODE_SELL_ONLY || EntryMode == MODE_BOTH)
         {
            ProcessRealEntries(1); // Sell側
         }
      }
   }
}


//+------------------------------------------------------------------+
//| ProcessRealEntries関数 - リアルエントリー処理                      |
//+------------------------------------------------------------------+
void ProcessRealEntries(int side)
  {
   string direction = (side == 0) ? "Buy" : "Sell";
   Print("ProcessRealEntries: ", direction, " 処理開始");

// リアルポジションがある場合はスキップ
   int operationType = (side == 0) ? OP_BUY : OP_SELL;
   int existingCount = position_count(operationType);

   if(existingCount > 0)
     {
      Print("既に", direction, "リアルポジションが存在するため、リアルエントリーはスキップされました: ", existingCount, "ポジション");
      return;
     }

// エントリーモードに基づくチェック
   bool modeAllowed = false;
   if(side == 0) // Buy
      modeAllowed = (EntryMode == MODE_BUY_ONLY || EntryMode == MODE_BOTH);
   else // Sell
      modeAllowed = (EntryMode == MODE_SELL_ONLY || EntryMode == MODE_BOTH);

   if(!modeAllowed)
     {
      Print("ProcessRealEntries: エントリーモードにより", direction, "側はスキップします");
      return;
     }

   Print("ProcessRealEntries: ", direction, " エントリーモードチェック通過");

// 戦略評価
   bool shouldEnter = EvaluateStrategyForEntry(side);

   Print("ProcessRealEntries: 最終エントリー判断: ", shouldEnter ? "エントリー実行" : "エントリーなし");

// エントリー条件を満たしていれば新規エントリー
   if(shouldEnter)
     {
      // スプレッドチェック
      double spreadPoints = (GetAskPrice() - GetBidPrice()) / Point;
      if(spreadPoints <= MaxSpreadPoints || MaxSpreadPoints <= 0)
        {
         Print("ProcessRealEntries: リアル", direction, "エントリー実行");

         // リアルエントリー実行
         ExecuteRealEntry(operationType, "戦略シグナル");
        }
      else
        {
         Print("ProcessRealEntries: スプレッドが大きすぎるため、リアル", direction, "エントリーをスキップしました: ",
               spreadPoints, " > ", MaxSpreadPoints);
        }
     }
   else
     {
      Print("ProcessRealEntries: リアル", direction, "エントリー条件不成立のためスキップします");
     }
  }


//+------------------------------------------------------------------+
