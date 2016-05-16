rem [2016-04-20 10:49:24] now just specify a dir and create DB's for all subdirs where no DB exists yet.

rem even voor bouwen/debuggen
rem del C:\pcc\Nico\Testruns\RCC-All\run596.db

tclsh read-vuserlogs-db-dir.tcl -dir C:\pcc\Nico\Testruns\RCC-All
tclsh read-vuserlogs-db-dir.tcl -dir C:\pcc\Nico\Testruns\clientreporting
