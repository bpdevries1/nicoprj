package require Itcl
package require xml

source [file join $env(CRUISE_DIR) checkout lib perflib.tcl]
source [file join $env(CRUISE_DIR) checkout script lib CLogger.tcl]
source [file join $env(CRUISE_DIR) checkout script lib CPlotter.tcl]

# class maar eenmalig definieren
if {[llength [itcl::find classes CLqnGraph]] > 0} {
	return
}

itcl::class CLqnGraph {

	private common log
	set log [CLogger::new_logger lqngraph info]

	public proc new_lqn_graph {a_lqns_control} {
		set result [uplevel {namespace which [CLqnGraph #auto]}]
		$result set_lqns_control $a_lqns_control
		return $result
	}

	private variable plotter
	private variable AXISLABEL

	private variable lqns_control

	private constructor {} {
		set plotter [CPlotter #auto abc] ; # reslogs_dir (abc) wordt niet gebruikt.
		set tijd_eenheid "sec"
		set_axis_label N "N (#threads)"
		set_axis_label X "X (#reqs/$tijd_eenheid)"
		set_axis_label R "R ($tijd_eenheid)"
		set_axis_label U "U (perc / 100)"
		set_axis_label Z "Z ($tijd_eenheid)"
	}

	public method set_lqns_control {a_lqns_control} {
		set lqns_control $a_lqns_control
	}
	
	public method set_tijd_eenheid {a_tijd_eenheid} {
		set tijd_eenheid $a_tijd_eenheid

		set_axis_label X "X (#reqs/$tijd_eenheid)"
		set_axis_label R "R ($tijd_eenheid)"
		set_axis_label Z "Z ($tijd_eenheid)"
	}
	
	public method set_axis_label {name label} {
		set AXISLABEL($name) $label
	}
	
	# @param name: bv Z0 of N1000-Zvar
	public method make_graphs {basedir result_dirname name Xaxis} {
		make_graph $basedir $result_dirname $name $Xaxis X R 
		make_graph $basedir $result_dirname $name $Xaxis X R calc
		# make_graph $basedir $result_dirname $name $Xaxis X U 
		# make_graph $basedir $result_dirname $name $Xaxis X U calc
		make_graph $basedir $result_dirname $name $Xaxis U "" 
		make_graph $basedir $result_dirname $name $Xaxis U "" calc
	}

	# @todo X-as is niet altijd N, kan ook Z zijn (bij Z variabel)
	# @param calc: als leeg, dan ook metingen. Als calc, dan alleen calc.
	# @param Y2axis kan leeg zijn.
	# @param basedir: alleen nodig voor metingen
	private method make_graph {basedir result_dirname name Xaxis Yaxis Y2axis {calc ""}} {
		$log debug start
		# set metingen_filename [file normalize [file join $basedir "generated-metingen" "Metingen-$name.0.tsv"]]
		set metingen_filename [det_metingen_filename $basedir $name]
		$log info "metingen_filename: $metingen_filename"
		if {$calc != "calc"} {
			if {![file exists $metingen_filename]} {
				$log debug "metingen_filename: $metingen_filename doesn't exist, returning."
				return
			}
		}
		
		make_graph_general $result_dirname $name $Xaxis $Yaxis $Y2axis $calc

		set clqn_executors [$lqns_control get_executors]
		if {($Yaxis == "X") && ($Y2axis == "R")} {
			foreach entry_name [$lqns_control get_entry_names] {
				foreach cexec $clqn_executors {
					make_graph_lqn $result_dirname $name $Xaxis "$entry_name.$Yaxis" "$entry_name.$Y2axis" $cexec
				}
			}
		} else {
			foreach cexec $clqn_executors {
				make_graph_lqn $result_dirname $name $Xaxis $Yaxis $Y2axis $cexec
			}
		}
		# make_graph_metingen $basedir $result_dirname $name $Xaxis $Yaxis $Y2axis $calc
		if {($Yaxis == "X") && ($Y2axis == "R")} {
			foreach entry_name [$lqns_control get_entry_names] {
				make_graph_metingen $basedir $result_dirname $name $Xaxis "$entry_name.$Yaxis" "$entry_name.$Y2axis" $calc
			}
		} else {
			make_graph_metingen $basedir $result_dirname $name $Xaxis $Yaxis $Y2axis $calc
		}
		$plotter plotfile
		$log debug finished
	}
	
	private method det_metingen_filename {basedir name} {
		return [file normalize [file join $basedir "generated-metingen" "Metingen-$name.tsv"]]
	}
	
	private method make_graph_general {result_dirname name Xaxis Yaxis Y2axis calc} {
		$plotter reset

		# $plotter set_graphfile [file normalize [file join $result_dirname "$name-${Yaxis}${Y2axis}${calc}.png"]]
		$plotter set_graphfile [file normalize [file join $result_dirname "${Yaxis}${Y2axis}${calc}.png"]]
		# $plotter set_option title "\"$name $Xaxis $Yaxis $Y2axis $calc\""
		# name: BSB-close-fct_np
		$plotter set_option title "\"$name\""

		$plotter set_y_axis [det_axis_label $Yaxis]
		if {$Y2axis == ""} {
			$plotter set_option grid ytics
		} else {
			$plotter set_y2_axis [det_axis_label $Y2axis]
			$plotter set_option grid y2tics
		}
	}
	
	private method det_axis_label {name} {
		set result $name
		catch {set result $AXISLABEL($name)}
		if {[regexp {^(.+)\.(.+)$} $name z entry_name value_name]} {
			set result "$entry_name.$AXISLABEL($value_name)"
		}
		return $result
	}
	
	private method make_graph_lqn {result_dirname name Xaxis Yaxis Y2axis cexec} {
	
		set cpdf [$cexec get_cpdf]
		$plotter set_datafile [$cpdf get_filename]
		$plotter set_x_axis [det_axis_label $Xaxis] [$cpdf get_column $Xaxis]

		$plotter add_line "${Yaxis}-[$cexec get_exec_method]" [$cpdf get_column $Yaxis] y1 "" yerrorlines [$cpdf get_column error_value]
		if {$Y2axis != ""} {
			$plotter add_line "${Y2axis}-[$cexec get_exec_method]" [$cpdf get_column $Y2axis] y2
		}
	}
		

	private method make_graph_metingen {basedir result_dirname name Xaxis Yaxis Y2axis calc} {
		$log debug start
		if {$calc != "calc"} {
			# Metingen-Cluster-Z0.0.tsv
			set metingen_filename [det_metingen_filename $basedir $name]
			$log debug "Metingen filename: $metingen_filename"
			$plotter set_datafile $metingen_filename

			set clqn_executors [$lqns_control get_executors]
			set cpdf [[lindex $clqn_executors 0] get_cpdf]
			
			$plotter set_x_axis "[det_axis_label $Xaxis]" [$cpdf get_column $Xaxis]

			$plotter add_line "${Yaxis}-meet" [$cpdf get_column $Yaxis] y1
			if {$Y2axis != ""} {
				$plotter add_line "${Y2axis}-meet" [$cpdf get_column $Y2axis] y2
			}
		}		
		$log debug finished
	}
		
	

}