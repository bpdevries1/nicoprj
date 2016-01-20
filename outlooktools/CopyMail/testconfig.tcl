# test config
# de folder namen zijn case sensitive.
set src_folder "Mailbox - fm.eu.ScritturaGlobalXDderivativesconfirmations/PerformanceTestSource"
set target_folder "Mailbox - fm.eu.ScritturaGlobalXDderivativesconfirmations/Inbox/Scrittura Global"

# set attachments_dir "."
set attachments_dir "C:\\Users\\deeldergj\\tmp"

# frequencies samen 42, dus 42x uitvoeren.
# set pacing_sec 1.0
# set mails_per_sec [expr 1000.0 / 3600]
set mails_per_sec [expr 5000.0 / 3600]
set runtime_sec 30

# at breakdown test use a 'rampup' of 1 or 2 hours.
# set rampup_sec 120
set rampup_sec 0

# not used:
# set max_pacing_msec 5000

# mail_types - list of subject and relative number of times to create.
set mail_types {
	"barcode 1 page original.pdf"	6
	"barcode 1 page scanned.pdf"	10
	"barcode 4 page original.pdf"	4
	"barcode 4 page scanned.pdf"	8
	"barcode 8 page scanned.pdf"	5
	"barcode 24 page scanned.pdf"	1
	"cp leading 1 page.pdf"			2
	"cp leading 6 page.pdf"			10
}

set debug 1
