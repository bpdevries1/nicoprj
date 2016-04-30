# test config
# de folder namen zijn case sensitive.
set src_folder "Nico.de.Vreeze@rabobank.com/Diversen/Test"
# set target_folder "Nico.de.Vreeze@rabobank.com/Diversen/Test2"

# set attachments_dir "."
set attachments_dir "c:\\temp"

# frequencies samen 42, dus 42x uitvoeren.
# set pacing_sec 1.0
# set mails_per_sec [expr 1000.0 / 3600]
# set mails_per_sec [expr 5000.0 / 3600]
set mails_per_sec 0.5
set runtime_sec 30

# at breakdown test use a 'rampup' of 1 or 2 hours.
# set rampup_sec 120
set rampup_sec 0

# not used:
# set max_pacing_msec 5000

# mail_types - list of subject and relative number of times to create.
set mail_types {
	"barcode 1 page blackwhite.pdf"   10 mail
	"barcode 2 page color.pdf"		  10 mail
	"barcode 5 page blackwhite.pdf"   10 mail
	"barcode 24 page blackwhite.pdf"  10 mail
	"cp leading 1 page.pdf"           10 mail
	"cp leading 4 page.pdf"			   0 mail
	"cp leading 6 page.pdf"			   0 mail
	"Risicos PSA.xls"			       0 fax
	"Fax sent (3p) to '+31307124088' @+31307124088" 10 fax
}

set mail_types_orig {
	"barcode 1 page blackwhite.pdf"   20 mail
	"barcode 2 page color.pdf"		   2 mail
	"barcode 5 page blackwhite.pdf"    2 mail
	"barcode 24 page blackwhite.pdf"   1 mail
	"cp leading 1 page.pdf"           10 mail
	"cp leading 4 page.pdf"			   5 mail
	"cp leading 6 page.pdf"			   2 mail
	"Risicos PSA.xls"			       1 fax
	"Fax sent (3p) to '+31307124088' @+31307124088" 10 fax
}

set target_folders {
  mail {
    "Nico.de.Vreeze@rabobank.com/Diversen/Test/mail1"
	"Nico.de.Vreeze@rabobank.com/Diversen/Test/mail2"
	"Nico.de.Vreeze@rabobank.com/Diversen/Test/mail3"
  }
  fax {
    "Nico.de.Vreeze@rabobank.com/Diversen/Test/fax1"
  }
}

set debug 1

