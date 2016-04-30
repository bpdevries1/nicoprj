Tools for analysing, correlating and parameterising Loadrunner VUGen scripts.

Meeste in VugenTcl.graphml, export in VugenTcl.png

Some desriptions:
add-logtransalways.tcl - in/out: c script files.
check-regexp-conc.tcl - in: c script file. Just check if web_reg_save is in concurrent section.
combine-user-dat.tcl - in/out: user.dat - used to combine RCC/CBW user files, for user200mix.dat
compare-user-40.tcl - leest wel user files, niets met DB. kan wat zijn hier.
find-double-files.tcl - iets met opschonen van sources, beetje vaag.
lwlog2users.tcl - leest wel vuserlog, output gewoon als tekst.
read-certs.tcl - zet alle bestaande certs (alleen de userid) in een DB.
read-results-db.tcl - read several results sqlite db's (trans, error_iter) into one user-info DB.
read-user-dat.tcl - read several user.dat files (in Vugen scritps) into one user-info DB.
read-vuserlogs-db.tcl - leest vuserlogs en vult tabellen (retraccts), trans, error, error_iter
sqlpivot.tcl - algemeen, 'platslaan' van data, meerdere kolommen maken. Dus meer kolommen, minder rijen.
user-invalid-remove.tcl - input losse files. Eigenlijk is dit een one-off script, niet verder bruikbaar.
vugenclean.tcl - opschonen script dirs, ivm backuppen naar netwerk schijf.
vugenlog2requests.tcl - http requests afleiden uit vugenlog. Output: file met url's en domeinen.

