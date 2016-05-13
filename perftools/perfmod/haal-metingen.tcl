package require Itcl

source [file join $env(CRUISE_DIR) checkout lib perflib.tcl]
source [file join $env(CRUISE_DIR) checkout script database CDatabase.tcl]
source CDefMetingenSpec.tcl

addLogger haalmetingen
setLogLevel haalmetingen debug
# setLogLevel haalmetingen info

# set TESTBUILD build.278

proc main {argc argv} {
	global sleeptime_prev f dirname

	check_params $argc $argv
	set dirname [lindex $argv 0]

	set has_class 0
	catch {
		source [file join $dirname CMetingenSpec.tcl]
		set has_class 1
	} msg
	log "msg: $msg" debug haalmetingen
	if {$has_class} {
		set metingen_spec [CMetingenSpec #auto $dirname]
	} else {
		# voor showcase nog de oude manier.
		set metingen_spec [CDefMetingenSpec #auto $dirname]
	}

	set f -1
	set sleeptime_prev -1

	set cdb [::CDatabase::get_database]
	set conn [$cdb get_connection]

	set query [$metingen_spec get_query]
	set qres [::mysql::query $conn $query]
 	::mysql::map $qres {nthreads rate avgresptime sleeptime usage} {	
		handle_record $nthreads $rate $avgresptime $sleeptime $usage
	}
	::mysql::endquery $qres

	if {$f != -1} {
		close $f
	}
	
}

proc check_params {argc argv} {
  global env argv0
  if {$argc != 1} {
    # fail "syntax: $argv0 <template_filename> <result_dirname>; got $argv \[#$argc\]"
    fail "syntax: $argv0 <dirname>; got $argv \[#$argc\]"
  }
}

proc handle_record {nthreads rate avgresptime sleeptime usage} {
	global sleeptime_prev f dirname
	
	log "start" debug haalmetingen
	if {$sleeptime != $sleeptime_prev} {
		if {$f != -1} {
			close $f
		}
		set sleeptime_prev $sleeptime
		file mkdir [file join $dirname "generated-metingen"]
		# oud: Metingen-Cluster-Z0.0.tsv
		# volgens lqn_control: Metingen-Cluster-Z-0sec.0.tsv

		# set f [open [file join $dirname "generated-metingen" "Metingen-$dirname-Z-[format %1.0f ${sleeptime}]sec.tsv"] w]
		set f [open [file join $dirname "generated-metingen" "Metingen-$dirname-Z[format %1.0f ${sleeptime}]sec.tsv"] w]

		puts $f "# N X R U"
	}
	puts $f "$nthreads\t$rate\t$avgresptime\t$usage"
}

main $argc $argv



