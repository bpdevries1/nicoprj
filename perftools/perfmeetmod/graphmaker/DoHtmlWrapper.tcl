package require Itcl
package require ndv
package require struct::list
package require struct::matrix
package require math

# ::ndv::source_once [file join [file dirname [info script]] .. lib ThreadHelper.tcl]
# ::ndv::source_once [file join [file dirname [info script]] JtlMaker.tcl]
::ndv::source_once [file join [file dirname [info script]] JtlMaker.tcl]

itcl::class DoHtmlWrapper {

	private common log
	set log [::ndv::CLogger::new_logger [file tail [info script]] info]
	# set log [::ndv::CLogger::new_logger [file tail [info script]] debug]

  private common instance ""
  
  private variable db
  private variable conn  
  
  private variable subdir
  private variable min_duration
  private variable maxlines ; # geen grafiek maken als er meer dan zoveel lijnstukken zijn.
  
  # tijdens query-en: mapping van threadname,threadnr -> y-waarde.
  # dit is de integer y-waarde, wel in deze class houden
  private variable ar_thread_y 
  
  private variable jm
  
  # tijdens maken graph: graph_start en graph_end
  private variable graph_start
  private variable graph_end
  
  # mapping van taskname -> linetype
  private variable ar_task_lt
  private variable n_task_lt
  
  private common dat0
  # dat0 bepalen bij het ::ndv::source_oncen van de file, anders verkeerde dir
  set dat0 [file normalize [file join [file dirname [info script]] tasks.dat0]]
  
  public proc get_instance {} {
    if {$instance == ""} {
   		set instance [uplevel {namespace which [DoHtmlWrapper #auto]}]
      $instance init0
    }
    return $instance
  }

  public method init0 {} {
    set db ""
    # @note default filter op .* zetten, zodat het wel altijd toegepast kan worden.
    set_taskregexp ".*"
    # set taskgraphname ""
    set subdir ""
    set min_duration 0
  }
  
  public method init {} {
    array unset ar_thread_y
    array unset ar_task_lt
    set n_task_lt 0
    array unset ar_heights
    array unset ar_n_heights
  }

  public method set_database {a_db} {
    set db $a_db 
    set conn [$db get_connection]
  }
  
  public method set_threadnamefilter {filter} {
    make_filter_proc proc_threadnamefilter $filter 
  }
  
  public method set_taskfilter {filter} {
    make_filter_proc proc_taskfilter $filter
  }

  private method make_filter_proc {proc_name filter} {
    $log debug "make_filter_proc: $proc_name - $filter"
    proc $proc_name [lindex $filter 0] [lindex $filter 1]
  }
  
  public method set_taskregexp {taskregexp} {
    $log debug "set_taskregexp: $taskregexp"
    # set taskregexp $a_taskregexp
    set_taskfilter [list x "regexp -- \{$taskregexp\} \$x"]
  }

  public method set_threadnameregexp {regexp} {
    make_filter_proc proc_threadnamefilter [list x "regexp -- \{$regexp\} \$x"] 
  }
  
  public method set_subdir {value} {
    set subdir $value 
  }
  
  public method set_min_duration {value} {
    set min_duration $value 
  }
  
  public method set_maxlines {value} {
    set maxlines $value 
  }
  
  #@param graph_start/end: "" or "2009-10-22 12:00:00"
  public method make_graph {testrun_id testrun_name output_dir a_graph_start a_graph_end} {
    global env
    $log debug "make_graph in output_dir: $output_dir: START"
    # file mkdir $output_dir
    file mkdir [file join $output_dir $subdir]
    set graph_start $a_graph_start
    set graph_end $a_graph_end
    set dt [det_str_start_end]
    set basename [file join $output_dir $subdir "dohtmltasks"]
    $log info "Make task graph: $basename START"
    # set cmd_filename "$basename$taskgraphname$dt.m"
    # set graph_filename "$basename$taskgraphname$dt.png"
    set jtl_filename "$basename.jtl"
    if {[file exists $jtl_filename]} {
      $log info "$jtl_filename already exists; do nothing"
      return [list "" ""]
    }    
    
    # set graph_filename "$basename.png"
    init
    # make_temptask $testrun_id
    make_temptables $testrun_id
    set jm [JtlMaker::new]
    foreach {graph_start graph_end} [make_jtlfile $testrun_id [file tail $testrun_name] $jtl_filename] break
    # gnuplot_file $cmd_filename $graph_filename $dat0
    # $log debug "Returning start-end: $graph_start-$graph_end"
    # $log debug "make_graph in output_dir: $output_dir: FINISHED"
    if {$graph_start == ""} {
      $log warn "graph_start is empty, don't make graph" 
    } else {
      $jm call_dohtml
      $jm move_to_output [file join $output_dir $subdir dohtml]
    }
    itcl::delete object $jm
    
    $log info "Make task graph: $basename FINSIHED"
    return [list $graph_start $graph_end]
  }

  private method det_str_start_end {} {
    if {$graph_start != ""} {
      set res "$graph_start-$graph_end"
      regsub -all -- " " $res "-" res
      regsub -all -- ":" $res "-" res
      return $res
    } else {
      return "" 
    }
  }
  
  private method make_temptables {testrun_id} {
    make_temptable temptask taskname $testrun_id proc_taskfilter
    make_temptable tempthreadname threadname $testrun_id proc_threadnamefilter
  }
  
  # make and fill a temporary table for determining if to include tasks
  # join this table with every query.
  # @note 19-1-2010 NdV the regexp/filter works on the taskname, not the graphlabel
  private method make_temptable {temptablename columnname testrun_id proc_filtername} {
    catch {::mysql::exec $conn "drop table $temptablename"}
    ::mysql::exec $conn "create table $temptablename (value varchar(255))"
    set query "select distinct t.$columnname
               from task t, logfile l
               where t.logfile_id = l.id
               and l.testrun_id = $testrun_id
               [det_subwhere_start_end]
               and t.sec_duration >= $min_duration
               order by 1"
    set qresult [::mysql::sel $conn $query -flatlist]
    $log debug "qresult before filter: $qresult"
    set qresult [::struct::list filter $qresult [itcl::code $proc_filtername]]
    $log debug "qresult after filter: $qresult"
    foreach value $qresult {
      ::mysql::exec $conn "insert into $temptablename values ('$value')"
    }
    if {[llength $qresult] == 0} {
      $log warn "Temp table contains no records: $temptablename" 
    }
  }

  # @return list with 2 elements: start and end, in format 2009-11-23 12:23:45
  private method make_jtlfile {testrun_id testrun_name jtl_filename} {
    $log debug "Making jtl file: $jtl_filename: START"
    set x_start ""
    foreach {x_start x_end} [det_xrange $testrun_id] break
    if {$x_start == ""} {
      $log debug "Empty x-range, returning"
      # 30-3-2010 NdV niets te plotten, er is geen data, filters mogelijk fout.
      return [list "" ""]
    }
    $log debug "x_start: $x_start"
    $log debug "x_end: $x_end"
    
    $jm open_file $jtl_filename
    
    set query "select t.threadname, t.threadnr, t.taskname, t.dec_start, t.dec_end, td.graphlabel, t.sec_duration * 1000
               from task t, logfile l, temptask tt, tempthreadname ttn, taskdef td
               where t.logfile_id = l.id
               and l.testrun_id = $testrun_id
               and t.taskname = td.taskname
               [det_subwhere_start_end]
               and t.sec_duration >= $min_duration
               and tt.value = t.taskname
               and ttn.value = t.threadname
               order by t.dt_start, t.dt_end"
    $log debug "query: $query"
    set qresult [::mysql::sel $conn $query -list]
    $log debug "# in qresult na query: [llength $qresult]"
    if {($maxlines > 0) && ([llength $qresult] > $maxlines)} {
      $log warn "More than $maxlines rows in resultset: [llength $qresult]; don't make graph"
      return "# More than $maxlines rows in resultset: [llength $qresult]; don't make graph"
    }
    # $log debug "# in qresult na filter: [llength $qresult]"
    foreach el $qresult {
      foreach {threadname threadnr taskname dec_start dec_end graphlabel msec} $el break
      $jm sample -elapsed $msec -timestamp $dec_start -label $graphlabel -threadname $threadname -threadnr $threadnr
    }
    
    $jm close_file
  }

  # @return list with 2 elements: start and end, in format 2009-11-23 12:23:45
  # @note deze nodig in DoHtmlWrapper
  private method det_xrange {testrun_id} {
    if {$graph_start == ""} {
      set query "select min(t.dt_start) start, max(t.dt_end) end, t.taskname
                 from task t, logfile l, temptask tt, tempthreadname ttn
                 where t.logfile_id = l.id
                 and l.testrun_id = $testrun_id
                 and t.sec_duration >= $min_duration
                 and tt.value = t.taskname
                 and ttn.value = t.threadname
                 group by 3"
      set qresult [::mysql::sel $conn $query -list]
      # ook hier is taskname het 3e element.
      
      # 14-1-2010 niet meer nodig.
      #set qresult [::struct::list filter $qresult [itcl::code pr_lindex2]]
      if {$qresult == {}} {
        # 30-3-2010 NdV als query geen result, dan niets te plotten, filters mogelijk fout
        return {} 
      }
      # nu start als minimum van start en end als maximum van end bepalen.
      
      # fold als hieronder is wel leuk, maar niet nodig, ::math::min kan ook wel een lijst aan.
      # staat wel in docs dat ::math::min op numerieke waardes werkt, gebruik hier timestamps.
      # 8-1-2010 NdV Blijkbaar toch iets aan de hand met ::math functies: met fold gaat het wel goed, zonder deze wordt
      # het resultaat in een list gezet, ofwel {2009-11-23 12:23:45} ipv 2009-11-23 12:23:45. 
      set start [::struct::list fold [::struct::list mapfor el $qresult {lindex $el 0}] 9999 ::math::min]
      set end [::struct::list fold [::struct::list mapfor el $qresult {lindex $el 1}] 0 ::math::max]
      
      #set start [::math::min [::struct::list mapfor el $qresult {lindex $el 0}]]
      #set end [::math::max [::struct::list mapfor el $qresult {lindex $el 1}]]

      # foreach {start end} $qresult break
      set result "\[\"$start\":\"$end\"\]"
      $log debug "xrange result: $result"
      # return $result
      return [list $start $end]
    } else {
      # return "\[\"$graph_start\":\"$graph_end\"\]"
      return [list $graph_start $graph_end]
    }
  }

  private method det_thread_label {threadname threadnr} {
    $log trace "thread name and nr: $threadname *** $threadnr ***"
    # @note evt ook bepalen uit filename, per logfile een nieuw threadnr, maar dan wel bij subclass.
    if {$threadnr == ""} {
      set threadnr 1
    }
    return "$threadname-$threadnr"
  }
  
  # @note deze ook nodig in DoHtmlWrapper
  private method det_subwhere_start_end {} {
    if {$graph_start != ""} {
      return " and t.dt_end >= '$graph_start'
               and t.dt_start <= '$graph_end' "
    } else {
      return " " 
    }
  }
  
}
