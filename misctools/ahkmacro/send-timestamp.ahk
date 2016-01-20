SetTitleMatchMode, 2
SetKeyDelay, -1

; WinActivate, Notepad++
; WinActivate, Word

; ts := "test42"

send_ts() {
	FormatTime, time, %A_Now%, yyyy-MM-dd HH:mm:ss  
	ts := "[" time "] "
	Send, %ts%
}

; send_ts()

F8::
;; Run Notepad
send_ts()
return

