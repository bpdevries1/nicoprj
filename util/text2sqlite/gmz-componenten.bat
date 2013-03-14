@echo off
setlocal
set EXCEL=C:\projecten\GemeenteZwolle\DImpact-troubleshoot\Componenten-info\20121029_SKO_GMZ_Iventarisatie_monitors.xlsx
call excel2sqlite.bat %EXCEL%

rem hierna nog graphviz dingen.

