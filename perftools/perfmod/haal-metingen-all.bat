rem tclsh haal-metingen.tcl halfcpu141
rem tclsh haal-metingen.tcl whatif
rem tclsh haal-metingen-download.tcl dl-500kb

rem for %d in (dl-2bytes dl-5Mb dl-500kb halfcpu141 JSF-0.5cpu JSF-3cpu JSFZ-0.5cpu JSP-0.5cpu JSP-3cpu JSPZ-0.5cpu whatif) do tclsh haal-metingen.tcl %d
for %d in (dl-2bytes dl-5Mb dl-500kb JSF-0.5cpu JSF-3cpu JSFZ-0.5cpu JSP-0.5cpu JSP-3cpu JSPZ-0.5cpu) do tclsh haal-metingen.tcl %d

