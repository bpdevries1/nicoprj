package require XOTcl
namespace import -force xotcl::*

package require struct::pool

Class IntPool

IntPool instproc init {} {
  # my set p [struct::pool intpool 50000]
  my instvar p max_id
  set p [struct::pool]
  $p maxsize 50000
  set max_id 0
}

IntPool instproc request {} {
  my instvar p max_id
  if {[$p request item]} {
    return $item 
  } else {
    incr max_id
    # 8-12-2012 item moet wel aan pool toegevoegd worden meteen, anders later problemen met add/release, welke te kiezen.
    $p add $max_id
    $p request item
    # return $max_id
    return $item
  }
}

IntPool instproc release {item} {
  my instvar p
  $p release $item  
}

