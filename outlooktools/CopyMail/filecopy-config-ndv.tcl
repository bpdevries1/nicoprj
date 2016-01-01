# test config
# de folder namen zijn case sensitive.
set src_folder {C:\PCC\Nico\Projecten\Scrittura\testpdfs}
set target_folder {c:\temp\testpdfs}

# set attachments_dir "."
# set attachments_dir "c:\\temp"

# frequencies samen 42, dus 42x uitvoeren.
# set pacing_sec 1.0
# set mails_per_sec [expr 1000.0 / 3600]
# set mails_per_sec [expr 5000.0 / 3600]
set mails_per_sec 1.0
set runtime_sec 60

# at breakdown test use a 'rampup' of 1 or 2 hours.
# set rampup_sec 120
set rampup_sec 0

# not used:
# set max_pacing_msec 5000

# mail_types - list of subject and relative number of times to create.
set mail_types {
	"barcode 1 page blackwhite.pdf"   20
	"barcode 2 page color.pdf"		   2
	"barcode 5 page blackwhite.pdf"    2
	"barcode 24 page blackwhite.pdf"   1
	"cp leading 1 page.pdf"           10
	"cp leading 4 page.pdf"			   5
	"cp leading 6 page.pdf"			   2
}

set debug 1

