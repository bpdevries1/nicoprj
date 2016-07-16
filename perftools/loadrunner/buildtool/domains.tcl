task domains {get/update domains
  Create or update domains.ini file with headers for [keep] and [delete], which
  may next be editen manually. In the next execution of this task, the script will be updated by the settings: domains which should be deleted will be commented out.
  Use comment_remove to really delete those statements.
} {
  if {[file exists domains.ini]} {
    set domains_ini [ini_read domains.ini]
  } else {
    set domains_ini {}
  }

  foreach filename [filter_ignore_files [get_source_files]] {
    set statements [read_source_statements $filename]
    set stmt_groups [group_statements $statements]
    set domains_ini [update_domains_ini $domains_ini $stmt_groups]; # any new ones?
    write_source_statements $filename $stmt_groups $domains_ini;    # possibly comment out.
    
  }
  ini_write domains.ini $domains_ini
}


