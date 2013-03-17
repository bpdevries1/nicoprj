#!/home/nico/bin/tclsh8.6

# koppel top2000.txt aan tracks.

package require tdbc::sqlite3
package require ndv

source ../lib/libmusic.tcl

set log [::ndv::CLogger::new_logger [file tail [info script]] debug]

proc main {argv} {
  lassign $argv db_name
  set conn [open_db $db_name]
  db_eval $conn "create table if not exists koppeltext (track_id, text_id, status)"  
  set stmts(insert) [$conn prepare "insert into koppeltext (track_id, text_id, status) values (:track_id, :text_id, :status)"]
  db_eval $conn "begin transaction"
  db_eval $conn "delete from koppeltext"
  db_eval $conn "insert into koppeltext (track_id, text_id, status)
                 select tr.id, tx.id, 'pos-artiest-titel'
                 from track tr, top2000text tx
                 where tr.positie*1 = tx.positie*1
                 and tr.path like '%' || tx.artiest || '%'
                 and tr.path like '%' || tx.titel || '%'"

  # als positie gelijk is en titel ook, dan ook goed.
  db_eval $conn "insert into koppeltext (track_id, text_id, status)
                 select tr.id, tx.id, 'pos-titel'
                 from track tr, top2000text tx
                 where tr.positie*1 = tx.positie*1
                 and not tr.path like '%' || tx.artiest || '%'
                 and tr.path like '%' || tx.titel || '%'"

  # als positie en artiest gelijk, dan waarsch ook goed.
  db_eval $conn "insert into koppeltext (track_id, text_id, status)
                 select tr.id, tx.id, 'pos-artiest'
                 from track tr, top2000text tx
                 where tr.positie*1 = tx.positie*1
                 and tr.path like '%' || tx.artiest || '%'
                 and not tr.path like '%' || tx.titel || '%'"
                 
  # als titel en artiest gelijk zijn, maar positie niet, dan toch goed, tenzij dubbel.
  db_eval $conn "insert into koppeltext (track_id, text_id, status)
                 select tr.id, tx.id, 'artiest-titel'
                 from track tr, top2000text tx
                 where not tr.positie*1 = tx.positie*1
                 and tr.path like '%' || tx.artiest || '%'
                 and tr.path like '%' || tx.titel || '%'"
  
  # check of er geen dubbele matches zijn, beide kanten op.
  # @todo nu wel dubbelen, dus te veel gematched: eerst printen wat precies, en ook de reden erbij.
  # @todo dan ook beter strategie te bepalen: eerste is beste, als alle 3 kloppen, maar welke dan?
  puts "Tracks with more than 1 matching entry in textfile:"
  foreach el [db_query $conn "select path, count(*) from track tr, koppeltext k
                              where k.track_id = tr.id
                              group by path
                              having count(*) > 1"] {
    puts $el
  }
  
  puts "Entry in textfile with more than one matching track:"
  foreach el [db_query $conn "select tx.positie, tx.artiest, tx.titel, count(*) from top2000text tx, koppeltext k
                              where k.text_id = tx.id
                              group by tx.positie, tx.artiest, tx.titel
                              having count(*) > 1"] {
    puts $el                              
  }                                

  puts "Number of matched items: [dict get [lindex [db_query $conn "select count(*) aantal from koppeltext"] 0] aantal]"
  
  db_eval $conn "commit"
  $conn close
}

proc open_db {db_name} {
  set conn [tdbc::sqlite3::connection create db $db_name]
  return $conn
}

proc db_eval {conn query {return_id 0}} {
  set stmt [$conn prepare $query]
  $stmt execute
  $stmt close
  if {$return_id} {
    return [[$conn getDBhandle] last_insert_rowid]   
  }
}

proc stmt_exec {conn stmt dct {return_id 0}} {
  $stmt execute $dct
  if {$return_id} {
    return [[$conn getDBhandle] last_insert_rowid]   
  }
}

# return resultset as list of dicts
proc db_query {conn query} {
  set stmt [$conn prepare $query]
  set rs [$stmt execute]
  set res [$rs allrows -as dicts]
  $rs close
  $stmt close
  return $res
}

main $argv
