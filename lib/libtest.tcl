# library functions for testing, built upon tcltest

package require tcltest

namespace eval ::libtest {

  # tcltest procedures should be available within libtest.
  namespace import -force ::tcltest::*
  
  namespace export testndv

  # [2016-07-22 10:13] Two arguments to the test function should be enough: expression and expected result.
  proc testndv {args} {
    global testndv_index
    incr testndv_index
    # test test-$testndv_index test-$testndv_index {*}$args
    # [2016-11-30 21:14] with this one we can use vars at parent level.
    uplevel tcltest::test test-$testndv_index test-$testndv_index $args
  }

}
