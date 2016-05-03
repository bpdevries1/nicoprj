# roep unison aan voor backup naar g: en sync met h:
# backup volledig automatisch, sync mss niet.

package require ndv

set UNISON_BINARY {c:\PCC\Util\Unison\Unison-2.40.102-Text.exe}

# TODO mss unison output bewaren, zodat je het de volgende dag kan bekijken, of eerst tonen de volgende keer dat je gosleep start.
# TODO mss toch periodiek uitvoeren, niet elke dag?

proc main {} {
  unzip_projects
}

proc unzip_projects {} {
  unzip_project {c:\PCC\nico\.staging\nicoprj} /c/PCC/nicoprj.zip
  unzip_project {c:\PCC\nico\.staging\perftoolset\tools} /c/PCC/perftoolset-tools.zip
  # unzip_project {c:\PCC\nico\.staging\nicoprj} c:/PCC/nicoprj.zip
  # unzip_project {c:\PCC\nico\.staging\perftoolset\tools} c:/PCC/perftoolset-tools.zip
}

proc unzip_project {dir zipfile} {
  global env
  # TODO check op existence, vertaal cygwin pad naar windows pad.
  set zipfile_win [det_win_file $zipfile]
  if {![file exists $zipfile_win]} {
	puts "zipfile does not exist: $zipfile"
	return
  }
  # file mkdir [file dirname $zipfile]
  file delete -force $dir
  file mkdir $dir
  cd $dir
  set old_path $env(PATH)
  set env(PATH) {c:\PCC\Util\cygwin\bin}
  puts "current dir: [pwd]"
  
  exec "C:/PCC/Util/cygwin/lib/p7zip/7z.exe" x -tzip -p1234test $zipfile
  file delete $zipfile_win
  set env(PATH) $old_path
}

proc det_win_file {cygwin_file} {
	if {[regexp {^/c/(.*)$} $cygwin_file z rest]} {
		return "c:/$rest"
	} else {
		error "Cannot convert to windows name: $cygwin_file"
	}
}

proc zip_project {dir zipfile} {
  global env
  # file mkdir [file dirname $zipfile]
  cd $dir
  set old_path $env(PATH)
  set env(PATH) {c:\PCC\Util\cygwin\bin}
  puts "current dir: [pwd]"
  file delete $zipfile
  exec "C:/PCC/Util/cygwin/lib/p7zip/7z.exe" a -tzip -p1234test $zipfile * -xr!*.exe -xr!*.dll -xr!*.log -xr!*.xls
  set env(PATH) $old_path
}

proc zip_vugens {} {
  exec {c:\pcc\util\tcl86\bin\tclsh86.exe} {C:\PCC\Nico\nicoprj\perftools\vugentools\vugenclean.tcl} {c:\PCC\Nico\VuGen}
  zip_vugen Dotcom
  zip_vugen RCC_CashBalancingWidget
  zip_vugen RCC_LoansWidget
  zip_vugen Transact_secure
}

# moet wel zonder .git, of leuk om erbij te hebben? hangt van grootte af.
# similar to zip_project, but possibly with other exclusions.
proc zip_vugen {script} {
  global env

  set zipfile [file join /c/PCC/Nico/zips $script.zip]
  set dir [file join {c:\PCC\Nico\VuGen} $script]

  file delete $zipfile
  
  # file mkdir [file dirname $zipfile]
  cd $dir
  set old_path $env(PATH)
  set env(PATH) {c:\PCC\Util\cygwin\bin}
  puts "current dir: [pwd]"
  exec "C:/PCC/Util/cygwin/lib/p7zip/7z.exe" a -r- -tzip -p1234test $zipfile * -xr!*.exe -xr!*.dll -xr!*.log -xr!*.xls
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

main
