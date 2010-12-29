if "%UNISON%"=="" goto :error

unison nico
rem unison bdcr-c
rem unison bdcr-n
unison perftoolset

rem kan hier evt nog goto LABEL-%UNISON_LOCATION% doen, om specifieke dingen per lokatie te doen.
goto label_%UNISON_LOCATION%

goto end

:label_bd
unison bdcr-perfdata

goto end

:label_thuis
unison dw-nicodata

goto end

:error
echo Environment variable UNISON not set. Use setenv-<location>.bat

:end
