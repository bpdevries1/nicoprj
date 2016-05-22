package require Itcl
package require struct ; # voor stack

# class maar eenmalig definieren
if {[llength [itcl::find classes CMthvFile]] > 0} {
	return
}

source [file join $env(CRUISE_DIR) checkout lib perflib.tcl]
source [file join $env(CRUISE_DIR) checkout is_xml.tcl]
source [file join $env(CRUISE_DIR) checkout script tool wiki2mthv CXmlHelper.tcl]

addLogger mthvfile
setLogLevel mthvfile info
# setLogLevel mthvfile debug

itcl::class CMthvFile {

	private common PREFIX "test_v_"

	private variable dirname
	private variable basename
	private variable filename
	private variable f
	private variable el_stack
	private variable xml_helper
	private variable hoofdstuknr

	public constructor {a_dirname a_basename} {
		set dirname $a_dirname
		set basename $a_basename
		file mkdir [file join $dirname xml]
		set filename [file join $dirname xml "${PREFIX}[to_mthv_basename ${basename}].xml"]
		set f [open $filename w]
		write_header
		set hoofdstuknr 0
		set el_stack [::struct::stack]
		set xml_helper [CXmlHelper #auto]
		$xml_helper set_channel $f
		$xml_helper set_level 1
	}

	public method finish {} {
		empty_stack
		write_footer
		close $f
		is_xml_check_file $filename
	}

	# @post beschrijving op de stack
	public method beschrijving_start {titel} {
		# beschrijving is top_level, eerst stack leegmaken.
		log "start" debug mthvfile
		empty_stack

		incr hoofdstuknr
		# $xml_helper tag_start beschrijving
		# $el_stack push beschrijving
		tag_start beschrijving
		$xml_helper tag_tekst titel "${hoofdstuknr}. $titel"
		# in titel niet mogelijk refs te gebruiken, helaas, dus als ref toevoegen.
		# tag_tekst titel "${hoofdstuknr}. $titel"
		
		log "finished" debug mthvfile
	}

	# stack neutraal
	# @param url: zonder [ en ]
	public method verwijzing {url} {
		tag_start verwijzing
		tekst "\[$url\]"
		tag_end verwijzing
	}

	public method lijst_item {lijst_item} {
		if {[stack_peek] != "lijst_genummerd"} {
			lijst_genummerd_start
		}
		tag_start lijstitem
		tag_tekst tekst $lijst_item
		tag_end lijstitem
	}

	public method lijst_genummerd_start {} {
		if {![stack_contains "omschrijving"]} {
			omschrijving_start
		}
		tag_start lijst_genummerd
	}

	public method omschrijving_start {} {
		if {![stack_contains "beschrijving"]} {
			beschrijving_start "Titel"
		}
		tag_start omschrijving
	}

	public method alinea {tekst} {
		if {[stack_peek] != "tekst"} {
			tekst_start
		}
		tag_tekst alinea $tekst
	}

	public method tekst_start {} {
		if {![stack_contains "omschrijving"]} {
			omschrijving_start
		}
		tag_start tekst
	}

	public method tag_start {tagname} {
		$xml_helper tag_start $tagname
		$el_stack push $tagname
	}

	public method tag_end {{tagname_check ""}} {
		set tagname [$el_stack pop]
		if {$tagname_check != ""} {
			if {$tagname != $tagname_check} {
				fail "Tagstart and end not equal: start=$tagname_check, end=$tagname"
			}
		}
		$xml_helper tag_end $tagname
	}

	public method tag_tekst {tagname tekst} {
		# $xml_helper tag_tekst $tagname $tekst
		$xml_helper tag_start $tagname
		tekst $tekst
		$xml_helper tag_end $tagname
	}

	# deze recursieve methode checkt of er refs in de tekst zitten en vervangt deze door links
	private method tekst {tekst} {
		if {[regexp {^(.*)\[([^\]]+)\](.*)$} $tekst z pre ref post]} {
			tekst $pre
			# $xml_helper tekst [ref_to_link $ref]
			ref_to_link $ref
			tekst $post
		} else {
			$xml_helper tekst $tekst
		}
	}

	# @param ref: naam=url of naam|url
	# @post de link staat in de file/channel
	private method ref_to_link {ref} {
		if {![regexp {^(.+)\|(.+)$} $ref z naam url]} {
			set naam $ref
			set url $ref
		}
		set url [to_mthv_url $url]
		tag_start link
		tag_tekst naam $naam
		tag_tekst url $url
		tag_end link
		# return "<link><naam>$naam</naam><url>$url</url></link>"
	}

	public method table_start {} {
		# tag_start table "border=\"1\" width=\"100%\""
		if {[stack_peek] != "tekst"} {
			tekst_start
		}
		tag_start table
		tag_start tbody
	}

	public method table_end {} {
		tag_end tbody
		tag_end table
	}

	private method to_mthv_basename {basename} {
		return $basename
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

	private method write_header {} {
		set now [clock seconds]
	
		puts $f "<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<?xml-stylesheet type=\"text/xsl\" href=\"../common/xsl/webstraatwebsite.xsl\"?>
<webdocument xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xsi:noNamespaceSchemaLocation=\"../schemas/webdocument.xsd\">
<informatiesoort>bestpractice</informatiesoort>
<bestpractice>
	<titel>${basename}</titel>
	<algemeen>
	  <doel>Doel: ${basename}</doel>
	  <doelgroep_dpo>
	    <architect>false</architect>
	    <ontwerper>false</ontwerper>
	    <bouwer>false</bouwer>
	    <tester>true</tester>
	    <configuratie_beheerder>false</configuratie_beheerder>
	  </doelgroep_dpo>
	  <doelgroep_rup>
	    <d_software_architect>false</d_software_architect>
	    <d_system_analist>false</d_system_analist>
	    <d_designer>false</d_designer>
	    <d_database_designer>false</d_database_designer>
	    <d_userinterface_designer>false</d_userinterface_designer>
	    <d_implementor>false</d_implementor>
	    <d_integrator>false</d_integrator>
	    <d_tester>true</d_tester>
	  </doelgroep_rup>
	  <fase_dpo>
	    <ontwerp>true</ontwerp>
	    <realisatie>true</realisatie>
	    <assemblage>true</assemblage>
	    <acceptatie>true</acceptatie>
	    <versiebeheer>false</versiebeheer>
	  </fase_dpo>
	  <fase_rup>
	    <inception>true</inception>
	    <elaboration>true</elaboration>
	    <construction>true</construction>
	    <transition>false</transition>
	  </fase_rup>
	  <categorie>
	    <architectuur_ontwerp>false</architectuur_ontwerp>
	    <gereedschap_infrastructuur>true</gereedschap_infrastructuur>
	    <referentie_implementatie>true</referentie_implementatie>
	    <technieken>true</technieken>
	    <voortbrengingsproces>false</voortbrengingsproces>
	  </categorie>
	  <versie>0.1</versie>
	  <versie_datum>
	    <dag>[clock format $now -format "%d"]</dag>
	    <maand>[clock format $now -format "%m"]</maand>
	    <jaar>[clock format $now -format "%Y"]</jaar>
	  </versie_datum>
	  <status>concept</status>
	</algemeen>"
	}

	private method write_footer {} {
		puts $f "</bestpractice>
</webdocument>"
	}
	
	private method empty_stack {} {
		log "start" debug mthvfile
		# puts $f "<tag1>*** GROTE ONZIN ***</tag1>"
		while {[$el_stack size] > 0} {
			set el [$el_stack pop]
			$xml_helper tag_end $el
		}
		
		log "finished" debug mthvfile
	}

	# check of een tag op de stack voorkomt
	private method stack_contains {tagname} {
		set n [$el_stack size]
		if {$n > 0} {
			set l [$el_stack peek $n]
			set i [lsearch -exact $l $tagname]
			if {$i == -1} {
				return 0
			} else {
				return 1
			}
		} else {
			return 0
		}
	}

	# helper methode om bug in stack implementatie op te lossen (behaviour klopt niet met doc)
	private method stack_peek {} {
		if {[$el_stack size] > 0} {
			return [$el_stack peek]
		} else {
			return ""
		}
	}
	
}


