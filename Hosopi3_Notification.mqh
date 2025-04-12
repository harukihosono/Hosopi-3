//+------------------------------------------------------------------+
//|                Hosopi 3 - ゴースト通知機能                        |
//|                       Copyright 2025                             |
//+------------------------------------------------------------------+
#include "Hosopi3_Defines.mqh"

//+------------------------------------------------------------------+
//| ゴースト通知設定パラメータ                                        |
//+------------------------------------------------------------------+
sinput string Comment_GhostNotification = ""; //+--- ゴースト通知設定 ---+
input bool EnableGhostAlertNotification = true;    // ゴーストアラート通知を有効にする
input bool EnableGhostPushNotification = false;    // ゴーストプッシュ通知を有効にする
input bool NotifyGhostEntries = true;              // ゴーストエントリー通知
input bool NotifyGhostClosures = true;             // ゴースト決済通知

//+------------------------------------------------------------------+
//| ゴースト通知送信関数                                              |
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
      if(TerminalInfoInteger(TERMINAL_NOTIFICATIONS_ENABLED))
      {
         SendNotification(message);
      }
      else
      {
         Print("プッシュ通知の送信に失敗しました - ターミナルでプッシュ通知が有効になっていません");
      }
   }
}

//+------------------------------------------------------------------+
//| ゴーストエントリー通知                                            |
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
//| ゴースト決済通知                                                 |
//+------------------------------------------------------------------+
void NotifyGhostClosure(int type, double profit)
{
   // 通知が無効の場合はスキップ
   if(!NotifyGhostClosures)
      return;
      
   string typeStr = (type == OP_BUY) ? "Buy" : "Sell";
   string message = "Hosopi 3: ゴースト" + typeStr + "決済" +
                    " | 利益: " + DoubleToString(profit, 2) + "円";
   
   // 通知送信
   SendGhostNotification(message, EnableGhostAlertNotification, EnableGhostPushNotification);
}