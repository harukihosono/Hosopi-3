//+------------------------------------------------------------------+
//|                      Unified_Utils.mqh                           |
//|           MQL4/MQL5 統合ユーティリティライブラリ                  |
//|                     Copyright 2025                               |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025"
#property version   "1.00"

#include "Unified_Trading.mqh"

//+------------------------------------------------------------------+
//| 定数定義                                                         |
//+------------------------------------------------------------------+
#define MAX_POSITIONS      40        // 最大ポジション数
#define MAX_OBJECTS        1000      // 最大オブジェクト数
#define CACHE_INTERVAL     60        // キャッシュ更新間隔（秒）
#define CACHE_INTERVAL_BT  3600      // バックテスト時のキャッシュ更新間隔

//+------------------------------------------------------------------+
//| 列挙型定義                                                       |
//+------------------------------------------------------------------+
// 時間設定タイプ
enum TIME_ZONE_TYPE
{
    GMT9 = 0,              // GMT+9（日本時間）
    GMT9_BACKTEST = 1,     // GMT+9（バックテスト用）
    GMT_FIXED = 2,         // 固定オフセット
    SERVER_TIME = 3        // サーバー時間
};

// ON/OFFモード
enum ON_OFF_MODE
{
    OFF_MODE = 0,          // 無効
    ON_MODE = 1            // 有効
};

// ポジション保護モード
enum PROTECTION_MODE
{
    PROTECTION_OFF = 0,    // 両建て許可
    PROTECTION_ON = 1      // 単方向のみ
};

// ゴーストポジション構造体
struct GhostPosition
{
    bool     isGhost;      // ゴーストかどうか
    double   price;        // エントリー価格
    double   lots;         // ロット数
    datetime openTime;     // エントリー時刻
    string   comment;      // コメント
};

//+------------------------------------------------------------------+
//| グローバル変数定義                                               |
//+------------------------------------------------------------------+
// キャッシュ変数
bool g_EquitySufficientCache = true;
datetime g_LastEquityCheckTime = 0;
bool g_TimeAllowedCache[2] = {true, true};
datetime g_LastTimeAllowedCheckTime[2] = {0, 0};
bool g_InitialTimeAllowedCache[2] = {true, true};
datetime g_LastInitialTimeAllowedCheckTime[2] = {0, 0};

// ゴーストポジション管理
GhostPosition g_GhostBuyPositions[MAX_POSITIONS];
GhostPosition g_GhostSellPositions[MAX_POSITIONS];
int g_GhostBuyCount = 0;
int g_GhostSellCount = 0;
bool g_BuyGhostClosed = false;
bool g_SellGhostClosed = false;

// ロットテーブル
double g_LotTable[MAX_POSITIONS];
double g_NanpinSpreadTable[MAX_POSITIONS];

// オブジェクト管理
string g_LineNames[MAX_OBJECTS];
string g_PanelNames[MAX_OBJECTS];
string g_TableNames[MAX_OBJECTS];
int g_LineObjectCount = 0;
int g_PanelObjectCount = 0;
int g_TableObjectCount = 0;
string g_ObjectPrefix = "";

// 決済後インターバル管理
bool g_BuyClosedRecently = false;
bool g_SellClosedRecently = false;
datetime g_BuyClosedTime = 0;
datetime g_SellClosedTime = 0;

// エントリー時間管理
datetime g_LastConstantLongEntryTime = 0;
datetime g_LastConstantShortEntryTime = 0;

// フラグ管理
bool g_AutoTrading = true;
bool g_GhostMode = true;
bool g_ArrowsVisible = true;
bool g_AvgPriceVisible = true;
bool g_UseEvenOddHoursEntry = false;

//+------------------------------------------------------------------+
//| 時間管理クラス                                                   |
//+------------------------------------------------------------------+
class CTimeManager
{
private:
    TIME_ZONE_TYPE m_timeZone;
    int m_summerOffset;
    int m_winterOffset;
    
public:
    CTimeManager()
    {
        m_timeZone = GMT9;
        m_summerOffset = 6;  // 夏時間オフセット
        m_winterOffset = 7;  // 冬時間オフセット
    }
    
    void SetTimeZone(TIME_ZONE_TYPE zone) { m_timeZone = zone; }
    void SetOffsets(int summer, int winter) { m_summerOffset = summer; m_winterOffset = winter; }
    
    // 設定に基づいた時間を取得
    datetime GetCurrentTime()
    {
        switch(m_timeZone)
        {
            case GMT9:
                return TimeGMT() + 9 * 3600;
                
            case GMT9_BACKTEST:
                return GetJapanTime();
                
            case GMT_FIXED:
                return TimeCurrent() + 9 * 3600;
                
            case SERVER_TIME:
            default:
                return TimeCurrent();
        }
    }
    
    // 日本時間を取得（サマータイム考慮）
    datetime GetJapanTime()
    {
        datetime now = TimeCurrent();
        int offset = IsSummer() ? m_summerOffset : m_winterOffset;
        return now + offset * 3600;
    }
    
    // サマータイム判定
    bool IsSummer()
    {
        datetime now = TimeCurrent();
        MqlDateTime dt;
        TimeToStruct(now, dt);
        
        int month = dt.mon;
        int day = dt.day;
        
        if(month < 3 || month > 11) return false;
        if(month > 3 && month < 11) return true;
        
        // 3月の第2日曜日から11月の第1日曜日まで
        if(month == 3)
        {
            int secondSunday = GetNthSunday(dt.year, 3, 2);
            return day >= secondSunday;
        }
        else if(month == 11)
        {
            int firstSunday = GetNthSunday(dt.year, 11, 1);
            return day < firstSunday;
        }
        
        return false;
    }
    
private:
    // N番目の日曜日を取得
    int GetNthSunday(int year, int month, int n)
    {
        string dateStr = StringFormat("%04d.%02d.01", year, month);
        datetime firstDay = StringToTime(dateStr);
        MqlDateTime dt;
        TimeToStruct(firstDay, dt);
        
        int firstSunday = (7 - dt.day_of_week) % 7 + 1;
        return firstSunday + (n - 1) * 7;
    }
};

//+------------------------------------------------------------------+
//| キャッシュ管理クラス                                             |
//+------------------------------------------------------------------+
class CCacheManager
{
public:
    // 有効証拠金チェック（キャッシュ付き）
    static bool IsEquitySufficientCached(double minEquity)
    {
        datetime currentTime = TimeCurrent();
        int cacheInterval = IsTesting() ? CACHE_INTERVAL_BT : CACHE_INTERVAL;
        
        if(currentTime - g_LastEquityCheckTime < cacheInterval)
            return g_EquitySufficientCache;
        
        g_LastEquityCheckTime = currentTime;
        
        #ifdef __MQL5__
        double currentEquity = AccountInfoDouble(ACCOUNT_EQUITY);
        #else
        double currentEquity = AccountEquity();
        #endif
        
        g_EquitySufficientCache = (currentEquity >= minEquity);
        
        if(!g_EquitySufficientCache)
        {
            Print(StringFormat("エントリー停止: 有効証拠金 %.2f が最低基準 %.2f を下回りました", 
                              currentEquity, minEquity));
        }
        
        return g_EquitySufficientCache;
    }
    
    // 時間許可チェック（キャッシュ付き）
    static bool IsTimeAllowedCached(int type, bool (*checkFunc)(int))
    {
        int typeIndex = (type == 0) ? 0 : 1;
        datetime currentTime = TimeCurrent();
        int cacheInterval = IsTesting() ? CACHE_INTERVAL_BT : CACHE_INTERVAL;
        
        if(currentTime - g_LastTimeAllowedCheckTime[typeIndex] < cacheInterval)
            return g_TimeAllowedCache[typeIndex];
        
        g_LastTimeAllowedCheckTime[typeIndex] = currentTime;
        g_TimeAllowedCache[typeIndex] = checkFunc(type);
        
        return g_TimeAllowedCache[typeIndex];
    }
    
    // キャッシュリセット
    static void ResetAllCaches()
    {
        g_EquitySufficientCache = true;
        g_LastEquityCheckTime = 0;
        
        for(int i = 0; i < 2; i++)
        {
            g_TimeAllowedCache[i] = true;
            g_LastTimeAllowedCheckTime[i] = 0;
            g_InitialTimeAllowedCache[i] = true;
            g_LastInitialTimeAllowedCheckTime[i] = 0;
        }
    }
};

//+------------------------------------------------------------------+
//| ロット管理クラス                                                 |
//+------------------------------------------------------------------+
class CLotManager
{
private:
    bool m_individualLotEnabled;
    double m_initialLot;
    double m_lotMultiplier;
    
public:
    CLotManager()
    {
        m_individualLotEnabled = false;
        m_initialLot = 0.01;
        m_lotMultiplier = 1.5;
    }
    
    void SetIndividualLotEnabled(bool enabled) { m_individualLotEnabled = enabled; }
    void SetInitialLot(double lot) { m_initialLot = lot; }
    void SetLotMultiplier(double multiplier) { m_lotMultiplier = multiplier; }
    
    // ロットテーブル初期化
    void InitializeLotTable(double lots[])
    {
        if(m_individualLotEnabled)
        {
            Print("個別指定ロットモードが有効です");
            // 個別ロット値は外部から設定される想定
        }
        else
        {
            Print("マーチンゲール方式でロット計算します - 初期ロット: ", m_initialLot, 
                  ", 倍率: ", m_lotMultiplier);
            
            g_LotTable[0] = m_initialLot;
            for(int i = 1; i < MAX_POSITIONS; i++)
            {
                double nextLot = g_LotTable[i-1] * m_lotMultiplier;
                nextLot = MathCeil(nextLot * 1000) / 1000;
                g_LotTable[i] = nextLot;
            }
        }
        
        // ログ出力
        string lotTableStr = "LOTテーブル詳細: \n";
        for(int i = 0; i < 10; i++)
        {
            lotTableStr += "レベル " + IntegerToString(i+1) + ": " + 
                          DoubleToString(g_LotTable[i], 3) + "\n";
        }
        Print(lotTableStr);
    }
    
    // レベルに応じたロット取得
    double GetLotByLevel(int level)
    {
        if(level < 1) level = 1;
        if(level > MAX_POSITIONS) level = MAX_POSITIONS;
        
        return g_LotTable[level - 1];
    }
};

//+------------------------------------------------------------------+
//| ゴーストポジション管理クラス                                     |
//+------------------------------------------------------------------+
class CGhostManager
{
public:
    // ゴーストポジション初期化
    static void InitializeGhostPosition(int type, string comment = "")
    {
        double price = (type == 0) ? g_Trading.GetAskPrice() : g_Trading.GetBidPrice();
        datetime now = TimeCurrent();
        
        if(type == 0) // Buy
        {
            if(g_GhostBuyCount < MAX_POSITIONS)
            {
                g_GhostBuyPositions[g_GhostBuyCount].isGhost = true;
                g_GhostBuyPositions[g_GhostBuyCount].price = price;
                g_GhostBuyPositions[g_GhostBuyCount].lots = g_LotTable[g_GhostBuyCount];
                g_GhostBuyPositions[g_GhostBuyCount].openTime = now;
                g_GhostBuyPositions[g_GhostBuyCount].comment = comment;
                g_GhostBuyCount++;
                
                Print("ゴーストBuyポジション追加: Count=", g_GhostBuyCount, 
                      ", Price=", price, ", Lot=", g_LotTable[g_GhostBuyCount-1]);
            }
        }
        else // Sell
        {
            if(g_GhostSellCount < MAX_POSITIONS)
            {
                g_GhostSellPositions[g_GhostSellCount].isGhost = true;
                g_GhostSellPositions[g_GhostSellCount].price = price;
                g_GhostSellPositions[g_GhostSellCount].lots = g_LotTable[g_GhostSellCount];
                g_GhostSellPositions[g_GhostSellCount].openTime = now;
                g_GhostSellPositions[g_GhostSellCount].comment = comment;
                g_GhostSellCount++;
                
                Print("ゴーストSellポジション追加: Count=", g_GhostSellCount, 
                      ", Price=", price, ", Lot=", g_LotTable[g_GhostSellCount-1]);
            }
        }
        
        SaveGhostPositionsToGlobal();
    }
    
    // ゴーストポジションリセット
    static void ResetGhost(int type)
    {
        if(type == 0) // Buy
        {
            for(int i = 0; i < MAX_POSITIONS; i++)
            {
                g_GhostBuyPositions[i].isGhost = false;
                g_GhostBuyPositions[i].price = 0;
                g_GhostBuyPositions[i].lots = 0;
                g_GhostBuyPositions[i].openTime = 0;
                g_GhostBuyPositions[i].comment = "";
            }
            g_GhostBuyCount = 0;
            g_BuyGhostClosed = false;
        }
        else // Sell
        {
            for(int i = 0; i < MAX_POSITIONS; i++)
            {
                g_GhostSellPositions[i].isGhost = false;
                g_GhostSellPositions[i].price = 0;
                g_GhostSellPositions[i].lots = 0;
                g_GhostSellPositions[i].openTime = 0;
                g_GhostSellPositions[i].comment = "";
            }
            g_GhostSellCount = 0;
            g_SellGhostClosed = false;
        }
        
        SaveGhostPositionsToGlobal();
    }
    
    // ゴーストポジション数取得
    static int GetGhostCount(int type)
    {
        return (type == 0) ? g_GhostBuyCount : g_GhostSellCount;
    }
    
    // ゴーストポジションの平均価格計算
    static double GetGhostAveragePrice(int type)
    {
        double totalLots = 0;
        double weightedPrice = 0;
        
        if(type == 0) // Buy
        {
            for(int i = 0; i < g_GhostBuyCount; i++)
            {
                if(g_GhostBuyPositions[i].isGhost)
                {
                    totalLots += g_GhostBuyPositions[i].lots;
                    weightedPrice += g_GhostBuyPositions[i].price * g_GhostBuyPositions[i].lots;
                }
            }
        }
        else // Sell
        {
            for(int i = 0; i < g_GhostSellCount; i++)
            {
                if(g_GhostSellPositions[i].isGhost)
                {
                    totalLots += g_GhostSellPositions[i].lots;
                    weightedPrice += g_GhostSellPositions[i].price * g_GhostSellPositions[i].lots;
                }
            }
        }
        
        return (totalLots > 0) ? weightedPrice / totalLots : 0;
    }
    
    // グローバル変数への保存
    static void SaveGhostPositionsToGlobal()
    {
        string prefix = "GHOST_" + Symbol() + "_" + IntegerToString(MagicNumber) + "_";
        
        // Buy側
        GlobalVariableSet(prefix + "BuyCount", g_GhostBuyCount);
        GlobalVariableSet(prefix + "BuyClosed", g_BuyGhostClosed ? 1 : 0);
        
        for(int i = 0; i < g_GhostBuyCount; i++)
        {
            string base = prefix + "Buy" + IntegerToString(i) + "_";
            GlobalVariableSet(base + "Price", g_GhostBuyPositions[i].price);
            GlobalVariableSet(base + "Lots", g_GhostBuyPositions[i].lots);
            GlobalVariableSet(base + "Time", (double)g_GhostBuyPositions[i].openTime);
        }
        
        // Sell側
        GlobalVariableSet(prefix + "SellCount", g_GhostSellCount);
        GlobalVariableSet(prefix + "SellClosed", g_SellGhostClosed ? 1 : 0);
        
        for(int i = 0; i < g_GhostSellCount; i++)
        {
            string base = prefix + "Sell" + IntegerToString(i) + "_";
            GlobalVariableSet(base + "Price", g_GhostSellPositions[i].price);
            GlobalVariableSet(base + "Lots", g_GhostSellPositions[i].lots);
            GlobalVariableSet(base + "Time", (double)g_GhostSellPositions[i].openTime);
        }
    }
    
    // グローバル変数から読み込み
    static void LoadGhostPositionsFromGlobal()
    {
        string prefix = "GHOST_" + Symbol() + "_" + IntegerToString(MagicNumber) + "_";
        
        // Buy側
        if(GlobalVariableCheck(prefix + "BuyCount"))
        {
            g_GhostBuyCount = (int)GlobalVariableGet(prefix + "BuyCount");
            g_BuyGhostClosed = (GlobalVariableGet(prefix + "BuyClosed") == 1);
            
            for(int i = 0; i < g_GhostBuyCount; i++)
            {
                string base = prefix + "Buy" + IntegerToString(i) + "_";
                g_GhostBuyPositions[i].isGhost = true;
                g_GhostBuyPositions[i].price = GlobalVariableGet(base + "Price");
                g_GhostBuyPositions[i].lots = GlobalVariableGet(base + "Lots");
                g_GhostBuyPositions[i].openTime = (datetime)GlobalVariableGet(base + "Time");
            }
        }
        
        // Sell側
        if(GlobalVariableCheck(prefix + "SellCount"))
        {
            g_GhostSellCount = (int)GlobalVariableGet(prefix + "SellCount");
            g_SellGhostClosed = (GlobalVariableGet(prefix + "SellClosed") == 1);
            
            for(int i = 0; i < g_GhostSellCount; i++)
            {
                string base = prefix + "Sell" + IntegerToString(i) + "_";
                g_GhostSellPositions[i].isGhost = true;
                g_GhostSellPositions[i].price = GlobalVariableGet(base + "Price");
                g_GhostSellPositions[i].lots = GlobalVariableGet(base + "Lots");
                g_GhostSellPositions[i].openTime = (datetime)GlobalVariableGet(base + "Time");
            }
        }
    }
    
    // グローバル変数からクリア
    static void ClearGhostPositionsFromGlobal()
    {
        string prefix = "GHOST_" + Symbol() + "_" + IntegerToString(MagicNumber) + "_";
        
        // 関連するすべてのグローバル変数を削除
        int total = GlobalVariablesTotal();
        for(int i = total - 1; i >= 0; i--)
        {
            string name = GlobalVariableName(i);
            if(StringFind(name, prefix) == 0)
            {
                GlobalVariableDel(name);
            }
        }
    }
};

//+------------------------------------------------------------------+
//| オブジェクト管理クラス                                           |
//+------------------------------------------------------------------+
class CObjectManager
{
public:
    // オブジェクト名保存
    static void SaveObjectName(string name, string &nameArray[], int &counter)
    {
        if(counter < MAX_OBJECTS)
        {
            nameArray[counter] = name;
            counter++;
        }
    }
    
    // プレフィックス設定
    static void SetObjectPrefix(string prefix)
    {
        g_ObjectPrefix = prefix;
    }
    
    // すべてのオブジェクトを削除
    static void DeleteAllObjects()
    {
        // ラインオブジェクト
        for(int i = 0; i < g_LineObjectCount; i++)
        {
            if(ObjectFind(0, g_LineNames[i]) >= 0)
                ObjectDelete(0, g_LineNames[i]);
        }
        g_LineObjectCount = 0;
        
        // パネルオブジェクト
        for(int i = 0; i < g_PanelObjectCount; i++)
        {
            if(ObjectFind(0, g_PanelNames[i]) >= 0)
                ObjectDelete(0, g_PanelNames[i]);
        }
        g_PanelObjectCount = 0;
        
        // テーブルオブジェクト
        for(int i = 0; i < g_TableObjectCount; i++)
        {
            if(ObjectFind(0, g_TableNames[i]) >= 0)
                ObjectDelete(0, g_TableNames[i]);
        }
        g_TableObjectCount = 0;
        
        ChartRedraw(0);
    }
    
    // 特定タイプのオブジェクトを削除
    static void DeleteObjectsByType(string type)
    {
        int total = ObjectsTotal(0);
        for(int i = total - 1; i >= 0; i--)
        {
            string name = ObjectName(0, i);
            
            // プレフィックスチェック
            if(StringFind(name, g_ObjectPrefix) != 0) 
                continue;
            
            // タイプチェック
            if(StringFind(name, type) >= 0)
            {
                ObjectDelete(0, name);
            }
        }
        ChartRedraw(0);
    }
    
    // ゴーストオブジェクトを削除
    static void DeleteAllGhostObjects(int type)
    {
        string direction = (type == 0) ? "Buy" : "Sell";
        string searchPattern = g_ObjectPrefix + "Ghost" + direction;
        
        int total = ObjectsTotal(0);
        for(int i = total - 1; i >= 0; i--)
        {
            string name = ObjectName(0, i);
            if(StringFind(name, searchPattern) >= 0)
            {
                ObjectDelete(0, name);
            }
        }
        ChartRedraw(0);
    }
};

//+------------------------------------------------------------------+
//| 色操作クラス                                                     |
//+------------------------------------------------------------------+
class CColorUtils
{
public:
    // 色を暗くする
    static color Darken(color clr, int percent)
    {
        int r = (clr & 0xFF0000) >> 16;
        int g = (clr & 0x00FF00) >> 8;
        int b = (clr & 0x0000FF);
        
        r = MathMax(0, r - r * percent / 100);
        g = MathMax(0, g - g * percent / 100);
        b = MathMax(0, b - b * percent / 100);
        
        return (color)((r << 16) + (g << 8) + b);
    }
    
    // 色を明るくする
    static color Lighten(color clr, int percent)
    {
        int r = (clr & 0xFF0000) >> 16;
        int g = (clr & 0x00FF00) >> 8;
        int b = (clr & 0x0000FF);
        
        r = MathMin(255, r + (255 - r) * percent / 100);
        g = MathMin(255, g + (255 - g) * percent / 100);
        b = MathMin(255, b + (255 - b) * percent / 100);
        
        return (color)((r << 16) + (g << 8) + b);
    }
};

//+------------------------------------------------------------------+
//| エントリー管理クラス                                             |
//+------------------------------------------------------------------+
class CEntryManager
{
private:
    static PROTECTION_MODE m_protectionMode;
    static bool m_enableCloseInterval;
    static int m_closeInterval;
    
public:
    // 保護モード設定
    static void SetProtectionMode(PROTECTION_MODE mode) { m_protectionMode = mode; }
    static PROTECTION_MODE GetProtectionMode() { return m_protectionMode; }
    
    // 決済後インターバル設定
    static void SetCloseInterval(bool enable, int minutes) 
    { 
        m_enableCloseInterval = enable;
        m_closeInterval = minutes;
    }
    
    // エントリー許可チェック（保護モード）
    static bool IsEntryAllowedByProtection(int side)
    {
        if(m_protectionMode == PROTECTION_OFF)
            return true;
        
        // 反対側のポジションチェック
        ENUM_POSITION_TYPE oppositeType = (side == 0) ? POSITION_TYPE_SELL : POSITION_TYPE_BUY;
        
        int realCount = g_Trading.PositionCount(oppositeType);
        int ghostCount = CGhostManager::GetGhostCount(oppositeType == POSITION_TYPE_BUY ? 0 : 1);
        
        return (realCount == 0 && ghostCount == 0);
    }
    
    // 決済後インターバルチェック
    static bool IsCloseIntervalElapsed(int side)
    {
        if(!m_enableCloseInterval || m_closeInterval <= 0)
            return true;
        
        datetime currentTime = TimeCurrent();
        
        if(side == 0) // Buy
        {
            if(g_BuyClosedRecently)
            {
                int elapsedMinutes = (int)((currentTime - g_BuyClosedTime) / 60);
                if(elapsedMinutes < m_closeInterval)
                {
                    Print("Buy側決済後インターバル中: 経過時間=", elapsedMinutes, 
                          "分, 設定=", m_closeInterval, "分");
                    return false;
                }
                g_BuyClosedRecently = false;
            }
        }
        else // Sell
        {
            if(g_SellClosedRecently)
            {
                int elapsedMinutes = (int)((currentTime - g_SellClosedTime) / 60);
                if(elapsedMinutes < m_closeInterval)
                {
                    Print("Sell側決済後インターバル中: 経過時間=", elapsedMinutes, 
                          "分, 設定=", m_closeInterval, "分");
                    return false;
                }
                g_SellClosedRecently = false;
            }
        }
        
        return true;
    }
    
    // 決済記録
    static void RecordClose(int side)
    {
        datetime currentTime = TimeCurrent();
        
        if(side == 0) // Buy
        {
            g_BuyClosedRecently = true;
            g_BuyClosedTime = currentTime;
        }
        else // Sell
        {
            g_SellClosedRecently = true;
            g_SellClosedTime = currentTime;
        }
    }
    
    // 保護モードテキスト取得
    static string GetProtectionModeText()
    {
        return (m_protectionMode == PROTECTION_OFF) ? "両建て許可" : "単方向のみ許可";
    }
};

// static変数の初期化
PROTECTION_MODE CEntryManager::m_protectionMode = PROTECTION_OFF;
bool CEntryManager::m_enableCloseInterval = false;
int CEntryManager::m_closeInterval = 0;

//+------------------------------------------------------------------+
//| ログ管理クラス                                                   |
//+------------------------------------------------------------------+
class CLogManager
{
private:
    static string m_logFileName;
    static bool m_enableLogging;
    static int m_logLevel;
    
public:
    enum LOG_LEVEL
    {
        LOG_ERROR = 0,
        LOG_WARNING = 1,
        LOG_INFO = 2,
        LOG_DEBUG = 3
    };
    
    // 初期化
    static void Initialize(string fileName, bool enable = true, int level = LOG_INFO)
    {
        m_logFileName = fileName;
        m_enableLogging = enable;
        m_logLevel = level;
    }
    
    // ログ出力
    static void Log(string message, LOG_LEVEL level = LOG_INFO)
    {
        if(!m_enableLogging || level > m_logLevel)
            return;
        
        string levelStr = "";
        switch(level)
        {
            case LOG_ERROR: levelStr = "[ERROR]"; break;
            case LOG_WARNING: levelStr = "[WARNING]"; break;
            case LOG_INFO: levelStr = "[INFO]"; break;
            case LOG_DEBUG: levelStr = "[DEBUG]"; break;
        }
        
        string timestamp = TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS);
        string logMessage = timestamp + " " + levelStr + " " + message;
        
        // コンソールに出力
        Print(logMessage);
        
        // ファイルに出力
        if(m_logFileName != "")
        {
            int handle = FileOpen(m_logFileName, FILE_WRITE|FILE_READ|FILE_TXT|FILE_SHARE_READ, ';');
            if(handle != INVALID_HANDLE)
            {
                FileSeek(handle, 0, SEEK_END);
                FileWriteString(handle, logMessage + "\n");
                FileClose(handle);
            }
        }
    }
    
    // エントリー理由をログ
    static void LogEntryReason(int type, string strategy, string reason)
    {
        string typeStr = (type == 0) ? "BUY" : "SELL";
        string message = StringFormat("Entry: %s | Strategy: %s | Reason: %s", 
                                     typeStr, strategy, reason);
        Log(message, LOG_INFO);
    }
    
    // 決済理由をログ
    static void LogCloseReason(int type, string reason, double profit)
    {
        string typeStr = (type == 0) ? "BUY" : "SELL";
        string message = StringFormat("Close: %s | Reason: %s | Profit: %.2f", 
                                     typeStr, reason, profit);
        Log(message, LOG_INFO);
    }
};

// static変数の初期化
string CLogManager::m_logFileName = "";
bool CLogManager::m_enableLogging = true;
int CLogManager::m_logLevel = CLogManager::LOG_INFO;

//+------------------------------------------------------------------+
//| 数値フォーマットクラス                                           |
//+------------------------------------------------------------------+
class CFormatUtils
{
public:
    // 金額フォーマット
    static string FormatMoney(double value, string currency = "")
    {
        string sign = value < 0 ? "-" : "";
        value = MathAbs(value);
        
        string formatted = DoubleToString(value, 2);
        
        // 3桁ごとにカンマを挿入
        int dotPos = StringFind(formatted, ".");
        if(dotPos < 0) dotPos = StringLen(formatted);
        
        string intPart = StringSubstr(formatted, 0, dotPos);
        string decPart = dotPos < StringLen(formatted) ? StringSubstr(formatted, dotPos) : "";
        
        string result = "";
        int count = 0;
        for(int i = StringLen(intPart) - 1; i >= 0; i--)
        {
            if(count > 0 && count % 3 == 0)
                result = "," + result;
            result = StringSubstr(intPart, i, 1) + result;
            count++;
        }
        
        result = sign + result + decPart;
        
        if(currency != "")
            result = currency + " " + result;
        
        return result;
    }
    
    // パーセンテージフォーマット
    static string FormatPercent(double value, int digits = 2)
    {
        return DoubleToString(value, digits) + "%";
    }
    
    // 時間フォーマット
    static string FormatTime(datetime time, bool includeSeconds = false)
    {
        if(includeSeconds)
            return TimeToString(time, TIME_DATE|TIME_SECONDS);
        else
            return TimeToString(time, TIME_DATE|TIME_MINUTES);
    }
    
    // ピップスフォーマット
    static string FormatPips(double pips)
    {
        return DoubleToString(pips, 1) + " pips";
    }
};

//+------------------------------------------------------------------+
//| 配列操作ユーティリティ                                           |
//+------------------------------------------------------------------+
class CArrayUtils
{
public:
    // 配列の最大値を取得
    template<typename T>
    static T ArrayMax(const T &array[])
    {
        if(ArraySize(array) == 0) return 0;
        
        T maxValue = array[0];
        for(int i = 1; i < ArraySize(array); i++)
        {
            if(array[i] > maxValue)
                maxValue = array[i];
        }
        return maxValue;
    }
    
    // 配列の最小値を取得
    template<typename T>
    static T ArrayMin(const T &array[])
    {
        if(ArraySize(array) == 0) return 0;
        
        T minValue = array[0];
        for(int i = 1; i < ArraySize(array); i++)
        {
            if(array[i] < minValue)
                minValue = array[i];
        }
        return minValue;
    }
    
    // 配列の合計を取得
    template<typename T>
    static T ArraySum(const T &array[])
    {
        T sum = 0;
        for(int i = 0; i < ArraySize(array); i++)
        {
            sum += array[i];
        }
        return sum;
    }
    
    // 配列の平均を取得
    template<typename T>
    static double ArrayAverage(const T &array[])
    {
        if(ArraySize(array) == 0) return 0;
        return (double)ArraySum(array) / ArraySize(array);
    }
};

//+------------------------------------------------------------------+
//| 文字列操作ユーティリティ                                         |
//+------------------------------------------------------------------+
class CStringUtils
{
public:
    // 文字列の置換
    static string Replace(string text, string find, string replace)
    {
        string result = text;
        int pos = 0;
        
        while((pos = StringFind(result, find, pos)) >= 0)
        {
            result = StringSubstr(result, 0, pos) + replace + 
                    StringSubstr(result, pos + StringLen(find));
            pos += StringLen(replace);
        }
        
        return result;
    }
    
    // 文字列のトリム
    static string Trim(string text)
    {
        int start = 0;
        int end = StringLen(text) - 1;
        
        // 先頭の空白を削除
        while(start <= end && StringGetCharacter(text, start) == ' ')
            start++;
        
        // 末尾の空白を削除
        while(end >= start && StringGetCharacter(text, end) == ' ')
            end--;
        
        if(start > end) return "";
        
        return StringSubstr(text, start, end - start + 1);
    }
    
    // 文字列を大文字に変換
    static string ToUpper(string text)
    {
        string result = text;
        StringToUpper(result);
        return result;
    }
    
    // 文字列を小文字に変換
    static string ToLower(string text)
    {
        string result = text;
        StringToLower(result);
        return result;
    }
};

//+------------------------------------------------------------------+
//| グローバルユーティリティオブジェクト                             |
//+------------------------------------------------------------------+
CTimeManager* g_TimeManager = NULL;
CLotManager* g_LotManager = NULL;

//+------------------------------------------------------------------+
//| ユーティリティの初期化                                           |
//+------------------------------------------------------------------+
void InitializeUtils()
{
    // タイムマネージャー作成
    if(g_TimeManager == NULL)
        g_TimeManager = new CTimeManager();
    
    // ロットマネージャー作成
    if(g_LotManager == NULL)
        g_LotManager = new CLotManager();
    
    // オブジェクトプレフィックス設定
    CObjectManager::SetObjectPrefix("UNI_" + Symbol() + "_" + IntegerToString(MagicNumber) + "_");
    
    // ログマネージャー初期化
    string logFile = "UnifiedEA_" + Symbol() + "_" + IntegerToString(MagicNumber) + ".log";
    CLogManager::Initialize(logFile, true, CLogManager::LOG_INFO);
    
    // ゴーストポジションをグローバル変数から読み込み
    CGhostManager::LoadGhostPositionsFromGlobal();
    
    // キャッシュリセット
    CCacheManager::ResetAllCaches();
}

//+------------------------------------------------------------------+
//| ユーティリティのクリーンアップ                                   |
//+------------------------------------------------------------------+
void CleanupUtils()
{
    // ゴーストポジションを保存
    CGhostManager::SaveGhostPositionsToGlobal();
    
    // オブジェクト削除
    CObjectManager::DeleteAllObjects();
    
    // タイムマネージャー削除
    if(g_TimeManager != NULL)
    {
        delete g_TimeManager;
        g_TimeManager = NULL;
    }
    
    // ロットマネージャー削除
    if(g_LotManager != NULL)
    {
        delete g_LotManager;
        g_LotManager = NULL;
    }
}

//+------------------------------------------------------------------+
//| 便利な関数マクロ                                                 |
//+------------------------------------------------------------------+
// 現在時間取得
#define GetCurrentTime() (g_TimeManager != NULL ? g_TimeManager.GetCurrentTime() : TimeCurrent())

// ログ出力
#define LogInfo(msg) CLogManager::Log(msg, CLogManager::LOG_INFO)
#define LogError(msg) CLogManager::Log(msg, CLogManager::LOG_ERROR)
#define LogDebug(msg) CLogManager::Log(msg, CLogManager::LOG_DEBUG)

// エントリー許可チェック
#define IsEntryAllowed(side) (CEntryManager::IsEntryAllowedByProtection(side) && \
                             CEntryManager::IsCloseIntervalElapsed(side))

// ゴースト関連
#define AddGhostPosition(type, comment) CGhostManager::InitializeGhostPosition(type, comment)
#define ResetGhostPositions(type) CGhostManager::ResetGhost(type)
#define GetGhostPositionCount(type) CGhostManager::GetGhostCount(type)