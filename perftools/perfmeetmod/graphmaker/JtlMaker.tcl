package require Itcl
package require ndv
package require Tclx
package require control

itcl::class JtlMaker {

	private common log
	# set log [::ndv::CLogger::new_logger [file tail [info script]] info]
	set log [::ndv::CLogger::new_logger [file tail [info script]] debug]

  # private common instance ""
  private common dhini
  # dat0 bepalen bij het ::ndv::source_oncen van de file, anders verkeerde dir
  set dhini [file normalize [file join [file dirname [info script]] dohtml.ini]]

  private common sample_options
  set sample_options {
    {elapsed.arg "" "Elapsed in msec"}
    {latency.arg "0" "Latency in msec"}
    {timestamp.arg "" "Timestamp (start!) in msec or yyyy-mm-dd hh:mm:ss.SSS or yyyymmddhhmmss.SSS (mysql-decimal)"}
    {success.arg "true" "Succesful sample?"}
    {label.arg "" "Label of sample, text or 0100_text"}
    {responsecode.arg "200" "HTTP Responsecode"}
    {responsemsg.arg "Success" "HTTP Response message"}
    {threadname.arg "" "Threadname or '01 Threadname 1-1'"}
    {threadnr.arg "1" "Used if threadname not like '01 Threadname 1-1'"}
    {bytes.arg "0" "Number of bytes in response"}
    {grpthreads.arg "1" "Number of threads in thread group"}
    {allthreads.arg "1" "Number of threads total"}
  }  
  
  private common PERL_BINARY d:/develop/perl/bin/perl.exe
  private common DOHTML_HOME d:/perftoolset/doHtml

  public proc new {} {
 		set instance [uplevel {namespace which [JtlMaker #auto]}]
    return $instance
  }
  
  private variable f
  private variable ar_threadgroups
  private variable next_threadgroup_nr
  private variable jtl_filename

  private constructor {} {
    set jtl_filename "<unknown>" 
  }
  
  public method open_file {filename} {
    $log info "Creating file: $filename"
    set jtl_filename $filename
    set f [open $filename w]
    puts_xml_header $f
    set next_threadgroup_nr 1
  }
  
  public method close_file {} {
    puts_xml_footer $f
    close $f
  }
  
  public method sample {args} {
		if {[llength $args] == 1} {
      set args [lindex $args 0] 
    }


    set usage ": sample \[options] :"
    array set ar [::cmdline::getoptions args $sample_options $usage]
    
    foreach {threadname label} [det_thread_label $ar(threadname) $ar(threadnr) $ar(label)] break
    
    # $log debug "Create list of lists"
    # set lst [list [list t $ar(elapsed)]]
    # backslashes achter de regels wel nodig, anders toch als losse statements gezien.
    set lst [list [list t $ar(elapsed)] \
                  [list lt $ar(latency)] \
                  [list ts [det_timestamp $ar(timestamp)]] \
                  [list s $ar(success)] \
                  [list lb $label] \
                  [list rc $ar(responsecode)] \
                  [list rm $ar(responsemsg)] \
                  [list tn $threadname] \
                  [list by $ar(bytes)] \
                  [list ng $ar(grpthreads)] \
                  [list na $ar(allthreads)]]
    
    #$log debug "List created: $lst" 
    
    # puts $f "<httpSample t=\"$ar(elapsed)\" lt=\"0\" ts=\"[det_timestamp $ar(timestamp)]\" s=\"$ar(success)\" lb=\"$label\" rc=\"$ar(responsecode)\" rm=\"$ar(responsemsg)\" tn=\"$threadname\" by=\"$ar(bytes)\" ng=\"$ar(grpthreads)\" na=\"$ar(allthreads)\"/>"
    puts $f "<httpSample [join [::struct::list mapfor el $lst {
      foreach {nm val} $el break
      format "%s=\"%s\"" $nm $val      
    }] " "]/>"

  }
  
  private method puts_xml_header {fo} {
     puts $fo "<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<testResults version=\"1.2\">"
  }
  
  private method puts_xml_footer {fo} {
    puts $fo "</testResults>"
  }  
 
  # @note met Pim besproken (5-3-2009): hij gebruikt de velden grpThreads en allThreads niet.
	# 25-3-09 NdV Pim gebruikt toch de start timestamp, dus ar_out(ts) vervangen door ar_in(ts)
  private method det_thread_label {threadname threadnr label} {
    if {[regexp {^[0-9]+ } $threadname]} {
      # already in the right format, assume label is in the right format too.
      return [list $threadname $label]
    } else {
      set threadgroup [det_threadgroup $threadname]
      if {$threadnr == ""} {set threadnr 1}
      set thread "[format %02d $threadgroup] $threadname $threadgroup-$threadnr"
      set label "[format %02d $threadgroup]00 $label"
      return [list $thread $label]
    }
  }  
  
  private method det_threadgroup {soort} {
    if {[array get ar_threadgroups $soort] == {}} {
      set ar_threadgroups($soort) $next_threadgroup_nr
      incr next_threadgroup_nr
    }
    return $ar_threadgroups($soort)
  }

  private method det_timestamp {timestamp} {
    $log debug "det_timestamp of: $timestamp"
    if {[string is double $timestamp]} {
      if {[regexp {^20} $timestamp]} {
        # mysql decimal format
        if {[regexp {^([0-9]+)(\.[0-9]+)?$} $timestamp z dt partsec]} {
          set sec [clock scan $dt -format "%Y%m%d%H%M%S"]
          $log debug "Returning (mysql decimal): [expr 1000.0 * "$sec$partsec"]"
          return [expr 1000.0 * "$sec$partsec"] 
        } else {
          error "Could not parse timestamp: $timestamp"
        }
      } else {
        $log debug "Returning: $timestamp"
        return $timestamp
      }
    } else {
      set partsec 0
      if {[regexp {^([^\.]+)(\.[0-9]+)?$} $timestamp z dt partsec]} {
        set sec [clock scan $dt -format "%Y-%m-%d %H:%M:%S"]
        $log debug "Returning: [expr 1000.0 * "$sec$partsec"]"
        return [expr 1000.0 * "$sec$partsec"] 
      } else {
        error "Could not parse timestamp: $timestamp" 
      }
    }
  }
  
  # @pre jtl_filename is gevuld, ofwel open_file is aangeroepen hiervoor
  public method call_dohtml {} {
    # global DOHTML_HOME PERL_BINARY log 
    ::control::assert {$jtl_filename != "<unknown>"} 
    set old_dir [pwd]
    cd ${DOHTML_HOME}
    #$log debug "datadir: $datadir"
    $log debug "dhini1: $dhini"
    if {0} {
      if {$dhini == ""} {
        set dhini ${datadir}/dohtml.ini
      }
    }
    $log debug "dhini2: $dhini"
    try_eval {
      set exec [list ${PERL_BINARY} -w ${DOHTML_HOME}/doHTML.pl -i ${dhini} -v -v -k -j -l UI testrun001 $jtl_filename]
      $log debug "exec: $exec"
      # exec ${PERL_BINARY} -w ${DOHTML_HOME}/doHTML.pl -i ${dhini} -v -v -k -j -l UI testrun001 $jtl_filename
      exec {*}$exec
    } {
      $log debug $errorResult 
    }
    cd $old_dir
  }
  
  public method move_to_output {output_dir} {
    # global DOHTML_HOME log
    # set output_dir [file join $datadir $output_dir]
    file delete -force $output_dir
    file mkdir $output_dir
    file rename [file join $DOHTML_HOME testrun001-UI.html] $output_dir
    file rename [file join $DOHTML_HOME HTMLTMP] $output_dir
    $log info "Moved output to: $output_dir"
  }
}

