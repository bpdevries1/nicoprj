package require ndv

::ndv::source_once platform-general.tcl ; # relative path to current file.

# set GRAPH_VIEWER_BINARY [find_newest [list /bin /usr/bin /usr/local/bin ~ ~/bin] "eog"]

proc show_graph_file {filename} {
  # global GRAPH_VIEWER_BINARY
  variable GRAPH_VIEWER_BINARY
  # @todo set_if_empty doesn't work, is in another namespace.
  # set_if_empty GRAPH_VIEWER_BINARY [find_newest [list /bin /usr/bin /usr/local/bin ~ ~/bin] "eog"]
  set GRAPH_VIEWER_BINARY [find_newest [list /bin /usr/bin /usr/local/bin ~ ~/bin] "eog"]
  # @todo 16-9-2011 NdV log info fails now, probably something with namespaces.
  #log info "Showing graph: $filename"
  exec $GRAPH_VIEWER_BINARY $filename &
}  

# with a single %, windows thinks it's an environment var it should handle.
# on unix, this is no problem. (maybe a $ would be a problem)
proc param_format {param} {
  return $param 
}

proc get_temp_dir {} {
  return "/tmp" 
}

proc get_path_sep {} {
  return ":"
}