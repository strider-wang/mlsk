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
	if(1)
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
			sub_table.act_sub_idx := -1
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

mlsk_table_scheduler(keys)
{
	Global mlsk_ctrl_table
	
	if(mlsk_table_call(mlsk_ctrl_table, keys) == 0)
	{
		mlsk_util_log("key not found in control table")
		
		act_exec_table := mlsk_ctrl_table.act_exec_table
		mlsk_table_call(act_exec_table, keys)
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
^a:: mlsk_table_scheduler("ctrl+a"), Return
^b:: mlsk_table_scheduler("ctrl+b"), Return
^c:: mlsk_table_scheduler("ctrl+c"), Return
^d:: mlsk_table_scheduler("ctrl+d"), Return
^e:: mlsk_table_scheduler("ctrl+e"), Return
^f:: mlsk_table_scheduler("ctrl+f"), Return
^g:: mlsk_table_scheduler("ctrl+g"), Return
^h:: mlsk_table_scheduler("ctrl+h"), Return
^i:: mlsk_table_scheduler("ctrl+i"), Return
^j:: mlsk_table_scheduler("ctrl+j"), Return
^k:: mlsk_table_scheduler("ctrl+k"), Return
^l:: mlsk_table_scheduler("ctrl+l"), Return
^m:: mlsk_table_scheduler("ctrl+m"), Return
^n:: mlsk_table_scheduler("ctrl+n"), Return
^o:: mlsk_table_scheduler("ctrl+o"), Return
^p:: mlsk_table_scheduler("ctrl+p"), Return
^q:: mlsk_table_scheduler("ctrl+q"), Return
^r:: mlsk_table_scheduler("ctrl+r"), Return
^s:: mlsk_table_scheduler("ctrl+s"), Return
^t:: mlsk_table_scheduler("ctrl+t"), Return
^u:: mlsk_table_scheduler("ctrl+u"), Return
^v:: mlsk_table_scheduler("ctrl+v"), Return
^w:: mlsk_table_scheduler("ctrl+w"), Return
^x:: mlsk_table_scheduler("ctrl+x"), Return
^y:: mlsk_table_scheduler("ctrl+y"), Return
^z:: mlsk_table_scheduler("ctrl+z"), Return
^0:: mlsk_table_scheduler("ctrl+0"), Return
^1:: mlsk_table_scheduler("ctrl+1"), Return
^2:: mlsk_table_scheduler("ctrl+2"), Return
^3:: mlsk_table_scheduler("ctrl+3"), Return
^4:: mlsk_table_scheduler("ctrl+4"), Return
^5:: mlsk_table_scheduler("ctrl+5"), Return
^6:: mlsk_table_scheduler("ctrl+6"), Return
^7:: mlsk_table_scheduler("ctrl+7"), Return
^8:: mlsk_table_scheduler("ctrl+8"), Return
^9:: mlsk_table_scheduler("ctrl+9"), Return

;;Alt+%c%
!a:: mlsk_table_scheduler("alt+a"), Return
!b:: mlsk_table_scheduler("alt+b"), Return
!c:: mlsk_table_scheduler("alt+c"), Return
!d:: mlsk_table_scheduler("alt+d"), Return
!e:: mlsk_table_scheduler("alt+e"), Return
!f:: mlsk_table_scheduler("alt+f"), Return
!g:: mlsk_table_scheduler("alt+g"), Return
!h:: mlsk_table_scheduler("alt+h"), Return
!i:: mlsk_table_scheduler("alt+i"), Return
!j:: mlsk_table_scheduler("alt+j"), Return
!k:: mlsk_table_scheduler("alt+k"), Return
!l:: mlsk_table_scheduler("alt+l"), Return
!m:: mlsk_table_scheduler("alt+m"), Return
!n:: mlsk_table_scheduler("alt+n"), Return
!o:: mlsk_table_scheduler("alt+o"), Return
!p:: mlsk_table_scheduler("alt+p"), Return
!q:: mlsk_table_scheduler("alt+q"), Return
!r:: mlsk_table_scheduler("alt+r"), Return
!s:: mlsk_table_scheduler("alt+s"), Return
!t:: mlsk_table_scheduler("alt+t"), Return
!u:: mlsk_table_scheduler("alt+u"), Return
!v:: mlsk_table_scheduler("alt+v"), Return
!w:: mlsk_table_scheduler("alt+w"), Return
!x:: mlsk_table_scheduler("alt+x"), Return
!y:: mlsk_table_scheduler("alt+y"), Return
!z:: mlsk_table_scheduler("alt+z"), Return
!0:: mlsk_table_scheduler("alt+0"), Return
!1:: mlsk_table_scheduler("alt+1"), Return
!2:: mlsk_table_scheduler("alt+2"), Return
!3:: mlsk_table_scheduler("alt+3"), Return
!4:: mlsk_table_scheduler("alt+4"), Return
!5:: mlsk_table_scheduler("alt+5"), Return
!6:: mlsk_table_scheduler("alt+6"), Return
!7:: mlsk_table_scheduler("alt+7"), Return
!8:: mlsk_table_scheduler("alt+8"), Return
!9:: mlsk_table_scheduler("alt+9"), Return

;;Shift+%c
+a:: mlsk_table_scheduler("shift+a"), Return
+b:: mlsk_table_scheduler("shift+b"), Return
+c:: mlsk_table_scheduler("shift+c"), Return
+d:: mlsk_table_scheduler("shift+d"), Return
+e:: mlsk_table_scheduler("shift+e"), Return
+f:: mlsk_table_scheduler("shift+f"), Return
+g:: mlsk_table_scheduler("shift+g"), Return
+h:: mlsk_table_scheduler("shift+h"), Return
+i:: mlsk_table_scheduler("shift+i"), Return
+j:: mlsk_table_scheduler("shift+j"), Return
+k:: mlsk_table_scheduler("shift+k"), Return
+l:: mlsk_table_scheduler("shift+l"), Return
+m:: mlsk_table_scheduler("shift+m"), Return
+n:: mlsk_table_scheduler("shift+n"), Return
+o:: mlsk_table_scheduler("shift+o"), Return
+p:: mlsk_table_scheduler("shift+p"), Return
+q:: mlsk_table_scheduler("shift+q"), Return
+r:: mlsk_table_scheduler("shift+r"), Return
+s:: mlsk_table_scheduler("shift+s"), Return
+t:: mlsk_table_scheduler("shift+t"), Return
+u:: mlsk_table_scheduler("shift+u"), Return
+v:: mlsk_table_scheduler("shift+v"), Return
+w:: mlsk_table_scheduler("shift+w"), Return
+x:: mlsk_table_scheduler("shift+x"), Return
+y:: mlsk_table_scheduler("shift+y"), Return
+z:: mlsk_table_scheduler("shift+z"), Return
+0:: mlsk_table_scheduler("shift+0"), Return
+1:: mlsk_table_scheduler("shift+1"), Return
+2:: mlsk_table_scheduler("shift+2"), Return
+3:: mlsk_table_scheduler("shift+3"), Return
+4:: mlsk_table_scheduler("shift+4"), Return
+5:: mlsk_table_scheduler("shift+5"), Return
+6:: mlsk_table_scheduler("shift+6"), Return
+7:: mlsk_table_scheduler("shift+7"), Return
+8:: mlsk_table_scheduler("shift+8"), Return
+9:: mlsk_table_scheduler("shift+9"), Return

;;Ctrl+Alt+%c%
^!a:: mlsk_table_scheduler("ctrl+alt+a"), Return
^!b:: mlsk_table_scheduler("ctrl+alt+b"), Return
^!c:: mlsk_table_scheduler("ctrl+alt+c"), Return
^!d:: mlsk_table_scheduler("ctrl+alt+d"), Return
^!e:: mlsk_table_scheduler("ctrl+alt+e"), Return
^!f:: mlsk_table_scheduler("ctrl+alt+f"), Return
^!g:: mlsk_table_scheduler("ctrl+alt+g"), Return
^!h:: mlsk_table_scheduler("ctrl+alt+h"), Return
^!i:: mlsk_table_scheduler("ctrl+alt+i"), Return
^!j:: mlsk_table_scheduler("ctrl+alt+j"), Return
^!k:: mlsk_table_scheduler("ctrl+alt+k"), Return
^!l:: mlsk_table_scheduler("ctrl+alt+l"), Return
^!m:: mlsk_table_scheduler("ctrl+alt+m"), Return
^!n:: mlsk_table_scheduler("ctrl+alt+n"), Return
^!o:: mlsk_table_scheduler("ctrl+alt+o"), Return
^!p:: mlsk_table_scheduler("ctrl+alt+p"), Return
^!q:: mlsk_table_scheduler("ctrl+alt+q"), Return
^!r:: mlsk_table_scheduler("ctrl+alt+r"), Return
^!s:: mlsk_table_scheduler("ctrl+alt+s"), Return
^!t:: mlsk_table_scheduler("ctrl+alt+t"), Return
^!u:: mlsk_table_scheduler("ctrl+alt+u"), Return
^!v:: mlsk_table_scheduler("ctrl+alt+v"), Return
^!w:: mlsk_table_scheduler("ctrl+alt+w"), Return
^!x:: mlsk_table_scheduler("ctrl+alt+x"), Return
^!y:: mlsk_table_scheduler("ctrl+alt+y"), Return
^!z:: mlsk_table_scheduler("ctrl+alt+z"), Return
^!0:: mlsk_table_scheduler("ctrl+alt+0"), Return
^!1:: mlsk_table_scheduler("ctrl+alt+1"), Return
^!2:: mlsk_table_scheduler("ctrl+alt+2"), Return
^!3:: mlsk_table_scheduler("ctrl+alt+3"), Return
^!4:: mlsk_table_scheduler("ctrl+alt+4"), Return
^!5:: mlsk_table_scheduler("ctrl+alt+5"), Return
^!6:: mlsk_table_scheduler("ctrl+alt+6"), Return
^!7:: mlsk_table_scheduler("ctrl+alt+7"), Return
^!8:: mlsk_table_scheduler("ctrl+alt+8"), Return
^!9:: mlsk_table_scheduler("ctrl+alt+9"), Return

;;Ctrl+Shift+%c%
^+a:: mlsk_table_scheduler("ctrl+shift+a"), Return
^+b:: mlsk_table_scheduler("ctrl+shift+b"), Return
^+c:: mlsk_table_scheduler("ctrl+shift+c"), Return
^+d:: mlsk_table_scheduler("ctrl+shift+d"), Return
^+e:: mlsk_table_scheduler("ctrl+shift+e"), Return
^+f:: mlsk_table_scheduler("ctrl+shift+f"), Return
^+g:: mlsk_table_scheduler("ctrl+shift+g"), Return
^+h:: mlsk_table_scheduler("ctrl+shift+h"), Return
^+i:: mlsk_table_scheduler("ctrl+shift+i"), Return
^+j:: mlsk_table_scheduler("ctrl+shift+j"), Return
^+k:: mlsk_table_scheduler("ctrl+shift+k"), Return
^+l:: mlsk_table_scheduler("ctrl+shift+l"), Return
^+m:: mlsk_table_scheduler("ctrl+shift+m"), Return
^+n:: mlsk_table_scheduler("ctrl+shift+n"), Return
^+o:: mlsk_table_scheduler("ctrl+shift+o"), Return
^+p:: mlsk_table_scheduler("ctrl+shift+p"), Return
^+q:: mlsk_table_scheduler("ctrl+shift+q"), Return
^+r:: mlsk_table_scheduler("ctrl+shift+r"), Return
^+s:: mlsk_table_scheduler("ctrl+shift+s"), Return
^+t:: mlsk_table_scheduler("ctrl+shift+t"), Return
^+u:: mlsk_table_scheduler("ctrl+shift+u"), Return
^+v:: mlsk_table_scheduler("ctrl+shift+v"), Return
^+w:: mlsk_table_scheduler("ctrl+shift+w"), Return
^+x:: mlsk_table_scheduler("ctrl+shift+x"), Return
^+y:: mlsk_table_scheduler("ctrl+shift+y"), Return
^+z:: mlsk_table_scheduler("ctrl+shift+z"), Return
^+0:: mlsk_table_scheduler("ctrl+shift+0"), Return
^+1:: mlsk_table_scheduler("ctrl+shift+1"), Return
^+2:: mlsk_table_scheduler("ctrl+shift+2"), Return
^+3:: mlsk_table_scheduler("ctrl+shift+3"), Return
^+4:: mlsk_table_scheduler("ctrl+shift+4"), Return
^+5:: mlsk_table_scheduler("ctrl+shift+5"), Return
^+6:: mlsk_table_scheduler("ctrl+shift+6"), Return
^+7:: mlsk_table_scheduler("ctrl+shift+7"), Return
^+8:: mlsk_table_scheduler("ctrl+shift+8"), Return
^+9:: mlsk_table_scheduler("ctrl+shift+9"), Return

;;Alt+Shift+%c%
!+a:: mlsk_table_scheduler("alt+shift+a"), Return
!+b:: mlsk_table_scheduler("alt+shift+b"), Return
!+c:: mlsk_table_scheduler("alt+shift+c"), Return
!+d:: mlsk_table_scheduler("alt+shift+d"), Return
!+e:: mlsk_table_scheduler("alt+shift+e"), Return
!+f:: mlsk_table_scheduler("alt+shift+f"), Return
!+g:: mlsk_table_scheduler("alt+shift+g"), Return
!+h:: mlsk_table_scheduler("alt+shift+h"), Return
!+i:: mlsk_table_scheduler("alt+shift+i"), Return
!+j:: mlsk_table_scheduler("alt+shift+j"), Return
!+k:: mlsk_table_scheduler("alt+shift+k"), Return
!+l:: mlsk_table_scheduler("alt+shift+l"), Return
!+m:: mlsk_table_scheduler("alt+shift+m"), Return
!+n:: mlsk_table_scheduler("alt+shift+n"), Return
!+o:: mlsk_table_scheduler("alt+shift+o"), Return
!+p:: mlsk_table_scheduler("alt+shift+p"), Return
!+q:: mlsk_table_scheduler("alt+shift+q"), Return
!+r:: mlsk_table_scheduler("alt+shift+r"), Return
!+s:: mlsk_table_scheduler("alt+shift+s"), Return
!+t:: mlsk_table_scheduler("alt+shift+t"), Return
!+u:: mlsk_table_scheduler("alt+shift+u"), Return
!+v:: mlsk_table_scheduler("alt+shift+v"), Return
!+w:: mlsk_table_scheduler("alt+shift+w"), Return
!+x:: mlsk_table_scheduler("alt+shift+x"), Return
!+y:: mlsk_table_scheduler("alt+shift+y"), Return
!+z:: mlsk_table_scheduler("alt+shift+z"), Return
!+0:: mlsk_table_scheduler("alt+shift+0"), Return
!+1:: mlsk_table_scheduler("alt+shift+1"), Return
!+2:: mlsk_table_scheduler("alt+shift+2"), Return
!+3:: mlsk_table_scheduler("alt+shift+3"), Return
!+4:: mlsk_table_scheduler("alt+shift+4"), Return
!+5:: mlsk_table_scheduler("alt+shift+5"), Return
!+6:: mlsk_table_scheduler("alt+shift+6"), Return
!+7:: mlsk_table_scheduler("alt+shift+7"), Return
!+8:: mlsk_table_scheduler("alt+shift+8"), Return
!+9:: mlsk_table_scheduler("alt+shift+9"), Return

