# test config
set src_folder "Nico.de.Vreeze@rabobank.com/Diversen/Test"
set target_folder "Nico.de.Vreeze@rabobank.com/Diversen/Test2"

# set attachments_dir "."
set attachments_dir "c:\\temp"

# frequencies samen 42, dus 42x uitvoeren.
set pacing_sec 1.0
set runtime_sec 1000
# later iets met rampup?

# mail_types - list of subject and relative number of times to create.
set mail_types {
	"barcode 1 page blackwhite.pdf"   20
	"barcode 2 page color.pdf"		   2
	"barcode 5 page blackwhite.pdf"    2
	"barcode 24 page blackwhite.pdf"   1
	"cp leading 1 page.pdf"           10
	"cp leading 4 page.pdf"			   5
	"cp leading 6 page.pdf"			   2
	"Risicos PSA.xls"			       1
}

set debug 0

