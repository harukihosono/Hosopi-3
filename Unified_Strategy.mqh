//+------------------------------------------------------------------+
//|                     Unified_Strategy.mqh                         |
//|           MQL4/MQL5 統合ストラテジーライブラリ                    |
//|                     Copyright 2025                               |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025"
#property version   "1.00"

#include "Unified_Trading.mqh"

//+------------------------------------------------------------------+
//| ストラテジー列挙型定義                                           |
//+------------------------------------------------------------------+
// エントリーモード
enum ENTRY_MODE_TYPE
{
    MODE_BUY_ONLY = 0,      // Buyのみ
    MODE_SELL_ONLY = 1,     // Sellのみ
    MODE_BOTH = 2           // Buy & Sell両方
};

// 条件判定タイプ
enum CONDITION_TYPE
{
    OR_CONDITION = 0,       // いずれかの条件が成立（OR条件）
    AND_CONDITION = 1       // すべての条件が成立（AND条件）
};

// 戦略方向
enum STRATEGY_DIRECTION
{
    TREND_FOLLOWING = 0,    // 順張り
    COUNTER_TREND = 1       // 逆張り
};

//+------------------------------------------------------------------+
//| インジケーター戦略基底クラス                                     |
//+------------------------------------------------------------------+
class CIndicatorStrategy
{
protected:
    string  m_symbol;
    int     m_timeframe;
    bool    m_enabled;
    int     m_buySignalType;
    int     m_sellSignalType;
    STRATEGY_DIRECTION m_buyDirection;
    STRATEGY_DIRECTION m_sellDirection;
    
public:
    CIndicatorStrategy() : m_enabled(false), m_buySignalType(0), m_sellSignalType(0) {}
    virtual ~CIndicatorStrategy() {}
    
    // 初期化
    virtual void Init(string symbol, int timeframe) 
    { 
        m_symbol = symbol; 
        m_timeframe = timeframe; 
    }
    
    // 有効/無効設定
    void SetEnabled(bool enabled) { m_enabled = enabled; }
    bool IsEnabled() { return m_enabled; }
    
    // シグナルチェック（純粋仮想関数）
    virtual bool CheckBuySignal() = 0;
    virtual bool CheckSellSignal() = 0;
    virtual string GetStrategyName() = 0;
    virtual string GetStateDescription() = 0;
};

//+------------------------------------------------------------------+
//| MA戦略クラス                                                     |
//+------------------------------------------------------------------+
class CMAStrategy : public CIndicatorStrategy
{
private:
    int     m_buyFastPeriod;
    int     m_buySlowPeriod;
    int     m_sellFastPeriod;
    int     m_sellSlowPeriod;
    int     m_maMethod;
    int     m_appliedPrice;
    int     m_shift;
    
    double GetMA(int period, int shift)
    {
        #ifdef __MQL5__
        double buffer[];
        int handle = iMA(m_symbol, (ENUM_TIMEFRAMES)m_timeframe, period, 0, (ENUM_MA_METHOD)m_maMethod, m_appliedPrice);
        if(handle != INVALID_HANDLE)
        {
            ArraySetAsSeries(buffer, true);
            if(CopyBuffer(handle, 0, shift, 1, buffer) > 0)
                return buffer[0];
        }
        return 0;
        #else
        return iMA(m_symbol, m_timeframe, period, 0, m_maMethod, m_appliedPrice, shift);
        #endif
    }
    
public:
    void SetParameters(int buyFast, int buySlow, int sellFast, int sellSlow, 
                      int method, int price, int shift)
    {
        m_buyFastPeriod = buyFast;
        m_buySlowPeriod = buySlow;
        m_sellFastPeriod = sellFast;
        m_sellSlowPeriod = sellSlow;
        m_maMethod = method;
        m_appliedPrice = price;
        m_shift = shift;
    }
    
    void SetSignalTypes(int buyType, int sellType, STRATEGY_DIRECTION buyDir, STRATEGY_DIRECTION sellDir)
    {
        m_buySignalType = buyType;
        m_sellSignalType = sellType;
        m_buyDirection = buyDir;
        m_sellDirection = sellDir;
    }
    
    virtual bool CheckBuySignal() override
    {
        if(!m_enabled || m_buySignalType == 0) return false;
        
        double fastCurrent = GetMA(m_buyFastPeriod, m_shift);
        double slowCurrent = GetMA(m_buySlowPeriod, m_shift);
        double fastPrev = GetMA(m_buyFastPeriod, m_shift + 1);
        double slowPrev = GetMA(m_buySlowPeriod, m_shift + 1);
        
        bool signal = false;
        
        switch(m_buySignalType)
        {
            case 1: // ゴールデンクロス
                signal = (fastPrev < slowPrev && fastCurrent > slowCurrent);
                break;
            case 2: // デッドクロス
                signal = (fastPrev > slowPrev && fastCurrent < slowCurrent);
                break;
            case 3: // 価格がMA上
                signal = (g_Trading.GetCurrentPrice(POSITION_TYPE_BUY) > fastCurrent);
                break;
            case 4: // 価格がMA下
                signal = (g_Trading.GetCurrentPrice(POSITION_TYPE_BUY) < fastCurrent);
                break;
            case 5: // 短期MAが長期MA上
                signal = (fastCurrent > slowCurrent);
                break;
            case 6: // 短期MAが長期MA下
                signal = (fastCurrent < slowCurrent);
                break;
        }
        
        return (m_buyDirection == TREND_FOLLOWING) ? signal : !signal;
    }
    
    virtual bool CheckSellSignal() override
    {
        if(!m_enabled || m_sellSignalType == 0) return false;
        
        double fastCurrent = GetMA(m_sellFastPeriod, m_shift);
        double slowCurrent = GetMA(m_sellSlowPeriod, m_shift);
        double fastPrev = GetMA(m_sellFastPeriod, m_shift + 1);
        double slowPrev = GetMA(m_sellSlowPeriod, m_shift + 1);
        
        bool signal = false;
        
        switch(m_sellSignalType)
        {
            case 1: // ゴールデンクロス
                signal = (fastPrev < slowPrev && fastCurrent > slowCurrent);
                break;
            case 2: // デッドクロス
                signal = (fastPrev > slowPrev && fastCurrent < slowCurrent);
                break;
            case 3: // 価格がMA上
                signal = (g_Trading.GetCurrentPrice(POSITION_TYPE_SELL) > fastCurrent);
                break;
            case 4: // 価格がMA下
                signal = (g_Trading.GetCurrentPrice(POSITION_TYPE_SELL) < fastCurrent);
                break;
            case 5: // 短期MAが長期MA上
                signal = (fastCurrent > slowCurrent);
                break;
            case 6: // 短期MAが長期MA下
                signal = (fastCurrent < slowCurrent);
                break;
        }
        
        return (m_sellDirection == TREND_FOLLOWING) ? signal : !signal;
    }
    
    virtual string GetStrategyName() override { return "MA Strategy"; }
    
    virtual string GetStateDescription() override
    {
        if(!m_enabled) return "MA: 無効";
        
        double fastCurrent = GetMA(m_buyFastPeriod, m_shift);
        double slowCurrent = GetMA(m_buySlowPeriod, m_shift);
        
        return StringFormat("MA: Fast=%.5f, Slow=%.5f", fastCurrent, slowCurrent);
    }
};

//+------------------------------------------------------------------+
//| RSI戦略クラス                                                    |
//+------------------------------------------------------------------+
class CRSIStrategy : public CIndicatorStrategy
{
private:
    int     m_period;
    int     m_appliedPrice;
    int     m_shift;
    double  m_oversold;
    double  m_overbought;
    
    double GetRSI(int shift)
    {
        #ifdef __MQL5__
        double buffer[];
        int handle = iRSI(m_symbol, (ENUM_TIMEFRAMES)m_timeframe, m_period, m_appliedPrice);
        if(handle != INVALID_HANDLE)
        {
            ArraySetAsSeries(buffer, true);
            if(CopyBuffer(handle, 0, shift, 1, buffer) > 0)
                return buffer[0];
        }
        return 0;
        #else
        return iRSI(m_symbol, m_timeframe, m_period, m_appliedPrice, shift);
        #endif
    }
    
public:
    void SetParameters(int period, int price, int shift, double oversold, double overbought)
    {
        m_period = period;
        m_appliedPrice = price;
        m_shift = shift;
        m_oversold = oversold;
        m_overbought = overbought;
    }
    
    void SetSignalTypes(int buyType, int sellType, STRATEGY_DIRECTION buyDir, STRATEGY_DIRECTION sellDir)
    {
        m_buySignalType = buyType;
        m_sellSignalType = sellType;
        m_buyDirection = buyDir;
        m_sellDirection = sellDir;
    }
    
    virtual bool CheckBuySignal() override
    {
        if(!m_enabled || m_buySignalType == 0) return false;
        
        double rsiCurrent = GetRSI(m_shift);
        double rsiPrev = GetRSI(m_shift + 1);
        
        bool signal = false;
        
        switch(m_buySignalType)
        {
            case 1: // 売られすぎ
                signal = (rsiCurrent < m_oversold);
                break;
            case 2: // 売られすぎから回復
                signal = (rsiPrev < m_oversold && rsiCurrent >= m_oversold);
                break;
            case 3: // 買われすぎ
                signal = (rsiCurrent > m_overbought);
                break;
            case 4: // 買われすぎから下落
                signal = (rsiPrev > m_overbought && rsiCurrent <= m_overbought);
                break;
        }
        
        return (m_buyDirection == TREND_FOLLOWING) ? signal : !signal;
    }
    
    virtual bool CheckSellSignal() override
    {
        if(!m_enabled || m_sellSignalType == 0) return false;
        
        double rsiCurrent = GetRSI(m_shift);
        double rsiPrev = GetRSI(m_shift + 1);
        
        bool signal = false;
        
        switch(m_sellSignalType)
        {
            case 1: // 売られすぎ
                signal = (rsiCurrent < m_oversold);
                break;
            case 2: // 売られすぎから回復
                signal = (rsiPrev < m_oversold && rsiCurrent >= m_oversold);
                break;
            case 3: // 買われすぎ
                signal = (rsiCurrent > m_overbought);
                break;
            case 4: // 買われすぎから下落
                signal = (rsiPrev > m_overbought && rsiCurrent <= m_overbought);
                break;
        }
        
        return (m_sellDirection == TREND_FOLLOWING) ? signal : !signal;
    }
    
    virtual string GetStrategyName() override { return "RSI Strategy"; }
    
    virtual string GetStateDescription() override
    {
        if(!m_enabled) return "RSI: 無効";
        
        double rsiCurrent = GetRSI(m_shift);
        
        return StringFormat("RSI: %.2f (OS=%.0f, OB=%.0f)", rsiCurrent, m_oversold, m_overbought);
    }
};

//+------------------------------------------------------------------+
//| 統合ストラテジーマネージャークラス                               |
//+------------------------------------------------------------------+
class CStrategyManager
{
private:
    CIndicatorStrategy* m_strategies[];
    int                 m_strategyCount;
    ENTRY_MODE_TYPE     m_entryMode;
    CONDITION_TYPE      m_conditionType;
    
public:
    CStrategyManager()
    {
        m_strategyCount = 0;
        m_entryMode = MODE_BOTH;
        m_conditionType = OR_CONDITION;
    }
    
    ~CStrategyManager()
    {
        for(int i = 0; i < m_strategyCount; i++)
        {
            if(m_strategies[i] != NULL)
            {
                delete m_strategies[i];
                m_strategies[i] = NULL;
            }
        }
        ArrayResize(m_strategies, 0);
    }
    
    // ストラテジー追加
    void AddStrategy(CIndicatorStrategy* strategy)
    {
        ArrayResize(m_strategies, m_strategyCount + 1);
        m_strategies[m_strategyCount] = strategy;
        m_strategyCount++;
    }
    
    // 設定
    void SetEntryMode(ENTRY_MODE_TYPE mode) { m_entryMode = mode; }
    void SetConditionType(CONDITION_TYPE type) { m_conditionType = type; }
    
    // シグナル評価
    bool EvaluateBuySignal()
    {
        // エントリーモードチェック
        if(m_entryMode != MODE_BUY_ONLY && m_entryMode != MODE_BOTH)
            return false;
        
        int enabledCount = 0;
        int validCount = 0;
        
        for(int i = 0; i < m_strategyCount; i++)
        {
            if(m_strategies[i].IsEnabled())
            {
                enabledCount++;
                if(m_strategies[i].CheckBuySignal())
                {
                    validCount++;
                    Print(m_strategies[i].GetStrategyName(), ": Buy シグナル成立");
                }
            }
        }
        
        if(enabledCount == 0) return false;
        
        if(m_conditionType == AND_CONDITION)
            return (validCount == enabledCount);
        else
            return (validCount > 0);
    }
    
    bool EvaluateSellSignal()
    {
        // エントリーモードチェック
        if(m_entryMode != MODE_SELL_ONLY && m_entryMode != MODE_BOTH)
            return false;
        
        int enabledCount = 0;
        int validCount = 0;
        
        for(int i = 0; i < m_strategyCount; i++)
        {
            if(m_strategies[i].IsEnabled())
            {
                enabledCount++;
                if(m_strategies[i].CheckSellSignal())
                {
                    validCount++;
                    Print(m_strategies[i].GetStrategyName(), ": Sell シグナル成立");
                }
            }
        }
        
        if(enabledCount == 0) return false;
        
        if(m_conditionType == AND_CONDITION)
            return (validCount == enabledCount);
        else
            return (validCount > 0);
    }
    
    // 状態取得
    string GetStrategyStatus()
    {
        string status = "=== Strategy Status ===\n";
        status += "Entry Mode: " + GetEntryModeString() + "\n";
        status += "Condition: " + (m_conditionType == AND_CONDITION ? "AND" : "OR") + "\n\n";
        
        for(int i = 0; i < m_strategyCount; i++)
        {
            status += m_strategies[i].GetStateDescription() + "\n";
        }
        
        return status;
    }
    
private:
    string GetEntryModeString()
    {
        switch(m_entryMode)
        {
            case MODE_BUY_ONLY: return "Buy Only";
            case MODE_SELL_ONLY: return "Sell Only";
            case MODE_BOTH: return "Buy & Sell";
            default: return "Unknown";
        }
    }
};

//+------------------------------------------------------------------+
//| 時間ベース戦略クラス                                             |
//+------------------------------------------------------------------+
class CTimeBasedStrategy
{
private:
    bool    m_enabled;
    int     m_startHour;
    int     m_startMinute;
    int     m_endHour;
    int     m_endMinute;
    bool    m_useJapanTime;
    
public:
    CTimeBasedStrategy() : m_enabled(false), m_useJapanTime(true) {}
    
    void SetEnabled(bool enabled) { m_enabled = enabled; }
    void SetTimeRange(int startH, int startM, int endH, int endM)
    {
        m_startHour = startH;
        m_startMinute = startM;
        m_endHour = endH;
        m_endMinute = endM;
    }
    
    void SetUseJapanTime(bool useJP) { m_useJapanTime = useJP; }
    
    bool IsInTimeRange()
    {
        if(!m_enabled) return true;
        
        datetime currentTime = m_useJapanTime ? GetJapanTime() : TimeCurrent();
        MqlDateTime dt;
        TimeToStruct(currentTime, dt);
        
        int currentMinutes = dt.hour * 60 + dt.min;
        int startMinutes = m_startHour * 60 + m_startMinute;
        int endMinutes = m_endHour * 60 + m_endMinute;
        
        if(startMinutes <= endMinutes)
            return (currentMinutes >= startMinutes && currentMinutes < endMinutes);
        else
            return (currentMinutes >= startMinutes || currentMinutes < endMinutes);
    }
    
private:
    datetime GetJapanTime()
    {
        return TimeGMT() + 9 * 3600; // 簡易的な日本時間計算
    }
};

//+------------------------------------------------------------------+
//| 偶数/奇数時間戦略クラス                                          |
//+------------------------------------------------------------------+
class CEvenOddHourStrategy
{
public:
    enum EVEN_ODD_TYPE
    {
        EVEN_ODD_DISABLED = 0,
        EVEN_HOUR_BUY_ODD_HOUR_SELL = 1,
        ODD_HOUR_BUY_EVEN_HOUR_SELL = 2,
        EVEN_HOUR_BOTH = 3,
        ODD_HOUR_BOTH = 4,
        ALL_HOURS_ENABLED = 5
    };
    
private:
    EVEN_ODD_TYPE m_type;
    bool m_useJapanTime;
    bool m_includeWeekends;
    
public:
    CEvenOddHourStrategy() : m_type(EVEN_ODD_DISABLED), m_useJapanTime(true), m_includeWeekends(false) {}
    
    void SetType(EVEN_ODD_TYPE type) { m_type = type; }
    void SetUseJapanTime(bool useJP) { m_useJapanTime = useJP; }
    void SetIncludeWeekends(bool include) { m_includeWeekends = include; }
    
    bool CheckSignal(ENUM_POSITION_TYPE side)
    {
        if(m_type == EVEN_ODD_DISABLED) return false;
        
        datetime currentTime = m_useJapanTime ? (TimeGMT() + 9 * 3600) : TimeCurrent();
        MqlDateTime dt;
        TimeToStruct(currentTime, dt);
        
        // 週末チェック
        if(!m_includeWeekends && (dt.day_of_week == 0 || dt.day_of_week == 6))
            return false;
        
        bool isEvenHour = (dt.hour % 2 == 0);
        
        switch(m_type)
        {
            case ALL_HOURS_ENABLED:
                return true;
                
            case EVEN_HOUR_BOTH:
                return isEvenHour;
                
            case ODD_HOUR_BOTH:
                return !isEvenHour;
                
            case EVEN_HOUR_BUY_ODD_HOUR_SELL:
                return (side == POSITION_TYPE_BUY) ? isEvenHour : !isEvenHour;
                
            case ODD_HOUR_BUY_EVEN_HOUR_SELL:
                return (side == POSITION_TYPE_BUY) ? !isEvenHour : isEvenHour;
        }
        
        return false;
    }
    
    string GetStateDescription()
    {
        string desc = "偶数/奇数時間: ";
        
        switch(m_type)
        {
            case EVEN_ODD_DISABLED: desc += "無効"; break;
            case EVEN_HOUR_BUY_ODD_HOUR_SELL: desc += "偶数時Buy/奇数時Sell"; break;
            case ODD_HOUR_BUY_EVEN_HOUR_SELL: desc += "奇数時Buy/偶数時Sell"; break;
            case EVEN_HOUR_BOTH: desc += "偶数時間のみ"; break;
            case ODD_HOUR_BOTH: desc += "奇数時間のみ"; break;
            case ALL_HOURS_ENABLED: desc += "全時間"; break;
        }
        
        if(m_type != EVEN_ODD_DISABLED)
        {
            desc += " (" + (m_useJapanTime ? "日本時間" : "サーバー時間");
            desc += ", " + (m_includeWeekends ? "週末含む" : "平日のみ") + ")";
        }
        
        return desc;
    }
};

//+------------------------------------------------------------------+
//| グローバルストラテジーマネージャー                               |
//+------------------------------------------------------------------+
CStrategyManager* g_StrategyManager = NULL;
CTimeBasedStrategy* g_TimeStrategy = NULL;
CEvenOddHourStrategy* g_EvenOddStrategy = NULL;

//+------------------------------------------------------------------+
//| ストラテジーの初期化                                             |
//+------------------------------------------------------------------+
void InitializeStrategies()
{
    // ストラテジーマネージャー作成
    if(g_StrategyManager == NULL)
        g_StrategyManager = new CStrategyManager();
    
    // 時間戦略作成
    if(g_TimeStrategy == NULL)
        g_TimeStrategy = new CTimeBasedStrategy();
    
    // 偶数/奇数時間戦略作成
    if(g_EvenOddStrategy == NULL)
        g_EvenOddStrategy = new CEvenOddHourStrategy();
}

//+------------------------------------------------------------------+
//| ストラテジーのクリーンアップ                                     |
//+------------------------------------------------------------------+
void CleanupStrategies()
{
    if(g_StrategyManager != NULL)
    {
        delete g_StrategyManager;
        g_StrategyManager = NULL;
    }
    
    if(g_TimeStrategy != NULL)
    {
        delete g_TimeStrategy;
        g_TimeStrategy = NULL;
    }
    
    if(g_EvenOddStrategy != NULL)
    {
        delete g_EvenOddStrategy;
        g_EvenOddStrategy = NULL;
    }
}

//+------------------------------------------------------------------+
//| エントリーシグナル評価（統合版）                                 |
//+------------------------------------------------------------------+
bool EvaluateEntrySignal(ENUM_POSITION_TYPE side)
{
    // 時間チェック
    if(g_TimeStrategy != NULL && !g_TimeStrategy.IsInTimeRange())
        return false;
    
    // 偶数/奇数時間チェック
    if(g_EvenOddStrategy != NULL && !g_EvenOddStrategy.CheckSignal(side))
        return false;
    
    // インジケーターシグナルチェック
    if(g_StrategyManager != NULL)
    {
        if(side == POSITION_TYPE_BUY)
            return g_StrategyManager.EvaluateBuySignal();
        else
            return g_StrategyManager.EvaluateSellSignal();
    }
    
    return false;
}