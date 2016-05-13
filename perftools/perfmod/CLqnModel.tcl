package require Itcl

source [file join $env(CRUISE_DIR) checkout lib perflib.tcl]
source [file join $env(CRUISE_DIR) checkout script lib CLogger.tcl]

# class maar eenmalig definieren
if {[llength [itcl::find classes CLqnModel]] > 0} {
	return
}

source CLqnEntry.tcl
source CLqnCall.tcl
source CLqnBreakdown.tcl

itcl::class CLqnModel {

	private common log
	# set log [CLogger::new_logger [file tail [info script]] debug]
	set log [CLogger::new_logger [file tail [info script]] info]

	public proc new_instance {} {
		set result [uplevel {namespace which [CLqnModel #auto]}]
		$result init
		return $result
	}

	private variable lst_entries
	private variable ar_entries ; # key: entry-name

	public method init {} {
		set lst_entries {}
		array unset ar_entries
	}
	
	public method det_entry {an_entry_name} {
		set entry ""
		catch {set entry $ar_entries($an_entry_name)}
		if {$entry == ""} {
			set entry [CLqnEntry::new_instance $an_entry_name]
			lappend lst_entries $entry
			set ar_entries($an_entry_name) $entry
		}
		return $entry
	}

	public method det_breakdown {an_entry_name} {
		set breakdown [CLqnBreakdown::new_instance $this $an_entry_name]
		$breakdown calc
		return $breakdown
	}

	public method log_debug {} {
		$log debug "Lqn Model:"
		foreach entry $lst_entries {
			$log debug "[$entry to_string]\n"
		}
	}

}
	