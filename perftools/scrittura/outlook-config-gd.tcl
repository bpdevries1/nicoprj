# test config

#set src_folder "Mailbox - fm.eu.ScritturaGlobalXDderivativesconfirmations/PerformanceTestSource"
#set target_folder "Mailbox - fm.eu.ScritturaGlobalXDderivativesconfirmations/Inbox/Scrittura Global"

# mailbox where Scrittura puts outgoing mails.
set scrit_out_mailbox "Mailbox - fm.nl.utrecht.ScritturaGlobalOutgoing/Inbox/ScritturaGlobalXD (PAT)/mail"

# when a mail in outbox has been replied to, move this mail to the handled folder.
set scrit_handled_mailbox "Mailbox - fm.nl.utrecht.ScritturaGlobalOutgoing/Handled"

# mailbox where Scrittura expects incoming mails, to be read by Teleform readers
set scrit_in_mailboxes {
	"DerivativesConfirmations@rabobank.com" "Mailbox - fm.eu.ScritturaGlobalXDderivativesconfirmations/Inbox/Scrittura Global"
	"UTFXMM@rabobank.com" "Mailbox - fm.eu.ScritturaGlobalXDFXMMconfirmations/Inbox/Scrittura Global"
	"fm.uk.London.DerivativesDocumentation@rabobank.com" "Mailbox - fm.eu.ScritturaGlobalXDLONconfirmations/Inbox/Scrittura Global"
	"SydneyFXMM@rabobank.com" "Mailbox - fm.eu.ScritturaGlobalXDSYDconfirmations/Inbox/Scrittura Global"
} 

# template file, to replace orig attachment(s) in e-mail.
set template_file {G:\My Documents\Gijsbert\Scrittura Global\Performance Test\cp leading 1 page.pdf}

set check_freq_sec 5
set check_max_mails 1

# even op 100 voor test.
set perc_change 0

set debug 1

