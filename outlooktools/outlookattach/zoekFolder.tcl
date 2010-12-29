# zoekFolder.tcl: include-file voor zoeken van een Outlook folder.

# zoek folder 1 niveau diep
proc zoekFolder {folders naam} {
  # puts "zoekfolder: $naam"
  set i [$folders : count]
  while {$i >= 1} {
     set folder [$folders item $i]
     if {[$folder : name] == "$naam"} {
       return $folder
     } else {
 	   incr i -1
     }
  }
  puts "niet gevonden: $naam"
  return 0
}

proc zoekFolderPad {ns pad} {
  # set folders [$ns : Folders]
  set f $ns
  while {[regexp {^([^/]+)/(.*)$} $pad z naam restpad]} {
     set folders [$f : Folders]
     set f [zoekFolder $folders $naam]
     set pad $restpad
  }
  set f [zoekFolder [$f : Folders] $pad]
  return $f

}

