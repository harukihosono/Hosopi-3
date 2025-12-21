//+------------------------------------------------------------------+
//|                    Hosopi 3 - 時間ベース戦略                      |
//|                           Copyright 2025                          |
//+------------------------------------------------------------------+
#include "Hosopi3_Defines.mqh"
#include "Hosopi3_Utils.mqh"

//+------------------------------------------------------------------+
//| 偶数/奇数時間エントリー戦略パラメータ                              |
//| パラメーターは Hosopi3_AllParams_*.mqh で定義済み                |
//+------------------------------------------------------------------+
// EvenOdd_UseJPTime と EvenOdd_IncludeWeekends は外部定義を使用

//+------------------------------------------------------------------+
//| 現在の時間が偶数か奇数かをチェック                                |
//+------------------------------------------------------------------+
bool IsEvenHour()
{
    datetime current_time;
    
    if(EvenOdd_UseJPTime)
        current_time = calculate_time();  // 日本時間を取得
    else
        current_time = TimeCurrent();     // サーバー時間を取得
    
    // 週末判定（土日）
    if(!EvenOdd_IncludeWeekends)
    {
        #ifdef __MQL4__
            int day_of_week = TimeDayOfWeek(current_time);
        #else
            MqlDateTime dt;
            TimeToStruct(current_time, dt);
            int day_of_week = dt.day_of_week;
        #endif
        
        if(day_of_week == 0 || day_of_week == 6) // 日曜日または土曜日
            return false;
    }
    
    // 時間を取得
    #ifdef __MQL4__
        int hour = TimeHour(current_time);
    #else
        MqlDateTime dt;
        TimeToStruct(current_time, dt);
        int hour = dt.hour;
    #endif
    
    return (hour % 2 == 0);
}

//+------------------------------------------------------------------+
//| 偶数/奇数戦略でエントリー可能かチェック                           |
//+------------------------------------------------------------------+
bool CanEntryByEvenOddStrategy(int operationType)
{
    if(EvenOdd_Entry_Strategy == EVEN_ODD_DISABLED)
        return true; // 戦略無効なら常に許可
    
    bool isEven = IsEvenHour();
    
    switch(EvenOdd_Entry_Strategy)
    {
        case EVEN_ONLY:
            return isEven;
            
        case ODD_ONLY:
            return !isEven;
            
        case EVEN_BUY_ODD_SELL:
            if(operationType == OP_BUY)
                return isEven;
            else if(operationType == OP_SELL)
                return !isEven;
            break;
            
        case ODD_BUY_EVEN_SELL:
            if(operationType == OP_BUY)
                return !isEven;
            else if(operationType == OP_SELL)
                return isEven;
            break;
            
        case EVEN_ODD_DISABLED:
        default:
            return true;
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| 時間フィルターチェック                                            |
//+------------------------------------------------------------------+
bool IsTimeAllowed(int operationType)
{
    datetime currentTime = calculate_time();
    
    #ifdef __MQL4__
        int dayOfWeek = TimeDayOfWeek(currentTime);
        int hour = TimeHour(currentTime);
        int minute = TimeMinute(currentTime);
    #else
        MqlDateTime dt;
        TimeToStruct(currentTime, dt);
        int dayOfWeek = dt.day_of_week;
        int hour = dt.hour;
        int minute = dt.min;
    #endif
    
    // 曜日フィルターチェック
    if(EnablePositionByDay)
    {
        switch(dayOfWeek)
        {
            case 0: if(!AllowSundayPosition) return false; break;
            case 1: if(!AllowMondayPosition) return false; break;
            case 2: if(!AllowTuesdayPosition) return false; break;
            case 3: if(!AllowWednesdayPosition) return false; break;
            case 4: if(!AllowThursdayPosition) return false; break;
            case 5: if(!AllowFridayPosition) return false; break;
            case 6: if(!AllowSaturdayPosition) return false; break;
        }
    }
    
    // 時間帯チェック
    int startHour, startMinute, endHour, endMinute;
    bool dayEnabled = true;
    
    switch(dayOfWeek)
    {
        case 0: // Sunday
            dayEnabled = (Sunday_Enable == ON_MODE);
            if(operationType == OP_BUY) {
                startHour = Sunday_Buy_StartHour;
                startMinute = Sunday_Buy_StartMinute;
                endHour = Sunday_Buy_EndHour;
                endMinute = Sunday_Buy_EndMinute;
            } else {
                startHour = Sunday_Sell_StartHour;
                startMinute = Sunday_Sell_StartMinute;
                endHour = Sunday_Sell_EndHour;
                endMinute = Sunday_Sell_EndMinute;
            }
            break;
            
        case 1: // Monday
            dayEnabled = (Monday_Enable == ON_MODE);
            if(operationType == OP_BUY) {
                startHour = Monday_Buy_StartHour;
                startMinute = Monday_Buy_StartMinute;
                endHour = Monday_Buy_EndHour;
                endMinute = Monday_Buy_EndMinute;
            } else {
                startHour = Monday_Sell_StartHour;
                startMinute = Monday_Sell_StartMinute;
                endHour = Monday_Sell_EndHour;
                endMinute = Monday_Sell_EndMinute;
            }
            break;

        case 2: // Tuesday
            dayEnabled = (Tuesday_Enable == ON_MODE);
            if(operationType == OP_BUY) {
                startHour = Tuesday_Buy_StartHour;
                startMinute = Tuesday_Buy_StartMinute;
                endHour = Tuesday_Buy_EndHour;
                endMinute = Tuesday_Buy_EndMinute;
            } else {
                startHour = Tuesday_Sell_StartHour;
                startMinute = Tuesday_Sell_StartMinute;
                endHour = Tuesday_Sell_EndHour;
                endMinute = Tuesday_Sell_EndMinute;
            }
            break;

        case 3: // Wednesday
            dayEnabled = (Wednesday_Enable == ON_MODE);
            if(operationType == OP_BUY) {
                startHour = Wednesday_Buy_StartHour;
                startMinute = Wednesday_Buy_StartMinute;
                endHour = Wednesday_Buy_EndHour;
                endMinute = Wednesday_Buy_EndMinute;
            } else {
                startHour = Wednesday_Sell_StartHour;
                startMinute = Wednesday_Sell_StartMinute;
                endHour = Wednesday_Sell_EndHour;
                endMinute = Wednesday_Sell_EndMinute;
            }
            break;

        case 4: // Thursday
            dayEnabled = (Thursday_Enable == ON_MODE);
            if(operationType == OP_BUY) {
                startHour = Thursday_Buy_StartHour;
                startMinute = Thursday_Buy_StartMinute;
                endHour = Thursday_Buy_EndHour;
                endMinute = Thursday_Buy_EndMinute;
            } else {
                startHour = Thursday_Sell_StartHour;
                startMinute = Thursday_Sell_StartMinute;
                endHour = Thursday_Sell_EndHour;
                endMinute = Thursday_Sell_EndMinute;
            }
            break;

        case 5: // Friday
            dayEnabled = (Friday_Enable == ON_MODE);
            if(operationType == OP_BUY) {
                startHour = Friday_Buy_StartHour;
                startMinute = Friday_Buy_StartMinute;
                endHour = Friday_Buy_EndHour;
                endMinute = Friday_Buy_EndMinute;
            } else {
                startHour = Friday_Sell_StartHour;
                startMinute = Friday_Sell_StartMinute;
                endHour = Friday_Sell_EndHour;
                endMinute = Friday_Sell_EndMinute;
            }
            break;

        case 6: // Saturday
            dayEnabled = (Saturday_Enable == ON_MODE);
            if(operationType == OP_BUY) {
                startHour = Saturday_Buy_StartHour;
                startMinute = Saturday_Buy_StartMinute;
                endHour = Saturday_Buy_EndHour;
                endMinute = Saturday_Buy_EndMinute;
            } else {
                startHour = Saturday_Sell_StartHour;
                startMinute = Saturday_Sell_StartMinute;
                endHour = Saturday_Sell_EndHour;
                endMinute = Saturday_Sell_EndMinute;
            }
            break;

        default:
            // 共通時間設定を使用（通常ここには来ないが安全のため）
            dayEnabled = (DayTimeControl_Active == ON_MODE);
            if(operationType == OP_BUY) {
                startHour = buy_StartHour;
                startMinute = buy_StartMinute;
                endHour = buy_EndHour;
                endMinute = buy_EndMinute;
            } else {
                startHour = sell_StartHour;
                startMinute = sell_StartMinute;
                endHour = sell_EndHour;
                endMinute = sell_EndMinute;
            }
            break;
    }
    
    if(!dayEnabled)
        return false;
    
    // 時間範囲チェック
    int currentTimeInMinutes = hour * 60 + minute;
    int startTimeInMinutes = startHour * 60 + startMinute;
    int endTimeInMinutes = endHour * 60 + endMinute;
    
    if(endTimeInMinutes > startTimeInMinutes)
    {
        // 通常の時間範囲 (例: 09:00-17:00)
        return (currentTimeInMinutes >= startTimeInMinutes && currentTimeInMinutes <= endTimeInMinutes);
    }
    else if(endTimeInMinutes < startTimeInMinutes)
    {
        // 日をまたぐ時間範囲 (例: 22:00-06:00)
        return (currentTimeInMinutes >= startTimeInMinutes || currentTimeInMinutes <= endTimeInMinutes);
    }
    
    // 24時間有効の場合
    return true;
}