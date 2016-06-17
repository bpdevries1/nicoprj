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

;; [2016-06-17 11:25:33] ineens werkt het in N++ ook weer, dus dingen hieronder zouden dan weg kunnen.

F9::
send_ts()
return

^+F8::
send_ts()
return

^+F9::
send_ts()
return
