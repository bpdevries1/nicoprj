rem padnamen worden te lang voor gnuplot, dus ga naar t: (is een subst van ..\perf)

T:
cd \model\showcase

rem for %d in (dl-2bytes dl-5Mb dl-500kb halfcpu141 JSF-0.5cpu JSF-3cpu JSFZ-0.5cpu JSP-0.5cpu JSP-3cpu JSPZ-0.5cpu whatif) do call calc-model.bat %d
for %d in (dl-2bytes dl-5Mb dl-500kb JSF-0.5cpu JSF-3cpu JSFZ-0.5cpu JSP-0.5cpu JSP-3cpu JSPZ-0.5cpu) do call calc-model.bat %d

rem call calc-model.bat halfcpu141
rem call calc-model.bat whatif
rem call calc-model.bat dl-500kb


C:

