package require Itcl

# class maar eenmalig definieren
if {[llength [itcl::find classes CXmlHelper]] > 0} {
	return
}

source [file join $env(CRUISE_DIR) checkout lib perflib.tcl]

addLogger xmlhelper
setLogLevel xmlhelper info
# setLogLevel xmlhelper debug

itcl::class CXmlHelper {

	private variable channel
	private variable level

	public constructor {} {
		set channel "<none>"
	}

	public method set_channel {a_channel} {
		set channel $a_channel
	}

	public method set_level {a_level} {
		set level $a_level
	}

	public method tag_start {tagname} {
		puts $channel "[to_spaces $level]<$tagname>"
		incr level
	}

	public method tag_end {tagname} {
		incr level -1
		puts $channel "[to_spaces $level]</$tagname>"
	}

	public method tag_tekst {tagname tekst} {
		puts $channel "[to_spaces $level]<$tagname>[expand_codes $tekst]</$tagname>"
	}

	public method tekst {tekst} {
		puts $channel [expand_codes $tekst]
	}

	private method to_spaces {level} {
		return [string repeat "  " $level]
	}

	private method expand_codes {tekst} {
		regsub -all "&" $tekst {\&amp;} tekst
		regsub -all "<" $tekst {\&lt;} tekst
		regsub -all ">" $tekst {\&gt;} tekst
		return $tekst
	}

}

