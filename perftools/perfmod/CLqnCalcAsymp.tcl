# placeholder voor lqn asymptoten berekeningen, vooralsnog niet meer gebruikt.

if {0} {

	private method calc_asymp_xml {result_dirname template_filename N Z} {
		$log debug "start"

		set rootname [file rootname [file tail $template_filename]]
		set xml_filename [file join $result_dirname "$rootname-LQNS-${Z}$tijd_eenheid-$N.xml"]
	
		# zet de XML om naar oud LQN formaat.
		if {[catch {set res [exec $LQN2LQN_EXE $xml_filename]} res_stderr]} {
			$log error "$res_stderr"
		}

		# calc_asymp_lqn $fo $result_dirname $template_filename $N $Z
		set rootname [file rootname [file tail $template_filename]]
		# set lqn_filename "generated/$rootname-${Z}sec-$N.lqn" 
		set lqn_filename [file join $result_dirname "$rootname-LQNS-${Z}$tijd_eenheid-$N.lqn"]
			
		set lqn_text_file [CLqnTextFile #auto]
		$lqn_text_file set_lqn_filename $lqn_filename
		$lqn_text_file set_entry_name $entry_name
		$lqn_text_file calc_asymp $N $Z
		set X [$lqn_text_file get_X]
		set R [$lqn_text_file get_R]
		set D_max [$lqn_text_file get_D_max]
		set D_sum [$lqn_text_file get_D_sum]
		# puts $fo "$N\t$X\t$R\t0\t$Z\t$D_max\t$D_sum"
		$cpdf_asymp write_line [list $N $X $R 0 $Z $D_max $D_sum]
		$log debug "finished"
	}

		# @todo nog iets met asymptoten berekening doen?		
		if {0} {
			if {$calc_asymp} {
				set cpdf_asymp [CPlotDataFile #auto]
				$cpdf_asymp set_filename [file normalize [file join $result_dirname "asymp-$name.tsv"]]
				$cpdf_asymp set_columns [list N X R U Z U_sc U_bg D_max D_sum]
				$cpdf_asymp write_header
			}
		}

			# @todo calc_asymp nog te doen zo?
			if {0} {
				if {$calc_asymp} {
					# @todo template_filename hier niet meer bekend, dus dit gaat niet werken...
					if {[regexp {lqntmp$} $template_filename]} {
						calc_asymp_lqn $result_dirname $template_filename $N $Z
					} else {
						calc_asymp_xml $result_dirname $template_filename $N $Z
					}
				}
			}			

		if {$calc_asymp} {
			$cpdf_asymp close
		}

		if {$calc_asymp} {
			set cpdf_asymp [CPlotDataFile #auto]
			$cpdf_asymp set_filename [file normalize [file join $result_dirname "asymp-$name.tsv"]]
			$cpdf_asymp set_columns [list N X R U Z U_sc U_bg D_max D_sum]
			$cpdf_asymp write_header
		}
		
				if {$calc_asymp} {
					if {[regexp {lqntmp$} $template_filename]} {
						calc_asymp_lqn $result_dirname $template_filename $N $Z
					} else {
						calc_asymp_xml $result_dirname $template_filename $N $Z
					}
				}

		if {$calc_asymp} {
			$cpdf_asymp close
		}

	private method make_graph_asymp {result_dirname name Xaxis Yaxis Y2axis} {
		if {$calc_asymp} {
			# asymptoten uit bounds analysis toevoegen.
			# asymptoten eerst, kunnen worden overgeplot door latere lijnen.
			# $plotter set_datafile [file normalize [file join $result_dirname "asymp-$name.tsv"]]
			# $plotter set_x_axis "$AXISLABEL($Xaxis)" $COLUMN($Xaxis)

			# $cpdf_asymp set_filename [file join $result_dirname "asymp-$name.tsv"]


			$plotter set_datafile [$cpdf_asymp get_filename]
			# $plotter set_x_axis "$AXISLABEL($Xaxis)" [$cpdf_asymp get_column $Xaxis]
			$plotter set_x_axis [det_axis_label $Xaxis] [$cpdf_asymp get_column $Xaxis]
			make_asymp_line $plotter $Yaxis y1
			if {$Y2axis != ""} {
				make_asymp_line $plotter $Y2axis y2
			}
		
		}
	}
	
				
	# @param axis_value: X, R, U
	# @param axis: y1, y2
	private method make_asymp_line {plotter axis_value axis} {
		if {$axis_value == "X"} {
			$plotter add_line "X-asymp" $COLUMN(X) $axis "" lines
		}
		if {$axis_value == "R"} {
			$plotter add_line "R-asymp" $COLUMN(R) $axis "" lines
		}
	}

##################
Ook andere deprecated methods

	# @param extraname: bv Z0 of N1000-Zvar
	# @deprecated, use method analyse
	public method lqns_control {dirname Z_list N_list template_filename lqn_properties_filename result_dirname {extraname ""}} {
		$log debug "start"

		set basename $dirname

		set name [det_name $basename $extraname $Z_list $N_list]

		read_lqn_properties $lqn_properties_filename

		# set fo [open "generated/$rootname-calc.tsv" w]
		# set fo [open [file join $result_dirname "calc-$name.tsv"] w]
		# set fo_asymp [open [file join $result_dirname "asymp-$name.tsv"] w]
		if {$exec_lqns} {
			set cpdf_lqns [CPlotDataFile #auto]
			$cpdf_lqns set_filename [file normalize [file join $result_dirname "lqns-$name.tsv"]]
			$cpdf_lqns set_columns [list N X R U Z U_sc U_bg error_value]
			$cpdf_lqns write_header
		}
		
		if {$exec_lqsim} {
			set cpdf_lqsim [CPlotDataFile #auto]
			$cpdf_lqsim set_filename [file normalize [file join $result_dirname "lqsim-$name.tsv"]]
			$cpdf_lqsim set_columns [list N X R U Z U_sc U_bg error_value]
			$cpdf_lqsim write_header
		}
				
		set fo_calctimes [open [file join $result_dirname "calctimes-$name.tsv"] w]
	
		# puts $fo "# N X R Z U"
		# zorgen dat kolom volgorde hetzelfde is in metingen en calc.
		# puts $fo "# N\tX\tR\tU\tZ\tU_sc\tU_bg\terror_value"
		# puts $fo_asymp "# N\tX\tR\tU\tZ\tU_sc\tU_bg\tD_max\tD_sum"
		puts $fo_calctimes "# method\tZ\tN\tCalctime (s)\tConv.Value\tIterations"
	
		foreach Z $Z_list {
			foreach N $N_list {
				if {$exec_lqns} {
					set str [time {lqns_depr LQNS $result_dirname $template_filename $N $Z conv_value iterations}]
					if {[regexp {^([0-9]+)} $str z time]} {
						puts $fo_calctimes "LQNS\t$Z\t$N\t[expr 0.000001 * $time]\t$conv_value\t[format %4.0f $iterations]"
						if {$iterations > 100} {
							$log warn "N=$N, Z=$Z, #iterations: $iterations, conv_value: $conv_value"
						}
					}
				}
				if {$exec_lqsim} {
					set str [time {lqns_depr LQSIM $result_dirname $template_filename $N $Z conv_value iterations}]
					if {[regexp {^([0-9]+)} $str z time]} {
						puts $fo_calctimes "LQSIM\t$Z\t$N\t[expr 0.000001 * $time]\t$conv_value\t[format %4.0f $iterations]"
					}
				}
			}
		}
		
		# close $fo
		# close $fo_asymp
		if {$exec_lqns} {
			$cpdf_lqns close
		}
		if {$exec_lqsim} {
			$cpdf_lqsim close
		}
		close $fo_calctimes
		
		if {[llength $Z_list] > 1} {
			set Xaxis "Z"
		} elseif {[llength $N_list] > 1} {
			set Xaxis "N"
		} else {
			# dummy, maar een combi
			set Xaxis "N"
		}

		make_graphs $dirname $result_dirname $name $Xaxis

		$log debug "finished"
	}


	# @deprecated, niet meer gebruikt in analyse, nog wel in lqns_control
	private method det_name {basename extraname Z_list N_list} {
		if {$extraname != ""} {
			return "$basename-$extraname"
		} else {
			if {[llength $Z_list] == 1} {
				return "$basename-Z[lindex $Z_list 0]"
			} elseif {[llength $N_list] == 1} {
				return "$basename-N[lindex $Z_list 0]"
			} else {
				return "$basename-unknown"
			}
		}
	}

	# @deprecated, private, alleen hier hernoemen.
	private method lqns_depr {exec_method result_dirname template_filename N Z conv_value_name iterations_name} {
		upvar $conv_value_name conv_value
		upvar $iterations_name iterations
		$log info "start"
		set rootname [file rootname [file tail $template_filename]]
		# set lqn_filename "generated/$rootname-${Z}sec-$N.lqn" 
		if {[regexp {lqntmp$} $template_filename]} {
			set lqn_filename [file join $result_dirname "$rootname-${exec_method}-${Z}$tijd_eenheid-$N.lqn"]
		} elseif {[regexp {xmltmp$} $template_filename]} {
			set lqn_filename [file join $result_dirname "$rootname-${exec_method}-${Z}$tijd_eenheid-$N.xml"]
		} else {
			fail "Unknown type of template file: $template_filename"
		}
		make_lqn_depr $template_filename $lqn_filename $N $Z
		set DOE_LQNS 1
		# set DOE_LQNS 0
		if {$DOE_LQNS} {
			call_lqns $lqn_filename $exec_method
			if {[regexp {lqntmp$} $template_filename]} {
				parse_results $lqn_filename X R U U_sc U_bg conv_value iterations
			} elseif {[regexp {xmltmp$} $template_filename]} {
				set lqn_xml_file [CLqnXmlFile #auto]
				$lqn_xml_file set_xml_file ${lqn_filename}.out
				$lqn_xml_file set_entry_name $entry_name
				$lqn_xml_file set_processor_name $processor_name
				$lqn_xml_file parse_results 
				set X [$lqn_xml_file get_X]
				set R [$lqn_xml_file get_R]
				set U [$lqn_xml_file get_U]
				set U_sc 0
				set U_bg 0
				set conv_value [$lqn_xml_file get_conv_value]
				set iterations [$lqn_xml_file get_iterations]
			} else {
				fail "Unknown type of template file: $template_filename"
			}
			# puts $fo "$N\t$X\t$R\t$Z\t$U"
			# als convergence value te hoog is, dan errorbar toevoegen.
			if {$conv_value > 1} {
				set error_value [expr 0.1 * $X]
				if {$error_value < 5} {
					set error_value 5
				}
			} else {
				set error_value 0
			}
			# puts $fo "$N\t$X\t$R\t$U\t$Z\t$U_sc\t$U_bg\t$error_value"
			if {$exec_method == "LQNS"} {
				$cpdf_lqns write_line [list $N $X $R $U $Z $U_sc $U_bg $error_value]
			} elseif {$exec_method == "LQSIM"} {
				$cpdf_lqsim write_line [list $N $X $R $U $Z $U_sc $U_bg $error_value]
			}
			make_emf $lqn_filename
		}
		$log info "finished"
	}

	# @deprecated
	# @todo niet meer per line, maar in één keer de hele file lezen en regsub's uitvoeren.
	private method make_lqn_depr {template_filename lqn_filename N Z} {
		set fi [open $template_filename r]
		set fo [open $lqn_filename w]
		while {![eof $fi]} {
			gets $fi line
			set line [replace_line $line N $N]
			set line [replace_line $line Z $Z]
			foreach lqn_prop $lqn_properties {
				set name [lindex $lqn_prop 0]
				set value [lindex $lqn_prop 1]
				set line [replace_line $line $name $value]
			}
			set line [expr_line $line]
			puts $fo $line 
		} 
		close $fi
		close $fo
	}

	private method call_lqns {lqn_filename exec_method} {
		$log info "start"
		set lqnfile_type [det_lqnfile_type $lqn_filename]
		
		if {$exec_method == "LQNS"} {
			if {$lqnfile_type == "lqn"} {
				if {[catch {set res [exec $LQNS_EXE $lqn_filename -p]} res_stderr]} {
					$log error "$res_stderr"
				}
			} elseif {$lqnfile_type == "xml"} {
				if {[catch {set res [exec $LQNS_EXE $lqn_filename -o - >${lqn_filename}.out]} res_stderr]} {
					$log error "$res_stderr"
				}
			} else {
				fail "Unknown filetype: $lqnfile_type"
			}
		} elseif {$exec_method == "LQSIM"} {
			if {$lqnfile_type == "lqn"} {
				if {0} {
					if {[catch {set res [exec $LQSIM_EXE -p -T 10000 $lqn_filename]} res_stderr]} {
						$log error "$res_stderr"
					}
				}
				if {[catch {set res [exec $LQSIM_EXE -p -T 10000 -H 0.1 $lqn_filename]} res_stderr]} {
					$log error "$res_stderr"
				}
			} elseif {$lqnfile_type == "xml"} {
				if {[catch {set res [exec $LQSIM_EXE -T 10000 $lqn_filename -o - >${lqn_filename}.out]} res_stderr]} {
					$log error "$res_stderr"
				}
			} else {
				fail "Unknown filetype: $lqnfile_type"
			}
		} else {
			fail "Unknown method: $exec_method"
		}
		$log info "finished"
	}

}

				
	
