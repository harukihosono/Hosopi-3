//+------------------------------------------------------------------+
//|                Hosopi 3 - ゴースト通知機能 (MQL4/MQL5共通)        |
//|                       Copyright 2025                             |
//+------------------------------------------------------------------+
#include "Hosopi3_Defines.mqh"

//+------------------------------------------------------------------+
//| ゴースト通知送信関数 (MQL4/MQL5共通)                             |
//+------------------------------------------------------------------+
void SendGhostNotification(string message, bool isAlert = true, bool isPush = true)
{
   // 実行時のチェック（デバッグ用）
   Print("SendGhostNotification: " + message + ", アラート=" + (isAlert ? "ON" : "OFF") + ", プッシュ=" + (isPush ? "ON" : "OFF"));
   
   // アラート通知（チャート上のポップアップ）
   if(EnableGhostAlertNotification && isAlert)
   {
      Alert(message);
   }
   
   // プッシュ通知（モバイルアプリへの通知）
   if(EnableGhostPushNotification && isPush)
   {
      // プッシュ通知が有効になっているか確認
      bool notificationsEnabled = false;
      
#ifdef __MQL5__
      notificationsEnabled = (bool)TerminalInfoInteger(TERMINAL_NOTIFICATIONS_ENABLED);
#else
      // MQL4では直接確認する方法がないため、SendNotificationの結果で判断
      notificationsEnabled = true;
#endif
      
      if(notificationsEnabled)
      {
         bool result = SendNotification(message);
         if(!result)
         {
            Print("プッシュ通知の送信に失敗しました");
         }
      }
      else
      {
         Print("プッシュ通知の送信に失敗しました - ターミナルでプッシュ通知が有効になっていません");
      }
   }
}

//+------------------------------------------------------------------+
//| ゴーストエントリー通知 (MQL4/MQL5共通)                           |
//+------------------------------------------------------------------+
void NotifyGhostEntry(int type, double lots, double price, int level)
{
   // 通知が無効の場合はスキップ
   if(!NotifyGhostEntries)
      return;
      
   string typeStr = (type == OP_BUY) ? "Buy" : "Sell";
   string message = "Hosopi 3: ゴースト" + typeStr + "エントリー" +
                    " | レベル: " + IntegerToString(level + 1) +
                    " | ロット: " + DoubleToString(lots, 2) +
                    " | 価格: " + DoubleToString(price, Digits);
   
   // 通知送信
   SendGhostNotification(message, EnableGhostAlertNotification, EnableGhostPushNotification);
}

//+------------------------------------------------------------------+
//| ゴースト決済通知 (MQL4/MQL5共通)                                 |
//+------------------------------------------------------------------+
void NotifyGhostClosure(int type, double profit)
{
   // 通知が無効の場合はスキップ
   if(!NotifyGhostClosures)
      return;
      
   string typeStr = (type == OP_BUY) ? "Buy" : "Sell";
   
   // 通貨記号を取得
   string currencySymbol = "";
#ifdef __MQL5__
   currencySymbol = AccountInfoString(ACCOUNT_CURRENCY);
#else
   currencySymbol = AccountCurrency();
#endif
   
   string message = "Hosopi 3: ゴースト" + typeStr + "決済" +
                    " | 利益: " + DoubleToString(profit, 2) + " " + currencySymbol;
   
   // 通知送信
   SendGhostNotification(message, EnableGhostAlertNotification, EnableGhostPushNotification);
}

//+------------------------------------------------------------------+
//| リアルポジションエントリー通知 (MQL4/MQL5共通)                    |
//+------------------------------------------------------------------+
void NotifyRealEntry(int type, double lots, double price, string reason)
{
   // 通知設定をチェック（必要に応じて追加のinputパラメータを定義）
   // if(!NotifyRealEntries) return;
   
   string typeStr = (type == OP_BUY) ? "Buy" : "Sell";
   string message = "Hosopi 3: " + typeStr + "エントリー" +
                    " | ロット: " + DoubleToString(lots, 2) +
                    " | 価格: " + DoubleToString(price, Digits) +
                    " | 理由: " + reason;
   
   // アラート通知のみ（プッシュ通知は必要に応じて設定）
   if(EnableGhostAlertNotification)
   {
      Alert(message);
   }
   
   // プッシュ通知も送信（リアルエントリーは重要なので）
   if(EnableGhostPushNotification)
   {
      bool notificationsEnabled = false;
      
#ifdef __MQL5__
      notificationsEnabled = (bool)TerminalInfoInteger(TERMINAL_NOTIFICATIONS_ENABLED);
#else
      notificationsEnabled = true;
#endif
      
      if(notificationsEnabled)
      {
         bool result = SendNotification(message);
         if(!result)
         {
            Print("リアルエントリー通知の送信に失敗しました");
         }
      }
   }
   
   // ログにも記録
   Print(message);
}

//+------------------------------------------------------------------+
//| エラー通知 (MQL4/MQL5共通)                                        |
//+------------------------------------------------------------------+
void NotifyError(string operation, int errorCode)
{
   string message = "Hosopi 3 エラー: " + operation + 
                    " | エラーコード: " + IntegerToString(errorCode) +
                    " | 説明: " + ErrorDescription(errorCode);
   
   Print(message);
   
   // 重要なエラーの場合はアラート
   if(EnableGhostAlertNotification)
   {
      Alert(message);
   }
}

//+------------------------------------------------------------------+
//| エラーコードの説明を取得 (MQL4/MQL5共通)                         |
//+------------------------------------------------------------------+
string ErrorDescription(int errorCode)
{
#ifdef __MQL5__
   // MQL5のエラーコード
   switch(errorCode)
   {
      case TRADE_RETCODE_REQUOTE: return "リクオート";
      case TRADE_RETCODE_REJECT: return "リクエスト拒否";
      case TRADE_RETCODE_CANCEL: return "トレーダーによるキャンセル";
      case TRADE_RETCODE_PLACED: return "注文配置";
      case TRADE_RETCODE_DONE: return "リクエスト完了";
      case TRADE_RETCODE_DONE_PARTIAL: return "リクエスト部分実行";
      case TRADE_RETCODE_ERROR: return "リクエスト処理エラー";
      case TRADE_RETCODE_TIMEOUT: return "リクエストタイムアウト";
      case TRADE_RETCODE_INVALID: return "無効なリクエスト";
      case TRADE_RETCODE_INVALID_VOLUME: return "無効なボリューム";
      case TRADE_RETCODE_INVALID_PRICE: return "無効な価格";
      case TRADE_RETCODE_INVALID_STOPS: return "無効なストップ";
      case TRADE_RETCODE_TRADE_DISABLED: return "取引無効";
      case TRADE_RETCODE_MARKET_CLOSED: return "市場クローズ";
      case TRADE_RETCODE_NO_MONEY: return "資金不足";
      case TRADE_RETCODE_PRICE_CHANGED: return "価格変更";
      case TRADE_RETCODE_PRICE_OFF: return "価格オフ";
      case TRADE_RETCODE_INVALID_EXPIRATION: return "無効な有効期限";
      case TRADE_RETCODE_ORDER_CHANGED: return "注文状態変更";
      case TRADE_RETCODE_TOO_MANY_REQUESTS: return "リクエスト過多";
      default: return "不明なエラー";
   }
#else
   // MQL4のエラーコード
   switch(errorCode)
   {
      case ERR_NO_ERROR: return "エラーなし";
      case ERR_NO_RESULT: return "エラーなしだが結果不明";
      case ERR_COMMON_ERROR: return "一般的なエラー";
      case ERR_INVALID_TRADE_PARAMETERS: return "無効な取引パラメータ";
      case ERR_SERVER_BUSY: return "トレードサーバーがビジー";
      case ERR_OLD_VERSION: return "古いバージョンのクライアント端末";
      case ERR_NO_CONNECTION: return "トレードサーバーに接続なし";
      case ERR_NOT_ENOUGH_RIGHTS: return "権限不足";
      case ERR_TOO_FREQUENT_REQUESTS: return "リクエストが頻繁すぎる";
      case ERR_MALFUNCTIONAL_TRADE: return "不正な取引操作";
      case ERR_ACCOUNT_DISABLED: return "アカウント無効";
      case ERR_INVALID_ACCOUNT: return "無効なアカウント";
      case ERR_TRADE_TIMEOUT: return "トレードタイムアウト";
      case ERR_INVALID_PRICE: return "無効な価格";
      case ERR_INVALID_STOPS: return "無効なストップ";
      case ERR_INVALID_TRADE_VOLUME: return "無効な取引量";
      case ERR_MARKET_CLOSED: return "市場がクローズ";
      case ERR_TRADE_DISABLED: return "取引無効";
      case ERR_NOT_ENOUGH_MONEY: return "資金不足";
      case ERR_PRICE_CHANGED: return "価格変更";
      case ERR_OFF_QUOTES: return "オフクオート";
      case ERR_BROKER_BUSY: return "ブローカービジー";
      case ERR_REQUOTE: return "リクオート";
      case ERR_ORDER_LOCKED: return "注文ロック";
      case ERR_LONG_POSITIONS_ONLY_ALLOWED: return "ロングポジションのみ許可";
      case ERR_TOO_MANY_REQUESTS: return "リクエスト過多";
      case ERR_TRADE_MODIFY_DENIED: return "変更拒否";
      case ERR_TRADE_CONTEXT_BUSY: return "トレードコンテキストビジー";
      default: return "不明なエラー";
   }
#endif
}

//+------------------------------------------------------------------+
//| リアルポジション決済通知 (MQL4/MQL5共通)                          |
//+------------------------------------------------------------------+
void NotifyRealClosure(int type, double profit, string reason = "")
{
   string typeStr = (type == OP_BUY) ? "Buy" : "Sell";
   
   // 通貨記号を取得
   string currencySymbol = "";
#ifdef __MQL5__
   currencySymbol = AccountInfoString(ACCOUNT_CURRENCY);
#else
   currencySymbol = AccountCurrency();
#endif
   
   string message = "Hosopi 3: " + typeStr + "決済" +
                    " | 利益: " + DoubleToString(profit, 2) + " " + currencySymbol;
   
   if(reason != "")
   {
      message += " | 理由: " + reason;
   }
   
   // アラート通知
   if(EnableGhostAlertNotification)
   {
      Alert(message);
   }
   
   // プッシュ通知
   if(EnableGhostPushNotification)
   {
      bool notificationsEnabled = false;
      
#ifdef __MQL5__
      notificationsEnabled = (bool)TerminalInfoInteger(TERMINAL_NOTIFICATIONS_ENABLED);
#else
      notificationsEnabled = true;
#endif
      
      if(notificationsEnabled)
      {
         bool result = SendNotification(message);
         if(!result)
         {
            Print("決済通知の送信に失敗しました");
         }
      }
   }
   
   // ログにも記録
   Print(message);
}

//+------------------------------------------------------------------+
//| 一括決済通知 (MQL4/MQL5共通)                                     |
//+------------------------------------------------------------------+
void NotifyCloseAll(double totalProfit)
{
   // 通貨記号を取得
   string currencySymbol = "";
#ifdef __MQL5__
   currencySymbol = AccountInfoString(ACCOUNT_CURRENCY);
#else
   currencySymbol = AccountCurrency();
#endif
   
   string message = "Hosopi 3: 全ポジション決済" +
                    " | 総利益: " + DoubleToString(totalProfit, 2) + " " + currencySymbol;
   
   // アラート通知
   if(EnableGhostAlertNotification)
   {
      Alert(message);
   }
   
   // プッシュ通知
   if(EnableGhostPushNotification)
   {
      bool notificationsEnabled = false;
      
#ifdef __MQL5__
      notificationsEnabled = (bool)TerminalInfoInteger(TERMINAL_NOTIFICATIONS_ENABLED);
#else
      notificationsEnabled = true;
#endif
      
      if(notificationsEnabled)
      {
         bool result = SendNotification(message);
         if(!result)
         {
            Print("一括決済通知の送信に失敗しました");
         }
      }
   }
   
   // ログにも記録
   Print(message);
}

//+------------------------------------------------------------------+
//| システム通知 (MQL4/MQL5共通)                                      |
//+------------------------------------------------------------------+
void NotifySystem(string message, bool isImportant = false)
{
   string fullMessage = "Hosopi 3 システム: " + message;
   
   // ログに記録
   Print(fullMessage);
   
   // 重要な通知の場合のみアラート
   if(isImportant && EnableGhostAlertNotification)
   {
      Alert(fullMessage);
   }
}