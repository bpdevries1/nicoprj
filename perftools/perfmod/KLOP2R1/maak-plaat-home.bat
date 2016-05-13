set DOT_DIR=C:\util\graphviz\Graphviz\bin

echo y | del generated\* /q >&nul
mkdir generated >&nul

tclsh maak-mapping-model.tcl 
%DOT_DIR%\dot.exe -Tpng generated\klop2-mapping.dot -o generated\\klop2-mapping.png
%DOT_DIR%\dot.exe -Tpng generated\legenda.dot -o generated\\legenda.png

