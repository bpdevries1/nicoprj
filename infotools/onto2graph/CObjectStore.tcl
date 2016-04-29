package require Itcl
package require Tclx ; #  voor cmdtrace en try_eval
package require ndv

# class maar eenmalig definieren
if {[llength [itcl::find classes CObjectStore]] > 0} {
	return
}

itcl::class CObjectStore {

	private common log
	# set log [CLogger::new_logger [file tail [info script]] info]
	set log [::ndv::CLogger::new_logger [file tail [info script]] debug] 
	
	public proc new_instance {} {
		set result [uplevel {namespace which [CObjectStore \#auto]}]
		return $result
	}
	
	public method reset_objects {} {
		global ar_objects
		array unset ar_objects
	}
	
	public method add_object {object} {
		global ar_objects
		set ar_objects($object) 1
	}
	
	public method has_object {object} {
		global ar_objects
		incr ar_objects($object) 0
		return $ar_objects($object)
	}	
	
}
