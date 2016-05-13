# exp.tcl : bepaald E(g), waarbij g(x) = max(f1(x), f2(x)), waarbij f1(x)=f2(x)=lambda*e^(-lambda*x)
proc main {} {
		 set lambda1 0.5 ; #zodat E=2
		 set lambda2 [expr 1.0 / 3.0] ; #zodat E=3
		 set lambda_call 1.0
		 set T1 0.0
		 set T2 0.0
		 set Tmax 0.0
		 set n 0
		 set i 0
		 while {1} {
		 		 incr n
		 		 incr i
		 		 set F1 [expr (-log(1-rand())/$lambda1) * (-log(1-rand())/$lambda_call)]
		 		 set F2 [expr (-log(1-rand())/$lambda2) * (-log(1-rand())/$lambda_call)]
		 		 if {$F1 > $F2} {
		 		 		 set Fmax $F1
		 		 } else {
		 		 		 set Fmax $F2
		 		 }
		 		 set T1 [expr $T1 + $F1]
		 		 set T2 [expr $T2 + $F2]
		 		 set Tmax [expr $Tmax + $Fmax]
		 		 set E1 [expr $T1 / $n]
		 		 set E2 [expr $T2 / $n]
		 		 set Emax [expr $Tmax / $n]
		 		 if {$i >= 10000} {
		 		 		 puts "[format "%1.3f" $E1] --- [format "%1.3f" $E2] --- [format "%1.3f" $Emax]"
		 		 		 set i 0
		 		 }
		 }
}

main
