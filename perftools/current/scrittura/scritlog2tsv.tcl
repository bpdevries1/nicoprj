# 2016-07-04 13:16:20,757 [[ACTIVE] ExecuteThread: '16' for queue: 'weblogic.kernel.Default (self-tuning)'] INFO  com.ipicorp.mvc.Controller  - In Controller.doPost() - Start of synchronized block : Remoteuser: utc_derv_tranoff1 --- 
#                                                                                                ThreadId: 82 --- SessionId: 8nS1n4HklKVNAzWqCD5zxqo4vn-0m0uxQGjScaOQBEEzCEMSY8Q1!-652425506!1467630977353

package require ndv

set_log_global info

proc main {} {
  set dir {C:\PCC\Nico\projecten-no-sync\scrittura\scrit-logs-2016-07-05-pat}
  set fo_xa [open [file join $dir xacache.tsv] w]
  set fo_sync [open [file join $dir sync.tsv] w]
  puts $fo_xa [join [list filename linenr ts threadname loglevel xa_loc transid caches_size] "\t"]
  puts $fo_sync [join [list filename linenr ts threadname loglevel dopost_loc remoteuser threadid sessionid] "\t"]
  foreach logfile [glob -directory $dir "scrittura.log.*"] {
    handle_log $logfile $fo_xa $fo_sync
  }

  close $fo_xa
  close $fo_sync
}

proc handle_log {logfile fo_xa fo_sync} {
  log info "Handling: $logfile"
  set fi [open $logfile r]
  set filename [file tail $logfile]
  set linenr 0
  while {[gets $fi line] >= 0} {
    incr linenr
    if {[regexp {^([^ ]+ [^ ]+) \[(.*)\] (INFO|WARN)  com.ipicorp.mvc.Controller  - (.*) : Remoteuser: ([^ ]+) --- ThreadId: (\d+) --- SessionId: (.*)$} $line z ts threadname loglevel dopost_loc remoteuser threadid sessionid]} {
      regsub -all "," $ts "." ts
      puts $fo_sync [join [list $filename $linenr $ts $threadname $loglevel $dopost_loc $remoteuser $threadid $sessionid] "\t"]
    } elseif {[regexp {^([^ ]+ [^ ]+) \[(.*)\] (INFO|WARN)  com.ipicorp.mvc.Controller  - (.*)$} $line z ts threadname loglevel rest]} {
      # maybe combine this with previous.
      regsub -all "," $ts "." ts
      puts $fo_sync [join [list $filename $linenr $ts $threadname $loglevel $rest "" "" ""] "\t"]
    } elseif {[regexp Controller $line]} {
      if {[regexp {^\s*at } $line]} {
        # ok, part of stacktrace
      } else {
        # [2016-07-06 15:53:19] nu eerst klaar met breakpoints
        # breakpoint  
      }
    } elseif {[regexp {^([^ ]+ [^ ]+) \[(.*)\] (INFO|WARN)  com.ipicorp.tools.cache.XACache  - (.*?)(caches.size\(\): (\d+))?$} $line z ts threadname loglevel xa_loc z caches_size]} {
      if {[regexp {^(.*)xid global-transactionid : (.*)$} $xa_loc xa_loc2 transid]} {
        set xa_loc $xa_loc2
      } else {
        set transid ""
      }
      regsub -all "," $ts "." ts
      puts $fo_xa [join [list $filename $linenr $ts $threadname $loglevel $xa_loc $transid $caches_size] "\t"]
    } elseif {[regexp {In XACache} $line]} {
      # [2016-07-06 15:53:19] nu eerst klaar met breakpoints
      # breakpoint
    }
    if {$linenr % 10000 == 0} {
      log info "line: $linenr"
    }
  }
  close $fi
}

proc main_old {} {
  set filename {C:\PCC\Nico\projecten-no-sync\scrittura\scrit-logs-2016-07-04-pat\dopost.txt}
  set tsvname "$filename.tsv"
  set fi [open $filename r]
  set fo [open $tsvname w]
  puts $fo [join [list ts threadname dopost_loc remoteuser threadid sessionid] "\t"]
  while {[gets $fi line] >= 0} {
	if {[regexp {^([^ ]+ [^ ]+) \[\[ACTIVE\] (.*) INFO  com.ipicorp.mvc.Controller  - (.*) : Remoteuser: ([^ ]+) --- ThreadId: (\d+) --- SessionId: (.*)$} $line z ts threadname dopost_loc remoteuser threadid sessionid]} {
		regsub -all "," $ts "." ts
		puts $fo [join [list $ts $threadname $dopost_loc $remoteuser $threadid $sessionid] "\t"]
	} elseif {[regexp Controller $line]} {
		breakpoint
	}
  }
  close $fi
  close $fo
}

main
