# sql script to add page_td tables in 'orig' db's
c:/nico/nicoprj/dbtools/dbscript.tcl -rootdir c:/projecten/Philips/KN-AN-Shop -dbpattern "keynotelogs.db" -script c:/nico/nicoprj/perftools/philips/tradedoubler-all.sql

# combine-tables to dashboard db
c:/nico/nicoprj/perftools/dashboardtools/combinetables.tcl -dir c:/projecten/Philips/Dashboards-Shop -srcdir c:/projecten/Philips/KN-AN-Shop -tables page_td2 -droptarget

# make graphs with tcl-R
c:/nico/nicoprj/perftools/graphtools/graph-tradedoubler.tcl -dir c:/projecten/Philips/Dashboards-Shop

