# maakbreakdown.tcl - vorm log4j.log.perf.out om naar breakdown die in performance
# rapportage te gebruiken is. De breakdown is ook tab-separated, dus doe verdere 
# behandeling in Excel of Word.
#
# syntax: tclsh maakbreakdown.tcl <log4j.log.perf.out >breakdown.txt

# print alleen tijden groter of gelijk aan 50 ms.
set TIJDTRESHOLD 50
set LOG 0

# filter punten en komma´s uit tijd
proc filterpunt tijd {
  regsub -all {\.} $tijd "" tijd
  regsub -all {\,} $tijd "" tijd
  return $tijd
}

# bepaal tijd uit regel, is 5e element
proc bepaaltijden line {
  set l [split $line "\t"]
  set tijd [filterpunt [lindex $l 4]]
  set eigentijd [filterpunt [lindex $l 8]]
  return [list $tijd $eigentijd]
}

proc bepaalinfo line {
  set l [split $line "\t"]
  set comp [lindex $l 1]
  set method [lindex $l 2]
  set aantal [lindex $l 6]
  set eigentijd [filterpunt [lindex $l 8]]
  return [list $comp $method $aantal $eigentijd]
}

proc log line {
  global stderr LOG
  if {$LOG} {
    puts stderr $line
  }
}

# sla eerst alles over tot "Summary van calls"
set gevonden 0
while {!$gevonden} {
  gets stdin line
  set gevonden [regexp "Summary van calls" $line]
}
# sla nog een paar regels over
gets stdin line
gets stdin line
gets stdin line

# hierna per groep van "Summary: xxx" behandelen.
while {![eof stdin]} {
  gets stdin line
  set line [string trim $line]
  if {[regexp "Summary: (.*)" $line z summ]} {
    log "start regel"
    # start van nieuwe summary
    set summary $summ
    gets stdin line; # header-regel
    gets stdin line; # eerste regel met totaaltijd
    set totaaltijden [bepaaltijden $line]
    set totaaltijd [lindex $totaaltijden 0]
    set eigentijd [lindex $totaaltijden 1]
    set regelstatus "geen"
    set diversentijd $eigentijd
    set tellingtijd 0
    set totaaltijdwl 0
    set totaaltijdengin 0
    set totaaltijdbo 0
    set insummary 1
    puts "Service: $summary"
    puts "comp\tnaam\tn\ttijd (ms)\twl\tcomm\tbo"
  } elseif {($line == "---") || ($line == "")} {
    log "einde regel"
    if {$insummary} {
      # einde van deze summary, mogelijk nog laatste regel behandelen
      if {$regelstatus == "normaal"} {
        # deze regel mogelijk overslaan en bij Diversen optellen
        if {$methodetijd < $TIJDTRESHOLD} {
          incr diversentijd $methodetijd
          # incr totaaltijdwl $methodetijd
        } else {
          puts "$methodecomp\t$methodenaam\t$methodeaantal\t$methodetijd"
          incr tellingtijd $methodetijd
          incr totaaltijdwl $methodetijd
        }
      }
    
      # print diversen en totaal
      # print voor debuggen ook berekende totale tijd
      puts "Diversen\t\t\t$diversentijd\t$diversentijd"
      incr totaaltijdwl $diversentijd
      puts "Totaal\t\t\t$totaaltijd\t$totaaltijdwl\t$totaaltijdengin\t$totaaltijdbo"
      set percwl [expr 100.0 * $totaaltijdwl / $totaaltijd]
      set percengin [expr 100.0 * $totaaltijdengin / $totaaltijd]
      set percbo [expr 100.0 * $totaaltijdbo / $totaaltijd]
      puts "Totaal Perc\t\t\t100%\t[format "%2.0f" $percwl]%\t[format "%2.0f" $percengin]%\t[format "%2.0f" $percbo]%"
      

      set totaalberekend [expr $tellingtijd + $diversentijd]
      # puts "Totaal berekend\t\t\t$totaalberekend"
      if {$totaaltijd != $totaalberekend} {
        puts "*** Verschil in berekening: [expr $totaaltijd - $totaalberekend]"
      }
      puts ""
      set insummary 0
    }
  } else {
    if {$insummary} {
      log "standaard regel: $line"
      # regel met breakdown info
      set info [bepaalinfo $line]; # list met comp, method, aantal en eigentijd.
      set comp [lindex $info 0]
      set naam [lindex $info 1]
      set aantal [lindex $info 2]
      set eigentijd [lindex $info 3]
      # deze info niet meteen printen, op volgende regel kan backoffice info staan...
      if {$naam == "Backoffice processing time"} {
        # einde van deze 3 regels, nu printen
        set methodetotaaltijd [expr $methodetijd + $engintijd + $eigentijd]
        puts "$comp\t$methodenaam\t$methodeaantal\t$methodetotaaltijd\t$methodetijd\t$engintijd\t$eigentijd"
        incr tellingtijd $methodetotaaltijd
        incr totaaltijdwl $methodetijd
        incr totaaltijdbo $eigentijd
        incr totaaltijdengin $engintijd
        set regelstatus "geen"
      } elseif {$naam == "Execute backoffice service"} {
        # middelste of laatste regel in backoffice call: set info, geen print
        set engintijd $eigentijd
        set regelstatus "engin"
      } else {
        # gewone regel, mogelijk nog vorige info printen
        if {$regelstatus == "geen"} {
          # geen vorige info te printen, set nieuwe vorige
          set methodecomp $comp
          set methodenaam $naam
          set methodeaantal $aantal
          set methodetijd $eigentijd
          set regelstatus "normaal"
        } elseif {$regelstatus == "normaal"} {
          # deze regel mogelijk overslaan en bij Diversen optellen
          if {$methodetijd < $TIJDTRESHOLD} {
            incr diversentijd $methodetijd
            # incr totaaltijdwl $methodetijd
          } else {
            puts "$methodecomp\t$methodenaam\t$methodeaantal\t$methodetijd\t$methodetijd"
            incr tellingtijd $methodetijd
            incr totaaltijdwl $methodetijd
          }
          set methodecomp $comp
          set methodenaam $naam
          set methodeaantal $aantal
          set methodetijd $eigentijd
          set regelstatus "normaal"
        } elseif {$regelstatus == "engin"} {
          # alleen engin-info, geen backoffice processing tijd
          set methodetotaaltijd [expr $methodetijd + $engintijd]
          puts "$methodecomp\t$methodenaam\t$methodeaantal\t$methodetotaaltijd\t$methodetijd\t$engintijd"
          incr tellingtijd $methodetotaaltijd
          incr totaaltijdwl $methodetijd
          incr totaaltijdengin $engintijd
          set methodecomp $comp
          set methodenaam $naam
          set methodeaantal $aantal
          set methodetijd $eigentijd
          set regelstatus "normaal"
        } else {
          # fout
          puts "Regelstatus: $regelstatus"
          exit 1
        }
      }
    }
  }
}

