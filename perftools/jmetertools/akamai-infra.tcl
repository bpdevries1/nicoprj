#!/usr/bin/env tclsh86

# akamai-infra.tcl - create GraphViz plots of Akamai edge and remote servers

package require tdbc::sqlite3
package require Tclx
package require ndv

# cachetype_remote is not null

set only_remote 1

set log [::ndv::CLogger::new_logger [file tail [info script]] debug]
$log set_file "[file tail [info script]].log"

proc main {argv} {
  global only_remote
  lassign $argv jtl_dir
  set db_dir [file join $jtl_dir jtldb] 
  set conn [open_db [find_db $db_dir]]
  # eerst alles, geen onderscheid per label
  foreach only_remote {0 1} {
    foreach dct [db_query $conn "select distinct label from reqs"] {
      dict_to_vars $dct
      make_png $conn $db_dir $label
    }
  }
}

proc make_png {conn db_dir label} {
  global only_remote
  if {$only_remote} {
    set remote "-only-remote"
  } else {
    set remote "" 
  }
  set dot_file [file join $db_dir "akamai-infra-$label$remote.dot"]
  set png_file [file join $db_dir "akamai-infra-$label$remote.png"]
  set f [open $dot_file w]
  write_dot_header $f "LR"
  write_dot_title $f "Akamai Infra ($label)"
  puts_nodes $conn $f $label
  puts_edges_client $conn $f $label
  puts_edges_remote $conn $f $label
  write_dot_footer $f
  close $f
  do_dot $dot_file $png_file
}

proc puts_nodes {conn f label} {
  global ar_nodes
  # set ar_nodes(client) [puts_node_stmt $f Client]
  
  set query "select distinct akserver 
              from reqs 
              where akserver <> ''
              and akserver <> 'none'
              and label = '$label'
              [query_only_remote]
              union 
              select distinct akserver_remote 
              from reqs
              where akserver_remote <> ''
              and akserver_remote <> 'none'
              and label = '$label'
              [query_only_remote]
              union
              select distinct hostname
              from reqs"
  
  foreach dct [db_query $conn $query] {
    if {$dct == {}} {
      continue ; # maybe something to do with union 
    }
    dict_to_vars $dct
    # breakpoint
    set ar_nodes($akserver) [puts_node_stmt $f [just_host $akserver]]
  }
}

# @return akserver without trailing domain spec like a195-12-225-158.deploy.akamaitechnologies.com

proc just_host {akserver} {
  if {[regexp {^([^\.]+)} $akserver z res]} {
    return $res 
  } else {
    error "Error in regexp with akserver: $akserver" 
  }
}

proc puts_edges {conn f label} {
  # @todo remotes: vergelijkbaar met client->edge, dus reuse.
  global aantallen
  set query "select count(*) aantal, akserver, cachetype 
              from reqs 
              where akserver <> ''
              and akserver <> 'none'
              and label = '$label'
              [query_only_remote]
              group by 2,3
              order by 2,3"

  # fp: group by akserver.
  set prev_akserver "<none>"
  foreach dct [db_query $conn $query] {
    log debug "$label-edges: $dct"
    dict_to_vars $dct
    if {$prev_akserver != $akserver} {
      # handle_prev $f $prev_akserver
      handle_prev $f client $prev_akserver
      foreach ct {TCP_HIT TCP_MEM_HIT TCP_MISS TCP_REFRESH_MISS} {
        set aantallen($ct) 0 
      }
      set prev_akserver $akserver
    }
    # incr aantallen([det_type $cachetype]) $aantal
    incr aantallen($cachetype) $aantal
    
    # breakpoint
    # set ar_nodes($akserver) [puts_node_stmt $f [just_host $akserver]]
  }
  handle_prev $f client $prev_akserver  
}

proc puts_edges_client {conn f label} {
  global aantallen
  set query "select count(*) aantal, hostname, akserver, cachetype 
              from reqs 
              where akserver <> ''
              and akserver <> 'none'
              and label = '$label'
              [query_only_remote]
              group by 2,3,4
              order by 2,3,4"

  # fp: group by akserver.
  set prev_client "<none>"
  set prev_akserver "<none>"
  foreach dct [db_query $conn $query] {
    log debug "$label-client: $dct"
    dict_to_vars $dct
    if {($prev_akserver != $akserver) || ($prev_client != $hostname)} {
      handle_prev $f $prev_client $prev_akserver 
      foreach ct {TCP_HIT TCP_MEM_HIT TCP_MISS TCP_REFRESH_MISS} {
        set aantallen($ct) 0 
      }
      set prev_client $hostname
      set prev_akserver $akserver
    }
    # incr aantallen([det_type $cachetype]) $aantal
    incr aantallen($cachetype) $aantal
    
    # breakpoint
    # set ar_nodes($akserver) [puts_node_stmt $f [just_host $akserver]]
  }
  handle_prev $f $prev_client $prev_akserver 
}

proc puts_edges_remote {conn f label} {
  global aantallen
  set query "select count(*) aantal, akserver, akserver_remote, cachetype_remote 
              from reqs 
              where akserver <> ''
              and akserver <> 'none'
              and akserver_remote <> ''
              and akserver_remote <> 'none'
              and label = '$label'
              [query_only_remote]
              group by 2,3,4
              order by 2,3,4"

  # fp: group by akserver.
  set prev_akserver "<none>"
  set prev_akserver_remote "<none>"
  foreach dct [db_query $conn $query] {
    log debug "$label-remote: $dct"
    dict_to_vars $dct
    if {($prev_akserver != $akserver) || ($prev_akserver_remote != $akserver_remote)} {
      handle_prev $f $prev_akserver $prev_akserver_remote
      foreach ct {TCP_HIT TCP_MEM_HIT TCP_MISS TCP_REFRESH_MISS} {
        set aantallen($ct) 0 
      }
      set prev_akserver $akserver
      set prev_akserver_remote $akserver_remote
    }
    # incr aantallen([det_type $cachetype]) $aantal
    incr aantallen($cachetype_remote) $aantal
    
    # breakpoint
    # set ar_nodes($akserver) [puts_node_stmt $f [just_host $akserver]]
  }
  handle_prev $f $prev_akserver $prev_akserver_remote
}

proc handle_prev {f akserver akserver_remote} {
  global ar_nodes
  if {($akserver != "<none>") && ($akserver_remote != "<none>")} {
    set nmisses [det_misses]
    puts $f [edge_stmt $ar_nodes($akserver) $ar_nodes($akserver_remote) label "T[det_total] / M$nmisses" color [det_color $nmisses]]
  }
}

proc det_total {} {
  global aantallen
  set total 0
  foreach k [array names aantallen] {
    incr total $aantallen($k) 
  }
  return $total
}

proc det_hits {} {
  global aantallen
  set total 0
  foreach k {TCP_HIT TCP_MEM_HIT} {
    incr total $aantallen($k) 
  }
  return $total
}

proc det_misses {} {
  global aantallen
  set total 0
  foreach k {TCP_MISS TCP_REFRESH_MISS} {
    incr total $aantallen($k) 
  }
  return $total
}

proc det_color {nmisses} {
  # doetniet: expr $nmisses == 0 ? "black" : "red"
  if {$nmisses == 0} {
    return "black" 
  } else {
    return "red"
  }
}

proc find_db {db_dir} {  
  lindex [glob -directory $db_dir "*.db"] 0 
}

proc query_only_remote {} {
  global only_remote
  if {$only_remote} {
    return "and cachetype_remote is not null"
  } else {
    return "" 
  }
}

main $argv

