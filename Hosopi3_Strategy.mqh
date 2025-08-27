//+------------------------------------------------------------------+
//|                    Hosopi 3 - 戦略システム統合ヘッダー            |
//|                           Copyright 2025                          |
//+------------------------------------------------------------------+
#ifndef HOSOPI3_STRATEGY_MQH
#define HOSOPI3_STRATEGY_MQH

// 戦略システムの全コンポーネントをインクルード
#include "Hosopi3_StrategyTime.mqh"       // 時間ベース戦略
#include "Hosopi3_StrategyTechnical.mqh"  // テクニカル指標戦略
#include "Hosopi3_StrategyIndicators.mqh" // インジケーター計算

//+------------------------------------------------------------------+
//| 戦略システム統合初期化                                            |
//+------------------------------------------------------------------+
bool InitializeStrategySystem()
{
    bool result = InitializeIndicatorHandles();
    
    if(result)
        Print("戦略システム初期化完了");
    else
        Print("戦略システム初期化失敗");
        
    return result;
}

//+------------------------------------------------------------------+
//| 戦略システム統合終了処理                                          |
//+------------------------------------------------------------------+
void DeinitializeStrategySystem()
{
    ReleaseIndicatorHandles();
    Print("戦略システム終了処理完了");
}

//+------------------------------------------------------------------+
//| エントリー判定統合関数                                            |
//+------------------------------------------------------------------+
bool CanExecuteEntry(int operationType)
{
    // 基本的なエントリー可否チェック
    if(!CanEntry(operationType))
        return false;
    
    // 時間フィルターチェック
    if(!IsTimeAllowed(operationType))
        return false;
    
    // 偶数奇数戦略チェック
    if(!CanEntryByEvenOddStrategy(operationType))
        return false;
    
    // テクニカル戦略チェック
    if(!CanEntryByTechnicalStrategy(operationType))
        return false;
    
    return true;
}

//+------------------------------------------------------------------+
//| テクニカル戦略評価メイン関数                                       |
//+------------------------------------------------------------------+
bool EvaluateStrategyForEntry(int side)
{
    // side: 0 = Buy, 1 = Sell
    bool entrySignal = false;

    Print("【戦略評価開始】 側=", side == 0 ? "Buy" : "Sell", 
          " MA戦略=", MA_Entry_Strategy == MA_ENTRY_ENABLED ? "有効" : "無効");

    // インジケーター評価
    bool strategySignals = false;
    int enabledStrategies = 0;
    int validSignals = 0;

    // 有効な戦略名収集
    string activeStrategies = "";

    // 各インジケーターのシグナルチェック
    if(MA_Entry_Strategy == MA_ENTRY_ENABLED)
    {
        enabledStrategies++;
        if(CheckMASignal(side))
        {
            validSignals++;
            if(activeStrategies != "")
                activeStrategies += ", ";
            activeStrategies += "MAクロス";
        }
    }

    if(RSI_Entry_Strategy == RSI_ENTRY_ENABLED)
    {
        enabledStrategies++;
        if(CheckRSISignal(side))
        {
            validSignals++;
            if(activeStrategies != "")
                activeStrategies += ", ";
            activeStrategies += "RSI";
        }
    }

    if(BB_Entry_Strategy == BB_ENTRY_ENABLED)
    {
        enabledStrategies++;
        if(CheckBollingerSignal(side))
        {
            validSignals++;
            if(activeStrategies != "")
                activeStrategies += ", ";
            activeStrategies += "ボリンジャーバンド";
        }
    }

    if(RCI_Entry_Strategy == RCI_ENTRY_ENABLED)
    {
        enabledStrategies++;
        if(CheckRCISignal(side))
        {
            validSignals++;
            if(activeStrategies != "")
                activeStrategies += ", ";
            activeStrategies += "RCI";
        }
    }

    if(Stoch_Entry_Strategy == STOCH_ENTRY_ENABLED)
    {
        enabledStrategies++;
        if(CheckStochasticSignal(side))
        {
            validSignals++;
            if(activeStrategies != "")
                activeStrategies += ", ";
            activeStrategies += "ストキャスティクス";
        }
    }

    if(CCI_Entry_Strategy == CCI_ENTRY_ENABLED)
    {
        enabledStrategies++;
        if(CheckCCISignal(side))
        {
            validSignals++;
            if(activeStrategies != "")
                activeStrategies += ", ";
            activeStrategies += "CCI";
        }
    }

    if(ADX_Entry_Strategy == ADX_ENTRY_ENABLED)
    {
        enabledStrategies++;
        if(CheckADXSignal(side))
        {
            validSignals++;
            if(activeStrategies != "")
                activeStrategies += ", ";
            activeStrategies += "ADX/DMI";
        }
    }

    if(EvenOdd_Entry_Strategy != EVEN_ODD_DISABLED)
    {
        enabledStrategies++;
        int operationType = (side == 0) ? OP_BUY : OP_SELL;
        if(CanEntryByEvenOddStrategy(operationType))
        {
            validSignals++;
            if(activeStrategies != "")
                activeStrategies += ", ";
            activeStrategies += "偶数/奇数時間";
        }
    }

    // インジケーター条件評価
    bool indicatorSignalsValid = false;

    // 有効な戦略が1つもない場合はfalseを返す
    if(enabledStrategies == 0)
    {
        Print("【最終判断】: 有効なインジケーターが0のため false を返します");
        return false;
    }

    // 条件タイプに基づいて評価
    if(Indicator_Condition_Type == AND_CONDITION)
    {
        // AND条件: すべての有効なインジケーターがシグナルを出した場合のみtrue
        indicatorSignalsValid = (validSignals == enabledStrategies);
        Print("【最終判断】 AND条件で評価: ", indicatorSignalsValid ? "すべてのシグナルが成立" : "一部のシグナルが不成立");
    }
    else
    {
        // OR条件: 少なくとも1つのインジケーターがシグナルを出した場合にtrue
        indicatorSignalsValid = (validSignals > 0);
        Print("【最終判断】 OR条件で評価: ", indicatorSignalsValid ? "1つ以上のシグナルが成立" : "シグナル不成立");
    }

    entrySignal = indicatorSignalsValid;

    // エントリー理由記録
    if(entrySignal)
    {
        string typeStr = (side == 0) ? "Buy" : "Sell";
        string conditionType = (Indicator_Condition_Type == AND_CONDITION) ? "AND条件" : "OR条件";
        string reason = conditionType + "(" + activeStrategies + ")";
        
        Print("【エントリーシグナル成立】 ", typeStr, " - ", reason);
    }

    return entrySignal;
}

//+------------------------------------------------------------------+
//| 戦略システム定期更新処理                                          |
//+------------------------------------------------------------------+
void UpdateStrategySystem()
{
    // インジケーター値を更新（必要に応じて）
    UpdateIndicatorValues();
}

//+------------------------------------------------------------------+
//| テクニカル指標エントリー判定                                       |
//+------------------------------------------------------------------+
bool CanEntryByTechnicalStrategy(int operationType)
{
    if(!g_EnableIndicatorsEntry)
        return true;
    
    // テクニカル戦略評価
    int side = (operationType == OP_BUY) ? 0 : 1;
    return EvaluateStrategyForEntry(side);
}

#endif // HOSOPI3_STRATEGY_MQH