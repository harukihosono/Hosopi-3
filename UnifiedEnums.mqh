//+------------------------------------------------------------------+
//|                    UnifiedEnums.mqh                              |
//|              MQL4/MQL5 統合列挙型定義                            |
//+------------------------------------------------------------------+

// 統合ポジションタイプ
#ifdef MQL4_PLATFORM
    #define UNIFIED_POSITION_BUY    OP_BUY
    #define UNIFIED_POSITION_SELL   OP_SELL
#else
    #define UNIFIED_POSITION_BUY    POSITION_TYPE_BUY
    #define UNIFIED_POSITION_SELL   POSITION_TYPE_SELL
#endif

// 統合注文タイプ
enum ENUM_UNIFIED_ORDER_TYPE
{
    UNIFIED_ORDER_BUY = 0,
    UNIFIED_ORDER_SELL = 1,
    UNIFIED_ORDER_BUY_LIMIT = 2,
    UNIFIED_ORDER_SELL_LIMIT = 3,
    UNIFIED_ORDER_BUY_STOP = 4,
    UNIFIED_ORDER_SELL_STOP = 5
};