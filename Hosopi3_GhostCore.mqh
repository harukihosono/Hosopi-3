//+------------------------------------------------------------------+
//|                Hosopi 3 - ゴーストコア機能                        |
//|                        Copyright 2025                            |
//+------------------------------------------------------------------+
#include "Hosopi3_Defines.mqh"
#include "Hosopi3_Compat.mqh"
#include "Hosopi3_Trading.mqh"
#include "Hosopi3_Utils.mqh"

//+------------------------------------------------------------------+
//| GetTickValue実装                                                  |
//+------------------------------------------------------------------+
double GetTickValue()
{
#ifdef __MQL4__
   return MarketInfo(Symbol(), MODE_TICKVALUE);
#else
   return SymbolInfoDouble(Symbol(), SYMBOL_TRADE_TICK_VALUE);
#endif
}

//+------------------------------------------------------------------+
//| ゴーストポジション配列の初期化                                    |
//+------------------------------------------------------------------+
void InitializeGhostArrays()
{
    // Buy配列の完全初期化
    for(int i = 0; i < MAX_GHOST_POSITIONS; i++)
    {
        g_GhostBuyPositions[i].type = 0;
        g_GhostBuyPositions[i].lots = 0;
        g_GhostBuyPositions[i].lot = 0;
        g_GhostBuyPositions[i].symbol = "";
        g_GhostBuyPositions[i].price = 0;
        g_GhostBuyPositions[i].openPrice = 0;
        g_GhostBuyPositions[i].profit = 0;
        g_GhostBuyPositions[i].ticket = 0;
        g_GhostBuyPositions[i].openTime = 0;
        g_GhostBuyPositions[i].isGhost = false;
        g_GhostBuyPositions[i].level = 0;
        g_GhostBuyPositions[i].stopLoss = 0;
        g_GhostBuyPositions[i].takeProfit = 0;
        g_GhostBuyPositions[i].swap = 0;
        g_GhostBuyPositions[i].commission = 0;
        g_GhostBuyPositions[i].comment = "";
        g_GhostBuyPositions[i].magic = 0;
        g_GhostBuyPositions[i].entryPoint = -1;
    }
    
    // Sell配列の完全初期化
    for(int i = 0; i < MAX_GHOST_POSITIONS; i++)
    {
        g_GhostSellPositions[i].type = 0;
        g_GhostSellPositions[i].lots = 0;
        g_GhostSellPositions[i].lot = 0;
        g_GhostSellPositions[i].symbol = "";
        g_GhostSellPositions[i].price = 0;
        g_GhostSellPositions[i].openPrice = 0;
        g_GhostSellPositions[i].profit = 0;
        g_GhostSellPositions[i].ticket = 0;
        g_GhostSellPositions[i].openTime = 0;
        g_GhostSellPositions[i].isGhost = false;
        g_GhostSellPositions[i].level = 0;
        g_GhostSellPositions[i].stopLoss = 0;
        g_GhostSellPositions[i].takeProfit = 0;
        g_GhostSellPositions[i].swap = 0;
        g_GhostSellPositions[i].commission = 0;
        g_GhostSellPositions[i].comment = "";
        g_GhostSellPositions[i].magic = 0;
        g_GhostSellPositions[i].entryPoint = -1;
    }
    
    g_GhostBuyCount = 0;
    g_GhostSellCount = 0;
}

//+------------------------------------------------------------------+
//| ゴーストポジションを追加                                          |
//+------------------------------------------------------------------+
bool AddGhostPosition(int operationType, double openPrice, double lot, string comment, int entryPoint)
{
    PositionInfo ghostPos;
    // 構造体の完全初期化
    ghostPos.type = operationType;
    ghostPos.lots = lot;
    ghostPos.lot = lot;
    ghostPos.symbol = Symbol();
    ghostPos.price = openPrice;
    ghostPos.openPrice = openPrice;
    ghostPos.profit = 0;
    ghostPos.ticket = (int)(TimeCurrent() + MathRand());
    ghostPos.openTime = TimeCurrent();
    ghostPos.isGhost = true;
    ghostPos.level = 0;
    ghostPos.stopLoss = 0;
    ghostPos.takeProfit = 0;
    ghostPos.swap = 0;
    ghostPos.commission = 0;
    ghostPos.comment = comment;
    ghostPos.magic = MagicNumber;
    ghostPos.entryPoint = entryPoint;
    
    if(operationType == OP_BUY && g_GhostBuyCount < MAX_GHOST_POSITIONS)
    {
        Print("DEBUG: Buyゴーストポジション追加 - Index=", g_GhostBuyCount, " Max=", MAX_GHOST_POSITIONS);
        g_GhostBuyPositions[g_GhostBuyCount] = ghostPos;
        g_GhostBuyCount++;
        return true;
    }
    else if(operationType == OP_SELL && g_GhostSellCount < MAX_GHOST_POSITIONS)
    {
        Print("DEBUG: Sellゴーストポジション追加 - Index=", g_GhostSellCount, " Max=", MAX_GHOST_POSITIONS);
        g_GhostSellPositions[g_GhostSellCount] = ghostPos;
        g_GhostSellCount++;
        return true;
    }
    else
    {
        Print("ERROR: ゴーストポジション追加失敗 - Type=", operationType, 
              " BuyCount=", g_GhostBuyCount, " SellCount=", g_GhostSellCount, " Max=", MAX_GHOST_POSITIONS);
        return false;
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| ゴーストポジションのリセット                                      |
//+------------------------------------------------------------------+
void ResetGhostPositions(int operationType)
{
    // ゴーストオブジェクト（矢印+線+ラベル）を削除
    DeleteGhostObjects(operationType);
    
    if(operationType == OP_BUY || operationType == -1)
    {
        for(int i = 0; i < g_GhostBuyCount; i++)
        {
            g_GhostBuyPositions[i].type = 0;
            g_GhostBuyPositions[i].lots = 0;
            g_GhostBuyPositions[i].lot = 0;
            g_GhostBuyPositions[i].symbol = "";
            g_GhostBuyPositions[i].price = 0;
            g_GhostBuyPositions[i].openPrice = 0;
            g_GhostBuyPositions[i].profit = 0;
            g_GhostBuyPositions[i].ticket = 0;
            g_GhostBuyPositions[i].openTime = 0;
            g_GhostBuyPositions[i].isGhost = false;
            g_GhostBuyPositions[i].level = 0;
            g_GhostBuyPositions[i].stopLoss = 0;
            g_GhostBuyPositions[i].takeProfit = 0;
            g_GhostBuyPositions[i].swap = 0;
            g_GhostBuyPositions[i].commission = 0;
            g_GhostBuyPositions[i].comment = "";
            g_GhostBuyPositions[i].magic = 0;
            g_GhostBuyPositions[i].entryPoint = -1;
        }
        g_GhostBuyCount = 0;
    }
    
    if(operationType == OP_SELL || operationType == -1)
    {
        for(int i = 0; i < g_GhostSellCount; i++)
        {
            g_GhostSellPositions[i].type = 0;
            g_GhostSellPositions[i].lots = 0;
            g_GhostSellPositions[i].lot = 0;
            g_GhostSellPositions[i].symbol = "";
            g_GhostSellPositions[i].price = 0;
            g_GhostSellPositions[i].openPrice = 0;
            g_GhostSellPositions[i].profit = 0;
            g_GhostSellPositions[i].ticket = 0;
            g_GhostSellPositions[i].openTime = 0;
            g_GhostSellPositions[i].isGhost = false;
            g_GhostSellPositions[i].level = 0;
            g_GhostSellPositions[i].stopLoss = 0;
            g_GhostSellPositions[i].takeProfit = 0;
            g_GhostSellPositions[i].swap = 0;
            g_GhostSellPositions[i].commission = 0;
            g_GhostSellPositions[i].comment = "";
            g_GhostSellPositions[i].magic = 0;
            g_GhostSellPositions[i].entryPoint = -1;
        }
        g_GhostSellCount = 0;
    }
}

//+------------------------------------------------------------------+
//| 有効なゴーストポジション数をカウント                              |
//+------------------------------------------------------------------+
int CountValidGhosts(int operationType)
{
    int count = 0;
    
    if(operationType == OP_BUY)
    {
        for(int i = 0; i < g_GhostBuyCount; i++)
        {
            if(g_GhostBuyPositions[i].isGhost)
                count++;
        }
    }
    else if(operationType == OP_SELL)
    {
        for(int i = 0; i < g_GhostSellCount; i++)
        {
            if(g_GhostSellPositions[i].isGhost)
                count++;
        }
    }
    
    return count;
}

//+------------------------------------------------------------------+
//| ゴーストポジションの利益計算                                      |
//+------------------------------------------------------------------+
double CalculateGhostProfit(int operationType)
{
    double totalProfit = 0;
    
    #ifdef __MQL5__
        double tickValue = SymbolInfoDouble(Symbol(), SYMBOL_TRADE_TICK_VALUE);
        double point = SymbolInfoDouble(Symbol(), SYMBOL_POINT);
    #else
        double tickValue = MarketInfo(Symbol(), MODE_TICKVALUE);
        double point = MarketInfo(Symbol(), MODE_POINT);
    #endif
    
    if(operationType == OP_BUY)
    {
        double currentPrice = GetBidPrice();
        int maxIndex = MathMin(g_GhostBuyCount, 40);
        for(int i = 0; i < maxIndex; i++)
        {
            if(g_GhostBuyPositions[i].isGhost)
            {
                double priceDiff = currentPrice - g_GhostBuyPositions[i].openPrice;
                double profit = (priceDiff / point) * tickValue * g_GhostBuyPositions[i].lot;
                totalProfit += NormalizeDouble(profit, 2);
                
                // Print("DEBUG: GhostBuy[", i, "] - Entry=", g_GhostBuyPositions[i].openPrice,
                //       " Current=", currentPrice, " Diff=", priceDiff,
                //       " Profit=", NormalizeDouble(profit, 2), " Lot=", g_GhostBuyPositions[i].lot);
            }
        }
    }
    else if(operationType == OP_SELL)
    {
        double currentPrice = GetAskPrice();  // Sell決済はAsk価格
        int maxIndex = MathMin(g_GhostSellCount, 40);
        for(int i = 0; i < maxIndex; i++)
        {
            if(g_GhostSellPositions[i].isGhost)
            {
                // Sell: エントリー価格（Bid） - 現在決済価格（Ask）
                double priceDiff = g_GhostSellPositions[i].openPrice - currentPrice;  // Bid(entry) - Ask(current)
                double profit = (priceDiff / point) * tickValue * g_GhostSellPositions[i].lot;
                totalProfit += NormalizeDouble(profit, 2);
                
                // Print("DEBUG: GhostSell[", i, "] - EntryBid=", g_GhostSellPositions[i].openPrice,
                //       " CurrentAsk=", currentPrice, " Diff=", priceDiff,
                //       " Profit=", NormalizeDouble(profit, 2), " Lot=", g_GhostSellPositions[i].lot);
            }
        }
    }
    
    return totalProfit;
}

//+------------------------------------------------------------------+
//| ゴーストオブジェクト削除                                          |
//+------------------------------------------------------------------+
void DeleteGhostObjects(int operationType)
{
    string typeStr = (operationType == OP_BUY) ? "0" : (operationType == OP_SELL) ? "1" : "";
    
    // 全てのオブジェクトを検索して削除
    int totalObjects = ObjectsTotalMQL4();
    for(int i = totalObjects - 1; i >= 0; i--)
    {
        string objName = ObjectNameMQL4(i);
        
        // ゴースト矢印を削除
        if(StringFind(objName, g_ObjectPrefix + "GhostArrow_" + typeStr) == 0 || 
           (operationType == -1 && StringFind(objName, g_ObjectPrefix + "GhostArrow_") == 0))
        {
            ObjectDeleteMQL4(objName);
        }
        
        // ゴースト水平線を削除
        if(StringFind(objName, g_ObjectPrefix + "GhostLine_" + typeStr) == 0 || 
           (operationType == -1 && StringFind(objName, g_ObjectPrefix + "GhostLine_") == 0))
        {
            ObjectDeleteMQL4(objName);
        }
        
        // ゴーストロットラベルを削除
        if(StringFind(objName, g_ObjectPrefix + "GhostLot_" + typeStr) == 0 || 
           (operationType == -1 && StringFind(objName, g_ObjectPrefix + "GhostLot_") == 0))
        {
            ObjectDeleteMQL4(objName);
        }
    }
    
    Print("ゴーストオブジェクト削除完了: Type=", operationType);
}

//+------------------------------------------------------------------+
//| ゴーストポジションの平均価格計算                                  |
//+------------------------------------------------------------------+
double CalculateGhostAveragePrice(int operationType)
{
    double totalPrice = 0;
    double totalLot = 0;
    
    if(operationType == OP_BUY)
    {
        for(int i = 0; i < g_GhostBuyCount; i++)
        {
            if(g_GhostBuyPositions[i].isGhost)
            {
                totalPrice += g_GhostBuyPositions[i].openPrice * g_GhostBuyPositions[i].lot;
                totalLot += g_GhostBuyPositions[i].lot;
            }
        }
    }
    else if(operationType == OP_SELL)
    {
        for(int i = 0; i < g_GhostSellCount; i++)
        {
            if(g_GhostSellPositions[i].isGhost)
            {
                totalPrice += g_GhostSellPositions[i].openPrice * g_GhostSellPositions[i].lot;
                totalLot += g_GhostSellPositions[i].lot;
            }
        }
    }
    
    if(totalLot > 0)
        return NormalizeDouble(totalPrice / totalLot, Digits());
    
    return 0;
}

//+------------------------------------------------------------------+
//| ゴーストストップロス処理                                          |
//+------------------------------------------------------------------+
void CheckGhostStopLossHit(int side)
{
    int operationType = (side == 0) ? OP_BUY : OP_SELL;
    double currentPrice = (side == 0) ? GetBidPrice() : GetAskPrice();
    
    bool stopLossHit = false;
    
    if(side == 0) // Buy
    {
        int validCount = CountValidGhosts(OP_BUY);
        if(validCount <= 0)
            return;
        
        double lowestStopLoss = 999999;
        
        for(int i = 0; i < g_GhostBuyCount; i++)
        {
            if(g_GhostBuyPositions[i].isGhost && g_GhostBuyPositions[i].stopLoss > 0)
            {
                if(g_GhostBuyPositions[i].stopLoss < lowestStopLoss)
                    lowestStopLoss = g_GhostBuyPositions[i].stopLoss;
            }
        }
        
        if(lowestStopLoss < 999999 && currentPrice <= lowestStopLoss)
            stopLossHit = true;
    }
    else // Sell
    {
        int validCount = CountValidGhosts(OP_SELL);
        if(validCount <= 0)
            return;
        
        double highestStopLoss = 0;
        
        for(int i = 0; i < g_GhostSellCount; i++)
        {
            if(g_GhostSellPositions[i].isGhost && g_GhostSellPositions[i].stopLoss > 0)
            {
                if(g_GhostSellPositions[i].stopLoss > highestStopLoss)
                    highestStopLoss = g_GhostSellPositions[i].stopLoss;
            }
        }
        
        if(highestStopLoss > 0 && currentPrice >= highestStopLoss)
            stopLossHit = true;
    }
    
    if(stopLossHit)
    {
        ResetGhostPositions(operationType);
        Print("ゴーストストップロス発動: ", (side == 0) ? "BUY" : "SELL");
    }
}