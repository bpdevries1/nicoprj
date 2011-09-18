package require ndv
package require http
package require htmlparse
package require struct::tree
package require struct::list
package require Tclx

::ndv::source_once ScheidsSchemaDef.tcl

proc main {} {
  global db

  set schemadef [ScheidsSchemaDef::new]
  $schemadef set_db_name_user_password scheids nico "pclip01;"
  set db [::ndv::CDatabase::get_database $schemadef]


  set query "select p.naam, z0.factor zf0, z0.opmerkingen zo0, z1.factor zf1, z1.opmerkingen z1o
             from persoon p 
             left join zeurfactor z0 on z0.persoon = p.id
             left join zeurfactor z1 on z1.persoon = p.id
             where z0.speelt_zelfde_dag = 0
             and z1.speelt_zelfde_dag = 1
             order by p.naam"
  set conn [$db get_connection]
  set res [::mysql::sel $conn $query -list]
  set f [open zeurfactor.tsv w]
  puts $f [join [list persoon zf0 opm0 zf1 opm1] "\t"]
  foreach el $res {
    puts $f [join $el "\t"]
  }
  close $f             
}

main
