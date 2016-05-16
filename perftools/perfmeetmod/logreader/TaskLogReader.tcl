package require Itcl
package require ndv
package require Tclx

::ndv::source_once [file join [file dirname [info script]] AbstractLogReader.tcl]
::ndv::source_once [file join [file dirname [info script]] TaskLogHelper.tcl]
::ndv::source_once [file join [file dirname [info script]] PrevInputHandler.tcl]
::ndv::source_once [file join [file dirname [info script]] FirstLastInputHandler.tcl]

itcl::class TaskLogReader {
  inherit AbstractLogReader
  
  private common log
	# set log [::ndv::CLogger::new_logger [file tail [info script]] info]
  set log [::ndv::CLogger::new_logger [file tail [info script]] debug]
	  
  # private common instance  ""

  public proc new {db} {
 		set instance [uplevel {namespace which [TaskLogReader #auto]}]
    $instance init $db
    return $instance  
  }

  protected variable db
  protected variable log_helper
  public variable logfile_id
  
  #protected variable ts_eerste
  #protected variable ts_laatste 
  # protected variable ts
  protected variable threadname 
  protected variable threadnr 
  
  protected variable lst_input_handlers

  public method init {a_db} {
    set db $a_db
    set log_helper [TaskLogHelper::get_instance]
    $log_helper set_db $db
    register_handlers
  }
  
  # @note don't check for typeperf and sar files, can_read values of those should be higher than this one.
  public method can_read {filename} {
    set ext [file extension $filename]
    if {$ext == ".log" || $ext == ".csv"} {
      # kijken of er ergens timestamps te vinden zijn.
      set f [open $filename r]
      gets $f line
      set ts [$log_helper parse_timestamp $line]
      close $f
      if {$ts != ""} {
        return 1
      }
    }
    return 0
  }

  public method read_log {filename testrun_id} {
    $log debug "read_log: $filename, $db, $testrun_id"
    set logfile_id [$db insert_object logfile -testrun_id $testrun_id -path $filename -kind [det_kind $filename]]

    try_eval {
      lassign [det_threadname_number $filename] threadname threadnr
      $log debug "read_log: $filename: $threadname *** $threadnr ***"
      
      foreach input_handler $lst_input_handlers {
        $input_handler file_start $filename $logfile_id $threadname $threadnr
      }
      
      set fi [open $filename r]
      while {![eof $fi]} {
        handle_block $fi
      }
      close $fi
      
      # file_finished
      foreach input_handler $lst_input_handlers {
        $input_handler file_finished
      }
    } {
      $log error "Failed to read: $filename. Error: $errorResult"
      # verwijder logfile uit DB, zodat 'ie volgende keer weer wordt ingelezen
      $db delete_object logfile $logfile_id
      error "Failed to read: $filename. Error: $errorResult"
    }

  }

  public method read_log_old {filename testrun_id} {
    $log debug "read_log: $filename, $db, $testrun_id"
    set logfile_id [$db insert_object logfile -testrun_id $testrun_id -path $filename -kind [det_kind $filename]]

      lassign [det_threadname_number $filename] threadname threadnr
      $log debug "read_log: $filename: $threadname *** $threadnr ***"
      
      foreach input_handler $lst_input_handlers {
        $input_handler file_start $logfile_id $threadname $threadnr
      }
      
      set fi [open $filename r]
      while {![eof $fi]} {
        handle_block $fi
      }
      close $fi
      
      # file_finished
      foreach input_handler $lst_input_handlers {
        $input_handler file_finished
      }

  }
  
  protected method register_handlers {} {
    set lst_input_handlers {} 
    register_handler [PrevInputHandler::new $this $log_helper]
    register_handler [FirstLastInputHandler::new $this $log_helper]
  }

  public method register_handler {a_handler} {
    lappend lst_input_handlers $a_handler 
  }
  
  public method unregister_handler {a_handler} {
    todo: remove from lst_input_handlers 
  }
  
  
  # default implementation: handle per line, but possible to override in subclasses.
  # @pre: not eof $fi
  protected method handle_block {fi} {
    gets $fi line
    handle_line $line
  }

  # default implementation: use parse_timestamp
  protected method handle_line {line} {
    set ts [$log_helper parse_timestamp $line]
    if {$ts != ""} {
      if {[$ts to_string] < "2010"} {
        $log warn "Timestamp < 2010: $line" 
      }
      foreach input_handler $lst_input_handlers {
        $input_handler handle_input $line $ts 
      }
    } else {
      if {$line != ""} {
        $log debug "log_helper could not parse_timestamp: $line"
        # 6-5-2010 NdV input handler toch aanroepen met lege timestamp
        foreach input_handler $lst_input_handlers {
          $input_handler handle_input $line "" 
        }
      } else {
        # empty line, don't log. 
      }
    }
  }

  public method det_task_name {line line_prev threadname} {
    # return "$threadname-logline"
    return "logline"
  }
    
  protected method det_kind {filename} {
    return "general" 
  }

  # @note voor selectie vooralsnog geen aparte reader class, dus hierin opnemen.
  protected method det_threadname_number {filename} {
    set dirname [file dirname $filename]
    set tail [file tail $filename]
    if {[regexp {^logging.*selectie} $tail]} {
      set threadname "selectie"
      set threadnr "1"
    } elseif {[regexp {EdossierLogging_[0-9]{8}_([0-9]+)_edossier.csv} $tail z nr]} {
      set threadname "edossier"
      set threadnr $nr
    } else {
      $log warn "Default task (tasklog) for file: $filename"
      set threadname "tasklog"
      set threadnr "1"
    }
    return [list $threadname $threadnr]
  }

  public method update_logfile_count {count} {
    $log debug "Updating count-field for logfile.id: $logfile_id"  
    $db update_object logfile $logfile_id -aantal $count
  }
  
}