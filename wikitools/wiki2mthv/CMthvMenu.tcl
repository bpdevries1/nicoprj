package require Itcl

# class maar eenmalig definieren
if {[llength [itcl::find classes CMthvMenu]] > 0} {
	return
}

source [file join $env(CRUISE_DIR) checkout lib perflib.tcl]
source [file join $env(CRUISE_DIR) checkout is_xml.tcl]
source [file join $env(CRUISE_DIR) checkout script tool wiki2mthv CXmlHelper.tcl]

addLogger mthvmenu
setLogLevel mthvmenu info
# setLogLevel mthvmenu debug

itcl::class CMthvMenu {

	private common PREFIX "test_v_"

	private variable dirname
	private variable filename
	private variable f
	private variable xml_helper

	public constructor {a_dirname} {
		set dirname $a_dirname
		file mkdir [file join $dirname xml]
		set filename [file join $dirname xml "${PREFIX}index.xml"]
		set f [open $filename w]
		write_header
		set xml_helper [CXmlHelper #auto]
		$xml_helper set_channel $f
		$xml_helper set_level 3
	}

	public method finish {} {
		write_footer
		close $f
		# @todo nieuwe versie ophalen.
		is_xml_check_file $filename
	}

	private method to_mthv_url {url} {
		if {[regexp {^http://} $url]} {
			return $url
		} else {
			# lokale url binnen wiki/mthv
			regsub -all " " $url "" url
			return "${PREFIX}$url.xml"
		}

	}

	public method link {naam url} {
		$xml_helper tag_start link
		$xml_helper tag_tekst naam $naam
		set url "${PREFIX}${url}.xml"
		$xml_helper tag_tekst url $url
		$xml_helper tag_end link
	}

	private method write_header {} {
		set now [clock seconds]
	
		puts $f "<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<?xml-stylesheet type=\"text/xsl\" href=\"../common/xsl/webstraatwebsite.xsl\"?>

<webdocument xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xsi:noNamespaceSchemaLocation=\"../schemas/webdocument.xsd\">
  <informatiesoort>menu</informatiesoort>
  <menu>
  	<submenuregel>
  		<submenu>
		 	<titel>Performance</titel>
"
	}

	private method write_footer {} {
		puts $f "  		</submenu>
  	</submenuregel>  	
  </menu>
</webdocument>"
	}
	
}


