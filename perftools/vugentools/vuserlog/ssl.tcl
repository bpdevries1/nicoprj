# functions to read SSL specific parts in log db.

proc handle_ssl_start {db logfile_id vuserid iteration} {
  global entry_type lines linenr_start linenr_end
  set entry_type "start"
  set lines {}
  set linenr_start -1
  set linenr_end -1
  
  handle_bio_block_bof $db $logfile_id $vuserid $iteration
  handle_func_block_bof $db $logfile_id $vuserid $iteration
}

proc handle_ssl_line {db logfile_id vuserid iteration line linenr} {
  global entry_type lines linenr_start linenr_end
  if {$line == "BIO\[02EAE778\]:Free - socket"} {
    log info "Free without src/line found"
    # breakpoint
  }
  set tp [line_type $line]
  if {$tp == "cont"} {
    lappend lines $line
    set linenr_end $linenr
  } else {
    handle_entry_${entry_type} $db $logfile_id $vuserid $iteration $linenr_start $linenr_end $lines
    set entry_type $tp
    set lines [list $line]
    set linenr_start $linenr
    set linenr_end $linenr
  }
}

# called when end-of-file reached.
proc handle_ssl_end {db logfile_id vuserid iteration} {
  global entry_type lines linenr_start linenr_end
  handle_entry_${entry_type} $db $logfile_id $vuserid $iteration $linenr_start $linenr_end $lines
  handle_bio_block_eof $db $logfile_id $vuserid $iteration
  handle_func_block_eof $db $logfile_id $vuserid $iteration
  create_extra_tables $db
  do_checks $db
}

proc line_type {line} {
  # Login_cert_main.c(81): [SSL:] Handsh
  # NOTE: source/linenr is optional (with ?) in next RE:
  if {[regexp {^([A-Za-z_0-9]+\.c\(\d+\): )?(.*)$} $line z src rest]} {
    if {$rest == ""} {
      # TODO: maybe need to look at next line.
      return "ssl"
    } elseif {[regexp {^    } $rest]} {
      return "cont"
    } elseif {[regexp {BIO\[[0-9A-F]+\]} $rest]} {
      # BIO[031CE708]:
      if {[regexp {return} $rest]} {
        return "cont"
      } else {
        return "bio"  
      }
    } elseif {[regexp {\[SSL:\]} $rest]} {
      # Login_cert_main.c(81): [SSL:] Handshake complete, ...
      return "ssl"
    } else {
      if {$src != ""} {
        return "func"  
      } else {
        # no source/line, some at end of log, to close/clean up things.  
        if {[regexp {^t=\d+ms: } $rest]} {
          return "func"
        } else {
          return "cont"
        }
      }
    }
  } else {
    return "cont"
  }
}


proc handle_entry_start {db logfile_id vuserid iteration linenr_start linenr_end lines} {
  log debug "Before first line, do nothing"
}

proc handle_entry_bio {db logfile_id vuserid iteration linenr_start linenr_end lines} {
  log debug "handle_entry_bio ($linenr_start -> $linenr_end): [join $lines "\n"]"
  set entry [join $lines "\n"]
  setvars {address call socket_fd result} ""
  set functype [det_functype $entry]
  if {[regexp {return} $entry]} {
    set functype "${functype}_return"
  }
  regexp {BIO\[([A-F0-9]+)\]: ?([^\n]*)} $entry z address call
  if {$call == ""} {
    log warn "call is empty in entry: $entry"
    breakpoint
  }
  regexp {return ([0-9-]+)} $entry z result
  regexp {socket fd=(\S+)} $call z socket_fd
  
    # BIO[02E3B560]:read(616,3628) - socket fd=616
  $db insert bio_entry [vars_to_dict logfile_id vuserid iteration linenr_start linenr_end entry functype address socket_fd call result]

  handle_bio_block $db $logfile_id $vuserid $iteration $linenr_start $linenr_end $functype $address $socket_fd
}

# bio_info: dict: key=address, val=dict: linenr_start, socket_fd
# $db add_tabledef bio_block {id} {logfile_id vuserid iteration linenr_start linenr_end address socket_fd}
proc handle_bio_block {db logfile_id vuserid iteration linenr_start linenr_end functype address socket_fd} {
  global bio_info
  if {$functype == "free"} {
    set d [dict get $bio_info $address]
    set linenr_start [dict get $d linenr_start]
    set socket_fd [dict get $d socket_fd]
    set iteration_start [dict get $d iteration_start]
    set iteration_end $iteration
    $db insert bio_block [vars_to_dict logfile_id vuserid iteration_start iteration_end linenr_start linenr_end address socket_fd]
    dict unset bio_info $address
  } else {
    set d [dict_get $bio_info $address]
    dict_set_if_empty d iteration_start $iteration 0
    dict_set_if_empty d linenr_start $linenr_start 0
    dict_set_if_empty d socket_fd $socket_fd
    dict set bio_info $address $d
  }
}

proc handle_bio_block_bof {db logfile_id vuserid iteration} {
  global bio_info
  set bio_info [dict create]
}

proc handle_bio_block_eof {db logfile_id vuserid iteration} {
  global bio_info
  set keys [dict keys $bio_info]
  if {$keys != {}} {
    log error "bio_info keys not empty at the end: (logfile_id=$logfile_id) $keys"
    error "bio_info keys not empty at the end: (logfile_id=$logfile_id) $keys"
  }
}

proc handle_entry_ssl {db logfile_id vuserid iteration linenr_start linenr_end lines} {
  log debug "handle_entry_ssl ($linenr_start -> $linenr_end): [join $lines "\n"]"
  set entry [join $lines "\n"]
  # Login_cert_main.c(81): [SSL:] Received callback about handshake completion, connection=securepat01.rabobank.com:443, SSL=02E54F78, ctx=02E31280, not reused, session address=02E55F58, ID (length 32): B1C73633E1EBBF558DAB080255A0E0A744DF4114C8BDD7F31500741187BDFB6E  	[MsgId: MMSG-26000]
  # Login_cert_main.c(81): [SSL:] New SSL, socket=03135208 [0], connection=securepat01.rabobank.com:443, SSL=0315ADE0, ctx=03151280, not reused, no session  	[MsgId: MMSG-26000]
  setvars {domain_port ssl ctx sess_address sess_id socket conn_nr} ""
  set functype [det_functype $entry]
  regexp {, connection=([^, ]+),} $entry z domain_port
  regexp {SSL=([0-9A-F]+)} $entry z ssl
  regexp {ctx=([0-9A-F]+)} $entry z ctx
  regexp {session address=([0-9A-F]+)} $entry z sess_address
  regexp {ID \(length \d+\): ([0-9A-F]+)} $entry z sess_id
  # session id: (length 32): 406AACA4B82125794114DDFBCCFD50BA767B15584C559340099FAB126B9F8AF3
  regexp {session id: \(length \d+\): ([0-9A-F]+)} $entry z sess_id
  regexp {socket=([A-Fa-f0-9]+) \[(\d+)\]} $entry z socket conn_nr
  
  $db insert ssl_entry [vars_to_dict logfile_id vuserid iteration linenr_start linenr_end entry functype domain_port ssl ctx sess_address sess_id socket conn_nr]
}

proc handle_entry_func {db logfile_id vuserid iteration linenr_start linenr_end lines} {
  log debug "handle_entry_func ($linenr_start -> $linenr_end): [join $lines "\n"]"
  set entry [join $lines "\n"]
  # Login_cert_main.c(81): t=8108ms: Already connected [1] to securepat01.rabobank.com:443  	[MsgId: MMSG-26000]
  # Logout.c(11): t=15974ms: Closed connection [5] to securepat01.rabobank.com:443 after completing 4 requests  	[MsgId: MMSG-26000]
  # Logout.c(11): t=16029ms: 1605-byte request headers for "https://securepat01.rabobank.com/cras/js/5/app.js" (RelFrameId=, Internal ID=50)
  # Login_cert_main.c(81): t=8855ms: 1207-byte response headers for "https://securepat01.rabobank.com/wps/myportal/rcc/!ut/p/a1/04_Sj9CPykssy0xPLMnMz0vMAfGjzOLNHL0dDZ28DbzdA80MDBx9Xb2dLUycjfyczIEKIoEKDHAARwNC-gtyQxUBGNo-Qw!!/dl5/d5/L2dBISEvZ0FBIS9nQSEh/pw/Z7_6AKA1BK0KGQ600AMEKC84C2N70/res/id=externalRatesCss/c=cacheLevelPage/=/" (RelFrameId=, Internal ID=8)
  #Login_cert_main.c(81): t=15869ms: Connecting [0] to host 85.119.19.235:443  	[MsgId: MMSG-26000]
  #Login_cert_main.c(81): t=15875ms: Connected socket [0] from 185.31.145.210:9570 to 85.119.19.235:443 in 6 ms  	[MsgId: MMSG-26000]
  setvars {functype ts_msec url domain_port ip_port conn_nr nreqs relframe_id internal_id conn_msec http_code} ""
  set functype [det_functype $entry]
  # RCC_Open.c(90): t=9904ms: Request done
  regexp {t=(\d+)ms: } $entry z ts_msec

  # Login_cert_main.c(81): t=5097ms: Connecting [0] to host 85.119.19.235:443  	[MsgId: MMSG-26000]
  regexp {Connecting \[(\d+)\] to host (\S+)} $entry z conn_nr ip_port
  #   Login_cert_main.c(81): t=5152ms: Connected socket [1] from 185.31.145.200:26919 to 85.119.19.235:443 in 5 ms  	[MsgId: MMSG-26000]
  regexp {Connected socket \[(\d+)\] from .* to (\S+) in (\d+) ms} $entry z conn_nr ip_port conn_msec
  regexp {Already connected \[(\d+)\] to (\S+)} $entry z conn_nr domain_port
  # Login_cert_main.c(81): t=5146ms: Closing connection [0] to server securepat01.rabobank.com - server indicated that the connection should be closed  	[MsgId: MMSG-26000]
  regexp {Closing connection \[(\d+)\] to server (\S+)} $entry z conn_nr domain_port
  regexp {Closed connection \[(\d+)\] to (\S+) after completing (\d+) request} $entry z conn_nr domain_port nreqs
  # t=65815ms: Closed connection [2] to securepat01.rabobank.com:443 after completing 1 request  	[MsgId: MMSG-26000]
  
  regexp {Re-negotiating https connection \[(\d+)\] to ([^,]+),} $entry z conn_nr domain_port
  
  regexp {request headers for "([^""]+)" \(RelFrameId=(.*), Internal ID=(\d+)\)} $entry z url relframe_id internal_id
  regexp {response headers for "([^""]+)" \(RelFrameId=(.*), Internal ID=(\d+)\)} $entry z url relframe_id internal_id
  # Login_cert_main.c(81): t=8697ms: Request done "https://cdnpat.rabobank.com/app/dl2/1.15.0/styles/app.css"  	[MsgId: MMSG-26000]
  regexp {Request done "([^""]+)"} $entry z url

  # RCC_Open.c(238):     HTTP/1.1 200 OK\r\n
  # Login_cert_main.c(81):     HTTP/1.0 302 Found\r\n
  regexp {(HTTP/1\.\d \d\d\d [^\\]+)\\} $entry z http_code
  if {($functype == "resp_headers") && ($http_code == "")} {
    log warn "Empty http code in resp_headers"
    breakpoint
  }
  if {($domain_port == "") && ($url != "")} {
    regexp {https://([^/]+)} $url z domain
    set domain_port "$domain:443"
  }
  # add 443 to domain_port if needed
  if {($domain_port != "") && ![regexp {:} $domain_port]} {
    set domain_port "$domain_port:443"
  }
  $db insert func_entry [vars_to_dict logfile_id vuserid iteration linenr_start linenr_end entry functype ts_msec url \
                             domain_port ip_port conn_nr nreqs relframe_id internal_id  conn_msec http_code]
  handle_func_block $db $logfile_id $vuserid $iteration $linenr_start $linenr_end $ts_msec $functype $conn_nr $conn_msec \
      $domain_port $ip_port $nreqs $url $http_code
}

proc handle_func_block {db logfile_id vuserid iteration linenr_start linenr_end ts_msec functype conn_nr conn_msec domain_port ip_port nreqs url http_code} {
  global conn_info req_info

  if {$conn_nr != ""} {
    set d [dict_get $conn_info $conn_nr]    
    if {$functype == "closed_conn"} {
      if {$d == {}} {
        log warn "Empty dict for closed_conn: logfile_id = $logfile_id, linenr=$linenr_start, conn_nr=$conn_nr"
        error "Stop now"
      }
      set linenr_start [:linenr_start $d]
      set iteration_start [:iteration_start $d]
      set iteration_end $iteration
      set conn_msec [:conn_msec $d]
      set domain_port [:domain_port $d]
      set ip_port [:ip_port $d]
      set ts_msec_end $ts_msec
      set ts_msec_start [:ts_msec_start $d]
      set ts_msec_diff [expr $ts_msec_end - $ts_msec_start]
      $db insert conn_block [vars_to_dict logfile_id vuserid iteration_start iteration_end linenr_start linenr_end ts_msec_start ts_msec_end ts_msec_diff conn_nr conn_msec domain_port ip_port nreqs]
      dict unset conn_info $conn_nr
    } else {
      dict_set_if_empty d iteration_start $iteration 0
      dict_set_if_empty d linenr_start $linenr_start 0
      dict_set_if_empty d ts_msec_start $ts_msec 0
      dict_set_if_empty d conn_msec $conn_msec
      dict_set_if_empty d domain_port $domain_port
      dict_set_if_empty d ip_port $ip_port
      dict_set_if_empty d nreqs $nreqs
      dict set conn_info $conn_nr $d
    }
  } elseif {$url != ""} {
    #   $db add_tabledef req_block {id} {logfile_id vuserid iteration_start iteration_end linenr_start linenr_end url domain_port nentries}
    set d [dict_get $req_info $url]
    dict incr d nentries
    dict_set_if_empty d http_code $http_code    
    if {$functype == "req_done"} {
      set linenr_start [:linenr_start $d]
      set iteration_start [:iteration_start $d]
      set iteration_end $iteration
      set nentries [:nentries $d]
      set ts_msec_end $ts_msec
      set ts_msec_start [:ts_msec_start $d]
      set ts_msec_diff [expr $ts_msec_end - $ts_msec_start]
      set http_code [:http_code $d]
      $db insert req_block [vars_to_dict logfile_id vuserid iteration_start iteration_end linenr_start linenr_end ts_msec_start ts_msec_end ts_msec_diff url domain_port nentries http_code]
      dict unset req_info $url
    } else {
      dict_set_if_empty d iteration_start $iteration 0
      dict_set_if_empty d linenr_start $linenr_start 0
      dict_set_if_empty d ts_msec_start $ts_msec 0
      dict set req_info $url $d
    }
  } else {
    # not a connection or request related call
    return
  }
}

proc handle_func_block_bof {db logfile_id vuserid iteration} {
  global conn_info req_info
  set conn_info [dict create]
  set req_info [dict create]
}

proc handle_func_block_eof {db logfile_id vuserid iteration} {
  global conn_info req_info
  set keys [dict keys $conn_info]
  if {$keys != {}} {
    log error "conn_info keys not empty at the end: (logfile_id=$logfile_id) $keys"
    error "conn_info keys not empty at the end: (logfile_id=$logfile_id) $keys"
  }
  set keys [dict keys $req_info]
  if {$keys != {}} {
    log error "req_info keys not empty at the end: (logfile_id=$logfile_id) $keys"
    error "req_info keys not empty at the end: (logfile_id=$logfile_id) $keys"
  }
}

set functypes {
  "Closed connection" closed_conn
  "Closing connection" closing_conn
  "Already connected" already_conn
  "request headers" req_headers
  "response headers" resp_headers
  "Found resource" found_resource
  "Parameter Substitution" par_subst
  "Request done" req_done
  "SSL protocol error" ssl_protocol_error
  "web_global_verification" web_global_verification
  "web_set_sockets_option" web_set_sockets_option
  "Maximum number of open connections" max_nr_open_conn
  "web_add_auto_filter" web_add_auto_filter
  "web_add_auto_header" web_add_auto_header
  "registered for adding to requests" registered_adding_requests
  "Connected socket" connected_socket
  "Connecting" connecting
  "Re-negotiating https connection" renegotiating_https_conn
  "web_set_option" web_set_option
  web_add_header web_add_header
  web_reg_find web_reg_find
  "No match found for the requested parameter" no_match_found
  "Saving Parameter" saving_parameter
  "web_set_certificate_ex" web_set_certificate_ex
  "Redirecting" redirecting
  "To location" to_location
  "Changing TCPIP buffer size" changing_tcpip_buffer_size
  "web_url" web_url
  "header registered" header_registered
  "web_concurrent_" web_concurrent
  "ssl_handle_status encounter error" ssl_handle_status_error

  "web_reg_save_param" web_reg_save_param
  "Request.*failed" req_failed
  "Transaction.*Fail" trans_failed

  "vuser_init\.c" vuser_init_c
  "functions\.c" functions_c
  "configfile\.c" configfile_c
  "dynatrace\.c" dynatrace_c
  
  "New SSL" new_ssl
  "Received callback about handshake completion" cb_handshake_completion
  "certificate error" cert_error
  "Handshake complete" handshake_complete
  "Considering establishing the above as a new global SSL session" consider_global_ssl
  "Established a global SSL session" established_global_ssl
  "Successful attempt to establish the reuse of the global SSL session" success_establish_reuse_global_ssl
  "Freeing the global SSL session in a callback" freeing_global_ssl
  "Connection information" conn_info
  
  write write
  read read
  ctrl ctrl
  "Free - socket" free

  "error" error  
}

proc det_functype {entry} {
  global functypes
  foreach {re ft} $functypes {
    if {[regexp $re $entry]} {
      return $ft
    }
  }
  return "unknown"
}

proc create_extra_tables {db} {
  $db exec "drop table if exists conn_bio_block"
  $db exec "create table conn_bio_block (bio_block_id, conn_block_id, reason)"
  $db exec "insert into conn_bio_block
select b.id, c.id, 'linenr_end 1 diff'
from bio_block b, conn_block c
where b.logfile_id = c.logfile_id
and b.linenr_end + 1 = c.linenr_end"
 
}

proc do_checks {db} {
  log info "Doing checks..."
  set have_warnings 0
  do_check "BIO blocks without corresponding conn_block" \
      "select * from bio_block where not id in (select bio_block_id from conn_bio_block)"
  do_check "Conn blocks without corresponding BIO block" \
      "select * from conn_block where not id in (select conn_block_id from conn_bio_block)"
  # in theorie ook nog kijken of dingen niet dubbel voorkomen, alleen kan bij deze niet.
  
  # even een om te testen
  # do_check "testje" "select * from conn_block where id = 1"
  
  if {$have_warnings} {
    log warn "**************************************"
    log warn "*** Some warnings, do investigate! ***"
    log warn "**************************************"
  } else {
    log info "Everything seems fine."
  }
}

proc do_check {msg sql} {
  upvar have_warnings have_warnings
  upvar db db
  set res [$db query $sql]
  if {[:# $res] > 0} {
    log warn "$msg:"
    log warn $res
    log warn "--------"
    set have_warnings 1    
  }
}

# TODO: source and sourceline: # Login_cert_main.c(81): [SSL:] Handsh
proc ssl_define_tables {db} {
  # iteration can be 'vuser_end', so not an integer.
  # TODO: $db set_default_type nothing|as_same
  #       as_same: als een veld geen datatype heeft, en eerdere def met dezelfde naam wel, neem deze dan over. Dan bv maar 1x bij linenr_start integer op te geven.
  # evt dan ook een def_datatype <col> <datatype> opnemen, zodat je dit vantevoren kunt
  # doen, evt ook met regexp's.
  $db add_tabledef bio_entry {id} {logfile_id {vuserid integer} iteration {linenr_start integer} {linenr_end integer} entry functype address socket_fd call result}
  # TODO: andere dingen in SSL line
  $db add_tabledef ssl_entry {id} {logfile_id {vuserid integer} iteration {linenr_start integer} {linenr_end integer} entry functype domain_port ssl ctx sess_address sess_id socket {conn_nr integer}}
  $db add_tabledef func_entry {id} {logfile_id {vuserid integer} iteration {linenr_start integer} {linenr_end integer} entry functype {ts_msec integer} url domain_port ip_port {conn_nr integer} {nreqs integer} {relframe_id integer} {internal_id integer} {conn_msec integer} http_code}

  $db add_tabledef bio_block {id} {logfile_id {vuserid integer} iteration_start iteration_end {linenr_start integer} {linenr_end integer} address socket_fd}
  $db add_tabledef conn_block {id} {logfile_id {vuserid integer} iteration_start iteration_end {linenr_start integer} {linenr_end integer} {ts_msec_start integer} {ts_msec_end integer} {ts_msec_diff integer} {conn_nr integer} {conn_msec integer} domain_port ip_port {nreqs integer}}
  $db add_tabledef req_block {id} {logfile_id {vuserid integer} iteration_start iteration_end {linenr_start integer} {linenr_end integer} {ts_msec_start integer} {ts_msec_end integer} {ts_msec_diff integer} url domain_port nentries http_code}
  
}

# library functions:

# check if new val is different form old var, but both not empty: this could be an error!
proc dict_set_if_empty {d_name key val {check 1}} {
  upvar $d_name d
  set old_val [dict_get $d $key]
  if {$old_val == ""} {
    dict set d $key $val
  } elseif {$old_val == $val} {
    # ok, still the same
  } elseif {$val == ""} {
    # ok, just keep old val.
  } else {
    if {$check} {
      error "old val ($old_val) differs from new val ($val), key=$key, dict=$d"  
    } else {
      # explicitly set to no check, eg with line numbers.
    }
  }
}

proc setvars {lst val} {
  foreach el $lst {
    upvar $el $el
    set $el $val
  }
}

