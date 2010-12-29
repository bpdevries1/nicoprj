# openstaand:
# * een aantal items wel gesaved, maar daarna fout bij aanpassen van de mail en saven van mail
#
# type attachments:
# 1: by value
# 2: .lnk (opslaan lukt wel, maar naam wat anders; bestand hierna verwijderd) 
# 4: by reference
# 5: embedded item
# 6: OLE (opslaan bestand kan dan blijkbaar niet: helaas; bestand hierna wel verwijderd, oppassen dus)

# outlookexport.tcl
# package require optcl
package require tcom
package require ndv

::ndv::source_once zoekFolder.tcl

set log [::ndv::CLogger::new_logger [file tail [info script]] debug]


proc main {argc argv} {
  global namespace log
  if {($argc != 2)} {
    # puts "syntax: tclsh outlookattach.tcl <dirroot> \[/alles]"
    puts "syntax: tclsh outlookattach.tcl <folderfile> <lastdatefile>"
    exit
  }
  #set dirroot [lindex $argv 0]
  set folderfile [lindex $argv 0]
  set lastdatefile [lindex $argv 1]
  
  set folders [leesFolders $folderfile]
  set lastdate [leesLastdate $lastdatefile]
  
  # start applicatie
  # set app [optcl::new Outlook.Application]
  set app [::tcom::ref getactiveobject "Outlook.Application"]
  set namespace [$app GetNamespace MAPI]
  
  foreach folderitem $folders {
    handleFolder $folderitem
  }
  
  #if {$alles} {
  #  handleNameSpace $ns
  #} else {
    # set folder [zoekFolderPad $ns "Mailbox - Nico de Vreeze (uto)/Inbox"]
    # handleFolder "\\Mailbox - Nico de Vreeze (uto)\\Inbox" $folder
    # handleFolder "\\Mailbox - Nico de Vreeze (uto)" $folder
  
    # set folder [zoekFolderPad $ns "Mailbox - Nico de Vreeze (uto)/Sent Items"]
    # handleFolder "\\Mailbox - Nico de Vreeze (uto)" $folder
  
    #set folder [zoekFolderPad $ns "Persoonlijke mappen/Gestuurd"]
    #handleFolder "\\Persoonlijke mappen" $folder
  
  #}
  
  schrijfLastdate $lastdatefile
}

# pad: pad zonder f.name, niet eindigend op backslash
proc handleFolder {folderitem} {
  global namespace log
  $log debug "handleFolder: $folderitem"
  
  set fname [lindex $folderitem 0]
  set padname [lindex $folderitem 1]

  set f [zoekFolderPad $namespace $fname]
  puts "HandleFolder: $fname"
  #set nwpad "$pad\\[$f : Name]"
  set nwpad $padname
  
  if {[$f : DefaultItemType] == "0"} {
     # mail-items behandelen
     set items [$f : items]
     set n [$items : count]

	 set i $n
	 set doorgaan 1
	 while {$doorgaan && ($i > 0)} {
      set item [$items item $i]
      # vaag, kan zijn dat checkDatum niet lukt, dan maar doorgaan met volgende
      if {[catch {
        set doorgaan [checkDatum $item]
      } melding]} {
        puts "Opvragen datum mislukt, verder met volgende; Melding: $melding"	
      }
      #if {[set errno [catch {handleMailItem $nwpad $item} melding]]} {
      #   puts "Fout: $nwpad - [$item : subject]"
      #   puts "  orig: $errno :: $melding"
      #   puts "  entryID: [$item : entryID]"
      #}
      if {$doorgaan} {
        handleMailItem $nwpad $item
      }
      optcl::unlock $item
      incr i -1
     }
     optcl::unlock $items
  }
  # subfolders - nu even niet meer.
  #set folders [$f : folders]
  #set n [$folders : count]
  #set i 1
  #while {$i <= $n} {
  #   set folder [$folders item $i]
  #	 handleFolder $nwpad $folder
  #	 incr i
  #	 optcl::unlock $folder
  #}
  #optcl::unlock $folders
}

proc handleMailItem {pad item} {
  global stderr
  # puts "$pad *** [$item : subject]"
  set body [$item : body]
  set atts [$item : Attachments]
  set n [$atts : count]
  set padclean [cleanpad $pad]

  if {0} {
    # achteraan beginnen, anders klopt index niet meer na verwijderen van een attachment.
    for {set i $n} {$i >= 1} {incr i -1} {
      set att [$atts item $i]
      set gelukt [saveAttachment $padclean $att $item]
      set filename "<onbekend>"
      catch {set filename [$att : filename]}
      set tekst "<attachment \"$filename\" verplaatst>"
      set body "$body\n$tekst"
      if {$gelukt} {
         $att delete
      }
      optcl::unlock $att
    }
  
    # veranderde mail saven
    if {$n > 0} {
      $item : body $body
      # # puts stderr "Fouten in prog: nu niets saven!"
      $item save
    }
  
    optcl::unlock $atts
  }
}

# pad is de dirnaam zonder backslash op het einde (maar begin evt. wel); en al ontdaan van rare tekens
# dirroot is rootpad zonder backslash op het einde
proc saveAttachment {pad att item} {
  global dirroot

  set gelukt 0

  if {[$att : type] == "6"} {
    # 6 is OLE, kan blijkbaar niet opgeslagen worden en verwijderd.
    return $gelukt
  }
  
  #file mkdir "$dirroot$pad"
  set subject [$item : subject]
  set filename $subject
  catch {set filename [$att : filename]}
  set filename [cleanpad $filename]

  #if {[string range $pad 0 0] == "\\"} {
  #  set padvoll "$dirroot$pad"
  #} else {
  #	set padvoll "$dirroot\\$pad"
  #}
  #schrijfEntry $padvoll $filename [$item : subject] [$item : entryID]

  #set filepad "$dirroot$pad\\$filename"
  set filepad "$pad\\$filename"
  set filepad [file join $pad $filename]
  if {[file exists $filepad]} {
    set filepad [vulaanpad $filepad]
  }
  puts "$filepad (type = [$att : type])"
  puts "filepad: $filepad"
  if {[catch {$att SaveAsFile $filepad} msg]} {
	puts "  opslaan bestand ($filepad) niet gelukt: $msg"
  } else {
    # opslaan wel gelukt
    set gelukt 1
  }
  # als bestand niet bestaat, is opslaan niet gelukt en mtime ook niet van belang
  if {[file exists $filepad]} {
    file mtime $filepad [string2time [$item : CreationTime]]
  } else {
    puts "  opgeslagen bestand bestaat niet."
  }

  return $gelukt
}

proc string2time str {
   regexp {^(.*)-(.*)-(.*) (.*)$} $str z d m y t
   return [clock scan "$y-$m-$d $t"]
}

proc cleanpad {pad} {
  regsub -all {/} $pad "_" pad
  regsub -all {\[} $pad "_" pad
  regsub -all {\]} $pad "_" pad
  regsub -all {,} $pad "_" pad
  regsub -all {\?} $pad "_" pad
  regsub -all {\*} $pad "_" pad
  regsub -all {!} $pad "_" pad

  # e trema en andere gekke tekens
  while {![string is ascii -failindex pos $pad]} {
    set pad "[string range $pad 0 [expr $pos - 1]]_[string range $pad [expr $pos + 1] end]"
  }
  
  return $pad
}

# maak filepadnaam uniek
proc vulaanpad {filepad} {
  set i 1
  set klaar 0
  set rootname [file rootname $filepad]
  # ext bevat ook de punt
  set ext [file extension $filepad]
  while {!$klaar} {
    set p "$rootname ($i)$ext"
    if {[file exists $p]} {
      set klaar 0
    } else {
      set klaar 1
    }
    incr i
  }
  return $p
}

# schrijf een regel in __attachments.txt
proc schrijfEntry {pad filenaam subject entryID} {
  file mkdir "$pad"
  set f [open "$pad\\__attachments.txt" a]
  puts $f "$filenaam - $subject \[$entryID\]"
  close $f
}



proc checkDatum {item} {
  global lastdate

  set result 0

  #puts "receivedTime: [$item : receivedTime]"
  set time [$item : receivedTime]
  regexp {^([0-9]+)-([0-9]+)-([0-9]+) } $time z d m j
  if {$j > 95} {
    set j [expr $j + 1900]
  } else {
    set j [expr $j + 2000]
  }
  set t2 [format "%4d%02d%02d" $j $m $d]
  set result [expr ($t2 >= $lastdate)]

  return $result
}


proc handleNameSpace {ns} {
  # puts "HandleNameSpace"
  set folders [$ns : folders]
  set n [$folders : count]
  set i 1
  while {$i <= $n} {
     set folder [$folders item $i]
	 handleFolder "" $folder
	 incr i
  }
}

proc leesFolders {folderfile} {
  set folders {}
  set f [open $folderfile r]
  while {![eof $f]} {
	gets $f line
    if {[string range $line 0 0] != "#"} {
		if {[regexp {^([^\t]+)\t(.*)$} $line z foldername dirname]} {
			lappend folders [list $foldername $dirname]
		}
	}
  }
  close $f
  return $folders
}

proc leesLastdate {lastdatefile} {
  set f [open $lastdatefile r]
  gets $f lastdate
  close $f
  return $lastdate
}

proc schrijfLastdate {lastdatefile} {
  set f [open $lastdatefile w]
  puts $f [clock format [clock seconds] -format "%Y%m%d"]
}

main $argc $argv
