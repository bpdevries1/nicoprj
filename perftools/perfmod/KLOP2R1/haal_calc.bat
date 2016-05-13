pause Druk op een toets om ingecheckte model en properties te verwijderen en gegenereerde op te halen.

echo Y | del /f KLOP2R1.xmltmp
echo Y | del /f KLOP2R1-*.xmlinc
echo Y | del /f KLOP2R1*.lqnprop
echo R | copy generated\KLOP2R1.xmltmp .
echo R | copy generated\KLOP2R1-*.xmlinc .
echo R | copy generated\KLOP2R1*.lqnprop .
cd ..
call calc-model.bat KLOP2R1 >& KLOP2R1\KLOP2R1.out
cd -
c:
cd KLOP2R1
type KLOP2R1.out


