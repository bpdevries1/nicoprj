rem tclsh read-vuserlogs-db.tcl -dir C:\pcc\Nico\Testruns\BigIP\run320 -db C:\pcc\Nico\Testruns\BigIP\bigip.db
rem tclsh read-vuserlogs-db.tcl -dir C:\pcc\Nico\Testruns\BigIP\run341 -db C:\pcc\Nico\Testruns\BigIP\bigip.db
rem tclsh read-vuserlogs-db.tcl -dir C:\pcc\Nico\Testruns\BigIP\run360 -db C:\pcc\Nico\Testruns\BigIP\bigip.db
rem tclsh read-vuserlogs-db.tcl -dir C:\pcc\Nico\Testruns\BigIP\run367 -db C:\pcc\Nico\Testruns\BigIP\bigip.db
rem tclsh read-vuserlogs-db.tcl -dir C:\pcc\Nico\Testruns\BigIP\run368 -db C:\pcc\Nico\Testruns\BigIP\bigip.db

rem tclsh read-vuserlogs-db.tcl -dir C:\pcc\Nico\Testruns\Akamai-ddos\run407 -db C:\pcc\Nico\Testruns\Akamai-ddos\akamai.db
rem tclsh read-vuserlogs-db.tcl -dir C:\pcc\Nico\Testruns\Akamai-ddos\run408 -db C:\pcc\Nico\Testruns\Akamai-ddos\akamai-408.db
rem tclsh read-vuserlogs-db.tcl -dir C:\pcc\Nico\Testruns\Akamai-ddos\run418 -db C:\pcc\Nico\Testruns\Akamai-ddos\cleanup-418.db
rem tclsh read-vuserlogs-db.tcl -dir C:\pcc\Nico\Testruns\RCC-CBW\run433 -db C:\pcc\Nico\Testruns\RCC-CBW\run433.db
rem tclsh read-vuserlogs-db.tcl -dir C:\pcc\Nico\Testruns\RCC-CBW\run435 -db C:\pcc\Nico\Testruns\RCC-CBW\run435.db
rem tclsh read-vuserlogs-db.tcl -dir C:\pcc\Nico\Testruns\RCC-CBW\run442 -db C:\pcc\Nico\Testruns\RCC-CBW\run442.db
rem tclsh read-vuserlogs-db.tcl -dir C:\pcc\Nico\Testruns\RCC-CBW\run464 -db C:\pcc\Nico\Testruns\RCC-CBW\run464.db
rem tclsh read-vuserlogs-db.tcl -dir C:\pcc\Nico\Testruns\DotCom\run442 -db C:\pcc\Nico\Testruns\DotCom\run442.db

rem [2016-01-19 11:21:49] dotcom testen.
rem tclsh read-vuserlogs-db.tcl -dir C:\pcc\Nico\Testruns\Dotcom\run455 -db C:\pcc\Nico\Testruns\Dotcom\run455.db
rem tclsh read-vuserlogs-db.tcl -dir C:\pcc\Nico\Testruns\Dotcom\run455a -db C:\pcc\Nico\Testruns\Dotcom\run455a.db

rem tclsh read-vuserlogs-db.tcl -dir C:\pcc\Nico\Testruns\clientreporting\run-20160208a -db C:\pcc\Nico\Testruns\clientreporting\clrep20160208b.db
rem tclsh read-vuserlogs-db.tcl -dir C:\pcc\Nico\Testruns\clientreporting\run529 -db C:\pcc\Nico\Testruns\clientreporting\run529.db
rem tclsh read-vuserlogs-db.tcl -dir C:\pcc\Nico\Testruns\clientreporting\run535 -db C:\pcc\Nico\Testruns\clientreporting\run535.db
rem tclsh read-vuserlogs-db.tcl -dir C:\pcc\Nico\Testruns\clientreporting\run535a -db C:\pcc\Nico\Testruns\clientreporting\run535a.db

rem tclsh read-vuserlogs-db.tcl -dir C:\pcc\Nico\Testruns\RCC-CBW\vugen-20160215c -db C:\pcc\Nico\Testruns\RCC-CBW\vugen-20160215c.db
rem tclsh read-vuserlogs-db.tcl -dir C:\pcc\Nico\Testruns\RCC-CBW\run480 -db C:\pcc\Nico\Testruns\RCC-CBW\run480.db
rem tclsh read-vuserlogs-db.tcl -dir C:\PCC\Nico\projecten-no-sync\scrittura\LST-20160324\PUT-msg -db C:\pcc\Nico\Testruns\Scrittura\LST-20160324.db
rem tclsh read-vuserlogs-db.tcl -dir C:\PCC\Nico\projecten-no-sync\scrittura\LST-20160324\PUT-msg\take3 -db C:\pcc\Nico\Testruns\Scrittura\LST-20160324.db

rem tclsh read-vuserlogs-db.tcl -dir C:\pcc\Nico\Testruns\clientreporting\run258 -db C:\pcc\Nico\Testruns\clientreporting\clrep20160208a.db
rem tclsh read-vuserlogs-db.tcl -dir C:\pcc\Nico\Testruns\clientreporting\run266 -db C:\pcc\Nico\Testruns\clientreporting\clrep20160208a.db

rem RCC All
rem tclsh read-vuserlogs-db.tcl -dir C:\pcc\Nico\Testruns\RCC-All\run516 -db C:\pcc\Nico\Testruns\RCC-All\run516.db
rem tclsh read-vuserlogs-db.tcl -dir C:\pcc\Nico\Testruns\RCC-All\run522 -db C:\pcc\Nico\Testruns\RCC-All\run522.db

rem [2016-04-20 10:49:24] now just specify a dir and create DB's for all subdirs where no DB exists yet.
tclsh read-vuserlogs-db-dir.tcl -dir C:\pcc\Nico\Testruns\RCC-All

goto end

cd C:\pcc\Nico\nicoprj\dbtools
tclsh C:\pcc\Nico\nicoprj\dbtools\excel2db.tcl -dir c:\PCC\Nico\Projecten\BigIP-Combitest\Certificates -db C:\pcc\Nico\Testruns\BigIP\bigip.db -table certs
cd -

:end
