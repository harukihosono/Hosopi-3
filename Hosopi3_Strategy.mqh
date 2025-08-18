//+------------------------------------------------------------------+
//|                    Hosopi 3 - 偶数/奇数時間エントリー戦略          |
//|                           Copyright 2025                          |
//|                    MQL4/MQL5 Cross-Platform Version               |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025"
#property link      ""
#property strict


// MQL4との互換性のためのモード定数（上部に移動）
#ifdef __MQL5__
   #define MODE_SMA 0
   #define MODE_EMA 1
   #define MODE_SMMA 2
   #define MODE_LWMA 3
   
   // ボリンジャーバンド用
   #define MODE_MAIN 0
   #define MODE_UPPER 1
   #define MODE_LOWER 2
   
   // ストキャスティクス用
   #define MODE_SIGNAL 1
   
   // ADX用
   #define MODE_PLUSDI 1
   #define MODE_MINUSDI 2
#endif


//+------------------------------------------------------------------+
//| グローバル変数 - インジケーターハンドル（MQL5用）                  |
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

// インジケーター値を格納するバッファ
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
#endif

//+------------------------------------------------------------------+
//| 偶数/奇数時間エントリー戦略のタイプ定義                            |
//+------------------------------------------------------------------+
enum EVEN_ODD_STRATEGY_TYPE
{
   EVEN_ODD_DISABLED = 0,       // 無効
   EVEN_HOUR_BUY_ODD_HOUR_SELL = 1,  // 偶数時間Buy・奇数時間Sell
   ODD_HOUR_BUY_EVEN_HOUR_SELL = 2,  // 奇数時間Buy・偶数時間Sell
   EVEN_HOUR_BOTH = 3,          // 偶数時間のみ両方向
   ODD_HOUR_BOTH = 4,           // 奇数時間のみ両方向
   ALL_HOURS_ENABLED = 5        // 全時間両方向
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
#ifdef __MQL4__
      int day_of_week = TimeDayOfWeek(current_time);
#else
      MqlDateTime dt;
      TimeToStruct(current_time, dt);
      int day_of_week = dt.day_of_week;
#endif
      if(day_of_week == 0 || day_of_week == 6)  // 0=日曜日, 6=土曜日
         return false;  // 週末は取引しない
   }
   
   // 現在の時間（時）を取得
#ifdef __MQL4__
   int current_hour = TimeHour(current_time);
#else
   MqlDateTime dt;
   TimeToStruct(current_time, dt);
   int current_hour = dt.hour;
#endif
   
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
   
   // 全時間両方向が有効な場合は常にtrue
   if(EvenOdd_Entry_Strategy == ALL_HOURS_ENABLED)
      return true;
      
   // 偶数時間両方向
   if(EvenOdd_Entry_Strategy == EVEN_HOUR_BOTH)
      return is_even_hour;
      
   // 奇数時間両方向
   if(EvenOdd_Entry_Strategy == ODD_HOUR_BOTH)
      return !is_even_hour;
   
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
   else if(EvenOdd_Entry_Strategy == EVEN_HOUR_BOTH)
      state = "偶数時間のみ両方向";
   else if(EvenOdd_Entry_Strategy == ODD_HOUR_BOTH)
      state = "奇数時間のみ両方向";
   else if(EvenOdd_Entry_Strategy == ALL_HOURS_ENABLED)
      state = "全時間両方向";
      
   return state + " (" + timeBase + ", " + weekendStatus + ")";
}

//+------------------------------------------------------------------+
//| 各テクニカル指標のエントリータイプ定義                            |
//+------------------------------------------------------------------+
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
//| 常時エントリー戦略のタイプ定義                                    |
//+------------------------------------------------------------------+
enum CONSTANT_ENTRY_STRATEGY_TYPE
{
   CONSTANT_ENTRY_DISABLED = 0,     // 無効
   CONSTANT_ENTRY_LONG = 1,         // 常時ロングエントリー
   CONSTANT_ENTRY_SHORT = 2,        // 常時ショートエントリー
   CONSTANT_ENTRY_BOTH = 3          // 常時ロング＆ショート両方
};

//+------------------------------------------------------------------+
//| 常時エントリー戦略パラメータ                                      |
//+------------------------------------------------------------------+
// ======== 常時エントリー戦略設定 ========
sinput string Comment_ConstantEntry = ""; //+--- 常時エントリー設定 ---+
input CONSTANT_ENTRY_STRATEGY_TYPE ConstantEntryStrategy = CONSTANT_ENTRY_DISABLED; // 常時エントリー戦略
input int ConstantEntryInterval = 0;        // 常時エントリー間隔（分）

//+------------------------------------------------------------------+
//| 常時エントリー戦略の状態を保持するグローバル変数                   |
//+------------------------------------------------------------------+
datetime g_LastConstantLongEntryTime = 0;    // 最後のロングエントリー時間
datetime g_LastConstantShortEntryTime = 0;   // 最後のショートエントリー時間

//+------------------------------------------------------------------+
//| 戦略初期化関数（メインファイルのOnInitから呼び出し）               |
//+------------------------------------------------------------------+
bool InitializeStrategy()
{
#ifdef __MQL5__
   // MQL5用のインジケーターハンドル初期化
   bool init_success = true;
   
   // MA戦略が有効な場合
   if(MA_Entry_Strategy == MA_ENTRY_ENABLED)
   {
      g_ma_buy_fast_handle = iMA(_Symbol, MA_Timeframe, MA_Buy_Fast_Period, 0, MA_Method, MA_Price);
      g_ma_buy_slow_handle = iMA(_Symbol, MA_Timeframe, MA_Buy_Slow_Period, 0, MA_Method, MA_Price);
      g_ma_sell_fast_handle = iMA(_Symbol, MA_Timeframe, MA_Sell_Fast_Period, 0, MA_Method, MA_Price);
      g_ma_sell_slow_handle = iMA(_Symbol, MA_Timeframe, MA_Sell_Slow_Period, 0, MA_Method, MA_Price);
      
      if(g_ma_buy_fast_handle == INVALID_HANDLE || g_ma_buy_slow_handle == INVALID_HANDLE ||
         g_ma_sell_fast_handle == INVALID_HANDLE || g_ma_sell_slow_handle == INVALID_HANDLE)
      {
         Print("MAハンドルの作成に失敗しました");
         init_success = false;
      }
   }
   
   // RSI戦略が有効な場合
   if(RSI_Entry_Strategy == RSI_ENTRY_ENABLED)
   {
      g_rsi_handle = iRSI(_Symbol, RSI_Timeframe, RSI_Period, RSI_Price);
      if(g_rsi_handle == INVALID_HANDLE)
      {
         Print("RSIハンドルの作成に失敗しました");
         init_success = false;
      }
   }
   
   // ボリンジャーバンド戦略が有効な場合
   if(BB_Entry_Strategy == BB_ENTRY_ENABLED)
   {
      g_bb_handle = iBands(_Symbol, BB_Timeframe, BB_Period, 0, BB_Deviation, BB_Price);
      if(g_bb_handle == INVALID_HANDLE)
      {
         Print("ボリンジャーバンドハンドルの作成に失敗しました");
         init_success = false;
      }
   }
   
   // ストキャスティクス戦略が有効な場合
   if(Stoch_Entry_Strategy == STOCH_ENTRY_ENABLED)
   {
      g_stoch_handle = iStochastic(_Symbol, Stoch_Timeframe, Stoch_K_Period, Stoch_D_Period, 
                                   Stoch_Slowing, Stoch_Method, (ENUM_STO_PRICE)Stoch_Price_Field);
      if(g_stoch_handle == INVALID_HANDLE)
      {
         Print("ストキャスティクスハンドルの作成に失敗しました");
         init_success = false;
      }
   }
   
   // CCI戦略が有効な場合
   if(CCI_Entry_Strategy == CCI_ENTRY_ENABLED)
   {
      g_cci_handle = iCCI(_Symbol, CCI_Timeframe, CCI_Period, CCI_Price);
      if(g_cci_handle == INVALID_HANDLE)
      {
         Print("CCIハンドルの作成に失敗しました");
         init_success = false;
      }
   }
   
   // ADX戦略が有効な場合
   if(ADX_Entry_Strategy == ADX_ENTRY_ENABLED)
   {
      g_adx_handle = iADX(_Symbol, ADX_Timeframe, ADX_Period);
      if(g_adx_handle == INVALID_HANDLE)
      {
         Print("ADXハンドルの作成に失敗しました");
         init_success = false;
      }
   }
   
   // テクニカルフィルターが有効な場合
   if(FilterType == FILTER_ENVELOPE)
   {
      g_envelope_handle = iEnvelopes(_Symbol, FilterTimeframe, FilterPeriod, 0, 
                                    FilterMethod, PRICE_CLOSE, EnvelopeDeviation);
      if(g_envelope_handle == INVALID_HANDLE)
      {
         Print("エンベロープハンドルの作成に失敗しました");
         init_success = false;
      }
   }
   else if(FilterType == FILTER_BOLLINGER)
   {
      // ボリンジャーバンドは必要に応じて動的に生成
      // ハンドル不要
   }
   
   // バッファを時系列として設定
   ArraySetAsSeries(g_ma_buy_fast_buffer, true);
   ArraySetAsSeries(g_ma_buy_slow_buffer, true);
   ArraySetAsSeries(g_ma_sell_fast_buffer, true);
   ArraySetAsSeries(g_ma_sell_slow_buffer, true);
   ArraySetAsSeries(g_rsi_buffer, true);
   ArraySetAsSeries(g_bb_main_buffer, true);
   ArraySetAsSeries(g_bb_upper_buffer, true);
   ArraySetAsSeries(g_bb_lower_buffer, true);
   ArraySetAsSeries(g_stoch_main_buffer, true);
   ArraySetAsSeries(g_stoch_signal_buffer, true);
   ArraySetAsSeries(g_cci_buffer, true);
   ArraySetAsSeries(g_adx_main_buffer, true);
   ArraySetAsSeries(g_adx_plusdi_buffer, true);
   ArraySetAsSeries(g_adx_minusdi_buffer, true);
   ArraySetAsSeries(g_envelope_upper_buffer, true);
   ArraySetAsSeries(g_envelope_lower_buffer, true);
   
   return init_success;
#else
   // MQL4では特に初期化処理は不要
   return true;
#endif
}

//+------------------------------------------------------------------+
//| 戦略終了処理関数（メインファイルのOnDeinitから呼び出し）           |
//+------------------------------------------------------------------+
void DeinitializeStrategy(const int reason)
{
#ifdef __MQL5__
   // 理由に応じた処理
   if(reason == REASON_CHARTCHANGE)
   {
      // 時間軸変更の場合はハンドルを保持
      return;
   }
   
   // MQL5用のハンドル解放
   if(g_ma_buy_fast_handle != INVALID_HANDLE) IndicatorRelease(g_ma_buy_fast_handle);
   if(g_ma_buy_slow_handle != INVALID_HANDLE) IndicatorRelease(g_ma_buy_slow_handle);
   if(g_ma_sell_fast_handle != INVALID_HANDLE) IndicatorRelease(g_ma_sell_fast_handle);
   if(g_ma_sell_slow_handle != INVALID_HANDLE) IndicatorRelease(g_ma_sell_slow_handle);
   if(g_rsi_handle != INVALID_HANDLE) IndicatorRelease(g_rsi_handle);
   if(g_bb_handle != INVALID_HANDLE) IndicatorRelease(g_bb_handle);
   if(g_stoch_handle != INVALID_HANDLE) IndicatorRelease(g_stoch_handle);
   if(g_cci_handle != INVALID_HANDLE) IndicatorRelease(g_cci_handle);
   if(g_adx_handle != INVALID_HANDLE) IndicatorRelease(g_adx_handle);
#endif
}

//+------------------------------------------------------------------+
//| MQL5用のインジケーター値取得関数                                  |
//+------------------------------------------------------------------+
#ifdef __MQL5__
bool GetIndicatorValue(int handle, int buffer_index, int shift, double &value)
{
   double buffer[];
   ArraySetAsSeries(buffer, true);
   ResetLastError();
   
   if(CopyBuffer(handle, buffer_index, shift, 1, buffer) <= 0)
   {
      int error = GetLastError();
      if(error != 4806)  // 4806はデータ未準備で正常
         Print("CopyBufferエラー: ", error);
      return false;
   }
   
   value = buffer[0];
   return true;
}
#endif

//+------------------------------------------------------------------+
//| Digitsの定義（MQL4との互換性）                                   |
//+------------------------------------------------------------------+
#ifdef __MQL5__
   #define Digits _Digits
#endif

//+------------------------------------------------------------------+
//| クロスプラットフォーム対応のMAクロス判定                           |
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
//| クロスプラットフォーム対応のADX/DMI判定                           |
//+------------------------------------------------------------------+
bool CheckADXSignal(int side)
{
   if(ADX_Entry_Strategy == ADX_ENTRY_DISABLED)
      return false;

   double adx, plus_di, minus_di, plus_di_prev, minus_di_prev;

#ifdef __MQL4__
   // MQL4での直接取得
   adx = iADX(_Symbol, ADX_Timeframe, ADX_Period, PRICE_CLOSE, MODE_MAIN, ADX_Signal_Shift);
   plus_di = iADX(_Symbol, ADX_Timeframe, ADX_Period, PRICE_CLOSE, MODE_PLUSDI, ADX_Signal_Shift);
   minus_di = iADX(_Symbol, ADX_Timeframe, ADX_Period, PRICE_CLOSE, MODE_MINUSDI, ADX_Signal_Shift);
   plus_di_prev = iADX(_Symbol, ADX_Timeframe, ADX_Period, PRICE_CLOSE, MODE_PLUSDI, ADX_Signal_Shift + 1);
   minus_di_prev = iADX(_Symbol, ADX_Timeframe, ADX_Period, PRICE_CLOSE, MODE_MINUSDI, ADX_Signal_Shift + 1);
#else
   // MQL5でのCopyBuffer使用
   if(!GetIndicatorValue(g_adx_handle, 0, ADX_Signal_Shift, adx) ||
      !GetIndicatorValue(g_adx_handle, 1, ADX_Signal_Shift, plus_di) ||
      !GetIndicatorValue(g_adx_handle, 2, ADX_Signal_Shift, minus_di) ||
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
            signal = (plus_di_prev < minus_di_prev && plus_di > minus_di);
            break;
         case ADX_STRONG_TREND_PLUS_DI:
            signal = (adx > ADX_Threshold && plus_di > minus_di);
            break;
         case ADX_MINUS_DI_CROSS_PLUS_DI:
            signal = (minus_di_prev < plus_di_prev && minus_di > plus_di);
            break;
         case ADX_STRONG_TREND_MINUS_DI:
            signal = (adx > ADX_Threshold && minus_di > plus_di);
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
            signal = (minus_di_prev < plus_di_prev && minus_di > plus_di);
            break;
         case ADX_STRONG_TREND_MINUS_DI:
            signal = (adx > ADX_Threshold && minus_di > plus_di);
            break;
         case ADX_PLUS_DI_CROSS_MINUS_DI:
            signal = (plus_di_prev < minus_di_prev && plus_di > minus_di);
            break;
         case ADX_STRONG_TREND_PLUS_DI:
            signal = (adx > ADX_Threshold && plus_di > minus_di);
            break;
      }
      return (ADX_Sell_Direction == TREND_FOLLOWING) ? signal : !signal;
   }
}

//+------------------------------------------------------------------+
//| テクニカルフィルターの判定                                      |
//+------------------------------------------------------------------+
bool CheckTechnicalFilter(int side)
{
   // フィルターが無効の場合
   if(FilterType == FILTER_NONE)
      return true;
      
   // エンベロープフィルター
   if(FilterType == FILTER_ENVELOPE)
      return CheckEnvelopeFilter(side);
      
   // ボリンジャーバンドフィルター
   if(FilterType == FILTER_BOLLINGER)
      return CheckBollingerFilter(side);
      
   return true;
}

//+------------------------------------------------------------------+
//| エンベロープフィルターの判定                                      |
//+------------------------------------------------------------------+
bool CheckEnvelopeFilter(int side)
{
   double target_band_current, target_band_previous = 0;
   double price_current, price_previous = 0;
   
   // Buy/Sellに応じた条件を取得
   ENUM_BAND_TARGET currentTarget = (side == 0) ? BuyBandTarget : SellBandTarget;
   ENUM_BAND_CONDITION currentCondition = (side == 0) ? BuyBandCondition : SellBandCondition;
   
   // 現在の価格とバンド値を取得
   price_current = GetClosePrice(FilterShift);
   if(!GetEnvelopeBandValue(FilterShift, target_band_current, currentTarget))
      return false;
      
   // クロス条件の場合は前の足の値も取得
   if(currentCondition == BAND_CROSS_DOWN || currentCondition == BAND_CROSS_UP)
   {
      price_previous = GetClosePrice(FilterShift + 1);
      if(!GetEnvelopeBandValue(FilterShift + 1, target_band_previous, currentTarget))
         return false;
   }
   
   return EvaluateBandCondition(price_current, target_band_current, price_previous, target_band_previous, currentCondition);
}

//+------------------------------------------------------------------+
//| エンベロープバンド値取得                                      |
//+------------------------------------------------------------------+
bool GetEnvelopeBandValue(int shift, double &band_value, ENUM_BAND_TARGET target)
{
#ifdef __MQL4__
   // MQL4での直接取得
   if(target == BAND_UPPER)
      band_value = iEnvelopes(_Symbol, FilterTimeframe, FilterPeriod, 0, 
                             FilterMethod, PRICE_CLOSE, EnvelopeDeviation, MODE_UPPER, shift);
   else if(target == BAND_LOWER)
      band_value = iEnvelopes(_Symbol, FilterTimeframe, FilterPeriod, 0, 
                             FilterMethod, PRICE_CLOSE, EnvelopeDeviation, MODE_LOWER, shift);
   else // BAND_MIDDLE
      band_value = iMA(_Symbol, FilterTimeframe, FilterPeriod, 0, FilterMethod, PRICE_CLOSE, shift);
      
   return (band_value > 0);
#else
   // MQL5でのCopyBuffer使用
   if(target == BAND_UPPER)
      return GetIndicatorValue(g_envelope_handle, 0, shift, band_value);
   else if(target == BAND_LOWER)
      return GetIndicatorValue(g_envelope_handle, 1, shift, band_value);
   else // BAND_MIDDLE
   {
      // 中央バンドは移動平均と同じ
      int ma_handle = iMA(_Symbol, FilterTimeframe, FilterPeriod, 0, FilterMethod, PRICE_CLOSE);
      return GetIndicatorValue(ma_handle, 0, shift, band_value);
   }
#endif
}

//+------------------------------------------------------------------+
//| ボリンジャーバンドフィルターの判定                              |
//+------------------------------------------------------------------+
bool CheckBollingerFilter(int side)
{
   double target_band_current, target_band_previous = 0;
   double price_current, price_previous = 0;
   
   // Buy/Sellに応じた条件を取得
   ENUM_BAND_TARGET currentTarget = (side == 0) ? BuyBandTarget : SellBandTarget;
   ENUM_BAND_CONDITION currentCondition = (side == 0) ? BuyBandCondition : SellBandCondition;
   
   // 現在の価格とバンド値を取得
   price_current = GetClosePrice(FilterShift);
   if(!GetBollingerBandValue(FilterShift, target_band_current, currentTarget))
      return false;
      
   // クロス条件の場合は前の足の値も取得
   if(currentCondition == BAND_CROSS_DOWN || currentCondition == BAND_CROSS_UP)
   {
      price_previous = GetClosePrice(FilterShift + 1);
      if(!GetBollingerBandValue(FilterShift + 1, target_band_previous, currentTarget))
         return false;
   }
   
   return EvaluateBandCondition(price_current, target_band_current, price_previous, target_band_previous, currentCondition);
}

//+------------------------------------------------------------------+
//| ボリンジャーバンド値取得                                      |
//+------------------------------------------------------------------+
bool GetBollingerBandValue(int shift, double &band_value, ENUM_BAND_TARGET target)
{
#ifdef __MQL4__
   // MQL4での直接取得
   if(target == BAND_UPPER)
      band_value = iBands(_Symbol, FilterTimeframe, FilterPeriod, BollingerDeviation, 0, 
                         BollingerAppliedPrice, MODE_UPPER, shift);
   else if(target == BAND_LOWER)
      band_value = iBands(_Symbol, FilterTimeframe, FilterPeriod, BollingerDeviation, 0, 
                         BollingerAppliedPrice, MODE_LOWER, shift);
   else // BAND_MIDDLE
      band_value = iBands(_Symbol, FilterTimeframe, FilterPeriod, BollingerDeviation, 0, 
                         BollingerAppliedPrice, MODE_MAIN, shift);
      
   return (band_value > 0);
#else
   // MQL5でのCopyBuffer使用
   int bb_handle = iBands(_Symbol, FilterTimeframe, FilterPeriod, 0, BollingerDeviation, 
                          BollingerAppliedPrice);
   if(bb_handle == INVALID_HANDLE)
      return false;
      
   int buffer_index;
   if(target == BAND_UPPER)
      buffer_index = 1;
   else if(target == BAND_LOWER)
      buffer_index = 2;
   else // BAND_MIDDLE
      buffer_index = 0;
      
   double buffer[1];
   if(CopyBuffer(bb_handle, buffer_index, shift, 1, buffer) <= 0)
      return false;
      
   band_value = buffer[0];
   return true;
#endif
}

//+------------------------------------------------------------------+
//| バンド条件の評価                                                |
//+------------------------------------------------------------------+
bool EvaluateBandCondition(double price_current, double band_current, double price_previous, double band_previous, ENUM_BAND_CONDITION condition)
{
   switch(condition)
   {
      case BAND_PRICE_ABOVE:
         return (price_current > band_current);
         
      case BAND_PRICE_BELOW:
         return (price_current < band_current);
         
      case BAND_CROSS_DOWN:
         // 前の足で価格がバンドより上、現在の足で価格がバンドより下
         return (price_previous > band_previous && price_current < band_current);
         
      case BAND_CROSS_UP:
         // 前の足で価格がバンドより下、現在の足で価格がバンドより上
         return (price_previous < band_previous && price_current > band_current);
   }
   
   return false;
}

//+------------------------------------------------------------------+
//| 指定されたシフトの終値を取得                                     |
//+------------------------------------------------------------------+
double GetClosePrice(int shift)
{
#ifdef __MQL4__
   return iClose(_Symbol, FilterTimeframe, shift);
#else
   double close_array[1];
   if(CopyClose(_Symbol, FilterTimeframe, shift, 1, close_array) <= 0)
      return 0;
   return close_array[0];
#endif
}

//+------------------------------------------------------------------+
//| 常時エントリー戦略の判定                                         |
//+------------------------------------------------------------------+
bool CheckConstantEntryStrategy(int side)
{
   // 戦略が無効の場合はすぐに false を返す
   if(ConstantEntryStrategy == CONSTANT_ENTRY_DISABLED)
      return false;

   // 現在時刻の取得
   datetime currentTime = TimeCurrent();

   // 前回エントリー時間の取得
   datetime lastEntryTime = (side == 0) ? g_LastConstantLongEntryTime : g_LastConstantShortEntryTime;

   // エントリー間隔チェック
   if(ConstantEntryInterval > 0)
   {
      // 指定された間隔が経過していなければfalse
      if(currentTime - lastEntryTime < ConstantEntryInterval * 60)
      {
         return false;
      }
   }

   // 戦略タイプに基づいてエントリー判断
   if(side == 0)  // ロング（Buy）
   {
      if(ConstantEntryStrategy == CONSTANT_ENTRY_LONG || ConstantEntryStrategy == CONSTANT_ENTRY_BOTH)
      {
         // エントリー時間更新
         g_LastConstantLongEntryTime = currentTime;
         return true;
      }
   }
   else  // ショート（Sell）
   {
      if(ConstantEntryStrategy == CONSTANT_ENTRY_SHORT || ConstantEntryStrategy == CONSTANT_ENTRY_BOTH)
      {
         // エントリー時間更新
         g_LastConstantShortEntryTime = currentTime;
         return true;
      }
   }

   return false;
}

//+------------------------------------------------------------------+
//| 常時エントリー戦略の状態をテキストで取得                          |
//+------------------------------------------------------------------+
string GetConstantEntryStrategyState()
{
   if(ConstantEntryStrategy == CONSTANT_ENTRY_DISABLED)
      return "無効";

   string state = "";

   switch(ConstantEntryStrategy)
   {
      case CONSTANT_ENTRY_LONG:
         state = "常時ロングエントリー";
         break;
      case CONSTANT_ENTRY_SHORT:
         state = "常時ショートエントリー";
         break;
      case CONSTANT_ENTRY_BOTH:
         state = "常時ロング＆ショート両方";
         break;
      default:
         state = "不明";
   }

   if(ConstantEntryInterval > 0)
      state += " (間隔: " + IntegerToString(ConstantEntryInterval) + "分)";
   else
      state += " (間隔制限なし)";

   return state;
}

//+------------------------------------------------------------------+
//| 常時エントリー戦略が有効かどうかを判定                           |
//+------------------------------------------------------------------+
bool IsConstantEntryEnabled()
{
   return ConstantEntryStrategy != CONSTANT_ENTRY_DISABLED;
}

//+------------------------------------------------------------------+
//| 常時エントリー戦略でBuy側が有効かチェック                         |
//+------------------------------------------------------------------+
bool IsConstantEntryBuyEnabled()
{
   return (ConstantEntryStrategy == CONSTANT_ENTRY_LONG || 
           ConstantEntryStrategy == CONSTANT_ENTRY_BOTH);
}

//+------------------------------------------------------------------+
//| 常時エントリー戦略でSell側が有効かチェック                        |
//+------------------------------------------------------------------+
bool IsConstantEntrySellEnabled()
{
   return (ConstantEntryStrategy == CONSTANT_ENTRY_SHORT || 
           ConstantEntryStrategy == CONSTANT_ENTRY_BOTH);
}

//+------------------------------------------------------------------+
//| 全インジケーターの評価関数                                       |
//+------------------------------------------------------------------+
bool EvaluateIndicatorsForEntry(int side)
{
   // エントリーモードの確認を追加
   bool modeAllowed = false;
   if(side == 0) // Buy
      modeAllowed = (EntryMode == MODE_BUY_ONLY || EntryMode == MODE_BOTH);
   else // Sell
      modeAllowed = (EntryMode == MODE_SELL_ONLY || EntryMode == MODE_BOTH);
   
   if(!modeAllowed) {
      return false;
   }

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

   // エントリーモードのチェック結果も加味
   bool finalResult = strategySignals && modeAllowed;
   Print("【最終判断】 エントリーモード考慮の結果: ", finalResult ? "成立" : "不成立");
   return finalResult;
}

//+------------------------------------------------------------------+
//| EvaluateStrategyForEntry関数 - 常時エントリー戦略追加版            |
//+------------------------------------------------------------------+
bool EvaluateStrategyForEntry(int side)
{
   // side: 0 = Buy, 1 = Sell
   bool entrySignal = false;

   // 【セクション: インジケーター評価】
   bool strategySignals = false;
   int enabledStrategies = 0;
   int validSignals = 0;

   // 【セクション: 有効な戦略名収集】
   string activeStrategies = "";

   // 【セクション: 常時エントリー戦略チェック】
   bool constantEntrySignal = false;
   if(ConstantEntryStrategy != CONSTANT_ENTRY_DISABLED)
   {
      enabledStrategies++;
      if(CheckConstantEntryStrategy(side))
      {
         validSignals++;
         constantEntrySignal = true;
         if(activeStrategies != "")
            activeStrategies += ", ";
         activeStrategies += "常時エントリー";
      }
   }

   // 各インジケーターのシグナルチェック
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

   // 常時エントリー戦略が有効で条件が成立している場合は、他のインジケーターに関係なくtrueを返す
   if(constantEntrySignal)
   {
      indicatorSignalsValid = true;
   }
   // 常時エントリー以外のインジケーターがある場合
   else if(enabledStrategies > (ConstantEntryStrategy != CONSTANT_ENTRY_DISABLED ? 1 : 0))
   {
      if(Indicator_Condition_Type == AND_CONDITION)
      {
         // AND条件: 常時エントリーを除くすべての有効なインジケーターがシグナルを出した場合のみtrue
         int requiredSignals = enabledStrategies;
         if(ConstantEntryStrategy != CONSTANT_ENTRY_DISABLED) requiredSignals--;
         
         indicatorSignalsValid = (validSignals >= requiredSignals);
      }
      else
      {
         // OR条件: 少なくとも1つのインジケーターがシグナルを出した場合にtrue
         indicatorSignalsValid = (validSignals > 0);
      }
   }

   // 【セクション: 最終判断】
   // インジケーター条件がOKかチェック
   bool needIndicators = (enabledStrategies > 0);

   // インジケーター条件が設定されている場合
   if(needIndicators)
   {
      entrySignal = indicatorSignalsValid;
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
      
      // 常時エントリーが成立した場合
      if(constantEntrySignal)
      {
         reason = "常時エントリー戦略";
      }
      // その他のインジケーターによるエントリーの場合
      else
      {
         string conditionType = (Indicator_Condition_Type == AND_CONDITION) ? "AND条件" : "OR条件";
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
//| GetStrategyDetails関数 - 常時エントリー戦略対応                    |
//+------------------------------------------------------------------+
string GetStrategyDetails(int side)
{
   // side: 0 = Buy, 1 = Sell
   string typeStr = (side == 0) ? "Buy" : "Sell";
   string strategyDetails = "【" + typeStr + " 戦略シグナル詳細】\n";

   // 【セクション: ポジション保護】
   strategyDetails += "【ポジション保護】: " + GetProtectionModeText() + "\n";

   // 【セクション: 常時エントリー】
   if(ConstantEntryStrategy != CONSTANT_ENTRY_DISABLED)
   {
      bool constantSignal = CheckConstantEntryStrategy(side);
      
      // 前回のエントリー時間を取得
      datetime lastEntryTime = (side == 0) ? g_LastConstantLongEntryTime : g_LastConstantShortEntryTime;
      string lastEntryTimeStr = (lastEntryTime > 0) ? 
                               TimeToString(lastEntryTime, TIME_DATE|TIME_MINUTES) : 
                               "なし";
      
      // インターバル情報
      string intervalInfo = "";
      if(ConstantEntryInterval > 0)
      {
         datetime nextEntryTime = lastEntryTime + ConstantEntryInterval * 60;
         intervalInfo = ", 次回可能時間: " + TimeToString(nextEntryTime, TIME_DATE|TIME_MINUTES);
      }

      strategyDetails += "【常時エントリー】: " + (constantSignal ? "シグナルあり" : "シグナルなし") +
                    " (モード: " + GetConstantEntryStrategyState() + 
                    ", 前回: " + lastEntryTimeStr + intervalInfo + ")\n";
   }

   // 【セクション: MAクロス】
   if(MA_Entry_Strategy == MA_ENTRY_ENABLED)
   {
      bool maSignal = CheckMASignal(side);
      
      // MA値の取得
      double fastMA_current, slowMA_current;
      
#ifdef __MQL4__
      if(side == 0)
      {
         fastMA_current = iMA(_Symbol, MA_Timeframe, MA_Buy_Fast_Period, 0, MA_Method, MA_Price, MA_Cross_Shift);
         slowMA_current = iMA(_Symbol, MA_Timeframe, MA_Buy_Slow_Period, 0, MA_Method, MA_Price, MA_Cross_Shift);
      }
      else
      {
         fastMA_current = iMA(_Symbol, MA_Timeframe, MA_Sell_Fast_Period, 0, MA_Method, MA_Price, MA_Cross_Shift);
         slowMA_current = iMA(_Symbol, MA_Timeframe, MA_Sell_Slow_Period, 0, MA_Method, MA_Price, MA_Cross_Shift);
      }
#else
      if(side == 0)
      {
         GetIndicatorValue(g_ma_buy_fast_handle, 0, MA_Cross_Shift, fastMA_current);
         GetIndicatorValue(g_ma_buy_slow_handle, 0, MA_Cross_Shift, slowMA_current);
      }
      else
      {
         GetIndicatorValue(g_ma_sell_fast_handle, 0, MA_Cross_Shift, fastMA_current);
         GetIndicatorValue(g_ma_sell_slow_handle, 0, MA_Cross_Shift, slowMA_current);
      }
#endif

      strategyDetails += "【MAクロス】: " + (maSignal ? "シグナルあり" : "シグナルなし") +
                    " (短期MA=" + DoubleToString(fastMA_current, Digits) +
                    ", 長期MA=" + DoubleToString(slowMA_current, Digits) + ")\n";
   }

   // 【セクション: RSI】
   if(RSI_Entry_Strategy == RSI_ENTRY_ENABLED)
   {
      bool rsiSignal = CheckRSISignal(side);
      
      // RSI値の取得
      double rsi_current;
#ifdef __MQL4__
      rsi_current = iRSI(_Symbol, RSI_Timeframe, RSI_Period, RSI_Price, RSI_Signal_Shift);
#else
      GetIndicatorValue(g_rsi_handle, 0, RSI_Signal_Shift, rsi_current);
#endif
      
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
      double middle, upper, lower, close;
#ifdef __MQL4__
      middle = iBands(_Symbol, BB_Timeframe, BB_Period, BB_Deviation, 0, BB_Price, MODE_MAIN, BB_Signal_Shift);
      upper = iBands(_Symbol, BB_Timeframe, BB_Period, BB_Deviation, 0, BB_Price, MODE_UPPER, BB_Signal_Shift);
      lower = iBands(_Symbol, BB_Timeframe, BB_Period, BB_Deviation, 0, BB_Price, MODE_LOWER, BB_Signal_Shift);
      close = iClose(_Symbol, BB_Timeframe, BB_Signal_Shift);
#else
      GetIndicatorValue(g_bb_handle, 0, BB_Signal_Shift, middle);
      GetIndicatorValue(g_bb_handle, 1, BB_Signal_Shift, upper);
      GetIndicatorValue(g_bb_handle, 2, BB_Signal_Shift, lower);
      double prices[];
      ArraySetAsSeries(prices, true);
      CopyClose(_Symbol, BB_Timeframe, BB_Signal_Shift, 1, prices);
      close = prices[0];
#endif
      
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
      double k_current, d_current;
#ifdef __MQL4__
      k_current = iStochastic(_Symbol, Stoch_Timeframe, Stoch_K_Period, Stoch_D_Period,
                             Stoch_Slowing, Stoch_Method, Stoch_Price_Field,
                             MODE_MAIN, Stoch_Signal_Shift);
      d_current = iStochastic(_Symbol, Stoch_Timeframe, Stoch_K_Period, Stoch_D_Period,
                             Stoch_Slowing, Stoch_Method, Stoch_Price_Field,
                             MODE_SIGNAL, Stoch_Signal_Shift);
#else
      GetIndicatorValue(g_stoch_handle, 0, Stoch_Signal_Shift, k_current);
      GetIndicatorValue(g_stoch_handle, 1, Stoch_Signal_Shift, d_current);
#endif
      
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
      double cci_current;
#ifdef __MQL4__
      cci_current = iCCI(_Symbol, CCI_Timeframe, CCI_Period, CCI_Price, CCI_Signal_Shift);
#else
      GetIndicatorValue(g_cci_handle, 0, CCI_Signal_Shift, cci_current);
#endif
      
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
      double adx, plus_di, minus_di;
#ifdef __MQL4__
      adx = iADX(_Symbol, ADX_Timeframe, ADX_Period, PRICE_CLOSE, MODE_MAIN, ADX_Signal_Shift);
      plus_di = iADX(_Symbol, ADX_Timeframe, ADX_Period, PRICE_CLOSE, MODE_PLUSDI, ADX_Signal_Shift);
      minus_di = iADX(_Symbol, ADX_Timeframe, ADX_Period, PRICE_CLOSE, MODE_MINUSDI, ADX_Signal_Shift);
#else
      GetIndicatorValue(g_adx_handle, 0, ADX_Signal_Shift, adx);
      GetIndicatorValue(g_adx_handle, 1, ADX_Signal_Shift, plus_di);
      GetIndicatorValue(g_adx_handle, 2, ADX_Signal_Shift, minus_di);
#endif
      
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
#ifdef __MQL4__
      int current_hour = TimeHour(current_time);
#else
      MqlDateTime dt;
      TimeToStruct(current_time, dt);
      int current_hour = dt.hour;
#endif
      bool is_even_hour = (current_hour % 2 == 0);
      
      strategyDetails += "【偶数/奇数時間】: " + (evenOddSignal ? "シグナルあり" : "シグナルなし") +
                    " (現在時間=" + IntegerToString(current_hour) + "時" +
                    ", " + (is_even_hour ? "偶数時間" : "奇数時間") + 
                    ", モード=" + GetEvenOddStrategyState() + ")\n";
   }

   return strategyDetails;
}

//+------------------------------------------------------------------+
//| ProcessStrategyLogic関数                                        |
//+------------------------------------------------------------------+
void ProcessStrategyLogic()
{
   // バックテスト時のログ出力を最小限にする
   bool isTesting = IsTesting();
   
   // 【セクション: 自動売買チェック】
   if(!EnableAutomaticTrading)
   {
      if(!isTesting) Print("【自動売買チェック】: 自動売買が無効のためスキップします");
      return;
   }

   // 【セクション: 最終損切りチェック】
   CheckFinalStopLoss();

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

   // 【セクション: 常時エントリー戦略チェック】
   bool isConstantEntryActive = IsConstantEntryEnabled();

   // 【セクション: 既存ポジションの管理】
   if((hasRealBuy || hasRealSell) && !isConstantEntryActive)  // 常時エントリーの場合は除外
   {
      // ナンピン機能が有効な場合のみナンピン条件をチェック
      if(EnableNanpin)
      {
         // リアルポジションのナンピン条件をチェック
         CheckNanpinConditions(0); // Buy側のナンピン条件チェック
         CheckNanpinConditions(1); // Sell側のナンピン条件チェック
      }
   }
   else
   {
      // 【セクション: 偶数/奇数時間戦略チェック】
      if(EvenOdd_Entry_Strategy != EVEN_ODD_DISABLED)
      {
         g_UseEvenOddHoursEntry = true;
      }
      else
      {
         g_UseEvenOddHoursEntry = false;
      }

      // 常時エントリー戦略の場合は、各方向個別にチェック
      if(isConstantEntryActive)
      {
         // Buy側のエントリー処理（既存ポジションがあってもチェック）
         if((EntryMode == MODE_BUY_ONLY || EntryMode == MODE_BOTH) && !hasRealBuy)
         {
            if(useGhostMode && EnableGhostEntry)
            {
               ProcessGhostEntries(0); // Buy側
            }
            else
            {
               ProcessRealEntries(0); // Buy側
            }
         }

         // Sell側のエントリー処理（既存ポジションがあってもチェック）
         if((EntryMode == MODE_SELL_ONLY || EntryMode == MODE_BOTH) && !hasRealSell)
         {
            if(useGhostMode && EnableGhostEntry)
            {
               ProcessGhostEntries(1); // Sell側
            }
            else
            {
               ProcessRealEntries(1); // Sell側
            }
         }
         
         // ナンピン処理も行う
         if(EnableNanpin)
         {
            if(hasRealBuy) CheckNanpinConditions(0);
            if(hasRealSell) CheckNanpinConditions(1);
         }
      }
      else
      {
         // 通常のエントリー処理（既存のコード）
         // ゴーストモードがONの場合
         if(useGhostMode && EnableGhostEntry)
         {
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
}

//+------------------------------------------------------------------+
//| 戦略評価 - ProcessGhostEntries関数用のインターフェース            |
//+------------------------------------------------------------------+
bool ShouldProcessGhostEntry(int side)
{
   // ProcessGhostEntries関数から呼び出されるエントリー評価関数
   return EvaluateStrategyForEntry(side);
}

bool ShouldProcessRealEntry(int side)
{
   // ProcessRealEntries関数から呼び出されるエントリー評価関数
   bool result = EvaluateStrategyForEntry(side);
   
   // エントリーモードとの整合性を確保する追加チェック
   bool modeAllowed = false;
   if(side == 0) // Buy
      modeAllowed = (EntryMode == MODE_BUY_ONLY || EntryMode == MODE_BOTH);
   else // Sell
      modeAllowed = (EntryMode == MODE_SELL_ONLY || EntryMode == MODE_BOTH);
   
   // 両方の条件が満たされた場合のみtrueを返す
   return result && modeAllowed;
}

bool CheckIndicatorSignals(int side)
{
   // エントリーモードチェック (追加)
   bool modeAllowed = false;
   if(side == 0) // Buy
      modeAllowed = (EntryMode == MODE_BUY_ONLY || EntryMode == MODE_BOTH);
   else // Sell
      modeAllowed = (EntryMode == MODE_SELL_ONLY || EntryMode == MODE_BOTH);
      
   if(!modeAllowed) {
      // デバッグログは出さない（頻繁にチェックされるため）
      return false;
   }

   // どれか1つでもシグナルがあればtrue
   return (ConstantEntryStrategy != CONSTANT_ENTRY_DISABLED && CheckConstantEntryStrategy(side)) ||
          (MA_Entry_Strategy == MA_ENTRY_ENABLED && CheckMASignal(side)) ||
          (RSI_Entry_Strategy == RSI_ENTRY_ENABLED && CheckRSISignal(side)) ||
          (BB_Entry_Strategy == BB_ENTRY_ENABLED && CheckBollingerSignal(side)) ||
          (RCI_Entry_Strategy == RCI_ENTRY_ENABLED && CheckRCISignal(side)) ||
          (Stoch_Entry_Strategy == STOCH_ENTRY_ENABLED && CheckStochasticSignal(side)) ||
          (CCI_Entry_Strategy == CCI_ENTRY_ENABLED && CheckCCISignal(side)) ||
          (ADX_Entry_Strategy == ADX_ENTRY_ENABLED && CheckADXSignal(side)) ||
          (EvenOdd_Entry_Strategy != EVEN_ODD_DISABLED && CheckEvenOddStrategy(side));
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

#ifdef __MQL4__
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
#else
   // MQL5では動的にハンドルを作成して値を取得
   int handle = INVALID_HANDLE;
   
   switch(indicator_type)
   {
      // 移動平均
      case INDICATOR_MA:
         handle = iMA(symbol, timeframe, period, 0, MODE_SMA, price_type);
         break;

      // RSI
      case INDICATOR_RSI:
         handle = iRSI(symbol, timeframe, period, price_type);
         break;

      // ボリンジャーバンド
      case INDICATOR_BOLLINGER:
         handle = iBands(symbol, timeframe, period, 0, deviation, price_type);
         break;

      // ストキャスティクス
      case INDICATOR_STOCHASTIC:
         handle = iStochastic(symbol, timeframe, period, 3, 3, MODE_SMA, STO_LOWHIGH);
         break;

      // CCI
      case INDICATOR_CCI:
         handle = iCCI(symbol, timeframe, period, price_type);
         break;

      // ADX
      case INDICATOR_ADX:
         handle = iADX(symbol, timeframe, period);
         break;
   }
   
   if(handle != INVALID_HANDLE)
   {
      double buffer[];
      ArraySetAsSeries(buffer, true);
      
      // ボリンジャーバンドの場合はバッファインデックスを調整
      int buffer_index = 0;
      if(indicator_type == INDICATOR_BOLLINGER)
      {
         if(mode == MODE_UPPER) buffer_index = 1;
         else if(mode == MODE_LOWER) buffer_index = 2;
      }
      // ストキャスティクスの場合
      else if(indicator_type == INDICATOR_STOCHASTIC)
      {
         if(mode == MODE_SIGNAL) buffer_index = 1;
      }
      // ADXの場合
      else if(indicator_type == INDICATOR_ADX)
      {
         if(mode == MODE_PLUSDI) buffer_index = 1;
         else if(mode == MODE_MINUSDI) buffer_index = 2;
      }
      
      if(CopyBuffer(handle, buffer_index, shift, 1, buffer) > 0)
      {
         value = buffer[0];
      }
      
      // ハンドルを解放
      IndicatorRelease(handle);
   }
#endif

   return value;
}

//+------------------------------------------------------------------+
//| 最終損切りチェック関数                                            |
//+------------------------------------------------------------------+
void CheckFinalStopLoss()
{
   if(FinalStopLossPoints <= 0) return; // 最終損切りが無効の場合は何もしない
   
   // Buy側ポジションの損切りチェック
   if(position_count(OP_BUY) > 0)
   {
      double avgPrice = CalculateRealAveragePrice(OP_BUY);
      if(avgPrice > 0)
      {
         double currentPrice = GetBidPrice();
         double lossPips = (avgPrice - currentPrice) / GetPoint();
         
         if(lossPips >= FinalStopLossPoints)
         {
            position_close(OP_BUY, 0.0, 10, MagicNumber);
            Print("最終損切り実行: Buy側ポジション全決済 (損失: ", lossPips, " points)");
         }
      }
   }
   
   // Sell側ポジションの損切りチェック
   if(position_count(OP_SELL) > 0)
   {
      double avgPrice = CalculateRealAveragePrice(OP_SELL);
      if(avgPrice > 0)
      {
         double currentPrice = GetAskPrice();
         double lossPips = (currentPrice - avgPrice) / GetPoint();
         
         if(lossPips >= FinalStopLossPoints)
         {
            position_close(OP_SELL, 0.0, 10, MagicNumber);
            Print("最終損切り実行: Sell側ポジション全決済 (損失: ", lossPips, " points)");
         }
      }
   }
}

//+------------------------------------------------------------------+