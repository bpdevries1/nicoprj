rem nieuwe met obligo en koppelen onderpand.
tclsh maak-plaat.tcl -firstss 57 -lastss 67

rem orig met koppeling atvance
tclsh maak-plaat.tcl -action-dir C:\\nico\\orig_finan -lastss 73

rem handmatige gemerge-de
tclsh maak-plaat.tcl -action-dir C:\\nico\\nieuw_finan -lastss 73

tclsh maak-plaat.tcl -action-dir C:\\nico\\orig_statusovergang

rem nieuw voor A9
tclsh maak-plaat.tcl -firstss 74

rem voor test-status
tclsh maak-plaat.tcl -action-dir C:\\nico\\test_status_2_0_55d\\gen-action
