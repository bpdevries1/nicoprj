set db_name [file join $root_folder "aaa/akamai-parallel.db"]

set src_table_defs [list [dict create table "xenu" field "url" where "inscope='yes'"]]
  
set drop_table 0

# set ts_treshold [det_ts_treshold $ts_start 3600]
set ts_treshold [det_ts_treshold $ts_start [expr 14 * 24 * 3600]]

# set wait_after 10

