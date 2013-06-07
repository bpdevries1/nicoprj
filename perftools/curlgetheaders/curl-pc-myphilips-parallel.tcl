set db_name [file join $root_folder "Ymor/Philips/MyPhilips/MyPhilips.db"]

set src_table_defs [list [dict create table "details" field "url_complete"]]
  
set drop_table 1

# set ts_treshold [det_ts_treshold $ts_start 3600]
# set ts_treshold [det_ts_treshold $ts_start [expr 14 * 24 * 3600]]

# treshold='0' now, do everything again (with status='todo')
# set ts_treshold [det_ts_treshold $ts_start [expr 0 * 24 * 3600]]
set ts_treshold [det_ts_treshold $ts_start [expr 1 * 24 * 3600]]
# set wait_after 10

