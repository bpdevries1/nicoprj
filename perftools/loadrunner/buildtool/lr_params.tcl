# Both real LR params (like set with Ctrl-L) as vars/params set in code are handled here.
# There is an overlap with add_param type=param.

task check_lr_params {Check LR parameter settings
  For each parameter, check:
  * not set to sequential - should only be used for script testing.
  * first row != 1        - should only be used for script testing.
} {
  foreach filename [glob -nocomplain *.prm] {
    check_lr_params_file $filename
  }
}

proc check_lr_params_file {filename} {
  set f [open $filename r]
  set param "<none>"
  while {[gets $f line] >= 0} {
    if {[regexp {^\[parameter:(.+)\]$} $line z pm]} {
      set param $pm
    } elseif {[regexp {SelectNextRow="([^""]+)"} $line z sel]} {
      if {$sel == "Sequential"} {
        puts "WARNING: $param: $line"
      }
    } elseif {[regexp {StartRow="(\d+)"} $line z st]} {
      if {$st != 1} {
        puts "WARNING: $param: $line"
      }
    }
  }
  close $f
}

task add_param {Add var/param to script
  Syntax: add_param <name> int|str var|param [<default>]
  Adds a config-parameter (not a LR-param) to the project, in the following locations:
  globals.h - iff it should be a var
  vuser_init.c - to set var or param
  *.config - to add var/param
} {
  # TODO: aan .config toevoegen, want dan moeten deze eerst bestaan.
  lassign $args name datatype varparam default_val
  if {$default_val == ""} {
    if {$datatype == "int"} {
      set default_val 0
    } elseif {$datatype == "str"} {
      set default_val ""
    } else {
      puts "Unknown datatype: $datatype (args=$args)"
      task_help add_param
      exit
    }
  }
  if {$varparam == "var"} {
    globals_add_var $name $datatype
  }
  add_param_configs $name $default_val
  vuser_init_add_param $name $datatype $varparam $default_val
}

proc add_param_configs {name default_val} {
  #set line "$name=$default_val"
  set line "$name = $default_val"
  foreach configname [glob -nocomplain *.config] {
    set text [read_file $configname]
    if {[lsearch -regexp [split $text "\n"] "^\\s*$name\\s*="] < 0} {
      set fo [open [tempname $configname] w]
      puts $fo $text
      puts $fo $line
      close $fo
      commit_file $configname
    }
  }
}

task param_domain {set domain param and replace within requests in action files
  Syntax: param_domain <domain>
} {
  lassign $args domain
  task_regsub -action -do $domain "{domain}"
  task_add_param domain str param $domain
}

# add iteration parameter to the script, iff it does not exist yet (idempotent)
proc add_param_iteration {} {
  # .usr: set ParameterFile=<script>.prm
  set prm_file [script_filename prm]
  set usr_file [script_filename usr]
  set ini [ini_read $usr_file]
  ini_set_param $ini General ParameterFile $prm_file
  ini_write $usr_file $ini

  # add param in .prm file
  set ini [ini_read $prm_file 0]
  set header "parameter:iteration"
  if {[:# [ini_lines $ini $header]] == 0} {
    set lines "Format=\"%d\"
OriginalValue=\"\"
Type=\"CurrentIteration\"
ParamName=\"iteration\""
    set ini [ini_set_lines $ini $header $lines] 
  }
  ini_write $prm_file $ini
  
  add_file_metadata $prm_file
}

