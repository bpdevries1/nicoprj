#!/usr/bin/env tclsh861

# deze alleen zippen van nicoprj en perftoolset/tools dirs om (via mail?) bij RABO te krijgen.

package require ndv

proc main {} {
  zip_projects
}

#nicoprj - 293MB, best veel.
#perftoolset - 43.3MB
#perftoolset/tools - 17.8 MB, moet kunnen, zeker gezipt.

proc zip_projects {} {
  zip_project /home/nico/nicoprj /home/ymor/RABO/zips/nicoprj.zip
  # zip_project /home/nico/perftoolset/tools /home/ymor/RABO/zips/perftoolset-tools.zip
}

proc add_xr {str} {
  return "-xr!$str"
}

proc zip_project {dir zipfile} {
  file mkdir [file dirname $zipfile]
  cd $dir
  puts "current dir: [pwd]"
  file delete $zipfile

  # for testing etc no password:

  # set ignores {*~ *.exe *.dll *.jar *.class *.jnilib *.log *.out *.xls .git mediatools tryout target output logs}
  # [2016-05-29 19:38] .dll nu wel, zou alleen percentile.dll moeten zijn, rest van de dll's staan in een target dir, worden ook ignored.
  set ignores {*~ *.exe *.jar *.class *.jnilib *.log *.out *.xls .git mediatools tryout target output logs}
  set options [map add_xr $ignores]
  
  # set options {-xr!*.exe -xr!*.dll -xr!*.log -xr!*.xls -xr!.git}
  # exec 7z a -tzip $zipfile * -xr!*.exe -xr!*.dll -xr!*.log -xr!*.xls -xr!.git
  exec 7z a -tzip -p1234test $zipfile * {*}$options

  # exec 7z a -tzip -p1234test $zipfile * -xr!*.exe -xr!*.dll -xr!*.log -xr!*.xls -xr!.git
}

main
