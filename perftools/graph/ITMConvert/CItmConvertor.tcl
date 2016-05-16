package require Itcl

set CLASSNAME [file rootname [file tail [info script]]]
# class maar eenmalig definieren
if {[llength [itcl::find classes $CLASSNAME]] > 0} {
	return
}

itcl::class $CLASSNAME {

	private variable header_line
	
	public proc new_instance {} {
		# Wil eigenlijk hier automatisch de classname laten bepalen
		set inst [uplevel {namespace which [CItmConvertor #auto]}]
		return $inst
	}

	private constructor {} {
		
	}
	
	public method convert_file {filename} {
		set header_filename "[file rootname $filename].H"
		read_header $header_filename
		set output_name "[file rootname $filename].tsv"
		set fi [open $filename r]
		set fo [open $output_name w]
		write_header $fo
		while {![eof $fi]} {
			gets $fi line
			puts $fo [convert_line $line]			
		}
		close $fi
		close $fo
	}

	private method read_header {header_filename} {
		set f [open $header_filename r]
		gets $f header_line
		close $f
	}
	
	private method write_header {fo} {
		puts $fo $header_line
	}
	
	private method convert_line {line} {
		# maak lijst van; op elk element een string trim; terug naar string met tabs
		return [join [map [lambda str {string trim $str}] [split $line "\t"]] "\t"]
	}
	
}