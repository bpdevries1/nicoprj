# DB schema definition for the Perfmeetmodel database.
package require Itcl
package require ndv

# ::ndv::source_once [file join $env(CRUISE_DIR) checkout lib perflib.tcl]
# 6-1-2010 NdV laden nu via package ndv.
#::ndv::source_once [file join [file dirname [info script]] lib CClassDef.tcl]
#::ndv::source_once [file join [file dirname [info script]] lib AbstractSchemaDef.tcl]

itcl::class PerfMeetModSchemaDef {
	inherit ::ndv::AbstractSchemaDef
  
  private common log
	# set log [::ndv::CLogger::new_logger [file tail [info script]] info]
  set log [::ndv::CLogger::new_logger [file tail [info script]] debug]
	
  public proc new {} {
 		set instance [uplevel {namespace which [PerfMeetModSchemaDef #auto]}]
    return $instance  
  }
  
	public constructor {} {
		# set db ""
		set conn ""
		set no_db 0 ; # default is een db beschikbaar.
    set_db_name_user_password  "indmeetmod" "perftest" "perftest"
    # set_db_name_user_password  "testmeetmod" "perftest" "perftest"
	}

	private method define_classes {} {
    $log debug "Define the 4 model classes"
    define_testrun
    define_logfile
    define_resname
    define_resusage
    define_task
    define_tempgraph
    define_machine
    define_taskdef
    define_graph
    define_task_graph
	}

	private method define_testrun {} {
		set classdef [::ndv::CClassDef::new_classdef $this testrun id]
		set classdefs(testrun) $classdef
		$classdef add_field_def id integer ; # blijkbaar toch nog nodig.
		$classdef add_field_def name string
	}

	private method define_logfile {} {
		set classdef [::ndv::CClassDef::new_classdef $this logfile id]
		set classdefs(logfile) $classdef
		$classdef add_field_def id integer ; # blijkbaar toch nog nodig.
		$classdef add_field_def testrun_id integer
    $classdef add_field_def path string 
    $classdef add_field_def kind string
    $classdef add_field_def aantal integer
	}

 	private method define_resname {} {
		set classdef [::ndv::CClassDef::new_classdef $this resname id]
		set classdefs(resname) $classdef
		$classdef add_field_def id integer ; # blijkbaar toch nog nodig.
    $classdef add_field_def fullname string
    $classdef add_field_def graphlabel string
    $classdef add_field_def tonen integer 1; # om te bepalen of resource in grafiek gezet moet worden.
  }
  
 	private method define_resusage {} {
		set classdef [::ndv::CClassDef::new_classdef $this resusage id]
		set classdefs(resusage) $classdef
		$classdef add_field_def id integer ; # blijkbaar toch nog nodig.
		$classdef add_field_def logfile_id integer
    $classdef add_field_def linenr integer 
    $classdef add_field_def machine string
    # $classdef add_field_def name string
    $classdef add_field_def resname_id integer
    $classdef add_field_def value float
    $classdef add_field_def dt datetime
    $classdef add_field_def dec_dt float
	}

 	private method define_task {} {
		set classdef [::ndv::CClassDef::new_classdef $this task id]
		set classdefs(task) $classdef
		$classdef add_field_def id integer ; # blijkbaar toch nog nodig.
		$classdef add_field_def logfile_id integer
		$classdef add_field_def threadname string 
		$classdef add_field_def threadnr integer
		$classdef add_field_def taskname string
		$classdef add_field_def dt_start datetime
		$classdef add_field_def dt_end datetime
		$classdef add_field_def sec_duration float
		$classdef add_field_def dec_start float
		$classdef add_field_def dec_end float
		$classdef add_field_def details string
	}

 	private method define_tempgraph {} {
		set classdef [::ndv::CClassDef::new_classdef $this tempgraph resname_id]
		set classdefs(tempgraph) $classdef
		$classdef add_field_def resname_id integer ; # blijkbaar toch nog nodig.
    $classdef add_field_def maxvalue float
    $classdef add_field_def fct float
    $classdef add_field_def label string
  }

  # machine type (fabriek, siebel, db) ook kunnen tonen in grafiek.
 	private method define_machine {} {
		set classdef [::ndv::CClassDef::new_classdef $this machine name]
		set classdefs(machine) $classdef
		$classdef add_field_def name string
    $classdef add_field_def type string
  }

 	private method define_taskdef {} {
		set classdef [::ndv::CClassDef::new_classdef $this taskdef taskname]
		set classdefs(taskdef) $classdef
		$classdef add_field_def taskname string
    $classdef add_field_def graphlabel string
  }

 	private method define_graph {} {
		set classdef [::ndv::CClassDef::new_classdef $this graph id]
		set classdefs(graph) $classdef
		$classdef add_field_def id integer 
		$classdef add_field_def path string
  }

 	private method define_task_graph {} {
		set classdef [::ndv::CClassDef::new_classdef $this task_graph id]
		set classdefs(task_graph) $classdef
		$classdef add_field_def id integer 
    $classdef add_field_def task_id integer
		$classdef add_field_def graph_id integer
		$classdef add_field_def tag integer
  }
  
}

