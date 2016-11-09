# [2016-10-25 09:13:45] reconnect network drive that still is available in the 'net use' list,
# but cannot connect anymore.
# by doing a net use <drive> /d followed by a reconnect of the original command.
# maybe also save connections, when they get lost between sessions.
# [2016-10-25 09:26:45] maybe /persistent:yes is enough for now.
# [2016-11-09 13:38:07] /persistent does not work.
package require ndv
package require twapi	; # for password entry.

proc main {argv} {
  set options {
	{user.arg "" "Domain\user if set, otherwise default"}
	{pass.arg "" "Password if set, otherwise default, not given."}
	{config.arg {g:\.config\recon\recon-ndv.tcl} "System specific configuration"}
	{debug "Breakpoint after showing info, before reconnect"}
  }
  set usage ": [file tail [info script]] \[options] DRIVE:"
  # array set params [::cmdline::getoptions argv $options $usage]
  set opt [getoptions argv $options $usage]
  lassign $argv drive
  #puts "drive: $drive"
  #puts "opt: $opt"
  source [:config $opt]
  set res [exec net use $drive]
  set share [det_share $res]
  # puts "res: $res"
  puts "Reconnecting $drive => $share"
  set user [:user [dict get $share_settings $drive]]
  puts "user: $user"
  set password [:password [dict get $share_settings $drive]]
  # breakpoint
  if {$password == ""} {
	  puts -nonewline "Password: "
	  flush stdout
	  set oldmode [twapi::modify_console_input_mode stdin -echoinput false -lineinput true]
	  gets stdin password
	  # Restore original input mode
	  eval [list twapi::set_console_input_mode stdin] $oldmode

	  #puts "Password:"
	  #gets stdin pw
	  # set pw [terminal:password:get "Password: "]
  }
  
  if [:debug $opt] {
	  puts "user: $user, pw: $password"
	  breakpoint
  }
  exec net use $drive /d
  exec net use $drive $share $password /user:$user
}

proc det_share {res} {
  if {[regexp {Remote name\s+(\S+)} $res z share]} {
	return $share
  } else {
    error "Cannot determine share from: $res"
  }
}

if 0 {

                             


   [/SAVECRED]
        [[/DELETE] | [/PERSISTENT:{YES | NO}]]

		net use s: /d

		
		
		
C:\PCC\nico\nicoprj\systemtools\backup2nas>net use s: \\bxts199521\d$ /user:raboneteu\vreezen.eu /savecred /persistent:yes
A command was used with conflicting switches.

C:\PCC\nico\nicoprj\systemtools\backup2nas>net use s: \\bxts199521\d$ /user:raboneteu\vreezen.eu /persistent:yes

[2016-11-09 12:56:03] waarschijnlijk drive s: met /persistent vorige week al gedaan, maar heeft dus niet geholpen. Dus alsnog recon verder.

[2016-11-09 13:32:30] Deze al eerder op laptop gedaan:
C:\PCC\Util\Console2>net use z:
Lokale naam             z:
Externe naam            \\bxtv150003.eu.rabonet.com\HOST_VOL3_L_FS$\ISD\Corporate Banking IT\disciplines\trim\99 PCC
Type netwerkbron        Schijf
De opdracht is voltooid.

net use z: /d
net use z: "\\bxtv150003.eu.rabonet.com\HOST_VOL3_L_FS$\ISD\Corporate Banking IT\disciplines\trim\99 PCC" /persistent:yes /user:raboneteu\vreezen

[2016-11-09 14:36:16] deze kan ook, vraag of het effect heeft.
net use /persistent:yes
		
}

# [2016-11-09 14:07:05] onderstaande ook gevonden, maar dan binary nodig, voor unix ook andere manieren, zie http://wiki.tcl.tk/2392 en http://wiki.tcl.tk/3348.
# terminal:password:get
# [2016-11-09 14:08:05] voor windows twapi gebruiken:



		
main $argv
