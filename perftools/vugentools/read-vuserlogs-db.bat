tclsh read-vuserlogs-db.tcl -dir C:\pcc\Nico\Testruns\BigIP\run320 -db C:\pcc\Nico\Testruns\BigIP\bigip.db
tclsh read-vuserlogs-db.tcl -dir C:\pcc\Nico\Testruns\BigIP\run341 -db C:\pcc\Nico\Testruns\BigIP\bigip.db
tclsh read-vuserlogs-db.tcl -dir C:\pcc\Nico\Testruns\BigIP\run360 -db C:\pcc\Nico\Testruns\BigIP\bigip.db
tclsh read-vuserlogs-db.tcl -dir C:\pcc\Nico\Testruns\BigIP\run367 -db C:\pcc\Nico\Testruns\BigIP\bigip.db
rem tclsh read-vuserlogs-db.tcl -dir C:\pcc\Nico\Testruns\BigIP\run368 -db C:\pcc\Nico\Testruns\BigIP\bigip.db

cd C:\pcc\Nico\nicoprj\dbtools
tclsh C:\pcc\Nico\nicoprj\dbtools\excel2db.tcl -dir c:\PCC\Nico\Projecten\BigIP-Combitest\Certificates -db C:\pcc\Nico\Testruns\BigIP\bigip.db -table certs
cd -
