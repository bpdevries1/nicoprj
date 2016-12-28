#! /usr/bin/env tclsh

package require ndv
package require struct::set

use libfp

proc main {argv} {
  lassign $argv until_line
  set infile "clang-orig.ebnf"
  set outfile "clang.ebnf"
  set text [read_file $infile]
  # set text "ahdhasd k +\n2e regel\nnog iets met + en dan wat"
  write_file $outfile [transform $text $until_line]
}

# from http://tigcc.ticalc.org/doc/keywords.html
set keywords { auto break case char const continue default do double else enum extern float for goto if int long register return short signed sizeof static struct switch typedef union unsigned void volatile while 
}

proc transform {text until_line} {
  global keywords
  # breakpoint
  # don't include |, is used in BNF itself.
  foreach chars {, : * ? \{ \} || << >> ^ / % ++ -- -> = == > < >= <= + - . ~ ! *= /= += -= <<= >>= ^= != |= %= ... ; ( ) [ ]} {
    # regsub -all " \\$char " $text " '$char' " text
    regsub -all [to_regexp $chars] $text " '$chars' <ows>\\1" text
  }
  # & and && have special syntax in regsub, so specific replace.
  regsub -all { \&([ \n])} $text " '\\&' <ows>\\1" text
  regsub -all { \&\&([ \n])} $text " '\\&\\&' <ows>\\1" text
  regsub -all { \&=([ \n])} $text " '\\&=' <ows>\\1" text
  foreach keyword $keywords {
    regsub -all " ${keyword}(\[ \\n\])" $text " '$keyword' <ows>\\1" text
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

  set lhs_rules [find_lhs_rules $all_lines]
  set rhs_rules [find_rhs_rules $all_lines]
  set new_rules [::struct::set difference $rhs_rules $lhs_rules]
  foreach rule $new_rules {
    lappend all_lines "<$rule> ::= '$rule'"
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
