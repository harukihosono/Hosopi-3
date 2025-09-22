//+------------------------------------------------------------------+
//|                Hosopi 3 - ゴースト表示機能                        |
//|                        Copyright 2025                            |
//+------------------------------------------------------------------+
#include "Hosopi3_Defines.mqh"
#include "Hosopi3_Compat.mqh"
#include "Hosopi3_Utils.mqh"
#include "Hosopi3_GhostCore.mqh"

// GUI関数の前方宣言（#import不要）

// 点線オブジェクトの種類を定義
#define LINE_TYPE_GHOST      0  // ゴーストポジションの水平線
#define LINE_TYPE_AVG_PRICE  1  // 平均価格ライン
#define LINE_TYPE_TP         2  // 利確ライン

//+------------------------------------------------------------------+
//| ゴーストエントリーポイントに矢印を表示                            |
//+------------------------------------------------------------------+
void ShowGhostEntryArrow(int operationType, double price, int entryPoint, double lot = 0.0, datetime entryTime = 0)
{
    if(!EnableGhostEntry)
    {
        Print("ERROR: EnableGhostEntry=false のため矢印描画をスキップ");
        return;
    }
    
    // エントリー時刻が指定されていない場合は現在時刻を使用
    datetime arrowTime = (entryTime > 0) ? entryTime : TimeCurrent();
        
    string arrowName = g_ObjectPrefix + "GhostArrow_" + IntegerToString(operationType) + "_" + 
                       IntegerToString(entryPoint) + "_" + IntegerToString(arrowTime);
    
    color arrowColor = (operationType == OP_BUY) ? clrBlue : clrRed;  // はっきりした色を使用
    int arrowCode = (operationType == OP_BUY) ? 233 : 234;  // 標準的なBuy/Sell矢印
    
    // 既存の同名オブジェクトを削除
    if(ObjectFindMQL4(arrowName) >= 0)
        ObjectDeleteMQL4(arrowName);
    
    #ifdef __MQL5__
    // MQL5での標準的なArrow作成方法
    if(ObjectCreate(0, arrowName, OBJ_ARROW, 0, arrowTime, price))
    {
        ObjectSetInteger(0, arrowName, OBJPROP_ARROWCODE, arrowCode);
        ObjectSetInteger(0, arrowName, OBJPROP_COLOR, arrowColor);
        ObjectSetInteger(0, arrowName, OBJPROP_WIDTH, GhostArrowSize);
        ObjectSetInteger(0, arrowName, OBJPROP_SELECTABLE, false);
        ObjectSetInteger(0, arrowName, OBJPROP_BACK, false);
        // BUY矢印は下、SELL矢印は上
        ObjectSetInteger(0, arrowName, OBJPROP_ANCHOR, (operationType == OP_BUY) ? ANCHOR_TOP : ANCHOR_BOTTOM);
        ChartRedraw(0); // 即座に再描画
    #else
    // MQL4での標準的なArrow作成方法
    if(ObjectCreate(arrowName, OBJ_ARROW, 0, arrowTime, price))
    {
        ObjectSet(arrowName, OBJPROP_ARROWCODE, arrowCode);
        ObjectSet(arrowName, OBJPROP_COLOR, arrowColor);
        ObjectSet(arrowName, OBJPROP_WIDTH, GhostArrowSize);
        ObjectSet(arrowName, OBJPROP_SELECTABLE, false);
        ObjectSet(arrowName, OBJPROP_BACK, false);
        WindowRedraw(); // チャート再描画
    #endif
        
        Print("DEBUG: 矢印設定完了 - Code=", arrowCode, " Color=", arrowColor, " Size=3");
        
        // 水平点線も追加
        string lineName = g_ObjectPrefix + "GhostLine_" + IntegerToString(operationType) + "_" + 
                         IntegerToString(entryPoint) + "_" + IntegerToString(TimeCurrent());
        
        if(ObjectFindMQL4(lineName) >= 0)
            ObjectDeleteMQL4(lineName);
            
        #ifdef __MQL5__
        if(ObjectCreate(0, lineName, OBJ_HLINE, 0, 0, price))
        {
            ObjectSetInteger(0, lineName, OBJPROP_COLOR, arrowColor);
            ObjectSetInteger(0, lineName, OBJPROP_STYLE, STYLE_DOT);
            ObjectSetInteger(0, lineName, OBJPROP_WIDTH, 1);
            ObjectSetInteger(0, lineName, OBJPROP_SELECTABLE, false);
            ObjectSetInteger(0, lineName, OBJPROP_BACK, true);
        }
        #else
        if(ObjectCreate(lineName, OBJ_HLINE, 0, 0, price))
        {
            ObjectSet(lineName, OBJPROP_COLOR, arrowColor);
            ObjectSet(lineName, OBJPROP_STYLE, STYLE_DOT);
            ObjectSet(lineName, OBJPROP_WIDTH, 1);
            ObjectSet(lineName, OBJPROP_SELECTABLE, false);
            ObjectSet(lineName, OBJPROP_BACK, true);
        }
        #endif
        
        // チャートを再描画して表示を強制更新
        ChartRedraw();
        
        // ロット数ラベルは無効化（ユーザー要望により削除）
        // string lotLabelName = g_ObjectPrefix + "GhostLot_" + IntegerToString(operationType) + "_" + 
        //                      IntegerToString(entryPoint) + "_" + IntegerToString(TimeCurrent());
        
        Print("SUCCESS: ゴースト矢印+線表示作成成功 - ", arrowName, " + ", lineName, " at ", price);
    }
    else
    {
        Print("ERROR: ゴースト矢印作成失敗 - ", arrowName, " Error=", GetLastError());
    }
}

// 水平線・ラベル作成関数はGUI.mqhで定義済みのため削除

//+------------------------------------------------------------------+
//| ゴーストストップロスのラインを更新                                |
//+------------------------------------------------------------------+
void UpdateGhostStopLine(int side, double stopPrice)
{
    string lineName = "GhostStopLine" + ((side == 0) ? "Buy" : "Sell");
    string labelName = "GhostStopLabel" + ((side == 0) ? "Buy" : "Sell");
    
    color lineColor = (side == 0) ? C'255,128,128' : C'255,64,64';
    
    CreateHorizontalLine(g_ObjectPrefix + lineName, stopPrice, lineColor, STYLE_DASH, 1);
    
    #ifdef __MQL5__
        string labelText = "Trail SL: " + DoubleToString(stopPrice, Digits());
    #else
        string labelText = "Trail SL: " + DoubleToString(stopPrice, Digits);
    #endif
    
    CreatePriceLabel(g_ObjectPrefix + labelName, labelText, stopPrice, lineColor, side == 0);
}

//+------------------------------------------------------------------+
//| ゴーストポジション情報を表示                                      |
//+------------------------------------------------------------------+
void DisplayGhostInfo()
{
    // P/Lラベル表示は無効化（ユーザー要望により削除）
    return;
    
    /*
    if(GhostInfoDisplay == OFF_MODE)
        return;
    
    string infoText = "";
    
    // Buy情報
    int buyCount = CountValidGhosts(OP_BUY);
    if(buyCount > 0)
    {
        double buyAvgPrice = CalculateGhostAveragePrice(OP_BUY);
        double buyProfit = CalculateGhostProfit(OP_BUY);
        
        #ifdef __MQL5__
            infoText += "Ghost BUY: " + IntegerToString(buyCount) + 
                       " | Avg: " + DoubleToString(buyAvgPrice, Digits()) +
                       " | P/L: " + DoubleToString(buyProfit, 2) + "\\n";
        #else
            infoText += "Ghost BUY: " + IntegerToString(buyCount) + 
                       " | Avg: " + DoubleToString(buyAvgPrice, Digits) +
                       " | P/L: " + DoubleToString(buyProfit, 2) + "\\n";
        #endif
    }
    
    // Sell情報
    int sellCount = CountValidGhosts(OP_SELL);
    if(sellCount > 0)
    {
        double sellAvgPrice = CalculateGhostAveragePrice(OP_SELL);
        double sellProfit = CalculateGhostProfit(OP_SELL);
        
        #ifdef __MQL5__
            infoText += "Ghost SELL: " + IntegerToString(sellCount) + 
                       " | Avg: " + DoubleToString(sellAvgPrice, Digits()) +
                       " | P/L: " + DoubleToString(sellProfit, 2);
        #else
            infoText += "Ghost SELL: " + IntegerToString(sellCount) + 
                       " | Avg: " + DoubleToString(sellAvgPrice, Digits) +
                       " | P/L: " + DoubleToString(sellProfit, 2);
        #endif
    }
    
    // 情報ラベルを作成
    string labelName = g_ObjectPrefix + "GhostInfo";
    if(ObjectFindMQL4(labelName) >= 0)
        ObjectDeleteMQL4(labelName);
    
    if(infoText != "" && ObjectCreateMQL4(labelName, OBJ_LABEL, 0, 0, 0))
    {
        ObjectSetTextMQL4(labelName, infoText, 9, "Courier New", clrWhite);
        ObjectSetMQL4(labelName, OBJPROP_CORNER_MQL4, CORNER_LEFT_UPPER);
        ObjectSetMQL4(labelName, OBJPROP_XDISTANCE_MQL4, 10);
        ObjectSetMQL4(labelName, OBJPROP_YDISTANCE_MQL4, 150);
        ObjectSetMQL4(labelName, OBJPROP_SELECTABLE_MQL4, false);
    }
    */
}

//+------------------------------------------------------------------+
//| ゴースト関連オブジェクトをクリア                                  |
//+------------------------------------------------------------------+
void ClearGhostObjects()
{
    DeleteObjectsByPrefix(g_ObjectPrefix + "GhostArrow_");
    DeleteObjectsByPrefix(g_ObjectPrefix + "GhostLine_");
    // DeleteObjectsByPrefix(g_ObjectPrefix + "GhostLot_");  // ロットラベル無効化により削除
    DeleteObjectsByPrefix(g_ObjectPrefix + "GhostStopLine");
    DeleteObjectsByPrefix(g_ObjectPrefix + "GhostStopLabel");
    DeleteObjectsByPrefix(g_ObjectPrefix + "GhostInfo");
}

//+------------------------------------------------------------------+
//| 全ゴーストエントリーポイントを表示                                |
//+------------------------------------------------------------------+
void DisplayAllGhostEntryPoints()
{
    // 既存のゴーストオブジェクトをクリア
    DeleteObjectsByPrefix(g_ObjectPrefix + "GhostArrow_");
    DeleteObjectsByPrefix(g_ObjectPrefix + "GhostLine_");
    // DeleteObjectsByPrefix(g_ObjectPrefix + "GhostLot_");  // ロットラベル無効化により削除
    
    // Buy側のゴーストエントリーポイント表示
    int buyMaxIndex = MathMin(g_GhostBuyCount, 40);
    for(int i = 0; i < buyMaxIndex; i++)
    {
        if(g_GhostBuyPositions[i].isGhost)
        {
            ShowGhostEntryArrow(OP_BUY, g_GhostBuyPositions[i].openPrice, g_GhostBuyPositions[i].entryPoint, g_GhostBuyPositions[i].lot, g_GhostBuyPositions[i].openTime);
        }
    }
    
    // Sell側のゴーストエントリーポイント表示
    int sellMaxIndex = MathMin(g_GhostSellCount, 40);
    for(int i = 0; i < sellMaxIndex; i++)
    {
        if(g_GhostSellPositions[i].isGhost)
        {
            ShowGhostEntryArrow(OP_SELL, g_GhostSellPositions[i].openPrice, g_GhostSellPositions[i].entryPoint, g_GhostSellPositions[i].lot, g_GhostSellPositions[i].openTime);
        }
    }
}