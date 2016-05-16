package require Itcl
package require ndv
package require struct::list

# ::ndv::source_once [file join [file dirname [info script]] .. .. .. lib tcl perflib.tcl]

itcl::class ResourceGraph {

	private common log
	# set log [::ndv::CLogger::new_logger [file tail [info script]] info]
	set log [::ndv::CLogger::new_logger [file tail [info script]] debug]

  private common instance ""
  private common R_binary "d:/develop/R/R-2.9.0/bin/Rscript.exe"

  private variable db
  private variable conn  
  
  private common r_script
  # r_script bepalen bij het ::ndv::source_oncen van de file, anders verkeerde dir
  set r_script [file normalize [file join [file dirname [info script]] "ResourceGraph.R"]]

  # tijdens maken graph: graph_start en graph_end
  private variable graph_start
  private variable graph_end
   
  public proc get_instance {} {
    if {$instance == ""} {
   		set instance [uplevel {namespace which [ResourceGraph #auto]}]
    }
    return $instance
  }
  
  public method set_database {a_db} {
    set db $a_db 
    set conn [$db get_connection]
  }
  
  public method make_graph {testrun_id testrun_name output_dir machine a_graph_start a_graph_end} {
    global env
    $log info "make resource graph ($testrun_id: $testrun_name) for $machine in output_dir: $output_dir START"
    set graph_start $a_graph_start
    set graph_end $a_graph_end
    file mkdir $output_dir
    set output_file [file join $output_dir "$machine.png"]
    if {[file exists $output_file]} {
      $log info "$output_file already exists; do nothing"
      return
    }    
    make_tempgraph $testrun_id $machine
    make_R_graph $testrun_id $testrun_name $output_dir $machine
    $log info "make resource graph ($testrun_id: $testrun_name) for $machine in output_dir: $output_dir FINISHED"
  }

  private method make_tempgraph {testrun_id machine} {
    try_eval {
      ::mysql::exec $conn "drop table tempgraph"  
    } {
      $log debug "table tempgraph could not be deleted"
    }
    ::mysql::exec $conn "create table tempgraph (resname_id integer, maxvalue float, fct float, label varchar(50))"

    set query "SELECT n.id, n.graphlabel, max(r.value)
FROM resusage r, logfile l, resname n
where r.logfile_id = l.id
and r.resname_id = n.id
and l.testrun_id = $testrun_id
and r.machine = '$machine'
and n.tonen = 1
[det_subwhere_start_end]
group by 1, 2"

    set qresult [::mysql::sel $conn $query -list]
    foreach row $qresult {
      foreach {resname_id graphlabel maxvalue} $row break
      foreach {label fct} [det_factor_label $graphlabel $maxvalue] break
      # ::mysql::exec $conn "insert into tempgraph values ($resname_id, $maxvalue, $fct, '[$db str_to_db $label]')"
      $db insert_object tempgraph -resname_id $resname_id -maxvalue $maxvalue -fct $fct -label $label
    }

  }

  private method det_subwhere_start_end {} {
    if {$graph_start != ""} {
      return " and r.dt >= '$graph_start'
               and r.dt <= '$graph_end' "
    } else {
      return " " 
    }
  }
  
  private method det_factor_label {label max} {
     # set max [expr pow 10 (ceil (log10 max))]
     set max [expr pow(10, ceil(log10($max)))]
     if {$max <= 100} {
       set fct 1 
       set str $label
     } else {
       set fct [expr $max / 100.0]
       # set str "$label (*[format "%2.0f" $fct])"
       set str "$label (*[format "%.4g" $fct])"
     }
     return [list $str $fct]
  }
  
  private method make_R_graph {testrun_id testrun_name output_dir machine} {
    $log debug "r_script: $r_script"
    # set r_script [file normalize [file join [file dirname [info script]] "Re::ndv::source_onceGraph.R"]]
    try_eval {
      # exec $r_script_exe $r_script [det_typeperf_output] $npoints $legend_name
      # set output_file [file join $output_dir "$machine[det_str_start_end].png"]
      set output_file [file join $output_dir "$machine.png"]
      $log debug "making png with R: $output_file" 
      set schemadef [$db get_schemadef]
      exec $R_binary $r_script $testrun_id $testrun_name $output_file $machine [det_title $machine] $graph_start $graph_end \
        [$schemadef get_db_name] [$schemadef get_username] [$schemadef get_password]
    } {
      $log error "Error during R processing: $errorResult"
    }   
  }

  private method det_title {machine} {
    set type [lindex [::mysql::sel $conn "select type from machine where name = '$machine'" -flatlist] 0]
    return "Resource usage on $machine ($type)"
  }
  
  private method det_str_start_end_old {} {
    if {$graph_start != ""} {
      set res "$graph_start-$graph_end"
      regsub -all -- " " $res "-" res
      regsub -all -- ":" $res "-" res
      return "-$res"
    } else {
      return "" 
    }
  }
   
}
