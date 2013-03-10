#!/home/nico/bin/tclsh

# 23-2-2013 NdV waarsch deze om ratings uit amarok te halen en in music-db te zetten.
# werkte nog op amarok, heb nu amarok2, dus oud.

package require ndv
package require Tclx
# package require struct::list

::ndv::source_once ../db/MusicSchemaDef.tcl

# set log [::ndv::CLogger::new_logger [file tail [info script]] debug]
set log [::ndv::CLogger::new_logger [file tail [info script]] info]

proc main {argc argv} {
  global log db conn stderr argv0 SINGLES_ON_SD
	$log info "Starting"

  set options {
    {dummy.arg "dummy" "Dummy argument"}
  }
  set usage ": [file tail [info script]] \[options] :"
  array set ar_argv [::cmdline::getoptions argv $options $usage]

  set schemadef [MusicSchemaDef::new]
  set db [::ndv::CDatabase::get_database $schemadef]
  set conn [$db get_connection]

  ::mysql::exec $conn "set names utf8"

  set lst [get_amarok_rating]
  foreach el $lst {
    # ::struct::list assign $el url rating
    lassign $el url rating
    $log debug "$rating: $url"
    if {1} {
      set query "update generic set freq = [expr $rating / 2.0] where id = (
        select generic
        from musicfile
        where path='[$db str_to_db [url_to_path $url]]'
      )"
    } else {
      set query "update generic set freq = 10 where id = (
        select generic
        from musicfile
        where path='[$db str_to_db [url_to_path $url]]'
      )"
    }
    set res [::mysql::exec $conn $query]
    # @todo evt res kan ongelijk 1 zijn als er in de waarde niets verandert, of als het record niet bestaat.
    if {$res != 1} {
      $log info "$rating: $url"
      $log warn "res: $res"
      # break
    }
    $log debug "exec-res: $res"
    # break ; # test
  }
  
}

proc get_amarok_rating {} {
  set conn [::mysql::connect -host localhost -user QQQ \
    -password "qqq" -db amarok]
  set query "select url, rating from statistics where rating >0 and url like '%Singles%'"
  set result [::mysql::sel $conn $query -list]
  ::mysql::close $conn
  return $result
}

# hoef alleen de ./ aan het begin eraf te halen.
proc url_to_path {url} {
  return [string range $url 2 end] 
}

main $argc $argv

