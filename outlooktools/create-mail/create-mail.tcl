package require tcom

proc main {argv} {
  set app [tcom::ref getactiveobject "Outlook.Application"]
  set namespace [$app GetNamespace MAPI]
  create_mail $app $namespace
}

proc create_mail {app namespace} {
  set msg [$app CreateItem 0]
  $msg Subject "Test NdV - files"
  $msg Body "NdV - see attachments"
  set recp [$msg Recipients]
  $recp Add "nico.de.vreeze@xs4all.nl"
  set att [$msg Attachments]
  set zipdir {C:\PCC\Nico\zips}
  foreach filename [glob -directory $zipdir -type f *.zip] {
	$att Add $filename 1 1 [file tail $filename]
  }
  $msg Save
  # Send gaat 'em ook echt sturen via Exchange, wil je niet.
  # msg.Send()
}

# todo main alleen uitvoeren als dit de startende app is.
main $argv
