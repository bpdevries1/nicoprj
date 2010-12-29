#!/home/nico/bin/tclsh
package require Itcl
package require Tclx ; # for try_eval

source [file join [file dirname [info script]] .. .. lib CLogger.tcl]
source [file join [file dirname [info script]] .. lib libmusic.tcl]
source [file join [file dirname [info script]] .. .. lib generallib.tcl]

source [file join [file dirname [info script]] .. lib setenv-media.tcl]

proc main {argc argv} {
	global env failed_dir
	set root_dir $env(MEDIA_NEW)
	set failed_dir [file join [file dirname $root_dir] _unpack_failed]
	unpack_dir $root_dir
  rename_dirs $root_dir
}

proc unpack_dir {dir} {
	foreach filename [glob -nocomplain -directory $dir -type f *] {
		# unpack_file_[det_file_type $filename] $filename
		unpack_file_[det_file_type $filename] $filename
	}
	foreach subdir [glob -nocomplain -directory $dir -type d *] {
		unpack_dir $subdir
	}
}

proc det_file_type {filename} {
	set ext [file extension $filename]
	if {$ext == ".zip"} {
		return zip
	} elseif {$ext == ".rar"} {
		return rar
	} else {
		return unknown
	}
}

proc unpack_file_unknown {filename} {
	# do nothing	
}

proc unpack_file_zip {filename} {
	return [unpack_file_general $filename]
}

proc unpack_file_rar {filename} {
	return [unpack_file_general $filename]
}

proc unpack_file_general {filename} {
	set target_dir [det_target_dir $filename]
	file mkdir $target_dir
	set filetype [det_file_type $filename]
	if {[un${filetype} $filename $target_dir]} {
		if {[unpacked_ok $filename $target_dir]} {
			file delete $filename
			# exit
		} else {
			puts "Unpacking ($filetype) failed for file: $filename"
		}
	} else {
		puts "Unpacking ($filetype) failed for file: $filename"
		move_to_failed $filename
		# exit
		file delete -force $target_dir
	}
	# exit
}

proc move_to_failed {filename} {
	global failed_dir
	file mkdir $failed_dir
	file rename $filename $failed_dir
}

# unpacked is ok if the total filesize of files in this dir is greater than size of archive.
# @todo maybe include a bit of slack, if archive is uncompressed.
proc unpacked_ok {filename target_dir} {
	set ONE_MB 1000000
	set packed_size [file size $filename]
	set dir_size [det_dir_size $target_dir]
	if {$dir_size + $ONE_MB >= $packed_size} {
		return 1
	} else {
		puts "Warning: packed size is $packed_size, dir_size is $dir_size for file: $filename"
		return 0
	}
}

proc det_dir_size {dir} {
	set size 0
	foreach filename [glob -nocomplain -directory $dir -type f *] {
		set size [expr $size + [file size $filename]]
	}
	foreach subdir [glob -nocomplain -directory $dir -type d *] {
		set size [expr $size + [det_dir_size $subdir]]
	}
	
	return $size
}

# target_dir: same as filename, without extension, and if it exists already, add a number to the dir.
proc det_target_dir {filename} {
	set target_dir [file rootname $filename]
	set number ""
	while {[file exists "${target_dir}${number}"]} {
		if {$number == ""} {
			set number 2
		} else {
			incr number
		}
	}
	return "${target_dir}${number}"
}

proc unrar {filename target_dir} {
	puts "Unrarring $filename => $target_dir"
	# exec /usr/bin/unrar x $filename "{$target_dir}/"
	# -p-: do not query password, so fail then.
	try_eval {
		set output [exec /usr/bin/unrar x -p- $filename $target_dir]
		set result 1
	} {
		# puts "Unrar failed, output: $output" ; #output niet gevuld bij catch.
		puts "$errorResult"
		# puts "errorCode: $errorCode"
		# puts "errorInfo: $errorInfo"
		set result 0
	}
	# als 't niet goed gaat, knalt 'ie wel, en wordt delete ook niet gedaan...
	# exit ; # for now, just one.
	return $result
}

proc unzip {filename target_dir} {
	puts "Unzipping $filename => $target_dir"
	try_eval {
		set output [exec /usr/bin/unzip $filename -d $target_dir]
		set result 1
	} {
		# print error info?
		set result 0
	}
	# als 't niet goed gaat, knalt 'ie wel, en wordt delete ook niet gedaan...
	# exit ; # for now, just one.
	return $result
}

set DO_RENAME 1

proc rename_dirs {dir} {
	global DO_RENAME
  set new_dirname [det_new_name $dir]
  if {$dir != $new_dirname} {
    puts "Renaming \n  $dir =>\n  $new_dirname"
    if {$DO_RENAME} {
      file rename $dir $new_dirname
      set dir $new_dirname
    }
  }
  foreach filename [glob -nocomplain -directory $dir -type f *] {
		# unpack_file_[det_file_type $filename] $filename
		rename_file $filename
	}
	foreach subdir [glob -nocomplain -directory $dir -type d *] {
		rename_dirs $subdir
	}
}

proc rename_file {filename} {
  global DO_RENAME
  set new_filename  [det_new_name $filename]
  if {$filename != $new_filename} {
    puts "Renaming \n  $filename =>\n  $new_filename" 
    if {$DO_RENAME} {
      file rename $filename $new_filename
    }
  }
  if {[should_delete $filename]} {
    delete_file $filename 
  }
}

proc should_delete {filename} {
  set ext [string tolower [file extension $filename]]
	set ext_list [list .txt .jpg .mpg .mpeg .wmv .rar .doc .avi .zip \
											.qt .m3u .nfo .sfv .db .ini .out .pdf .htm .html .log \
											.xls .tcl {} .swf .nra .x32 .bmp .url .exe .dat .cue \
											.gif .cda .inf .alb .wpl .asx .lnk .bkp .pls .bat .cmd .sh]
                      
  set ext_list [list .txt .jpg .db .ini .m3u .sfv]                      
  if {[lsearch -exact $ext_list $ext] > -1} {
		return 1
	} else {
    return 0    
  }
  
}

proc delete_file {filename} {
  puts "Deleting file: $filename" 
  file delete $filename
}

proc det_new_name {pathname} {
  set result $pathname
  # altijd spaties om streepjes, wel losse vervang actie, ander infinite loop potentieel
  set result [string map {"-" " - "} $result]
  
  # vervang _ door spatie, & door and, dubbele spatie door enkele spatie, blokhaken door ronde haken...
  set result [string map {"_" " " " & " " and " "  " " " "[" "(" "]" ")"} $result]
  # soms 2 spaties bij een streepje oorspronkelijk; door bovenstaande worden dit er 3, dan 2 en met onderste toch weer 1.
  set result [string map {"_" " " " & " " and " "  " " " "[" "(" "]" ")"} $result]

  # vervang en join/split op 2 niveau's: path-onderdeel en word hierbinnen.
  set result2 [file join {*}[map2 path_part [file split $result] {to_title $path_part}]]
  
  if {0} {
    if {[string length $result] != [string length $result2]} {
      puts "ERROR: string replace failed for pathname: $pathname => $result2"
      set result $pathname
    } else {
      set result $result2 
    }
  }
  # nu ook spaties aan begin of einde van onderdeel verwijderd, dus dan klopt lengte niet meer.
  set result $result2 
  
  return $result
}

proc to_title {path_part} {
  # vervang alle woorden in pathname van minimaal 2 (eigenlijk alles dus) tekens en allemaal hoofdletters door hun totitle variant
  # ook de laatste woorden, die eindigen op .mp3
  set result $path_part
  set result2 [join [map2 word [split $result " "] {
    if {[string is upper [string range $word 0 0]]} {
      string totitle $word
    } else {
      set dummy $word
    }
  }] " "]
  
  if {[string length $result] != [string length $result2]} {
    puts "ERROR: string replace failed for path_part: $path_part => $result2"
    set result $path_part
  } else {
    set result $result2 
  }
  return [string trim $result]
}

main $argc $argv
