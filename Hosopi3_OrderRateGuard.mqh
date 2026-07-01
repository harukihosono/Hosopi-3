//+------------------------------------------------------------------+
//|                                      Hosopi3_OrderRateGuard.mqh   |
//|                 注文レートガード（過剰オーダー抑制）              |
//|                 ELDRA2 Risk/ELDRA_OrderRateGuard.mqh を移植       |
//|                                                                   |
//| ブローカーサーバーへの注文系メッセージ送信回数を監視し、過剰な    |
//| 場合に新規エントリーを一時停止するサーキットブレーカー。          |
//|  1. 連続失敗ブレーカー: 注文失敗が連続したら一時停止。繰り返すと  |
//|     エスカレーション（60秒→2倍→最大30分）。指定回数の一時停止後は |
//|     完全停止（指定分後に自動復帰、0でEA再起動まで）。             |
//|     ※成功で失敗カウントは即リセット（正当な連続発注では作動しない）|
//|  2. レート監視: 直近60秒の注文操作数が上限超過でクールダウン      |
//|  3. サーバー応答: TOO_MANY_REQUESTS(MT5:10024/MT4:4,8,137,141)で  |
//|     即時バックオフ（30秒→2倍→最大300秒）                          |
//|  4. ブロック対象: 新規エントリー/ナンピンのみ。決済・SL変更は許可 |
//|                                                                   |
//| 入力は Hosopi3_AllParams_MQL5/MQL4.mqh「39. 注文レートガード設定」 |
//+------------------------------------------------------------------+
#ifndef HOSOPI3_ORDERRATEGUARD_MQH
#define HOSOPI3_ORDERRATEGUARD_MQH

// --- 内部状態 ---
int      g_ORG_Buckets[60];                 // 秒単位のリングバッファ（直近60秒の操作数）
long     g_ORG_BucketEpoch[60];             // 各バケットのエポック秒
datetime g_ORG_SuspendUntil = 0;            // 一時停止解除時刻
int      g_ORG_ServerLimitHits = 0;         // サーバーレート制限の連続検出回数
datetime g_ORG_LastServerLimitHit = 0;      // 最後にサーバーレート制限を検出した時刻
datetime g_ORG_LastTripLog = 0;             // 作動ログのスロットル
bool     g_ORG_LabelShown = false;          // 警告ラベル表示中フラグ
int      g_ORG_ConsecFails = 0;             // 連続注文失敗回数（成功でリセット）
int      g_ORG_FailTrips = 0;               // 連続失敗による一時停止回数（成功でリセット）
bool     g_ORG_HardStopped = false;         // 完全停止フラグ
datetime g_ORG_HardStopUntil = 0;           // 完全停止からの自動復帰時刻（0=自動復帰しない）
datetime g_ORG_LastBlockLog = 0;            // ブロックログのスロットル

#define ORG_SERVER_LIMIT_BASE_COOLDOWN  30   // サーバーレート制限時の初期バックオフ（秒）
#define ORG_SERVER_LIMIT_MAX_COOLDOWN   300  // サーバーレート制限時の最大バックオフ（秒）
#define ORG_ESCALATION_RESET_SEC        1800 // この秒数レート制限が無ければエスカレーションをリセット
#define ORG_FAIL_TRIP_BASE_COOLDOWN     60   // 連続失敗時の初期クールダウン（秒）
#define ORG_FAIL_TRIP_MAX_COOLDOWN      1800 // 連続失敗時の最大クールダウン（秒）

//+------------------------------------------------------------------+
//| 警告ラベル表示／削除                                              |
//+------------------------------------------------------------------+
string OrderRateGuardLabelName()
{
   return g_ObjectPrefix + "OrderRateGuardWarn";
}

void OrderRateGuardShowLabel(string reason)
{
   string name = OrderRateGuardLabelName();
   long chartWidth = ChartGetInteger(0, CHART_WIDTH_IN_PIXELS);
   int x = (int)MathMax(10, chartWidth / 2 - 220);
   string txt = "【注文レートガード作動中】注文操作を一時停止: " + reason;
#ifdef __MQL5__
   if(ObjectFind(0, name) < 0)
   {
      ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
      ObjectSetInteger(0, name, OBJPROP_YDISTANCE, 28);
      ObjectSetInteger(0, name, OBJPROP_COLOR, clrOrange);
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
      ObjectSet(name, OBJPROP_YDISTANCE, 28);
      ObjectSet(name, OBJPROP_SELECTABLE, false);
      ObjectSet(name, OBJPROP_HIDDEN, true);
      ObjectSet(name, OBJPROP_ZORDER, 3300);
   }
   ObjectSetText(name, txt, 11, "Meiryo UI", clrOrange);
#endif
   g_ORG_LabelShown = true;
   ChartRedraw(0);
}

void OrderRateGuardHideLabel()
{
   if(!g_ORG_LabelShown) return;
   string name = OrderRateGuardLabelName();
#ifdef __MQL5__
   if(ObjectFind(0, name) >= 0) ObjectDelete(0, name);
#else
   if(ObjectFind(name) >= 0) ObjectDelete(name);
#endif
   g_ORG_LabelShown = false;
   ChartRedraw(0);
}

//+------------------------------------------------------------------+
//| 注文操作を記録（サーバーへ実際に送信された操作のみ）              |
//+------------------------------------------------------------------+
void OrderRateGuard_Record()
{
   if(!EnableOrderRateGuard) return;
   long epochSec = (long)TimeCurrent();
   int idx = (int)(epochSec % 60);
   if(g_ORG_BucketEpoch[idx] != epochSec)
   {
      g_ORG_Buckets[idx] = 0;
      g_ORG_BucketEpoch[idx] = epochSec;
   }
   g_ORG_Buckets[idx]++;
}

//+------------------------------------------------------------------+
//| 直近60秒の注文操作数を集計                                        |
//+------------------------------------------------------------------+
int OrderRateGuard_CountLastMinute()
{
   long nowSec = (long)TimeCurrent();
   int total = 0;
   for(int i = 0; i < 60; i++)
   {
      if(nowSec - g_ORG_BucketEpoch[i] < 60)
         total += g_ORG_Buckets[i];
   }
   return total;
}

//+------------------------------------------------------------------+
//| ガード状態を全リセット                                            |
//+------------------------------------------------------------------+
void OrderRateGuard_Reset(string reason)
{
   g_ORG_HardStopped     = false;
   g_ORG_HardStopUntil   = 0;
   g_ORG_SuspendUntil    = 0;
   g_ORG_ConsecFails     = 0;
   g_ORG_FailTrips       = 0;
   g_ORG_ServerLimitHits = 0;
   Print("[OrderRateGuard] ", reason, " → 新規注文を再開します");
   OrderRateGuardHideLabel();
}

//+------------------------------------------------------------------+
//| 完全停止                                                          |
//+------------------------------------------------------------------+
void OrderRateGuard_HardStop(string context)
{
   if(g_ORG_HardStopped) return;
   g_ORG_HardStopped = true;

   string reason = StringFormat("注文失敗による一時停止が %d 回繰り返されたため完全停止 (%s)",
                                g_ORG_FailTrips, context);

   if(OrderFailAutoRecoverMin > 0)
   {
      g_ORG_HardStopUntil = TimeCurrent() + (datetime)((long)OrderFailAutoRecoverMin * 60);
      Print("[OrderRateGuard] ", reason, StringFormat(" - %d分後に自動復帰します", OrderFailAutoRecoverMin));
      if(!FundsGuard_IsTester())
         Alert("【Hosopi3】注文ガード完全停止: ", reason, StringFormat(" - %d分後に自動復帰します", OrderFailAutoRecoverMin));
      OrderRateGuardShowLabel(reason + StringFormat("（%d分後に自動復帰）", OrderFailAutoRecoverMin));
   }
   else
   {
      g_ORG_HardStopUntil = 0;
      Print("[OrderRateGuard] ", reason, " - 新規注文を停止しました。原因を確認してEAを再起動してください");
      if(!FundsGuard_IsTester())
         Alert("【Hosopi3】注文ガード完全停止: ", reason, " - EA再起動まで新規注文を行いません");
      OrderRateGuardShowLabel(reason + "（EA再起動まで停止）");
   }
}

//+------------------------------------------------------------------+
//| 注文結果を記録（連続失敗ブレーカーの主トリガー）                  |
//+------------------------------------------------------------------+
void OrderRateGuard_RecordResult(bool success, string context)
{
   if(!EnableOrderRateGuard) return;

   if(success)
   {
      g_ORG_ConsecFails = 0;
      g_ORG_FailTrips = 0;
      return;
   }

   if(OrderFailStopCount <= 0) return;

   g_ORG_ConsecFails++;
   if(g_ORG_ConsecFails < OrderFailStopCount) return;

   // 連続失敗が上限到達 → 一時停止（繰り返すごとにクールダウンを2倍に拡大）
   g_ORG_ConsecFails = 0;
   g_ORG_FailTrips++;

   if(OrderFailHardStopTrips > 0 && g_ORG_FailTrips >= OrderFailHardStopTrips)
   {
      OrderRateGuard_HardStop(context);
      return;
   }

   int cooldown = ORG_FAIL_TRIP_BASE_COOLDOWN;
   for(int i = 1; i < g_ORG_FailTrips && cooldown < ORG_FAIL_TRIP_MAX_COOLDOWN; i++)
      cooldown *= 2;
   if(cooldown > ORG_FAIL_TRIP_MAX_COOLDOWN) cooldown = ORG_FAIL_TRIP_MAX_COOLDOWN;

   datetime now = TimeCurrent();
   datetime until = now + cooldown;
   if(until > g_ORG_SuspendUntil) g_ORG_SuspendUntil = until;

   string reason = StringFormat("注文失敗が %d 回連続 (%s) → %d秒間停止（%d回目/%d回で完全停止）",
                                OrderFailStopCount, context, cooldown,
                                g_ORG_FailTrips, OrderFailHardStopTrips);
   Print("[OrderRateGuard] ", reason);
   if(!FundsGuard_IsTester() && g_ORG_FailTrips <= 3)
      Alert("【Hosopi3】注文レートガード作動: ", reason);
   OrderRateGuardShowLabel(reason);
}

//+------------------------------------------------------------------+
//| ガード作動中か（新規エントリーをブロックすべきか）                |
//+------------------------------------------------------------------+
bool OrderRateGuard_Blocked()
{
   if(!EnableOrderRateGuard) return false;

   if(g_ORG_HardStopped) return true;

   datetime now = TimeCurrent();
   if(now < g_ORG_SuspendUntil) return true;

   // レート監視（上限超過でクールダウン開始）
   if(OrderRateMaxPerMin > 0)
   {
      int count = OrderRateGuard_CountLastMinute();
      if(count >= OrderRateMaxPerMin)
      {
         int cooldown = (OrderRateCooldownSec > 0) ? OrderRateCooldownSec : 60;
         g_ORG_SuspendUntil = now + cooldown;
         string reason = StringFormat("直近60秒の注文操作 %d 回が上限 %d 回を超過（%d秒間停止）",
                                      count, OrderRateMaxPerMin, cooldown);
         if(now - g_ORG_LastTripLog >= 30)
         {
            g_ORG_LastTripLog = now;
            Print("[OrderRateGuard] ", reason);
            if(!FundsGuard_IsTester())
               Alert("【Hosopi3】注文レートガード作動: ", reason);
         }
         OrderRateGuardShowLabel(reason);
         return true;
      }
   }
   return false;
}

//+------------------------------------------------------------------+
//| サーバーがレート制限エラーを返した時のバックオフ                  |
//+------------------------------------------------------------------+
void OrderRateGuard_OnServerRateLimit(string context)
{
   if(!EnableOrderRateGuard) return;

   datetime now = TimeCurrent();

   if(g_ORG_LastServerLimitHit > 0 && now - g_ORG_LastServerLimitHit > ORG_ESCALATION_RESET_SEC)
      g_ORG_ServerLimitHits = 0;

   g_ORG_ServerLimitHits++;
   g_ORG_LastServerLimitHit = now;

   int cooldown = ORG_SERVER_LIMIT_BASE_COOLDOWN;
   for(int i = 1; i < g_ORG_ServerLimitHits && cooldown < ORG_SERVER_LIMIT_MAX_COOLDOWN; i++)
      cooldown *= 2;
   if(cooldown > ORG_SERVER_LIMIT_MAX_COOLDOWN) cooldown = ORG_SERVER_LIMIT_MAX_COOLDOWN;

   datetime until = now + cooldown;
   if(until > g_ORG_SuspendUntil) g_ORG_SuspendUntil = until;

   string reason = StringFormat("サーバーがレート制限を通知 (%s) → %d秒バックオフ（%d回目）",
                                context, cooldown, g_ORG_ServerLimitHits);
   Print("[OrderRateGuard] ", reason);
   if(!FundsGuard_IsTester() && g_ORG_ServerLimitHits <= 3)
      Alert("【Hosopi3】注文レートガード: ", reason);
   OrderRateGuardShowLabel(reason);
}

//+------------------------------------------------------------------+
//| 状態更新（毎tick呼び出し）                                         |
//+------------------------------------------------------------------+
void OrderRateGuard_Update()
{
   if(g_ORG_HardStopped)
   {
      if(g_ORG_HardStopUntil > 0 && TimeCurrent() >= g_ORG_HardStopUntil)
         OrderRateGuard_Reset("完全停止からの自動復帰");
      return;
   }

   if(g_ORG_LabelShown && TimeCurrent() >= g_ORG_SuspendUntil)
   {
      Print("[OrderRateGuard] クールダウン終了、注文操作を再開します");
      OrderRateGuardHideLabel();
   }
}

//+------------------------------------------------------------------+
//| ブロックログ（60秒スロットル）                                    |
//+------------------------------------------------------------------+
void OrderRateGuardLogBlocked(string context)
{
   datetime now = TimeCurrent();
   if(now - g_ORG_LastBlockLog < 60) return;
   g_ORG_LastBlockLog = now;
   if(g_ORG_HardStopped)
   {
      if(g_ORG_HardStopUntil > 0)
         PrintFormat("[OrderRateGuard] 注文操作を拒否(%s): 完全停止中（自動復帰まで残り%d秒）",
                     context, (int)(g_ORG_HardStopUntil - now));
      else
         PrintFormat("[OrderRateGuard] 注文操作を拒否(%s): 完全停止中（EA再起動まで）", context);
      return;
   }
   PrintFormat("[OrderRateGuard] 注文操作を拒否(%s): クールダウン中（残り%d秒）",
               context, (int)(g_ORG_SuspendUntil - now));
}

//+------------------------------------------------------------------+
//| サーバー応答がレート制限エラーか判定（MT5/MT4）                   |
//+------------------------------------------------------------------+
bool OrderRateGuard_IsServerRateLimit(uint errorCode, uint retcode)
{
   if(retcode == 10024) return true;              // MT5 TRADE_RETCODE_TOO_MANY_REQUESTS
   switch(errorCode) {
      case 4:    // MT4 ERR_SERVER_BUSY
      case 8:    // MT4 ERR_TOO_FREQUENT_REQUESTS
      case 137:  // MT4 ERR_BROKER_BUSY
      case 141:  // MT4 ERR_TOO_MANY_REQUESTS
         return true;
   }
   return false;
}

#endif // HOSOPI3_ORDERRATEGUARD_MQH
