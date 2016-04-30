# test config

#set src_folder "Mailbox - fm.eu.ScritturaGlobalXDderivativesconfirmations/PerformanceTestSource"
#set target_folder "Mailbox - fm.eu.ScritturaGlobalXDderivativesconfirmations/Inbox/Scrittura Global"

# mailbox where Scrittura puts outgoing mails.
set scrit_out_mailbox "Nico.de.Vreeze@rabobank.com/Diversen/Scrit-out"

# when a mail in outbox has been replied to, move this mail to the handled folder.
set scrit_handled_mailbox "Nico.de.Vreeze@rabobank.com/Diversen/Scrit-handled"

# mailbox where Scrittura expects incoming mails, to be read by Teleform readers
set scrit_in_mailboxes {
	"FX SPOT" "Nico.de.Vreeze@rabobank.com/Diversen/Scrit-in"
	"FX FORWARD" "Nico.de.Vreeze@rabobank.com/Diversen/Scrit-in"
	"Derivative" "Nico.de.Vreeze@rabobank.com/Diversen/Scrit-in2"
	"CRAS" "Nico.de.Vreeze@rabobank.com/Diversen/Scrit-in2"
	"CONFIRMATION" "Nico.de.Vreeze@rabobank.com/Diversen/Scrit-in2"
} 

# template file, to replace orig attachment(s) in e-mail.
set template_file {C:\PCC\Nico\Projecten\Scrittura\LPT-2015\testpdfs\barcode 1 page blackwhite.pdf}

set check_freq_sec 5
set check_max_mails 1

# even op 100 voor test.
set perc_change 100

set debug 1

