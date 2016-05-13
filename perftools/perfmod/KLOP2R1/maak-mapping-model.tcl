package require Itcl

source [file join $env(CRUISE_DIR) checkout lib perflib.tcl]
source [file join $env(CRUISE_DIR) checkout script lib CLogger.tcl]

source CLqnTemplate.tcl

# class maar eenmalig definieren
if {[llength [itcl::find classes CMappingPlaat]] > 0} {
	return
}

itcl::class CMappingPlaat {

	private common log
	# set log [CLogger::new_logger [file tail [info script]] debug]
	set log [CLogger::new_logger [file tail [info script]] info]

	private variable fi
	private variable fo

	private variable cur_page
	private variable cur_trg_portlet
	private variable cur_trg_action
	private variable cur_res_portlet
	private variable cur_res_action
	private variable cur_n_gghh
	private variable cur_method_gghh
	
	private variable lst_portlets
	private variable lst_trg_portlets
	private variable lst_page_portlets	
	private variable lst_portlet_actions
	private variable lst_gghh_calls
	private variable lst_bos
	private variable lst_bo_methods
	
	private variable trg_portlet_new
	private variable res_action_new
	
	private variable ophouden
	
	private variable clqn_template
	
	public constructor {} {
	
	}

	public method init_vars {} {
		set cur_page ""
		set cur_trg_portlet ""
		set cur_trg_action ""
		set cur_res_portlet ""
		set cur_res_action ""
		set cur_n_gghh ""
		set cur_method_gghh ""
		
		set lst_portlets {}
		set lst_trg_portlets {}
		set lst_page_portlets {}
		set lst_portlet_actions {}
		set lst_gghh_calls {}
		set lst_bos {}
		set lst_bo_methods {}
		
		set trg_portlet_new 0
		set res_action_new 0
		
	}
	
	public method maak_plaat {} {
		set tsv_filename "klop2-mapping.tsv"
		set dot_filename "generated\\klop2-mapping.dot"
		set clqn_template [CLqnTemplate::new_instance]
		$clqn_template init_excel
		handle_file $tsv_filename $dot_filename
		$clqn_template write_model "generated\\KLOP2R1.xmltmp" "generated\\KLOP2R1.lqnprop"
	}
	
	private method handle_file {tsv_filename dot_filename} {
		set fo [open $dot_filename w]
		write_header
		init_vars
		set fi [open $tsv_filename r]
		gets $fi line
		gets $fi line
		set ophouden 0
		while {![eof $fi]} {
			gets $fi line
			set lst [split $line "\t"]
			if {[llength $lst] >= 11} {
				set lst [lrange $lst 0 10]	
				handle_record $lst
			} else {
				$log warn "Regel niet 11 items (#[llength $lst]): [join $lst "/*\\"]"
			}
			if {$ophouden} {
				break
			}
		}
		close $fi
		
		write_footer
		close $fo

		set fo [open "generated/legenda.dot" w]
		write_header
		maak_legenda
		write_footer
	}
	
	private method maak_legenda {} {
		puts_page "Pagina"
		puts_portlet "Portlet"
		puts_page_portlet "Pagina" "Portlet"
		puts_action "Portlet" "Trigger actie" trigger
		puts_action "Portlet" "Gevolg actie" result
		puts_trigger "Portlet" "Trigger actie" "Portlet" "Gevolg actie"
		puts_gghh_call "GGHH Methode"
		puts_action_gghh "Portlet" "Gevolg actie" "GGHH Methode" "Aantal calls"
		puts_bo "Raakvlak systeem"
		puts_bo_method "Raakvlak systeem" "Raakvlak service methode"
		puts_gghh_bo "GGHH Methode" "Raakvlak systeem" "Raakvlak service methode" "Aantal calls"
	}
	
	# @pre lst heeft 11 elementen
	private method handle_record {lst} {
		puts $fo "# $lst"
		if {[regexp {<} [lindex $lst 0]]} {
			set ophouden 1
			return
		}
		foreach {page trg_portlet trg_action res_portlet res_action n_gghh method_gghh bo n_bo bo_method notes} $lst {
			handle_page $page
			handle_trg_portlet $trg_portlet
			if {$trg_portlet_new} {
				handle_trg_action $trg_action
				handle_res_portlet_action $res_portlet $res_action
				if {$res_action_new} {
					handle_gghh $method_gghh $n_gghh
					handle_bo $bo $bo_method $n_bo
				}
			}
		}
		
	}
	
	private method handle_page {page} {
		if {$page != ""} {
			puts_page $page
			set cur_page $page
			# $clqn_template set_page $page
		}
	}
	
	private method puts_page {page} {
		puts $fo "  [make_ident page $page] \[label=\"$page\",shape=box,fontname=Helvetica,style=filled,fillcolor=lightblue\];"
	}

	private method handle_trg_portlet {trg_portlet} {
		if {$trg_portlet != ""} {
			$log debug "Handle trg portlet: $trg_portlet"
			if {[list_add lst_trg_portlets $trg_portlet]} {
				puts_portlet $trg_portlet
				set trg_portlet_new 1
			} else {
				set trg_portlet_new 0
			}
			set cur_trg_portlet $trg_portlet
			if {[list_add lst_page_portlets "$cur_page.$cur_trg_portlet"]} {
				puts_page_portlet $cur_page $cur_trg_portlet
				$log debug "Nieuwe portlet op page: $cur_page.$cur_trg_portlet"
			} else {
				$log debug "Bestaande portlet op page: $cur_page.$cur_trg_portlet"
			}
			$log debug "Trg portlet new: $trg_portlet_new"
		}
	}

	private method puts_portlet {portlet} {
		regsub -all " " $portlet "\\n" label
		puts $fo "  [make_ident portlet $portlet] \[label=\"$label\",shape=box,fontname=Helvetica,style=filled,fillcolor=lightsalmon\];"
	}
	
	private method puts_page_portlet {page portlet} {
		puts $fo "  [make_ident page $page] -> [make_ident portlet $portlet] \[style=dashed\];"
	}
	
	# @pre: trg_portlet_new == 1
	private method handle_trg_action {trg_action} {
		if {$trg_action != ""} {
			set cur_trg_action $trg_action
			if {[list_add lst_portlet_actions "$cur_trg_portlet.$cur_trg_action"]} {
				puts_action $cur_trg_portlet $cur_trg_action trigger
				$clqn_template set_page_action $cur_page $cur_trg_action 
			} else {
				$log warn "Handle trg action: $trg_action: action al aanwezig."
			}
		}
	}

	# @pre: als res_portlet is ingevuld, dan res_action ook.
	private method handle_res_portlet_action {res_portlet res_action} {
		if {$res_portlet != ""} {
			set cur_res_portlet $res_portlet
			set cur_res_action $res_action
			
			if {[list_add lst_portlets $res_portlet]} {
				puts_portlet $res_portlet
				if {[list_add lst_page_portlets "$cur_page.$cur_res_portlet"]} {
					puts_page_portlet $cur_page $cur_res_portlet
				}
			}
			
			if {[list_add lst_portlet_actions "$cur_res_portlet.$cur_res_action"]} {
				puts_action $cur_res_portlet $cur_res_action result
				# puts_trigger $cur_trg_portlet $cur_trg_action $cur_res_portlet $cur_res_action
				set res_action_new 1		
			} else {
				set res_action_new 0
			}
			# bugfix: trigger-lijn sowieso tekenen
			puts_trigger $cur_trg_portlet $cur_trg_action $cur_res_portlet $cur_res_action
		}
	}

	# todo? misschien splitten van putten action en pijl
	private method puts_action {portlet action action_type} {
		if {$action_type == "trigger"} {
			set fillcolor "lightsalmon"			
		} else {
			set fillcolor "lightseagreen"
		}
		puts $fo "  [make_ident action "$portlet-$action"] \[label=\"$action\",shape=ellipse,fontname=Helvetica,style=filled,fillcolor=$fillcolor\];"
		puts $fo "  [make_ident portlet $portlet] -> [make_ident action "$portlet-$action"] \[style=dashed\];"
	}

	private method puts_trigger {trg_portlet trg_action res_portlet res_action} {
		# puts $fo "  [make_ident action "$trg_portlet-$trg_action"] -> [make_ident action "$res_portlet-$res_action"] \[label=\"trigger\"\];"
		puts $fo "  [make_ident action "$trg_portlet-$trg_action"] -> [make_ident action "$res_portlet-$res_action"];"
	}

	private method handle_gghh {method_gghh n_gghh} {
		if {$method_gghh != ""} {
			set cur_method_gghh $method_gghh
			if {[list_add lst_gghh_calls $method_gghh]} {
				puts_gghh_call $method_gghh
				# puts_action_gghh $cur_res_portlet $cur_res_action $cur_method_gghh $n_gghh
			}
			# bugfix: ook pijl trekken bij andere portlet naar al bestaande GGHH call.
			puts_action_gghh $cur_res_portlet $cur_res_action $cur_method_gghh $n_gghh
			$clqn_template add_gghh_call [make_ident "" $cur_method_gghh] $n_gghh
		}
	}
	
	private method puts_gghh_call {method_gghh} {
		set fillcolor "palevioletred"
		regsub -all " " $method_gghh "\\n" label
		puts $fo "  [make_ident gghh $method_gghh] \[label=\"$label\",shape=ellipse,fontname=Helvetica,style=filled,fillcolor=$fillcolor\];"
	}
	
	private method puts_action_gghh {res_portlet res_action method_gghh n_gghh} {
		puts $fo "  [make_ident action "$res_portlet-$res_action"] -> [make_ident gghh $method_gghh] \[label=\"#$n_gghh\"\];"
	}
	
	# @pre als bo gevuld, dan bo_method en n_bo ook
	private method handle_bo {bo bo_method n_bo} {
		if {$bo != ""} {
			if {[list_add lst_bos $bo]} {
				puts_bo $bo
			}
			if {[list_add lst_bo_methods "$bo.$bo_method"]} {
				puts_bo_method $bo $bo_method
			}
			puts_gghh_bo $cur_method_gghh $bo $bo_method $n_bo
			$clqn_template add_bo_call $bo $bo_method $n_bo
		}
	}

	private method puts_bo {bo} {
		set fillcolor "lightyellow"
		puts $fo "  [make_ident bo $bo] \[label=\"$bo\",shape=box,fontname=Helvetica,style=filled,fillcolor=$fillcolor\];"
	}
	
	private method puts_bo_method {bo bo_method} {
		regsub -all " " $bo_method "\\n" label
		set fillcolor "lightyellow"
		# puts $fo "  [make_ident bo_method "$bo.$bo_method"] \[label=\"$bo_method\",shape=ellipse,fontname=Helvetica,style=filled,fillcolor=$fillcolor\];"
		puts $fo "  [make_ident bo_method "$bo.$bo_method"] \[label=\"$label\",shape=ellipse,fontname=Helvetica,style=filled,fillcolor=$fillcolor\];"
		puts $fo "  [make_ident bo_method "$bo.$bo_method"] -> [make_ident bo $bo] \[style=dashed\];"
	}
	
	private method puts_gghh_bo {method_gghh bo bo_method n_bo} {
		puts $fo "  [make_ident gghh $method_gghh] -> [make_ident bo_method "$bo.$bo_method"] \[label=\"#$n_bo\"\];"
	}

	# identifiers puur gebruikt voor dot; intern in TCL script de labels als identifier.
	private method make_ident {type label} {
		set res $label
		regsub -all {[- /?()#:.]} $res "_" res
		
		return "$type$res"
	}
	
	private method write_header {} {
		puts $fo "digraph G \{
	node \[font=Helvetica\];
	edge \[font=Helvetica\];
	rankdir = \"LR\""		
	}
	
	private method write_footer {} {
		puts $fo "\}"
	}
	
}

proc main {argc argv} {
  check_params $argc $argv
  set mapping_plaat [CMappingPlaat #auto]
  $mapping_plaat maak_plaat
}

proc check_params {argc argv} {
  global env argv0
  if {$argc != 0} {
    # fail "syntax: $argv0 <template_filename> <result_dirname>; got $argv \[#$argc\]"
    fail "syntax: $argv0 ; got $argv \[#$argc\]"
  }
}

# aanroepen vanuit Ant, maar ook mogelijk om vanuit Tcl te doen.
if {[file tail $argv0] == [file tail [info script]]} {
  main $argc $argv
}