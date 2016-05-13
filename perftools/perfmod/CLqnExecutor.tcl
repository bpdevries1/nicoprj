# functionaliteit van lqns-control overnemen

package require Itcl
package require Tclx

source [file join $env(CRUISE_DIR) checkout lib perflib.tcl]
source [file join $env(CRUISE_DIR) checkout script lib CLogger.tcl]

source CLqnXmlFile.tcl
source CLqnTextFile.tcl
source CPlotDataFile.tcl
source CTemplateFile.tcl

# class maar eenmalig definieren
if {[llength [itcl::find classes CLqnExecutor]] > 0} {
	return
}

itcl::class CLqnExecutor {

	private common log
	# set log [CLogger::new_logger lqnsctrl debug]
	set log [CLogger::new_logger lqnexec info]

	public proc new_lqn_executor {exec_method lqns_control} {
		set result [uplevel {namespace which [CLqnExecutor #auto]}]
		$result set_exec_method $exec_method
		$result set_lqns_control $lqns_control
		return $result
	}
	
	private variable LQNS_EXE
	private variable LQSIM_EXE
	private variable LQN2EMF_EXE
	private variable EMF_FACTOR

	private variable lqns_control
	# private variable result_dirname
	private variable exec_method
	private variable cpdf
	private variable var_name
	private variable fo_calctimes
	private variable ctmpfile
	# private variable entry_name
	# private variable processor_name

	private variable breakdown_collection

	private constructor {} {
		global env
		set LQNS_HOME "C:\\nico\\util\\lqn\\LQN Solvers\\"
		catch {set LQNS_HOME $env(LQNS_HOME)}

		set LQNS_EXE [file join $LQNS_HOME lqns.exe]
		$log debug "LQNS_EXE: $LQNS_EXE"
		set LQSIM_EXE [file join $LQNS_HOME lqsim.exe]
		set LQN2EMF_EXE [file join $LQNS_HOME lqn2emf.exe]
		set EMF_FACTOR 2
				
		set breakdown_collection ""
		# set exec_method $an_exec_method
		# set lqns_control $a_lqns_control
	}
	
	public method set_exec_method {an_exec_method} {
		set exec_method $an_exec_method
	}
	
	public method set_lqns_control {a_lqns_control} {
		set lqns_control $a_lqns_control
	}
	
	public method set_ctmpfile {a_ctmpfile} {
		set ctmpfile $a_ctmpfile
	}
	
	public method get_cpdf {} {
		return $cpdf
	}
	
	public method get_exec_method {} {
		return $exec_method
	}
	
	public method set_fo_calctimes {a_fo_calctimes} {
		set fo_calctimes $a_fo_calctimes
	}
	
	public method set_breakdown_collection {a_breakdown_collection} {
		set breakdown_collection $a_breakdown_collection
	}
	
	public method execute {var_name lst_var_values case_name} {
		set cpdf [CPlotDataFile::new_pdf]
		$cpdf set_filename [file normalize [file join [$lqns_control get_result_dirname] "${exec_method}.tsv"]]
		
		# $cpdf set_columns [list $var_name X R U error_value]
		set lst [list $var_name]
		foreach entry_name [$lqns_control get_entry_names] {
			lappend lst "$entry_name.X"
			lappend lst "$entry_name.R"
		}
		lappend lst U
		lappend lst error_value
		$cpdf set_columns $lst
		$cpdf write_header

		foreach val $lst_var_values {
			set str [time {calc $exec_method $var_name $val $case_name conv_value iterations}]
			if {[regexp {^([0-9]+)} $str z time]} {
				# puts $fo_calctimes "LQNS\t$Z\t$N\t[expr 0.000001 * $time]\t$conv_value\t[format %4.0f $iterations]"
				puts $fo_calctimes "$exec_method\t$val\t[expr 0.000001 * $time]\t$conv_value\t[format %4.0f $iterations]"
				if {$iterations > 100} {
					$log warn "val = $val, #iterations: $iterations, conv_value: $conv_value"
				}
			}

		}
		close_files
	}

	# nieuwere lqns methode, zonder N en Z in de paramlijst.
	# @param var_value: de waarde vande variabele die gevarieerd wordt in de loop.
	private method calc {exec_method var_name var_value case_name conv_value_name iterations_name} {
		upvar $conv_value_name conv_value
		upvar $iterations_name iterations
		$log info "start"
		set template_filename [$ctmpfile get_template_filename]
		set lqn_filename [file join [$lqns_control get_result_dirname] "${exec_method}-${var_name}-${var_value}.xml"]
		make_lqn $template_filename $lqn_filename $var_name $var_value
		call_lqns $lqn_filename $exec_method
		# alleen nog ondersteuning XML input/output files.
		set lqn_xml_file [CLqnXmlFile #auto]
		$lqn_xml_file set_xml_file ${lqn_filename}.out
		set lst_entry_names [$lqns_control get_entry_names]
		$lqn_xml_file set_entry_names $lst_entry_names
		$lqn_xml_file set_processor_name [$lqns_control get_processor_name]
		$lqn_xml_file parse_results 
		# set X [$lqn_xml_file get_X]
		# set R [$lqn_xml_file get_R]
		set U [$lqn_xml_file get_U]
		# set U_sc 0
		# set U_bg 0
		set conv_value [$lqn_xml_file get_conv_value]
		set iterations [$lqn_xml_file get_iterations]

		# als convergence value te hoog is, dan errorbar toevoegen.
		if {$conv_value > 1} {
			# set error_value [expr 0.1 * $X]
			# kan zijn dat waarde niet bekend is, dan error value ook niet
			set error_value "-"
			catch {set error_value [expr 0.1 * [$lqn_xml_file get_entry_value [lindex $lst_entry_names 0] X]]}
			if {$error_value != "-"} {
				if {$error_value < 5} {
					set error_value 5
				}
			}
		} else {
			set error_value 0
		}
		# $cpdf write_line [list $var_value $X $R $U $error_value]

		set lst [list $var_value]
		foreach entry_name $lst_entry_names {
			lappend lst [$lqn_xml_file get_entry_value $entry_name X]
			lappend lst [$lqn_xml_file get_entry_value $entry_name R]			
		}
		lappend lst $U
		lappend lst $error_value
		$cpdf write_line $lst
		
		make_emf $lqn_filename

		foreach entry_name $lst_entry_names {
			set lqn_breakdown [$lqn_xml_file det_breakdown $entry_name]
			if {$lqn_breakdown != ""} {
				$lqn_breakdown set_var $var_name $var_value
				# $lqn_breakdown log_debug
				# $lqn_breakdown print stdout
				$breakdown_collection add_breakdown $lqn_breakdown
			}
		}

		$log info "finished"
	}



	# @todo niet meer per line, maar in één keer de hele file lezen en regsub's uitvoeren.
	private method make_lqn {template_filename lqn_filename var_name var_value} {
		# set ctmpfile [CTemplateFile #auto $template_filename]
		$ctmpfile set_property $var_name $var_value
		$ctmpfile make_file $lqn_filename
	}

	private method call_lqns {lqn_filename exec_method} {
		$log info "start"
		set lqnfile_type [det_lqnfile_type $lqn_filename]
		
		if {$exec_method == "LQNS"} {
			if {$lqnfile_type == "xml"} {
				if {[catch {set res [exec $LQNS_EXE $lqn_filename -o - >${lqn_filename}.out.tmp]} res_stderr]} {
					$log error "$res_stderr"
				}
			} else {
				fail "Unknown filetype: $lqnfile_type"
			}
		} elseif {$exec_method == "LQSIM"} {
			if {$lqnfile_type == "xml"} {
        try_eval {
          # set res [exec $LQSIM_EXE -P messages=5000 -T 10000 $lqn_filename -o - >${lqn_filename}.out.tmp]
          # NdV 17-11-2009 met tracing voor timeline
          # set res [exec $LQSIM_EXE -P messages=5000 -t timeline -m ${lqn_filename}.log -T 250 $lqn_filename -o - >${lqn_filename}.out.tmp]
          if {1} {
            set res [exec $LQSIM_EXE -P messages=5000 -t task=.* -m ${lqn_filename}.log -T 250700 $lqn_filename -o - >${lqn_filename}.out.tmp]
          } else {
            set res [exec $LQSIM_EXE -P messages=5000 -T 250700 $lqn_filename -o - >${lqn_filename}.out.tmp]
          }
        } {
          $log error "Error LQSIM: $errorResult" 
        }
        if {0} {
          if {[catch {set res [exec $LQSIM_EXE -P messages=5000 -T 10000 $lqn_filename -o - >${lqn_filename}.out.tmp]} res_stderr]} {
            $log error "$res_stderr"
          }
        }
			} else {
				fail "Unknown filetype: $lqnfile_type"
			}
		} else {
			fail "Unknown method: $exec_method"
		}
		split_result_file "${lqn_filename}.out"
		$log info "finished"
	}

	# zet warnings in een aparte warning file, rest in output.
	private method split_result_file {out_filename} {
		set fi [open "${out_filename}.tmp" r]
		# sowieso een out_filename maken, blijft evt leeg
		set fo [open ${out_filename} w]
		set fow -1

		set state BEGIN
		while {![eof $fi]} {
			gets $fi line
			if {$state == "BEGIN"} {
				if {[regexp {<\?xml} $line]} {
					puts $fo $line
					set state XML
				} else {
					if {$fow == -1} {
						set fow [open "${out_filename}.warn" w]
					}
					puts $fow $line
				}
			}	elseif {$state == "XML"} {
				puts $fo $line
			}	else {
				fail "Unknown state: $state"
			}
		}
		close $fi
		file delete "${out_filename}.tmp"
		if {$fo != -1} {
			close $fo
		}
		if {$fow != -1} {
			close $fow
		}
	}

	private method make_emf {lqn_filename} {
		$log info "making EMF..."
		# catch {set res [exec $LQN2EMF_EXE -M3 $lqn_filename]} res_stderr
		set lqnfile_type [det_lqnfile_type $lqn_filename]
		if {$lqnfile_type == "lqn"} {
			catch {set res [exec $LQN2EMF_EXE -M${EMF_FACTOR} $lqn_filename]} res_stderr
		} elseif {$lqnfile_type == "xml"} {
			catch {set res [exec $LQN2EMF_EXE -M${EMF_FACTOR} ${lqn_filename}.out]} res_stderr
			# set res [exec $LQN2EMF_EXE -M${EMF_FACTOR} ${lqn_filename}.out]
		} 
	
	}

	private method det_lqnfile_type {lqn_filename} {
		if {[regexp {lqn$} $lqn_filename]} {
			fail "lqn filetype no longer supported, use XML"
			return "lqn"
		} elseif {[regexp {xml$} $lqn_filename]} {
			return "xml"
		} else {
			fail "Unknown file type: $lqn_filename"
		}
	}

	public method close_files {} {
		$cpdf close
	}

	
}