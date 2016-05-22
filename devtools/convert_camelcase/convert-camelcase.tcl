# convert-camelcase.tcl

package require fileutil

source [file join $env(CRUISE_DIR) checkout lib perflib.tcl]

addLogger ccc
setLogLevel ccc info
# setLogLevel ccc debug

proc main {argc argv} {
	check_params $argc $argv
	
	set filename [lindex $argv 0]
	
	file rename $filename ${filename}.bak
	
	convert_file $filename.bak $filename 

	# evt een diff exec-en.
	catch {exec diff $filename.bak $filename}
}

proc check_params {argc $argv} {
	global argv0
	if {$argc != 1} {
		fail "syntax: tclsh $argv0 <sourcefile.tcl>"
	}
}

proc convert_file {source_name target_name} {
	set fo [open $target_name w]
	
	::fileutil::foreachLine line $source_name {
		puts $fo [convert_line $line]
	}
	
	close $fo
}

# recursive
proc convert_line {line} {
	log "converting line: $line" debug ccc
	if {[regexp {^(.*?)\y([a-z][a-zA-Z0-9]+)\y(.*)$} $line z pre word post]} {
		set result "[convert_line $pre][convert_word $word][convert_line $post]"	
	} else {
		set result $line
	}
	log "converted line: $line => $result" debug ccc
	return $result
}

# @param word: word, starting with a letter a-z (no capital)
proc convert_word {word} {
	log "converting word: $word" debug ccc
	regsub -all {([A-Z])} $word {_[string tolower \1]} word2
	catch {set word2 [subst $word2]}
	log "converted word: $word => $word2" debug ccc
	return $word2
}

# aanroepen vanuit Ant, maar ook mogelijk om vanuit Tcl te doen.
if {[file tail $argv0] == [file tail [info script]]} {
  main $argc $argv
}
