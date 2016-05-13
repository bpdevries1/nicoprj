package require Itcl
package require xml

source [file join $env(CRUISE_DIR) checkout lib perflib.tcl]
source [file join $env(CRUISE_DIR) checkout script lib CLogger.tcl]

source CLqnModel.tcl

# class maar eenmalig definieren
if {[llength [itcl::find classes CLqnXmlFile]] > 0} {
	return
}

# vooral bedoeld om output XML van Lqn te parsen.
# later evt ook de asymptoten berekening direct op de (input) XML doen.
itcl::class CLqnXmlFile {

	private common log
	set log [CLogger::new_logger lqnxmlfile info]

	private variable xml_file
	private variable lst_entry_names ; # names of entry to show X and R for.
	private variable processor_name ; # name of processor to show usage for.

	# output results
	# private variable X
	# private variable R
	private variable ar_entry_values
	private variable U
	private variable conv_value
	private variable iterations

	# model for breaking down response times
	private variable lqn_model

	# parse instance vars
	private variable current_path
	private variable current_entry
	private variable current_processor
	private variable current_called_entry
	private variable current_lqn_call

	public constructor {} {
		set xml_file ""
		set lst_entry_names {}
		set processor_name ""
		set lqn_model ""
		init
	}

	private method init {} {
		# set X 0
		# set R 0
		# set U 0
		set U "-"
		set conv_value 0
		set iterations 0	
		set current_path ""
		set current_entry ""
		set current_processor ""	
	}

	if {0} {
		public method get_X {} {
			return $X
		}
		
		public method get_R {} {
			return $R
		}
	}

	public method get_entry_value {entry_name value_name} {
		set result "-"
		catch {set result $ar_entry_values($entry_name,$value_name)}
		# voorlopig even hier
		if {$value_name == "R"} {
			catch {set result [expr $result + $ar_entry_values($entry_name,callwait)]}
		}
		return $result
	}

	public method get_U {} {
		return $U
	}

	public method get_conv_value {} {
		return $conv_value
	}

	public method get_iterations {} {
		return $iterations
	}

	public method set_xml_file {a_file} {
		set xml_file $a_file
	}
	
	public method set_entry_names {a_lst_entry_names} {
		set lst_entry_names $a_lst_entry_names
	}

	public method set_processor_name {a_processor_name} {
		set processor_name $a_processor_name
	}
	
	public method det_breakdown {an_entry_name} {
		if {$lqn_model != ""} {
			return [$lqn_model det_breakdown $an_entry_name]
		} else {
			return ""
		}
	}
	
	public method parse_results {} {
		$log debug "start" 
		init
		# moet hier met itcl::code zelf de $this reference meegeven...
		set parser [::xml::parser -elementstartcommand [itcl::code $this el_start] \
															-elementendcommand [itcl::code $this el_end] \
															-characterdatacommand [itcl::code $this cdata]]
		set f [open $xml_file r]
		set str [read $f]
		close $f
		
		if {[string length $str] > 0} {
			set lqn_model [CLqnModel::new_instance]
			$parser parse $str
			$lqn_model log_debug
		} else {
			set conv_value 10 ; # aangeven dat het fout is.
		}


		if {0} {
			# # strip evt foutmeldingen voor het begin van de xml tag
			# strippen hoeft hier niet meer, is al gebeurd in CLqnExecutor
			set len1 [string length $str]
			set str2 ""
			regexp {(<\?xml .*)$} $str z str2
			set len2 [string length $str2]
			if {$len2 > 0} {
				$parser parse $str2
			} else {
				# aangeven dat het fout is.
				set conv_value 10
			}
				
			if {$len1 != $len2} {
				# schrijf bestand opnieuw, ook gebruikt voor EMF generatie
				set f [open $xml_file w]
				puts $f $str
				close $f
			}
		}		
		$log debug "finished"
	}
	
	private method el_start {name attlist args} {
    array set att $attlist
    $log debug "el_start: $name - $attlist"
    if {$current_path == ""} {
      set current_path $name
    } else {
      set current_path "$current_path.$name"
    }
    
    if {[regexp {solver-params\.result-general} $current_path]} {
    	set conv_value $att(conv-val)
    	set iterations $att(iterations)
    } elseif {$name == "entry"} {
    	set current_entry $att(name)
    } elseif {$name == "processor"} {
			set current_processor $att(name)    
		} elseif {$name == "result-entry"} {
			set X $att(throughput)
			set ar_entry_values($current_entry,X) $X
			$log debug "set $current_entry.X to $X"
		} elseif {$name == "activity"} {
			set D ""
			catch {set D $att(host-demand-mean)}
			if {$D != ""} {
				[$lqn_model det_entry $current_entry] set_service_demand $D
			}
    } elseif {$name == "result-activity"} {
			set R $att(service-time)
			set proc_wait $att(proc-waiting)
			set ar_entry_values($current_entry,R) $R
			$log debug "set $current_entry.R to $R"
			[$lqn_model det_entry $current_entry] set_service_time $R
			[$lqn_model det_entry $current_entry] set_proc_wait $proc_wait
    } elseif {$name == "result-processor"} {
			if {$current_processor == $processor_name} {
				set U $att(utilization)
			}    	
		} elseif {$name == "synch-call"} {
			set current_called_entry $att(dest)
			set n_calls $att(calls-mean)
			set current_lqn_call [CLqnCall::new_instance [$lqn_model det_entry $current_entry] [$lqn_model det_entry $current_called_entry] $n_calls]
			[$lqn_model det_entry $current_entry] add_call $current_lqn_call
    } elseif {$name == "result-call"} {
    	set wait $att(waiting)
    	set ar_entry_values($current_called_entry,callwait) $wait
			$current_lqn_call set_task_wait $wait
    }
    
    
	}
  
	private method el_end {name args} {
    if {[regexp "^(.*)$name$" $current_path z current_path]} {
      # verwijder evt eindigende punt van current_path
      regexp {^(.+)\.$} $current_path z current_path
    }
	}
  
	private method cdata {data args} {
    if {$current_path != ""} {

    }
	}	
	
	
}