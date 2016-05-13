3-9-2009 Onderstaand de bevindingen van Pim Kars.

Input
- model.zip
- checkout.zip

Install ActiveTcl 8.5
install benodigde Tcl packages met getpackages

unzip lqns-models.zip naar een directory, zeg AAP
create directory AAP/checkout
	kan een willekeurige directory zijn
unzip checkout.zip in deze directory

adapt AAP/calc-model.bat -> calc-model voor bash
zie hieronder de inhoud van calc-model
belangrijk:
	set env: CRUISE_DIR=<AAP>
	set env: GNUPLOT_EXE=<filenaam van pgnuplot"

adapt in CLqnExecutor.tcl:
	set LQNS_HOME "C:\\nico\\util\\lqn\\LQN Solvers\"
	met de juiste directory naam voor LQN Solvers

copy $LQNS_HOME/*.xsd naar C:\Program Files\LQN Solvers
	de voorbeelden in de subdirectories verwachten daar de xsd

calc-model:
export CRUISE_DIR="\perf\NdV-LQNS-Tcl\NdV-Lqns-models"
export GNUPLOT_EXE="d:\utils\gnuplot-4.2.5\gnuplot\bin\pgnuplot.exe"
tclsh85 CCalcModels.tcl $1

getpackages:
teacup create    d:/apps/Tcl/repository
teacup default   d:/apps/Tcl/repository
teacup link make d:/apps/Tcl/repository d:/apps/Tcl/bin/tclsh85.exe
teacup install Itcl
teacup install Tclx
teacup install xml
teacup install xml::tcl
teacup install xmldefs
teacup install sgml
teacup install tclparser
teacup install xml::tclparser
teacup install sgmlparser
teacup install uri
teacup install struct
teacup install html
teacup install fileutil
teacup install math

