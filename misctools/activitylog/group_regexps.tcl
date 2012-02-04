# lst_group_regexps: list of elements, where each element is a list of two elements: regexp and groupname
# (wanted to do something with regsub, to determine group more dynamically, but cannot find a use for it now (5-9-09)
# (Idea was to determine everything after last dash (-) and use this as a group, but don't do this now)
# init code, subject to change, therefore on top of file.
proc init_group_regexps {} {
	global lst_group_regexps
	set lst_group_regexps {}

	# as soon as one regexp returns true, the search is stopped, so the most detailed should be first.
	# @todo (maybe later) add a start and end date for the regexp's, as projects also have a start and end date.
	# @todo vaak nog wel een filename in de title-bar, maar niet de directory-naam, een find uitvoeren duurt erg lang, evt alleen in c:\projecten
	# kijken. Of is current-dir nog aan een app te vragen?
	
	add_re RWS RWS
	add_re rws RWS
	add_re Facilitor RWS 
	add_re Rijkswaterstaat RWS
	
	add_re ERI Ericsson
	add_re Ericsson Ericsson 
	add_re {Site.?.andler} Ericsson
	
	add_re TWE TweedeKamer
	add_re {Tweede Kamer} TweedeKamer 
	add_re {VLOS} TweedeKamer 
	add_re {vlos} TweedeKamer 
	
	add_re CAP CAP 
	
	add_re {STR_} Stratos
	add_re {Stratos} Stratos
	
	add_re {KEN_} Kennemer
	add_re {kg} Kennemer
	
	
	#add_re {Maasstad} Maasstad
	#add_re {MSZ_} Maasstad
	#add_re {qtp-alt.xlsx} Maasstad 
	#add_re {msz} Maasstad
	add_res Maasstad {Maasstad} {MSZ_} {qtp-alt.xlsx} {msz} {Macro Scheduler}
	
	# Van Oord vanaf 27-1-2012
	add_res VanOord {Van.?Oord} {VO_}
	
	# PA-Rol
	add_re {HPM2011} YmorPA 
	add_re {Ymor PA} YmorPA
	
	# Ymor algemeen
	add_res Ymor {uren-week} {YMR_} {Ymonitor} {TOPdesk} {YViewer} {uren-saldo}
	
	# on Linux
	add_re {Git Gui} Programming
	add_re {ActiveTcl} Programming
	add_re {VLC Media Player} Media
	add_re {nico@pclinux} General
	
	# General tools, not able to determine which (client) project.
	add_re {^Add Thoughts$} General
	add_re {^ThinkingRock } General
	add_re {^Total Commander} General
	add_re { - Mozilla Firefox} General
  add_re {- Windows Internet Explorer} General
	add_re {jEdit} General
	add_re {Programmer.s File Editor} General
	add_re {4NT} General
	add_re {Adobe Reader} General
	add_re {PowerPoint} General
	add_re {4DOS/NT Prompt} General
	add_re {PopTray} General
	add_res General {Mozilla Firefox} {Windows Task Manager}
	
	add_re { - Microsoft Outlook$} Outlook
	add_re { - Bericht} Outlook
	add_re { - Vergadering} Outlook
	add_re { - Afspraak} Outlook
	add_re { - Message} Outlook
	
	# protege
	# lappend lst_group_regexps [list {} ]

  # default, system regexps	
  add_re {Herinnering} Screensaver
  add_re {\{NONE\}} Screensaver
	
  # Empty er ook maar bij, toch als screensaver
  add_re {^$} Screensaver
}

proc add_res {group args} {
  foreach re $args {
    add_re $re $group 
  }
}

proc add_re {re group} {
  global lst_group_regexps
  lappend lst_group_regexps [list $re $group]
}

