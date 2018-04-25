;# multiple level short key

;; table definition
;; Parameters:
;;   sub_tables  : sub key tables
;;   act_sub_idx : active sub key index in sub_tables
;;   tip         : which will be shown to user
;;   handle      : the handler for currently hit key combination

mlsk_exec_table1               := {sub_tables:[], act_sub_idx:-1, keys:"",            tip:"mlsk execute table 1",  handle:""}
mlsk_exec_table2               := {sub_tables:[], act_sub_idx:-1, keys:"",            tip:"mlsk execute table 2",  handle:""}
mlsk_exec_tables               := [mlsk_exec_table1, mlsk_exec_table2]

mlsk_ctrl_table                := {sub_tables:[], act_sub_idx:-1, keys:"",            tip:"mlsk control table",    handle:"", act_exec_table:mlsk_exec_table1}
mlsk_ctrl_table.sub_tables[1]  := {sub_tables:[], act_sub_idx:-1, keys:"ctrl+alt+s",  tip:"suspend mlsk",          handle:"mlsk_util_suspend_hot_keys"}
mlsk_ctrl_table.sub_tables[2]  := {sub_tables:[], act_sub_idx:-1, keys:"ctrl+alt+t",  tip:"suspend mlsk timed",    handle:"mlsk_util_suspend_hot_keys_timed"}
mlsk_ctrl_table.sub_tables[3]  := {sub_tables:[], act_sub_idx:-1, keys:"ctrl+alt+g",  tip:"test",    handle:"mlsk_util_dummy"}

mlsk_exec_table1               := {sub_tables:[], act_sub_idx:-1, keys:"",            tip:"mlsk execute table 1",  handle:""}
mlsk_exec_table1.sub_tables[1] := {sub_tables:[], act_sub_idx:-1, keys:"ctrl+alt+w",  tip:"ctrl+alt+w",            handle:"mlsk_util_dummy"}


;; control table utility definition
mlsk_util_show_tip(tipString, tipTimer)
{
    ToolTip %tipString%, 100, 400
    SetTimer, RemoveToolTip, %tipTimer%
    return

    RemoveToolTip:
    SetTimer, RemoveToolTip, Off
    ToolTip
    return
}

mlsk_util_suspend_hot_keys()
{
    Suspend, On
    Return
}

mlsk_util_suspend_hot_keys_timed()
{
    Suspend, On
    suspendTimer := 3000
    
    SetTimer, mlsk_suspend_timer, %suspendTimer%
    return

    mlsk_suspend_timer:
    SetTimer, mlsk_suspend_timer, Off
    Suspend, Off
    return
}

mlsk_util_resume_hot_keys()
{
    Suspend, Off
    Return
}

mlsk_util_dummy()
{
    MsgBox, mlsk_util_dummy called
    Return
}

mlsk_util_log(log_str)
{
    if(0)
    {
        MsgBox % log_str
        mlsk_util_show_tip(log_str, 3000)
    }
    else
    {
        mlsk_util_show_tip(log_str, 3000)
    }
    Return
}

mlsk_util_function_call(function_name)
{
    if(function_name == "")
    {
        Return
    }
    
    fn := Func(function_name)
    fn.() ;; TODO: old form, new form should be: fn.Call(), Requires [v1.1.19+]
    Return
}

mlsk_util_table_check(mlsk_table) ;; duplicate key combination check for given table
{
    sub_tables        := mlsk_table.sub_tables
    existing_key_list := {}
    
    if(mlsk_table.HasKey("sub_tables") && sub_tables == [])
    {
        Return 0
    }
    else
    {
        for index, sub_table in sub_tables
        {
            keys := sub_table.keys
            if(keys != "")
            {
                mlsk_util_log("duplicate keys check:" (keys) ",  hasKey? " (existing_key_list.HasKey(keys)))
                
                if(existing_key_list.HasKey(keys))
                {
                    mlsk_util_log("keys of " (keys) " is duplicated, please check")
                    Return 1
                }
                else
                {
                    existing_key_list[keys] := 1 ;;mark keys already exists
                }
            }
            else
            {
                Continue
            }
        }
        
        for index, sub_table in sub_tables
        {
            mlsk_util_table_check(sub_table)
        }
    }
    
    Return
}

mlsk_table_index_clear(mlsk_table)
{
    mlsk_table.act_sub_idx := -1
    
    Return
}

mlsk_table_index_clear_all(mlsk_table)
{
    mlsk_table.act_sub_idx := -1
    
    if(mlsk_table.sub_tables != [])
    {
        for index, sub_table in mlsk_table.sub_tables
        {
            mlsk_table_index_clear_all(sub_table)
        }
    }
    
    Return
}

;; control scheduler
mlsk_table_call(mlsk_table, keys) ;; Return 0: hotkey not found, Return 1: hotkey found
{
    act_sub_idx := mlsk_table.act_sub_idx
    sub_tables  := mlsk_table.sub_tables

    mlsk_util_table_check(mlsk_table)
    
    mlsk_util_log("act_sub_idx is " (act_sub_idx))
    
    if(!mlsk_table.HasKey("act_sub_idx"))
    {
        mlsk_util_log("Not a valid hotkey table")
        Return
    }
    
    if(act_sub_idx == -1) ;; need to loop sub_tables if exist
    {
        if(sub_tables == []) ;; empty sub tables
        {
        }
        else
        {
            for index, sub_table in sub_tables
            {
                if(sub_table.keys == keys)
                {
                    mlsk_util_log("keys found")
                    
                    mlsk_util_function_call(sub_table.handle)
                    mlsk_table_index_clear_all(mlsk_table)
                    mlsk_util_show_tip(sub_table.tip, 3000)
                    Return 1
                }
            }
        }        
    }
    else if(act_sub_idx >= 1) 
    {
        if(sub_tables == [])
        {
        }
        else
        {
            sub_table = sub_tables[act_sub_idx]
            mlsk_table_call(sub_table, keys)
        }        
    }
    else ;; not possible, valid array index begins from 1
    {
        mlsk_util_log("The index of sub table is not valid, it should be -1 or Positive Integer number. Reset to -1")
        mlsk_table_index_clear_all(mlsk_table)
    }
    
    Return 0
}

mlsk_table_scheduler(keys_name, keys_combo)
{
    Global mlsk_ctrl_table
    
    if(mlsk_table_call(mlsk_ctrl_table, keys_name) == 0)
    {
        mlsk_util_log((keys_combo)": key not found in control table")
        
        act_exec_table := mlsk_ctrl_table.act_exec_table
        if(mlsk_table_call(act_exec_table, keys_name) == 0)
        {
            mlsk_util_log((keys_combo)": key not found in execute table, will resend it as it is")

            Suspend, On
            Send % keys_combo
            Suspend, Off
        }
    }
    else
    {
        mlsk_util_log("key found in control table")
    }
    
    Return
}

;; execute table function definition
mlsk_exec_call_everything()
{
    Run, C:\Program Files (x86)\Everything\Everything.exe
    Return 
}

;; key combination definition
;;Ctrl+%c%
^a:: mlsk_table_scheduler("ctrl+a","{ctrl down}a{ctrl up}"), Return
^b:: mlsk_table_scheduler("ctrl+b","{ctrl down}b{ctrl up}"), Return
^c:: mlsk_table_scheduler("ctrl+c","{ctrl down}c{ctrl up}"), Return
^d:: mlsk_table_scheduler("ctrl+d","{ctrl down}d{ctrl up}"), Return
^e:: mlsk_table_scheduler("ctrl+e","{ctrl down}e{ctrl up}"), Return
^f:: mlsk_table_scheduler("ctrl+f","{ctrl down}f{ctrl up}"), Return
^g:: mlsk_table_scheduler("ctrl+g","{ctrl down}g{ctrl up}"), Return
^h:: mlsk_table_scheduler("ctrl+h","{ctrl down}h{ctrl up}"), Return
^i:: mlsk_table_scheduler("ctrl+i","{ctrl down}i{ctrl up}"), Return
^j:: mlsk_table_scheduler("ctrl+j","{ctrl down}j{ctrl up}"), Return
^k:: mlsk_table_scheduler("ctrl+k","{ctrl down}k{ctrl up}"), Return
^l:: mlsk_table_scheduler("ctrl+l","{ctrl down}l{ctrl up}"), Return
^m:: mlsk_table_scheduler("ctrl+m","{ctrl down}m{ctrl up}"), Return
^n:: mlsk_table_scheduler("ctrl+n","{ctrl down}n{ctrl up}"), Return
^o:: mlsk_table_scheduler("ctrl+o","{ctrl down}o{ctrl up}"), Return
^p:: mlsk_table_scheduler("ctrl+p","{ctrl down}p{ctrl up}"), Return
^q:: mlsk_table_scheduler("ctrl+q","{ctrl down}q{ctrl up}"), Return
^r:: mlsk_table_scheduler("ctrl+r","{ctrl down}r{ctrl up}"), Return
^s:: mlsk_table_scheduler("ctrl+s","{ctrl down}s{ctrl up}"), Return
^t:: mlsk_table_scheduler("ctrl+t","{ctrl down}t{ctrl up}"), Return
^u:: mlsk_table_scheduler("ctrl+u","{ctrl down}u{ctrl up}"), Return
^v:: mlsk_table_scheduler("ctrl+v","{ctrl down}v{ctrl up}"), Return
^w:: mlsk_table_scheduler("ctrl+w","{ctrl down}w{ctrl up}"), Return
^x:: mlsk_table_scheduler("ctrl+x","{ctrl down}x{ctrl up}"), Return
^y:: mlsk_table_scheduler("ctrl+y","{ctrl down}y{ctrl up}"), Return
^z:: mlsk_table_scheduler("ctrl+z","{ctrl down}z{ctrl up}"), Return
^0:: mlsk_table_scheduler("ctrl+0","{ctrl down}0{ctrl up}"), Return
^1:: mlsk_table_scheduler("ctrl+1","{ctrl down}1{ctrl up}"), Return
^2:: mlsk_table_scheduler("ctrl+2","{ctrl down}2{ctrl up}"), Return
^3:: mlsk_table_scheduler("ctrl+3","{ctrl down}3{ctrl up}"), Return
^4:: mlsk_table_scheduler("ctrl+4","{ctrl down}4{ctrl up}"), Return
^5:: mlsk_table_scheduler("ctrl+5","{ctrl down}5{ctrl up}"), Return
^6:: mlsk_table_scheduler("ctrl+6","{ctrl down}6{ctrl up}"), Return
^7:: mlsk_table_scheduler("ctrl+7","{ctrl down}7{ctrl up}"), Return
^8:: mlsk_table_scheduler("ctrl+8","{ctrl down}8{ctrl up}"), Return
^9:: mlsk_table_scheduler("ctrl+9","{ctrl down}9{ctrl up}"), Return

;;Alt+%c%
!a:: mlsk_table_scheduler("alt+a","{alt down}a{alt up}"), Return
!b:: mlsk_table_scheduler("alt+b","{alt down}b{alt up}"), Return
!c:: mlsk_table_scheduler("alt+c","{alt down}c{alt up}"), Return
!d:: mlsk_table_scheduler("alt+d","{alt down}d{alt up}"), Return
!e:: mlsk_table_scheduler("alt+e","{alt down}e{alt up}"), Return
!f:: mlsk_table_scheduler("alt+f","{alt down}f{alt up}"), Return
!g:: mlsk_table_scheduler("alt+g","{alt down}g{alt up}"), Return
!h:: mlsk_table_scheduler("alt+h","{alt down}h{alt up}"), Return
!i:: mlsk_table_scheduler("alt+i","{alt down}i{alt up}"), Return
!j:: mlsk_table_scheduler("alt+j","{alt down}j{alt up}"), Return
!k:: mlsk_table_scheduler("alt+k","{alt down}k{alt up}"), Return
!l:: mlsk_table_scheduler("alt+l","{alt down}l{alt up}"), Return
!m:: mlsk_table_scheduler("alt+m","{alt down}m{alt up}"), Return
!n:: mlsk_table_scheduler("alt+n","{alt down}n{alt up}"), Return
!o:: mlsk_table_scheduler("alt+o","{alt down}o{alt up}"), Return
!p:: mlsk_table_scheduler("alt+p","{alt down}p{alt up}"), Return
!q:: mlsk_table_scheduler("alt+q","{alt down}q{alt up}"), Return
!r:: mlsk_table_scheduler("alt+r","{alt down}r{alt up}"), Return
!s:: mlsk_table_scheduler("alt+s","{alt down}s{alt up}"), Return
!t:: mlsk_table_scheduler("alt+t","{alt down}t{alt up}"), Return
!u:: mlsk_table_scheduler("alt+u","{alt down}u{alt up}"), Return
!v:: mlsk_table_scheduler("alt+v","{alt down}v{alt up}"), Return
!w:: mlsk_table_scheduler("alt+w","{alt down}w{alt up}"), Return
!x:: mlsk_table_scheduler("alt+x","{alt down}x{alt up}"), Return
!y:: mlsk_table_scheduler("alt+y","{alt down}y{alt up}"), Return
!z:: mlsk_table_scheduler("alt+z","{alt down}z{alt up}"), Return
!0:: mlsk_table_scheduler("alt+0","{alt down}0{alt up}"), Return
!1:: mlsk_table_scheduler("alt+1","{alt down}1{alt up}"), Return
!2:: mlsk_table_scheduler("alt+2","{alt down}2{alt up}"), Return
!3:: mlsk_table_scheduler("alt+3","{alt down}3{alt up}"), Return
!4:: mlsk_table_scheduler("alt+4","{alt down}4{alt up}"), Return
!5:: mlsk_table_scheduler("alt+5","{alt down}5{alt up}"), Return
!6:: mlsk_table_scheduler("alt+6","{alt down}6{alt up}"), Return
!7:: mlsk_table_scheduler("alt+7","{alt down}7{alt up}"), Return
!8:: mlsk_table_scheduler("alt+8","{alt down}8{alt up}"), Return
!9:: mlsk_table_scheduler("alt+9","{alt down}9{alt up}"), Return

;;Shift+%c
+a:: mlsk_table_scheduler("shift+a","{shift down}a{shift up}"), Return
+b:: mlsk_table_scheduler("shift+b","{shift down}b{shift up}"), Return
+c:: mlsk_table_scheduler("shift+c","{shift down}c{shift up}"), Return
+d:: mlsk_table_scheduler("shift+d","{shift down}d{shift up}"), Return
+e:: mlsk_table_scheduler("shift+e","{shift down}e{shift up}"), Return
+f:: mlsk_table_scheduler("shift+f","{shift down}f{shift up}"), Return
+g:: mlsk_table_scheduler("shift+g","{shift down}g{shift up}"), Return
+h:: mlsk_table_scheduler("shift+h","{shift down}h{shift up}"), Return
+i:: mlsk_table_scheduler("shift+i","{shift down}i{shift up}"), Return
+j:: mlsk_table_scheduler("shift+j","{shift down}j{shift up}"), Return
+k:: mlsk_table_scheduler("shift+k","{shift down}k{shift up}"), Return
+l:: mlsk_table_scheduler("shift+l","{shift down}l{shift up}"), Return
+m:: mlsk_table_scheduler("shift+m","{shift down}m{shift up}"), Return
+n:: mlsk_table_scheduler("shift+n","{shift down}n{shift up}"), Return
+o:: mlsk_table_scheduler("shift+o","{shift down}o{shift up}"), Return
+p:: mlsk_table_scheduler("shift+p","{shift down}p{shift up}"), Return
+q:: mlsk_table_scheduler("shift+q","{shift down}q{shift up}"), Return
+r:: mlsk_table_scheduler("shift+r","{shift down}r{shift up}"), Return
+s:: mlsk_table_scheduler("shift+s","{shift down}s{shift up}"), Return
+t:: mlsk_table_scheduler("shift+t","{shift down}t{shift up}"), Return
+u:: mlsk_table_scheduler("shift+u","{shift down}u{shift up}"), Return
+v:: mlsk_table_scheduler("shift+v","{shift down}v{shift up}"), Return
+w:: mlsk_table_scheduler("shift+w","{shift down}w{shift up}"), Return
+x:: mlsk_table_scheduler("shift+x","{shift down}x{shift up}"), Return
+y:: mlsk_table_scheduler("shift+y","{shift down}y{shift up}"), Return
+z:: mlsk_table_scheduler("shift+z","{shift down}z{shift up}"), Return
+0:: mlsk_table_scheduler("shift+0","{shift down}0{shift up}"), Return
+1:: mlsk_table_scheduler("shift+1","{shift down}1{shift up}"), Return
+2:: mlsk_table_scheduler("shift+2","{shift down}2{shift up}"), Return
+3:: mlsk_table_scheduler("shift+3","{shift down}3{shift up}"), Return
+4:: mlsk_table_scheduler("shift+4","{shift down}4{shift up}"), Return
+5:: mlsk_table_scheduler("shift+5","{shift down}5{shift up}"), Return
+6:: mlsk_table_scheduler("shift+6","{shift down}6{shift up}"), Return
+7:: mlsk_table_scheduler("shift+7","{shift down}7{shift up}"), Return
+8:: mlsk_table_scheduler("shift+8","{shift down}8{shift up}"), Return
+9:: mlsk_table_scheduler("shift+9","{shift down}9{shift up}"), Return

;;Ctrl+Alt+%c%
^!a:: mlsk_table_scheduler("ctrl+alt+a","{ctrl down}{alt down}a{alt up}{ctrl up}"), Return
^!b:: mlsk_table_scheduler("ctrl+alt+b","{ctrl down}{alt down}b{alt up}{ctrl up}"), Return
^!c:: mlsk_table_scheduler("ctrl+alt+c","{ctrl down}{alt down}c{alt up}{ctrl up}"), Return
^!d:: mlsk_table_scheduler("ctrl+alt+d","{ctrl down}{alt down}d{alt up}{ctrl up}"), Return
^!e:: mlsk_table_scheduler("ctrl+alt+e","{ctrl down}{alt down}e{alt up}{ctrl up}"), Return
^!f:: mlsk_table_scheduler("ctrl+alt+f","{ctrl down}{alt down}f{alt up}{ctrl up}"), Return
^!g:: mlsk_table_scheduler("ctrl+alt+g","{ctrl down}{alt down}g{alt up}{ctrl up}"), Return
^!h:: mlsk_table_scheduler("ctrl+alt+h","{ctrl down}{alt down}h{alt up}{ctrl up}"), Return
^!i:: mlsk_table_scheduler("ctrl+alt+i","{ctrl down}{alt down}i{alt up}{ctrl up}"), Return
^!j:: mlsk_table_scheduler("ctrl+alt+j","{ctrl down}{alt down}j{alt up}{ctrl up}"), Return
^!k:: mlsk_table_scheduler("ctrl+alt+k","{ctrl down}{alt down}k{alt up}{ctrl up}"), Return
^!l:: mlsk_table_scheduler("ctrl+alt+l","{ctrl down}{alt down}l{alt up}{ctrl up}"), Return
^!m:: mlsk_table_scheduler("ctrl+alt+m","{ctrl down}{alt down}m{alt up}{ctrl up}"), Return
^!n:: mlsk_table_scheduler("ctrl+alt+n","{ctrl down}{alt down}n{alt up}{ctrl up}"), Return
^!o:: mlsk_table_scheduler("ctrl+alt+o","{ctrl down}{alt down}o{alt up}{ctrl up}"), Return
^!p:: mlsk_table_scheduler("ctrl+alt+p","{ctrl down}{alt down}p{alt up}{ctrl up}"), Return
^!q:: mlsk_table_scheduler("ctrl+alt+q","{ctrl down}{alt down}q{alt up}{ctrl up}"), Return
^!r:: mlsk_table_scheduler("ctrl+alt+r","{ctrl down}{alt down}r{alt up}{ctrl up}"), Return
^!s:: mlsk_table_scheduler("ctrl+alt+s","{ctrl down}{alt down}s{alt up}{ctrl up}"), Return
^!t:: mlsk_table_scheduler("ctrl+alt+t","{ctrl down}{alt down}t{alt up}{ctrl up}"), Return
^!u:: mlsk_table_scheduler("ctrl+alt+u","{ctrl down}{alt down}u{alt up}{ctrl up}"), Return
^!v:: mlsk_table_scheduler("ctrl+alt+v","{ctrl down}{alt down}v{alt up}{ctrl up}"), Return
^!w:: mlsk_table_scheduler("ctrl+alt+w","{ctrl down}{alt down}w{alt up}{ctrl up}"), Return
^!x:: mlsk_table_scheduler("ctrl+alt+x","{ctrl down}{alt down}x{alt up}{ctrl up}"), Return
^!y:: mlsk_table_scheduler("ctrl+alt+y","{ctrl down}{alt down}y{alt up}{ctrl up}"), Return
^!z:: mlsk_table_scheduler("ctrl+alt+z","{ctrl down}{alt down}z{alt up}{ctrl up}"), Return
^!0:: mlsk_table_scheduler("ctrl+alt+0","{ctrl down}{alt down}0{alt up}{ctrl up}"), Return
^!1:: mlsk_table_scheduler("ctrl+alt+1","{ctrl down}{alt down}1{alt up}{ctrl up}"), Return
^!2:: mlsk_table_scheduler("ctrl+alt+2","{ctrl down}{alt down}2{alt up}{ctrl up}"), Return
^!3:: mlsk_table_scheduler("ctrl+alt+3","{ctrl down}{alt down}3{alt up}{ctrl up}"), Return
^!4:: mlsk_table_scheduler("ctrl+alt+4","{ctrl down}{alt down}4{alt up}{ctrl up}"), Return
^!5:: mlsk_table_scheduler("ctrl+alt+5","{ctrl down}{alt down}5{alt up}{ctrl up}"), Return
^!6:: mlsk_table_scheduler("ctrl+alt+6","{ctrl down}{alt down}6{alt up}{ctrl up}"), Return
^!7:: mlsk_table_scheduler("ctrl+alt+7","{ctrl down}{alt down}7{alt up}{ctrl up}"), Return
^!8:: mlsk_table_scheduler("ctrl+alt+8","{ctrl down}{alt down}8{alt up}{ctrl up}"), Return
^!9:: mlsk_table_scheduler("ctrl+alt+9","{ctrl down}{alt down}9{alt up}{ctrl up}"), Return

;;Ctrl+Shift+%c%
^+a:: mlsk_table_scheduler("ctrl+shift+a","{ctrl down}{shift down}a{shift up}{ctrl up}"), Return
^+b:: mlsk_table_scheduler("ctrl+shift+b","{ctrl down}{shift down}b{shift up}{ctrl up}"), Return
^+c:: mlsk_table_scheduler("ctrl+shift+c","{ctrl down}{shift down}c{shift up}{ctrl up}"), Return
^+d:: mlsk_table_scheduler("ctrl+shift+d","{ctrl down}{shift down}d{shift up}{ctrl up}"), Return
^+e:: mlsk_table_scheduler("ctrl+shift+e","{ctrl down}{shift down}e{shift up}{ctrl up}"), Return
^+f:: mlsk_table_scheduler("ctrl+shift+f","{ctrl down}{shift down}f{shift up}{ctrl up}"), Return
^+g:: mlsk_table_scheduler("ctrl+shift+g","{ctrl down}{shift down}g{shift up}{ctrl up}"), Return
^+h:: mlsk_table_scheduler("ctrl+shift+h","{ctrl down}{shift down}h{shift up}{ctrl up}"), Return
^+i:: mlsk_table_scheduler("ctrl+shift+i","{ctrl down}{shift down}i{shift up}{ctrl up}"), Return
^+j:: mlsk_table_scheduler("ctrl+shift+j","{ctrl down}{shift down}j{shift up}{ctrl up}"), Return
^+k:: mlsk_table_scheduler("ctrl+shift+k","{ctrl down}{shift down}k{shift up}{ctrl up}"), Return
^+l:: mlsk_table_scheduler("ctrl+shift+l","{ctrl down}{shift down}l{shift up}{ctrl up}"), Return
^+m:: mlsk_table_scheduler("ctrl+shift+m","{ctrl down}{shift down}m{shift up}{ctrl up}"), Return
^+n:: mlsk_table_scheduler("ctrl+shift+n","{ctrl down}{shift down}n{shift up}{ctrl up}"), Return
^+o:: mlsk_table_scheduler("ctrl+shift+o","{ctrl down}{shift down}o{shift up}{ctrl up}"), Return
^+p:: mlsk_table_scheduler("ctrl+shift+p","{ctrl down}{shift down}p{shift up}{ctrl up}"), Return
^+q:: mlsk_table_scheduler("ctrl+shift+q","{ctrl down}{shift down}q{shift up}{ctrl up}"), Return
^+r:: mlsk_table_scheduler("ctrl+shift+r","{ctrl down}{shift down}r{shift up}{ctrl up}"), Return
^+s:: mlsk_table_scheduler("ctrl+shift+s","{ctrl down}{shift down}s{shift up}{ctrl up}"), Return
^+t:: mlsk_table_scheduler("ctrl+shift+t","{ctrl down}{shift down}t{shift up}{ctrl up}"), Return
^+u:: mlsk_table_scheduler("ctrl+shift+u","{ctrl down}{shift down}u{shift up}{ctrl up}"), Return
^+v:: mlsk_table_scheduler("ctrl+shift+v","{ctrl down}{shift down}v{shift up}{ctrl up}"), Return
^+w:: mlsk_table_scheduler("ctrl+shift+w","{ctrl down}{shift down}w{shift up}{ctrl up}"), Return
^+x:: mlsk_table_scheduler("ctrl+shift+x","{ctrl down}{shift down}x{shift up}{ctrl up}"), Return
^+y:: mlsk_table_scheduler("ctrl+shift+y","{ctrl down}{shift down}y{shift up}{ctrl up}"), Return
^+z:: mlsk_table_scheduler("ctrl+shift+z","{ctrl down}{shift down}z{shift up}{ctrl up}"), Return
^+0:: mlsk_table_scheduler("ctrl+shift+0","{ctrl down}{shift down}0{shift up}{ctrl up}"), Return
^+1:: mlsk_table_scheduler("ctrl+shift+1","{ctrl down}{shift down}1{shift up}{ctrl up}"), Return
^+2:: mlsk_table_scheduler("ctrl+shift+2","{ctrl down}{shift down}2{shift up}{ctrl up}"), Return
^+3:: mlsk_table_scheduler("ctrl+shift+3","{ctrl down}{shift down}3{shift up}{ctrl up}"), Return
^+4:: mlsk_table_scheduler("ctrl+shift+4","{ctrl down}{shift down}4{shift up}{ctrl up}"), Return
^+5:: mlsk_table_scheduler("ctrl+shift+5","{ctrl down}{shift down}5{shift up}{ctrl up}"), Return
^+6:: mlsk_table_scheduler("ctrl+shift+6","{ctrl down}{shift down}6{shift up}{ctrl up}"), Return
^+7:: mlsk_table_scheduler("ctrl+shift+7","{ctrl down}{shift down}7{shift up}{ctrl up}"), Return
^+8:: mlsk_table_scheduler("ctrl+shift+8","{ctrl down}{shift down}8{shift up}{ctrl up}"), Return
^+9:: mlsk_table_scheduler("ctrl+shift+9","{ctrl down}{shift down}9{shift up}{ctrl up}"), Return

;;Alt+Shift+%c%
!+a:: mlsk_table_scheduler("alt+shift+a","{alt down}{shift down}a{shift up}{alt up}"), Return
!+b:: mlsk_table_scheduler("alt+shift+b","{alt down}{shift down}b{shift up}{alt up}"), Return
!+c:: mlsk_table_scheduler("alt+shift+c","{alt down}{shift down}c{shift up}{alt up}"), Return
!+d:: mlsk_table_scheduler("alt+shift+d","{alt down}{shift down}d{shift up}{alt up}"), Return
!+e:: mlsk_table_scheduler("alt+shift+e","{alt down}{shift down}e{shift up}{alt up}"), Return
!+f:: mlsk_table_scheduler("alt+shift+f","{alt down}{shift down}f{shift up}{alt up}"), Return
!+g:: mlsk_table_scheduler("alt+shift+g","{alt down}{shift down}g{shift up}{alt up}"), Return
!+h:: mlsk_table_scheduler("alt+shift+h","{alt down}{shift down}h{shift up}{alt up}"), Return
!+i:: mlsk_table_scheduler("alt+shift+i","{alt down}{shift down}i{shift up}{alt up}"), Return
!+j:: mlsk_table_scheduler("alt+shift+j","{alt down}{shift down}j{shift up}{alt up}"), Return
!+k:: mlsk_table_scheduler("alt+shift+k","{alt down}{shift down}k{shift up}{alt up}"), Return
!+l:: mlsk_table_scheduler("alt+shift+l","{alt down}{shift down}l{shift up}{alt up}"), Return
!+m:: mlsk_table_scheduler("alt+shift+m","{alt down}{shift down}m{shift up}{alt up}"), Return
!+n:: mlsk_table_scheduler("alt+shift+n","{alt down}{shift down}n{shift up}{alt up}"), Return
!+o:: mlsk_table_scheduler("alt+shift+o","{alt down}{shift down}o{shift up}{alt up}"), Return
!+p:: mlsk_table_scheduler("alt+shift+p","{alt down}{shift down}p{shift up}{alt up}"), Return
!+q:: mlsk_table_scheduler("alt+shift+q","{alt down}{shift down}q{shift up}{alt up}"), Return
!+r:: mlsk_table_scheduler("alt+shift+r","{alt down}{shift down}r{shift up}{alt up}"), Return
!+s:: mlsk_table_scheduler("alt+shift+s","{alt down}{shift down}s{shift up}{alt up}"), Return
!+t:: mlsk_table_scheduler("alt+shift+t","{alt down}{shift down}t{shift up}{alt up}"), Return
!+u:: mlsk_table_scheduler("alt+shift+u","{alt down}{shift down}u{shift up}{alt up}"), Return
!+v:: mlsk_table_scheduler("alt+shift+v","{alt down}{shift down}v{shift up}{alt up}"), Return
!+w:: mlsk_table_scheduler("alt+shift+w","{alt down}{shift down}w{shift up}{alt up}"), Return
!+x:: mlsk_table_scheduler("alt+shift+x","{alt down}{shift down}x{shift up}{alt up}"), Return
!+y:: mlsk_table_scheduler("alt+shift+y","{alt down}{shift down}y{shift up}{alt up}"), Return
!+z:: mlsk_table_scheduler("alt+shift+z","{alt down}{shift down}z{shift up}{alt up}"), Return
!+0:: mlsk_table_scheduler("alt+shift+0","{alt down}{shift down}0{shift up}{alt up}"), Return
!+1:: mlsk_table_scheduler("alt+shift+1","{alt down}{shift down}1{shift up}{alt up}"), Return
!+2:: mlsk_table_scheduler("alt+shift+2","{alt down}{shift down}2{shift up}{alt up}"), Return
!+3:: mlsk_table_scheduler("alt+shift+3","{alt down}{shift down}3{shift up}{alt up}"), Return
!+4:: mlsk_table_scheduler("alt+shift+4","{alt down}{shift down}4{shift up}{alt up}"), Return
!+5:: mlsk_table_scheduler("alt+shift+5","{alt down}{shift down}5{shift up}{alt up}"), Return
!+6:: mlsk_table_scheduler("alt+shift+6","{alt down}{shift down}6{shift up}{alt up}"), Return
!+7:: mlsk_table_scheduler("alt+shift+7","{alt down}{shift down}7{shift up}{alt up}"), Return
!+8:: mlsk_table_scheduler("alt+shift+8","{alt down}{shift down}8{shift up}{alt up}"), Return
!+9:: mlsk_table_scheduler("alt+shift+9","{alt down}{shift down}9{shift up}{alt up}"), Return
