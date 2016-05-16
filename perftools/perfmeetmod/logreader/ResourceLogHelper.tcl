package require Itcl
package require ndv

itcl::class ResourceLogHelper {
  private common log
	# set log [::ndv::CLogger::new_logger [file tail [info script]] info]
  set log [::ndv::CLogger::new_logger [file tail [info script]] debug]
	  
  private common instance  ""

  public proc get_instance {} {
    if {$instance == ""} {
   		set instance [uplevel {namespace which [ResourceLogHelper #auto]}]
    }
    return $instance  
  }

  private variable db
  private variable ar_resname_id
  private variable ar_machine
  
  public method set_db {a_db} {
    set db $a_db 
  }

  public method det_resname_id {fullname} {
    # $log debug "det_resname_id for fullname: $fullname"
    # 15-1-2010 array names -exact nodig, want array get gebruikt string match, en werkt niet bij bv "Memory\Available MBytes"
    if {[array names ar_resname_id -exact $fullname] == {}} {
      # if not in cache, search in database
      $log debug "det_resname_id: $fullname not found in cache, look in database..."
      $log debug "cache: [array names ar_resname_id]"
      set resname_ids [$db find_objects resname -fullname $fullname]
      if {$resname_ids == {}} {
        $log debug "$fullname not found in database, make new record"
        if {![regexp {\\(.+)$} $fullname z graphlabel]} {
          set graphlabel $fullname 
        }
        set resname_id [$db insert_object resname -fullname $fullname -graphlabel $graphlabel]
      } else {
        set resname_id [lindex $resname_ids 0] 
      }
      set ar_resname_id($fullname) $resname_id
    }
    return $ar_resname_id($fullname)
  }
  
  # @return name
  # @side-effect: machine is added to database table machine, and also put in cache.
  public method det_machine {name} {
    # $log debug "det_resname_id for fullname: $fullname"
    # 15-1-2010 array names -exact nodig, want array get gebruikt string match, en werkt niet bij bv "Memory\Available MBytes"
    if {[array names ar_machine -exact $name] == {}} {
      # if not in cache, search in database
      $log debug "det_machine: $name not found in cache, look in database..."
      $log debug "cache: [array names ar_machine]"
      set lst [$db find_objects machine -name $name]
      if {$lst == {}} {
        $log debug "$name not found in database, make new record"
        set type $name        
        $db insert_object machine -name $name -type $type
      } else {
        set name [lindex $lst 0] 
      }
      set ar_machine($name) $name
    }
    return $ar_machine($name)
  }  
  
  
}
