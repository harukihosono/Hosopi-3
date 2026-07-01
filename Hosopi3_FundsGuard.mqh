//+------------------------------------------------------------------+
//|                                          Hosopi3_FundsGuard.mqh   |
//|                  資金不足ガード（発注前ブロック）                 |
//|                  ELDRA2 ELDRA_FundsGuard.mqh を移植               |
//|                                                                   |
//| 有効証拠金・余剰証拠金が不足している場合、新規/ナンピンエントリー |
//| を OrderSend 送信前にブロックする。資金枯渇口座でEAが発注試行を   |
//| 繰り返しブローカーサーバーへ過剰送信するのを防止する。           |
//|                                                                   |
//| 作動条件（毎秒評価・すべてクライアント側計算でサーバー負荷なし）  |
//|  1. 有効証拠金 <= 0                                               |
//|  2. 有効証拠金 < 最小ロットの必要証拠金（口座資金枯渇）           |
//|  3. 余剰証拠金 < 最小ロットの必要証拠金                           |
//|  4. 有効証拠金 < 最低有効証拠金（input、0=無効）                  |
//|  5. サーバーがNO_MONEY(10019)/エラー134を返却 → 即時ラッチ        |
//|                                                                   |
//| 解除条件: 余剰証拠金が最小ロット必要証拠金の1.5倍以上に回復       |
//| （ヒステリシスで作動/解除の振動を防止）                           |
//|                                                                   |
//| 入力パラメータ EnableFundsGuard / FundsGuardMinEquity は          |
//| Hosopi3_AllParams_MQL5/MQL4.mqh の「38. 資金不足ガード設定」で定義 |
//+------------------------------------------------------------------+
#ifndef HOSOPI3_FUNDSGUARD_MQH
#define HOSOPI3_FUNDSGUARD_MQH

// --- 内部状態 ---
bool     g_FundsGuardActive = false;            // ガード作動中フラグ
string   g_FundsGuardReason = "";               // 作動理由
datetime g_FundsGuardEngagedAt = 0;             // 作動時刻
datetime g_FundsGuardNoMoneyUntil = 0;          // NO_MONEYラッチの最低継続期限
datetime g_FundsGuardLastEval = 0;              // 評価スロットル（1秒）
datetime g_FundsGuardLastBlockLog = 0;          // ブロックログのスロットル（60秒）

#define FUNDS_GUARD_NO_MONEY_LATCH_SEC  300     // NO_MONEY受信後の最低ガード継続時間（秒）
#define FUNDS_GUARD_RELEASE_FACTOR      1.5     // 解除に必要な余剰証拠金倍率（ヒステリシス）

//+------------------------------------------------------------------+
//| テスター判定                                                     |
//+------------------------------------------------------------------+
bool FundsGuard_IsTester()
{
#ifdef __MQL5__
   return (bool)MQLInfoInteger(MQL_TESTER);
#else
   return (IsTesting() || IsOptimization() || IsVisualMode());
#endif
}

//+------------------------------------------------------------------+
//| ガード作動中か（新規エントリーをブロックすべきか）                |
//+------------------------------------------------------------------+
bool FundsGuardBlocked()
{
   return g_FundsGuardActive;
}

//+------------------------------------------------------------------+
//| 最小ロットの必要証拠金を計算（クライアント側計算のみ）            |
//+------------------------------------------------------------------+
double FundsGuardMinLotMargin()
{
#ifdef __MQL5__
   double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double price  = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   if(minLot <= 0 || price <= 0) return -1;
   double required = 0;
   if(!OrderCalcMargin(ORDER_TYPE_BUY, _Symbol, minLot, price, required)) return -1;
   return required;
#else
   double minLot = MarketInfo(_Symbol, MODE_MINLOT);
   double marginPerLot = MarketInfo(_Symbol, MODE_MARGINREQUIRED);
   if(minLot <= 0 || marginPerLot <= 0) return -1;
   return marginPerLot * minLot;
#endif
}

//+------------------------------------------------------------------+
//| 警告ラベル表示／削除                                              |
//+------------------------------------------------------------------+
string FundsGuardLabelName()
{
   return g_ObjectPrefix + "FundsGuardWarn";
}

void FundsGuardShowLabel()
{
   string name = FundsGuardLabelName();
   long chartWidth = ChartGetInteger(0, CHART_WIDTH_IN_PIXELS);
   int x = (int)MathMax(10, chartWidth / 2 - 220);
   string txt = "【資金不足ガード作動中】新規エントリー停止: " + g_FundsGuardReason;

#ifdef __MQL5__
   if(ObjectFind(0, name) < 0)
   {
      ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
      ObjectSetInteger(0, name, OBJPROP_YDISTANCE, 8);
      ObjectSetInteger(0, name, OBJPROP_COLOR, clrRed);
      ObjectSetString(0, name, OBJPROP_FONT, "Meiryo UI");
      ObjectSetInteger(0, name, OBJPROP_FONTSIZE, 11);
      ObjectSetInteger(0, name, OBJPROP_ANCHOR, ANCHOR_LEFT_UPPER);
      ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
      ObjectSetInteger(0, name, OBJPROP_ZORDER, 3300);
   }
   ObjectSetString(0, name, OBJPROP_TEXT, txt);
#else
   if(ObjectFind(name) < 0)
   {
      ObjectCreate(name, OBJ_LABEL, 0, 0, 0);
      ObjectSet(name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSet(name, OBJPROP_XDISTANCE, x);
      ObjectSet(name, OBJPROP_YDISTANCE, 8);
      ObjectSet(name, OBJPROP_SELECTABLE, false);
      ObjectSet(name, OBJPROP_HIDDEN, true);
      ObjectSet(name, OBJPROP_ZORDER, 3300);
   }
   ObjectSetText(name, txt, 11, "Meiryo UI", clrRed);
#endif
   ChartRedraw(0);
}

void FundsGuardHideLabel()
{
   string name = FundsGuardLabelName();
#ifdef __MQL5__
   if(ObjectFind(0, name) >= 0) { ObjectDelete(0, name); ChartRedraw(0); }
#else
   if(ObjectFind(name) >= 0) { ObjectDelete(name); ChartRedraw(0); }
#endif
}

//+------------------------------------------------------------------+
//| ガード作動                                                        |
//+------------------------------------------------------------------+
void FundsGuardEngage(string reason)
{
   if(g_FundsGuardActive)
   {
      // 作動中は理由の更新のみ
      if(g_FundsGuardReason != reason)
      {
         g_FundsGuardReason = reason;
         FundsGuardShowLabel();
      }
      return;
   }

   g_FundsGuardActive = true;
   g_FundsGuardEngagedAt = TimeCurrent();
   g_FundsGuardReason = reason;
   PrintFormat("[FundsGuard] 資金不足ガード作動: %s → 新規エントリー注文を送信前ブロックします", reason);
   if(!FundsGuard_IsTester())
      Alert("【Hosopi3】資金不足ガード作動: ", reason, " - 新規エントリーを停止しました");
   FundsGuardShowLabel();
}

//+------------------------------------------------------------------+
//| ガード解除                                                        |
//+------------------------------------------------------------------+
void FundsGuardRelease(double equity, double freeMargin)
{
   if(!g_FundsGuardActive) return;
   g_FundsGuardActive = false;
   g_FundsGuardReason = "";
   g_FundsGuardNoMoneyUntil = 0;
   PrintFormat("[FundsGuard] 資金回復を確認、ガード解除: Equity=%.2f FreeMargin=%.2f", equity, freeMargin);
   FundsGuardHideLabel();
}

//+------------------------------------------------------------------+
//| サーバーから資金不足エラーが返った時のラッチ                      |
//| MQL5: TRADE_RETCODE_NO_MONEY(10019) / MQL4: エラー134            |
//| どの発注経路で発生しても以後の発注試行を即時停止する              |
//+------------------------------------------------------------------+
void FundsGuardOnNoMoneyError(string context)
{
   if(!EnableFundsGuard) return;
   g_FundsGuardNoMoneyUntil = TimeCurrent() + FUNDS_GUARD_NO_MONEY_LATCH_SEC;
   FundsGuardEngage("サーバー応答: 資金不足エラー (" + context + ")");
}

//+------------------------------------------------------------------+
//| エントリーブロック時のログ（60秒スロットル）                      |
//+------------------------------------------------------------------+
void FundsGuardLogBlocked(string context)
{
   datetime now = TimeCurrent();
   if(now - g_FundsGuardLastBlockLog < 60) return;
   g_FundsGuardLastBlockLog = now;
   PrintFormat("[FundsGuard] エントリー拒否(%s): %s", context, g_FundsGuardReason);
}

//+------------------------------------------------------------------+
//| ガード状態の更新（毎tick呼び出し、内部で1秒スロットル）            |
//+------------------------------------------------------------------+
void UpdateFundsGuard()
{
   if(!EnableFundsGuard)
   {
      if(g_FundsGuardActive) FundsGuardRelease(0, 0);
      return;
   }

   datetime now = TimeCurrent();
   if(now == g_FundsGuardLastEval) return;  // 1秒スロットル
   g_FundsGuardLastEval = now;

#ifdef __MQL5__
   double equity     = AccountInfoDouble(ACCOUNT_EQUITY);
   double freeMargin = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
#else
   double equity     = AccountEquity();
   double freeMargin = AccountFreeMargin();
#endif
   double minLotMargin = FundsGuardMinLotMargin();

   // --- 作動条件 ---
   bool insufficient = false;
   string reason = "";

   if(equity <= 0)
   {
      insufficient = true;
      reason = StringFormat("有効証拠金ゼロ (Equity=%.2f)", equity);
   }
   else if(minLotMargin > 0 && equity < minLotMargin)
   {
      insufficient = true;
      reason = StringFormat("口座資金枯渇: 有効証拠金 %.2f < 最小ロット必要証拠金 %.2f", equity, minLotMargin);
   }
   else if(minLotMargin > 0 && freeMargin < minLotMargin)
   {
      insufficient = true;
      reason = StringFormat("余剰証拠金不足: %.2f < 最小ロット必要証拠金 %.2f", freeMargin, minLotMargin);
   }
   else if(FundsGuardMinEquity > 0 && equity < FundsGuardMinEquity)
   {
      insufficient = true;
      reason = StringFormat("有効証拠金 %.2f が最低設定値 %.2f 未満", equity, FundsGuardMinEquity);
   }

   if(insufficient)
   {
      FundsGuardEngage(reason);
      return;
   }

   // --- 解除条件（ヒステリシス + NO_MONEYラッチ） ---
   if(g_FundsGuardActive)
   {
      if(now < g_FundsGuardNoMoneyUntil) return;  // NO_MONEYラッチ中は解除しない

      bool recovered = true;
      if(minLotMargin > 0 && freeMargin < minLotMargin * FUNDS_GUARD_RELEASE_FACTOR)
         recovered = false;
      if(FundsGuardMinEquity > 0 && equity < FundsGuardMinEquity)
         recovered = false;

      if(recovered)
         FundsGuardRelease(equity, freeMargin);
   }
}

#endif // HOSOPI3_FUNDSGUARD_MQH
