//+------------------------------------------------------------------+
//|                   Hosopi 3 - GUI関連関数                         |
//|                         Copyright 2025                           |
//+------------------------------------------------------------------+
#include "Hosopi3_Defines.mqh"
#include "Hosopi3_Utils.mqh"
#include "Hosopi3_Trading.mqh"




//+------------------------------------------------------------------+
//| GUIを作成する - ゴーストエントリーボタン追加版                      |
//+------------------------------------------------------------------+
void CreateGUI()
{
   DeleteGUI(); // 既存のGUIを削除
   g_PanelObjectCount = 0; // オブジェクトカウントリセット
   
   // パネル位置を調整
   int adjustedPanelY = PanelY;
   
   // メインパネル背景 - ゴーストボタン追加のため高さを拡大
   CreatePanel("MainPanel", PanelX, adjustedPanelY, PANEL_WIDTH, PANEL_HEIGHT + 170, COLOR_PANEL_BG, COLOR_PANEL_BORDER);
   
   // パネルタイトル
   CreateTitleBar("TitleBar", PanelX, adjustedPanelY, PANEL_WIDTH, TITLE_HEIGHT, COLOR_TITLE_BG, PanelTitle);
   
   int buttonWidth = (PANEL_WIDTH - (PANEL_MARGIN * 3)) / 2; // 2列のボタン用
   int fullWidth = PANEL_WIDTH - (PANEL_MARGIN * 2); // 横いっぱいのボタン用
   
   // ========== 行1: 決済ボタン ==========
   int row1Y = adjustedPanelY + TITLE_HEIGHT + PANEL_MARGIN;
   
   // Sell決済ボタン (左)
   CreateButton("btnCloseSell", "Close Sell", PanelX + PANEL_MARGIN, row1Y, buttonWidth, BUTTON_HEIGHT, COLOR_BUTTON_SELL, COLOR_TEXT_LIGHT);
   
   // Buy決済ボタン (右)
   CreateButton("btnCloseBuy", "Close Buy", PanelX + PANEL_MARGIN * 2 + buttonWidth, row1Y, buttonWidth, BUTTON_HEIGHT, COLOR_BUTTON_BUY, COLOR_TEXT_LIGHT);
   
   // ========== 行2: 全決済ボタン ==========
   int row2Y = row1Y + BUTTON_HEIGHT + PANEL_MARGIN;
   
   // 全決済ボタン（横いっぱい）
   CreateButton("btnCloseAll", "Close All", PanelX + PANEL_MARGIN, row2Y, fullWidth, BUTTON_HEIGHT, COLOR_BUTTON_CLOSE_ALL, COLOR_TEXT_DARK);
   
   // ========== 行3: 直接エントリーボタン ==========
   int row3Y = row2Y + BUTTON_HEIGHT + PANEL_MARGIN * 2; // 間隔を広く
   
   // セクションラベル
   CreateLabel("lblDirectEntry", "【直接エントリー】", PanelX + PANEL_MARGIN, row3Y - 5, COLOR_TEXT_LIGHT);
   
   // Sellエントリーボタン (左)
   CreateButton("btnDirectSell", "SELL NOW", PanelX + PANEL_MARGIN, row3Y + 15, buttonWidth, BUTTON_HEIGHT, COLOR_BUTTON_SELL, COLOR_TEXT_LIGHT);
   
   // Buyエントリーボタン (右)
   CreateButton("btnDirectBuy", "BUY NOW", PanelX + PANEL_MARGIN * 2 + buttonWidth, row3Y + 15, buttonWidth, BUTTON_HEIGHT, COLOR_BUTTON_BUY, COLOR_TEXT_LIGHT);
   
   // ========== 新規追加: 行3.5: ゴーストエントリーボタン ==========
   int row3_5Y = row3Y + BUTTON_HEIGHT + PANEL_MARGIN + 15;
   
   // セクションラベル
   CreateLabel("lblGhostEntry", "【ゴーストエントリー】", PanelX + PANEL_MARGIN, row3_5Y - 5, COLOR_TEXT_LIGHT);
   
   // ゴーストSellエントリーボタン (左)
   CreateButton("btnGhostSell", "GHOST SELL", PanelX + PANEL_MARGIN, row3_5Y + 15, buttonWidth, BUTTON_HEIGHT, COLOR_BUTTON_SELL, COLOR_TEXT_LIGHT);
   
   // ゴーストBuyエントリーボタン (右)
   CreateButton("btnGhostBuy", "GHOST BUY", PanelX + PANEL_MARGIN * 2 + buttonWidth, row3_5Y + 15, buttonWidth, BUTTON_HEIGHT, COLOR_BUTTON_BUY, COLOR_TEXT_LIGHT);
   
   // ========== 行4: 途中からエントリーボタン ==========
   int row4Y = row3_5Y + BUTTON_HEIGHT + PANEL_MARGIN * 2 + 15; // 間隔を広く
   
   // セクションラベル
   CreateLabel("lblLevelEntry", "【レベル指定エントリー】", PanelX + PANEL_MARGIN, row4Y - 5, COLOR_TEXT_LIGHT);
   
   // 現在のゴーストカウントに基づいてレベルを決定
   int buyLevel = ghost_position_count(OP_BUY) + 1;
   int sellLevel = ghost_position_count(OP_SELL) + 1;
   
   // Sellエントリーボタン (左)
   CreateButton("btnLevelSell", "SELL Level " + IntegerToString(sellLevel), PanelX + PANEL_MARGIN, row4Y + 15, buttonWidth, BUTTON_HEIGHT, COLOR_BUTTON_SELL, COLOR_TEXT_LIGHT);
   
   // Buyエントリーボタン (右)
   CreateButton("btnLevelBuy", "BUY Level " + IntegerToString(buyLevel), PanelX + PANEL_MARGIN * 2 + buttonWidth, row4Y + 15, buttonWidth, BUTTON_HEIGHT, COLOR_BUTTON_BUY, COLOR_TEXT_LIGHT);
   
   // ========== 行5: 設定セクション ==========
   int row5Y = row4Y + BUTTON_HEIGHT + PANEL_MARGIN * 2 + 15; // 間隔を広く
   
   // セクションラベル
   CreateLabel("lblSettings", "【設定】", PanelX + PANEL_MARGIN, row5Y - 5, COLOR_TEXT_LIGHT);
   
   // Ghostモードボタン（横いっぱい）
   CreateButton("btnGhostToggle", "GHOST " + (g_GhostMode ? "ON" : "OFF"), 
               PanelX + PANEL_MARGIN, row5Y + 15, fullWidth, BUTTON_HEIGHT, 
               g_GhostMode ? COLOR_BUTTON_ACTIVE : COLOR_BUTTON_INACTIVE, COLOR_TEXT_LIGHT);
   
   // ========== 行6: ゴーストリセットボタン ==========
   int row6Y = row5Y + BUTTON_HEIGHT + PANEL_MARGIN + 15;
   
   // ゴーストリセットボタン（横いっぱい）
   CreateButton("btnResetGhost", "GHOST RESET", PanelX + PANEL_MARGIN, row6Y, fullWidth, BUTTON_HEIGHT, COLOR_BUTTON_INACTIVE, COLOR_TEXT_LIGHT);
   
   // ========== 行7: 平均取得単価表示切替ボタン ==========
   int row7Y = row6Y + BUTTON_HEIGHT + PANEL_MARGIN;
   
   // 平均取得単価表示切替ボタン（横いっぱい）
   CreateButton("btnToggleAvgPrice", "AVG PRICE " + (g_AvgPriceVisible ? "ON" : "OFF"), 
               PanelX + PANEL_MARGIN, row7Y, fullWidth, BUTTON_HEIGHT, 
               g_AvgPriceVisible ? COLOR_BUTTON_ACTIVE : COLOR_BUTTON_INACTIVE, COLOR_TEXT_LIGHT);
   
   // ========== 行8: 情報表示ボタン ==========
   int row8Y = row7Y + BUTTON_HEIGHT + PANEL_MARGIN;
   
   // ロット情報表示ボタン (左)
   CreateButton("btnShowLotTable", "Lot Table", PanelX + PANEL_MARGIN, row8Y, buttonWidth, BUTTON_HEIGHT, COLOR_BUTTON_NEUTRAL, COLOR_TEXT_LIGHT);
   
   // 設定情報表示ボタン (右)
   CreateButton("btnShowSettings", "Settings", PanelX + PANEL_MARGIN * 2 + buttonWidth, row8Y, buttonWidth, BUTTON_HEIGHT, COLOR_BUTTON_NEUTRAL, COLOR_TEXT_LIGHT);
   
   // パネルの高さを調整
   int panelHeight = row8Y + BUTTON_HEIGHT + PANEL_MARGIN - adjustedPanelY;
   ObjectSet(g_ObjectPrefix + "MainPanel" + "BG", OBJPROP_YSIZE, panelHeight);
   
   ChartRedraw(); // チャートを再描画
}

//+------------------------------------------------------------------+
//| ラベル作成 - フォントをMS Gothicに変更                           |
//+------------------------------------------------------------------+
void CreateLabel(string name, string text, int x, int y, color textColor)
{
   // オブジェクト名にプレフィックスを追加（複数チャート対策）
   string objectName = g_ObjectPrefix + name;
   
   ObjectCreate(objectName, OBJ_LABEL, 0, 0, 0);
   ObjectSet(objectName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSet(objectName, OBJPROP_XDISTANCE, x);
   ObjectSet(objectName, OBJPROP_YDISTANCE, y);
   // MS ゴシックフォントを使用
   ObjectSetText(objectName, text, 9, "MS Gothic", textColor);
   ObjectSet(objectName, OBJPROP_SELECTABLE, false);
   
   // オブジェクト名を保存
   SaveObjectName(objectName, g_PanelNames, g_PanelObjectCount);
}

//+------------------------------------------------------------------+
//| パネル作成                                                        |
//+------------------------------------------------------------------+
void CreatePanel(string name, int x, int y, int width, int height, color bgColor, color borderColor)
{
   // オブジェクト名にプレフィックスを追加（複数チャート対策）
   string objectName = g_ObjectPrefix + name;
   
   // パネル背景
   string bgName = objectName + "BG";
   ObjectCreate(bgName, OBJ_RECTANGLE_LABEL, 0, 0, 0);
   ObjectSet(bgName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSet(bgName, OBJPROP_XDISTANCE, x);
   ObjectSet(bgName, OBJPROP_YDISTANCE, y);
   ObjectSet(bgName, OBJPROP_XSIZE, width);
   ObjectSet(bgName, OBJPROP_YSIZE, height);
   ObjectSet(bgName, OBJPROP_BGCOLOR, bgColor);
   ObjectSet(bgName, OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSet(bgName, OBJPROP_COLOR, borderColor);
   ObjectSet(bgName, OBJPROP_WIDTH, PANEL_BORDER_WIDTH);
   ObjectSet(bgName, OBJPROP_BACK, false);
   ObjectSet(bgName, OBJPROP_SELECTABLE, false);
   
   // オブジェクト名を保存
   SaveObjectName(bgName, g_PanelNames, g_PanelObjectCount);
}

//+------------------------------------------------------------------+
//| タイトルバー作成                                                  |
//+------------------------------------------------------------------+
void CreateTitleBar(string name, int x, int y, int width, int height, color bgColor, string title)
{
   // オブジェクト名にプレフィックスを追加（複数チャート対策）
   string objectName = g_ObjectPrefix + name;
   
   // タイトルバー背景
   string bgName = objectName + "BG";
   ObjectCreate(bgName, OBJ_RECTANGLE_LABEL, 0, 0, 0);
   ObjectSet(bgName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSet(bgName, OBJPROP_XDISTANCE, x);
   ObjectSet(bgName, OBJPROP_YDISTANCE, y);
   ObjectSet(bgName, OBJPROP_XSIZE, width);
   ObjectSet(bgName, OBJPROP_YSIZE, height);
   ObjectSet(bgName, OBJPROP_BGCOLOR, bgColor);
   ObjectSet(bgName, OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSet(bgName, OBJPROP_COLOR, bgColor);
   ObjectSet(bgName, OBJPROP_BACK, false);
   ObjectSet(bgName, OBJPROP_SELECTABLE, false);
   
   // タイトルテキスト
   string textName = objectName + "Text";
   ObjectCreate(textName, OBJ_LABEL, 0, 0, 0);
   ObjectSet(textName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSet(textName, OBJPROP_XDISTANCE, x + 10);
   ObjectSet(textName, OBJPROP_YDISTANCE, y + 8);
   ObjectSetText(textName, title, 10, "Arial", COLOR_TITLE_TEXT);
   ObjectSet(textName, OBJPROP_SELECTABLE, false);
   
   // オブジェクト名を保存
   SaveObjectName(bgName, g_PanelNames, g_PanelObjectCount);
   SaveObjectName(textName, g_PanelNames, g_PanelObjectCount);
}

//+------------------------------------------------------------------+
//| ボタン作成 - フォントをMS Gothicに変更                           |
//+------------------------------------------------------------------+
void CreateButton(string name, string text, int x, int y, int width, int height, color bgColor, color textColor)
{
   // オブジェクト名にプレフィックスを追加（複数チャート対策）
   string objectName = g_ObjectPrefix + name;
   
   // ボタン背景
   string bgName = objectName + "BG";
   ObjectCreate(bgName, OBJ_RECTANGLE_LABEL, 0, 0, 0);
   ObjectSet(bgName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSet(bgName, OBJPROP_XDISTANCE, x);
   ObjectSet(bgName, OBJPROP_YDISTANCE, y);
   ObjectSet(bgName, OBJPROP_XSIZE, width);
   ObjectSet(bgName, OBJPROP_YSIZE, height);
   ObjectSet(bgName, OBJPROP_BGCOLOR, bgColor);
   ObjectSet(bgName, OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSet(bgName, OBJPROP_COLOR, ColorDarken(bgColor, 20));
   ObjectSet(bgName, OBJPROP_WIDTH, 1);
   ObjectSet(bgName, OBJPROP_BACK, false);
   ObjectSet(bgName, OBJPROP_SELECTABLE, false);
   
   // ボタン本体
   ObjectCreate(objectName, OBJ_BUTTON, 0, 0, 0);
   ObjectSet(objectName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSet(objectName, OBJPROP_XDISTANCE, x);
   ObjectSet(objectName, OBJPROP_YDISTANCE, y);
   ObjectSet(objectName, OBJPROP_XSIZE, width);
   ObjectSet(objectName, OBJPROP_YSIZE, height);
   // MS ゴシックフォントを使用
   ObjectSetText(objectName, text, 9, "MS Gothic", textColor);
   ObjectSet(objectName, OBJPROP_BGCOLOR, bgColor);
   ObjectSet(objectName, OBJPROP_BORDER_COLOR, ColorDarken(bgColor, 20));
   ObjectSet(objectName, OBJPROP_COLOR, textColor);
   ObjectSet(objectName, OBJPROP_SELECTABLE, false);
   
   // オブジェクト名を保存
   SaveObjectName(bgName, g_PanelNames, g_PanelObjectCount);
   SaveObjectName(objectName, g_PanelNames, g_PanelObjectCount);
}

//+------------------------------------------------------------------+
//| ロットテーブル表示を作成するための補助関数                         |
//+------------------------------------------------------------------+
void CreateLotTableDialog()
{
   // ダイアログタイトル
   string title = "Hosopi 3 - ロットテーブル";
   
   // ダイアログ内容を構築
   string message = "現在のロットテーブル:\n\n";
   
   // 最初の10レベルを表示
   for(int i = 0; i < 10; i++)
   {
      message += "Level " + IntegerToString(i + 1) + ": " + DoubleToString(g_LotTable[i], 2) + "\n";
   }
   
   // 次の10レベルは折りたたんで表示
   message += "\n続き (11-20):\n";
   for(int i = 10; i < 20; i++)
   {
      message += "Level " + IntegerToString(i + 1) + ": " + DoubleToString(g_LotTable[i], 2) + "\n";
   }
   
   // 設定モードを表示
   message += "\n設定モード: " + (IndividualLotEnabled == ON_MODE ? "個別指定" : "マーチンゲール方式");
   if(IndividualLotEnabled == OFF_MODE)
   {
      message += "\n初期ロット: " + DoubleToString(InitialLot, 2);
      message += "\n倍率: " + DoubleToString(LotMultiplier, 2);
   }
   
   // メッセージボックスを表示
   MessageBox(message, title, MB_ICONINFORMATION);
}


//+------------------------------------------------------------------+
//| エントリーモードを文字列に変換する補助関数                         |
//+------------------------------------------------------------------+
string GetEntryModeString(int mode)
{
   switch(mode)
   {
      case MODE_BUY_ONLY: return "Buyのみ";
      case MODE_SELL_ONLY: return "Sellのみ";
      case MODE_BOTH: return "Buy & Sell両方";
      default: return "不明";
   }
}

//+------------------------------------------------------------------+
//| GUIを削除する                                                     |
//+------------------------------------------------------------------+
void DeleteGUI()
{
   for(int i = 0; i < g_PanelObjectCount; i++)
   {
      if(ObjectFind(g_PanelNames[i]) >= 0)
         ObjectDelete(g_PanelNames[i]);
   }
   
   g_PanelObjectCount = 0;
   ChartRedraw(); // チャートを再描画
}

//+------------------------------------------------------------------+
//| GUIを更新する - レベルボタン対応版                               |
//+------------------------------------------------------------------+
void UpdateGUI()
{
   // オブジェクト名にプレフィックスを追加（複数チャート対策）
   string ghostBtnPrefix = g_ObjectPrefix + "btnGhostToggle";
   string avgPriceBtnPrefix = g_ObjectPrefix + "btnToggleAvgPrice";
   string levelBuyBtnPrefix = g_ObjectPrefix + "btnLevelBuy";
   string levelSellBtnPrefix = g_ObjectPrefix + "btnLevelSell";
   
   // レベルボタンのラベルを更新
   int buyLevel = ghost_position_count(OP_BUY) + 1;
   int sellLevel = ghost_position_count(OP_SELL) + 1;
   
   ObjectSetText(levelBuyBtnPrefix, "BUY Level " + IntegerToString(buyLevel), 9, "MS Gothic", COLOR_TEXT_LIGHT);
   ObjectSetText(levelSellBtnPrefix, "SELL Level " + IntegerToString(sellLevel), 9, "MS Gothic", COLOR_TEXT_LIGHT);
   
   // Ghost ON/OFFボタン状態更新
   color ghostButtonColor = g_GhostMode ? COLOR_BUTTON_ACTIVE : COLOR_BUTTON_INACTIVE;
   ObjectSet(ghostBtnPrefix + "BG", OBJPROP_BGCOLOR, ghostButtonColor);
   ObjectSet(ghostBtnPrefix + "BG", OBJPROP_COLOR, ColorDarken(ghostButtonColor, 20));
   ObjectSet(ghostBtnPrefix, OBJPROP_BGCOLOR, ghostButtonColor);
   ObjectSet(ghostBtnPrefix, OBJPROP_BORDER_COLOR, ColorDarken(ghostButtonColor, 20));
   ObjectSetText(ghostBtnPrefix, g_GhostMode ? "GHOST ON" : "GHOST OFF", 9, "MS Gothic", COLOR_TEXT_LIGHT);
   
   // 平均取得単価表示ボタン状態更新
   color avgPriceButtonColor = g_AvgPriceVisible ? COLOR_BUTTON_ACTIVE : COLOR_BUTTON_INACTIVE;
   ObjectSet(avgPriceBtnPrefix + "BG", OBJPROP_BGCOLOR, avgPriceButtonColor);
   ObjectSet(avgPriceBtnPrefix + "BG", OBJPROP_COLOR, ColorDarken(avgPriceButtonColor, 20));
   ObjectSet(avgPriceBtnPrefix, OBJPROP_BGCOLOR, avgPriceButtonColor);
   ObjectSet(avgPriceBtnPrefix, OBJPROP_BORDER_COLOR, ColorDarken(avgPriceButtonColor, 20));
   ObjectSetText(avgPriceBtnPrefix, g_AvgPriceVisible ? "AVG PRICE ON" : "AVG PRICE OFF", 9, "MS Gothic", COLOR_TEXT_LIGHT);
   
   ChartRedraw(); // チャートを再描画
}


//+------------------------------------------------------------------+
//| ボタンクリックを処理する - ゴーストエントリーボタン対応版         |
//+------------------------------------------------------------------+
void ProcessButtonClick(string buttonName)
{
   // プレフィックスを除去してボタン名を比較（複数チャート対策）
   string originalName = buttonName;
   
   // プレフィックスチェック
   if(StringFind(buttonName, g_ObjectPrefix) == 0) {
      // プレフィックスを除去
      buttonName = StringSubstr(buttonName, StringLen(g_ObjectPrefix));
   } else {
      // このEAに属さないボタンならスキップ
      return;
   }
   
   // ボタンの状態をリセット（押したままにならないように）
   ObjectSet(originalName, OBJPROP_STATE, false);
   
   // Buy Close
   if(buttonName == "btnCloseBuy")
   {
      Print("Close Buy clicked");
      position_close(0);
      UpdateGUI();
   }
   
   // Sell Close
   else if(buttonName == "btnCloseSell")
   {
      Print("Close Sell clicked");
      position_close(1);
      UpdateGUI();
   }
   
   // Close All
   else if(buttonName == "btnCloseAll")
   {
      Print("Close All clicked");
      
      // リアルポジションを閉じる
      position_close(0);
      position_close(1);
      
      // ゴーストもリセット
      ResetGhost(OP_BUY);
      ResetGhost(OP_SELL);
      
      // グローバル変数からもクリア
      ClearGhostPositionsFromGlobal();
      
      // 決済済みフラグもリセット
      g_BuyGhostClosed = false;
      g_SellGhostClosed = false;
      SaveGhostPositionsToGlobal();
      
      Print("すべてのポジションとゴーストをリセットしました");
      
      UpdateGUI();
      UpdatePositionTable();
   }
   
   // Ghost Toggle
   else if(buttonName == "btnGhostToggle" || buttonName == "btnGhostMode")
   {
      g_GhostMode = !g_GhostMode;
      
      // ゴーストモードをOFFにした場合は、すべてのゴーストをリセット
      if(!g_GhostMode)
      {
         ResetGhost(OP_BUY);
         ResetGhost(OP_SELL);
      }
      else
      {
         // ゴーストモードをONにした場合、決済済みフラグをリセット
         g_BuyGhostClosed = false;
         g_SellGhostClosed = false;
         SaveGhostPositionsToGlobal();
      }
      
      UpdateGUI();
      Print("ゴーストモードを", g_GhostMode ? "ON" : "OFF", "に切り替えました");
   }
   
   // Reset Ghost
   else if(buttonName == "btnResetGhost")
   {
      Print("Reset Ghost clicked - ゴーストデータをリセットします");
      
      // ゴーストオブジェクトを削除
      DeleteAllGhostObjectsByType(OP_BUY);
      DeleteAllGhostObjectsByType(OP_SELL);
      
      // ゴーストポジションをリセット
      ResetGhost(OP_BUY);  // 両方のゴーストをリセット
      ResetGhost(OP_SELL);
      
      // グローバル変数からも完全にクリア
      ClearGhostPositionsFromGlobal();
      
      // 決済済みフラグもリセット
      g_BuyGhostClosed = false;
      g_SellGhostClosed = false;
      SaveGhostPositionsToGlobal();
      
      // GUIとテーブルを再作成
      DeleteGUI();
      DeletePositionTable();
      CreateGUI();
      CreatePositionTable();
      
      UpdateGUI();
      
      // 最後にチャートを再描画
      ChartRedraw();
      
      Print("すべてのゴーストポジションをリセットしました");
   }
   
   // Toggle Average Price Display
   else if(buttonName == "btnToggleAvgPrice" || buttonName == "btnAvgPriceLine")
   {
      g_AvgPriceVisible = !g_AvgPriceVisible;
      
      if(!g_AvgPriceVisible)
      {
         DeleteAllLines();
      }
      
      UpdateGUI();
      Print("平均価格ラインを", g_AvgPriceVisible ? "表示" : "非表示", "に切り替えました");
   }
   
   // ===== 直接エントリー機能 =====
   
   // 直接Buy
   else if(buttonName == "btnDirectBuy")
   {
      Print("直接Buyボタンがクリックされました");
      ExecuteDiscretionaryEntry(OP_BUY);
      UpdatePositionTable();
      UpdateGUI(); // レベルボタンのラベルを更新
   }
   
// 直接Sell
else if(buttonName == "btnDirectSell")
{
   Print("直接Sellボタンがクリックされました");
   ExecuteDiscretionaryEntry(OP_SELL);
   UpdatePositionTable();
   UpdateGUI(); // レベルボタンのラベルを更新
}

// ===== ゴーストエントリーボタン処理（新規追加） =====

// ゴーストBuy
else if(buttonName == "btnGhostBuy")
{
   Print("ゴーストBuyボタンがクリックされました");
   if(!g_GhostMode)
   {
      // ゴーストモードが無効の場合はメッセージを表示
      MessageBox("ゴーストモードが無効です。先にGHOST ONにしてください。", "ゴーストエントリーエラー", MB_ICONWARNING);
   }
   else if(position_count(OP_BUY) > 0)
   {
      // すでにリアルポジションがある場合
      MessageBox("すでにBuy方向のリアルポジションが存在します。\nゴーストエントリーはリアルポジションがない状態で行ってください。", 
                 "ゴーストエントリーエラー", MB_ICONWARNING);
   }
   else
   {
      // ゴーストBuyポジション初期化
      InitializeGhostPosition(OP_BUY, "手動ゴーストエントリー");
      UpdatePositionTable();
      UpdateGUI(); // レベルボタンのラベルを更新
   }
}

// ゴーストSell
else if(buttonName == "btnGhostSell")
{
   Print("ゴーストSellボタンがクリックされました");
   if(!g_GhostMode)
   {
      // ゴーストモードが無効の場合はメッセージを表示
      MessageBox("ゴーストモードが無効です。先にGHOST ONにしてください。", "ゴーストエントリーエラー", MB_ICONWARNING);
   }
   else if(position_count(OP_SELL) > 0)
   {
      // すでにリアルポジションがある場合
      MessageBox("すでにSell方向のリアルポジションが存在します。\nゴーストエントリーはリアルポジションがない状態で行ってください。", 
                 "ゴーストエントリーエラー", MB_ICONWARNING);
   }
   else
   {
      // ゴーストSellポジション初期化
      InitializeGhostPosition(OP_SELL, "手動ゴーストエントリー");
      UpdatePositionTable();
      UpdateGUI(); // レベルボタンのラベルを更新
   }
}

// ===== レベル指定エントリーボタン =====

// レベル指定Buy
else if(buttonName == "btnLevelBuy")
{
   // 現在のゴーストカウント+1をレベルとして使用
   int entryLevel = ghost_position_count(OP_BUY) + 1;
   Print("レベル指定Buyボタンがクリックされました: レベル", entryLevel);
   ExecuteEntryFromLevel(OP_BUY, entryLevel);
   UpdatePositionTable();
   UpdateGUI(); // レベルボタンのラベルを更新
}

// レベル指定Sell
else if(buttonName == "btnLevelSell")
{
   // 現在のゴーストカウント+1をレベルとして使用
   int entryLevel = ghost_position_count(OP_SELL) + 1;
   Print("レベル指定Sellボタンがクリックされました: レベル", entryLevel);
   ExecuteEntryFromLevel(OP_SELL, entryLevel);
   UpdatePositionTable();
   UpdateGUI(); // レベルボタンのラベルを更新
}

// ロットテーブル表示ボタン
else if(buttonName == "btnShowLotTable")
{
   Print("ロットテーブル表示ボタンがクリックされました");
   CreateLotTableDialog();
}

// 設定情報表示ボタン
else if(buttonName == "btnShowSettings")
{
   Print("設定情報表示ボタンがクリックされました");
   ShowSettingsDialog();
}

// 未知のボタンの場合
else
{
   Print("未知のボタンがクリックされました: ", buttonName);
}
}

//+------------------------------------------------------------------+
//| 設定情報ダイアログを表示                                         |
//+------------------------------------------------------------------+
void ShowSettingsDialog()
{
   // ダイアログタイトル
   string title = "Hosopi 3 - 設定情報";
   
   // ダイアログ内容を構築
   string message = "【基本設定】\n";
   message += "エントリーモード: " + GetEntryModeString(EntryMode) + "\n";
   message += "ゴーストモード: " + (g_GhostMode ? "ON" : "OFF") + "\n";
   message += "ナンピンスキップレベル: " + IntegerToString((int)NanpinSkipLevel) + "\n\n";
   
   message += "【ナンピン設定】\n";
   message += "ナンピン機能: " + (EnableNanpin ? "有効" : "無効") + "\n";
   message += "ナンピンインターバル: " + IntegerToString(NanpinInterval) + "分\n";
   message += "最大スプレッド: " + IntegerToString(MaxSpreadPoints) + "ポイント\n\n";
   
   message += "【利確設定】\n";
   message += "利確モード: ";
   switch(TakeProfitMode) {
      case TP_OFF: message += "無効"; break;
      case TP_LIMIT: message += "指値"; break;
      case TP_MARKET: message += "成行"; break;
      default: message += "不明";
   }
   message += "\n";
   message += "利確ポイント: " + IntegerToString(TakeProfitPoints) + "\n\n";
   
   message += "【トレーリングストップ】\n";
   message += "トレーリングストップ: " + (EnableTrailingStop ? "有効" : "無効") + "\n";
   
   // メッセージボックスを表示
   MessageBox(message, title, MB_ICONINFORMATION);
}

//+------------------------------------------------------------------+
//| 平均取得単価表示/非表示切替                                       |
//+------------------------------------------------------------------+
void ToggleAveragePriceVisibility(bool visible)
{
if(visible)
{
   // 表示ONの場合は平均取得価格ラインを更新表示
   UpdateAveragePriceLines(0); // Buy側
   UpdateAveragePriceLines(1); // Sell側
}
else
{
   // 表示OFFの場合はラインを削除
   DeleteAllLines();
}

ChartRedraw(); // チャートを再描画
}

//+------------------------------------------------------------------+
//| 水平線を作成                                                     |
//+------------------------------------------------------------------+
void CreateHorizontalLine(string name, double price, color lineColor, int style, int width)
{
// オブジェクト名にプレフィックスを追加（複数チャート対策）
string objectName = g_ObjectPrefix + name;

if(ObjectFind(objectName) >= 0)
   ObjectDelete(objectName);
   
ObjectCreate(objectName, OBJ_HLINE, 0, 0, price);
ObjectSet(objectName, OBJPROP_COLOR, lineColor);
ObjectSet(objectName, OBJPROP_STYLE, style);
ObjectSet(objectName, OBJPROP_WIDTH, width);
ObjectSet(objectName, OBJPROP_BACK, false);
ObjectSet(objectName, OBJPROP_SELECTABLE, true);
ObjectSet(objectName, OBJPROP_SELECTED, false);
ObjectSet(objectName, OBJPROP_HIDDEN, true);

// オブジェクト名を保存
SaveObjectName(objectName, g_LineNames, g_LineObjectCount);
}

//+------------------------------------------------------------------+
//| 価格ラベルを作成                                                  |
//+------------------------------------------------------------------+
void CreatePriceLabel(string name, string text, double price, color textColor, bool isAbove)
{
// オブジェクト名にプレフィックスを追加（複数チャート対策）
string objectName = g_ObjectPrefix + name;

// 既存のラベルがあれば削除
if(ObjectFind(objectName) >= 0)
   ObjectDelete(objectName);
   
// ラベルの作成
datetime labelTime = TimeCurrent() + 1800; // 現在時刻から30分後の位置に表示
ObjectCreate(objectName, OBJ_TEXT, 0, labelTime, price + (isAbove ? 25*Point : -25*Point));
ObjectSetText(objectName, text, 8, "Arial Bold", textColor);
ObjectSet(objectName, OBJPROP_BACK, false);
ObjectSet(objectName, OBJPROP_SELECTABLE, false);

// オブジェクト名を保存
SaveObjectName(objectName, g_LineNames, g_LineObjectCount);
}
//+------------------------------------------------------------------+
//| すべてのラインを削除 - ボタン保護版                               |
//+------------------------------------------------------------------+
void DeleteAllLines()
{
   // チャート上のすべてのオブジェクトを検索して関連するラインを削除
   for(int i = ObjectsTotal() - 1; i >= 0; i--)
   {
      string name = ObjectName(i);
      
      // 自分のEAのオブジェクトのみを対象にする
      if(StringFind(name, g_ObjectPrefix) != 0) 
         continue;
      
      // GUIボタンを保護 - 重要
      if(StringFind(name, "btn") >= 0 || StringFind(name, "Panel") >= 0 || StringFind(name, "Title") >= 0)
         continue;
      
      // 平均価格ラインとTP関連のオブジェクトを削除
      if(StringFind(name, "AvgPrice") >= 0 || 
         StringFind(name, "TPLine") >= 0 || 
         StringFind(name, "Label") >= 0 || 
         StringFind(name, "LimitTP") >= 0)
      {
         ObjectDelete(name);
      }
   }
   
   // 配列に保存されたオブジェクトも削除
   for(int i = 0; i < g_LineObjectCount; i++)
   {
      if(ObjectFind(g_LineNames[i]) >= 0)
      {
         // ここでもボタン保護
         if(StringFind(g_LineNames[i], "btn") >= 0)
            continue;
            
         ObjectDelete(g_LineNames[i]);
      }
   }
   
   // 明示的に特定のオブジェクト名を指定して削除
   string specificObjects[12]; // 配列サイズを宣言
   
   // 各要素に個別に値を代入
   specificObjects[0] = g_ObjectPrefix + "AvgPriceBuy";
   specificObjects[1] = g_ObjectPrefix + "AvgPriceSell";
   specificObjects[2] = g_ObjectPrefix + "TPLineBuy";
   specificObjects[3] = g_ObjectPrefix + "TPLineSell";
   specificObjects[4] = g_ObjectPrefix + "AvgPriceLabelBuy";
   specificObjects[5] = g_ObjectPrefix + "AvgPriceLabelSell";
   specificObjects[6] = g_ObjectPrefix + "TPLabelBuy";
   specificObjects[7] = g_ObjectPrefix + "TPLabelSell";
   specificObjects[8] = g_ObjectPrefix + "LimitTPBuy";
   specificObjects[9] = g_ObjectPrefix + "LimitTPSell";
   specificObjects[10] = g_ObjectPrefix + "LimitTPLabelBuy";
   specificObjects[11] = g_ObjectPrefix + "LimitTPLabelSell";
   
   for(int i = 0; i < ArraySize(specificObjects); i++)
   {
      if(ObjectFind(specificObjects[i]) >= 0)
      {
         ObjectDelete(specificObjects[i]);
      }
   }
   
   // カウンターをリセット
   g_LineObjectCount = 0;
   
   // チャートの再描画を強制
   ChartRedraw();
}


//+------------------------------------------------------------------+
//| 決済時にラインを削除する関数                                      |
//+------------------------------------------------------------------+
void CleanupLinesOnClose(int side)
{
    // 方向に対応するラインを削除
    string direction = (side == 0) ? "Buy" : "Sell";
    
    // 平均価格ライン、TPライン、各ラベルを削除
    string objects[6];
    objects[0] = g_ObjectPrefix + "AvgPrice" + direction;
    objects[1] = g_ObjectPrefix + "TPLine" + direction;
    objects[2] = g_ObjectPrefix + "AvgPriceLabel" + direction;
    objects[3] = g_ObjectPrefix + "TPLabel" + direction;
    objects[4] = g_ObjectPrefix + "LimitTP" + direction;
    objects[5] = g_ObjectPrefix + "LimitTPLabel" + direction;
    
    for(int i = 0; i < ArraySize(objects); i++)
    {
        if(ObjectFind(objects[i]) >= 0)
        {
            ObjectDelete(objects[i]);
            Print("決済時にライン削除: ", objects[i]);
        }
    }
    
    // チャートを再描画
    ChartRedraw();
}

//+------------------------------------------------------------------+
//| ポジションがない場合にラインを削除するチェック関数                 |
//+------------------------------------------------------------------+
void CheckAndDeleteLinesIfNoPositions()
{
   // Buy方向のチェック
   int buyPositions = position_count(OP_BUY);
   int buyGhosts = ghost_position_count(OP_BUY);
   
   // Buy方向のポジションがゼロならラインを削除
   if(buyPositions == 0 && buyGhosts == 0)
   {
      CleanupLinesOnClose(0); // Buy側のライン削除
   }
   
   // Sell方向のチェック
   int sellPositions = position_count(OP_SELL);
   int sellGhosts = ghost_position_count(OP_SELL);
   
   // Sell方向のポジションがゼロならラインを削除
   if(sellPositions == 0 && sellGhosts == 0)
   {
      CleanupLinesOnClose(1); // Sell側のライン削除
   }
}