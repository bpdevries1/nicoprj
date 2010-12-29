# General functions
# 30-3-2010 wilde assert hier inzetten, maar bestaat ook al in package 'control'.

package provide ndv 0.1.1

namespace eval ::ndv {

	namespace export assert
	
  proc assert {expr {message ""}} {
    set res 1
    set code [catch {uplevel 1 [list expr $expr]} res]
    if {$code} {
      log "Assert: evaluation failed: $expr; msg = $res; message = $message" warn perflib
      error "Assert: evaluation failed: $expr"
    } else {
      if {!$res} {
        if {$message != ""} {
          set error_message $message
        } else {
          set error_message "Assert: evaluation of expr resulted in false: $expr"
        }
        log $error_message warn perflib
        error $error_message
      } else {
        # everything ok, do nothing.
      }
    }
  }
}
