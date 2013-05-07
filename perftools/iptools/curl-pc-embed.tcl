# set conn [open_db "~/Dropbox/Philips/Akamai/akamai.db"]
# @note 6-5-2013 NdV even curlgetheader2, want loopt thuis ook nog, weer mergen morgen.
set db_name [file join $root_folder "aaa/akamai.db"]

set table_def [make_table_def curlgetheader ts_start ts fieldvalue param exitcode resulttext msec cacheheaders akamai_env iter cacheable expires expiry cachetype maxage]
set src_table_defs [list [dict create table embedded field url] \
                         [dict create table embedded field embed]]
  
set drop_table 0

# set ts_treshold [det_ts_treshold $ts_start 3600]
set ts_treshold [det_ts_treshold $ts_start [expr 7 * 24 * 3600]]
