package require Itcl

source [file join $env(CRUISE_DIR) checkout lib perflib.tcl]
source [file join $env(CRUISE_DIR) checkout script lib CLogger.tcl]

source ../CLqnProcessor.tcl
source ../CLqnTask.tcl
source ../CLqnEntry.tcl
source ../CLqnCall.tcl
source ../CLqnProperty.tcl

###################
# Uitgangspunten:
# * Uitvoer is minimaal onderscheidend model: alleen Portal pagina's, calls naar GGHH services en raakvlaksystemen.
# * Dus niet Portlets als aparte laag.
# * In deze klasse vertaalslag van Excel model naar LQN model, dus onderliggende klassen zijn algemeen LQN

# class maar eenmalig definieren
if {[llength [itcl::find classes CLqnTemplate]] > 0} {
	return
}

itcl::class CLqnTemplate {

	private common log
	set log [CLogger::new_logger [file tail [info script]] debug]

	public proc new_instance {} {
		set result [uplevel {namespace which [CLqnTemplate #auto]}]
		return $result
	}

	private variable lst_properties ; # voor algemene properties
	private variable lst_processors
	
	# state variabelen
	private variable entry_browser
	private variable task_portal
	private variable proc_gghh
	private variable proc_mf
	
	private variable cur_entry_page ; # current page
	private variable cur_entry_gghh ; # current gghh call
	
	public constructor {} {
		set lst_properties {}
		set lst_processors {}
		
	}

	# specifieke methode voor maken model obv Excel
	public method init_excel {} {
		set proc_browser [CLqnProcessor::new_instance PBrowser N 10]
		lappend lst_processors $proc_browser
		set task_browser [CLqnTask::new_instance TBrowser NT_Browser "\${N}"]
		$task_browser set_ref_task Z 0
		$proc_browser add_task $task_browser
		set entry_browser [CLqnEntry::new_template_instance EBrowser D_Browser 0.00001]
		$task_browser add_entry $entry_browser
		
		set proc_portal [CLqnProcessor::new_instance PPortal N_Portal 12]
		lappend lst_processors $proc_portal
		set task_portal [CLqnTask::new_instance TPortal NT_Portal 120]
		$proc_portal add_task $task_portal
		# entries op portal zijn pagina's + acties
		
		set proc_gghh [CLqnProcessor::new_instance PGGHH N_GGHH 10]
		set proc_mf [CLqnProcessor::new_instance PMF N_MF 5]
		
		lappend lst_processors $proc_gghh $proc_mf
		# lappend lst_processors $proc_gghh
		# lappend lst_processors $proc_mf
	}
	
	public method set_page_action {page_name action_name} {
		if {$action_name == "selPage"} {
			set name $page_name
		} else {
			set name "${page_name}_[make_ident ${action_name}]"
		}
		# set cur_entry_page [CLqnEntry::new_template_instance "E${page_name}" "D_${page_name}" 0.1]
		set cur_entry_page [CLqnEntry::new_template_instance "E${name}" "D_${name}" 0.1]
		$task_portal add_entry $cur_entry_page
		# $entry_browser add_template_call $cur_entry_page "P_${page_name}" 0.1
		$entry_browser add_template_call $cur_entry_page "P_${name}" 0.1
	}
	
	# kijk naar 2e woord van method gghh (1e is raadpl) en maak taak hiervoor. Vervolgens entry maken binnen deze taak.
	public method add_gghh_call {method_gghh n_gghh} {
		if {$n_gghh > 0} {
			set gghh_task_name [det_gghh_task_name $method_gghh]
			set ctask_gghh [det_gghh_bo_task $proc_gghh $gghh_task_name] ; # nieuwe of bestaande
			set cur_entry_gghh [det_gghh_bo_entry $ctask_gghh $method_gghh] ; #  nieuwe of bestaande
			# $cur_entry_page add_template_call $cur_entry_gghh "" $n_gghh
			set call [det_gghh_bo_call $cur_entry_page $cur_entry_gghh]
			$call add_n_calls $n_gghh
		}
	}
	
	private method det_gghh_task_name {method_gghh} {
		set l [split $method_gghh "_"]
		if {[llength $l] > 1} {
			return [lindex $l 1]
		} else {
			return $method_gghh
		}	
	}
	
	private method det_gghh_bo_task {cproc gghh_task_name} {
		set task [$cproc get_task "T${gghh_task_name}"]
		if {$task == ""} {
			set task [CLqnTask::new_instance "T${gghh_task_name}" "NT_${gghh_task_name}" 100]
			$cproc add_task $task
		}
		return $task
	}
	
	private method det_gghh_bo_entry {ctask_gghh method_gghh} {
		set entry [$ctask_gghh get_entry "E${method_gghh}"]
		if {$entry == ""} {
			set entry [CLqnEntry::new_template_instance "E${method_gghh}" "D_${method_gghh}" 0.05]
			$ctask_gghh add_entry $entry
		}
		return $entry
	}
	
				
	private method det_gghh_bo_call {cur_entry_page entry_gghh} {
		set call [$cur_entry_page get_call $entry_gghh]
		if {$call == ""} {
		  # aantal calls eerst op 0, wordt hierna aangevuld
			set call [$cur_entry_page add_template_call $entry_gghh "" 0]
		}
		return $call
	}

	public method add_bo_call {bo bo_method n_bo} {
		if {$n_bo > 0} {
			set ctask_bo [det_gghh_bo_task $proc_mf $bo] ; # nieuwe of bestaande
			set method_name [det_bo_method_name $bo_method]
			set entry_bo [det_gghh_bo_entry $ctask_bo $method_name] ; #  nieuwe of bestaande
			set call [det_gghh_bo_call $cur_entry_gghh $entry_bo]
			$call add_n_calls $n_bo
		}
	}
	
	private method det_bo_method_name {bo_method} {
		if {[regexp {^Ophalen (.*)} $bo_method z name]} {
			return [make_ident $name]
		} else {
			return [make_ident $bo_method]
		}
	}
	
	public method write_model {a_template_filename a_props_filename} {
		write_template $a_template_filename
		write_props $a_props_filename
	}
	
	private method write_template {a_template_filename} {
		set f [open $a_template_filename w]
		write_header $f
		foreach cproc $lst_processors {
			set proc_filename "[file rootname $a_template_filename]-[$cproc get_name].xmlinc" 	
			set fproc [open $proc_filename w]
			$cproc write_file $fproc
			close $fproc
			# bij includen niet de dirnaam meegeven.
			write_include $f [file tail $proc_filename]
		}
		write_footer $f
		close $f
	}
	
	private method write_header {f} {
		puts $f "<?xml version=\"1.0\"?>
<lqn-model name=\"KLOP2\" description=\"Perf model KLOP2\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xsi:noNamespaceSchemaLocation=\"file:///C:/Program Files/LQN Solvers/lqn.xsd\">
   <solver-params comment=\"Complexiteits Reductie KLOP2\" conv_val=\"1e-005\" it_limit=\"500\" print_int=\"10\" underrelax_coeff=\"0.9\"/>
"
	}
	
	private method write_footer {f} {
		puts $f "</lqn-model>"
	}
	
	private method write_include {f include_filename} {
		puts $f "@\[INCLUDE ${include_filename}\]@"
	}
	
	private method write_props {a_props_filename} {
		set f [open $a_props_filename w]
		puts $f "# Generated properties file: $a_props_filename"
		puts $f "# Generated on [clock format [clock seconds] -format "%d-%m-%Y %T"]"

		# algemene properties
		foreach cprop $lst_properties {
			$cprop write_file $f
		}
		close $f
		
		# specifieke properties
		foreach cproc $lst_processors {
			set proc_filename "[file rootname $a_props_filename]-[$cproc get_name].lqnprop" 	
			set fproc [open $proc_filename w]

			# $cproc write_properties_file $f
			$cproc write_properties_file $fproc
			close $fproc
		}		
		
	}

	# identifiers puur gebruikt voor dot; intern in TCL script de labels als identifier.
	private method make_ident {label} {
		set res $label
		regsub -all {[- /?()#:.]} $res "_" res
		return $res
	}

	
}

