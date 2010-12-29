# @todo ook description opnemen in views, wel zorgen dat database-plaatje nog gevonden wordt.
# @todo bv alle issues/reqs tonen per environment, steeds nieuw kopje per environment.
# def_table_fields [list env_name] ; # new table for these fields.
# def_row_fields [list issue_name] ; # new row for these fields, with key-columns
# def_col_fields [list issue_desc issue_kind issue_objects:connect_br issue_objects:llength]; # a value column for these fields. There can be 0 or more issue-objects
# for each issue, they should be connected by <br>'s.
# from the table from the query another data structure should be deducted:
# list [
#		[list page_field_names]
#   [list page_values]
#   [list key_field_names]
#   [list value_field_names]
#   [list rows]
#   each row:
#     [list [list key_values] [list value_values]
# of iets met een assoc-array.
#
# uitgangspunt:
# * the query levert gesorteerde, gegroepeerde results op.
#
# @todo idee: resultset eerst omzetten naar hierarchische structuur (XML-achtig), hier report van maken.
# @todo dan ook multi key velden beter te behandelen: keyveld 1 niet steeds herhalen als alleen key veld 2 verandert.
# @todo ook idee om XML vervolgens met XSLT op te maken: daar ook best tools voor, en std. XSLT!

# Revision: $Ref$

package require Itcl
package require Tclx ; #  voor cmdtrace en try_eval
package require xml
package require struct::stack

# eigen dingen: loggen, xml en html generatie.
package require ndv

# class maar eenmalig definieren
if {[llength [itcl::find classes COntoReport]] > 0} {
	return
}

itcl::class COntoReport {

	private common log
	# set log [CLogger::new_logger [file tail [info script]] info]
	set log [::ndv::CLogger::new_logger [file tail [info script]] debug] 
	
	public proc new_instance {} {
		set result [uplevel {namespace which [COntoReport \#auto]}]
		return $result
	}
	
	private variable contology
	private variable db
	
	private variable report_name
	private variable query
	# @todo lst_file_fields: fields that cause a new report file to be made.
	# @todo kan zijn dat bv file_fields wel gevuld, en section fields leeg, dan 1 tabel per file.
	private variable lst_section_fields ; # which fields causes a new section.
	private variable lst_key_fields
	private variable lst_value_fields
	private variable lst_all_fields ; # should be the same list as query result
	private variable ar_field_info ; # key: field-name; value: [list <type> <type_index>]
																	 #   type: section, key, value
																	 #   type_index: index within the type, starting with 0
	
	# tijdens runnen
	private variable ar_row_values
	private variable ar_prev_row_values ; # for key fields, one value; for value fields, a list of the values with the same key.
	private variable hh ; # htmlhelper
	private variable stack_tags ; # stack with xml tags.
	private variable cur_field ; # current field name, for corresponding with value.
	private variable is_in_table; # are we between <table> and </table> tags?
	private variable prev_key_field_index ; # do determine if a key field starts a new row
	private variable ar_table_value_lists; # array where values are lists with values for value-values (dus).
	
	public method init {an_ontology} {
		set contology $an_ontology
		set db [$contology get_db]
		reset
	}	
	
	public method reset {} {
		set report_name ""
		set query ""
		set lst_section_fields {}
		set lst_key_fields {}
		set lst_value_fields {}
	}
	
	public method set_name {a_name} {
		set report_name $a_name
	}
	
	public method set_query {a_query} {
		set query $a_query
	}
	
	public method add_section_field {a_key_field} {
		lappend lst_section_fields $a_key_field
	}

	public method add_key_field {a_key_field} {
		lappend lst_key_fields $a_key_field
	}
	
	public method add_value_field {a_value_field} {
		lappend lst_value_fields $a_value_field
	}
	
	private method init_report {} {
		set lst_all_fields {}
		set i 0
		foreach field $lst_section_fields {
			lappend lst_all_fields $field
			set ar_field_info($field) [list section $i]
			incr i
		}
		set i 0
		foreach field $lst_key_fields {
			lappend lst_all_fields $field
			set ar_field_info($field) [list key $i]
			incr i
		}
		set i 0
		foreach field $lst_value_fields {
			lappend lst_all_fields $field
			set ar_field_info($field) [list value $i]
			incr i
		}
		set prev_key_field_index -1 ; # so the first at level 0 starts a new row.
		set is_in_table 0; # beetje dubbelop met vorige instance var.
	}
	
	# gebruik settings voor section, key en value:
	# section: nieuwe h1,h2,h3, afhankelijk van aantal section fields, inclusief start tabel.
	# key: nieuwe rij in tabel, bij meerdere key-fields niet herhalen van voorlaatste.
	# value: cell
	# @todo meerdere waarden in 1 cell, met bv <hr/> gescheiden of andere functie op los laten.
	# of dit _is_ de definitie van value, want key zorgt voor een nieuwe rij!
	# todo: std methods voor report gebruiken, xml als tussenstap.
	public method make_report {} {
		$log debug "make_report: start: ${report_name}"
		init_report
		# reset_ar_prev_row_values
		
		set target_dir [file normalize "generated"]
		
		# eerst xml maken
		set xml_filename [file join $target_dir "${report_name}.xml"]
		query2xml $query $xml_filename
		
		set f [open [file join $target_dir "${report_name}.html"] w]
		set hh [::ndv::CHtmlHelper::new]
		$hh set_channel $f
		$hh write_header $report_name 0 ; #0: niet heading 1.
		
		set stack_tags [::struct::stack]
    set parser [::xml::parser -elementstartcommand [itcl::code $this el_start] \
															-elementendcommand [itcl::code $this el_end] \
															-characterdatacommand [itcl::code $this character_data] \
                               -errorcommand [itcl::code $this xml_error]]
    set fi [open $xml_filename r]
		set xml [read $fi]
		close $fi
		# $log debug "parsing xml: $xml"
		$parser parse $xml
		finish_table
		$stack_tags destroy
		
		if {0} {
			set result [::mysql::sel $db $query -list]
			# @todo sections
	
			$hh table_start border 1
			make_table_header_row
	
			foreach el $result {
				handle_result_row $el
			}
			#$hh table_row "nu alleen de laatste nog" b c
			make_table_row_prev
			$hh table_end
		}
		
		$hh write_footer
		close $f
	}

  private method el_start {name attlist args} {
    # array set att $attlist
		if {$name == "result"} {
			
		} elseif {$name == "cell"} {
			
		} elseif {$name == "name"} {
			
		} elseif {$name == "value"} {
			
		}
		# set cur_tag $name
		$stack_tags push $name
  }
  
	private method character_data {data} {
		set cur_tag [$stack_tags peek]
		if {$cur_tag == "result"} {
			# nothing, html report already started.
		} elseif {$cur_tag == "cell"} {
			# ook niets.
		} elseif {$cur_tag == "name"} {
			set cur_field $data
		} elseif {$cur_tag == "value"} {
			handle_cell $cur_field $data		
		}
	}
	
  private method el_end {name args} {
		if {$name == "result"} {
			
		} elseif {$name == "cell"} {
			
		} elseif {$name == "name"} {
			
		} elseif {$name == "value"} {
			
		}
		$stack_tags pop
		
	}
	
  private method xml_error {errorcode errormsg} {
    if {$errorcode != "unclosedelement"} {
      $log warn "Error in XML file: $errorcode: $errormsg" 
    } else {
			$log warn "Error in XML file (unclosed element): $errorcode: $errormsg"
		}
  }
	
	private method handle_cell {name value} {
		set field_info $ar_field_info($name)
		set field_type [lindex $field_info 0]
		set field_index [lindex $field_info 1]
		if {$field_type == "section"} {
			handle_section $field_index $value
		} elseif {$field_type == "key"} {
			handle_key $field_index $value
		} elseif {$field_type == "value"} {
			handle_value $field_index $name $value
		} else {
			# nothing, or error.
		}
	}

	private method handle_section {field_index value} {
		#$hh line "Section $field_index: $value"
		finish_table
		$hh heading [expr $field_index + 1] $value ; # +1: beginnen bij heading 1, title geeft naam van de file.
	}
	
	private method handle_key {field_index value} {
		#$hh line "Key $field_index: $value"
		if {$prev_key_field_index == -1} {
			# @todo waarsch hier wel duidelijk dat het om een nieuwe tabel gaat.
			make_new_row $field_index $value
		} elseif {$field_index <= $prev_key_field_index} {
			close_prev_row ; # vorige value cellen afsluiten, kan niet eerder.
			make_new_row $field_index $value
		} else {
			if {$field_index == [expr $prev_key_field_index + 1]} {
				# ok, 1 kolom verder.
				$hh table_data $value
			} else {
				$log warn "Error in creating report: current key field index too big: $field_index >> $prev_key_field_index"
			}
		}
		set prev_key_field_index $field_index
	}
	
	private method close_prev_row {} {
		# put value-fields in cells
		foreach field $lst_value_fields {
			$hh table_data [det_cell_value $ar_table_value_lists($field)]			
		}
		$hh table_row_end
	}
	
	private method make_new_row {field_index value} {
		# kan zijn dat er nog geen tabel is.
		if {!$is_in_table} {
			start_table
			set is_in_table 1
		}
		$hh table_row_start
		for {set i 0} {$i < $field_index} {incr i} {
			# empty cells before new key.
			$hh table_data "<br/>"
		}
		$hh table_data $value
		clear_table_value_lists
	}
	
	private method clear_table_value_lists {} {
		array unset ar_table_value_lists
		foreach field $lst_value_fields {
			set ar_table_value_lists($field) {}
		}
	}
	
	private method start_table {} {
		$hh table_start border 1
		make_table_header_row
	}
	
	private method handle_value {field_index name value} {
		# $hh line "Value $field_index: $value"
		lappend ar_table_value_lists($name) $value
	}
	
	private method finish_table {} {
		if {$is_in_table} {
			$log debug "is in table"
			close_prev_row			
			$hh table_end
		}
		set is_in_table 0
		set prev_key_field_index -1
	}
	
	public method make_report_old {} {
		init_report
		reset_ar_prev_row_values
		
		set target_dir [file normalize "generated"]
		
		set f [open [file join $target_dir "${report_name}.html"] w]
		set hh [::ndv::CHtmlHelper::new]
		$hh set_channel $f
		$hh write_header $report_name
		
		set result [::mysql::sel $db $query -list]
		# @todo sections

		$hh table_start border 1
		make_table_header_row

		foreach el $result {
			handle_result_row $el
		}
		#$hh table_row "nu alleen de laatste nog" b c
		make_table_row_prev
		$hh table_end
		
		$hh write_footer
		close $f
	}
	
	private method make_table_header_row {} {
		$hh table_row_start
		foreach key_field $lst_key_fields {
			$hh table_data $key_field 1
		}
		foreach key_field $lst_value_fields {
			$hh table_data $key_field 1
		}
		$hh table_row_end
	}
	
	# @todo eerst in assoc array, dan printen.
	private method handle_result_row {lst_row_values} {
		set i 0
		foreach field $lst_all_fields {
			set ar_row_values($field) [lindex $lst_row_values $i]
			incr i
		}

		if {[has_same_key]} {
			add_row_prev
		} else {
			#$hh table_row "make row previous" b c
			make_table_row_prev
			set_row_prev
		}
		
		if {0} {
		$hh table_row_start
		foreach field $lst_all_fields {
			$hh table_data $ar_row_values($field) 0
		}
		$hh table_row_end
		}
	}

	private method reset_ar_prev_row_values {} {
		foreach field $lst_key_fields {
			set ar_prev_row_values($field) ""
		}
		# probably not needed.
		foreach field $lst_value_fields {
			set ar_prev_row_values($field) ""
		}
	}
	
	private method has_same_key {} {
		set same 1
		foreach field $lst_key_fields {
			if {$ar_prev_row_values($field) != $ar_row_values($field)} {
				set same 0
			}
		}
		$log debug "has_same_key: $same ($ar_row_values([lindex $lst_key_fields end]))"
		return $same
	}
	
	# @pre values in array ar_row_values
	# @post values in array ar_prev_row_values, where the value values are lists.
	private method set_row_prev {} {
		foreach field $lst_key_fields {
			set ar_prev_row_values($field) $ar_row_values($field)
		}
		foreach field $lst_value_fields {
			set ar_prev_row_values($field) [list $ar_row_values($field)]
		}
	}
	
	private method add_row_prev {} {
		foreach field $lst_value_fields {
			lappend ar_prev_row_values($field) $ar_row_values($field)
			$log debug "na append: ($field) $ar_prev_row_values($field) (#[llength $ar_prev_row_values($field)])"
		}
	}
	
	private method make_table_row_prev {} {
		#$hh table_row a b c
		# check if we have previous, or this is first row
		if {$ar_prev_row_values([lindex $lst_key_fields 0]) != ""} {
			$hh table_row_start
			foreach field $lst_key_fields {
				$hh table_data $ar_prev_row_values($field) 0
			}
			foreach field $lst_value_fields {
				$hh table_data [det_cell_value $ar_prev_row_values($field)] 0
			}
			$hh table_row_end
		}
	}

	# 2 cases:
	# all elements in list are the same: only return one element
	# elements differ, concat with <hr/>
	private method det_cell_value {lst_values} {
		set result ""
		set lst_values [ontdubbel_list $lst_values]
		set result [$hh to_html [join $lst_values "<hr/>"]]
		if {$result == ""} {
			# leeg element vervangen door break, ziet er beter uit.
			set result "<br/>"
		}
		$log debug "det_cell_value: $result"
		return $result
	}
	
	private method ontdubbel_list {lst} {
		foreach el $lst {
			set ar($el) 1
		}
		return [lsort [array names ar]]
	}
	
	public method query2xml {query filename} {
		set f [open $filename w]
		set xh [::ndv::CXmlHelper::new]
		$xh set_channel $f
		#puts $f "<result>"

		set lst_col_names [det_col_names $query]

		$xh tag_start "result"
		set result [::mysql::sel $db $query -list]
		if {[llength $result] > 0} {
			set n_cols [llength [lindex $result 0]]
		} else {
			set n_cols -1
		}
		set prev_row {}
		foreach row $result {
			set new_pos [det_new_position $prev_row $row $n_cols]
			# puts $f "$new_pos: $row"
			xml_close_prev_row $xh $prev_row $new_pos $n_cols
			puts_row $xh $lst_col_names $row $new_pos $n_cols
			set prev_row $row
		}
		xml_close_prev_row $xh $prev_row 0 $n_cols
		
		#puts $f "</result>"
		$xh tag_end "result"
		close $f
	}

	private method det_col_names {query} {
		set h [::mysql::sel $db $query]
		set result [::mysql::col $db -current name]
		# vaag: endquery werkt alleen op query, niet op sel, geen andere manier om te sluiten.
		#::mysql::endquery $h
		return $result
	}
	
	# determine first position where the two rows (lists) differ, base 0
	# @result: 0 if prev row is empty or differ at first field.
	# @result: #columns if the rows are the same.
	private method det_new_position {prev_row row n_cols} {
		set result -1
		if {$prev_row == {}} {
			set result 0
		}
		set i 0
		while {($i < $n_cols) && ($result < 0)} {
			if {[lindex $prev_row $i] != [lindex $row $i]} {
				set result $i
			}
			incr i
		}
		
		return $result
	}

	private method xml_close_prev_row {xh prev_row new_pos n_cols} {
		if {$prev_row == {}} {
			return
		} else {
			for {set i [expr $n_cols - 1]} {$i >= $new_pos} {incr i -1} {
				$xh tag_end "cell"
			}
		}
	}

	# @todo column namen bepalen uit query en in array zetten.
	private method puts_row {xh lst_col_names row new_pos n_cols} {
		for {set i $new_pos} {$i < $n_cols} {incr i} {
			$xh tag_start "cell"
			$xh tag_tekst name [lindex $lst_col_names $i]
			$xh tag_tekst value [lindex $row $i]
		}
	}


}
