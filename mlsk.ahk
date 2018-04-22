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
^!e::
{
	mlsk_exec_call_everything()
	WinMaximize
	
	Return
}

^!t::
{
	mlsk_util_function_call("mlsk_util_dummy")
	MsgBox "Ctrl+alt+t"
	Return
}

^!g::
{
	mlsk_table_scheduler("ctrl+alt+g")
	Return
}

^!w::
{
	mlsk_table_scheduler("ctrl+alt+w")
	Return
}
