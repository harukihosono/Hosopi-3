//+------------------------------------------------------------------+
//| Hosopi3_ParamHelp.mqh                                            |
//| パラメーターのFX初心者向け解説（ツールチップ用）。                 |
//| Hosopi3_ParamHelp(name) が説明文を返す。未登録は "" (ラベルのみ)。 |
//| セクション見出しは Hosopi3_SectionHelp(label) で番号プレフィックス |
//| 判定（MQL5=sinput group / MQL4=Title文字列 の両ラベルに対応）。    |
//| ※ELDRA2 ELDRA_ParamHelp.mqh の仕組みを移植。随時追記可。          |
//+------------------------------------------------------------------+
#ifndef HOSOPI3_PARAMHELP_MQH
#define HOSOPI3_PARAMHELP_MQH

//+------------------------------------------------------------------+
//| セクション見出しの解説（ラベル先頭の「番号.」で判定）             |
//+------------------------------------------------------------------+
string Hosopi3_SectionHelp(string label)
{
   if(StringFind(label, "1.") == 0)   return "【EAの基本動作】\nマジックナンバーやエントリー方向など、EA全体の土台となる設定です。複数のEA・チャートを同じ口座で動かすときはマジックナンバーの重複に注意。";
   if(StringFind(label, "2.") == 0)   return "【ナンピンマーチン＝下がったら買い増す】\n価格が逆行するたびに一定間隔でポジションを追加し、平均取得単価を有利な位置に引き寄せて小さな戻りで全決済する手法。段数とロット倍率が大きいほど必要証拠金が急増します。初心者は0.01ロット×低倍率から。";
   if(StringFind(label, "3.") == 0)   return "【利確・損切＝出口の設定】\n平均取得単価からの利確幅と、耐えきれない時に損失を確定するラインを決めます。ナンピン系EAは『利確は浅く・損切りは口座が耐えられる範囲で必ず』が基本。";
   if(StringFind(label, "5.") == 0)   return "【資金管理】\n有効証拠金が少ない時に新規エントリーを止めるなど、口座を守るための設定です。";
   if(StringFind(label, "6.") == 0)   return "【ゴーストエントリー＝Hosopi独自の仮想ナンピン】\n最初の数段はリアル注文を出さず『仮想ポジション（ゴースト）』として記録だけ進め、指定段からリアル注文に切り替えます。浅い押し戻りでは資金を使わず、深く逆行した時だけ実弾を投入する仕組み。";
   if(StringFind(label, "7.") == 0)   return "【時間フィルター】\n取引する曜日・時間帯を制限します。時間取得方法はGMT_AUTO（ブローカー名から自動判定）推奨。";
   if(StringFind(label, "36.") == 0)  return "【ボラありフィルター】\n値動き(ATR)がスプレッドに対して小さい静かな相場ではスプレッド負けしやすいため、エントリーを見送ります。";
   if(StringFind(label, "37.") == 0)  return "【高ボラフィルター＝急騰急落ブロック】\n指標発表などでATRが平常時の数倍に急拡大した危険な場面で新規エントリーをブロックします。ナンピンEAが荒れ相場に突っ込むのを防ぐ安全装置。";
   if(StringFind(label, "38.") == 0)  return "【資金不足ガード】\n証拠金が足りない状態での発注をOrderSend送信前にブロックします。資金枯渇口座でサーバーに発注を連打して口座凍結されるのを防ぐ保護機能。基本ONのまま推奨。";
   if(StringFind(label, "39.") == 0)  return "【注文レートガード】\n注文の連続失敗や1分あたりの過剰な注文数を検知してEAを一時停止する最終防衛線。連打・ロット暴走事故の再発防止機能。基本ONのまま推奨。";
   if(StringFind(label, "40.") == 0)  return "【ナンピンインターバル】\n前回ナンピンから一定時間が経つまで次のナンピンを禁止します。急落時に数秒で全段数を使い切ってしまう『高速積み増し』を抑制。";
   if(StringFind(label, "41.") == 0)  return "【時間決済・週末クローズ】\n古いポジションを時間経過で強制決済したり、週末の持ち越しを避けるためJST土曜の指定時刻に全決済します。窓開けリスク対策。";
   return "";
}

//+------------------------------------------------------------------+
//| パラメーター個別の解説（input変数名で判定）                       |
//+------------------------------------------------------------------+
string Hosopi3_ParamHelp(string n)
{
   if(n == "input_set_memo") return "このセットの説明・運用メモを自由記入。HTMLパラメータレポートの上部にメモとして大きく表示される。銘柄・推奨時間帯・検証結果・注意点などを書いておくと、後で設定を開いたとき一目で分かる。";

   //======== 1. 基本設定 ========
   if(n == "MagicNumber")            return "EAが自分の注文を識別するための番号。同じ口座で複数のEAやチャートを動かす場合は必ず別の番号にする。かぶると他のEAのポジションを勝手に決済する事故につながる。";
   if(n == "EAComment")              return "注文に付けるコメント文字列。取引履歴でどのEAの注文か見分けるのに使う。";
   if(n == "EntryMode")              return "エントリーする方向の制限。買いのみ／売りのみ／両方向から選択。相場観に合わせて片方向に絞ると資金効率が上がる。";
   if(n == "EnableAutomaticTrading") return "自動売買のマスタースイッチ。OFFにするとシグナルが出てもエントリーしない（GUIボタンからの手動操作は可能）。";
   if(n == "MaxSpreadPoints")        return "スプレッド（買値と売値の差＝取引コスト）がこのポイント数より広い時はエントリーを見送る。指標発表時や早朝のスプレッド拡大時の不利な約定を防ぐ。";
   if(n == "Slippage")               return "注文時に許容する価格のズレ（ポイント）。狭すぎると約定拒否が増え、広すぎると不利な価格で約定しやすい。";
   if(n == "EnableDebugLog")         return "詳細な動作ログをエキスパートログに出力する。動作検証・不具合調査のとき以外はOFFでよい。";

   //======== 2. ナンピンマーチン ========
   if(n == "InitialLot")             return "1段目（最初のエントリー）のロット数。ナンピンマーチンは段数が進むと倍率でロットが膨らむため、必ず最小の0.01から始めて資金と相談で調整する。";
   if(n == "MaxPositions")           return "最大ナンピン段数（同方向の最大ポジション数）。大きいほど深い逆行に耐えるが、後半の段は巨大ロットになり必要証拠金が急増する。資金に対して欲張らないこと。";
   if(n == "LotMultiplier")          return "ナンピン倍率。次の段のロット＝前の段×この倍率。1.8で15段まで行くと1段目の数百倍のロットになる。倍率を0.1下げるだけで最大リスクは大きく減る。";
   if(n == "NanpinSpread")           return "ナンピン間隔（ポイント）。前回エントリーからこの幅だけ逆行したら次の段を追加する。狭いとすぐ段数を消費し、広いと耐久力が上がる代わりに戻りで利確しにくい。";
   if(n == "NanpinSkipLevel")        return "指定した段数まではゴースト（仮想ポジション）で数え、その次の段からリアル注文を出す。例: SKIP_5なら1〜5段目は仮想、6段目から実弾。浅い逆行では資金を使わない仕組み。";
   if(n == "UseInitialLotForRealEntry") return "ONにすると、ゴーストからリアルに切り替わった最初の注文を（倍率計算ではなく）初期ロットで発注する。リスクを抑えたい時に。";
   if(n == "Enable001LotFix")        return "初期ロット0.01の時の特別処理（0.01→0.02固定など）。ロット計算の端数対策。";
   if(n == "UseAsyncOrders")         return "非同期注文を使う（MT5のみ）。複数ポジションの決済が高速になる。通常はONのまま。";
   if(n == "NanpinInterval")         return "ナンピンの最小間隔（分）。0=無制限。前回ナンピンからこの時間が経つまで次の段を追加しない。セクション40のナンピンインターバルと同種の機能（こちらが旧来設定）。";
   if(n == "UseAtrNanpinSpread")     return "ナンピン幅を固定ポイントではなくATR（平均的な値動き幅）ベースで自動調整する。ボラが大きい相場では間隔が広がり、静かな相場では狭まる。";
   if(n == "AtrTimeframe")           return "ATRベースのナンピン幅を計算する時間足。";
   if(n == "AtrPeriod")              return "ATR（値動き幅の平均）の期間。標準14。小さいほど直近の値動きに敏感。";
   if(n == "AtrMultiplier")          return "ナンピン幅＝ATR×この乗数。大きいほどナンピン間隔が広がる。";

   //======== 3. 利確・損切 ========
   if(n == "EnableTakeProfit")       return "利確機能ON/OFF。全ポジションの平均取得単価から利確幅に達したら、そのサイドを成行で全決済する。";
   if(n == "TakeProfitPoints")       return "利確幅（ポイント）。平均取得単価からこの幅だけ有利に動いたら全決済。ナンピン系は深追いせず浅めに取るのが基本。";
   if(n == "EnableBreakEvenByPositions") return "ポジション数が増えた時の建値決済ON/OFF。指定段数以上になったら、利益が出た時点（±0付近）で逃げる安全機能。";
   if(n == "BreakEvenMinPositions")  return "建値決済が発動する最低ポジション数。この段数以上ナンピンしてしまったら欲張らずに建値で撤退する。";
   if(n == "BreakEvenProfit")        return "建値決済とみなす最低利益額。0なら±0以上になった時点で決済。";
   if(n == "EnableMaxLossClose")     return "最大損失決済ON/OFF。合計含み損がこの金額に達したら全決済して損失を確定する『金額ベースの最終損切り』。口座を守る保険として設定推奨。";
   if(n == "MaxLossAmount")          return "最大損失額（口座通貨）。合計含み損がこの金額に達したら全ポジションを決済する。";
   if(n == "EnablePercentLossClose") return "残高%損失決済ON/OFF。合計含み損（スワップ・手数料込み）が残高×指定%に達したら全決済する。金額版（最大損失決済）の%版で、残高が変わっても比率で守れる。";
   if(n == "PercentLossLimit")       return "損失限度（残高に対する%）。例: 5.0なら残高の5%の含み損で全決済。";
   if(n == "FinalStopLossPoints")    return "最終損切り幅（ポイント）。平均取得単価からこの幅逆行したら決済する最後の砦。";

   //======== 4. トレーリング ========
   if(n == "EnableTrailingStop")     return "トレーリングストップON/OFF。含み益が伸びると決済ラインも一緒に追いかけ、利益を確保しながら伸ばす。トレンド相場向き。";
   if(n == "TrailingTrigger")        return "含み益がこのポイント数に達して初めてトレーリング開始。小さいと早く発動（早めに利益確保）、大きいと大きく伸びるまで待つ。";
   if(n == "TrailingOffset")         return "現在価格から何ポイント後ろに決済ラインを置いて追従するか。狭いとすぐ利確、広いと押し目に耐えて伸ばす。";

   //======== 5. 資金管理 ========
   if(n == "EquityControl_Active")   return "有効証拠金チェックON/OFF。有効証拠金が下の最低額を下回ったら新規エントリーを停止する。";
   if(n == "MinimumEquity")          return "新規エントリーに必要な最低有効証拠金（口座通貨）。これを下回ると新規を見送る。";
   if(n == "EnableCloseInterval")    return "決済後インターバルON/OFF。全決済した後、指定時間は次の初回エントリーをしない。連続被弾を防ぐクールダウン。";
   if(n == "CloseInterval")          return "決済後のインターバル（分）。";

   //======== 6. ゴースト ========
   if(n == "EnableGhostEntry")       return "ゴーストエントリー機能ON/OFF。ONだと最初の数段（ナンピンスキップレベルまで）は仮想ポジションとして記録だけ進め、リアル資金を使わない。OFFだと1段目からリアル注文。";
   if(n == "EnableIndicatorGhostEntry") return "インジケーター（戦略）シグナルの初回エントリーをゴーストから開始するか。OFF（既定）だと自動売買ON時のシグナルは1段目から即リアル注文。ONだとナンピンスキップレベルまで仮想ポジションで進め、超えた段からリアル注文になる（バックテストと同じ挙動）。";
   if(n == "GhostBuyColor")          return "チャートに表示するゴースト買いポジション矢印の色。";
   if(n == "GhostSellColor")         return "チャートに表示するゴースト売りポジション矢印の色。";
   if(n == "GhostArrowSize")         return "ゴースト矢印の表示サイズ。";

   //======== 7. 時間フィルター ========
   if(n == "set_time")               return "時間の取得方法。GMT_AUTO（推奨）＝ブローカー名からタイムゾーンを自動検出して日本時間に換算。GMT9=PC時間使用。GMT9_BACKTEST=バックテスト用に夏/冬オフセットを手動指定。";
   if(n == "natu")                   return "夏時間のGMTオフセット（時間）。GMT9_BACKTESTモードで使用。多くの海外ブローカーは夏GMT+3→日本時間換算で6。";
   if(n == "huyu")                   return "冬時間のGMTオフセット（時間）。GMT9_BACKTESTモードで使用。多くの海外ブローカーは冬GMT+2→7。";
   if(n == "EnablePositionByDay")    return "曜日別エントリー制御ON/OFF。ONにすると下の曜日別許可設定に従う。";
   if(n == "DayTimeControl_Active")  return "時間帯別エントリー制御ON/OFF。ONにすると指定の時間帯だけエントリーする。OFFなら時間フィルター無効（終日エントリー可）。";

   //======== 9. 戦略エントリー条件 ========
   if(n == "Strategy_Entry_Condition") return "テクニカル戦略シグナルが出た時にエントリーを許可する条件。『同方向ポジションがない場合のみ』が基本。『常に許可』は追撃・両建てを許すため上級者向け。";
   if(n == "Indicator_Condition_Type") return "複数のテクニカル指標を有効にした場合の判定方法。OR=どれか1つ成立でエントリー、AND=全部成立した時だけエントリー（厳選）。";

   //======== 18. 常時エントリー ========
   if(n == "ConstantEntryStrategy")  return "シグナルを待たず常にエントリーし続ける戦略。ナンピン＋利確のサイクルを回し続ける運用に使う。方向（ロング/ショート/両方）を選択。";
   if(n == "ConstantEntryInterval")  return "常時エントリーの間隔（分、0=無制限）。決済後すぐ再エントリーせず一定間隔を空ける。";

   //======== 23-25. 個別指定 ========
   if(n == "IndividualLotEnabled")   return "ONにすると倍率計算ではなく、段ごとに手で指定したロット（Lot_1〜Lot_40）を使う。細かくリスクを設計したい人向け。";
   if(n == "IndividualSpreadEnabled") return "ONにすると固定ナンピン幅ではなく、段ごとに指定した間隔（Spread_1〜Spread_40）を使う。深い段ほど間隔を広げる等の設計が可能。";
   if(n == "VariableTP_Enabled")     return "ONにするとポジション数に応じた利確幅（TP_Level1〜40）を使う。段数が増えるほど利確を浅くして早く逃げる設計が定石。";

   //======== 26. インジケーターエントリー ========
   if(n == "InpIndicatorMode")       return "カスタムインジケーターをエントリーに使うか、決済に使うか、両方かを選択。";
   if(n == "InpIndicatorName")       return "使用するカスタムインジケーターのファイル名（Indicatorsフォルダ内）。オブジェクト名/矢印コード判定のみ使う場合はインジケーターハンドル不要。";
   if(n == "InpEntryCondition")      return "インジケーターシグナルでエントリーする時のポジション条件。『完全ノーポジ時のみ』が最も安全。";

   //======== 35. オブジェクト条件 ========
   if(n == "BuySignalPrefix")        return "チャート上のオブジェクト名にこの文字列が含まれていたら（部分一致）買いシグナルとみなす。他のインジケーターが描く矢印オブジェクトを拾ってエントリーできる。";
   if(n == "SellSignalPrefix")       return "オブジェクト名にこの文字列が含まれていたら（部分一致）売りシグナルとみなす。";

   //======== 35b. 矢印コード条件 ========
   if(n == "InpEnableBuySignalArrow") return "オブジェクト名ではなく矢印コード（Wingdings番号）で買いシグナルを検知する。名前がランダムなインジケーターの矢印でも拾える。";
   if(n == "InpEnableSellSignalArrow") return "矢印コードで売りシグナルを検知する。";
   if(n == "InpBuySignalArrowCode")  return "買いシグナルとみなす矢印コード（Wingdings番号）。233=上矢印が一般的。";
   if(n == "InpSellSignalArrowCode") return "売りシグナルとみなす矢印コード。234=下矢印が一般的。";
   if(n == "InpBuyExitArrowCode")    return "買いポジションを決済する矢印コード。既定234=下矢印。";
   if(n == "InpSellExitArrowCode")   return "売りポジションを決済する矢印コード。既定233=上矢印。";

   //======== 36. ボラありフィルター ========
   if(n == "InpVolatilityFilterEnabled") return "値動きフィルターON/OFF。値動き(ATR)が小さい静かな相場ではスプレッド負けしやすいので、エントリーを見送る。";
   if(n == "InpVolatilityATRTimeframe")  return "値動きの大きさを測るATRの時間足。短い足(M5等)で直近の勢いを見る。";
   if(n == "InpVolatilityATRPeriod")     return "ATR(値動き幅の平均)の期間。小さいほど直近の値動きに敏感。";
   if(n == "InpVolatilitySpreadMultiplier") return "『ATR > スプレッド×この倍率』の時だけエントリー許可。大きいほど厳しく（よく動く時だけ）。無駄なコスト負けを防ぐ。";
   if(n == "InpVolatilityFilterMode")    return "フィルターを初回エントリーだけに掛けるか、ナンピンにも掛けるかの選択。";

   //======== 37. 高ボラフィルター ========
   if(n == "InpHighVolFilterEnabled")    return "高ボラフィルターON/OFF。現在のATRが平均ATRの指定倍を超えた『急騰急落中』は新規エントリーをブロックする。指標発表時の突っ込みエントリー防止。";
   if(n == "InpHighVolATRPeriod")        return "平均ATRの期間。標準14。";
   if(n == "InpHighVolATRMultiplier")    return "ブロック発動の倍率。『現在ATR > 平均ATR×この値』で新規を止める。2.0=平常時の2倍動いたら危険とみなす。";
   if(n == "InpHighVolFilterMode")       return "フィルターを初回のみ/ナンピンのみ/全部に適用するかの選択。";
   if(n == "InpHighVolFilterApplyToGhost") return "ゴースト（仮想）エントリーにも高ボラブロックを適用するか。OFFならゴーストは通し、リアル注文だけブロックする。";

   //======== 38. 資金不足ガード ========
   if(n == "EnableFundsGuard")       return "資金不足ガードON/OFF。有効証拠金・余剰証拠金が最小ロットの必要証拠金を下回ると発注前にブロックする。サーバーがNO_MONEYエラーを返した場合も300秒ラッチして連打を防ぐ。基本ON推奨。";
   if(n == "FundsGuardMinEquity")    return "この有効証拠金（口座通貨）を下回ったらエントリーを止める追加のしきい値。0=自動判定（必要証拠金ベース）のみ。";

   //======== 39. 注文レートガード ========
   if(n == "EnableOrderRateGuard")   return "注文レートガードON/OFF。注文の連続失敗や過剰な注文頻度を検知してEAを停止する最終防衛線。連打・ロット暴走事故の保険として基本ON推奨。";
   if(n == "OrderFailStopCount")     return "注文がこの回数連続で失敗したら一時停止する（0=無効）。";
   if(n == "OrderFailHardStopTrips") return "一時停止がこの回数繰り返されたら完全停止する（0=無効）。何かが根本的におかしい状態の保護。";
   if(n == "OrderFailAutoRecoverMin") return "完全停止から自動復帰するまでの時間（分）。0=自動復帰なし（EA再起動が必要）。";
   if(n == "OrderRateMaxPerMin")     return "1分あたりの最大注文操作数（0=監視無効）。これを超えるとクールダウンに入る。正常運用では届かない値にしておく暴走検知用。";
   if(n == "OrderRateCooldownSec")   return "レート超過時に注文を止める時間（秒）。";

   //======== 40. ナンピンインターバル ========
   if(n == "EnableNanpinInterval")   return "ナンピンインターバルON/OFF。前回ナンピンから指定時間が経つまで次のナンピンをスキップする。急変時に数分で全段数を使い切る事故を防ぐ。";
   if(n == "NanpinIntervalMinutes")  return "ナンピンとナンピンの最小間隔（分）。";

   //======== 41. 時間決済・週末クローズ ========
   if(n == "EnableTimeClose")        return "時間決済ON/OFF。そのサイドの最古ポジションが指定時間を経過したらサイド全体を決済する。塩漬け防止。";
   if(n == "TimeCloseMinutes")       return "決済までの経過時間（分）。最古の建玉基準。";
   if(n == "EnableWeekendClose")     return "週末クローズON/OFF。日本時間土曜の指定時刻に全ポジションを決済し、週明けの窓開けリスクを避ける。";
   if(n == "WeekendCloseTime")       return "週末クローズの時刻（HHMM形式、日本時間の土曜日）。例: 0545=土曜早朝5時45分（NYクローズ直前）。";

   return "";   // 未登録: ラベルのみ表示
}

#endif // HOSOPI3_PARAMHELP_MQH
