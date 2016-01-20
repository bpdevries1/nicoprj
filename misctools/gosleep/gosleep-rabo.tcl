# roep unison aan voor backup naar g: en sync met h:
# backup volledig automatisch, sync mss niet.

package require ndv

set UNISON_BINARY {c:\PCC\Util\Unison\Unison-2.40.102-Text.exe}

# TODO mss unison output bewaren, zodat je het de volgende dag kan bekijken, of eerst tonen de volgende keer dat je gosleep start.
# TODO mss toch periodiek uitvoeren, niet elke dag?

proc main {} {
  if 0 {
	  unison -auto projecten2h
	  unison -auto -batch backup2g
	  unison -auto -batch vugen2h
  }
  zip_projects
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
  zip_project {c:\PCC\nico\nicoprj} /c/PCC/Nico/zips/nicoprj.zip
  zip_project {c:\PCC\nico\perftoolset\tools} /c/PCC/Nico/zips/perftoolset-tools.zip
}

proc zip_project {dir zipfile} {
  global env
  # file mkdir [file dirname $zipfile]
  cd $dir
  # C:/PCC/Util/cygwin/lib/p7zip/7z.exe" a -tzip -p1234test $zipfile *"
  # C:\PCC\Util\cygwin\lib\p7zip\7z.exe
  # exec {C:\PCC\Util\cygwin\lib\p7zip\7z.exe}
  # cygwin1.dll => set PATH=%PATH%;c:\PCC\Util\cygwin\bin
  set old_path $env(PATH)
  set env(PATH) {c:\PCC\Util\cygwin\bin}
  # breakpoint
  puts "current dir: [pwd]"
  # zonder exe/dll's. -x[r[-|0]]]{@listfile|!wildcard}: eXclude filenames
  # -x!*.exe -x!*.dll
  # 7z a -tzip archive.zip *.txt -x!temp.*
  exec "C:/PCC/Util/cygwin/lib/p7zip/7z.exe" a -tzip -p1234test $zipfile * -xr!*.exe -xr!*.dll -xr!*.log -xr!*.xls
  # evt in een mail zetten?
  set env(PATH) $old_path
}

main