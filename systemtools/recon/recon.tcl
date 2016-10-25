# [2016-10-25 09:13:45] reconnect network drive that still is available in the 'net use' list,
# but cannot connect anymore.
# by doing a net use <drive> /d followed by a reconnect of the original command.
# maybe also save connections, when they get lost between sessions.
# [2016-10-25 09:26:45] maybe /persistent:yes is enough for now.

package require ndv

proc main {argv} {
  set options {
	{user.arg "" "Domain\user if set, otherwise default"}
	{pass.arg "" "Password if set, otherwise default, not given."}
  }
  set usage ": [file tail [info script]] \[options] DRIVE:"
  # array set params [::cmdline::getoptions argv $options $usage]
  set opt [getoptions argv $options $usage]
  lassign $argv drive
  puts "drive: $drive"
  puts "opt: $opt"
  set res [exec net use $drive]
  puts "res: $res"
}

   [/SAVECRED]
        [[/DELETE] | [/PERSISTENT:{YES | NO}]]

		net use s: /d

C:\PCC\nico\nicoprj\systemtools\backup2nas>net use s: \\bxts199521\d$ /user:raboneteu\vreezen.eu /savecred /persistent:yes
A command was used with conflicting switches.

C:\PCC\nico\nicoprj\systemtools\backup2nas>net use s: \\bxts199521\d$ /user:raboneteu\vreezen.eu /persistent:yes
		
		
main $argv
