SetTitleMatchMode, 2
SetKeyDelay, -1

send_ts() {
	FormatTime, time, %A_Now%, yyyy-MM-dd HH:mm:ss  
	ts := "[" time "] "
	Send, %ts%
}

; send_ts()

F8::
send_ts()
return

;; [2016-06-17 11:25:33] ineens werkt het in N++ ook weer, dus dingen hieronder zouden dan weg kunnen.
;; [2016-08-16 10:40:02] F9 in Word gebruikt voor herberekenen velden, zoals inhoudsopgave, dus hier nu weg.
;;F9::
;;send_ts()
;;return

;;^+F8::
;;send_ts()
;;return

;;^+F9::
;;send_ts()
;;return

;; [2016-08-08 09:29:33] In outlook - Alt-Shift-m - move to folder sub menu.
!+m::
Send, {AppsKey}m
return
