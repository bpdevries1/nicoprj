#!/usr/bin/env tclsh861

# not to run automatically, but in a separate test, to see if arrow keys etc work
# as long as tclsh is added in front, editing works fine, then rlwrap is included.
# just with ./test-breakpoint.tcl rlwrap is not included, and arrow keys don't work.
package require ndv
breakpoint

