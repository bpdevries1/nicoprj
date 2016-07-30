# file and I/O functions

namespace eval ::libio {
  namespace export with_file

  # takes care of closing a file automatically.
  # TODO error handling, close fd even when an error occurs, but throw error.
  # @param f - name of var to use within body
  # @param fd - value of open file description, result of eg [open]
  # @param body - code to execute with open file.
  proc with_file {f_name fd body} {
    upvar $f_name f
    set f $fd
    uplevel $body
    close $fd
  }
  
}




  
