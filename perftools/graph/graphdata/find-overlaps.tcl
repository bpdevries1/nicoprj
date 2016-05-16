package require ndv

::ndv::source_once "graphdata-lib.tcl"

# @param lst: list of strings
# @return a list: first element is list of shortened string, second element is mapping from the shortened key to the original longer name
# example: [ABC/DEF ABC/GHI ZYX/123 ZYX/456] => [[A/DEF A/GHI Z/123 Z/456] [A/ ABC/ Z/ ZYX/]
# @note: maybe do this recursive, append the list of mappings, do the removing on a subset and concat later?
# 28-12-2012 @note: this could be a library function, but for now, don't do this.
#
# test cases
#  remove_overlaps {abc/def abc/ghi}
#  remove_overlaps {abc/def abc/ghi def/123 def/456}
#  remove_overlaps {abc/def def/123 bla abc/ghi def/456}
#  remove_overlaps {Sentinel Datum Duration Status {} {} {} {}} => 3-9-2011 blijft hangen, infinite loop.
#  remove_overlaps {Sentinel Datum Duration Status}
#  remove_overlaps {""} => 3-9-2011 blijft ook hangen, infinite loop. => extra check toegevoegd, nu ok.

set MAX_LEGEND_LENGTH 60

proc remove_overlaps {lst} {
  global MAX_LEGEND_LENGTH
  # variable MAX_LEGEND_LENGTH ; # wihtin namespace.
  set lst_s [lsort $lst]
  set ndx1 0
  set lst_shrt {}
  set counter 1
  set mapping {}
  while {$ndx1 < [llength $lst]} {
    set str1 [lindex $lst_s $ndx1]
    set ndx2 [expr $ndx1 + 1] ; # if the index goes beyond the list, the lindex returns an empty string, and the overlap will be empty.
    set ov [find_overlap2 $str1 [lindex $lst_s $ndx2]]
    if {[string length $ov] < 2} {
      # no overlap, put first item in result and continue with second item
      if {[string length $str1] > $MAX_LEGEND_LENGTH} {
        # maybe need a more sophisticated substring, for now take the last characters, normally most distinctive.
        lappend lst_shrt [string range $str1 end-$MAX_LEGEND_LENGTH end]
      } else {
        lappend lst_shrt $str1
      }
      incr ndx1
    } else {
      # put shortened first and second item in result, see if next items have same overlap.
      set replacement "$counter[string index $ov end]"
      lappend mapping $replacement $ov
      incr counter
      lappend lst_shrt "$replacement[string range $str1 [string length $ov] end]"
      lappend lst_shrt "$replacement[string range [lindex $lst_s $ndx2] [string length $ov] end]"
      incr ndx2
      while {[find_overlap2 $str1 [lindex $lst_s $ndx2]] == $ov} {
        lappend lst_shrt "$replacement[string range [lindex $lst_s $ndx2] [string length $ov] end]"
        incr ndx2
      }
      set ndx1 $ndx2
    }
  }
  # make a long->short mapping
  foreach el1 $lst_s el2 $lst_shrt {
    set ar_map($el1) $el2 
  }
  # use this to create a shortened list in the original order.
  set res {}
  foreach el $lst {
    lappend res $ar_map($el)
  } 
  
  list [mapfor el $lst {set ar_map($el)}] $mapping
}

# @return the largest overlapping string in a list of strings, counted from the start.
# @example [ABC/DEF ABC/GHI] => ABC/
proc find_overlap {lst} {
  set l [llength $lst]
  if {$l == 0} {
    return "" 
  } elseif {$l == 1} {
    lindex $lst 0 
  } elseif {$l == 2} {
    find_overlap2 {*}$lst 
  } else {
    # find overlap of the first two, concat with rest of the list and recurse. (tail recursive)
    find_overlap [concat [list [find_overlap2 [lindex $lst 0] [lindex $lst 1]]] [lrange $lst 2 end]] 
  }
}

# @return the largest overlapping string in both strings, counted from the start.
# @example [ABC/DEF ABC/GHI] => ABC/
# test cases
#   find_overlap2 "" "" => 3-9-2011 blijft hangen, infinite loop.
proc find_overlap2 {str1 str2} {
  set n [expr min([string length $str1],[string length $str2])]
  set i 0
  # 3-9-2011 als beide strings leeg zijn, levert dit steeds true, en oneindige lus.
  # 3-9-2011 dus check op $i < $n toegevoegd.
  while {($i < $n) && ([string index $str1 $i] == [string index $str2 $i])} {
    incr i 
  }
  # now search backwards for a special character, only split on those characters.
  incr i -1 ; # set to last matching char.
  while {(![regexp {[/\\._ ]} [string index $str1 $i]]) && ($i >= 0)} {
    incr i -1 
  }
  string range $str1 0 $i
}

