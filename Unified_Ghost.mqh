//+------------------------------------------------------------------+
//|                       Unified_Ghost.mqh                          |
//|          MQL4/MQL5 統合ゴースト管理ライブラリ                    |
//|                     Copyright 2025                               |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025"
#property version   "1.00"

#include "Unified_Trading.mqh"
#include "Unified_Utils.mqh"

//+------------------------------------------------------------------+
//| ゴースト関連の定数定義                                           |
//+------------------------------------------------------------------+
#define MAX_GHOST_POSITIONS  40
#define GHOST_LINE_STYLE     STYLE_DOT
#define GHOST_LINE_WIDTH     1

// ゴーストポジション構造体
struct GhostPositionInfo
{
    int      type;           // OP_BUY/OP_SELL
    double   lots;           // ロットサイズ
    string   symbol;         // 通貨ペア
    double   price;          // エントリー価格
    double   profit;         // 仮想損益
    datetime openTime;       // エントリー時間
    bool     isActive;       // アクティブフラグ
    int      level;          // ポジションレベル
    double   stopLoss;       // ストップロス価格
    string   comment;        // コメント
};

//+------------------------------------------------------------------+
//| ゴースト管理クラス                                               |
//+------------------------------------------------------------------+
class CUnifiedGhost
{
private:
    // ゴーストポジション配列
    GhostPositionInfo m_buyGhosts[MAX_GHOST_POSITIONS];
    GhostPositionInfo m_sellGhosts[MAX_GHOST_POSITIONS];
    int m_buyGhostCount;
    int m_sellGhostCount;
    
    // 決済フラグ
    bool m_buyGhostClosed;
    bool m_sellGhostClosed;
    
    // 設定
    string m_symbol;
    int m_magic;
    string m_objectPrefix;
    string m_globalPrefix;
    
    // 色設定
    color m_buyColor;
    color m_sellColor;
    color m_ghostBuyColor;
    color m_ghostSellColor;
    
    // 表示設定
    bool m_showGhostLines;
    bool m_showGhostArrows;
    
public:
    CUnifiedGhost();
    ~CUnifiedGhost();
    
    // 初期化
    void Init(string symbol, int magic, string prefix);
    void SetColors(color buyColor, color sellColor, color ghostBuyColor, color ghostSellColor);
    void SetDisplayOptions(bool showLines, bool showArrows);
    
    // ゴーストポジション管理
    bool AddGhostPosition(ENUM_POSITION_TYPE type, double lots, double price, string comment = "");
    bool RemoveGhostPosition(ENUM_POSITION_TYPE type, int index);
    void ResetGhosts(ENUM_POSITION_TYPE type);
    void ResetAllGhosts();
    
    // ゴースト情報取得
    int GetGhostCount(ENUM_POSITION_TYPE type);
    double GetGhostAveragePrice(ENUM_POSITION_TYPE type);
    double GetGhostTotalLots(ENUM_POSITION_TYPE type);
    double GetGhostProfit(ENUM_POSITION_TYPE type);
    double GetLastGhostPrice(ENUM_POSITION_TYPE type);
    GhostPositionInfo GetGhostInfo(ENUM_POSITION_TYPE type, int index);
    
    // 表示管理
    void UpdateGhostDisplay();
    void CreateGhostEntryPoint(ENUM_POSITION_TYPE type, double price, double lots, int level, datetime time);
    void CreateGhostLine(ENUM_POSITION_TYPE type, double price, int level);
    void DeleteGhostObjects(ENUM_POSITION_TYPE type);
    void DeleteAllGhostObjects();
    
    // ストップロス管理
    void UpdateGhostStopLoss(ENUM_POSITION_TYPE type, double stopPrice);
    bool CheckGhostStopLossHit(ENUM_POSITION_TYPE type);
    
    // 永続化
    void SaveToGlobalVariables();
    bool LoadFromGlobalVariables();
    void ClearGlobalVariables();
    
    // ユーティリティ
    bool IsGhostClosed(ENUM_POSITION_TYPE type);
    void SetGhostClosed(ENUM_POSITION_TYPE type, bool closed);
    string GetUniqueObjectName(string baseName);
    
private:
    // 内部ヘルパー関数
    void CreateLine(string name, double price, color clr, int style, int width);
    void CreateArrow(string name, datetime time, double price, int code, color clr, int size);
    void CreateText(string name, datetime time, double price, string text, color clr, int fontSize);
    color DarkenColor(color clr, int percent);
    double CalculateTickValue();
};

//+------------------------------------------------------------------+
//| コンストラクタ                                                   |
//+------------------------------------------------------------------+
CUnifiedGhost::CUnifiedGhost()
{
    m_buyGhostCount = 0;
    m_sellGhostCount = 0;
    m_buyGhostClosed = false;
    m_sellGhostClosed = false;
    m_symbol = "";
    m_magic = 0;
    m_objectPrefix = "";
    m_globalPrefix = "";
    m_buyColor = clrDodgerBlue;
    m_sellColor = clrOrangeRed;
    m_ghostBuyColor = clrDeepSkyBlue;
    m_ghostSellColor = clrCrimson;
    m_showGhostLines = true;
    m_showGhostArrows = true;
    
    // 配列を初期化
    for(int i = 0; i < MAX_GHOST_POSITIONS; i++)
    {
        m_buyGhosts[i].isActive = false;
        m_sellGhosts[i].isActive = false;
    }
}

//+------------------------------------------------------------------+
//| デストラクタ                                                     |
//+------------------------------------------------------------------+
CUnifiedGhost::~CUnifiedGhost()
{
    SaveToGlobalVariables();
    DeleteAllGhostObjects();
}

//+------------------------------------------------------------------+
//| 初期化                                                          |
//+------------------------------------------------------------------+
void CUnifiedGhost::Init(string symbol, int magic, string prefix)
{
    m_symbol = (symbol == NULL || symbol == "") ? Symbol() : symbol;
    m_magic = magic;
    m_objectPrefix = prefix + "Ghost_";
    m_globalPrefix = m_symbol + "_" + IntegerToString(m_magic) + "_Ghost_";
    
    // 既存のゴーストポジション情報を読み込み
    LoadFromGlobalVariables();
}

//+------------------------------------------------------------------+
//| 色設定                                                          |
//+------------------------------------------------------------------+
void CUnifiedGhost::SetColors(color buyColor, color sellColor, color ghostBuyColor, color ghostSellColor)
{
    m_buyColor = buyColor;
    m_sellColor = sellColor;
    m_ghostBuyColor = ghostBuyColor;
    m_ghostSellColor = ghostSellColor;
}

//+------------------------------------------------------------------+
//| 表示オプション設定                                               |
//+------------------------------------------------------------------+
void CUnifiedGhost::SetDisplayOptions(bool showLines, bool showArrows)
{
    m_showGhostLines = showLines;
    m_showGhostArrows = showArrows;
}

//+------------------------------------------------------------------+
//| ゴーストポジション追加                                           |
//+------------------------------------------------------------------+
bool CUnifiedGhost::AddGhostPosition(ENUM_POSITION_TYPE type, double lots, double price, string comment)
{
    GhostPositionInfo* ghosts;
    int* count;
    
    if(type == POSITION_TYPE_BUY)
    {
        ghosts = m_buyGhosts;
        count = &m_buyGhostCount;
    }
    else
    {
        ghosts = m_sellGhosts;
        count = &m_sellGhostCount;
    }
    
    // 空きスロットを探す
    int freeSlot = -1;
    for(int i = 0; i < MAX_GHOST_POSITIONS; i++)
    {
        if(!ghosts[i].isActive)
        {
            freeSlot = i;
            break;
        }
    }
    
    if(freeSlot < 0)
    {
        Print("ゴーストポジションが最大数に達しています");
        return false;
    }
    
    // ゴーストポジション情報を設定
    ghosts[freeSlot].type = (type == POSITION_TYPE_BUY) ? OP_BUY : OP_SELL;
    ghosts[freeSlot].lots = lots;
    ghosts[freeSlot].symbol = m_symbol;
    ghosts[freeSlot].price = price;
    ghosts[freeSlot].profit = 0;
    ghosts[freeSlot].openTime = TimeCurrent();
    ghosts[freeSlot].isActive = true;
    ghosts[freeSlot].level = *count;
    ghosts[freeSlot].stopLoss = 0;
    ghosts[freeSlot].comment = comment;
    
    (*count)++;
    
    // 表示を更新
    CreateGhostEntryPoint(type, price, lots, ghosts[freeSlot].level, ghosts[freeSlot].openTime);
    CreateGhostLine(type, price, ghosts[freeSlot].level);
    
    // グローバル変数に保存
    SaveToGlobalVariables();
    
    Print("ゴースト", (type == POSITION_TYPE_BUY ? "Buy" : "Sell"), "追加: ",
          "レベル=", ghosts[freeSlot].level + 1, ", ロット=", lots, ", 価格=", price);
    
    return true;
}

//+------------------------------------------------------------------+
//| ゴーストポジション削除                                           |
//+------------------------------------------------------------------+
bool CUnifiedGhost::RemoveGhostPosition(ENUM_POSITION_TYPE type, int index)
{
    GhostPositionInfo* ghosts;
    int* count;
    
    if(type == POSITION_TYPE_BUY)
    {
        ghosts = m_buyGhosts;
        count = &m_buyGhostCount;
    }
    else
    {
        ghosts = m_sellGhosts;
        count = &m_sellGhostCount;
    }
    
    if(index < 0 || index >= MAX_GHOST_POSITIONS || !ghosts[index].isActive)
        return false;
    
    ghosts[index].isActive = false;
    (*count)--;
    
    // 表示を更新
    UpdateGhostDisplay();
    
    // グローバル変数に保存
    SaveToGlobalVariables();
    
    return true;
}

//+------------------------------------------------------------------+
//| ゴーストリセット                                                 |
//+------------------------------------------------------------------+
void CUnifiedGhost::ResetGhosts(ENUM_POSITION_TYPE type)
{
    if(type == POSITION_TYPE_BUY)
    {
        for(int i = 0; i < MAX_GHOST_POSITIONS; i++)
        {
            m_buyGhosts[i].isActive = false;
        }
        m_buyGhostCount = 0;
        m_buyGhostClosed = true;
        DeleteGhostObjects(type);
    }
    else
    {
        for(int i = 0; i < MAX_GHOST_POSITIONS; i++)
        {
            m_sellGhosts[i].isActive = false;
        }
        m_sellGhostCount = 0;
        m_sellGhostClosed = true;
        DeleteGhostObjects(type);
    }
    
    SaveToGlobalVariables();
}

//+------------------------------------------------------------------+
//| 全ゴーストリセット                                               |
//+------------------------------------------------------------------+
void CUnifiedGhost::ResetAllGhosts()
{
    ResetGhosts(POSITION_TYPE_BUY);
    ResetGhosts(POSITION_TYPE_SELL);
}

//+------------------------------------------------------------------+
//| ゴースト数取得                                                   |
//+------------------------------------------------------------------+
int CUnifiedGhost::GetGhostCount(ENUM_POSITION_TYPE type)
{
    return (type == POSITION_TYPE_BUY) ? m_buyGhostCount : m_sellGhostCount;
}

//+------------------------------------------------------------------+
//| ゴースト平均価格計算                                             |
//+------------------------------------------------------------------+
double CUnifiedGhost::GetGhostAveragePrice(ENUM_POSITION_TYPE type)
{
    GhostPositionInfo* ghosts = (type == POSITION_TYPE_BUY) ? m_buyGhosts : m_sellGhosts;
    
    double totalLots = 0;
    double weightedPrice = 0;
    
    for(int i = 0; i < MAX_GHOST_POSITIONS; i++)
    {
        if(ghosts[i].isActive)
        {
            totalLots += ghosts[i].lots;
            weightedPrice += ghosts[i].price * ghosts[i].lots;
        }
    }
    
    return (totalLots > 0) ? weightedPrice / totalLots : 0;
}

//+------------------------------------------------------------------+
//| ゴースト合計ロット数取得                                         |
//+------------------------------------------------------------------+
double CUnifiedGhost::GetGhostTotalLots(ENUM_POSITION_TYPE type)
{
    GhostPositionInfo* ghosts = (type == POSITION_TYPE_BUY) ? m_buyGhosts : m_sellGhosts;
    
    double totalLots = 0;
    
    for(int i = 0; i < MAX_GHOST_POSITIONS; i++)
    {
        if(ghosts[i].isActive)
        {
            totalLots += ghosts[i].lots;
        }
    }
    
    return totalLots;
}

//+------------------------------------------------------------------+
//| ゴースト損益計算                                                 |
//+------------------------------------------------------------------+
double CUnifiedGhost::GetGhostProfit(ENUM_POSITION_TYPE type)
{
    GhostPositionInfo* ghosts = (type == POSITION_TYPE_BUY) ? m_buyGhosts : m_sellGhosts;
    
    double totalProfit = 0;
    double tickValue = CalculateTickValue();
    
    #ifdef __MQL5__
    double currentBid = SymbolInfoDouble(m_symbol, SYMBOL_BID);
    double currentAsk = SymbolInfoDouble(m_symbol, SYMBOL_ASK);
    double point = SymbolInfoDouble(m_symbol, SYMBOL_POINT);
    #else
    double currentBid = MarketInfo(m_symbol, MODE_BID);
    double currentAsk = MarketInfo(m_symbol, MODE_ASK);
    double point = MarketInfo(m_symbol, MODE_POINT);
    #endif
    
    for(int i = 0; i < MAX_GHOST_POSITIONS; i++)
    {
        if(ghosts[i].isActive)
        {
            double profit;
            if(type == POSITION_TYPE_BUY)
            {
                profit = (currentBid - ghosts[i].price) * ghosts[i].lots * tickValue / point;
            }
            else
            {
                profit = (ghosts[i].price - currentAsk) * ghosts[i].lots * tickValue / point;
            }
            totalProfit += profit;
        }
    }
    
    return totalProfit;
}

//+------------------------------------------------------------------+
//| 最後のゴースト価格取得                                           |
//+------------------------------------------------------------------+
double CUnifiedGhost::GetLastGhostPrice(ENUM_POSITION_TYPE type)
{
    GhostPositionInfo* ghosts = (type == POSITION_TYPE_BUY) ? m_buyGhosts : m_sellGhosts;
    
    double lastPrice = 0;
    datetime lastTime = 0;
    
    for(int i = 0; i < MAX_GHOST_POSITIONS; i++)
    {
        if(ghosts[i].isActive && ghosts[i].openTime > lastTime)
        {
            lastTime = ghosts[i].openTime;
            lastPrice = ghosts[i].price;
        }
    }
    
    return lastPrice;
}

//+------------------------------------------------------------------+
//| ゴースト情報取得                                                 |
//+------------------------------------------------------------------+
GhostPositionInfo CUnifiedGhost::GetGhostInfo(ENUM_POSITION_TYPE type, int index)
{
    GhostPositionInfo info;
    info.isActive = false;
    
    if(index < 0 || index >= MAX_GHOST_POSITIONS)
        return info;
    
    if(type == POSITION_TYPE_BUY)
        return m_buyGhosts[index];
    else
        return m_sellGhosts[index];
}

//+------------------------------------------------------------------+
//| ゴースト表示更新                                                 |
//+------------------------------------------------------------------+
void CUnifiedGhost::UpdateGhostDisplay()
{
    // 既存のオブジェクトを削除
    DeleteAllGhostObjects();
    
    // Buy側ゴーストを再描画
    for(int i = 0; i < MAX_GHOST_POSITIONS; i++)
    {
        if(m_buyGhosts[i].isActive)
        {
            if(m_showGhostArrows)
                CreateGhostEntryPoint(POSITION_TYPE_BUY, m_buyGhosts[i].price, 
                                    m_buyGhosts[i].lots, m_buyGhosts[i].level, 
                                    m_buyGhosts[i].openTime);
            if(m_showGhostLines)
                CreateGhostLine(POSITION_TYPE_BUY, m_buyGhosts[i].price, m_buyGhosts[i].level);
        }
    }
    
    // Sell側ゴーストを再描画
    for(int i = 0; i < MAX_GHOST_POSITIONS; i++)
    {
        if(m_sellGhosts[i].isActive)
        {
            if(m_showGhostArrows)
                CreateGhostEntryPoint(POSITION_TYPE_SELL, m_sellGhosts[i].price, 
                                    m_sellGhosts[i].lots, m_sellGhosts[i].level, 
                                    m_sellGhosts[i].openTime);
            if(m_showGhostLines)
                CreateGhostLine(POSITION_TYPE_SELL, m_sellGhosts[i].price, m_sellGhosts[i].level);
        }
    }
    
    ChartRedraw(0);
}

//+------------------------------------------------------------------+
//| ゴーストエントリーポイント作成                                   |
//+------------------------------------------------------------------+
void CUnifiedGhost::CreateGhostEntryPoint(ENUM_POSITION_TYPE type, double price, double lots, int level, datetime time)
{
    if(!m_showGhostArrows)
        return;
    
    string arrowName = GetUniqueObjectName("Entry_" + IntegerToString(level) + "_" + 
                                          (type == POSITION_TYPE_BUY ? "Buy" : "Sell"));
    string infoName = GetUniqueObjectName("Info_" + IntegerToString(level) + "_" + 
                                         (type == POSITION_TYPE_BUY ? "Buy" : "Sell"));
    
    // 矢印作成
    int arrowCode = (type == POSITION_TYPE_BUY) ? 233 : 234;
    color arrowColor = (type == POSITION_TYPE_BUY) ? m_ghostBuyColor : m_ghostSellColor;
    CreateArrow(arrowName, time, price, arrowCode, arrowColor, 3);
    
    // 情報テキスト作成
    string infoText = "G " + (type == POSITION_TYPE_BUY ? "Buy" : "Sell") + " " + DoubleToString(lots, 2);
    double textOffset = (type == POSITION_TYPE_BUY ? 20 : -20) * g_Trading.GetPoint();
    CreateText(infoName, time, price + textOffset, infoText, arrowColor, 8);
}

//+------------------------------------------------------------------+
//| ゴーストライン作成                                               |
//+------------------------------------------------------------------+
void CUnifiedGhost::CreateGhostLine(ENUM_POSITION_TYPE type, double price, int level)
{
    if(!m_showGhostLines)
        return;
    
    string lineName = GetUniqueObjectName("Line_" + IntegerToString(level) + "_" + 
                                         (type == POSITION_TYPE_BUY ? "Buy" : "Sell"));
    
    color lineColor = (type == POSITION_TYPE_BUY) ? m_ghostBuyColor : m_ghostSellColor;
    CreateLine(lineName, price, lineColor, GHOST_LINE_STYLE, GHOST_LINE_WIDTH);
}

//+------------------------------------------------------------------+
//| ゴーストオブジェクト削除                                         |
//+------------------------------------------------------------------+
void CUnifiedGhost::DeleteGhostObjects(ENUM_POSITION_TYPE type)
{
    string typeStr = (type == POSITION_TYPE_BUY) ? "Buy" : "Sell";
    
    #ifdef __MQL5__
    int total = ObjectsTotal(0);
    for(int i = total - 1; i >= 0; i--)
    {
        string name = ObjectName(0, i);
        if(StringFind(name, m_objectPrefix) == 0 && StringFind(name, typeStr) >= 0)
        {
            ObjectDelete(0, name);
        }
    }
    #else
    int total = ObjectsTotal();
    for(int i = total - 1; i >= 0; i--)
    {
        string name = ObjectName(i);
        if(StringFind(name, m_objectPrefix) == 0 && StringFind(name, typeStr) >= 0)
        {
            ObjectDelete(name);
        }
    }
    #endif
    
    ChartRedraw(0);
}

//+------------------------------------------------------------------+
//| 全ゴーストオブジェクト削除                                       |
//+------------------------------------------------------------------+
void CUnifiedGhost::DeleteAllGhostObjects()
{
    #ifdef __MQL5__
    int total = ObjectsTotal(0);
    for(int i = total - 1; i >= 0; i--)
    {
        string name = ObjectName(0, i);
        if(StringFind(name, m_objectPrefix) == 0)
        {
            ObjectDelete(0, name);
        }
    }
    #else
    int total = ObjectsTotal();
    for(int i = total - 1; i >= 0; i--)
    {
        string name = ObjectName(i);
        if(StringFind(name, m_objectPrefix) == 0)
        {
            ObjectDelete(name);
        }
    }
    #endif
    
    ChartRedraw(0);
}

//+------------------------------------------------------------------+
//| ゴーストストップロス更新                                         |
//+------------------------------------------------------------------+
void CUnifiedGhost::UpdateGhostStopLoss(ENUM_POSITION_TYPE type, double stopPrice)
{
    GhostPositionInfo* ghosts = (type == POSITION_TYPE_BUY) ? m_buyGhosts : m_sellGhosts;
    
    for(int i = 0; i < MAX_GHOST_POSITIONS; i++)
    {
        if(ghosts[i].isActive)
        {
            ghosts[i].stopLoss = stopPrice;
        }
    }
    
    // ストップラインを表示
    string lineName = GetUniqueObjectName("StopLine_" + (type == POSITION_TYPE_BUY ? "Buy" : "Sell"));
    color lineColor = (type == POSITION_TYPE_BUY) ? clrPink : clrLightCoral;
    CreateLine(lineName, stopPrice, lineColor, STYLE_DASH, 2);
    
    SaveToGlobalVariables();
}

//+------------------------------------------------------------------+
//| ゴーストストップロスヒットチェック                               |
//+------------------------------------------------------------------+
bool CUnifiedGhost::CheckGhostStopLossHit(ENUM_POSITION_TYPE type)
{
    if(GetGhostCount(type) == 0)
        return false;
    
    GhostPositionInfo* ghosts = (type == POSITION_TYPE_BUY) ? m_buyGhosts : m_sellGhosts;
    
    #ifdef __MQL5__
    double currentBid = SymbolInfoDouble(m_symbol, SYMBOL_BID);
    double currentAsk = SymbolInfoDouble(m_symbol, SYMBOL_ASK);
    #else
    double currentBid = MarketInfo(m_symbol, MODE_BID);
    double currentAsk = MarketInfo(m_symbol, MODE_ASK);
    #endif
    
    double currentPrice = (type == POSITION_TYPE_BUY) ? currentBid : currentAsk;
    
    // 最も厳しいストップロスを探す
    double stopLevel = 0;
    bool hasStop = false;
    
    for(int i = 0; i < MAX_GHOST_POSITIONS; i++)
    {
        if(ghosts[i].isActive && ghosts[i].stopLoss > 0)
        {
            if(!hasStop)
            {
                stopLevel = ghosts[i].stopLoss;
                hasStop = true;
            }
            else
            {
                if(type == POSITION_TYPE_BUY && ghosts[i].stopLoss > stopLevel)
                    stopLevel = ghosts[i].stopLoss;
                else if(type == POSITION_TYPE_SELL && ghosts[i].stopLoss < stopLevel)
                    stopLevel = ghosts[i].stopLoss;
            }
        }
    }
    
    if(!hasStop)
        return false;
    
    // ストップロスヒット判定
    if(type == POSITION_TYPE_BUY && currentPrice <= stopLevel)
        return true;
    else if(type == POSITION_TYPE_SELL && currentPrice >= stopLevel)
        return true;
    
    return false;
}

//+------------------------------------------------------------------+
//| グローバル変数に保存                                             |
//+------------------------------------------------------------------+
void CUnifiedGhost::SaveToGlobalVariables()
{
    // カウンター保存
    GlobalVariableSet(m_globalPrefix + "BuyCount", m_buyGhostCount);
    GlobalVariableSet(m_globalPrefix + "SellCount", m_sellGhostCount);
    GlobalVariableSet(m_globalPrefix + "BuyClosed", m_buyGhostClosed ? 1 : 0);
    GlobalVariableSet(m_globalPrefix + "SellClosed", m_sellGhostClosed ? 1 : 0);
    
    // Buy側ゴースト保存
    int buyIndex = 0;
    for(int i = 0; i < MAX_GHOST_POSITIONS && buyIndex < m_buyGhostCount; i++)
    {
        if(m_buyGhosts[i].isActive)
        {
            string prefix = m_globalPrefix + "Buy_" + IntegerToString(buyIndex) + "_";
            GlobalVariableSet(prefix + "Lots", m_buyGhosts[i].lots);
            GlobalVariableSet(prefix + "Price", m_buyGhosts[i].price);
            GlobalVariableSet(prefix + "Time", (double)m_buyGhosts[i].openTime);
            GlobalVariableSet(prefix + "Level", m_buyGhosts[i].level);
            GlobalVariableSet(prefix + "StopLoss", m_buyGhosts[i].stopLoss);
            buyIndex++;
        }
    }
    
    // Sell側ゴースト保存
    int sellIndex = 0;
    for(int i = 0; i < MAX_GHOST_POSITIONS && sellIndex < m_sellGhostCount; i++)
    {
        if(m_sellGhosts[i].isActive)
        {
            string prefix = m_globalPrefix + "Sell_" + IntegerToString(sellIndex) + "_";
            GlobalVariableSet(prefix + "Lots", m_sellGhosts[i].lots);
            GlobalVariableSet(prefix + "Price", m_sellGhosts[i].price);
            GlobalVariableSet(prefix + "Time", (double)m_sellGhosts[i].openTime);
            GlobalVariableSet(prefix + "Level", m_sellGhosts[i].level);
            GlobalVariableSet(prefix + "StopLoss", m_sellGhosts[i].stopLoss);
            sellIndex++;
        }
    }
    
    GlobalVariableSet(m_globalPrefix + "SaveTime", (double)TimeCurrent());
}

//+------------------------------------------------------------------+
//| グローバル変数から読み込み                                       |
//+------------------------------------------------------------------+
bool CUnifiedGhost::LoadFromGlobalVariables()
{
    if(!GlobalVariableCheck(m_globalPrefix + "SaveTime"))
        return false;
    
    // カウンター読み込み
    m_buyGhostCount = (int)GlobalVariableGet(m_globalPrefix + "BuyCount");
    m_sellGhostCount = (int)GlobalVariableGet(m_globalPrefix + "SellCount");
    m_buyGhostClosed = GlobalVariableGet(m_globalPrefix + "BuyClosed") > 0;
    m_sellGhostClosed = GlobalVariableGet(m_globalPrefix + "SellClosed") > 0;
    
    // 配列を初期化
    for(int i = 0; i < MAX_GHOST_POSITIONS; i++)
    {
        m_buyGhosts[i].isActive = false;
        m_sellGhosts[i].isActive = false;
    }
    
    // Buy側ゴースト読み込み
    for(int i = 0; i < m_buyGhostCount; i++)
    {
        string prefix = m_globalPrefix + "Buy_" + IntegerToString(i) + "_";
        if(GlobalVariableCheck(prefix + "Lots"))
        {
            // 最初の空きスロットを探す
            for(int j = 0; j < MAX_GHOST_POSITIONS; j++)
            {
                if(!m_buyGhosts[j].isActive)
                {
                    m_buyGhosts[j].type = OP_BUY;
                    m_buyGhosts[j].lots = GlobalVariableGet(prefix + "Lots");
                    m_buyGhosts[j].symbol = m_symbol;
                    m_buyGhosts[j].price = GlobalVariableGet(prefix + "Price");
                    m_buyGhosts[j].profit = 0;
                    m_buyGhosts[j].openTime = (datetime)GlobalVariableGet(prefix + "Time");
                    m_buyGhosts[j].isActive = true;
                    m_buyGhosts[j].level = (int)GlobalVariableGet(prefix + "Level");
                    m_buyGhosts[j].stopLoss = GlobalVariableGet(prefix + "StopLoss");
                    m_buyGhosts[j].comment = "";
                    break;
                }
            }
        }
    }
    
    // Sell側ゴースト読み込み
    for(int i = 0; i < m_sellGhostCount; i++)
    {
        string prefix = m_globalPrefix + "Sell_" + IntegerToString(i) + "_";
        if(GlobalVariableCheck(prefix + "Lots"))
        {
            // 最初の空きスロットを探す
            for(int j = 0; j < MAX_GHOST_POSITIONS; j++)
            {
                if(!m_sellGhosts[j].isActive)
                {
                    m_sellGhosts[j].type = OP_SELL;
                    m_sellGhosts[j].lots = GlobalVariableGet(prefix + "Lots");
                    m_sellGhosts[j].symbol = m_symbol;
                    m_sellGhosts[j].price = GlobalVariableGet(prefix + "Price");
                    m_sellGhosts[j].profit = 0;
                    m_sellGhosts[j].openTime = (datetime)GlobalVariableGet(prefix + "Time");
                    m_sellGhosts[j].isActive = true;
                    m_sellGhosts[j].level = (int)GlobalVariableGet(prefix + "Level");
                    m_sellGhosts[j].stopLoss = GlobalVariableGet(prefix + "StopLoss");
                    m_sellGhosts[j].comment = "";
                    break;
                }
            }
        }
    }
    
    // 表示を更新
    UpdateGhostDisplay();
    
    return true;
}

//+------------------------------------------------------------------+
//| グローバル変数クリア                                             |
//+------------------------------------------------------------------+
void CUnifiedGhost::ClearGlobalVariables()
{
    int total = GlobalVariablesTotal();
    for(int i = total - 1; i >= 0; i--)
    {
        string name = GlobalVariableName(i);
        if(StringFind(name, m_globalPrefix) == 0)
        {
            GlobalVariableDel(name);
        }
    }
}

//+------------------------------------------------------------------+
//| ゴースト決済フラグ取得                                           |
//+------------------------------------------------------------------+
bool CUnifiedGhost::IsGhostClosed(ENUM_POSITION_TYPE type)
{
    return (type == POSITION_TYPE_BUY) ? m_buyGhostClosed : m_sellGhostClosed;
}

//+------------------------------------------------------------------+
//| ゴースト決済フラグ設定                                           |
//+------------------------------------------------------------------+
void CUnifiedGhost::SetGhostClosed(ENUM_POSITION_TYPE type, bool closed)
{
    if(type == POSITION_TYPE_BUY)
        m_buyGhostClosed = closed;
    else
        m_sellGhostClosed = closed;
    
    SaveToGlobalVariables();
}

//+------------------------------------------------------------------+
//| ユニークなオブジェクト名取得                                     |
//+------------------------------------------------------------------+
string CUnifiedGhost::GetUniqueObjectName(string baseName)
{
    return m_objectPrefix + baseName + "_" + IntegerToString(TimeCurrent());
}

//+------------------------------------------------------------------+
//| 水平線作成（内部ヘルパー）                                       |
//+------------------------------------------------------------------+
void CUnifiedGhost::CreateLine(string name, double price, color clr, int style, int width)
{
    #ifdef __MQL5__
    if(ObjectFind(0, name) < 0)
    {
        ObjectCreate(0, name, OBJ_HLINE, 0, 0, price);
    }
    ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
    ObjectSetInteger(0, name, OBJPROP_STYLE, style);
    ObjectSetInteger(0, name, OBJPROP_WIDTH, width);
    ObjectSetInteger(0, name, OBJPROP_BACK, true);
    ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
    ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
    #else
    if(ObjectFind(name) < 0)
    {
        ObjectCreate(name, OBJ_HLINE, 0, 0, price);
    }
    ObjectSet(name, OBJPROP_COLOR, clr);
    ObjectSet(name, OBJPROP_STYLE, style);
    ObjectSet(name, OBJPROP_WIDTH, width);
    ObjectSet(name, OBJPROP_BACK, true);
    ObjectSet(name, OBJPROP_SELECTABLE, false);
    #endif
}

//+------------------------------------------------------------------+
//| 矢印作成（内部ヘルパー）                                         |
//+------------------------------------------------------------------+
void CUnifiedGhost::CreateArrow(string name, datetime time, double price, int code, color clr, int size)
{
    #ifdef __MQL5__
    if(ObjectFind(0, name) < 0)
    {
        ObjectCreate(0, name, OBJ_ARROW, 0, time, price);
    }
    ObjectSetInteger(0, name, OBJPROP_ARROWCODE, code);
    ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
    ObjectSetInteger(0, name, OBJPROP_WIDTH, size);
    ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
    ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
    #else
    if(ObjectFind(name) < 0)
    {
        ObjectCreate(name, OBJ_ARROW, 0, time, price);
    }
    ObjectSet(name, OBJPROP_ARROWCODE, code);
    ObjectSet(name, OBJPROP_COLOR, clr);
    ObjectSet(name, OBJPROP_WIDTH, size);
    ObjectSet(name, OBJPROP_SELECTABLE, false);
    #endif
}

//+------------------------------------------------------------------+
//| テキスト作成（内部ヘルパー）                                     |
//+------------------------------------------------------------------+
void CUnifiedGhost::CreateText(string name, datetime time, double price, string text, color clr, int fontSize)
{
    #ifdef __MQL5__
    if(ObjectFind(0, name) < 0)
    {
        ObjectCreate(0, name, OBJ_TEXT, 0, time, price);
    }
    ObjectSetString(0, name, OBJPROP_TEXT, text);
    ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
    ObjectSetString(0, name, OBJPROP_FONT, "MS Gothic");
    ObjectSetInteger(0, name, OBJPROP_FONTSIZE, fontSize);
    ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
    ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
    #else
    if(ObjectFind(name) < 0)
    {
        ObjectCreate(name, OBJ_TEXT, 0, time, price);
    }
    ObjectSetText(name, text, fontSize, "MS Gothic", clr);
    ObjectSet(name, OBJPROP_SELECTABLE, false);
    #endif
}

//+------------------------------------------------------------------+
//| 色を暗くする（内部ヘルパー）                                     |
//+------------------------------------------------------------------+
color CUnifiedGhost::DarkenColor(color clr, int percent)
{
    int r = (clr & 0xFF0000) >> 16;
    int g = (clr & 0x00FF00) >> 8;
    int b = (clr & 0x0000FF);
    
    r = MathMax(0, r - r * percent / 100);
    g = MathMax(0, g - g * percent / 100);
    b = MathMax(0, b - b * percent / 100);
    
    return (color)((r << 16) + (g << 8) + b);
}

//+------------------------------------------------------------------+
//| ティック値計算（内部ヘルパー）                                   |
//+------------------------------------------------------------------+
double CUnifiedGhost::CalculateTickValue()
{
    #ifdef __MQL5__
    return SymbolInfoDouble(m_symbol, SYMBOL_TRADE_TICK_VALUE);
    #else
    return MarketInfo(m_symbol, MODE_TICKVALUE);
    #endif
}

//+------------------------------------------------------------------+
//| グローバルゴーストオブジェクト                                   |
//+------------------------------------------------------------------+
CUnifiedGhost* g_Ghost = NULL;

//+------------------------------------------------------------------+
//| ゴースト初期化                                                  |
//+------------------------------------------------------------------+
void InitializeGhost()
{
    if(g_Ghost == NULL)
    {
        g_Ghost = new CUnifiedGhost();
        g_Ghost.Init(Symbol(), MagicNumber, g_ObjectPrefix);
    }
}

//+------------------------------------------------------------------+
//| ゴーストクリーンアップ                                           |
//+------------------------------------------------------------------+
void CleanupGhost()
{
    if(g_Ghost != NULL)
    {
        delete g_Ghost;
        g_Ghost = NULL;
    }
}

//+------------------------------------------------------------------+
//| 簡易アクセス関数                                                 |
//+------------------------------------------------------------------+
// ゴーストポジション追加
bool AddGhostPosition(int type, double lots, double price, string comment = "")
{
    if(g_Ghost == NULL) return false;
    ENUM_POSITION_TYPE posType = (type == OP_BUY) ? POSITION_TYPE_BUY : POSITION_TYPE_SELL;
    return g_Ghost.AddGhostPosition(posType, lots, price, comment);
}

// ゴーストリセット
void ResetGhostPositions(int type)
{
    if(g_Ghost == NULL) return;
    ENUM_POSITION_TYPE posType = (type == OP_BUY) ? POSITION_TYPE_BUY : POSITION_TYPE_SELL;
    g_Ghost.ResetGhosts(posType);
}

// ゴースト数取得
int GetGhostPositionCount(int type)
{
    if(g_Ghost == NULL) return 0;
    ENUM_POSITION_TYPE posType = (type == OP_BUY) ? POSITION_TYPE_BUY : POSITION_TYPE_SELL;
    return g_Ghost.GetGhostCount(posType);
}

// ゴースト平均価格取得
double GetGhostAveragePrice(int type)
{
    if(g_Ghost == NULL) return 0;
    ENUM_POSITION_TYPE posType = (type == OP_BUY) ? POSITION_TYPE_BUY : POSITION_TYPE_SELL;
    return g_Ghost.GetGhostAveragePrice(posType);
}

// ゴースト損益取得
double GetGhostProfit(int type)
{
    if(g_Ghost == NULL) return 0;
    ENUM_POSITION_TYPE posType = (type == OP_BUY) ? POSITION_TYPE_BUY : POSITION_TYPE_SELL;
    return g_Ghost.GetGhostProfit(posType);
}

// リアルとゴーストの合計数取得
int GetCombinedPositionCount(int type)
{
    int realCount = g_Trading != NULL ? g_Trading.PositionCount((type == OP_BUY) ? POSITION_TYPE_BUY : POSITION_TYPE_SELL) : 0;
    int ghostCount = GetGhostPositionCount(type);
    return realCount + ghostCount;
}

// リアルとゴーストの平均価格取得
double GetCombinedAveragePrice(int type)
{
    if(g_Trading == NULL || g_Ghost == NULL) return 0;
    
    ENUM_POSITION_TYPE posType = (type == OP_BUY) ? POSITION_TYPE_BUY : POSITION_TYPE_SELL;
    
    // リアルポジション情報
    double realAvgPrice = g_Trading.GetAveragePrice(posType);
    double realTotalLots = g_Trading.GetTotalLots(posType);
    
    // ゴーストポジション情報
    double ghostAvgPrice = g_Ghost.GetGhostAveragePrice(posType);
    double ghostTotalLots = g_Ghost.GetGhostTotalLots(posType);
    
    // 合計ロット数
    double totalLots = realTotalLots + ghostTotalLots;
    
    if(totalLots <= 0) return 0;
    
    // 加重平均価格を計算
    double weightedPrice = (realAvgPrice * realTotalLots) + (ghostAvgPrice * ghostTotalLots);
    return weightedPrice / totalLots;
}

// リアルとゴーストの合計損益取得
double GetCombinedProfit(int type)
{
    if(g_Trading == NULL || g_Ghost == NULL) return 0;
    
    ENUM_POSITION_TYPE posType = (type == OP_BUY) ? POSITION_TYPE_BUY : POSITION_TYPE_SELL;
    
    double realProfit = g_Trading.GetTotalProfit(posType);
    double ghostProfit = g_Ghost.GetGhostProfit(posType);
    
    return realProfit + ghostProfit;
}