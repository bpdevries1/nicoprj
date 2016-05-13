# functionaliteit van lqns-control overnemen

package require Itcl

source [file join $env(CRUISE_DIR) checkout lib perflib.tcl]
# source [file join $env(CRUISE_DIR) checkout script lib CPlotter.tcl]
source [file join $env(CRUISE_DIR) checkout script lib CLogger.tcl]

source CLqnXmlFile.tcl
source CLqnTextFile.tcl
source CPlotDataFile.tcl
source CTemplateFile.tcl
source CLqnExecutor.tcl
source CLqngraph.tcl
source CLqnBreakdownCollection.tcl
source CLqnBreakdownGraph.tcl

# class maar eenmalig definieren
if {[llength [itcl::find classes CLqnsControl]] > 0} {
	return
}

itcl::class CLqnsControl {

	private common log
	# set log [CLogger::new_logger lqnsctrl debug]
	set log [CLogger::new_logger lqnsctrl info]

	private variable LQNS_EXE
	private variable LQSIM_EXE
	private variable LQN2EMF_EXE
	private variable EMF_FACTOR
	# private variable plotter
	# private variable COLUMN
	# private variable AXISLABEL

	# private variable bg_process_type ; # NO_BG, BG_CLIENT, BG_SERVER
	private variable method ; # LQNS, LQSIM, BOTH
	# private variable entry_name ; # name of entry to show X and R for.
	private variable lst_entry_names ; # names of entry to show X and R for.
	private variable processor_name ; # name of processor to show usage for.
	private variable processor_entry_name ; # name of processor entry to show usage for.
	private variable tijd_eenheid ; # sec of min of uur.

	private variable project_name
	private variable case_name

	# lqns-control (deze class) bepaalt de waarde van result_dirname
	# waarde dynamisch bepaald adhv projectname (en casename?)
	# private variable result_dirname

	# vlaggen, wat wel en niet doen?
	# private variable calc_asymp ; # calc/show asympotes?
	private variable exec_lqns
	private variable exec_lqsim

	private variable ctmpfile ; # aparte class om vanuit template-file een lqn file te maken.
	private variable clqn_executors
	private variable clqn_graph
	
	public constructor {} {
		global env

		set clqn_graph [CLqnGraph::new_lqn_graph $this]
		set ctmpfile [CTemplateFile::new_ctemplatefile]
		set clqn_executors {}

		set_method LQNS ; # LQNS, LQSIM
		set_tijd_eenheid "sec"
	}

	public method set_project_name {a_project_name} {
		set project_name $a_project_name
	}

	public method set_axis_label {name label} {
		$clqn_graph set_axis_label $name $label
	}

	# @param a_bg_process_type: NO_BG, BG_CLIENT, BG_SERVER
	if {0} {
		public method set_background_process_type {a_bg_process_type} {
			set bg_process_type $a_bg_process_type
		}
	}

	public method set_method {a_method} {
		set method $a_method
		if {($method == "LQNS") || ($method == "BOTH")} {
			set exec_lqns 1
		} else {
			set exec_lqns 0
		}
		if {($method == "LQSIM") || ($method == "BOTH")} {
			set exec_lqsim 1
		} else {
			set exec_lqsim 0
		}
		
		set clqn_executors {}
		if {$exec_lqns} {
			set cexec [CLqnExecutor::new_lqn_executor LQNS $this]
			$cexec set_ctmpfile $ctmpfile
			lappend clqn_executors $cexec			
		}
		if {$exec_lqsim} {
			set cexec [CLqnExecutor::new_lqn_executor LQSIM $this]
			$cexec set_ctmpfile $ctmpfile
			lappend clqn_executors $cexec			
		}
		
	}

	if {0} {
		public method set_entry_name {an_entry_name} {
			set entry_name $an_entry_name
		}
	
		public method get_entry_name {} {
			return $entry_name
		}
	}
	
	public method set_entry_names {a_lst_entry_names} {
		set lst_entry_names $a_lst_entry_names
	}

	public method get_entry_names {} {
		return $lst_entry_names
	}

	public method set_processor_name {a_processor_name {a_processor_entry_name NONE}} {
		set processor_name $a_processor_name
		set processor_entry_name $a_processor_entry_name
	}

	public method get_processor_name {} {
		return $processor_name
	}

	public method get_processor_entry_name {} {
		return $processor_entry_name
	}

	public method set_tijd_eenheid {a_tijd_eenheid} {
		set tijd_eenheid $a_tijd_eenheid
		$clqn_graph set_tijd_eenheid $a_tijd_eenheid
	}

	public method set_calc_asymp {a_calc_asymp} {
		$log warn deprecated
	}

	public method set_lqn_property {a_name a_value} {
		$ctmpfile set_property $a_name $a_value
	}

	public method get_lqn_property {a_name} {
		$ctmpfile get_property $a_name
	}
	
	public method set_template_filename {a_template_filename} {
		$ctmpfile set_template_filename $a_template_filename
	}

	# @deprecated, use add_lqn_properties_filename
	public method set_lqn_properties_filename {a_lqn_properties_filename} {
		# $ctmpfile read_properties $a_lqn_properties_filename
		add_lqn_properties_filename $a_lqn_properties_filename
	}

	# add the properties in filename.
	public method add_lqn_properties_filename {a_lqn_properties_filename} {
		$ctmpfile read_properties $a_lqn_properties_filename
	}
	
	public method get_result_dirname {} {
		return [file join $project_name "generated-$case_name"]
	}

	public method get_executors {} {
		return $clqn_executors
	}

	# public entry method
	# @param case_name: bv Z0 of N1000-Zvar
	public method analyse {var_name lst_var_values a_case_name} {
		$log debug "start"
		set case_name $a_case_name
		prepare_result_dir

		set basename $project_name
		set name "$basename-$case_name"

		# set fo_calctimes [open [file join [get_result_dirname] "$name-calctimes.tsv"] w]
		set fo_calctimes [open [file join [get_result_dirname] "calctimes.tsv"] w]
		puts $fo_calctimes "# method\t$var_name\tCalctime (s)\tConv.Value\tIterations"

		set breakdown_graph [CLqnBreakdownGraph::new_instance [get_result_dirname]]
		foreach cexec $clqn_executors {
			$cexec set_fo_calctimes $fo_calctimes
			set breakdown_collection [CLqnBreakdownCollection::new_instance]
			$cexec set_breakdown_collection $breakdown_collection
			# $cexec execute $var_name $lst_var_values $case_name $name
			$cexec execute $var_name $lst_var_values $case_name
			$breakdown_graph make_graphs $breakdown_collection [$cexec get_exec_method]
		}
		
		close $fo_calctimes
		
		$clqn_graph make_graphs $project_name [get_result_dirname] $name $var_name

		$log debug "finished"
	}

	private method prepare_result_dir {} {
		# file delete -force $result_dirname
		# directory zelf niet verwijderen, is vaak current dir in explorer etc.
		# 15-6-07: dirs niet verwijderen, per lqnscontrol.analyse doen.
		set result_dirname [get_result_dirname]
		$log debug "$result_dirname: deleting contents..."
		set filelist [glob -nocomplain -directory $result_dirname *]
		foreach filename $filelist {
			file delete -force $filename
		}
		file mkdir $result_dirname
	}

}

