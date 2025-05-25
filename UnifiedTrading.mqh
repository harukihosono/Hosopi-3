//+------------------------------------------------------------------+
//|                      Unified_Trading.mqh                         |
//|           MQL4/MQL5 統合トレーディングライブラリ                  |
//|                     Copyright 2025                               |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025"
#property version   "1.00"

//+------------------------------------------------------------------+
//| プラットフォーム検出                                             |
//+------------------------------------------------------------------+
#ifdef __MQL5__
    #include <Trade\Trade.mqh>
    #include <Trade\SymbolInfo.mqh>
    #include <Trade\PositionInfo.mqh>
    #include <Trade\OrderInfo.mqh>
#endif

//+------------------------------------------------------------------+
//| 統合列挙型定義（MQL4/MQL5共通）                                  |
//+------------------------------------------------------------------+
// MQL4用の列挙型定義（MQL5との互換性のため）
#ifdef __MQL4__

enum ENUM_POSITION_TYPE
{
    POSITION_TYPE_BUY = 0,
    POSITION_TYPE_SELL = 1
};

enum ENUM_POSITION_PROPERTY_DOUBLE
{
    POSITION_VOLUME = 0,
    POSITION_PRICE_OPEN = 1,
    POSITION_SL = 2,
    POSITION_TP = 3,
    POSITION_PRICE_CURRENT = 4,
    POSITION_SWAP = 5,
    POSITION_PROFIT = 6
};

enum ENUM_POSITION_PROPERTY_INTEGER
{
    POSITION_TICKET = 0,
    POSITION_TIME = 1,
    POSITION_TYPE = 5,
    POSITION_MAGIC = 6
};

enum ENUM_POSITION_PROPERTY_STRING
{
    POSITION_SYMBOL = 0,
    POSITION_COMMENT = 1
};

enum ENUM_ORDER_TYPE_FILLING
{
    ORDER_FILLING_FOK = 0,
    ORDER_FILLING_IOC = 1,
    ORDER_FILLING_RETURN = 2
};

#endif // __MQL4__

//+------------------------------------------------------------------+
//| グローバル変数とキャッシュ                                        |
//+------------------------------------------------------------------+
// キャッシュシステム（Hosopi3から）
bool g_EquitySufficientCache = true;
datetime g_LastEquityCheckTime = 0;
bool g_TimeAllowedCache[2] = {true, true};
datetime g_LastTimeAllowedCheckTime[2] = {0, 0};

// 平均価格キャッシュ（ELDRAから）
double g_lastBuyAvgPrice = 0;
double g_lastSellAvgPrice = 0;
datetime g_lastAvgPriceUpdate = 0;

// 取引設定
input int MagicNumber = 12345;                    // マジックナンバー
input int Slippage = 3;                          // スリッページ
input ENUM_ORDER_TYPE_FILLING OrderTypeFilling = ORDER_FILLING_IOC; // 注文執行タイプ

//+------------------------------------------------------------------+
//| 統合トレーディングクラス                                         |
//+------------------------------------------------------------------+
class CUnifiedTrading
{
private:
    int     m_magic;
    string  m_symbol;
    int     m_slippage;
    ENUM_ORDER_TYPE_FILLING m_filling_type;
    
    // キャッシュ管理
    void    UpdateCaches();
    
public:
    // コンストラクタ/デストラクタ
    CUnifiedTrading();
    ~CUnifiedTrading();
    
    // 初期化
    void    Init(int magic, string symbol, int slippage, ENUM_ORDER_TYPE_FILLING filling);
    
    // ポジション管理（統合インターフェース）
    bool    OpenPosition(ENUM_POSITION_TYPE type, double lots, double sl = 0, double tp = 0, string comment = "");
    bool    OpenPositionAsync(ENUM_POSITION_TYPE type, double lots, double sl = 0, double tp = 0, string comment = "");
    bool    ClosePosition(ENUM_POSITION_TYPE type, double lots = 0);
    bool    CloseAllPositions();
    void    ClosePositionPartial(ENUM_POSITION_TYPE side, double volumeToClose);
    void    CloseOldestPosition(ENUM_POSITION_TYPE side);
    
    // ポジション情報
    int     PositionCount(ENUM_POSITION_TYPE type);
    double  GetAveragePrice(ENUM_POSITION_TYPE type);
    double  GetFirstEntryPrice(ENUM_POSITION_TYPE type);
    double  GetLastEntryPrice(ENUM_POSITION_TYPE type);
    double  GetMaxLotSize(ENUM_POSITION_TYPE type);
    double  GetTotalLots(ENUM_POSITION_TYPE type);
    double  GetTotalProfit(ENUM_POSITION_TYPE type);
    
    // 価格取得（統合）
    double  GetAskPrice();
    double  GetBidPrice();
    double  GetCurrentPrice(ENUM_POSITION_TYPE type);
    
    // ロット管理
    double  NormalizeLot(double lot);
    double  CalculateLotSize(int method, double param1 = 0, double param2 = 0);
    
    // ユーティリティ
    bool    IsTradeAllowed();
    bool    IsMarketOpen();
    double  GetPoint();
    int     GetDigits();
    double  GetSpread();
    
    // アカウント情報
    double  GetAccountBalance();
    double  GetAccountEquity();
    double  GetAccountFreeMargin();
    
    // 保留注文
    bool    PlacePendingOrder(int orderType, double price, double lots, double sl = 0, double tp = 0, string comment = "");
    void    DeleteAllPendingOrders();
    int     GetPendingOrdersCount();
};

//+------------------------------------------------------------------+
//| コンストラクタ                                                   |
//+------------------------------------------------------------------+
CUnifiedTrading::CUnifiedTrading()
{
    m_magic = 0;
    m_symbol = "";
    m_slippage = 3;
    m_filling_type = ORDER_FILLING_IOC;
}

//+------------------------------------------------------------------+
//| デストラクタ                                                     |
//+------------------------------------------------------------------+
CUnifiedTrading::~CUnifiedTrading()
{
}

//+------------------------------------------------------------------+
//| 初期化                                                          |
//+------------------------------------------------------------------+
void CUnifiedTrading::Init(int magic, string symbol, int slippage, ENUM_ORDER_TYPE_FILLING filling)
{
    m_magic = magic;
    m_symbol = (symbol == NULL || symbol == "") ? Symbol() : symbol;
    m_slippage = slippage;
    m_filling_type = filling;
}

//+------------------------------------------------------------------+
//| Ask価格取得                                                      |
//+------------------------------------------------------------------+
double CUnifiedTrading::GetAskPrice()
{
#ifdef __MQL5__
    MqlTick tick;
    if(SymbolInfoTick(m_symbol, tick))
        return tick.ask;
    return 0;
#else
    return MarketInfo(m_symbol, MODE_ASK);
#endif
}

//+------------------------------------------------------------------+
//| Bid価格取得                                                      |
//+------------------------------------------------------------------+
double CUnifiedTrading::GetBidPrice()
{
#ifdef __MQL5__
    MqlTick tick;
    if(SymbolInfoTick(m_symbol, tick))
        return tick.bid;
    return 0;
#else
    return MarketInfo(m_symbol, MODE_BID);
#endif
}

//+------------------------------------------------------------------+
//| 現在価格取得                                                     |
//+------------------------------------------------------------------+
double CUnifiedTrading::GetCurrentPrice(ENUM_POSITION_TYPE type)
{
    return (type == POSITION_TYPE_BUY) ? GetBidPrice() : GetAskPrice();
}

//+------------------------------------------------------------------+
//| ポジションオープン（同期）                                       |
//+------------------------------------------------------------------+
bool CUnifiedTrading::OpenPosition(ENUM_POSITION_TYPE type, double lots, double sl, double tp, string comment)
{
#ifdef __MQL5__
    MqlTradeRequest request = {};
    MqlTradeResult result = {};
    
    request.action = TRADE_ACTION_DEAL;
    request.symbol = m_symbol;
    request.volume = lots;
    request.type = (type == POSITION_TYPE_BUY) ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;
    request.price = (type == POSITION_TYPE_BUY) ? GetAskPrice() : GetBidPrice();
    request.sl = sl;
    request.tp = tp;
    request.deviation = m_slippage;
    request.magic = m_magic;
    request.comment = comment;
    request.type_filling = m_filling_type;
    
    if(!OrderSend(request, result))
    {
        Print("OrderSend error: ", GetLastError(), " RetCode: ", result.retcode);
        return false;
    }
    
    return (result.retcode == TRADE_RETCODE_DONE || result.retcode == TRADE_RETCODE_PLACED);
    
#else // MQL4
    int orderType = (type == POSITION_TYPE_BUY) ? OP_BUY : OP_SELL;
    double price = (type == POSITION_TYPE_BUY) ? GetAskPrice() : GetBidPrice();
    color arrowColor = (type == POSITION_TYPE_BUY) ? clrBlue : clrRed;
    
    int ticket = OrderSend(m_symbol, orderType, lots, price, m_slippage, sl, tp, comment, m_magic, 0, arrowColor);
    
    if(ticket < 0)
    {
        Print("OrderSend error: ", GetLastError());
        return false;
    }
    
    return true;
#endif
}

//+------------------------------------------------------------------+
//| ポジションオープン（非同期）                                     |
//+------------------------------------------------------------------+
bool CUnifiedTrading::OpenPositionAsync(ENUM_POSITION_TYPE type, double lots, double sl, double tp, string comment)
{
#ifdef __MQL5__
    MqlTradeRequest request = {};
    MqlTradeResult result = {};
    
    request.action = TRADE_ACTION_DEAL;
    request.symbol = m_symbol;
    request.volume = lots;
    request.type = (type == POSITION_TYPE_BUY) ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;
    request.price = (type == POSITION_TYPE_BUY) ? GetAskPrice() : GetBidPrice();
    request.sl = sl;
    request.tp = tp;
    request.deviation = m_slippage;
    request.magic = m_magic;
    request.comment = comment;
    request.type_filling = m_filling_type;
    
    if(!OrderSendAsync(request, result))
    {
        Print("OrderSendAsync error: ", GetLastError());
        return false;
    }
    
    return true;
    
#else // MQL4 - 非同期はサポートされないので同期処理
    return OpenPosition(type, lots, sl, tp, comment);
#endif
}

//+------------------------------------------------------------------+
//| ポジションクローズ                                               |
//+------------------------------------------------------------------+
bool CUnifiedTrading::ClosePosition(ENUM_POSITION_TYPE type, double lots)
{
    bool result = false;
    
#ifdef __MQL5__
    for(int i = PositionsTotal() - 1; i >= 0; i--)
    {
        ulong ticket = PositionGetTicket(i);
        if(PositionSelectByTicket(ticket))
        {
            if(PositionGetString(POSITION_SYMBOL) == m_symbol &&
               PositionGetInteger(POSITION_MAGIC) == m_magic &&
               PositionGetInteger(POSITION_TYPE) == type)
            {
                double volume = (lots <= 0) ? PositionGetDouble(POSITION_VOLUME) : MathMin(lots, PositionGetDouble(POSITION_VOLUME));
                
                MqlTradeRequest request = {};
                MqlTradeResult res = {};
                
                request.action = TRADE_ACTION_DEAL;
                request.position = ticket;
                request.symbol = m_symbol;
                request.volume = volume;
                request.type = (type == POSITION_TYPE_BUY) ? ORDER_TYPE_SELL : ORDER_TYPE_BUY;
                request.price = (type == POSITION_TYPE_BUY) ? GetBidPrice() : GetAskPrice();
                request.deviation = m_slippage;
                request.magic = m_magic;
                request.type_filling = m_filling_type;
                
                if(OrderSend(request, res))
                {
                    result = true;
                    if(lots > 0 && lots <= PositionGetDouble(POSITION_VOLUME))
                        break;
                }
            }
        }
    }
#else // MQL4
    for(int i = OrdersTotal() - 1; i >= 0; i--)
    {
        if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
        {
            int orderType = OrderType();
            bool typeMatch = false;
            
            if(type == POSITION_TYPE_BUY && orderType == OP_BUY)
                typeMatch = true;
            else if(type == POSITION_TYPE_SELL && orderType == OP_SELL)
                typeMatch = true;
            
            if(typeMatch && OrderSymbol() == m_symbol && OrderMagicNumber() == m_magic)
            {
                double closeVolume = (lots <= 0) ? OrderLots() : MathMin(lots, OrderLots());
                double closePrice = (type == POSITION_TYPE_BUY) ? GetBidPrice() : GetAskPrice();
                
                if(OrderClose(OrderTicket(), closeVolume, closePrice, m_slippage, clrNONE))
                {
                    result = true;
                    if(lots > 0 && lots <= OrderLots())
                        break;
                }
            }
        }
    }
#endif
    
    return result;
}

//+------------------------------------------------------------------+
//| 全ポジションクローズ                                             |
//+------------------------------------------------------------------+
bool CUnifiedTrading::CloseAllPositions()
{
    bool buyResult = ClosePosition(POSITION_TYPE_BUY);
    bool sellResult = ClosePosition(POSITION_TYPE_SELL);
    return buyResult || sellResult;
}

//+------------------------------------------------------------------+
//| ポジション数カウント                                             |
//+------------------------------------------------------------------+
int CUnifiedTrading::PositionCount(ENUM_POSITION_TYPE type)
{
    int count = 0;
    
#ifdef __MQL5__
    for(int i = PositionsTotal() - 1; i >= 0; i--)
    {
        if(PositionSelectByTicket(PositionGetTicket(i)))
        {
            if(PositionGetString(POSITION_SYMBOL) == m_symbol &&
               PositionGetInteger(POSITION_MAGIC) == m_magic &&
               PositionGetInteger(POSITION_TYPE) == type)
            {
                count++;
            }
        }
    }
#else // MQL4
    for(int i = OrdersTotal() - 1; i >= 0; i--)
    {
        if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
        {
            int orderType = OrderType();
            bool typeMatch = false;
            
            if(type == POSITION_TYPE_BUY && orderType == OP_BUY)
                typeMatch = true;
            else if(type == POSITION_TYPE_SELL && orderType == OP_SELL)
                typeMatch = true;
            
            if(typeMatch && OrderSymbol() == m_symbol && OrderMagicNumber() == m_magic)
            {
                count++;
            }
        }
    }
#endif
    
    return count;
}

//+------------------------------------------------------------------+
//| 平均価格計算                                                     |
//+------------------------------------------------------------------+
double CUnifiedTrading::GetAveragePrice(ENUM_POSITION_TYPE type)
{
    double lotsSum = 0;
    double priceSum = 0;
    
#ifdef __MQL5__
    for(int i = PositionsTotal() - 1; i >= 0; i--)
    {
        if(PositionSelectByTicket(PositionGetTicket(i)))
        {
            if(PositionGetString(POSITION_SYMBOL) == m_symbol &&
               PositionGetInteger(POSITION_MAGIC) == m_magic &&
               PositionGetInteger(POSITION_TYPE) == type)
            {
                double lots = PositionGetDouble(POSITION_VOLUME);
                double price = PositionGetDouble(POSITION_PRICE_OPEN);
                lotsSum += lots;
                priceSum += price * lots;
            }
        }
    }
#else // MQL4
    for(int i = OrdersTotal() - 1; i >= 0; i--)
    {
        if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
        {
            int orderType = OrderType();
            bool typeMatch = false;
            
            if(type == POSITION_TYPE_BUY && orderType == OP_BUY)
                typeMatch = true;
            else if(type == POSITION_TYPE_SELL && orderType == OP_SELL)
                typeMatch = true;
            
            if(typeMatch && OrderSymbol() == m_symbol && OrderMagicNumber() == m_magic)
            {
                double lots = OrderLots();
                double price = OrderOpenPrice();
                lotsSum += lots;
                priceSum += price * lots;
            }
        }
    }
#endif
    
    return (lotsSum > 0) ? priceSum / lotsSum : 0;
}

//+------------------------------------------------------------------+
//| 最初のエントリー価格取得                                         |
//+------------------------------------------------------------------+
double CUnifiedTrading::GetFirstEntryPrice(ENUM_POSITION_TYPE type)
{
    double firstPrice = 0;
    datetime firstTime = TimeCurrent();
    
#ifdef __MQL5__
    for(int i = PositionsTotal() - 1; i >= 0; i--)
    {
        if(PositionSelectByTicket(PositionGetTicket(i)))
        {
            if(PositionGetString(POSITION_SYMBOL) == m_symbol &&
               PositionGetInteger(POSITION_MAGIC) == m_magic &&
               PositionGetInteger(POSITION_TYPE) == type)
            {
                datetime openTime = (datetime)PositionGetInteger(POSITION_TIME);
                if(openTime < firstTime)
                {
                    firstTime = openTime;
                    firstPrice = PositionGetDouble(POSITION_PRICE_OPEN);
                }
            }
        }
    }
#else // MQL4
    for(int i = OrdersTotal() - 1; i >= 0; i--)
    {
        if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
        {
            int orderType = OrderType();
            bool typeMatch = false;
            
            if(type == POSITION_TYPE_BUY && orderType == OP_BUY)
                typeMatch = true;
            else if(type == POSITION_TYPE_SELL && orderType == OP_SELL)
                typeMatch = true;
            
            if(typeMatch && OrderSymbol() == m_symbol && OrderMagicNumber() == m_magic)
            {
                datetime openTime = OrderOpenTime();
                if(openTime < firstTime)
                {
                    firstTime = openTime;
                    firstPrice = OrderOpenPrice();
                }
            }
        }
    }
#endif
    
    return firstPrice;
}

//+------------------------------------------------------------------+
//| 最後のエントリー価格取得                                         |
//+------------------------------------------------------------------+
double CUnifiedTrading::GetLastEntryPrice(ENUM_POSITION_TYPE type)
{
    double lastPrice = 0;
    datetime lastTime = 0;
    
#ifdef __MQL5__
    for(int i = PositionsTotal() - 1; i >= 0; i--)
    {
        if(PositionSelectByTicket(PositionGetTicket(i)))
        {
            if(PositionGetString(POSITION_SYMBOL) == m_symbol &&
               PositionGetInteger(POSITION_MAGIC) == m_magic &&
               PositionGetInteger(POSITION_TYPE) == type)
            {
                datetime openTime = (datetime)PositionGetInteger(POSITION_TIME);
                if(openTime > lastTime)
                {
                    lastTime = openTime;
                    lastPrice = PositionGetDouble(POSITION_PRICE_OPEN);
                }
            }
        }
    }
#else // MQL4
    for(int i = OrdersTotal() - 1; i >= 0; i--)
    {
        if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
        {
            int orderType = OrderType();
            bool typeMatch = false;
            
            if(type == POSITION_TYPE_BUY && orderType == OP_BUY)
                typeMatch = true;
            else if(type == POSITION_TYPE_SELL && orderType == OP_SELL)
                typeMatch = true;
            
            if(typeMatch && OrderSymbol() == m_symbol && OrderMagicNumber() == m_magic)
            {
                datetime openTime = OrderOpenTime();
                if(openTime > lastTime)
                {
                    lastTime = openTime;
                    lastPrice = OrderOpenPrice();
                }
            }
        }
    }
#endif
    
    return lastPrice;
}

//+------------------------------------------------------------------+
//| 最大ロットサイズ取得                                             |
//+------------------------------------------------------------------+
double CUnifiedTrading::GetMaxLotSize(ENUM_POSITION_TYPE type)
{
    double maxLot = 0;
    
#ifdef __MQL5__
    for(int i = PositionsTotal() - 1; i >= 0; i--)
    {
        if(PositionSelectByTicket(PositionGetTicket(i)))
        {
            if(PositionGetString(POSITION_SYMBOL) == m_symbol &&
               PositionGetInteger(POSITION_MAGIC) == m_magic &&
               PositionGetInteger(POSITION_TYPE) == type)
            {
                double lots = PositionGetDouble(POSITION_VOLUME);
                if(lots > maxLot)
                    maxLot = lots;
            }
        }
    }
#else // MQL4
    for(int i = OrdersTotal() - 1; i >= 0; i--)
    {
        if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
        {
            int orderType = OrderType();
            bool typeMatch = false;
            
            if(type == POSITION_TYPE_BUY && orderType == OP_BUY)
                typeMatch = true;
            else if(type == POSITION_TYPE_SELL && orderType == OP_SELL)
                typeMatch = true;
            
            if(typeMatch && OrderSymbol() == m_symbol && OrderMagicNumber() == m_magic)
            {
                double lots = OrderLots();
                if(lots > maxLot)
                    maxLot = lots;
            }
        }
    }
#endif
    
    return maxLot;
}

//+------------------------------------------------------------------+
//| 合計ロット数取得                                                 |
//+------------------------------------------------------------------+
double CUnifiedTrading::GetTotalLots(ENUM_POSITION_TYPE type)
{
    double totalLots = 0;
    
#ifdef __MQL5__
    for(int i = PositionsTotal() - 1; i >= 0; i--)
    {
        if(PositionSelectByTicket(PositionGetTicket(i)))
        {
            if(PositionGetString(POSITION_SYMBOL) == m_symbol &&
               PositionGetInteger(POSITION_MAGIC) == m_magic &&
               PositionGetInteger(POSITION_TYPE) == type)
            {
                totalLots += PositionGetDouble(POSITION_VOLUME);
            }
        }
    }
#else // MQL4
    for(int i = OrdersTotal() - 1; i >= 0; i--)
    {
        if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
        {
            int orderType = OrderType();
            bool typeMatch = false;
            
            if(type == POSITION_TYPE_BUY && orderType == OP_BUY)
                typeMatch = true;
            else if(type == POSITION_TYPE_SELL && orderType == OP_SELL)
                typeMatch = true;
            
            if(typeMatch && OrderSymbol() == m_symbol && OrderMagicNumber() == m_magic)
            {
                totalLots += OrderLots();
            }
        }
    }
#endif
    
    return totalLots;
}

//+------------------------------------------------------------------+
//| 合計利益取得                                                     |
//+------------------------------------------------------------------+
double CUnifiedTrading::GetTotalProfit(ENUM_POSITION_TYPE type)
{
    double totalProfit = 0;
    
#ifdef __MQL5__
    for(int i = PositionsTotal() - 1; i >= 0; i--)
    {
        if(PositionSelectByTicket(PositionGetTicket(i)))
        {
            if(PositionGetString(POSITION_SYMBOL) == m_symbol &&
               PositionGetInteger(POSITION_MAGIC) == m_magic &&
               PositionGetInteger(POSITION_TYPE) == type)
            {
                totalProfit += PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
            }
        }
    }
#else // MQL4
    for(int i = OrdersTotal() - 1; i >= 0; i--)
    {
        if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
        {
            int orderType = OrderType();
            bool typeMatch = false;
            
            if(type == POSITION_TYPE_BUY && orderType == OP_BUY)
                typeMatch = true;
            else if(type == POSITION_TYPE_SELL && orderType == OP_SELL)
                typeMatch = true;
            
            if(typeMatch && OrderSymbol() == m_symbol && OrderMagicNumber() == m_magic)
            {
                totalProfit += OrderProfit() + OrderSwap() + OrderCommission();
            }
        }
    }
#endif
    
    return totalProfit;
}

//+------------------------------------------------------------------+
//| 部分決済                                                         |
//+------------------------------------------------------------------+
void CUnifiedTrading::ClosePositionPartial(ENUM_POSITION_TYPE side, double volumeToClose)
{
#ifdef __MQL5__
    for(int i = PositionsTotal() - 1; i >= 0; i--)
    {
        if(volumeToClose <= 0) break;
        
        if(PositionSelectByTicket(PositionGetTicket(i)))
        {
            if(PositionGetString(POSITION_SYMBOL) == m_symbol &&
               PositionGetInteger(POSITION_MAGIC) == m_magic &&
               PositionGetInteger(POSITION_TYPE) == side)
            {
                double currentVolume = PositionGetDouble(POSITION_VOLUME);
                double closeVolume = MathMin(volumeToClose, currentVolume);
                
                MqlTradeRequest request = {};
                MqlTradeResult result = {};
                request.action = TRADE_ACTION_DEAL;
                request.position = PositionGetInteger(POSITION_TICKET);
                request.symbol = m_symbol;
                request.volume = closeVolume;
                request.type = (side == POSITION_TYPE_BUY) ? ORDER_TYPE_SELL : ORDER_TYPE_BUY;
                request.price = (side == POSITION_TYPE_BUY) ? GetBidPrice() : GetAskPrice();
                request.deviation = m_slippage;
                request.magic = m_magic;
                request.comment = "Partial Close";
                request.type_filling = m_filling_type;
                
                if(OrderSend(request, result))
                {
                    if(result.retcode == TRADE_RETCODE_DONE || result.retcode == TRADE_RETCODE_PLACED)
                    {
                        volumeToClose -= closeVolume;
                    }
                }
            }
        }
    }
#else // MQL4
    for(int i = OrdersTotal() - 1; i >= 0; i--)
    {
        if(volumeToClose <= 0) break;
        
        if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
        {
            int orderType = OrderType();
            bool typeMatch = false;
            
            if(side == POSITION_TYPE_BUY && orderType == OP_BUY)
                typeMatch = true;
            else if(side == POSITION_TYPE_SELL && orderType == OP_SELL)
                typeMatch = true;
            
            if(typeMatch && OrderSymbol() == m_symbol && OrderMagicNumber() == m_magic)
            {
                double currentVolume = OrderLots();
                double closeVolume = MathMin(volumeToClose, currentVolume);
                double closePrice = (side == POSITION_TYPE_BUY) ? GetBidPrice() : GetAskPrice();
                
                if(OrderClose(OrderTicket(), closeVolume, closePrice, m_slippage, clrNONE))
                {
                    volumeToClose -= closeVolume;
                }
            }
        }
    }
#endif
}

//+------------------------------------------------------------------+
//| 最も古いポジションを閉じる                                       |
//+------------------------------------------------------------------+
void CUnifiedTrading::CloseOldestPosition(ENUM_POSITION_TYPE side)
{
    datetime oldestTime = TimeCurrent();
    
#ifdef __MQL5__
    ulong oldestTicket = 0;
    
    for(int i = PositionsTotal() - 1; i >= 0; i--)
    {
        if(PositionSelectByTicket(PositionGetTicket(i)))
        {
            if(PositionGetString(POSITION_SYMBOL) == m_symbol &&
               PositionGetInteger(POSITION_MAGIC) == m_magic &&
               PositionGetInteger(POSITION_TYPE) == side)
            {
                datetime openTime = (datetime)PositionGetInteger(POSITION_TIME);
                if(openTime < oldestTime)
                {
                    oldestTime = openTime;
                    oldestTicket = PositionGetTicket(i);
                }
            }
        }
    }
    
    if(oldestTicket > 0)
    {
        if(PositionSelectByTicket(oldestTicket))
        {
            MqlTradeRequest request = {};
            MqlTradeResult result = {};
            request.action = TRADE_ACTION_DEAL;
            request.position = oldestTicket;
            request.symbol = m_symbol;
            request.volume = PositionGetDouble(POSITION_VOLUME);
            request.type = (side == POSITION_TYPE_BUY) ? ORDER_TYPE_SELL : ORDER_TYPE_BUY;
            request.price = (side == POSITION_TYPE_BUY) ? GetBidPrice() : GetAskPrice();
            request.deviation = m_slippage;
            request.magic = m_magic;
            request.comment = "Close Oldest";
            request.type_filling = m_filling_type;
            
            OrderSend(request, result);
        }
    }
#else // MQL4
    int oldestTicket = -1;
    
    for(int i = OrdersTotal() - 1; i >= 0; i--)
    {
        if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
        {
            int orderType = OrderType();
            bool typeMatch = false;
            
            if(side == POSITION_TYPE_BUY && orderType == OP_BUY)
                typeMatch = true;
            else if(side == POSITION_TYPE_SELL && orderType == OP_SELL)
                typeMatch = true;
            
            if(typeMatch && OrderSymbol() == m_symbol && OrderMagicNumber() == m_magic)
            {
                datetime openTime = OrderOpenTime();
                if(openTime < oldestTime)
                {
                    oldestTime = openTime;
                    oldestTicket = OrderTicket();
                }
            }
        }
    }
    
    if(oldestTicket > 0)
    {
        if(OrderSelect(oldestTicket, SELECT_BY_TICKET))
        {
            double closePrice = (OrderType() == OP_BUY) ? GetBidPrice() : GetAskPrice();
            OrderClose(oldestTicket, OrderLots(), closePrice, m_slippage, clrNONE);
        }
    }
#endif
}

//+------------------------------------------------------------------+
//| ロット正規化                                                     |
//+------------------------------------------------------------------+
double CUnifiedTrading::NormalizeLot(double lot)
{
    double minLot = SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_MIN);
    double maxLot = SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_MAX);
    double lotStep = SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_STEP);
    
    lot = MathMax(minLot, lot);
    lot = MathMin(maxLot, lot);
    lot = MathRound(lot / lotStep) * lotStep;
    
    return NormalizeDouble(lot, 2);
}

//+------------------------------------------------------------------+
//| 取引許可チェック                                                 |
//+------------------------------------------------------------------+
bool CUnifiedTrading::IsTradeAllowed()
{
#ifdef __MQL5__
    return (bool)MQLInfoInteger(MQL_TRADE_ALLOWED) && (bool)TerminalInfoInteger(TERMINAL_TRADE_ALLOWED);
#else
    return ::IsTradeAllowed();
#endif
}

//+------------------------------------------------------------------+
//| ポイント取得                                                     |
//+------------------------------------------------------------------+
double CUnifiedTrading::GetPoint()
{
#ifdef __MQL5__
    return SymbolInfoDouble(m_symbol, SYMBOL_POINT);
#else
    return MarketInfo(m_symbol, MODE_POINT);
#endif
}

//+------------------------------------------------------------------+
//| 桁数取得                                                         |
//+------------------------------------------------------------------+
int CUnifiedTrading::GetDigits()
{
#ifdef __MQL5__
    return (int)SymbolInfoInteger(m_symbol, SYMBOL_DIGITS);
#else
    return (int)MarketInfo(m_symbol, MODE_DIGITS);
#endif
}

//+------------------------------------------------------------------+
//| スプレッド取得                                                   |
//+------------------------------------------------------------------+
double CUnifiedTrading::GetSpread()
{
#ifdef __MQL5__
    return (GetAskPrice() - GetBidPrice()) / GetPoint();
#else
    return MarketInfo(m_symbol, MODE_SPREAD);
#endif
}

//+------------------------------------------------------------------+
//| アカウント残高取得                                               |
//+------------------------------------------------------------------+
double CUnifiedTrading::GetAccountBalance()
{
#ifdef __MQL5__
    return AccountInfoDouble(ACCOUNT_BALANCE);
#else
    return AccountBalance();
#endif
}

//+------------------------------------------------------------------+
//| アカウント有効証拠金取得                                         |
//+------------------------------------------------------------------+
double CUnifiedTrading::GetAccountEquity()
{
#ifdef __MQL5__
    return AccountInfoDouble(ACCOUNT_EQUITY);
#else
    return AccountEquity();
#endif
}

//+------------------------------------------------------------------+
//| アカウント余剰証拠金取得                                         |
//+------------------------------------------------------------------+
double CUnifiedTrading::GetAccountFreeMargin()
{
#ifdef __MQL5__
    return AccountInfoDouble(ACCOUNT_MARGIN_FREE);
#else
    return AccountFreeMargin();
#endif
}

//+------------------------------------------------------------------+
//| 保留注文を出す                                                   |
//+------------------------------------------------------------------+
bool CUnifiedTrading::PlacePendingOrder(int orderType, double price, double lots, double sl, double tp, string comment)
{
#ifdef __MQL5__
    MqlTradeRequest request = {};
    MqlTradeResult result = {};
    
    request.action = TRADE_ACTION_PENDING;
    request.symbol = m_symbol;
    request.volume = lots;
    request.type = (ENUM_ORDER_TYPE)orderType;
    request.price = NormalizeDouble(price, GetDigits());
    request.sl = sl;
    request.tp = tp;
    request.deviation = m_slippage;
    request.magic = m_magic;
    request.comment = comment;
    request.type_filling = m_filling_type;
    request.expiration = TimeCurrent() + 86400; // 24時間有効
    request.type_time = ORDER_TIME_SPECIFIED;
    
    if(!OrderSend(request, result))
    {
        Print("OrderSend error: ", GetLastError());
        return false;
    }
    
    return (result.retcode == TRADE_RETCODE_DONE);
    
#else // MQL4
    int mql4OrderType = -1;
    switch(orderType)
    {
        case 2: mql4OrderType = OP_BUYLIMIT; break;
        case 3: mql4OrderType = OP_SELLLIMIT; break;
        case 4: mql4OrderType = OP_BUYSTOP; break;
        case 5: mql4OrderType = OP_SELLSTOP; break;
        default: return false;
    }
    
    datetime expiration = TimeCurrent() + 86400;
    
    int ticket = OrderSend(m_symbol, mql4OrderType, lots, price, m_slippage, sl, tp, comment, m_magic, expiration, clrNONE);
    
    return (ticket > 0);
#endif
}

//+------------------------------------------------------------------+
//| すべての保留注文を削除                                           |
//+------------------------------------------------------------------+
void CUnifiedTrading::DeleteAllPendingOrders()
{
#ifdef __MQL5__
    for(int i = OrdersTotal() - 1; i >= 0; i--)
    {
        ulong ticket = OrderGetTicket(i);
        if(OrderSelect(ticket))
        {
            if(OrderGetString(ORDER_SYMBOL) == m_symbol &&
               OrderGetInteger(ORDER_MAGIC) == m_magic)
            {
                MqlTradeRequest request = {};
                MqlTradeResult result = {};
                
                request.action = TRADE_ACTION_REMOVE;
                request.order = ticket;
                
                OrderSend(request, result);
            }
        }
    }
#else // MQL4
    for(int i = OrdersTotal() - 1; i >= 0; i--)
    {
        if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
        {
            if(OrderType() >= OP_BUYLIMIT &&
               OrderSymbol() == m_symbol &&
               OrderMagicNumber() == m_magic)
            {
                OrderDelete(OrderTicket());
            }
        }
    }
#endif
}

//+------------------------------------------------------------------+
//| 保留注文数取得                                                   |
//+------------------------------------------------------------------+
int CUnifiedTrading::GetPendingOrdersCount()
{
    int count = 0;
    
#ifdef __MQL5__
    for(int i = OrdersTotal() - 1; i >= 0; i--)
    {
        if(OrderSelect(OrderGetTicket(i)))
        {
            if(OrderGetString(ORDER_SYMBOL) == m_symbol &&
               OrderGetInteger(ORDER_MAGIC) == m_magic)
            {
                count++;
            }
        }
    }
#else // MQL4
    for(int i = OrdersTotal() - 1; i >= 0; i--)
    {
        if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
        {
            if(OrderType() >= OP_BUYLIMIT &&
               OrderSymbol() == m_symbol &&
               OrderMagicNumber() == m_magic)
            {
                count++;
            }
        }
    }
#endif
    
    return count;
}

//+------------------------------------------------------------------+
//| グローバルトレーディングオブジェクト                             |
//+------------------------------------------------------------------+
CUnifiedTrading* g_Trading = NULL;

//+------------------------------------------------------------------+
//| トレーディングオブジェクトの初期化                               |
//+------------------------------------------------------------------+
void InitializeTrading()
{
    if(g_Trading == NULL)
    {
        g_Trading = new CUnifiedTrading();
        g_Trading.Init(MagicNumber, Symbol(), Slippage, OrderTypeFilling);
    }
}

//+------------------------------------------------------------------+
//| トレーディングオブジェクトのクリーンアップ                       |
//+------------------------------------------------------------------+
void CleanupTrading()
{
    if(g_Trading != NULL)
    {
        delete g_Trading;
        g_Trading = NULL;
    }
}