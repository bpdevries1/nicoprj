package require ndv

# TODO: kan zijn dat dir wat dieper zit, bv bij de top250 (seven samurai bv)
proc det_dir_orig {film_path} {
  # regexp {_tijdelijk/([^/]+)/} $temp_film z dir_orig
  # return $dir_orig
  if {[file isdirectory $film_path]} {
    file tail $film_path
  } else {
    # not sure if this is generic enough.
    file tail [file dirname $film_path]  
  }
}

proc det_dir_new {dir_orig} {
  # remove numbers from top 250 film
  set dir_new $dir_orig
  if {[regexp {^\d+ - (.+)$} $dir_new z d2]} {
    set dir_new $d2
  }
  regsub -all {\.} $dir_new " " dir_new; # replace (common) dots by spaces.

  # parse 4 digits as a year, provided they are surrounded by parens, brackets, braces or spaces
  # everything before is the name of the movie, everything after is cruft.
  # hack: space erachter, zodat 'film 2016' ook gesnapt wordt. 
  if {[regexp {^(.+)[\(\{\[ ](\d{4})[\)\}\] ]} "$dir_new " z name year]} {
    return "[string trim $name] ($year)"
  }
  if {[regexp {__YEAR__} $dir_new]} {
    return $dir_new
  } else {
    return "$dir_new (__YEAR__)"  
  }
}

# if path already 'exists' (already called before with the same path), add a suffix.
set _film_paths [dict create]

# TODO: met huidige manier blijf je renamen: je geeft een al goede mee, deze bestaat al,
# dus wordt een andere suffix bedacht. Dus dan belangrijk of dit path dezelfde is.
# en film (2017)2 wordt hier eerst als film (2017) meegegeven, die dan waarsch ook bestaat.
# iets van orig_path meegeven, denk ik.
# zodra path2 gelijk is aan orig path, dan is het goed.
proc add_suffix {path_orig path_new} {
  global _film_paths
  set suffix ""
  set path2 $path_new$suffix
  while {[dict exists $_film_paths $path2] || [file exists $path2] } {
    if {$path2 == $path_orig} {
      break;                    # want to rename to existing name, not needed.
    }
    if {$suffix == ""} {
      set suffix 2
    } else {
      incr suffix
    }
    set path2 $path_new$suffix
  }
  dict set _film_paths $path2 1
  return $path2;                # could be same as orig, then no rename will be done.
}

