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
#include "Hosopi3_CyberUI.mqh"            // CyberUIシステム

//+------------------------------------------------------------------+
//| 戦略システム統合初期化                                            |
//+------------------------------------------------------------------+
bool InitializeStrategySystem()
{
    bool result = InitializeIndicatorHandles();
    
    if(!result)
        Print("ERROR: 戦略システム初期化失敗");
    // 戦略システム初期化完了
        
    return result;
}

//+------------------------------------------------------------------+
//| 戦略システム統合終了処理                                          |
//+------------------------------------------------------------------+
void DeinitializeStrategySystem()
{
    ReleaseIndicatorHandles();
    // 戦略システム終了処理完了
}

//+------------------------------------------------------------------+
//| エントリー判定統合関数                                            |
//+------------------------------------------------------------------+
bool CanExecuteEntry(int operationType)
{
    // ボラティリティフィルターチェック（最優先で実行して早期リターン）
    // 適用モードに応じて判定
    if(InpVolatilityFilterEnabled)
    {
        // 初回エントリーの場合は常に適用
        int buyPositions = position_count(OP_BUY);
        int sellPositions = position_count(OP_SELL);
        bool isInitialEntry = (buyPositions == 0 && sellPositions == 0);

        // デバッグ用：ポジション状況をログ出力
        static datetime lastPosLogTime = 0;
        static int lastBuyPos = -1;
        static int lastSellPos = -1;

        // ポジション数が変化したか、定期的にログ出力
        if(buyPositions != lastBuyPos || sellPositions != lastSellPos ||
           TimeCurrent() - lastPosLogTime > 1800) { // 30分に1回または変化時
            Print("【ボラティリティフィルター状況】");
            Print("  ポジション: BUY=", buyPositions, " SELL=", sellPositions);
            Print("  初回エントリー判定: ", isInitialEntry ? "YES(初回)" : "NO(ナンピン)");
            Print("  フィルターモード: ", InpVolatilityFilterMode == VOLATILITY_FILTER_ALL_ENTRIES ? "ALL(すべて)" : "INITIAL_ONLY(初回のみ)");
            Print("  フィルター適用: ", InpVolatilityFilterEnabled ? "有効" : "無効");

            lastPosLogTime = TimeCurrent();
            lastBuyPos = buyPositions;
            lastSellPos = sellPositions;
        }

        // フィルター適用条件の判定
        bool shouldApplyFilter = false;
        if(InpVolatilityFilterMode == VOLATILITY_FILTER_ALL_ENTRIES) {
            // すべてのエントリーに適用
            shouldApplyFilter = true;
        }
        else if(InpVolatilityFilterMode == VOLATILITY_FILTER_INITIAL_ONLY && isInitialEntry) {
            // 初回エントリーのみに適用
            shouldApplyFilter = true;
        }

        if(shouldApplyFilter)
        {
            if(!PassVolatilityEntryFilter()) {
                // フィルターでブロックされた場合のログ
                static datetime lastBlockLogTime = 0;
                if(TimeCurrent() - lastBlockLogTime > 300) { // 5分に1回
                    Print("エントリーブロック: ボラティリティフィルターにより",
                          operationType == OP_BUY ? "BUY" : "SELL", "エントリーを拒否");
                    lastBlockLogTime = TimeCurrent();
                }
                return false;
            }
        }
    }

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

    // 戦略評価開始

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

    // カスタムインジケーターエントリー
    if(IndicatorEntryHasConfiguration() && InpIndicatorMode != INDICATOR_EXIT_ONLY)
    {
        enabledStrategies++;
        if(CheckIndicatorEntrySignal(side))
        {
            validSignals++;
            if(activeStrategies != "")
                activeStrategies += ", ";
            activeStrategies += IndicatorEntryDisplayName();
        }
    }

    // インジケーター条件評価
    bool indicatorSignalsValid = false;

    // 有効な戦略が1つもない場合はfalseを返す
    if(enabledStrategies == 0)
    {
        return false;
    }

    // 条件タイプに基づいて評価
    if(Indicator_Condition_Type == AND_CONDITION)
    {
        // AND条件: すべての有効なインジケーターがシグナルを出した場合のみtrue
        indicatorSignalsValid = (validSignals == enabledStrategies);
    }
    else
    {
        // OR条件: 少なくとも1つのインジケーターがシグナルを出した場合にtrue
        indicatorSignalsValid = (validSignals > 0);
    }

    entrySignal = indicatorSignalsValid;

    // エントリー理由記録
    if(entrySignal)
    {
        string typeStr = (side == 0) ? "Buy" : "Sell";
        string conditionType = (Indicator_Condition_Type == AND_CONDITION) ? "AND条件" : "OR条件";
        string reason = conditionType + "(" + activeStrategies + ")";

        Print("エントリーシグナル: ", typeStr, " - ", reason);
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

    // CyberUIシステムとの連携 - エントリー状態を評価してUIを更新（現在無効化）
    // UpdateCyberUIWithStrategyState();
}

//+------------------------------------------------------------------+
//| CyberUIとの戦略状態連携                                          |
//+------------------------------------------------------------------+
void UpdateCyberUIWithStrategyState()
{
    // Buy/Sellの各エントリー信号を評価
    bool buySignal = false;
    bool sellSignal = false;

    // インジケーター戦略が有効な場合のみ評価
    if(g_EnableIndicatorsEntry)
    {
        buySignal = EvaluateStrategyForEntry(0);  // Buy側 (side=0)
        sellSignal = EvaluateStrategyForEntry(1); // Sell側 (side=1)
    }

    // エントリー状態を決定
    ENUM_ENTRY_STATE entryState = ENTRY_STATE_NEUTRAL;

    if(buySignal && sellSignal)
    {
        entryState = ENTRY_STATE_BUYSELL;
    }
    else if(buySignal)
    {
        entryState = ENTRY_STATE_BUY;
    }
    else if(sellSignal)
    {
        entryState = ENTRY_STATE_SELL;
    }

    // CyberUIエントリー状態を設定（チャート背景色を更新）
    SetCyberEntryState(entryState);

    // テクニカル指標パネルの状態を更新
    UpdateCyberTechnicalPanels();
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