# package require TclOO zou nu niet meer nodig moeten zijn.
# 5-5-2016 TODO: deze sowieso ook op Windows nog testen.

package require Tclx;           # for (set) union.

oo::class create ssl_session_conn {

  # 2 dicts:
  variable ssl_info sess_info db logfile_id vuserid iteration functypes

  constructor {a_db} {
    set db $a_db
    my define_tables
    set ssl_info [dict create]
    set sess_info [dict create]
    my define_functypes
    log debug "ssl_session_conn object created"
  }

  # destructor has no args/params
  destructor {
    unset ssl_info
    unset sess_info
    log debug "ssl_session_conn object destroyed"
  }

  method sub {topic value} {
    if {$topic == "iteration"} {
      set iteration $value
    }
  }
  
  # TODO: fkeys naar ssl_session en conn_block later nog. Of op natuurlijke sleutels?
  method define_tables {} {
    $db add_tabledef ssl_conn_block {id} {logfile_id {min_linenr int} {max_linenr int}
      {iteration_start int} {iteration_end int} sess_id
      sess_address ssl ctx domain_port estab_global_linenrs {isglobal int}}
  }
  
  method bof {plogfile_id pvuserid piteration} {
    set logfile_id $plogfile_id
    set vuserid $pvuserid
    set iteration $piteration
  }

  method eof {plogfile_id piteration} {
    if {$plogfile_id != $logfile_id} {
      error "logfile_id at eof ($plogfile_id) differs from bof ($logfile_id)"
    }
    dict for {k v} $ssl_info {
      my insert_ssl $v
    }
  }

  method entry {entry_type it linenr_start linenr_end lines} {
    if {$entry_type != "ssl"} {
      return
    }
    log debug "oo:handling entry: $entry_type"
    set entry [join $lines "\n"]
    set functype [my det_functype $entry]
    #lassign [my det_entry_vars $entry] domain_port ssl ctx sess_address \
    #    sess_id socket conn_nr
    set dentry [my det_entry_dict $entry]
    log debug "oo:dentry: $dentry"
    set ssl [:ssl $dentry]
    set dssl [dict_get $ssl_info $ssl]
    if {$functype == "new_ssl"} {
      log debug "oo:handling newssl"
      # niet huidige afbreken, kunnen parallel zijn.
      # wel nieuwe maken voor in dict
      if {$dssl != {}} {
        # blijkbaar nog een oude, deze wegschrijven en verwijderen.
        log warn "oo:newssl entry ($linenr_start, $ssl) while already know this ssl: insert and start anew"
        my insert_ssl $dssl
      }
      my init_dssl $dentry $linenr_start $linenr_end
    } elseif {$functype == "freeing_global_ssl"} {
      # TODO: obv session_id kijken of er nog ssl-entries zijn, en deze dan afsluiten.
      log debug "oo:TODO handle freeing global ssl"
    } else {
      # zou al in dict te vinden moeten zijn
      if {$dssl == {}} {
        if {$ssl != ""} {
          log warn "oo:got non-newssl entry, but cannot find info ($linenr_start, $ssl)"
        } else {
          log debug "oo: no ssl field in line: ignore: entry"
          # no ssl field in line, ignore for now.
        }
      } else {
        # ssl found, check sess_id
        set apnd 0
        if {[:sess_id $dssl] == ""} {
          set apnd 1
        } elseif {[:sess_id $dentry] == ""} {
          set apnd 1
        } elseif {[:sess_id $dentry] == [:sess_id $dssl]} {
          set apnd 1
        } else {
          # new session_id: insert this one and start a new one.
          log debug "oo:new session id: insert old and start anew"
          my insert_ssl $dssl
          my init_dssl $dentry $linenr_start $linenr_end          
        }
        if {$apnd} {
          log debug "oo:appending info: $dssl with $dentry"
          # ok, add session info to current record
          # set dssl [dict_merge_append $dssl $dentry]
          set dssl [dict_merge_fn union $dssl $dentry]
          # also set last linenr etc.
          dict set dssl max_linenr $linenr_end
          dict set ssl_info $ssl $dssl
        }
      }
    }
  }
  
  method det_entry_dict {entry} {
    # TODO: deze regexp's nu overgenomen uit handle_entry_ssl, dus dubbel.
    # TODO: check for isglobal?
    setvars {domain_port ssl ctx sess_address sess_id socket conn_nr} ""
    regexp {, connection=([^, ]+),} $entry z domain_port
    regexp {SSL=([0-9A-F]+)} $entry z ssl
    regexp {ctx=([0-9A-F]+)} $entry z ctx
    regexp {session address=([0-9A-F]+)} $entry z sess_address
    regexp {ID \(length \d+\): ([0-9A-F]+)} $entry z sess_id
    regexp {session id: \(length \d+\): ([0-9A-F]+)} $entry z sess_id
    regexp {socket=([A-Fa-f0-9]+) \[(\d+)\]} $entry z socket conn_nr
    # list $domain_port $ssl $ctx $sess_address $sess_id $socket $conn_nr
    vars_to_dict domain_port ssl ctx sess_address sess_id socket conn_nr
  }

  method init_dssl {dentry linenr_start linenr_end} {
    set dssl $dentry
    dict set dssl min_linenr $linenr_start
    dict set dssl max_linenr $linenr_end
    dict set dssl iteration_start $iteration
    dict set dssl iteration_end $iteration
    dict set ssl_info [:ssl $dentry] $dssl    
    return $dssl
  }

  # write ssl record to db, remove from 'global' list
  method insert_ssl {dssl} {
    log debug "inserting ssl_conn_block: $dssl"
    my assert_dssl $dssl
    dict set dssl logfile_id $logfile_id
    dict set dssl iteration_end $iteration
    $db insert ssl_conn_block $dssl
    dict unset ssl_info [:ssl $dssl]
  }

  method assert_dssl {dssl} {
    if {[:# [:sess_id $dssl]] > 1} {
      error "More than one sess_id in dssl: $dssl"
    }
  }
  
  method define_functypes {} {
    set functypes {
      "Closed connection" closed_conn
      "Closing connection" closing_conn
      "Already connected" already_conn
      "Request done" req_done
      "SSL protocol error" ssl_protocol_error
      "Connected socket" connected_socket
      "Connecting" connecting
      "Re-negotiating https connection" renegotiating_https_conn
      "web_set_option" web_set_option
      "web_set_certificate_ex" web_set_certificate_ex
      "ssl_handle_status encounter error" ssl_handle_status_error
  
      "New SSL" new_ssl
      "Received callback about handshake completion" cb_handshake_completion
      "certificate error" cert_error
      "Handshake complete" handshake_complete

      "=== Established checken voor considering, deze staan in dezelfde entry ===" __dummy__
      "Established a global SSL session" established_global_ssl
      "Considering establishing the above as a new global SSL session" consider_global_ssl
  
      "Successful attempt to establish the reuse of the global SSL session" success_establish_reuse_global_ssl
      "Freeing the global SSL session in a callback" freeing_global_ssl
      "Connection information" conn_info

      "error" error  
    }
  }
  
  method det_functype {entry} {
    foreach {re ft} $functypes {
      if {[regexp $re $entry]} {
        return $ft
      }
    }
    return "unknown"

    
  }
}
