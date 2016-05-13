package require ndv

set_log_global info

proc main {argv} {
  set list150 {C:\PCC\Nico\Projecten\Transact-ClientReporting\2016\PDF-XLS\clrep-150items.txt}
  set resdir {C:\PCC\Nico\VuGen\ClientReporting\result1\Iteration1}
  set itemparams {C:\PCC\Nico\VuGen\ClientReporting\itemparams.txt}
  set dbname [file join [file dirname $list150] "items.db"]
  set db [get_results_db $dbname]
  handle_list $list150 $resdir $db
  handle_itemparams $itemparams $db
  $db close
}

proc handle_list {list150 resdir db} {
  set f [open $list150 r]
  set type "<none>"
  set old_dir [pwd]
  try_eval {
	  cd $resdir
	  while {[gets $f line] >= 0} {
		if {[regexp {== (.+) ==} $line z tp]} {
			set type $tp
		} else {
			set item [string trim $line]
			if {$item != ""} {
				handle_item $type $item $db
			}
		}
	  }
	  close $f
  } {
	puts stderr "error occurred: $errorResult"
  }
  cd $old_dir
}

proc handle_item {type item db} {
  puts "Handling item: $type: $item"
  $db insert item150 [vars_to_dict type item]
  set res [exec {c:\PCC\util\cygwin\bin\grep} -l $item *]
  puts "res: $res"
  set files [split $res "\n"]
  foreach file $files {
	puts "$type-$item-$file"
	$db insert itemfile [vars_to_dict type item file]
  }
}

proc handle_itemparams {itemparams db} {
  set f [open $itemparams r]
  while {[gets $f line] >= 0} {
  # All_Open_Transactions.c(263): Notify: Saving Parameter "Itemparams1 = "CD3878301","CD3883003","CD3874939","CD3875310","CD19910535","CD23801677","CD23801334","CD18970906","CD7740207","CD23801411","CD23801494","CD23831653","CD18397088","CD26905625"".
	if {[regexp {Saving Parameter "(\S+) = (.*)".} $line z paramname items]} {
		set lst [split $items ","]
		foreach el $lst {
			if {[regexp {"(.+)"} $el z item]} {
				$db insert paramfound [vars_to_dict paramname item]
			}
		}
	}
  }
  close $f
}

# deze mogelijk in libdb:
proc get_results_db {db_name} {
  set existing_db [file exists $db_name]
  set db [dbwrapper new $db_name]
  define_tables $db
  $db create_tables 0 ; # 0: don't drop tables first. Always do create, eg for new table defs. 1: drop tables first.
  if {!$existing_db} {
    log info "New db: $db_name, create tables"
    # create_indexes $db
  } else {
    log info "Existing db: $db_name, don't create tables"
  }
  $db prepare_insert_statements
  #breakpoint
  return $db
} 

proc define_tables {db} {
  $db add_tabledef item150 {id} {type item}
  $db add_tabledef itemfile {id} {type item file}
  $db add_tabledef paramfound {id} {paramname item}
}

main $argv
