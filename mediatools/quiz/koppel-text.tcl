#!/usr/bin/env tclsh86

# !/home/nico/bin/tclsh8.6

# koppel top2000.txt aan tracks.

package require tdbc::sqlite3
package require ndv

source ../lib/libmusic.tcl

set log [::ndv::CLogger::new_logger [file tail [info script]] debug]
set logfilename "[file tail [info script]].log" 
file delete $logfilename
$log set_file $logfilename

proc main {argv} {
  if {[llength $argv] > 0} {
    lassign $argv db_name
  } else {
    set db_name "/media/Iomega HDD/media/Music/Quiz/Top 2000 2012/top2000-2012.db" 
  }
  set conn [open_db $db_name]
  db_eval $conn "create table if not exists koppeltext (track_id, text_id, status)"  
  set stmts(insert) [$conn prepare "insert into koppeltext (track_id, text_id, status) values (:track_id, :text_id, :status)"]
  db_eval $conn "begin transaction"
  db_eval $conn "delete from koppeltext"
  
  # insert_manual $conn <track_id> <text_pos>
  # track.position can be duplicate
  insert_manual $conn 1294 1240
  insert_manual $conn 1295 1241
  
  
  set and_not_inserted_yet "and not exists (
        select 1 
        from koppeltext kt 
        where kt.track_id = tr.id
      )
      and not exists (
        select 1 
        from koppeltext kt 
        where kt.text_id = tx.id
      )"
  
  # eerst checken op positie, artiest en titel.
  db_eval $conn "insert into koppeltext (track_id, text_id, status)
                 select tr.id, tx.id, 'pos-artiest-titel'
                 from track tr, top2000text tx
                 where tr.positie*1 = tx.positie*1
                 and tr.path like '%' || tx.artiest || '%'
                 and tr.path like '%' || tx.titel || '%' 
                 $and_not_inserted_yet"

  # als positie gelijk is en titel ook, dan ook goed.
  db_eval $conn "insert into koppeltext (track_id, text_id, status)
                 select tr.id, tx.id, 'pos-titel'
                 from track tr, top2000text tx
                 where tr.positie*1 = tx.positie*1
                 and not tr.path like '%' || tx.artiest || '%'
                 and tr.path like '%' || tx.titel || '%'
                 $and_not_inserted_yet"

  # als positie en artiest gelijk, dan waarsch ook goed.
  db_eval $conn "insert into koppeltext (track_id, text_id, status)
                 select tr.id, tx.id, 'pos-artiest'
                 from track tr, top2000text tx
                 where tr.positie*1 = tx.positie*1
                 and tr.path like '%' || tx.artiest || '%'
                 and not tr.path like '%' || tx.titel || '%'
                 $and_not_inserted_yet"
                 
  # als titel en artiest gelijk zijn, maar positie niet, dan toch goed, tenzij dubbel.
  db_eval $conn "insert into koppeltext (track_id, text_id, status)
                 select tr.id, tx.id, 'artiest-titel'
                 from track tr, top2000text tx
                 where not tr.positie*1 = tx.positie*1
                 and tr.path like '%' || tx.artiest || '%'
                 and tr.path like '%' || tx.titel || '%'
                 $and_not_inserted_yet"
  
  # dan alleen matchen op positie
  db_eval $conn "insert into koppeltext (track_id, text_id, status)
                 select tr.id, tx.id, 'pos'
                 from track tr, top2000text tx
                 where tr.positie*1 = tx.positie*1
                 and not tr.path like '%' || tx.artiest || '%'
                 and not tr.path like '%' || tx.titel || '%'
                 $and_not_inserted_yet"
                 
  # check of er geen dubbele matches zijn, beide kanten op.
  # @todo nu wel dubbelen, dus te veel gematched: eerst printen wat precies, en ook de reden erbij.
  # @todo dan ook beter strategie te bepalen: eerste is beste, als alle 3 kloppen, maar welke dan?
  log info "Tracks with more than 1 matching entry in textfile:"
  log info "Should be none"
  foreach el [db_query $conn "select tr.id, path, count(*) from track tr, koppeltext k
                              where k.track_id = tr.id
                              group by path
                              having count(*) > 1
                              order by path"] {
    log info $el
  }

  log info "Tracks with no matching entry in textfile:"
  foreach el [db_query $conn "select tr.id, path
                              from track tr
                              where not exists (
                                select 1
                                from koppeltext k
                                where k.track_id = tr.id
                                )
                              order by path"] {
    log info $el                                
  }
   
  log info "Entries in textfile with more than one matching track:"
  foreach el [db_query $conn "select tx.id, tx.positie, tx.artiest, tx.titel, count(*) 
                              from top2000text tx, koppeltext k
                              where k.text_id = tx.id
                              group by tx.positie, tx.artiest, tx.titel
                              having count(*) > 1
                              order by tx.positie"] {
    log info $el
    set tx_id [dict get $el id]
    foreach el2 [db_query $conn "select tx.id tx_id, tx.positie, tx.artiest, tx.titel,
                                 tr.id tr_id, tr.path
                                 from top2000text tx, track tr, koppeltext k
                                 where tr.id = k.track_id
                                 and tx.id = k.text_id
                                 and tx.id = $tx_id"] {
      log info $el2                               
    }
  }                                
 
  log info "Entries in textfile with no matching track:"
  foreach el [db_query $conn "select tx.id, tx.positie, tx.artiest, tx.titel
                              from top2000text tx
                              where not exists (
                                select 1
                                from koppeltext k
                                where k.text_id = tx.id
                                )
                              order by tx.positie"] {
    log info $el                                
  }

  log_matches $conn "pos" "Track and titles only matched on position: check manually!"
  log_matches $conn "manual" "Track and titles matched manually: check!"
  
  log info "Number of matched items: [dict get [lindex [db_query $conn "select count(*) aantal from koppeltext"] 0] aantal]"
  
  # onderstaande werkt niet: hele directory moet ook goed gezet worden, gebaseerd op nieuwe positie: toch maar met tcl oplossen.
  # en ook orig (mp3) extensie van track gebruiken voor nieuwe filenaam, komt iet anders dan mp3 voor?
  #db_eval $conn "update track set path2 = (select tx.ariest || ' - ' || tx.titel from top2000text tx, koppeltext k where k.text_id = tx.id and k.track_id = track.id)"
  #db_eval $conn "alter table track add positie2"
  #db_eval $conn "update track set positie2 = (select tx.positie from top2000text tx, koppeltext k where k.text_id = tx.id and k.track_id = track.id)"
  
  db_eval $conn "commit"
  $conn close
}

proc log_matches {conn status text} {
  log info $text
  foreach el [db_query $conn "select tx.id, tx.positie, tx.artiest, tx.titel,
                              tr.id, tr.path
                              from top2000text tx, track tr, koppeltext k
                              where tr.id = k.track_id
                              and tx.id = k.text_id
                              and k.status='$status'
                              order by 1.0*tx.positie"] {
    log info "Track: [det_track_info $el]"
    log info "Text:  [det_text_info $el]"
    log info "==="
  }
}

proc det_track_info {el} {
  dict_to_vars $el
  return "[file tail $path]"
}

proc det_text_info {el} {
  dict_to_vars $el
  return "$positie. $artiest - $titel"
}

proc insert_manual {conn track_id text_pos} {
  db_eval $conn "insert into koppeltext (track_id, text_id, status)
                 select $track_id, tx.id, 'manual'
                 from top2000text tx
                 where 1.0*tx.positie = $text_pos"  
}

main $argv

