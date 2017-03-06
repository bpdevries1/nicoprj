# roep unison aan voor backup naar g: en sync met h:
# backup volledig automatisch, sync mss niet.

package require ndv

set UNISON_BINARY {c:\PCC\Util\Unison\Unison-2.40.102-Text.exe}

use libfp

# TODO mss unison output bewaren, zodat je het de volgende dag kan bekijken, of eerst tonen de volgende keer dat je gosleep start.
# TODO mss toch periodiek uitvoeren, niet elke dag?

proc main {} {
  # zip_projects ; # [2016-12-01 10:30:10] niet meer nodig, git (github/bitbucket)
  # zip_vugens
  if 1 {
      # heck_drives h: g: u: w: v:
	  check_drives h: g: u:
	  # [2017-03-06 11:15:25] script now fails if u: not mounted. Could decide to continue anyway.
	  unison -auto projecten2h ; # [2016-12-01 10:28:27] deze nog wel belangrijk.
	  unison -auto sync-c-g ; # [2016-12-01 10:29:39] kijken hoe automatisch dit gaat.
	  unison -auto projecten2vdc ; # [2017-01-05 15:35:46] deze nu erbij, ook u: schijf.
	  unison -auto sync-c-u ; # [2017-01-05 15:35:59] en deze ook.
	  check_drives h: g: u: ; # [2017-03-06 11:15:57] also check at the end, for reporting.
	  
	  # unison -auto -batch backup2g ; # [2016-12-01 10:28:46] deze vervangen door sync-c-g (om daarna ook op laptop te zetten)
	  # unison -auto -batch vugen2h ; # [2016-12-01 10:28:13] niet echt nodig, scripts in git/bitbucket.
	  # zip_vugens ; # [2016-09-29 09:10:09] niet meer nodig.
	  # zip_alm_dbs ; # [2016-12-01 10:27:45] voorlopig niet nodig, hier al tijd niets mee gedaan.
	  # zip_notes_org ; # [2016-12-01 10:27:16] niet meer nodig, deze zitten in sync-c-g project.
	  # cleanup
  }
}

proc check_drives {args} {
	foreach drive $args {
		set root [file join $drive ""]
		set res [list]
		if {![file exists $root]} {
			puts "WARN: drive not mounted: $drive"
		} else {
			set res [glob -nocomplain -directory $root *]
			puts "$root => [count $res]"
			# puts $res
		}
	}
	# exit; # for test.
}

proc unison {args} {
  global UNISON_BINARY stdout
  catch {
    # stdout net als stderr gewoon doorsturen naar de console, niet als result opvangen.
    # exec -ignorestderr $UNISON_BINARY {*}$args 1>@2
    # set f [open unison.out w]
    # exec -ignorestderr $UNISON_BINARY {*}$args >&@ $f
    exec -ignorestderr $UNISON_BINARY {*}$args >&@ stdout
    # close $f
  } res
  puts "res: $res"
}

#nicoprj - 293MB, best veel.
#perftoolset - 43.3MB
#perftoolset/tools - 17.8 MB, moet kunnen, zeker gezipt.

proc zip_projects {} {
  # [2016-09-29 09:09:55] niet meer nodig om source projects te zippen.
  # zip_project {c:\PCC\nico\nicoprj} /c/PCC/Nico/zips/nicoprj.zip
  # zip_project {c:\PCC\nico\perftoolset\tools} /c/PCC/Nico/zips/perftoolset-tools.zip
}

proc zip_project {dir zipfile} {
  global env
  # file mkdir [file dirname $zipfile]
  cd $dir
  set old_path $env(PATH)
  set env(PATH) {c:\PCC\Util\cygwin\bin}
  puts "current dir: [pwd]"
  
  file delete [det_win_file $zipfile]
  exec "C:/PCC/Util/cygwin/lib/p7zip/7z.exe" a -tzip -p1234test $zipfile * -xr!*.exe -xr!*.dll -xr!*.log -xr!*.xls
  set env(PATH) $old_path
}


proc zip_vugens {} {
  # [2016-05-12 17:20:30] niet altijd de clean, want soms juist wel alle info bewaren.
  # exec {c:\pcc\util\tcl86\bin\tclsh86.exe} {C:\PCC\Nico\nicoprj\perftools\vugentools\vugenclean.tcl} {c:\PCC\Nico\VuGen}
  # zip_vugen ClientReporting
  # zip_vugen clrep-rec-20160512a
  if 0 {
	zip_vugen RCC_All
  }
  #zip_vugen Dotcom
  #zip_vugen RCC_CashBalancingWidget
  #zip_vugen RCC_LoansWidget
  #zip_vugen Transact_secure
}

# moet wel zonder .git, of leuk om erbij te hebben? hangt van grootte af.
# similar to zip_project, but possibly with other exclusions.
proc zip_vugen {script} {
  global env

  set zipfile [file join /c/PCC/Nico/zips $script.zip]
  set dir [file join {c:\PCC\Nico\VuGen} $script]

  file delete [det_win_file $zipfile]
  
  # file mkdir [file dirname $zipfile]
  cd $dir
  set old_path $env(PATH)
  set env(PATH) {c:\PCC\Util\cygwin\bin}
  puts "current dir: [pwd]"
  exec "C:/PCC/Util/cygwin/lib/p7zip/7z.exe" a -r- -tzip -p1234test $zipfile * -xr!*.exe -xr!*.dll -xr!*.log -xr!*.xls -xr!outputs
  set env(PATH) $old_path
}

proc zip_alm_dbs {} {
  zip_alm_db almpc.db
  zip_alm_db almpc-scen.db
}

proc zip_alm_db {dbname} {
  global env

  set zipfile [file join /c/PCC/Nico/zips $dbname.zip]
  set path [file join {c:\PCC\Nico\ALMData} $dbname]
  set dir [file dirname $path]
  file delete $zipfile
  
  # file mkdir [file dirname $zipfile]
  cd $dir
  set old_path $env(PATH)
  set env(PATH) {c:\PCC\Util\cygwin\bin}
  puts "current dir: [pwd]"
  exec "C:/PCC/Util/cygwin/lib/p7zip/7z.exe" a -tzip -p1234test $zipfile $dbname
  set env(PATH) $old_path
}

proc zip_notes_org {} {
  global env

  # set zipfile [file join /c/PCC/Nico/zips notes-org.zip]
  set ziproot /c/PCC/Nico/zips
  # set path [file join {c:\PCC\Nico\ALMData} $dbname]
  set paths {c:/PCC/Nico/Notes c:/PCC/Nico/org}
  # set paths {/c/PCC/Nico/Notes /c/PCC/Nico/org}
  
  set old_path $env(PATH)
  set env(PATH) {c:\PCC\Util\cygwin\bin}
  
  foreach path $paths {
	  cd $path
	  set zipfile "$ziproot/[file tail $path]"
	  file delete $zipfile
	  puts "current dir: [pwd]"
	  # exec "C:/PCC/Util/cygwin/lib/p7zip/7z.exe" a -tzip -p1234test -r- $zipfile *
	  # [2016-02-01 10:28:13] TODO deze nog met subdirs, niet triviaal om dit uit te schakelen.
	  exec "C:/PCC/Util/cygwin/lib/p7zip/7z.exe" a -tzip -p1234test -r- $zipfile ./*
  }
  set env(PATH) $old_path
  
  # file mkdir [file dirname $zipfile]
}

# clean up temp dirs etc.
proc cleanup {} {
  puts "Cleaning up temp dirs..."
  cleanup_dir {c:\users\vreezen\AppData\Local\Temp}
  puts "Finished cleaning up."
}

# recursively called.
proc cleanup_dir {dir} {
	foreach subdir [glob -nocomplain -directory $dir -type d *] {
		cleanup_dir $subdir
		# delete may fail, because no rights or locked file, or files in dir.
		catch {file delete $subdir}
	}
	foreach filename [glob -nocomplain -directory $dir -type f *] {
		# delete may fail, because no rights or locked file.
		catch {file delete $filename}
	}
}

proc det_win_file {cygwin_file} {
        if {[regexp {^/c/(.*)$} $cygwin_file z rest]} {
             return "c:/$rest"
        } else {
             error "Cannot convert to windows name: $cygwin_file"
        }
}

main
