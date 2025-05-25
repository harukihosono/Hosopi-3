//+------------------------------------------------------------------+
//|                       Unified_GUI.mqh                            |
//|            MQL4/MQL5 統合GUIライブラリ                           |
//|                     Copyright 2025                               |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025"
#property version   "1.00"

#include "Unified_Trading.mqh"
#include "Unified_Utils.mqh"

//+------------------------------------------------------------------+
//| GUI定数定義                                                      |
//+------------------------------------------------------------------+
// パネルサイズ
#define PANEL_WIDTH         280
#define PANEL_HEIGHT        500
#define BUTTON_HEIGHT       30
#define TITLE_HEIGHT        35
#define PANEL_MARGIN        10
#define PANEL_BORDER_WIDTH  2

// テーブルサイズ
#define TABLE_WIDTH         400
#define TABLE_ROW_HEIGHT    20
#define TABLE_HEADER_HEIGHT 25

// 色定義
#define COLOR_PANEL_BG      C'32,32,32'      // パネル背景色
#define COLOR_PANEL_BORDER  C'64,64,64'      // パネル枠線色
#define COLOR_TITLE_BG      C'48,48,48'      // タイトルバー背景色
#define COLOR_TITLE_TEXT    C'255,255,255'   // タイトルテキスト色
#define COLOR_TEXT_LIGHT    C'255,255,255'   // 明るいテキスト色
#define COLOR_TEXT_DARK     C'0,0,0'         // 暗いテキスト色
#define COLOR_BUTTON_BUY    C'59,125,255'    // 買いボタン色
#define COLOR_BUTTON_SELL   C'255,59,59'     // 売りボタン色
#define COLOR_BUTTON_NEUTRAL C'100,100,100'  // 中立ボタン色
#define COLOR_BUTTON_ACTIVE C'0,200,100'     // アクティブボタン色
#define COLOR_BUTTON_INACTIVE C'64,64,64'    // 非アクティブボタン色
#define COLOR_BUTTON_CLOSE_ALL C'255,165,0'  // 全決済ボタン色
#define COLOR_TABLE_HEADER  C'48,48,48'      // テーブルヘッダー色
#define COLOR_TABLE_BG      C'24,24,24'      // テーブル背景色
#define COLOR_TABLE_BORDER  C'64,64,64'      // テーブル枠線色
#define COLOR_LINE_BUY      clrDodgerBlue    // 買いライン色
#define COLOR_LINE_SELL     clrOrangeRed     // 売りライン色
#define COLOR_LINE_TP       clrLime          // 利食いライン色

//+------------------------------------------------------------------+
//| レイアウトパターン列挙型                                         |
//+------------------------------------------------------------------+
enum LAYOUT_PATTERN
{
    LAYOUT_DEFAULT = 0,         // デフォルト (パネル上/テーブル下)
    LAYOUT_SIDE_BY_SIDE = 1,    // 横並び (パネル左/テーブル右)
    LAYOUT_TABLE_TOP = 2,       // テーブル優先 (テーブル上/パネル下)
    LAYOUT_COMPACT = 3,         // コンパクト (小さいパネル)
    LAYOUT_CUSTOM = 4           // カスタム (位置を個別指定)
};

//+------------------------------------------------------------------+
//| GUIマネージャークラス                                            |
//+------------------------------------------------------------------+
class CGUIManager
{
private:
    // レイアウト設定
    LAYOUT_PATTERN m_layoutPattern;
    int m_panelX, m_panelY;
    int m_tableX, m_tableY;
    int m_effectivePanelX, m_effectivePanelY;
    int m_effectiveTableX, m_effectiveTableY;
    
    // フォント設定
    string m_fontName;
    int m_fontSize;
    
    // パネルタイトル
    string m_panelTitle;
    
    // 表示フラグ
    bool m_showPanel;
    bool m_showTable;
    bool m_showAvgPriceLines;
    bool m_showTPLines;
    
    // オブジェクトカウンター
    int m_objectCount;
    
public:
    CGUIManager();
    ~CGUIManager();
    
    // 初期化
    void Init(string title, LAYOUT_PATTERN layout = LAYOUT_DEFAULT);
    void SetPosition(int panelX, int panelY, int tableX = -1, int tableY = -1);
    void SetFont(string fontName, int fontSize);
    
    // レイアウト管理
    void ApplyLayoutPattern();
    void SetCustomLayout(int panelX, int panelY, int tableX, int tableY);
    
    // パネル作成
    void CreateMainPanel();
    void UpdatePanel();
    void DeletePanel();
    
    // ボタン作成
    void CreateButton(string name, string text, int x, int y, int width, int height, 
                     color bgColor, color textColor);
    void UpdateButton(string name, string text, color bgColor, bool enabled = true);
    
    // ラベル作成
    void CreateLabel(string name, string text, int x, int y, color textColor, 
                    int fontSize = 0, string fontName = "");
    void UpdateLabel(string name, string text);
    
    // テーブル作成
    void CreatePositionTable();
    void UpdatePositionTable();
    void DeleteTable();
    
    // ライン管理
    void CreateAveragePriceLine(int type, double price);
    void CreateTPLine(int type, double price);
    void UpdateLines();
    void DeleteAllLines();
    
    // イベント処理
    bool ProcessChartEvent(const int id, const long& lparam, const double& dparam, 
                          const string& sparam);
    void ProcessButtonClick(string buttonName);
    
    // 表示制御
    void ShowPanel(bool show) { m_showPanel = show; }
    void ShowTable(bool show) { m_showTable = show; }
    void ShowAvgPriceLines(bool show) { m_showAvgPriceLines = show; UpdateLines(); }
    void ShowTPLines(bool show) { m_showTPLines = show; UpdateLines(); }
    
    // ユーティリティ
    string GetLayoutPatternText();
    void RefreshAll();
    
private:
    // 内部ヘルパー関数
    void CreateRectangleLabel(string name, int x, int y, int width, int height, 
                             color bgColor, color borderColor = clrNONE, int borderWidth = 0);
    void CreateTextLabel(string name, string text, int x, int y, color textColor, 
                        string fontName, int fontSize, ENUM_ANCHOR_POINT anchor = ANCHOR_LEFT);
    string GetUniqueObjectName(string baseName);
    void RegisterObject(string name);
    void UnregisterObject(string name);
};

//+------------------------------------------------------------------+
//| コンストラクタ                                                   |
//+------------------------------------------------------------------+
CGUIManager::CGUIManager()
{
    m_layoutPattern = LAYOUT_DEFAULT;
    m_panelX = 20;
    m_panelY = 50;
    m_tableX = 20;
    m_tableY = 580;
    m_fontName = "Arial";
    m_fontSize = 9;
    m_panelTitle = "Unified EA Panel";
    m_showPanel = true;
    m_showTable = true;
    m_showAvgPriceLines = true;
    m_showTPLines = true;
    m_objectCount = 0;
    
    ApplyLayoutPattern();
}

//+------------------------------------------------------------------+
//| デストラクタ                                                     |
//+------------------------------------------------------------------+
CGUIManager::~CGUIManager()
{
    DeletePanel();
    DeleteTable();
    DeleteAllLines();
}

//+------------------------------------------------------------------+
//| 初期化                                                          |
//+------------------------------------------------------------------+
void CGUIManager::Init(string title, LAYOUT_PATTERN layout)
{
    m_panelTitle = title;
    m_layoutPattern = layout;
    ApplyLayoutPattern();
    
    if(m_showPanel)
        CreateMainPanel();
    if(m_showTable)
        CreatePositionTable();
}

//+------------------------------------------------------------------+
//| レイアウトパターン適用                                           |
//+------------------------------------------------------------------+
void CGUIManager::ApplyLayoutPattern()
{
    switch(m_layoutPattern)
    {
        case LAYOUT_DEFAULT:
            m_effectivePanelX = m_panelX;
            m_effectivePanelY = m_panelY;
            m_effectiveTableX = m_panelX;
            m_effectiveTableY = m_panelY + PANEL_HEIGHT + 30;
            break;
            
        case LAYOUT_SIDE_BY_SIDE:
            m_effectivePanelX = m_panelX;
            m_effectivePanelY = m_panelY;
            m_effectiveTableX = m_panelX + PANEL_WIDTH + 20;
            m_effectiveTableY = m_panelY;
            break;
            
        case LAYOUT_TABLE_TOP:
            m_effectivePanelX = m_panelX;
            m_effectivePanelY = m_panelY + TABLE_ROW_HEIGHT * 15 + 50;
            m_effectiveTableX = m_panelX;
            m_effectiveTableY = m_panelY;
            break;
            
        case LAYOUT_COMPACT:
            m_effectivePanelX = m_panelX;
            m_effectivePanelY = m_panelY;
            m_effectiveTableX = m_panelX;
            m_effectiveTableY = m_panelY + PANEL_HEIGHT - 100 + 20;
            break;
            
        case LAYOUT_CUSTOM:
            // カスタムレイアウトは個別設定を使用
            break;
    }
}

//+------------------------------------------------------------------+
//| メインパネル作成                                                 |
//+------------------------------------------------------------------+
void CGUIManager::CreateMainPanel()
{
    DeletePanel(); // 既存パネルを削除
    
    int x = m_effectivePanelX;
    int y = m_effectivePanelY;
    int panelHeight = (m_layoutPattern == LAYOUT_COMPACT) ? PANEL_HEIGHT - 100 : PANEL_HEIGHT;
    
    // パネル背景
    CreateRectangleLabel("MainPanel", x, y, PANEL_WIDTH, panelHeight, 
                        COLOR_PANEL_BG, COLOR_PANEL_BORDER, PANEL_BORDER_WIDTH);
    
    // タイトルバー
    CreateRectangleLabel("TitleBar", x, y, PANEL_WIDTH, TITLE_HEIGHT, COLOR_TITLE_BG);
    CreateTextLabel("TitleText", m_panelTitle, x + 10, y + 8, COLOR_TITLE_TEXT, 
                   m_fontName, m_fontSize + 1, ANCHOR_LEFT);
    
    int buttonWidth = (PANEL_WIDTH - (PANEL_MARGIN * 3)) / 2;
    int fullWidth = PANEL_WIDTH - (PANEL_MARGIN * 2);
    int currentY = y + TITLE_HEIGHT + PANEL_MARGIN;
    
    // 行1: 決済ボタン
    CreateButton("btnCloseSell", "Close Sell", x + PANEL_MARGIN, currentY, 
                buttonWidth, BUTTON_HEIGHT, COLOR_BUTTON_SELL, COLOR_TEXT_LIGHT);
    CreateButton("btnCloseBuy", "Close Buy", x + PANEL_MARGIN * 2 + buttonWidth, currentY, 
                buttonWidth, BUTTON_HEIGHT, COLOR_BUTTON_BUY, COLOR_TEXT_LIGHT);
    
    currentY += BUTTON_HEIGHT + PANEL_MARGIN;
    
    // 行2: 全決済ボタン
    CreateButton("btnCloseAll", "Close All", x + PANEL_MARGIN, currentY, 
                fullWidth, BUTTON_HEIGHT, COLOR_BUTTON_CLOSE_ALL, COLOR_TEXT_DARK);
    
    currentY += BUTTON_HEIGHT + PANEL_MARGIN * 2;
    
    // 行3: 直接エントリー
    CreateLabel("lblDirectEntry", "【Direct Entry】", x + PANEL_MARGIN, currentY - 5, COLOR_TEXT_LIGHT);
    currentY += 15;
    
    CreateButton("btnDirectSell", "SELL NOW", x + PANEL_MARGIN, currentY, 
                buttonWidth, BUTTON_HEIGHT, COLOR_BUTTON_SELL, COLOR_TEXT_LIGHT);
    CreateButton("btnDirectBuy", "BUY NOW", x + PANEL_MARGIN * 2 + buttonWidth, currentY, 
                buttonWidth, BUTTON_HEIGHT, COLOR_BUTTON_BUY, COLOR_TEXT_LIGHT);
    
    currentY += BUTTON_HEIGHT + PANEL_MARGIN;
    
    // 行4: ゴーストエントリー
    if(g_GhostMode)
    {
        CreateLabel("lblGhostEntry", "【Ghost Entry】", x + PANEL_MARGIN, currentY - 5, COLOR_TEXT_LIGHT);
        currentY += 15;
        
        CreateButton("btnGhostSell", "GHOST SELL", x + PANEL_MARGIN, currentY, 
                    buttonWidth, BUTTON_HEIGHT, COLOR_BUTTON_SELL, COLOR_TEXT_LIGHT);
        CreateButton("btnGhostBuy", "GHOST BUY", x + PANEL_MARGIN * 2 + buttonWidth, currentY, 
                    buttonWidth, BUTTON_HEIGHT, COLOR_BUTTON_BUY, COLOR_TEXT_LIGHT);
        
        currentY += BUTTON_HEIGHT + PANEL_MARGIN;
    }
    
    // 行5: 設定
    CreateLabel("lblSettings", "【Settings】", x + PANEL_MARGIN, currentY - 5, COLOR_TEXT_LIGHT);
    currentY += 15;
    
    // ゴーストモードトグル
    CreateButton("btnGhostToggle", g_GhostMode ? "GHOST ON" : "GHOST OFF", 
                x + PANEL_MARGIN, currentY, fullWidth, BUTTON_HEIGHT, 
                g_GhostMode ? COLOR_BUTTON_ACTIVE : COLOR_BUTTON_INACTIVE, COLOR_TEXT_LIGHT);
    
    currentY += BUTTON_HEIGHT + PANEL_MARGIN;
    
    // 平均価格表示トグル
    CreateButton("btnAvgPriceToggle", m_showAvgPriceLines ? "AVG PRICE ON" : "AVG PRICE OFF", 
                x + PANEL_MARGIN, currentY, fullWidth, BUTTON_HEIGHT, 
                m_showAvgPriceLines ? COLOR_BUTTON_ACTIVE : COLOR_BUTTON_INACTIVE, COLOR_TEXT_LIGHT);
    
    currentY += BUTTON_HEIGHT + PANEL_MARGIN;
    
    // 情報表示ボタン
    CreateButton("btnShowInfo", "Show Info", x + PANEL_MARGIN, currentY, 
                buttonWidth, BUTTON_HEIGHT, COLOR_BUTTON_NEUTRAL, COLOR_TEXT_LIGHT);
    CreateButton("btnShowSettings", "Settings", x + PANEL_MARGIN * 2 + buttonWidth, currentY, 
                buttonWidth, BUTTON_HEIGHT, COLOR_BUTTON_NEUTRAL, COLOR_TEXT_LIGHT);
    
    ChartRedraw(0);
}

//+------------------------------------------------------------------+
//| ボタン作成                                                       |
//+------------------------------------------------------------------+
void CGUIManager::CreateButton(string name, string text, int x, int y, int width, int height, 
                              color bgColor, color textColor)
{
    string objName = GetUniqueObjectName(name);
    
    // ボタン背景
    string bgName = objName + "_BG";
    CreateRectangleLabel(bgName, x, y, width, height, bgColor, 
                        CColorUtils::Darken(bgColor, 20), 1);
    
    // ボタン本体
    #ifdef __MQL5__
    if(ObjectCreate(0, objName, OBJ_BUTTON, 0, 0, 0))
    {
        ObjectSetInteger(0, objName, OBJPROP_XDISTANCE, x);
        ObjectSetInteger(0, objName, OBJPROP_YDISTANCE, y);
        ObjectSetInteger(0, objName, OBJPROP_XSIZE, width);
        ObjectSetInteger(0, objName, OBJPROP_YSIZE, height);
        ObjectSetString(0, objName, OBJPROP_TEXT, text);
        ObjectSetInteger(0, objName, OBJPROP_COLOR, textColor);
        ObjectSetInteger(0, objName, OBJPROP_BGCOLOR, bgColor);
        ObjectSetInteger(0, objName, OBJPROP_BORDER_COLOR, CColorUtils::Darken(bgColor, 20));
        ObjectSetString(0, objName, OBJPROP_FONT, m_fontName);
        ObjectSetInteger(0, objName, OBJPROP_FONTSIZE, m_fontSize);
        ObjectSetInteger(0, objName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
        ObjectSetInteger(0, objName, OBJPROP_SELECTABLE, false);
        ObjectSetInteger(0, objName, OBJPROP_STATE, false);
        
        RegisterObject(objName);
        RegisterObject(bgName);
    }
    #else
    if(ObjectCreate(objName, OBJ_BUTTON, 0, 0, 0))
    {
        ObjectSet(objName, OBJPROP_XDISTANCE, x);
        ObjectSet(objName, OBJPROP_YDISTANCE, y);
        ObjectSet(objName, OBJPROP_XSIZE, width);
        ObjectSet(objName, OBJPROP_YSIZE, height);
        ObjectSetText(objName, text, m_fontSize, m_fontName, textColor);
        ObjectSet(objName, OBJPROP_BGCOLOR, bgColor);
        ObjectSet(objName, OBJPROP_BORDER_COLOR, CColorUtils::Darken(bgColor, 20));
        ObjectSet(objName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
        ObjectSet(objName, OBJPROP_SELECTABLE, false);
        ObjectSet(objName, OBJPROP_STATE, false);
        
        RegisterObject(objName);
        RegisterObject(bgName);
    }
    #endif
}

//+------------------------------------------------------------------+
//| ボタン更新                                                       |
//+------------------------------------------------------------------+
void CGUIManager::UpdateButton(string name, string text, color bgColor, bool enabled)
{
    string objName = GetUniqueObjectName(name);
    string bgName = objName + "_BG";
    
    #ifdef __MQL5__
    if(ObjectFind(0, objName) >= 0)
    {
        ObjectSetString(0, objName, OBJPROP_TEXT, text);
        ObjectSetInteger(0, objName, OBJPROP_BGCOLOR, bgColor);
        ObjectSetInteger(0, objName, OBJPROP_BORDER_COLOR, CColorUtils::Darken(bgColor, 20));
        ObjectSetInteger(0, objName, OBJPROP_STATE, false);
    }
    
    if(ObjectFind(0, bgName) >= 0)
    {
        ObjectSetInteger(0, bgName, OBJPROP_BGCOLOR, bgColor);
        ObjectSetInteger(0, bgName, OBJPROP_COLOR, CColorUtils::Darken(bgColor, 20));
    }
    #else
    if(ObjectFind(objName) >= 0)
    {
        ObjectSetText(objName, text, m_fontSize, m_fontName, COLOR_TEXT_LIGHT);
        ObjectSet(objName, OBJPROP_BGCOLOR, bgColor);
        ObjectSet(objName, OBJPROP_BORDER_COLOR, CColorUtils::Darken(bgColor, 20));
        ObjectSet(objName, OBJPROP_STATE, false);
    }
    
    if(ObjectFind(bgName) >= 0)
    {
        ObjectSet(bgName, OBJPROP_BGCOLOR, bgColor);
        ObjectSet(bgName, OBJPROP_COLOR, CColorUtils::Darken(bgColor, 20));
    }
    #endif
}

//+------------------------------------------------------------------+
//| ラベル作成                                                       |
//+------------------------------------------------------------------+
void CGUIManager::CreateLabel(string name, string text, int x, int y, color textColor, 
                             int fontSize, string fontName)
{
    if(fontSize == 0) fontSize = m_fontSize;
    if(fontName == "") fontName = m_fontName;
    
    CreateTextLabel(name, text, x, y, textColor, fontName, fontSize, ANCHOR_LEFT);
}

//+------------------------------------------------------------------+
//| ラベル更新                                                       |
//+------------------------------------------------------------------+
void CGUIManager::UpdateLabel(string name, string text)
{
    string objName = GetUniqueObjectName(name);
    
    #ifdef __MQL5__
    if(ObjectFind(0, objName) >= 0)
    {
        ObjectSetString(0, objName, OBJPROP_TEXT, text);
    }
    #else
    if(ObjectFind(objName) >= 0)
    {
        ObjectSetText(objName, text, m_fontSize, m_fontName, COLOR_TEXT_LIGHT);
    }
    #endif
}

//+------------------------------------------------------------------+
//| ポジションテーブル作成                                           |
//+------------------------------------------------------------------+
void CGUIManager::CreatePositionTable()
{
    DeleteTable(); // 既存テーブルを削除
    
    int x = m_effectiveTableX;
    int y = m_effectiveTableY;
    
    // テーブル背景
    int maxRows = 15;
    int tableHeight = TABLE_HEADER_HEIGHT + (TABLE_ROW_HEIGHT * maxRows) + 10;
    
    CreateRectangleLabel("TableBG", x, y, TABLE_WIDTH, tableHeight, 
                        COLOR_TABLE_BG, COLOR_TABLE_BORDER, 1);
    
    // ヘッダー背景
    CreateRectangleLabel("TableHeader", x, y, TABLE_WIDTH, TABLE_HEADER_HEIGHT, 
                        COLOR_TABLE_HEADER, COLOR_TABLE_BORDER, 1);
    
    // ヘッダーテキスト
    int colX = x + 5;
    CreateTextLabel("HeaderNo", "#", colX, y + 5, COLOR_TEXT_LIGHT, m_fontName, m_fontSize, ANCHOR_LEFT);
    
    colX += 30;
    CreateTextLabel("HeaderType", "Type", colX, y + 5, COLOR_TEXT_LIGHT, m_fontName, m_fontSize, ANCHOR_LEFT);
    
    colX += 50;
    CreateTextLabel("HeaderLots", "Lots", colX, y + 5, COLOR_TEXT_LIGHT, m_fontName, m_fontSize, ANCHOR_LEFT);
    
    colX += 60;
    CreateTextLabel("HeaderPrice", "Price", colX, y + 5, COLOR_TEXT_LIGHT, m_fontName, m_fontSize, ANCHOR_LEFT);
    
    colX += 80;
    CreateTextLabel("HeaderProfit", "Profit", colX, y + 5, COLOR_TEXT_LIGHT, m_fontName, m_fontSize, ANCHOR_LEFT);
    
    colX += 80;
    CreateTextLabel("HeaderComment", "Comment", colX, y + 5, COLOR_TEXT_LIGHT, m_fontName, m_fontSize, ANCHOR_LEFT);
    
    UpdatePositionTable();
}

//+------------------------------------------------------------------+
//| ポジションテーブル更新                                           |
//+------------------------------------------------------------------+
void CGUIManager::UpdatePositionTable()
{
    if(!m_showTable) return;
    
    int x = m_effectiveTableX;
    int y = m_effectiveTableY + TABLE_HEADER_HEIGHT + 5;
    int rowCount = 0;
    int maxRows = 15;
    
    // 既存の行を削除
    for(int i = 0; i < maxRows; i++)
    {
        string rowPrefix = "TableRow" + IntegerToString(i);
        if(ObjectFind(0, GetUniqueObjectName(rowPrefix + "_No")) >= 0)
        {
            ObjectDelete(0, GetUniqueObjectName(rowPrefix + "_No"));
            ObjectDelete(0, GetUniqueObjectName(rowPrefix + "_Type"));
            ObjectDelete(0, GetUniqueObjectName(rowPrefix + "_Lots"));
            ObjectDelete(0, GetUniqueObjectName(rowPrefix + "_Price"));
            ObjectDelete(0, GetUniqueObjectName(rowPrefix + "_Profit"));
            ObjectDelete(0, GetUniqueObjectName(rowPrefix + "_Comment"));
        }
    }
    
    // リアルポジション表示
    #ifdef __MQL5__
    for(int i = 0; i < PositionsTotal() && rowCount < maxRows; i++)
    {
        ulong ticket = PositionGetTicket(i);
        if(PositionSelectByTicket(ticket))
        {
            if(PositionGetString(POSITION_SYMBOL) == Symbol() &&
               PositionGetInteger(POSITION_MAGIC) == MagicNumber)
            {
                DisplayPositionRow(rowCount, x, y + rowCount * TABLE_ROW_HEIGHT,
                                 (int)ticket,
                                 PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY ? "BUY" : "SELL",
                                 PositionGetDouble(POSITION_VOLUME),
                                 PositionGetDouble(POSITION_PRICE_OPEN),
                                 PositionGetDouble(POSITION_PROFIT),
                                 PositionGetString(POSITION_COMMENT));
                rowCount++;
            }
        }
    }
    #else
    for(int i = 0; i < OrdersTotal() && rowCount < maxRows; i++)
    {
        if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
        {
            if(OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumber &&
               OrderType() <= OP_SELL)
            {
                DisplayPositionRow(rowCount, x, y + rowCount * TABLE_ROW_HEIGHT,
                                 OrderTicket(),
                                 OrderType() == OP_BUY ? "BUY" : "SELL",
                                 OrderLots(),
                                 OrderOpenPrice(),
                                 OrderProfit(),
                                 OrderComment());
                rowCount++;
            }
        }
    }
    #endif
    
    // ゴーストポジション表示
    if(g_GhostMode)
    {
        // Buy側ゴースト
        for(int i = 0; i < g_GhostBuyCount && rowCount < maxRows; i++)
        {
            if(g_GhostBuyPositions[i].isGhost)
            {
                DisplayPositionRow(rowCount, x, y + rowCount * TABLE_ROW_HEIGHT,
                                 0, "[G]BUY",
                                 g_GhostBuyPositions[i].lots,
                                 g_GhostBuyPositions[i].price,
                                 0.0,
                                 g_GhostBuyPositions[i].comment);
                rowCount++;
            }
        }
        
        // Sell側ゴースト
        for(int i = 0; i < g_GhostSellCount && rowCount < maxRows; i++)
        {
            if(g_GhostSellPositions[i].isGhost)
            {
                DisplayPositionRow(rowCount, x, y + rowCount * TABLE_ROW_HEIGHT,
                                 0, "[G]SELL",
                                 g_GhostSellPositions[i].lots,
                                 g_GhostSellPositions[i].price,
                                 0.0,
                                 g_GhostSellPositions[i].comment);
                rowCount++;
            }
        }
    }
    
    ChartRedraw(0);
}

//+------------------------------------------------------------------+
//| ポジション行表示                                                 |
//+------------------------------------------------------------------+
void CGUIManager::DisplayPositionRow(int row, int x, int y, int ticket, string type, 
                                    double lots, double price, double profit, string comment)
{
    string rowPrefix = "TableRow" + IntegerToString(row);
    color textColor = (StringFind(type, "BUY") >= 0) ? COLOR_LINE_BUY : COLOR_LINE_SELL;
    
    // ゴーストポジションは薄い色
    if(StringFind(type, "[G]") >= 0)
    {
        textColor = CColorUtils::Darken(textColor, 30);
    }
    
    int colX = x + 5;
    
    // #
    string ticketStr = ticket > 0 ? IntegerToString(ticket) : "---";
    CreateTextLabel(rowPrefix + "_No", ticketStr, colX, y, textColor, m_fontName, m_fontSize - 1, ANCHOR_LEFT);
    
    // Type
    colX += 30;
    CreateTextLabel(rowPrefix + "_Type", type, colX, y, textColor, m_fontName, m_fontSize - 1, ANCHOR_LEFT);
    
    // Lots
    colX += 50;
    CreateTextLabel(rowPrefix + "_Lots", DoubleToString(lots, 2), colX, y, textColor, m_fontName, m_fontSize - 1, ANCHOR_LEFT);
    
    // Price
    colX += 60;
    CreateTextLabel(rowPrefix + "_Price", DoubleToString(price, g_Trading.GetDigits()), colX, y, textColor, m_fontName, m_fontSize - 1, ANCHOR_LEFT);
    
    // Profit
    colX += 80;
    color profitColor = profit >= 0 ? clrLime : clrRed;
    CreateTextLabel(rowPrefix + "_Profit", CFormatUtils::FormatMoney(profit), colX, y, profitColor, m_fontName, m_fontSize - 1, ANCHOR_LEFT);
    
    // Comment
    colX += 80;
    string shortComment = StringLen(comment) > 15 ? StringSubstr(comment, 0, 15) + "..." : comment;
    CreateTextLabel(rowPrefix + "_Comment", shortComment, colX, y, COLOR_TEXT_LIGHT, m_fontName, m_fontSize - 1, ANCHOR_LEFT);
}

//+------------------------------------------------------------------+
//| 平均価格ライン作成                                               |
//+------------------------------------------------------------------+
void CGUIManager::CreateAveragePriceLine(int type, double price)
{
    if(!m_showAvgPriceLines || price <= 0) return;
    
    string lineName = GetUniqueObjectName(type == 0 ? "AvgPriceBuy" : "AvgPriceSell");
    color lineColor = (type == 0) ? COLOR_LINE_BUY : COLOR_LINE_SELL;
    
    // 既存のラインを削除
    if(ObjectFind(0, lineName) >= 0)
        ObjectDelete(0, lineName);
    
    // 新しいラインを作成
    #ifdef __MQL5__
    if(ObjectCreate(0, lineName, OBJ_HLINE, 0, 0, price))
    {
        ObjectSetInteger(0, lineName, OBJPROP_COLOR, lineColor);
        ObjectSetInteger(0, lineName, OBJPROP_STYLE, STYLE_DASH);
        ObjectSetInteger(0, lineName, OBJPROP_WIDTH, 2);
        ObjectSetInteger(0, lineName, OBJPROP_BACK, false);
        ObjectSetInteger(0, lineName, OBJPROP_SELECTABLE, true);
        ObjectSetInteger(0, lineName, OBJPROP_SELECTED, false);
        ObjectSetInteger(0, lineName, OBJPROP_HIDDEN, true);
        ObjectSetString(0, lineName, OBJPROP_TOOLTIP, StringFormat("%s Avg: %.5f", 
                       type == 0 ? "Buy" : "Sell", price));
        
        RegisterObject(lineName);
    }
    #else
    if(ObjectCreate(lineName, OBJ_HLINE, 0, 0, price))
    {
        ObjectSet(lineName, OBJPROP_COLOR, lineColor);
        ObjectSet(lineName, OBJPROP_STYLE, STYLE_DASH);
        ObjectSet(lineName, OBJPROP_WIDTH, 2);
        ObjectSet(lineName, OBJPROP_BACK, false);
        ObjectSet(lineName, OBJPROP_SELECTABLE, true);
        ObjectSetText(lineName, StringFormat("%s Avg: %.5f", type == 0 ? "Buy" : "Sell", price));
        
        RegisterObject(lineName);
    }
    #endif
    
    // 価格ラベル
    datetime labelTime = TimeCurrent() + PeriodSeconds(Period()) * 10;
    string labelName = GetUniqueObjectName(type == 0 ? "AvgPriceBuyLabel" : "AvgPriceSellLabel");
    
    if(ObjectFind(0, labelName) >= 0)
        ObjectDelete(0, labelName);
    
    #ifdef __MQL5__
    if(ObjectCreate(0, labelName, OBJ_TEXT, 0, labelTime, price))
    {
        ObjectSetString(0, labelName, OBJPROP_TEXT, StringFormat("%s AVG: %.5f", 
                       type == 0 ? "BUY" : "SELL", price));
        ObjectSetInteger(0, labelName, OBJPROP_COLOR, lineColor);
        ObjectSetString(0, labelName, OBJPROP_FONT, m_fontName);
        ObjectSetInteger(0, labelName, OBJPROP_FONTSIZE, m_fontSize);
        ObjectSetInteger(0, labelName, OBJPROP_ANCHOR, ANCHOR_LEFT);
        
        RegisterObject(labelName);
    }
    #else
    if(ObjectCreate(labelName, OBJ_TEXT, 0, labelTime, price))
    {
        ObjectSetText(labelName, StringFormat("%s AVG: %.5f", type == 0 ? "BUY" : "SELL", price), 
                     m_fontSize, m_fontName, lineColor);
        
        RegisterObject(labelName);
    }
    #endif
}

//+------------------------------------------------------------------+
//| TPライン作成                                                     |
//+------------------------------------------------------------------+
void CGUIManager::CreateTPLine(int type, double price)
{
    if(!m_showTPLines || price <= 0) return;
    
    string lineName = GetUniqueObjectName(type == 0 ? "TPLineBuy" : "TPLineSell");
    
    // 既存のラインを削除
    if(ObjectFind(0, lineName) >= 0)
        ObjectDelete(0, lineName);
    
    // 新しいラインを作成
    #ifdef __MQL5__
    if(ObjectCreate(0, lineName, OBJ_HLINE, 0, 0, price))
    {
        ObjectSetInteger(0, lineName, OBJPROP_COLOR, COLOR_LINE_TP);
        ObjectSetInteger(0, lineName, OBJPROP_STYLE, STYLE_DOT);
        ObjectSetInteger(0, lineName, OBJPROP_WIDTH, 1);
        ObjectSetInteger(0, lineName, OBJPROP_BACK, false);
        ObjectSetString(0, lineName, OBJPROP_TOOLTIP, StringFormat("%s TP: %.5f", 
                       type == 0 ? "Buy" : "Sell", price));
        
        RegisterObject(lineName);
    }
    #else
    if(ObjectCreate(lineName, OBJ_HLINE, 0, 0, price))
    {
        ObjectSet(lineName, OBJPROP_COLOR, COLOR_LINE_TP);
        ObjectSet(lineName, OBJPROP_STYLE, STYLE_DOT);
        ObjectSet(lineName, OBJPROP_WIDTH, 1);
        ObjectSet(lineName, OBJPROP_BACK, false);
        ObjectSetText(lineName, StringFormat("%s TP: %.5f", type == 0 ? "Buy" : "Sell", price));
        
        RegisterObject(lineName);
    }
    #endif
}

//+------------------------------------------------------------------+
//| ライン更新                                                       |
//+------------------------------------------------------------------+
void CGUIManager::UpdateLines()
{
    // Buy側
    if(g_Trading.PositionCount(POSITION_TYPE_BUY) > 0 || g_GhostBuyCount > 0)
    {
        double avgPrice = g_Trading.GetAveragePrice(POSITION_TYPE_BUY);
        if(avgPrice == 0 && g_GhostBuyCount > 0)
            avgPrice = CGhostManager::GetGhostAveragePrice(0);
        
        if(avgPrice > 0)
        {
            CreateAveragePriceLine(0, avgPrice);
            
            // TP計算とライン作成（設定に応じて）
            // double tpPrice = avgPrice + TakeProfitPoints * g_Trading.GetPoint();
            // CreateTPLine(0, tpPrice);
        }
    }
    else
    {
        // ポジションがない場合はラインを削除
        ObjectDelete(0, GetUniqueObjectName("AvgPriceBuy"));
        ObjectDelete(0, GetUniqueObjectName("AvgPriceBuyLabel"));
        ObjectDelete(0, GetUniqueObjectName("TPLineBuy"));
    }
    
    // Sell側
    if(g_Trading.PositionCount(POSITION_TYPE_SELL) > 0 || g_GhostSellCount > 0)
    {
        double avgPrice = g_Trading.GetAveragePrice(POSITION_TYPE_SELL);
        if(avgPrice == 0 && g_GhostSellCount > 0)
            avgPrice = CGhostManager::GetGhostAveragePrice(1);
        
        if(avgPrice > 0)
        {
            CreateAveragePriceLine(1, avgPrice);
            
            // TP計算とライン作成（設定に応じて）
            // double tpPrice = avgPrice - TakeProfitPoints * g_Trading.GetPoint();
            // CreateTPLine(1, tpPrice);
        }
    }
    else
    {
        // ポジションがない場合はラインを削除
        ObjectDelete(0, GetUniqueObjectName("AvgPriceSell"));
        ObjectDelete(0, GetUniqueObjectName("AvgPriceSellLabel"));
        ObjectDelete(0, GetUniqueObjectName("TPLineSell"));
    }
}

//+------------------------------------------------------------------+
//| すべてのラインを削除                                             |
//+------------------------------------------------------------------+
void CGUIManager::DeleteAllLines()
{
    string lineNames[] = {
        "AvgPriceBuy", "AvgPriceBuyLabel", "TPLineBuy",
        "AvgPriceSell", "AvgPriceSellLabel", "TPLineSell"
    };
    
    for(int i = 0; i < ArraySize(lineNames); i++)
    {
        string objName = GetUniqueObjectName(lineNames[i]);
        if(ObjectFind(0, objName) >= 0)
        {
            ObjectDelete(0, objName);
        }
    }
}

//+------------------------------------------------------------------+
//| チャートイベント処理                                             |
//+------------------------------------------------------------------+
bool CGUIManager::ProcessChartEvent(const int id, const long& lparam, const double& dparam, 
                                   const string& sparam)
{
    if(id == CHARTEVENT_OBJECT_CLICK)
    {
        // プレフィックスチェック
        if(StringFind(sparam, g_ObjectPrefix) == 0)
        {
            ProcessButtonClick(sparam);
            return true;
        }
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| ボタンクリック処理                                               |
//+------------------------------------------------------------------+
void CGUIManager::ProcessButtonClick(string buttonName)
{
    // プレフィックスを除去
    string originalName = buttonName;
    if(StringFind(buttonName, g_ObjectPrefix) == 0)
    {
        buttonName = StringSubstr(buttonName, StringLen(g_ObjectPrefix));
    }
    
    // ボタンの状態をリセット
    #ifdef __MQL5__
    ObjectSetInteger(0, originalName, OBJPROP_STATE, false);
    #else
    ObjectSet(originalName, OBJPROP_STATE, false);
    #endif
    
    // 各ボタンの処理
    if(buttonName == "btnCloseBuy")
    {
        CLogManager::Log("Close Buy clicked", CLogManager::LOG_INFO);
        g_Trading.ClosePosition(POSITION_TYPE_BUY);
        UpdatePositionTable();
    }
    else if(buttonName == "btnCloseSell")
    {
        CLogManager::Log("Close Sell clicked", CLogManager::LOG_INFO);
        g_Trading.ClosePosition(POSITION_TYPE_SELL);
        UpdatePositionTable();
    }
    else if(buttonName == "btnCloseAll")
    {
        CLogManager::Log("Close All clicked", CLogManager::LOG_INFO);
        g_Trading.CloseAllPositions();
        CGhostManager::ResetGhost(0);
        CGhostManager::ResetGhost(1);
        UpdatePositionTable();
    }
    else if(buttonName == "btnDirectBuy")
    {
        CLogManager::Log("Direct Buy clicked", CLogManager::LOG_INFO);
        g_Trading.OpenPosition(POSITION_TYPE_BUY, 0.1);
        UpdatePositionTable();
    }
    else if(buttonName == "btnDirectSell")
    {
        CLogManager::Log("Direct Sell clicked", CLogManager::LOG_INFO);
        g_Trading.OpenPosition(POSITION_TYPE_SELL, 0.1);
        UpdatePositionTable();
    }
    else if(buttonName == "btnGhostBuy")
    {
        if(g_GhostMode)
        {
            CGhostManager::InitializeGhostPosition(0, "Manual Ghost");
            UpdatePositionTable();
        }
        else
        {
            Alert("Ghost mode is disabled");
        }
    }
    else if(buttonName == "btnGhostSell")
    {
        if(g_GhostMode)
        {
            CGhostManager::InitializeGhostPosition(1, "Manual Ghost");
            UpdatePositionTable();
        }
        else
        {
            Alert("Ghost mode is disabled");
        }
    }
    else if(buttonName == "btnGhostToggle")
    {
        g_GhostMode = !g_GhostMode;
        
        if(!g_GhostMode)
        {
            CGhostManager::ResetGhost(0);
            CGhostManager::ResetGhost(1);
        }
        
        UpdateButton("btnGhostToggle", g_GhostMode ? "GHOST ON" : "GHOST OFF",
                    g_GhostMode ? COLOR_BUTTON_ACTIVE : COLOR_BUTTON_INACTIVE);
        UpdatePositionTable();
    }
    else if(buttonName == "btnAvgPriceToggle")
    {
        m_showAvgPriceLines = !m_showAvgPriceLines;
        
        UpdateButton("btnAvgPriceToggle", m_showAvgPriceLines ? "AVG PRICE ON" : "AVG PRICE OFF",
                    m_showAvgPriceLines ? COLOR_BUTTON_ACTIVE : COLOR_BUTTON_INACTIVE);
        
        if(!m_showAvgPriceLines)
            DeleteAllLines();
        else
            UpdateLines();
    }
    else if(buttonName == "btnShowInfo")
    {
        ShowInfoDialog();
    }
    else if(buttonName == "btnShowSettings")
    {
        ShowSettingsDialog();
    }
    
    ChartRedraw(0);
}

//+------------------------------------------------------------------+
//| 情報ダイアログ表示                                               |
//+------------------------------------------------------------------+
void CGUIManager::ShowInfoDialog()
{
    string message = "=== Position Information ===\n\n";
    
    // Buy側情報
    int buyCount = g_Trading.PositionCount(POSITION_TYPE_BUY);
    int buyGhostCount = CGhostManager::GetGhostCount(0);
    double buyAvgPrice = g_Trading.GetAveragePrice(POSITION_TYPE_BUY);
    double buyTotalLots = g_Trading.GetTotalLots(POSITION_TYPE_BUY);
    double buyProfit = g_Trading.GetTotalProfit(POSITION_TYPE_BUY);
    
    message += "[BUY Side]\n";
    message += "Positions: " + IntegerToString(buyCount) + 
               " (Ghost: " + IntegerToString(buyGhostCount) + ")\n";
    message += "Total Lots: " + DoubleToString(buyTotalLots, 2) + "\n";
    message += "Average Price: " + DoubleToString(buyAvgPrice, g_Trading.GetDigits()) + "\n";
    message += "Profit: " + CFormatUtils::FormatMoney(buyProfit) + "\n\n";
    
    // Sell側情報
    int sellCount = g_Trading.PositionCount(POSITION_TYPE_SELL);
    int sellGhostCount = CGhostManager::GetGhostCount(1);
    double sellAvgPrice = g_Trading.GetAveragePrice(POSITION_TYPE_SELL);
    double sellTotalLots = g_Trading.GetTotalLots(POSITION_TYPE_SELL);
    double sellProfit = g_Trading.GetTotalProfit(POSITION_TYPE_SELL);
    
    message += "[SELL Side]\n";
    message += "Positions: " + IntegerToString(sellCount) + 
               " (Ghost: " + IntegerToString(sellGhostCount) + ")\n";
    message += "Total Lots: " + DoubleToString(sellTotalLots, 2) + "\n";
    message += "Average Price: " + DoubleToString(sellAvgPrice, g_Trading.GetDigits()) + "\n";
    message += "Profit: " + CFormatUtils::FormatMoney(sellProfit) + "\n\n";
    
    // 合計
    message += "[TOTAL]\n";
    message += "Total Profit: " + CFormatUtils::FormatMoney(buyProfit + sellProfit) + "\n";
    
    MessageBox(message, "Position Information", MB_ICONINFORMATION);
}

//+------------------------------------------------------------------+
//| 設定ダイアログ表示                                               |
//+------------------------------------------------------------------+
void CGUIManager::ShowSettingsDialog()
{
    string message = "=== EA Settings ===\n\n";
    
    message += "[Basic Settings]\n";
    message += "Magic Number: " + IntegerToString(MagicNumber) + "\n";
    message += "Ghost Mode: " + (g_GhostMode ? "ON" : "OFF") + "\n";
    message += "Protection Mode: " + CEntryManager::GetProtectionModeText() + "\n\n";
    
    message += "[Layout Settings]\n";
    message += "Layout Pattern: " + GetLayoutPatternText() + "\n";
    message += "Panel Position: X=" + IntegerToString(m_effectivePanelX) + 
               ", Y=" + IntegerToString(m_effectivePanelY) + "\n";
    message += "Table Position: X=" + IntegerToString(m_effectiveTableX) + 
               ", Y=" + IntegerToString(m_effectiveTableY) + "\n\n";
    
    message += "[Display Settings]\n";
    message += "Show Panel: " + (m_showPanel ? "ON" : "OFF") + "\n";
    message += "Show Table: " + (m_showTable ? "ON" : "OFF") + "\n";
    message += "Show Avg Price Lines: " + (m_showAvgPriceLines ? "ON" : "OFF") + "\n";
    message += "Show TP Lines: " + (m_showTPLines ? "ON" : "OFF") + "\n";
    
    MessageBox(message, "EA Settings", MB_ICONINFORMATION);
}

//+------------------------------------------------------------------+
//| レイアウトパターンテキスト取得                                   |
//+------------------------------------------------------------------+
string CGUIManager::GetLayoutPatternText()
{
    switch(m_layoutPattern)
    {
        case LAYOUT_DEFAULT: return "Default (Panel Top/Table Bottom)";
        case LAYOUT_SIDE_BY_SIDE: return "Side by Side (Panel Left/Table Right)";
        case LAYOUT_TABLE_TOP: return "Table Top (Table Top/Panel Bottom)";
        case LAYOUT_COMPACT: return "Compact (Small Panel)";
        case LAYOUT_CUSTOM: return "Custom (User Defined)";
        default: return "Unknown";
    }
}

//+------------------------------------------------------------------+
//| 矩形ラベル作成（内部ヘルパー）                                   |
//+------------------------------------------------------------------+
void CGUIManager::CreateRectangleLabel(string name, int x, int y, int width, int height, 
                                      color bgColor, color borderColor, int borderWidth)
{
    string objName = GetUniqueObjectName(name);
    
    #ifdef __MQL5__
    if(ObjectCreate(0, objName, OBJ_RECTANGLE_LABEL, 0, 0, 0))
    {
        ObjectSetInteger(0, objName, OBJPROP_XDISTANCE, x);
        ObjectSetInteger(0, objName, OBJPROP_YDISTANCE, y);
        ObjectSetInteger(0, objName, OBJPROP_XSIZE, width);
        ObjectSetInteger(0, objName, OBJPROP_YSIZE, height);
        ObjectSetInteger(0, objName, OBJPROP_BGCOLOR, bgColor);
        ObjectSetInteger(0, objName, OBJPROP_BORDER_TYPE, borderWidth > 0 ? BORDER_FLAT : BORDER_NONE);
        ObjectSetInteger(0, objName, OBJPROP_COLOR, borderColor);
        ObjectSetInteger(0, objName, OBJPROP_WIDTH, borderWidth);
        ObjectSetInteger(0, objName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
        ObjectSetInteger(0, objName, OBJPROP_BACK, false);
        ObjectSetInteger(0, objName, OBJPROP_SELECTABLE, false);
        
        RegisterObject(objName);
    }
    #else
    if(ObjectCreate(objName, OBJ_RECTANGLE_LABEL, 0, 0, 0))
    {
        ObjectSet(objName, OBJPROP_XDISTANCE, x);
        ObjectSet(objName, OBJPROP_YDISTANCE, y);
        ObjectSet(objName, OBJPROP_XSIZE, width);
        ObjectSet(objName, OBJPROP_YSIZE, height);
        ObjectSet(objName, OBJPROP_BGCOLOR, bgColor);
        ObjectSet(objName, OBJPROP_BORDER_TYPE, borderWidth > 0 ? BORDER_FLAT : BORDER_NONE);
        ObjectSet(objName, OBJPROP_COLOR, borderColor);
        ObjectSet(objName, OBJPROP_WIDTH, borderWidth);
        ObjectSet(objName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
        ObjectSet(objName, OBJPROP_BACK, false);
        ObjectSet(objName, OBJPROP_SELECTABLE, false);
        
        RegisterObject(objName);
    }
    #endif
}

//+------------------------------------------------------------------+
//| テキストラベル作成（内部ヘルパー）                               |
//+------------------------------------------------------------------+
void CGUIManager::CreateTextLabel(string name, string text, int x, int y, color textColor, 
                                 string fontName, int fontSize, ENUM_ANCHOR_POINT anchor)
{
    string objName = GetUniqueObjectName(name);
    
    #ifdef __MQL5__
    if(ObjectCreate(0, objName, OBJ_LABEL, 0, 0, 0))
    {
        ObjectSetInteger(0, objName, OBJPROP_XDISTANCE, x);
        ObjectSetInteger(0, objName, OBJPROP_YDISTANCE, y);
        ObjectSetString(0, objName, OBJPROP_TEXT, text);
        ObjectSetInteger(0, objName, OBJPROP_COLOR, textColor);
        ObjectSetString(0, objName, OBJPROP_FONT, fontName);
        ObjectSetInteger(0, objName, OBJPROP_FONTSIZE, fontSize);
        ObjectSetInteger(0, objName, OBJPROP_ANCHOR, anchor);
        ObjectSetInteger(0, objName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
        ObjectSetInteger(0, objName, OBJPROP_SELECTABLE, false);
        
        RegisterObject(objName);
    }
    #else
    if(ObjectCreate(objName, OBJ_LABEL, 0, 0, 0))
    {
        ObjectSet(objName, OBJPROP_XDISTANCE, x);
        ObjectSet(objName, OBJPROP_YDISTANCE, y);
        ObjectSetText(objName, text, fontSize, fontName, textColor);
        ObjectSet(objName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
        ObjectSet(objName, OBJPROP_SELECTABLE, false);
        
        RegisterObject(objName);
    }
    #endif
}

//+------------------------------------------------------------------+
//| ユニークなオブジェクト名取得                                     |
//+------------------------------------------------------------------+
string CGUIManager::GetUniqueObjectName(string baseName)
{
    return g_ObjectPrefix + baseName;
}

//+------------------------------------------------------------------+
//| オブジェクト登録                                                 |
//+------------------------------------------------------------------+
void CGUIManager::RegisterObject(string name)
{
    CObjectManager::SaveObjectName(name, g_PanelNames, g_PanelObjectCount);
}

//+------------------------------------------------------------------+
//| パネル削除                                                       |
//+------------------------------------------------------------------+
void CGUIManager::DeletePanel()
{
    for(int i = 0; i < g_PanelObjectCount; i++)
    {
        if(ObjectFind(0, g_PanelNames[i]) >= 0)
        {
            ObjectDelete(0, g_PanelNames[i]);
        }
    }
    g_PanelObjectCount = 0;
}

//+------------------------------------------------------------------+
//| テーブル削除                                                     |
//+------------------------------------------------------------------+
void CGUIManager::DeleteTable()
{
    for(int i = 0; i < g_TableObjectCount; i++)
    {
        if(ObjectFind(0, g_TableNames[i]) >= 0)
        {
            ObjectDelete(0, g_TableNames[i]);
        }
    }
    g_TableObjectCount = 0;
}

//+------------------------------------------------------------------+
//| 全更新                                                          |
//+------------------------------------------------------------------+
void CGUIManager::RefreshAll()
{
    UpdatePanel();
    UpdatePositionTable();
    UpdateLines();
    ChartRedraw(0);
}

//+------------------------------------------------------------------+
//| パネル更新                                                       |
//+------------------------------------------------------------------+
void CGUIManager::UpdatePanel()
{
    // ゴーストモードボタン
    UpdateButton("btnGhostToggle", g_GhostMode ? "GHOST ON" : "GHOST OFF",
                g_GhostMode ? COLOR_BUTTON_ACTIVE : COLOR_BUTTON_INACTIVE);
    
    // 平均価格表示ボタン
    UpdateButton("btnAvgPriceToggle", m_showAvgPriceLines ? "AVG PRICE ON" : "AVG PRICE OFF",
                m_showAvgPriceLines ? COLOR_BUTTON_ACTIVE : COLOR_BUTTON_INACTIVE);
}

//+------------------------------------------------------------------+
//| グローバルGUIマネージャー                                        |
//+------------------------------------------------------------------+
CGUIManager* g_GUIManager = NULL;

//+------------------------------------------------------------------+
//| GUI初期化                                                        |
//+------------------------------------------------------------------+
void InitializeGUI(string panelTitle = "Unified EA Panel", LAYOUT_PATTERN layout = LAYOUT_DEFAULT)
{
    if(g_GUIManager == NULL)
    {
        g_GUIManager = new CGUIManager();
        g_GUIManager.Init(panelTitle, layout);
    }
}

//+------------------------------------------------------------------+
//| GUIクリーンアップ                                                |
//+------------------------------------------------------------------+
void CleanupGUI()
{
    if(g_GUIManager != NULL)
    {
        delete g_GUIManager;
        g_GUIManager = NULL;
    }
}

//+------------------------------------------------------------------+
//| GUI更新（OnTick用）                                              |
//+------------------------------------------------------------------+
void UpdateGUIOnTick()
{
    if(g_GUIManager != NULL)
    {
        static datetime lastUpdate = 0;
        datetime currentTime = TimeCurrent();
        
        // 1秒ごとに更新
        if(currentTime - lastUpdate >= 1)
        {
            g_GUIManager.UpdatePositionTable();
            g_GUIManager.UpdateLines();
            lastUpdate = currentTime;
        }
    }
}

//+------------------------------------------------------------------+
//| GUIイベント処理（OnChartEvent用）                                |
//+------------------------------------------------------------------+
void ProcessGUIEvent(const int id, const long& lparam, const double& dparam, const string& sparam)
{
    if(g_GUIManager != NULL)
    {
        g_GUIManager.ProcessChartEvent(id, lparam, dparam, sparam);
    }
}