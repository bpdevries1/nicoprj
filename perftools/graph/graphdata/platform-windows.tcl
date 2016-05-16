package require ndv

::ndv::source_once platform-general.tcl ; # relative path to current file.

# set GRAPH_VIEWER_BINARY [find_newest [list C:/util/irfanview] "i_view32.exe"]

proc show_graph_file {filename} {
  # global GRAPH_VIEWER_BINARY log
  variable GRAPH_VIEWER_BINARY
  # set_if_empty is in another namespace.
  # set_if_empty GRAPH_VIEWER_BINARY [find_newest [list C:/util/irfanview] "i_view32.exe"]
  set GRAPH_VIEWER_BINARY [find_newest [list C:/util/irfanview] "i_view32.exe"]
  
  # @todo 16-9-2011 NdV log info fails now, probably something with namespaces.
  #log info "Showing graph: $filename"
  #log debug "exec: $GRAPH_VIEWER_BINARY $filename &"
  exec $GRAPH_VIEWER_BINARY [file nativename [file normalize $filename]] &
  # following from helpfile, but does not work, probably something with 4NT.
  # exec {*}[auto_execok start] {} [file nativename [file normalize $filename]]
}  

# with a single %, windows thinks it's an environment var it should handle.
proc param_format {param} {
  regsub -all "%" $param "%%" param
  return $param 
}

proc get_temp_dir_old {} {
  file mkdir "c:/tmp"
  return "c:/tmp" 
}

# 2015-11-25 c:/tmp not always available.
# TODO make dynamic.
proc get_temp_dir {} {
  file mkdir "c:/temp"
  return "c:/temp" 
}

proc get_path_sep {} {
  return ";"
}