//+------------------------------------------------------------------+
//|                   Hosopi 3 - 列挙型定義ファイル                   |
//|                              Copyright 2025                      |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025"
#property link      ""
#property strict

#ifndef HOSOPI3_ENUMS_MQH
#define HOSOPI3_ENUMS_MQH

//+------------------------------------------------------------------+
//|                         列挙型定義                               |
//+------------------------------------------------------------------+

// フィルタータイプの列挙型
enum FILTER_TYPE
{
   FILTER_NONE = 0,        // フィルターなし
   FILTER_ENVELOPE = 1,    // エンベロープ
   FILTER_BOLLINGER = 2    // ボリンジャーバンド
};

//+------------------------------------------------------------------+
//|                  テクニカル戦略関連のenum定義                     |
//+------------------------------------------------------------------+

// EVEN_ODD_STRATEGY_TYPE は Hosopi3_Defines.mqh の EVEN_ODD_STRATEGY を使用

// 各テクニカル指標のエントリータイプ定義
enum MA_ENTRY_TYPE
{
   MA_ENTRY_DISABLED = 0,     // 無効
   MA_ENTRY_ENABLED = 1       // 有効
};

enum RSI_ENTRY_TYPE
{
   RSI_ENTRY_DISABLED = 0,    // 無効
   RSI_ENTRY_ENABLED = 1      // 有効
};

enum BOLLINGER_ENTRY_TYPE
{
   BB_ENTRY_DISABLED = 0,     // 無効
   BB_ENTRY_ENABLED = 1       // 有効
};

enum RCI_ENTRY_TYPE
{
   RCI_ENTRY_DISABLED = 0,    // 無効
   RCI_ENTRY_ENABLED = 1      // 有効
};

enum STOCH_ENTRY_TYPE
{
   STOCH_ENTRY_DISABLED = 0,  // 無効
   STOCH_ENTRY_ENABLED = 1    // 有効
};

enum CCI_ENTRY_TYPE
{
   CCI_ENTRY_DISABLED = 0,    // 無効
   CCI_ENTRY_ENABLED = 1      // 有効
};

enum ADX_ENTRY_TYPE
{
   ADX_ENTRY_DISABLED = 0,    // 無効
   ADX_ENTRY_ENABLED = 1      // 有効
};

// 戦略方向定義
enum STRATEGY_DIRECTION
{
   TREND_FOLLOWING = 0,       // 順張り（トレンドフォロー）
   COUNTER_TREND = 1          // 逆張り（カウンタートレンド）
};

// MA戦略タイプ定義
enum MA_STRATEGY_TYPE
{
   MA_GOLDEN_CROSS = 1,       // ゴールデンクロス
   MA_DEAD_CROSS = 2,         // デッドクロス
   MA_PRICE_ABOVE_MA = 3,     // 価格がMA上抜け
   MA_PRICE_BELOW_MA = 4,     // 価格がMA下抜け
   MA_FAST_ABOVE_SLOW = 5,    // 短期MAが長期MA上
   MA_FAST_BELOW_SLOW = 6     // 短期MAが長期MA下
};

// RSI戦略タイプ定義
enum RSI_STRATEGY_TYPE
{
   RSI_OVERSOLD = 1,          // 売られすぎレベル
   RSI_OVERSOLD_EXIT = 2,     // 売られすぎから回復
   RSI_OVERBOUGHT = 3,        // 買われすぎレベル
   RSI_OVERBOUGHT_EXIT = 4    // 買われすぎから下落
};

// ボリンジャーバンド戦略タイプ定義
enum BB_STRATEGY_TYPE
{
   BB_TOUCH_LOWER = 1,        // 下限バンドタッチ
   BB_BREAK_LOWER = 2,        // 下限バンド突破
   BB_TOUCH_UPPER = 3,        // 上限バンドタッチ
   BB_BREAK_UPPER = 4         // 上限バンド突破
};

// RCI戦略タイプ定義
enum RCI_STRATEGY_TYPE
{
   RCI_BELOW_MINUS_THRESHOLD = 1,    // -しきい値以下
   RCI_RISING_FROM_BOTTOM = 2,       // -しきい値から上昇
   RCI_ABOVE_PLUS_THRESHOLD = 3,     // +しきい値以上
   RCI_FALLING_FROM_PEAK = 4         // +しきい値から下落
};

// ストキャスティクス戦略タイプ定義
enum STOCH_STRATEGY_TYPE
{
   STOCH_OVERSOLD = 1,                  // 売られすぎレベル
   STOCH_K_CROSS_D_OVERSOLD = 2,        // %Kが%Dを上抜け（売られすぎ圏）
   STOCH_OVERSOLD_EXIT = 3,             // 売られすぎ圏から脱出
   STOCH_OVERBOUGHT = 4,                // 買われすぎレベル
   STOCH_K_CROSS_D_OVERBOUGHT = 5,      // %Kが%Dを下抜け（買われすぎ圏）
   STOCH_OVERBOUGHT_EXIT = 6            // 買われすぎ圏から脱出
};

// テクニカル指標エントリー条件定義
enum STRATEGY_ENTRY_CONDITION
{
   STRATEGY_NO_SAME_DIRECTION = 0,    // 同方向ポジションがない場合のみ
   STRATEGY_NO_POSITIONS = 1,         // ポジションが全くない場合のみ
   STRATEGY_ALWAYS_ALLOW = 2,         // 常にエントリー許可（追加・両建て可）
   STRATEGY_DIFFERENT_CANDLE = 3,     // 異なるローソク足でのみエントリー
   STRATEGY_CONSTANT_ENTRY = 4        // 常時エントリー戦略
};

// CCI戦略タイプ定義
enum CCI_STRATEGY_TYPE
{
   CCI_OVERSOLD = 1,          // 売られすぎレベル
   CCI_OVERSOLD_EXIT = 2,     // 売られすぎから回復
   CCI_OVERBOUGHT = 3,        // 買われすぎレベル
   CCI_OVERBOUGHT_EXIT = 4    // 買われすぎから下落
};

// ADX戦略タイプ定義
enum ADX_STRATEGY_TYPE
{
   ADX_PLUS_DI_CROSS_MINUS_DI = 1,      // +DIが-DIを上抜け
   ADX_STRONG_TREND_PLUS_DI = 2,        // 強いトレンドで+DI > -DI
   ADX_MINUS_DI_CROSS_PLUS_DI = 3,      // -DIが+DIを上抜け
   ADX_STRONG_TREND_MINUS_DI = 4        // 強いトレンドで-DI > +DI
};

// 条件判定タイプ
enum CONDITION_TYPE
{
   OR_CONDITION = 0,          // いずれかの条件が成立（OR条件）
   AND_CONDITION = 1          // すべての条件が成立（AND条件）
};

// 常時エントリー戦略タイプ定義
enum CONSTANT_ENTRY_STRATEGY_TYPE
{
   CONSTANT_ENTRY_DISABLED = 0,     // 無効
   CONSTANT_ENTRY_LONG = 1,         // 常時ロングエントリー
   CONSTANT_ENTRY_SHORT = 2,        // 常時ショートエントリー
   CONSTANT_ENTRY_BOTH = 3          // 常時ロング＆ショート両方
};

// ポジション保護機能の定義
enum POSITION_PROTECTION_MODE
{
   PROTECTION_OFF = 0,     // 両建て許可
   PROTECTION_ON = 1       // 単方向のみ許可
};

// 平均取得単価計算方法の列挙型
enum AVG_PRICE_CALCULATION_MODE
{
   REAL_POSITIONS_ONLY = 0,    // リアルポジションのみ
   REAL_AND_GHOST = 1          // リアルとゴースト両方
};

// 利確機能は bool型の EnableTakeProfit で制御

// レイアウトパターンの列挙型
enum LAYOUT_PATTERN
{
   LAYOUT_DEFAULT = 0,       // デフォルト (パネル上/テーブル下)
   LAYOUT_SIDE_BY_SIDE = 1,  // 横並び (パネル左/テーブル右)  
   LAYOUT_TABLE_TOP = 2,     // テーブル優先 (テーブル上/パネル下)
   LAYOUT_COMPACT = 3,       // コンパクト (小さいパネル)
   LAYOUT_CUSTOM = 4         // カスタム (位置を個別指定)
};

#endif // HOSOPI3_ENUMS_MQH