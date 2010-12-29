package require ndv
package require http
package require htmlparse
package require struct::tree
package require struct::list
package require Tclx

::ndv::source_once ScheidsSchemaDef.tcl

proc main {} {
  set schemadef [ScheidsSchemaDef::new]
  $schemadef set_db_name_user_password scheids nico "pclip01;"
  set db [::ndv::CDatabase::get_database $schemadef]
 
  set str [join [::mysql::sel [$db get_connection] "select email from persoon" -flatlist] "; "]
  puts "e-mails: $str"
  puts "Also put on clipboard"
  exec putclip.exe <<$str
}

main
