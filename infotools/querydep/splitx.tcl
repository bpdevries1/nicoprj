    proc splitx {str {regexp {[\t \r\n]+}}} {
        # Bugfix 476988
        if {[string length $str] == 0} {
            return {}
        }
        if {[string length $regexp] == 0} {
            return [::split $str ""]
        }
        set list  {}
        set start 0
        while {[regexp -start $start -indices -- $regexp $str match submatch]} {
            foreach {subStart subEnd} $submatch break
            foreach {matchStart matchEnd} $match break
            incr matchStart -1
            incr matchEnd
            lappend list [string range $str $start $matchStart]
            if {$subStart >= $start} {
                lappend list [string range $str $subStart $subEnd]
            }
            set start $matchEnd
        }
        lappend list [string range $str $start end]
        return $list
    }
 
