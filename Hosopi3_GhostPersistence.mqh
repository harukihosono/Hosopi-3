//+------------------------------------------------------------------+
//|                Hosopi 3 - ゴースト永続化機能                      |
//|                        Copyright 2025                            |
//+------------------------------------------------------------------+
#include "Hosopi3_Defines.mqh"
#include "Hosopi3_Compat.mqh"
#include "Hosopi3_GhostCore.mqh"

//+------------------------------------------------------------------+
//| ゴーストポジションをグローバル変数に保存                          |
//+------------------------------------------------------------------+
void SaveGhostPositionsToGlobal()
{
    string prefix = GenerateGlobalVarPrefix();
    
    // Buy側の保存
    GlobalVariableSet(prefix + "GhostBuyCount", g_GhostBuyCount);
    
    for(int i = 0; i < g_GhostBuyCount; i++)
    {
        string buyPrefix = prefix + "GhostBuy_" + IntegerToString(i) + "_";
        
        GlobalVariableSet(buyPrefix + "isGhost", g_GhostBuyPositions[i].isGhost ? 1 : 0);
        GlobalVariableSet(buyPrefix + "openPrice", g_GhostBuyPositions[i].openPrice);
        GlobalVariableSet(buyPrefix + "lot", g_GhostBuyPositions[i].lot);
        GlobalVariableSet(buyPrefix + "openTime", (double)g_GhostBuyPositions[i].openTime);
        GlobalVariableSet(buyPrefix + "magic", g_GhostBuyPositions[i].magic);
        GlobalVariableSet(buyPrefix + "ticket", (double)g_GhostBuyPositions[i].ticket);
        GlobalVariableSet(buyPrefix + "stopLoss", g_GhostBuyPositions[i].stopLoss);
        GlobalVariableSet(buyPrefix + "takeProfit", g_GhostBuyPositions[i].takeProfit);
        GlobalVariableSet(buyPrefix + "swap", g_GhostBuyPositions[i].swap);
        GlobalVariableSet(buyPrefix + "commission", g_GhostBuyPositions[i].commission);
        GlobalVariableSet(buyPrefix + "profit", g_GhostBuyPositions[i].profit);
        GlobalVariableSet(buyPrefix + "entryPoint", g_GhostBuyPositions[i].entryPoint);
        
        // コメントは別途保存（グローバル変数は文字列を直接保存できないため）
        GlobalVariableSet(buyPrefix + "commentLength", StringLen(g_GhostBuyPositions[i].comment));
    }
    
    // Sell側の保存
    GlobalVariableSet(prefix + "GhostSellCount", g_GhostSellCount);
    
    for(int i = 0; i < g_GhostSellCount; i++)
    {
        string sellPrefix = prefix + "GhostSell_" + IntegerToString(i) + "_";
        
        GlobalVariableSet(sellPrefix + "isGhost", g_GhostSellPositions[i].isGhost ? 1 : 0);
        GlobalVariableSet(sellPrefix + "openPrice", g_GhostSellPositions[i].openPrice);
        GlobalVariableSet(sellPrefix + "lot", g_GhostSellPositions[i].lot);
        GlobalVariableSet(sellPrefix + "openTime", (double)g_GhostSellPositions[i].openTime);
        GlobalVariableSet(sellPrefix + "magic", g_GhostSellPositions[i].magic);
        GlobalVariableSet(sellPrefix + "ticket", (double)g_GhostSellPositions[i].ticket);
        GlobalVariableSet(sellPrefix + "stopLoss", g_GhostSellPositions[i].stopLoss);
        GlobalVariableSet(sellPrefix + "takeProfit", g_GhostSellPositions[i].takeProfit);
        GlobalVariableSet(sellPrefix + "swap", g_GhostSellPositions[i].swap);
        GlobalVariableSet(sellPrefix + "commission", g_GhostSellPositions[i].commission);
        GlobalVariableSet(sellPrefix + "profit", g_GhostSellPositions[i].profit);
        GlobalVariableSet(sellPrefix + "entryPoint", g_GhostSellPositions[i].entryPoint);
        
        GlobalVariableSet(sellPrefix + "commentLength", StringLen(g_GhostSellPositions[i].comment));
    }
}

//+------------------------------------------------------------------+
//| ゴーストポジションをグローバル変数から読み込み                    |
//+------------------------------------------------------------------+
bool LoadGhostPositionsFromGlobal()
{
    string prefix = GenerateGlobalVarPrefix();
    
    // Buy側の読み込み
    if(GlobalVariableCheck(prefix + "GhostBuyCount"))
    {
        g_GhostBuyCount = (int)GlobalVariableGet(prefix + "GhostBuyCount");
        
        for(int i = 0; i < g_GhostBuyCount && i < MAX_GHOST_POSITIONS; i++)
        {
            string buyPrefix = prefix + "GhostBuy_" + IntegerToString(i) + "_";
            
            if(!GlobalVariableCheck(buyPrefix + "isGhost"))
                continue;
                
            g_GhostBuyPositions[i].isGhost = (GlobalVariableGet(buyPrefix + "isGhost") == 1);
            g_GhostBuyPositions[i].openPrice = GlobalVariableGet(buyPrefix + "openPrice");
            g_GhostBuyPositions[i].lot = GlobalVariableGet(buyPrefix + "lot");
            g_GhostBuyPositions[i].openTime = (datetime)GlobalVariableGet(buyPrefix + "openTime");
            g_GhostBuyPositions[i].magic = (int)GlobalVariableGet(buyPrefix + "magic");
            g_GhostBuyPositions[i].ticket = (int)GlobalVariableGet(buyPrefix + "ticket");
            g_GhostBuyPositions[i].stopLoss = GlobalVariableGet(buyPrefix + "stopLoss");
            g_GhostBuyPositions[i].takeProfit = GlobalVariableGet(buyPrefix + "takeProfit");
            g_GhostBuyPositions[i].swap = GlobalVariableGet(buyPrefix + "swap");
            g_GhostBuyPositions[i].commission = GlobalVariableGet(buyPrefix + "commission");
            g_GhostBuyPositions[i].profit = GlobalVariableGet(buyPrefix + "profit");
            g_GhostBuyPositions[i].entryPoint = (int)GlobalVariableGet(buyPrefix + "entryPoint");
            
            // コメントは簡略化して保存
            g_GhostBuyPositions[i].comment = "Ghost_Buy_" + IntegerToString(i);
        }
    }
    
    // Sell側の読み込み
    if(GlobalVariableCheck(prefix + "GhostSellCount"))
    {
        g_GhostSellCount = (int)GlobalVariableGet(prefix + "GhostSellCount");
        
        for(int i = 0; i < g_GhostSellCount && i < MAX_GHOST_POSITIONS; i++)
        {
            string sellPrefix = prefix + "GhostSell_" + IntegerToString(i) + "_";
            
            if(!GlobalVariableCheck(sellPrefix + "isGhost"))
                continue;
                
            g_GhostSellPositions[i].isGhost = (GlobalVariableGet(sellPrefix + "isGhost") == 1);
            g_GhostSellPositions[i].openPrice = GlobalVariableGet(sellPrefix + "openPrice");
            g_GhostSellPositions[i].lot = GlobalVariableGet(sellPrefix + "lot");
            g_GhostSellPositions[i].openTime = (datetime)GlobalVariableGet(sellPrefix + "openTime");
            g_GhostSellPositions[i].magic = (int)GlobalVariableGet(sellPrefix + "magic");
            g_GhostSellPositions[i].ticket = (int)GlobalVariableGet(sellPrefix + "ticket");
            g_GhostSellPositions[i].stopLoss = GlobalVariableGet(sellPrefix + "stopLoss");
            g_GhostSellPositions[i].takeProfit = GlobalVariableGet(sellPrefix + "takeProfit");
            g_GhostSellPositions[i].swap = GlobalVariableGet(sellPrefix + "swap");
            g_GhostSellPositions[i].commission = GlobalVariableGet(sellPrefix + "commission");
            g_GhostSellPositions[i].profit = GlobalVariableGet(sellPrefix + "profit");
            g_GhostSellPositions[i].entryPoint = (int)GlobalVariableGet(sellPrefix + "entryPoint");
            
            g_GhostSellPositions[i].comment = "Ghost_Sell_" + IntegerToString(i);
        }
    }
    
    return (g_GhostBuyCount > 0 || g_GhostSellCount > 0);
}

//+------------------------------------------------------------------+
//| ゴーストポジション関連のグローバル変数をクリア                    |
//+------------------------------------------------------------------+
void ClearGhostGlobalVariables()
{
    string prefix = GenerateGlobalVarPrefix();
    
    // Buy側のクリア
    if(GlobalVariableCheck(prefix + "GhostBuyCount"))
    {
        int buyCount = (int)GlobalVariableGet(prefix + "GhostBuyCount");
        
        for(int i = 0; i < buyCount; i++)
        {
            string buyPrefix = prefix + "GhostBuy_" + IntegerToString(i) + "_";
            
            GlobalVariableDel(buyPrefix + "isGhost");
            GlobalVariableDel(buyPrefix + "openPrice");
            GlobalVariableDel(buyPrefix + "lot");
            GlobalVariableDel(buyPrefix + "openTime");
            GlobalVariableDel(buyPrefix + "magic");
            GlobalVariableDel(buyPrefix + "ticket");
            GlobalVariableDel(buyPrefix + "stopLoss");
            GlobalVariableDel(buyPrefix + "takeProfit");
            GlobalVariableDel(buyPrefix + "swap");
            GlobalVariableDel(buyPrefix + "commission");
            GlobalVariableDel(buyPrefix + "profit");
            GlobalVariableDel(buyPrefix + "entryPoint");
            GlobalVariableDel(buyPrefix + "commentLength");
        }
        
        GlobalVariableDel(prefix + "GhostBuyCount");
    }
    
    // Sell側のクリア
    if(GlobalVariableCheck(prefix + "GhostSellCount"))
    {
        int sellCount = (int)GlobalVariableGet(prefix + "GhostSellCount");
        
        for(int i = 0; i < sellCount; i++)
        {
            string sellPrefix = prefix + "GhostSell_" + IntegerToString(i) + "_";
            
            GlobalVariableDel(sellPrefix + "isGhost");
            GlobalVariableDel(sellPrefix + "openPrice");
            GlobalVariableDel(sellPrefix + "lot");
            GlobalVariableDel(sellPrefix + "openTime");
            GlobalVariableDel(sellPrefix + "magic");
            GlobalVariableDel(sellPrefix + "ticket");
            GlobalVariableDel(sellPrefix + "stopLoss");
            GlobalVariableDel(sellPrefix + "takeProfit");
            GlobalVariableDel(sellPrefix + "swap");
            GlobalVariableDel(sellPrefix + "commission");
            GlobalVariableDel(sellPrefix + "profit");
            GlobalVariableDel(sellPrefix + "entryPoint");
            GlobalVariableDel(sellPrefix + "commentLength");
        }
        
        GlobalVariableDel(prefix + "GhostSellCount");
    }
}

//+------------------------------------------------------------------+
//| 起動時のゴーストポジション復元処理                                |
//+------------------------------------------------------------------+
void RestoreGhostPositionsOnStartup()
{
    if(EnableGhostEntry && LoadGhostPositionsFromGlobal())
    {
        Print("ゴーストポジションを復元しました - Buy:", g_GhostBuyCount, " Sell:", g_GhostSellCount);
    }
    else
    {
        InitializeGhostArrays();
        Print("ゴーストポジション配列を初期化しました");
    }
}