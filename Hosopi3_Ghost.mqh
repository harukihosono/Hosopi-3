//+------------------------------------------------------------------+
//|                Hosopi 3 - ゴーストシステム統合ヘッダー            |
//|                        Copyright 2025                            |
//+------------------------------------------------------------------+
#ifndef HOSOPI3_GHOST_MQH
#define HOSOPI3_GHOST_MQH

// ゴーストシステムの全コンポーネントをインクルード
#include "Hosopi3_GhostCore.mqh"        // コア機能
#include "Hosopi3_GhostDisplay.mqh"     // 表示機能
#include "Hosopi3_GhostPersistence.mqh" // 永続化機能

//+------------------------------------------------------------------+
//| ゴーストシステム統合初期化関数                                    |
//+------------------------------------------------------------------+
void InitializeGhostSystem()
{
    InitializeGhostArrays();
    RestoreGhostPositionsOnStartup();
    DisplayGhostInfo();
}

//+------------------------------------------------------------------+
//| ゴーストシステム統合終了処理                                      |
//+------------------------------------------------------------------+
void DeinitializeGhostSystem()
{
    SaveGhostPositionsToGlobal();
    ClearGhostObjects();
}

//+------------------------------------------------------------------+
//| ゴーストシステム統合更新処理                                      |
//+------------------------------------------------------------------+
void UpdateGhostSystem()
{
    // ストップロスチェック
    CheckGhostStopLossHit(0); // Buy
    CheckGhostStopLossHit(1); // Sell
    
    // 表示更新
    DisplayGhostInfo();
    DisplayAllGhostEntryPoints();
    
    // 定期保存
    SaveGhostPositionsToGlobal();
}

//+------------------------------------------------------------------+
//| ゴーストエントリー実行の統合関数                                  |
//+------------------------------------------------------------------+
bool ExecuteGhostEntry(int operationType, double price, double lot, string comment, int entryPoint)
{
    if(!EnableGhostEntry)
        return false;
    
    // スプレッド情報をログ出力
    double askPrice = GetAskPrice();
    double bidPrice = GetBidPrice(); 
    double spread = (askPrice - bidPrice) / GetPointValue();
    
    Print("DEBUG: ExecuteGhostEntry - Type=", operationType, 
          " EntryPrice=", price, " Ask=", askPrice, " Bid=", bidPrice,
          " Spread=", spread, " Point=", GetPointValue());
    
    // 価格の妥当性チェック
    if(operationType == OP_BUY && MathAbs(price - askPrice) > spread * GetPointValue())
    {
        Print("WARNING: Buy価格異常 - EntryPrice=", price, " ExpectedAsk=", askPrice);
    }
    else if(operationType == OP_SELL && MathAbs(price - bidPrice) > spread * GetPointValue())
    {
        Print("WARNING: Sell価格異常 - EntryPrice=", price, " ExpectedBid=", bidPrice);
    }
    
    // ゴーストポジション追加
    if(AddGhostPosition(operationType, price, lot, comment, entryPoint))
    {
        // 表示更新（矢印は表示、左上テキストラベルは無効）
        ShowGhostEntryArrow(operationType, price, entryPoint, lot, TimeCurrent());
        // DisplayGhostInfo();  // 左上テキストラベルは無効化
        
        // 永続化
        SaveGhostPositionsToGlobal();
        
        return true;
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| ゴーストリセットの統合関数                                        |
//+------------------------------------------------------------------+
void ResetGhostSystem(int operationType = -1)
{
    ResetGhostPositions(operationType);
    ClearGhostObjects();
    ClearGhostGlobalVariables();
    
    if(operationType == -1)
        InitializeGhostArrays();
}

#endif // HOSOPI3_GHOST_MQH