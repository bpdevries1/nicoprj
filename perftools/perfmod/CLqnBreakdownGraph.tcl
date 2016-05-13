package require Itcl

source [file join $env(CRUISE_DIR) checkout lib perflib.tcl]
source [file join $env(CRUISE_DIR) checkout script lib CLogger.tcl]
# source [file join $env(CRUISE_DIR) checkout script lib CPlotter.tcl]

# class maar eenmalig definieren
if {[llength [itcl::find classes CLqnBreakdownGraph]] > 0} {
	return
}

itcl::class CLqnBreakdownGraph {

	private common log
	# set log [CLogger::new_logger [file tail [info script]] debug]
	set log [CLogger::new_logger [file tail [info script]] info]

	public proc new_instance {a_result_dir} {
		set result [uplevel {namespace which [CLqnBreakdownGraph #auto]}]
		$result init $a_result_dir
		return $result
	}

	# constants
	# private common N_BREAKDOWN_ITEMS 5 ; # lijkt te weinig.
	# private common N_BREAKDOWN_ITEMS 10
	private common N_BREAKDOWN_ITEMS 100

	# instance vars
	private variable result_dir

	# instance methods while making graphs => not re-entrant.
	private variable breakdown_collection
	private variable exec_method

	public method init {a_result_dir} {
		set breakdown_collection ""
		set exec_method ""
		set result_dir [file normalize $a_result_dir]
	}
	
	public method make_graphs {a_breakdown_collection a_exec_method} {
		$log debug start
		set breakdown_collection $a_breakdown_collection
		set exec_method $a_exec_method
		$log debug "Making graphs for collection: [$breakdown_collection to_string]; exec_method: $exec_method"
		set lst_entry_names [$breakdown_collection get_entry_names]
		set lst_values [$breakdown_collection get_values]
		if {[llength $lst_entry_names] == 1} {
			$log info "#entries==1 => don't make graph for each value"
		} else {
			foreach value $lst_values {
				make_graph_value $value $lst_entry_names
			}
		}
		
		if {[llength $lst_values] == 1} {
			$log info "#values==1 => don't make graph for each entry"
		} else {
			foreach entry_name $lst_entry_names {
				make_graph_entry $entry_name $lst_values
			}
		}
		$log debug finished
	}

	private method make_graph_entry {entry_name lst_values} {
		$log debug "Making breakdown graph for entry $entry_name"
		
		set basename "$exec_method-$entry_name"
		set lst_labels [$breakdown_collection det_biggest_breakdown_labels $N_BREAKDOWN_ITEMS [list $entry_name] $lst_values]

		make_data_file_entry $entry_name $lst_values $basename $lst_labels
		make_m_file_entry $entry_name $basename $lst_labels $lst_values
		gnuplot_file [file join $result_dir "$basename.m"] [file join $result_dir "$basename.png"] [file join $result_dir "$basename.tsv"]
	}

	private method make_graph_value {value lst_entry_names} {
		$log debug "Making breakdown graph for value $value"
		set basename "$exec_method-[$breakdown_collection get_var_name]$value"
		set lst_labels [$breakdown_collection det_biggest_breakdown_labels $N_BREAKDOWN_ITEMS $lst_entry_names [list $value]]

		make_data_file_value $value $lst_entry_names $basename $lst_labels
		make_m_file_value $value $basename $lst_labels $lst_entry_names
		gnuplot_file [file join $result_dir "$basename.m"] [file join $result_dir "$basename.png"] [file join $result_dir "$basename.tsv"]
	}
	
	private method make_data_file_entry {entry_name lst_values basename lst_labels} {
		set f [open [file join $result_dir "$basename.tsv"] w]
		puts $f "# breakdown data for $basename"

		puts $f "# [$breakdown_collection get_var_name]\tR\t[join $lst_labels "\t"]"

		foreach value $lst_values {
			set breakdown [$breakdown_collection get_breakdown $entry_name $value]
			set R [$breakdown get_service_time]
			set lst_breakdown_times {}
			foreach label $lst_labels {
				lappend lst_breakdown_times [$breakdown get_breakdown_time $label]
			}
			puts $f "$value\t$R\t[join $lst_breakdown_times "\t"]"
		}
		
		close $f	
	}

	private method make_m_file_entry {entry_name basename lst_labels lst_values} {
		set f [open [file join $result_dir "$basename.m"] w]

		# sum the items starting from item 3 (base 1: first 2 are value and R
		set lst_plot_lines [det_plot_lines $basename $lst_labels 3]
		# set boxwidth [expr 1.0 * $x_value_max / (2.0 * $n_x_values)]
		set boxwidth [det_boxwidth $lst_values]
		
		puts $f "set terminal png size 1000, 1000 
set output '[file join $result_dir "$basename.png"]'

set format y \"%g\"
set grid ytics
set key below
set pointsize 1.0
set title \"Response time breakdowns for $entry_name\"
set xlabel \"[$breakdown_collection get_var_name]\"
set ylabel \"R (sec)\"
set xrange \[0:*\]
set yrange \[0:*\]
set ytics 

set style fill solid 0.5
set style fill pattern 1
# set boxwidth 0.75 relative
set boxwidth $boxwidth absolute

plot [join $lst_plot_lines " , \\\n"];

set output
exit"		
		
		close $f
	
	}

	# make the datafile for a specfic value (i.e. N=10), containing the times for all selected entries
	private method make_data_file_value {value lst_entry_names basename lst_labels} {
		set f [open [file join $result_dir "$basename.tsv"] w]
		puts $f "# breakdown data for [$breakdown_collection get_var_name]=$value"

		puts $f "# index\tentry name\tR\t[join $lst_labels "\t"]"

		set index 0
		foreach entry_name $lst_entry_names {
			set breakdown [$breakdown_collection get_breakdown $entry_name $value]
			set R [$breakdown get_service_time]
			set lst_breakdown_times {}
			foreach label $lst_labels {
				lappend lst_breakdown_times [$breakdown get_breakdown_time $label]
			}
			puts $f "$index\t$entry_name\t$R\t[join $lst_breakdown_times "\t"]"
			incr index
		}
		
		close $f	
	}

	private method make_m_file_value {value basename lst_labels lst_entry_names} {
		set f [open [file join $result_dir "$basename.m"] w]

		# sum the items starting from item 4 (base 1: first 3 are index, entryname and R
		set lst_plot_lines [det_plot_lines $basename $lst_labels 4]
		set xrange_max [expr [llength $lst_entry_names] - 0.5]
		
		puts $f "set terminal png
set output '[file join $result_dir "$basename.png"]'

set format y \"%g\"
set grid ytics
set key below
set pointsize 1.0
set title \"Response time breakdowns for [$breakdown_collection get_var_name]=$value\"
set xlabel \"Entry name\"
set ylabel \"R (sec)\"
set xrange \[-0.5:$xrange_max\]
set yrange \[0:*\]
set ytics 

set style fill solid 0.5
set style fill pattern 1
set boxwidth 0.7 relative
set xtics rotate by 90 ([det_xtics $lst_entry_names])

plot [join $lst_plot_lines " , \\\n"];

set output
exit"		
		
		close $f
	
	}

	
	# @param base_sum_index: 3 for entry-file, 4 for value-file
	# column for R is base_sum_index - 1
	private method det_plot_lines {basename lst_labels base_sum_index} {
		set lst_result {}
		for {set i [expr [llength $lst_labels] - 1]} {$i >= 0} {incr i -1} {
			lappend lst_result "'[file join $result_dir "$basename.tsv"]' using 1:[det_graph_sum $i $base_sum_index] axes x1y1 with boxes title '[lindex $lst_labels $i]'"
			# filledcurves zien er niet goed uit.
			# lappend lst_result "'[file join $result_dir "$basename.tsv"]' using 1:[det_graph_sum $i] axes x1y1 with filledcurves x1 title '[lindex $lst_labels $i]'"
		}
		lappend lst_result "'[file join $result_dir "$basename.tsv"]' using 1:[expr $base_sum_index - 1] axes x1y1 with linespoints linewidth 5 title 'R'"
		return $lst_result
	}
	
	# 2: ($3+$4$5)
	# 1: ($3+$4)
	# 0: ($3)
	private method det_graph_sum {index base_sum_index} {
		set lst {}
		for {set i 0} {$i <= $index} {incr i} {
			lappend lst "\$[expr $i + $base_sum_index]"
		}
		return "([join $lst "+"])"
	}
	
	# boxwidth is measured in x-axis units.
	# calculate 90% of the smallest distance between two x values
	# @pre: lst_values is sorted.
	private method det_boxwidth {lst_values} {
		# set boxwidth [expr 1.0 * $x_value_max / (2.0 * $n_x_values)]
		set min_distance [expr [lindex $lst_values 1] - [lindex $lst_values 0]]
		for {set i 1} {$i < [expr [llength $lst_values] - 1]} {incr i} {
			set distance [expr [lindex $lst_values [expr $i + 1]] - [lindex $lst_values $i]]
			if {$distance < $min_distance} {
				set min_distance $distance
			}
		}
		return [expr 0.9 * $min_distance]
	}
	
	# "00-PortalStart" 0, "01-Login" 1, "02-ShowCase" 2, "05-SelectKlant" 3, "07-Logout" 4
	private method det_xtics {lst_entry_names} {
		set lst_result {}
		set index 0
		foreach entry_name $lst_entry_names {
			lappend lst_result "\"$entry_name\" $index"
			incr index
		}
		return [join $lst_result ", "]
	}
	
}