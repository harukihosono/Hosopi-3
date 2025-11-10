//+------------------------------------------------------------------+
//|                                    Hosopi3_IndicatorEntry.mqh    |
//|                                     Copyright 2025               |
//|                                                                  |
//+------------------------------------------------------------------+

#ifndef HOSOPI3_INDICATOR_ENTRY_MQH
#define HOSOPI3_INDICATOR_ENTRY_MQH

//==================================================================
// インジケーターエントリークラス（MQL4/MQL5共通）
//==================================================================

class IndicatorEntryManager
{
private:
#ifdef __MQL5__
   // インジケーターハンドル（MQL5）
   int m_indicatorHandle;
#endif

   // インジケーターパラメーター配列
   double m_params[20];

   // 最後にチェックしたバーの時間（シフト1以上の場合のみ使用）
   datetime m_lastBarTime;

   // エントリー済みフラグ（同じ条件での連続エントリー防止）
   bool m_buyEntryDone;
   bool m_sellEntryDone;

   // 前回の条件状態（交差判定用）
   bool m_prevBuyCondition;
   bool m_prevSellCondition;
   bool m_prevBuyExitCondition;
   bool m_prevSellExitCondition;

public:
   // コンストラクタ
   IndicatorEntryManager()
   {
#ifdef __MQL5__
      m_indicatorHandle = INVALID_HANDLE;
#endif
      m_lastBarTime = 0;
      m_buyEntryDone = false;
      m_sellEntryDone = false;
      m_prevBuyCondition = false;
      m_prevSellCondition = false;
      m_prevBuyExitCondition = false;
      m_prevSellExitCondition = false;

      // パラメーター配列を初期化
      m_params[0] = InpParam1;   m_params[1] = InpParam2;   m_params[2] = InpParam3;   m_params[3] = InpParam4;
      m_params[4] = InpParam5;   m_params[5] = InpParam6;   m_params[6] = InpParam7;   m_params[7] = InpParam8;
      m_params[8] = InpParam9;   m_params[9] = InpParam10;  m_params[10] = InpParam11; m_params[11] = InpParam12;
      m_params[12] = InpParam13; m_params[13] = InpParam14; m_params[14] = InpParam15; m_params[15] = InpParam16;
      m_params[16] = InpParam17; m_params[17] = InpParam18; m_params[18] = InpParam19; m_params[19] = InpParam20;
   }

   // デストラクタ
   ~IndicatorEntryManager()
   {
#ifdef __MQL5__
      if(m_indicatorHandle != INVALID_HANDLE)
      {
         IndicatorRelease(m_indicatorHandle);
      }
#endif
   }

   // 初期化
   bool Initialize()
   {
      // 有効な条件が一つもない場合は初期化しない
      if(!HasAnyEnabledCondition())
         return true;

#ifdef __MQL5__
      // MQL5: カスタムインジケーターのハンドルを取得
      m_indicatorHandle = iCustom(_Symbol, InpCustomTimeframe, InpIndicatorName,
                                  m_params[0], m_params[1], m_params[2], m_params[3], m_params[4],
                                  m_params[5], m_params[6], m_params[7], m_params[8], m_params[9],
                                  m_params[10], m_params[11], m_params[12], m_params[13], m_params[14],
                                  m_params[15], m_params[16], m_params[17], m_params[18], m_params[19]);

      if(m_indicatorHandle == INVALID_HANDLE)
      {
         Print("インジケーターハンドルの取得に失敗: ", InpIndicatorName);
         return false;
      }
#else
      // MQL4: インジケーターの存在確認のためテスト呼び出し
      double testValue = iCustom(_Symbol, (int)InpCustomTimeframe, InpIndicatorName,
                                 m_params[0], m_params[1], m_params[2], m_params[3], m_params[4],
                                 m_params[5], m_params[6], m_params[7], m_params[8], m_params[9],
                                 m_params[10], m_params[11], m_params[12], m_params[13], m_params[14],
                                 m_params[15], m_params[16], m_params[17], m_params[18], m_params[19],
                                 0, 0);

      if(GetLastError() != 0)
      {
         Print("インジケーターの読み込みに失敗: ", InpIndicatorName);
         return false;
      }
#endif

      string modeText = "";
      if(InpIndicatorMode == INDICATOR_ENTRY_ONLY)
         modeText = "エントリーのみ";
      else if(InpIndicatorMode == INDICATOR_EXIT_ONLY)
         modeText = "決済のみ";
      else
         modeText = "エントリー＆決済";

      Print("インジケーターマネージャーを初期化しました: ", InpIndicatorName, " (", modeText, ")");
      return true;
   }

   // エントリー・決済条件をチェック
   // 注意: エントリー処理は戦略システム（Hosopi3_Strategy.mqh）経由で実行されるため、
   //       ここでは決済処理のみを実行する（AND条件を正しく機能させるため）
   void CheckConditions()
   {
      // 有効な条件がない場合は処理しない
      if(!HasAnyEnabledCondition())
         return;

#ifdef __MQL5__
      if(m_indicatorHandle == INVALID_HANDLE)
         return;
#endif

      // 決済処理のみを実行（エントリーは戦略システム経由で実行される）
      if(InpIndicatorMode == INDICATOR_EXIT_ONLY || InpIndicatorMode == INDICATOR_ENTRY_AND_EXIT)
      {
         CheckExitConditions();
      }
   }

   // 買いエントリーシグナル判定（戦略システムから呼ばれる用にpublic化）
   bool ShouldBuy()
   {
      bool buySignal = false;

      // シグナル条件チェック
      if(InpEnableBuySignal)
      {
         bool signalResult = CheckSignalCondition(InpBuySignalBuffer, true);
         if(signalResult) {
            Print("[ShouldBuy] Buy signal detected from buffer ", InpBuySignalBuffer);
         }
         buySignal |= signalResult;
      }

      // 価格条件チェック
      if(InpEnableBuyPrice)
      {
         buySignal |= CheckPriceCondition(InpBuySignalBuffer, InpBuyPriceType, InpBuyPriceCondition);
      }

      // 数値条件チェック
      if(InpEnableBuyValue)
      {
         buySignal |= CheckValueCondition(InpBuySignalBuffer, InpBuyValueThreshold, InpBuyValueCondition);
      }

      // オブジェクト条件チェック
      if(InpEnableBuySignalObject)
      {
         buySignal |= CheckObjectSignal(BuySignalPrefix);
      }

      return buySignal;
   }

   // 売りエントリーシグナル判定（戦略システムから呼ばれる用にpublic化）
   bool ShouldSell()
   {
      bool sellSignal = false;

      // シグナル条件チェック
      if(InpEnableSellSignal)
      {
         bool signalResult = CheckSignalCondition(InpSellSignalBuffer, false);
         if(signalResult) {
            Print("[ShouldSell] Sell signal detected from buffer ", InpSellSignalBuffer);
         }
         sellSignal |= signalResult;
      }

      // 価格条件チェック
      if(InpEnableSellPrice)
      {
         sellSignal |= CheckPriceCondition(InpSellSignalBuffer, InpSellPriceType, InpSellPriceCondition);
      }

      // 数値条件チェック
      if(InpEnableSellValue)
      {
         sellSignal |= CheckValueCondition(InpSellSignalBuffer, InpSellValueThreshold, InpSellValueCondition);
      }

      // オブジェクト条件チェック
      if(InpEnableSellSignalObject)
      {
         sellSignal |= CheckObjectSignal(SellSignalPrefix);
      }

      return sellSignal;
   }

private:
   // エントリー条件をチェック
   void CheckEntryConditions()
   {
      // 買いシグナルをチェック
      bool currentBuyCondition = ShouldBuy();
      if(currentBuyCondition && !m_buyEntryDone)
      {
         Print("[Entry] Buy condition met, checking if can enter...");
         if(CanEntry(true))
         {
            // 交差条件の場合は前回false→今回trueの時のみエントリー
            if(NeedsCrossCheck(true))
            {
               if(!m_prevBuyCondition && currentBuyCondition)
               {
                  ExecuteBuyOrder(0, false);
                  Print("[ENTRY EXECUTED] インジケーターシグナルによる買いエントリー実行");
                  m_buyEntryDone = true;
               }
            }
            else
            {
               // 非交差条件の場合は条件を満たしたらエントリー
               ExecuteBuyOrder(0, false);
               Print("[ENTRY EXECUTED] インジケーターシグナルによる買いエントリー実行");
               m_buyEntryDone = true;
            }
         }
         else {
            Print("[Entry] Cannot enter - position condition not met");
         }
      }
      m_prevBuyCondition = currentBuyCondition;

      // 売りシグナルをチェック
      bool currentSellCondition = ShouldSell();
      if(currentSellCondition && !m_sellEntryDone)
      {
         Print("[Entry] Sell condition met, checking if can enter...");
         if(CanEntry(false))
         {
            // 交差条件の場合は前回false→今回trueの時のみエントリー
            if(NeedsCrossCheck(false))
            {
               if(!m_prevSellCondition && currentSellCondition)
               {
                  ExecuteSellOrder(0, false);
                  Print("[ENTRY EXECUTED] インジケーターシグナルによる売りエントリー実行");
                  m_sellEntryDone = true;
               }
            }
            else
            {
               // 非交差条件の場合は条件を満たしたらエントリー
               ExecuteSellOrder(0, false);
               Print("[ENTRY EXECUTED] インジケーターシグナルによる売りエントリー実行");
               m_sellEntryDone = true;
            }
         }
         else {
            Print("[Entry] Cannot enter - position condition not met");
         }
      }
      m_prevSellCondition = currentSellCondition;
   }

   // 決済条件をチェック
   void CheckExitConditions()
   {
      // 買いポジションの決済条件をチェック
      bool currentBuyExitCondition = ShouldExitBuy();
      if(currentBuyExitCondition)
      {
         if(PositionCount(OP_BUY) > 0)
         {
            // 交差条件の場合は前回false→今回trueの時のみ決済
            if(NeedsCrossCheckForExit(true))
            {
               if(!m_prevBuyExitCondition && currentBuyExitCondition)
               {
                  ClosePosition(OP_BUY, false);
                  Print("インジケーターシグナルによる買いポジション決済実行");
               }
            }
            else
            {
               // 非交差条件の場合は条件を満たしたら決済
               ClosePosition(OP_BUY, false);
               Print("インジケーターシグナルによる買いポジション決済実行");
            }
         }
      }
      m_prevBuyExitCondition = currentBuyExitCondition;

      // 売りポジションの決済条件をチェック
      bool currentSellExitCondition = ShouldExitSell();
      if(currentSellExitCondition)
      {
         if(PositionCount(OP_SELL) > 0)
         {
            // 交差条件の場合は前回false→今回trueの時のみ決済
            if(NeedsCrossCheckForExit(false))
            {
               if(!m_prevSellExitCondition && currentSellExitCondition)
               {
                  ClosePosition(OP_SELL, false);
                  Print("インジケーターシグナルによる売りポジション決済実行");
               }
            }
            else
            {
               // 非交差条件の場合は条件を満たしたら決済
               ClosePosition(OP_SELL, false);
               Print("インジケーターシグナルによる売りポジション決済実行");
            }
         }
      }
      m_prevSellExitCondition = currentSellExitCondition;

      // 反対シグナルによる決済（有効な場合のみ）
      if(InpOppositeSignalExit == OPPOSITE_EXIT_ON)
      {
         if(ShouldBuy() && PositionCount(OP_SELL) > 0)
         {
            ClosePosition(OP_SELL, false);
            Print("[OPPOSITE EXIT] 買いシグナルによる売りポジション決済実行");
         }

         if(ShouldSell() && PositionCount(OP_BUY) > 0)
         {
            ClosePosition(OP_BUY, false);
            Print("[OPPOSITE EXIT] 売りシグナルによる買いポジション決済実行");
         }
      }
   }

   // 交差条件のチェックが必要かどうか（エントリー用）
   bool NeedsCrossCheck(bool isBuy)
   {
      if(isBuy)
      {
         return (InpEnableBuyPrice && (InpBuyPriceCondition == PRICE_CONDITION_CROSS ||
                                      InpBuyPriceCondition == PRICE_CONDITION_UP_CROSS ||
                                      InpBuyPriceCondition == PRICE_CONDITION_DOWN_CROSS)) ||
                (InpEnableBuyValue && (InpBuyValueCondition == VALUE_CONDITION_CROSS ||
                                      InpBuyValueCondition == VALUE_CONDITION_UP_CROSS ||
                                      InpBuyValueCondition == VALUE_CONDITION_DOWN_CROSS));
      }
      else
      {
         return (InpEnableSellPrice && (InpSellPriceCondition == PRICE_CONDITION_CROSS ||
                                       InpSellPriceCondition == PRICE_CONDITION_UP_CROSS ||
                                       InpSellPriceCondition == PRICE_CONDITION_DOWN_CROSS)) ||
                (InpEnableSellValue && (InpSellValueCondition == VALUE_CONDITION_CROSS ||
                                       InpSellValueCondition == VALUE_CONDITION_UP_CROSS ||
                                       InpSellValueCondition == VALUE_CONDITION_DOWN_CROSS));
      }
   }

   // 交差条件のチェックが必要かどうか（決済用）
   bool NeedsCrossCheckForExit(bool isBuy)
   {
      if(isBuy)
      {
         return (InpEnableBuyExitPrice && (InpBuyExitPriceCondition == PRICE_CONDITION_CROSS ||
                                          InpBuyExitPriceCondition == PRICE_CONDITION_UP_CROSS ||
                                          InpBuyExitPriceCondition == PRICE_CONDITION_DOWN_CROSS)) ||
                (InpEnableBuyExitValue && (InpBuyExitValueCondition == VALUE_CONDITION_CROSS ||
                                          InpBuyExitValueCondition == VALUE_CONDITION_UP_CROSS ||
                                          InpBuyExitValueCondition == VALUE_CONDITION_DOWN_CROSS));
      }
      else
      {
         return (InpEnableSellExitPrice && (InpSellExitPriceCondition == PRICE_CONDITION_CROSS ||
                                           InpSellExitPriceCondition == PRICE_CONDITION_UP_CROSS ||
                                           InpSellExitPriceCondition == PRICE_CONDITION_DOWN_CROSS)) ||
                (InpEnableSellExitValue && (InpSellExitValueCondition == VALUE_CONDITION_CROSS ||
                                           InpSellExitValueCondition == VALUE_CONDITION_UP_CROSS ||
                                           InpSellExitValueCondition == VALUE_CONDITION_DOWN_CROSS));
      }
   }

   // 有効な条件があるかチェック
   bool HasAnyEnabledCondition()
   {
      // エントリー条件
      bool hasEntryCondition = InpEnableBuySignal || InpEnableSellSignal ||
                              InpEnableBuyPrice || InpEnableSellPrice ||
                              InpEnableBuyValue || InpEnableSellValue ||
                              InpEnableBuySignalObject || InpEnableSellSignalObject;

      // 決済条件
      bool hasExitCondition = InpEnableBuyExitSignal || InpEnableSellExitSignal ||
                             InpEnableBuyExitPrice || InpEnableSellExitPrice ||
                             InpEnableBuyExitValue || InpEnableSellExitValue ||
                             InpEnableBuyExitObject || InpEnableSellExitObject;

      // モードに応じて必要な条件をチェック
      if(InpIndicatorMode == INDICATOR_ENTRY_ONLY)
         return hasEntryCondition;
      else if(InpIndicatorMode == INDICATOR_EXIT_ONLY)
         return hasExitCondition;
      else // INDICATOR_ENTRY_AND_EXIT
         return hasEntryCondition || hasExitCondition;
   }

   // 買いポジション決済シグナル判定
   bool ShouldExitBuy()
   {
      bool exitSignal = false;

      // 決済シグナル条件チェック
      // 買いポジション決済時は決済専用シグナルをチェック
      if(InpEnableBuyExitSignal)
      {
         bool signalResult = CheckSignalCondition(InpBuyExitBuffer, false); // 売り方向のシグナルを検出
         if(signalResult) {
            Print("[ExitBuy] 買いポジション決済シグナル検出 from buffer ", InpBuyExitBuffer);
         }
         exitSignal |= signalResult;
      }

      // 価格条件チェック
      if(InpEnableBuyExitPrice)
      {
         exitSignal |= CheckPriceCondition(InpBuyExitBuffer, InpBuyExitPriceType, InpBuyExitPriceCondition);
      }

      // 数値条件チェック
      if(InpEnableBuyExitValue)
      {
         exitSignal |= CheckValueCondition(InpBuyExitBuffer, InpBuyExitValueThreshold, InpBuyExitValueCondition);
      }

      // オブジェクト条件チェック
      if(InpEnableBuyExitObject)
      {
         exitSignal |= CheckObjectSignal(BuyExitPrefix);
      }

      return exitSignal;
   }

   // 売りポジション決済シグナル判定
   bool ShouldExitSell()
   {
      bool exitSignal = false;

      // 決済シグナル条件チェック
      // 売りポジション決済時は決済専用シグナルをチェック
      if(InpEnableSellExitSignal)
      {
         bool signalResult = CheckSignalCondition(InpSellExitBuffer, true); // 買い方向のシグナルを検出
         if(signalResult) {
            Print("[ExitSell] 売りポジション決済シグナル検出 from buffer ", InpSellExitBuffer);
         }
         exitSignal |= signalResult;
      }

      // 価格条件チェック
      if(InpEnableSellExitPrice)
      {
         exitSignal |= CheckPriceCondition(InpSellExitBuffer, InpSellExitPriceType, InpSellExitPriceCondition);
      }

      // 数値条件チェック
      if(InpEnableSellExitValue)
      {
         exitSignal |= CheckValueCondition(InpSellExitBuffer, InpSellExitValueThreshold, InpSellExitValueCondition);
      }

      // オブジェクト条件チェック
      if(InpEnableSellExitObject)
      {
         exitSignal |= CheckObjectSignal(SellExitPrefix);
      }

      return exitSignal;
   }

   // エントリー可能かチェック（ポジション数制御）
   bool CanEntry(bool isBuy)
   {
      // エントリー前の共通チェック（時間フィルター、急変フィルター、スプレッドチェックなど）
      string orderTypeStr = isBuy ? "インジケーター買い" : "インジケーター売り";
      if(!PreOrderChecks(orderTypeStr, false))
         return false;

      switch(InpEntryCondition)
      {
         case ENTRY_ALWAYS:
            return true; // 常にエントリー可

         case ENTRY_NO_POSITION:
            // 全ポジション数が0の場合のみ
            return (PositionCount(OP_BUY) + PositionCount(OP_SELL)) == 0;

         case ENTRY_NO_SAME_DIRECTION:
            // 同方向ポジションがない場合のみ
            return isBuy ? (PositionCount(OP_BUY) == 0) : (PositionCount(OP_SELL) == 0);

         default:
            return false;
      }
   }

   // シグナル条件チェック
   bool CheckSignalCondition(int buffer, bool isBuy)
   {
      double currentValue = GetIndicatorValue(buffer, InpIndicatorShift);
      double prevValue = GetIndicatorValue(buffer, InpIndicatorShift + 1);

      // デバッグログ出力
      if(InpIndicatorShift == 0) {
         Print("[Signal Check] Buffer=", buffer, ", isBuy=", isBuy, ", Current=", currentValue, ", Prev=", prevValue);
      }

      // シグナル判定パターン
      // 1. EMPTY_VALUEから有効値への変化
      if(prevValue == EMPTY_VALUE && currentValue != EMPTY_VALUE && currentValue != 0) {
         Print("[Signal Detected] Type 1: EMPTY_VALUE to Valid Value");
         return true;
      }

      // 2. 0から正値への変化（買いシグナル）または0から負値への変化（売りシグナル）
      if(isBuy && prevValue <= 0 && currentValue > 0) {
         Print("[Signal Detected] Type 2: Buy signal (0 to positive)");
         return true;
      }
      if(!isBuy && prevValue >= 0 && currentValue < 0) {
         Print("[Signal Detected] Type 2: Sell signal (0 to negative)");
         return true;
      }

      // 3. 値が存在する場合（矢印インジケーター等）
      if(currentValue != EMPTY_VALUE && currentValue != 0) {
         // 前回値がEMPTY_VALUEまたは0の場合、新規シグナルとして判定
         if(prevValue == EMPTY_VALUE || prevValue == 0) {
            Print("[Signal Detected] Type 3: New signal value=", currentValue);
            return true;
         }
      }

      return false;
   }

   // 価格条件チェック
   bool CheckPriceCondition(int buffer, ENUM_APPLIED_PRICE priceType, ENUM_PRICE_CONDITION_TYPE conditionType)
   {
      double indicatorValue = GetIndicatorValue(buffer, InpIndicatorShift);
      double prevIndicatorValue = GetIndicatorValue(buffer, InpIndicatorShift + 1);

      if(indicatorValue == EMPTY_VALUE || prevIndicatorValue == EMPTY_VALUE)
         return false;

      double price = GetPrice(priceType, InpIndicatorShift);
      double prevPrice = GetPrice(priceType, InpIndicatorShift + 1);

      return CheckPriceConditionLogic(conditionType, price, indicatorValue, prevPrice, prevIndicatorValue);
   }

   // 数値条件チェック
   bool CheckValueCondition(int buffer, double threshold, ENUM_VALUE_CONDITION_TYPE conditionType)
   {
      double indicatorValue = GetIndicatorValue(buffer, InpIndicatorShift);
      double prevIndicatorValue = GetIndicatorValue(buffer, InpIndicatorShift + 1);

      if(indicatorValue == EMPTY_VALUE || prevIndicatorValue == EMPTY_VALUE)
         return false;

      return CheckValueConditionLogic(conditionType, indicatorValue, threshold, prevIndicatorValue, threshold);
   }

   // オブジェクトシグナルチェック
   bool CheckObjectSignal(string prefix)
   {
      datetime barTime = iTime(_Symbol, InpCustomTimeframe, InpIndicatorShift);

      for(int i = ObjectsTotal(0, -1, -1) - 1; i >= 0; i--)
      {
         string objName = ObjectName(0, i, -1, -1);
         if(StringFind(objName, prefix) == 0)
         {
            datetime objTime = (datetime)ObjectGetInteger(0, objName, OBJPROP_TIME);
            if(objTime == barTime)
            {
               double objValue = ObjectGetDouble(0, objName, OBJPROP_PRICE);
               return objValue != 0;
            }
         }
      }

      return false;
   }

   // 価格条件判定関数
   bool CheckPriceConditionLogic(ENUM_PRICE_CONDITION_TYPE conditionType, double price, double indicatorValue, double prevPrice, double prevIndicatorValue)
   {
      switch(conditionType)
      {
         case PRICE_CONDITION_NONE:
            return false;

         case PRICE_CONDITION_CROSS:
            return (prevPrice <= prevIndicatorValue && price > indicatorValue) || (prevPrice >= prevIndicatorValue && price < indicatorValue);

         case PRICE_CONDITION_UP_CROSS:
            return prevPrice <= prevIndicatorValue && price > indicatorValue;

         case PRICE_CONDITION_DOWN_CROSS:
            return prevPrice >= prevIndicatorValue && price < indicatorValue;

         case PRICE_CONDITION_BELOW:
            return price < indicatorValue;

         case PRICE_CONDITION_ABOVE:
            return price > indicatorValue;

         default:
            return false;
      }
   }

   // 数値条件判定関数
   bool CheckValueConditionLogic(ENUM_VALUE_CONDITION_TYPE conditionType, double indicatorValue, double threshold, double prevIndicatorValue, double prevThreshold)
   {
      switch(conditionType)
      {
         case VALUE_CONDITION_NONE:
            return false;

         case VALUE_CONDITION_CROSS:
            return (prevIndicatorValue <= prevThreshold && indicatorValue > threshold) || (prevIndicatorValue >= prevThreshold && indicatorValue < threshold);

         case VALUE_CONDITION_UP_CROSS:
            return prevIndicatorValue <= prevThreshold && indicatorValue > threshold;

         case VALUE_CONDITION_DOWN_CROSS:
            return prevIndicatorValue >= prevThreshold && indicatorValue < threshold;

         case VALUE_CONDITION_BELOW:
            return indicatorValue < threshold;

         case VALUE_CONDITION_ABOVE:
            return indicatorValue > threshold;

         default:
            return false;
      }
   }

   // インジケーター値を取得（MQL4/MQL5共通）
   double GetIndicatorValue(int buffer, int shift)
   {
#ifdef __MQL5__
      double value[1] = {EMPTY_VALUE};
      if(CopyBuffer(m_indicatorHandle, buffer, shift, 1, value) <= 0)
      {
         return EMPTY_VALUE;
      }
      return value[0];
#else
      double value = iCustom(_Symbol, (int)InpCustomTimeframe, InpIndicatorName,
                             m_params[0], m_params[1], m_params[2], m_params[3], m_params[4],
                             m_params[5], m_params[6], m_params[7], m_params[8], m_params[9],
                             m_params[10], m_params[11], m_params[12], m_params[13], m_params[14],
                             m_params[15], m_params[16], m_params[17], m_params[18], m_params[19],
                             buffer, shift);
      return value;
#endif
   }

   // 価格データを取得
   double GetPrice(ENUM_APPLIED_PRICE priceType, int shift)
   {
      switch(priceType)
      {
         case PRICE_OPEN:    return iOpen(_Symbol, InpCustomTimeframe, shift);
         case PRICE_HIGH:    return iHigh(_Symbol, InpCustomTimeframe, shift);
         case PRICE_LOW:     return iLow(_Symbol, InpCustomTimeframe, shift);
         case PRICE_CLOSE:   return iClose(_Symbol, InpCustomTimeframe, shift);
         case PRICE_MEDIAN:  return (iHigh(_Symbol, InpCustomTimeframe, shift) + iLow(_Symbol, InpCustomTimeframe, shift)) / 2;
         case PRICE_TYPICAL: return (iHigh(_Symbol, InpCustomTimeframe, shift) + iLow(_Symbol, InpCustomTimeframe, shift) + iClose(_Symbol, InpCustomTimeframe, shift)) / 3;
         case PRICE_WEIGHTED:return (iOpen(_Symbol, InpCustomTimeframe, shift) + iHigh(_Symbol, InpCustomTimeframe, shift) + iLow(_Symbol, InpCustomTimeframe, shift) + iClose(_Symbol, InpCustomTimeframe, shift)) / 4;
         default:            return iClose(_Symbol, InpCustomTimeframe, shift);
      }
   }

   // ポジション数を取得（Hosopi3関数を使用）
   int PositionCount(int posType)
   {
      return position_count(posType);
   }

   // ポジションを決済（リアル+ゴースト両方）
   void ClosePosition(int posType, bool isPartial)
   {
      // リアルポジションを決済
      if(position_count(posType) > 0)
      {
         position_close(posType);
      }

      // ゴーストポジションもリセット
      if(ghost_position_count(posType) > 0)
      {
         ResetSpecificGhost(posType);
      }
   }

   // 買い注文を実行（戦略エントリーと同じ仕組みでゴースト→リアル）
   void ExecuteBuyOrder(int side, bool isNanpin)
   {
      int operationType = OP_BUY;
      int totalPositionCount = combined_position_count(operationType);
      int currentLevel = totalPositionCount + 1;

      // ナンピンスキップレベルのチェック
      if(NanpinSkipLevel != SKIP_NONE && currentLevel <= (int)NanpinSkipLevel)
      {
         // ゴーストエントリー
         double price = GetAskPrice();
         double lot = g_LotTable[currentLevel - 1];
         string comment = "インジケーター買いシグナル Lv" + IntegerToString(currentLevel);

         if(EnableGhostEntry)
         {
            ExecuteGhostEntry(operationType, price, lot, comment, currentLevel);
         }
      }
      else
      {
         // リアルエントリー
         ExecuteRealEntry(OP_BUY, "インジケーター買いシグナル");
      }
   }

   // 売り注文を実行（戦略エントリーと同じ仕組みでゴースト→リアル）
   void ExecuteSellOrder(int side, bool isNanpin)
   {
      int operationType = OP_SELL;
      int totalPositionCount = combined_position_count(operationType);
      int currentLevel = totalPositionCount + 1;

      // ナンピンスキップレベルのチェック
      if(NanpinSkipLevel != SKIP_NONE && currentLevel <= (int)NanpinSkipLevel)
      {
         // ゴーストエントリー
         double price = GetBidPrice();
         double lot = g_LotTable[currentLevel - 1];
         string comment = "インジケーター売りシグナル Lv" + IntegerToString(currentLevel);

         if(EnableGhostEntry)
         {
            ExecuteGhostEntry(operationType, price, lot, comment, currentLevel);
         }
      }
      else
      {
         // リアルエントリー
         ExecuteRealEntry(OP_SELL, "インジケーター売りシグナル");
      }
   }

   // 事前チェック（スプレッド、時間フィルターなど）
   bool PreOrderChecks(string orderType, bool isNanpin)
   {
      // スプレッドチェック
      if((GetAskPrice() - GetBidPrice()) / GetPointValue() > MaxSpreadPoints && MaxSpreadPoints > 0)
      {
         Print("スプレッドが大きすぎるため、", orderType, "はスキップされました");
         return false;
      }

      return true;
   }
};

// グローバルインスタンス
IndicatorEntryManager g_indicatorManager;

//==================================================================
// 関数エクスポート
//==================================================================

// 初期化関数
bool InitializeIndicatorEntry()
{
   return g_indicatorManager.Initialize();
}

// 条件チェック関数（名前を変更）
void ProcessIndicatorEntry()
{
   g_indicatorManager.CheckConditions();
}

//------------------------------------------------------------------
//| インジケーターエントリー設定が有効かを外部から確認するための関数 |
//------------------------------------------------------------------
bool IndicatorEntryHasConfiguration()
{
   bool hasEntryCondition = InpEnableBuySignal  || InpEnableSellSignal  ||
                            InpEnableBuyPrice   || InpEnableSellPrice   ||
                            InpEnableBuyValue   || InpEnableSellValue   ||
                            InpEnableBuySignalObject || InpEnableSellSignalObject;

   bool hasExitCondition  = InpEnableBuyExitSignal  || InpEnableSellExitSignal  ||
                            InpEnableBuyExitPrice   || InpEnableSellExitPrice   ||
                            InpEnableBuyExitValue   || InpEnableSellExitValue   ||
                            InpEnableBuyExitObject || InpEnableSellExitObject;

   switch(InpIndicatorMode)
   {
      case INDICATOR_ENTRY_ONLY:
         return hasEntryCondition;
      case INDICATOR_EXIT_ONLY:
         return hasExitCondition;
      case INDICATOR_ENTRY_AND_EXIT:
         return hasEntryCondition || hasExitCondition;
      default:
         return false;
   }
}

//------------------------------------------------------------------
//| Infoパネル表示用のインジケーター名を取得                         |
//------------------------------------------------------------------
string IndicatorEntryDisplayName()
{
   if(StringLen(InpIndicatorName) == 0)
      return "Custom";

   if(InpIndicatorName == "Your_Custom_Indicator")
      return "Custom";

   return InpIndicatorName;
}

//------------------------------------------------------------------
//| 戦略システムから呼ばれるシグナルチェック関数                      |
//------------------------------------------------------------------
bool CheckIndicatorEntrySignal(int side)
{
   // エントリーモードがエントリー無効の場合はfalse
   if(InpIndicatorMode == INDICATOR_EXIT_ONLY)
      return false;

   // 有効な条件がない場合はfalse
   if(!IndicatorEntryHasConfiguration())
      return false;

   // 買い/売りシグナルをチェック
   bool isBuy = (side == 0);

   if(isBuy)
      return g_indicatorManager.ShouldBuy();
   else
      return g_indicatorManager.ShouldSell();
}

#endif // HOSOPI3_INDICATOR_ENTRY_MQH
