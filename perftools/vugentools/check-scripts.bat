rem TODO - 1 project waarin alles staat? Dan alle scripts met elkaar vergelijken.

rem 26-8-2015 CBW -> Loans widget
tclsh check-scripts.tcl cbw-loans.tcl

goto end

tclsh check-scripts.tcl clrep.tcl

rem 26-8-2015 rtfxmm best nog wel verschillen nu, maar is nu niet in scope.
rem tclsh check-scripts.tcl rtfxmm.tcl


rem 26-8-2015 ClientReporting -> Loans widget
tclsh check-scripts.tcl clrep-loans.tcl


:end
