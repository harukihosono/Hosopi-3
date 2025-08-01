//+------------------------------------------------------------------+
//|               Hosopi 3 - 定義・列挙型・グローバル変数             |
//|                         Copyright 2025                           |
//+------------------------------------------------------------------+


// ナンピンスキップの列挙型
enum NANPIN_SKIP {
    SKIP_NONE = 0,     // スキップなし
    SKIP_1 = 1,        // 1段目までゴースト、2段目からリアル
    SKIP_2 = 2,        // 2段目までゴースト、3段目からリアル
    SKIP_3 = 3,        // 3段目までゴースト、4段目からリアル
    SKIP_4 = 4,        // 4段目までゴースト、5段目からリアル
    SKIP_5 = 5,        // 5段目までゴースト、6段目からリアル
    SKIP_6 = 6,        // 6段目までゴースト、7段目からリアル
    SKIP_7 = 7,        // 7段目までゴースト、8段目からリアル
    SKIP_8 = 8,        // 8段目までゴースト、9段目からリアル
    SKIP_9 = 9,        // 9段目までゴースト、10段目からリアル
    SKIP_10 = 10,      // 10段目までゴースト、11段目からリアル
    SKIP_11 = 11,      // 11段目までゴースト、12段目からリアル
    SKIP_12 = 12,      // 12段目までゴースト、13段目からリアル
    SKIP_13 = 13,      // 13段目までゴースト、14段目からリアル
    SKIP_14 = 14,      // 14段目までゴースト、15段目からリアル
    SKIP_15 = 15,      // 15段目までゴースト、16段目からリアル
    SKIP_16 = 16,      // 16段目までゴースト、17段目からリアル
    SKIP_17 = 17,      // 17段目までゴースト、18段目からリアル
    SKIP_18 = 18,      // 18段目までゴースト、19段目からリアル
    SKIP_19 = 19,      // 19段目までゴースト、20段目からリアル
    SKIP_20 = 20       // 20段目までゴースト、21段目からリアル
};

// 最大ポジション数の列挙型
enum MAX_POSITIONS {
    POS_1 = 1,     // 1ポジション
    POS_2 = 2,     // 2ポジション
    POS_3 = 3,     // 3ポジション
    POS_4 = 4,     // 4ポジション
    POS_5 = 5,     // 5ポジション
    POS_6 = 6,     // 6ポジション
    POS_7 = 7,     // 7ポジション
    POS_8 = 8,     // 8ポジション
    POS_9 = 9,     // 9ポジション
    POS_10 = 10,   // 10ポジション
    POS_11 = 11,   // 11ポジション
    POS_12 = 12,   // 12ポジション
    POS_13 = 13,   // 13ポジション
    POS_14 = 14,   // 14ポジション
    POS_15 = 15,   // 15ポジション
    POS_16 = 16,   // 16ポジション
    POS_17 = 17,   // 17ポジション
    POS_18 = 18,   // 18ポジション
    POS_19 = 19,   // 19ポジション
    POS_20 = 20,   // 20ポジション
    POS_21 = 21,   // 21ポジション
    POS_22 = 22,   // 22ポジション
    POS_23 = 23,   // 23ポジション
    POS_24 = 24,   // 24ポジション
    POS_25 = 25,   // 25ポジション
    POS_26 = 26,   // 26ポジション
    POS_27 = 27,   // 27ポジション
    POS_28 = 28,   // 28ポジション
    POS_29 = 29,   // 29ポジション
    POS_30 = 30,   // 30ポジション
    POS_31 = 31,   // 31ポジション
    POS_32 = 32,   // 32ポジション
    POS_33 = 33,   // 33ポジション
    POS_34 = 34,   // 34ポジション
    POS_35 = 35,   // 35ポジション
    POS_36 = 36,   // 36ポジション
    POS_37 = 37,   // 37ポジション
    POS_38 = 38,   // 38ポジション
    POS_39 = 39,   // 39ポジション
    POS_40 = 40    // 40ポジション
};

// OnOff列挙型
enum ON_OFF {
    OFF_MODE = 0,     // OFF
    ON_MODE = 1       // ON
};

// 時間取得方法の列挙型
enum USE_TIMES {
    GMT9,              // WindowsPCの時間を使って計算する
    GMT9_BACKTEST,     // EAで計算された時間を使う（バックテスト用）
    GMT_KOTEI          // サーバータイムがGMT+0で固定されている（バックテスト用）
};

// エントリー方向制御
enum ENTRY_MODE {
    MODE_BUY_ONLY = 0,       // BUYのみ
    MODE_SELL_ONLY = 1,      // SELLのみ
    MODE_BOTH = 2            // BUY & SELL両方
};

// ポジション情報の構造体
struct PositionInfo {
    int type;           // 注文タイプ (OP_BUY/OP_SELL)
    double lots;        // ロットサイズ
    string symbol;      // 通貨ペア
    double price;       // 価格
    double profit;      // 利益/損失
    int ticket;         // チケット番号（ゴーストの場合は0）
    datetime openTime;  // オープン時間
    bool isGhost;       // ゴーストフラグ
    int level;          // ナンピンレベル
    double stopLoss;    // ストップロスレベル
};

//--- GUI関連定数
#define PANEL_WIDTH            300      // パネル幅
#define PANEL_HEIGHT           250      // パネル高さ
#define TITLE_HEIGHT           30       // タイトルの高さ
#define BUTTON_WIDTH           120      // ボタン幅
#define BUTTON_HEIGHT          30       // ボタン高さ
#define PANEL_MARGIN           10       // パネル内部マージン
#define PANEL_BORDER_WIDTH     2        // パネル枠線幅
#define STATUS_HEIGHT          20       // ステータス表示の高さ

//--- テーブル関連定数
#define TABLE_WIDTH            640      // テーブル幅
#define TABLE_ROW_HEIGHT       22       // テーブル行の高さ
#define TABLE_HEADER_BG        C'40,40,60'  // テーブルヘッダー背景色
#define TABLE_ROW_BG1          C'24,24,32'  // 奇数行背景色
#define TABLE_ROW_BG2          C'32,32,48'  // 偶数行背景色
#define TABLE_TEXT_COLOR       C'220,220,220' // テーブルテキスト色
#define TABLE_BUY_COLOR        C'0,160,255'   // Buy色
#define TABLE_SELL_COLOR       C'255,80,80'   // Sell色
#define TABLE_GHOST_COLOR      C'128,128,128' // ゴースト色
#define MAX_VISIBLE_ROWS       20       // 最大表示行数

//--- 色定義
#define COLOR_PANEL_BG         C'8,8,16'      // パネル背景色
#define COLOR_PANEL_BORDER     C'64,64,96'    // パネル枠線色
#define COLOR_TITLE_BG         C'32,32,64'    // タイトル背景色
#define COLOR_TITLE_TEXT       C'255,255,255' // タイトルテキスト色
#define COLOR_BUTTON_BUY       C'0,128,255'   // BUYボタン色
#define COLOR_BUTTON_SELL      C'255,64,64'   // SELLボタン色
#define COLOR_BUTTON_ACTIVE    C'0,160,0'     // アクティブボタン色
#define COLOR_BUTTON_INACTIVE  C'40,40,56'    // 非アクティブボタン色
#define COLOR_BUTTON_NEUTRAL   C'64,64,80'    // 中立ボタン色
#define COLOR_BUTTON_CLOSE_ALL C'255,215,0'   // 全決済ボタン色
#define COLOR_TEXT_LIGHT       C'240,240,240' // 明るいテキスト色
#define COLOR_TEXT_DARK        C'32,32,48'    // 暗いテキスト色
#define COLOR_STATUS_BG        C'24,24,36'    // ステータスバー背景色

//--- グローバル変数宣言

// ロットおよびナンピン幅のテーブル
double g_LotTable[40];         // ロットテーブル
int g_NanpinSpreadTable[40];   // ナンピン幅テーブル

// ゴーストポジション情報
PositionInfo g_GhostBuyPositions[40];  // ゴーストBuyポジション
PositionInfo g_GhostSellPositions[40]; // ゴーストSellポジション
int g_GhostBuyCount = 0;       // ゴーストBuyポジション数
int g_GhostSellCount = 0;      // ゴーストSellポジション数

// ゴーストポジションが閉じられたかを示すフラグ
bool g_BuyGhostClosed = false;
bool g_SellGhostClosed = false;

// フラグ・制御用変数
bool g_AutoTrading = true;    // 自動売買フラグ
bool g_GhostMode = true;      // ゴーストモードフラグ
bool g_ArrowsVisible = true;  // 矢印表示制御用フラグ
bool g_AvgPriceVisible = true; // 平均取得単価表示制御用フラグ
bool g_UseEvenOddHoursEntry = false; // 偶数/奇数時間エントリー使用フラグ

// 機能制御設定用の追加グローバル変数
bool g_EnableNanpin = true;         // ナンピン機能有効フラグ
bool g_EnableGhostEntry = true;     // ゴーストエントリー機能有効フラグ
bool g_EnableIndicatorsEntry = false; // テクニカル指標エントリー有効フラグ
bool g_EnableTimeEntry = false;      // 時間ベースエントリー有効フラグ
bool g_EnableFixedTP = true;        // 固定利確有効フラグ
bool g_EnableIndicatorsTP = false;  // テクニカル指標利確有効フラグ
bool g_EnableTrailingStop = false;  // トレーリングストップ有効フラグ

// 片側決済後の再エントリー制御用フラグと時間記録
bool g_BuyClosedRecently = false;    // Buy側が最近決済されたフラグ
bool g_SellClosedRecently = false;   // Sell側が最近決済されたフラグ
datetime g_BuyClosedTime = 0;        // Buy側の決済時間
datetime g_SellClosedTime = 0;       // Sell側の決済時間

// Hosopi3_Defines.mqh に追加する変数
bool g_ShowPositionTable = true;    // テーブル表示フラグ

// オブジェクト関連
string g_LineNames[10];    // ライン関連のオブジェクト名を保存する配列
int g_LineObjectCount = 0;
string g_EntryNames[200];   // エントリーポイント関連のオブジェクト名を保存する配列
int g_EntryObjectCount = 0;
string g_TableNames[500];   // テーブル関連のオブジェクト名を保存する配列
int g_TableObjectCount = 0;
string g_PanelNames[100];   // パネル関連のオブジェクト名を保存する配列
int g_PanelObjectCount = 0;

// 複数チャート対応のためのプレフィックス生成用変数
long g_AccountNumber = 0;        // 口座番号
string g_GlobalVarPrefix = "";   // グローバル変数プレフィックス
string g_ObjectPrefix = "";      // オブジェクト名プレフィックス

datetime g_LastUpdateTime = 0;   // 前回の更新時間

// キャッシュを活用するための変数を追加 (Hosopi3_Defines.mqh に追加)
// グローバル変数でエントリー制限の状態をキャッシュ
bool g_EquitySufficientCache = true;
datetime g_LastEquityCheckTime = 0;
bool g_TimeAllowedCache[2] = {true, true}; // [0]=Buy, [1]=Sell
datetime g_LastTimeAllowedCheckTime[2] = {0, 0}; // [0]=Buy, [1]=Sell

// 時間制限チェック用のキャッシュ（Utils.mqhから移動）
bool g_InitialTimeAllowedCache[2] = {true, true}; // [0]=Buy, [1]=Sell
datetime g_LastInitialTimeAllowedCheckTime[2] = {0, 0}; // [0]=Buy, [1]=Sell

// MQL5専用の定義
#ifdef __MQL5__
   // オーダーフィリングモードのグローバル変数
   ENUM_ORDER_TYPE_FILLING OrderFillingMode;
#endif
