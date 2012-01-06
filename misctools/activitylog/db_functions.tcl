proc is_new_time_group {title} {
	set result 0
	# {NONE} is screensaver, report in group
	# if {$title == "{NONE}"} {set result 1}
	if {$title == "{NO INFO}"} {set result 1}
	if {$title == "{STARTED}"} {set result 1}
	return $result	
}

proc det_group {title} {
	global lst_group_regexps
	if {[regexp {Tools} $title]} {
		log debug "Determining group of: $title"
	}
	set result "Unknown"
	foreach el $lst_group_regexps {
		# nu niet foreach, dan werkt break niet goed
		lassign $el re group
		if {[regexp -nocase $re $title]} {
			set result $group
			break
		}
	}
	return $result
}

