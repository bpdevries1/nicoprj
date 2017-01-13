#! /usr/bin/env tclsh

package require ndv
package require struct::set

use libfp

set OWS 1

proc main {argv} {
  lassign $argv until_line
  set infile "clang-orig.ebnf"
  set outfile "clang.ebnf"
  set text [read_file $infile]
  # set text "ahdhasd k +\n2e regel\nnog iets met + en dan wat"
  write_file $outfile [transform $text $until_line]
}

# from http://tigcc.ticalc.org/doc/keywords.html
set keywords { auto break case char const continue default do double else enum extern float for goto if int long register return short signed sizeof static struct switch typedef union unsigned void volatile while thread_local bool complex imaginary atomic
}

# if keywords or operators are already included in quotes, the <ows> won't get added. Fixed by first adding quotes, next add <ows> after each quoted element. 
# TODO: ows rule should include comments (as now done with auto-whitespace)
# -> [2017-01-04 22:25] done, but need to test.

# add <ows> after usage of terminals like identifier, don't want the ows to be part of identifiers, constants and strings.

if 0 {
  struct-or-union-specifier ::= struct-or-union '{' struct-declaration-list '}'
	| struct-or-union identifier '{' struct-declaration-list '}'
	| struct-or-union identifier

  so here each identifier needs to be followed by <ows>. Don't do this if identifier etc is the rule, should be covered by add_ows?

  Could be <identifier> as well.
  
}

proc transform {text until_line} {
  global keywords OWS
  if {$OWS} {
    set ows " <ows>"
  } else {
    set ows ""
  }
  # breakpoint
  # don't include |, is used in BNF itself.
  # First add quotes around characters...
  foreach chars {, : * ? \{ \} || << >> ^ / % ++ -- -> = == > < >= <= + - . ~ ! *= /= += -= <<= >>= ^= != |= %= ... ; ( ) [ ]} {
    # regsub -all " \\$char " $text " '$char' " text
    regsub -all [to_regexp $chars] $text " '$chars'\\1" text
  }
  # & and && have special syntax in regsub, so specific replace.
  # And also add quotes around some more specific characters.
  regsub -all { \&([ \n])} $text " '\\&'\\1" text
  regsub -all { \&\&([ \n])} $text " '\\&\\&'\\1" text
  regsub -all { \&=([ \n])} $text " '\\&='\\1" text
  # Add also add quotes around keywords, should be quoted.
  foreach keyword $keywords {
    regsub -all " ${keyword}(\[ \\n\])" $text " '$keyword'\\1" text
  }

  # next add <ows> after each terminal symbol/operator/keyword.
  # 'a' 'b' => 'a' <ows> 'b' <ows>
  # if ows is not added (if I want to use auto-whitespace again), this will remain the same. The single space in between will stay there.
  # don't want to do replace in some lines, so split by line.
  set lines [split $text "\n"]
  set lines2 [list]

  set rules_ignore {keyword identifier floating-constant integer-constant character-constant string chars escaped-char mws ows ws-or-comment ws comment inside-comment}

  set rules_append {keyword identifier floating-constant integer-constant character-constant string}
  
  foreach line $lines {
    set line_orig $line
    if {[add_ows? $line $rules_ignore]} {
      # add <ows> after each quoted item in the line:
      regsub -all {('[^'']+')} $line "\\1$ows" line
      # add <ows> after usage of things like identifier.
      foreach rule $rules_append {
        regsub -all "(\\s<?)${rule}(>?)(\\s|$)" $line "\\1${rule}\\2 <ows>\\3" line
      }
    }
    lappend lines2 $line
    if {[regexp {compound-statement	::=} $line_orig]} {
      # breakpoint
    }
  }
  
  join $lines2 "\n"
  
}

proc add_ows? {line rules} {
  if {[regexp keyword $line]} {
    #breakpoint
  }
  
  foreach rule $rules {
    if {[regexp "$rule>? ?::=" $line]} {
      return 0
    }
  }
  if {[regexp keyword $line]} {
    #breakpoint
  }
  return 1
}

# [2017-01-03 21:52] Old version which does some extra processing which was useful at the start, not anymore.
proc transform_old {text until_line} {
  global keywords OWS
  if {$OWS} {
    set ows " <ows>"
  } else {
    set ows ""
  }
  # breakpoint
  # don't include |, is used in BNF itself.
  foreach chars {, : * ? \{ \} || << >> ^ / % ++ -- -> = == > < >= <= + - . ~ ! *= /= += -= <<= >>= ^= != |= %= ... ; ( ) [ ]} {
    # regsub -all " \\$char " $text " '$char' " text
    regsub -all [to_regexp $chars] $text " '$chars'$ows\\1" text
  }
  # & and && have special syntax in regsub, so specific replace.
  regsub -all { \&([ \n])} $text " '\\&'$ows\\1" text
  regsub -all { \&\&([ \n])} $text " '\\&\\&'$ows\\1" text
  regsub -all { \&=([ \n])} $text " '\\&='$ows\\1" text
  foreach keyword $keywords {
    regsub -all " ${keyword}(\[ \\n\])" $text " '$keyword'$ows\\1" text
  }

  # keep text until until_line, replace rest with trivial LHS ::= 'LHS'
  set lines [split $text "\n"]
  set keep_lines [lrange $lines 0 $until_line]
  set other_lines [lrange $lines $until_line end]
  set all_lines $keep_lines
  foreach line $other_lines {
    if {[regexp {^<([a-z-]+)> ::=} $line z lhs]} {
      lappend all_lines "<$lhs> ::= '$lhs'"
      lappend all_lines ""
    }
  }

  # Add dummy rules when they only appear on RHS, not LHS.
  # [2017-01-03 21:50] Not used anymore.
  set lhs_rules [find_lhs_rules $all_lines]
  set rhs_rules [find_rhs_rules $all_lines]
  set new_rules [::struct::set difference $rhs_rules $lhs_rules]
  foreach rule $new_rules {
    # [2016-12-31 22:32] Nu even niet meer doen.
    # lappend all_lines "<$rule> ::= '$rule'"
  }

  # temporary, add to source:
  # lappend all_lines [keyword_def]

  
  join $all_lines "\n"
  
  # return $text
}


proc keyword_def {} {
  global keywords
  set quoted_keywords [map [fn x {return "'$x'"}] $keywords]
  return "<keyword> ::= [join $quoted_keywords " | "]"
}

proc find_lhs_rules {lines} {
  set res [list]
  foreach line $lines {
    if {[regexp {^<([a-z-]+)> ::=} $line z lhs]} {
      lappend res $lhs
    }
    # also without <>
    if {[regexp {^([a-z-]+) ::=} $line z lhs]} {
      lappend res $lhs
    }
    
  }
  return $res
}

proc find_rhs_rules {lines} {
  set res [list]
  foreach line $lines {
    foreach {_ rhs} [regexp -all -inline {<([a-z-]+)>} $line] {
      lappend res $rhs
    }
  }
  return $res
}

proc to_regexp {chars} {
  set res " "
  foreach char [split $chars ""] {
    append res "\\$char"
  }
  append res "(\[ \\n\])"
  return $res
}

main $argv
