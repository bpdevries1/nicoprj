package require XOTcl
namespace import -force xotcl::*

package require struct::set

source intpool.tcl

# TODO:

# done:
# eerste doel: zelfde functionaliteit als nu. -> klaar
# dan runtime -> klaar
# dan vkey/vport -> klaar.
# NOTHING state when a vport is finished (to distinguish items)
# icm NOTHING: tijdje wachten voordat vkey wordt hergebruikt.
# alternatief: niet tijdje wachten, maar NOTHING op tijd tussen prev_ts en curr_ts zetten, dus halve minuut ertussen hier.
# hele bestand inlezen.
# plotten obv vkey en ps_runtime.

Class RuntimeStats -parameter {cb_item cb_runtime}

RuntimeStats instproc init {} {
  my instvar intpool
  my set prev_items {}
  my set curr_items {}
  my instvar dt_start
  array unset dt_start
  my set dt ""
  my set prev_dt ""
  IntPool create intpool
}

RuntimeStats instproc start_time_block {dt_fmt} {
  my instvar dt prev_dt
  set dt $dt_fmt
}

RuntimeStats instproc end_time_block {} {
  # aan het einde curr_items en prev_items vergelijken
  my instvar prev_items curr_items dt prev_dt dt_start cb_runtime cb_item vkey ar_value
  lassign [struct::set intersect3 $prev_items $curr_items] both_items old_items new_items
  foreach item $old_items {
    $cb_runtime $vkey($item) $dt_start($item) $prev_dt $item    
    array unset dt_start $item 
    intpool release $vkey($item)
    array unset vkey $item
    array unset ar_value $item
  }
  foreach item $new_items {
    set dt_start($item) $dt
    set vkey($item) [intpool request]
    $cb_item $vkey($item) $dt $item $ar_value($item)
  }
  foreach item $both_items {
    $cb_item $vkey($item) $dt $item $ar_value($item)
  }
  set prev_items $curr_items
  set curr_items {}  
  set prev_dt $dt
}

RuntimeStats instproc end_file {} {
  my set curr_items {}
  my end_time_block  
}  

RuntimeStats instproc itemline {key value} {
  #my instvar cb_item
  #my instvar cb_runtime
  #my instvar dt
  my instvar cb_item cb_runtime dt curr_items vkey ar_value
  lappend curr_items $key  
  #puts "calling callback from item"
  # $cb_item $vkey($key) $dt $key $value
  set ar_value($key) $value
  # $cb_runtime 1 $dt $dt $key
  #puts "called callback from item"
}


