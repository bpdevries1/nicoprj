package require Itcl

# class maar eenmalig definieren
if {[llength [itcl::find classes CMediaWikiWriter]] > 0} {
	return
}

source [file join $env(CRUISE_DIR) checkout lib perflib.tcl]
source [file join $env(CRUISE_DIR) checkout script lib CLogger.tcl]
source [file join $env(CRUISE_DIR) checkout script lib CXmlHelper.tcl]

itcl::class CMediaWikiWriter {

	private common log
	set log [CLogger::new_logger mediawikiwriter debug]

	private variable page_prefix

	private variable f ; # file handle for import-file.
	private variable f_index ; # index file met alle pagina's
	private variable f_page ; # file per page, ter controle.
	private variable xml_helper

	private variable current_page

	public proc new_media_wiki_writer {target_dir} {
		set result [uplevel {namespace which [CMediaWikiWriter #auto]}]
		$result init $target_dir
		return $result
	}

	private variable target_dir

	private constructor {} {
		set target_dir ""	
		set page_prefix "Portals-"
		set xml_helper [CXmlHelper #auto]
		set f -1
		set f_page -1
		set f_index -1
		set current_page ""
	}

	public method init {a_target_dir} {
		set_target_dir $a_target_dir
	}

	public method set_target_dir {a_target_dir} {
		set target_dir $a_target_dir
	}

	public method all_start {} {
		set f [open [file join $target_dir "mediawiki-import.xml"] w]
		$xml_helper set_channel $f
		puts $f "<mediawiki xmlns=\"http://www.mediawiki.org/xml/export-0.3/\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xsi:schemaLocation=\"http://www.mediawiki.org/xml/export-0.3/ http://www.mediawiki.org/xml/export-0.3.xsd\" version=\"0.3\" xml:lang=\"nl\">"		
		$xml_helper set_level 1
		
		set f_index [open [file join $target_dir "index.txt"] w]
	}
	
	public method all_end {} {
		puts $f "</mediawiki>"
		close $f
		
		close $f_index
	}
	
	public method page_start {a_page_name} {
		set current_page [convert_page_name ${a_page_name}]
		$xml_helper tag_start page
		$xml_helper tag_tekst title [convert_page_name ${a_page_name}]
		# $xml_helper tag_tekst title "${page_prefix}${a_page_name}"
		$xml_helper tag_start revision
		$xml_helper tag_start text "xml:space=\"preserve\""
		
		set f_page [open [file join $target_dir "${page_prefix}${a_page_name}.txt"] w]
		puts $f_index "* \[\[${page_prefix}${a_page_name}\]\]"
	}
	
	public method page_end {} {
		$xml_helper tag_end text
		$xml_helper tag_end revision
		$xml_helper tag_end page
		
		close $f_page
		
		set current_page ""
	}

	# tekst zowel naar algemene xml file als naar een aparte tekstfile
	public method tekst {tekst} {
		$xml_helper tekst $tekst
		puts $f_page $tekst
	}

	# stack neutraal
	# @param url: zonder [ en ]
	public method verwijzing {url} {
		tekst "\[\[$url\]\]"
	}

	public method lijst_start {} {
	
	}
	
	public method lijst_end {} {
	
	}

	# list-items in beide wiki's hetzelfde.
	public method lijst_item {lijst_item} {
		handle_tekst $lijst_item
	}

	public method lijst_genummerd_start {} {
		# tag_start lijst_genummerd
	}

	public method header {level tekst} {
		# @todo header is anders, aanpassen.
		set isjes [string repeat "=" [expr $level + 1]]
		handle_tekst "$isjes $tekst $isjes"
	}

	public method alinea {tekst} {
		$log debug start
		# tag_tekst alinea $tekst
		handle_tekst $tekst
		$log debug finished
	}

	# deze recursieve methode checkt of er refs in de tekst zitten en vervangt deze door links
	private method handle_tekst {tekst} {
		set tekst [convert_refs $tekst]
		set tekst [convert_codes $tekst]
		tekst $tekst
	}

	# @return tekst met refs geconverteerd naar mediawiki formaat.
	# @todo eigenlijk moet parsing in de reader class zitten.
	private method convert_refs {tekst} {
		if {[regexp {^(.*)\[([^\]]+)\](.*)$} $tekst z pre ref post]} {
			return "[convert_refs $pre][convert_ref $ref][convert_refs $post]"
		}	else {
			return $tekst
		}
	}

	# @param ref: naam van item, zonder blokhaken etc.
	# @param ref: bv {Image src='attach/AspectOrientedProgramming/wasadmin1.JPG} => [[image:<pagename>-wasadmin1.JPG]]
	# @param ref: bv {Image src='WikiServer:attach/SIBUSAanmaken/ScreenShot001.bmp' caption='Geef Bus naam' }
	private method convert_ref {ref} {
		set caption ""
		if {[regexp -nocase {\{Image src='([^']+)'( caption='([^']+)')? *\}} $ref z img_src z caption]} {
			regsub -all "'" $img_src "" img_src
			set img_src [file tail $img_src]
			if {$caption == ""} {
				return "\[\[image:$current_page-$img_src\]\]"
			} else {
				return "\[\[image:$current_page-$img_src|$caption\]\]"
			}
		} elseif {[regexp {^(.+)\|(.+)$} $ref z naam url]} {
			set naam [string trim $naam]
			set url [string trim $url]
			$log debug "url: $url"
			set tp [det_link_type url]
			if {$tp == "external"} {
				return "\[$url $naam\]"
			} elseif {$tp == "att"} {
				return "\[\[media:$current_page-$url|$naam\]\]"			
			} else {
				return "\[\[[convert_page_name $url]|$naam\]\]"
			}
		} else {
			set tp [det_link_type ref]
			if {$tp == "external"} {
				return $ref
			} elseif {$tp == "att"} {
				return "\[\[media:$current_page-$ref\]\]"			
			} else {
				return "\[\[[convert_page_name $ref]\]\]"
			}
		}			
	}

	# @post url kan aangepast zijn.
	private method is_external {url_name} {
		upvar $url_name url
		if {[regexp {^http://} $url]} {
			set url [convert_external_link $url]
			return 1
		} elseif {[regexp -nocase {^Webserver:(.*)} $url z url_part]} {
			set url "http://10.79.106.58/[convert_external_link $url_part]"
			return 1
		} elseif {[regexp -nocase {^Tomcatserver:(.*)} $url z url_part]} {
			set url "http://10.79.106.58:8080/[convert_external_link $url_part]"
			return 1
		} else {
			return 0
		}
	}

	# @post url kan aangepast zijn.
	private method det_link_type {url_name} {
		upvar $url_name url
		if {[regexp {^http://} $url]} {
			set url [convert_external_link $url]
			return external
		} elseif {[regexp -nocase {^Webserver:(.*)} $url z url_part]} {
			set url "http://10.79.106.58/[convert_external_link $url_part]"
			return external
		} elseif {[regexp -nocase {^Tomcatserver:(.*)} $url z url_part]} {
			set url "http://10.79.106.58:8080/[convert_external_link $url_part]"
			return external
		} elseif {[regexp {\.} $url]} {
			return att
		} else {
			return internal
		}
	}


	private method convert_external_link {url} {
		regsub -all " " $url "%20" url
		return $url		
	}


	# @param ref: naam=url of naam|url
	# @post de link staat in de file/channel
	private method ref_to_link {ref} {
		if {![regexp {^(.+)\|(.+)$} $ref z naam url]} {
			set naam $ref
			set url $ref
		}
		set url [to_mediawiki_url $url]
		tekst $url
	}

	private method convert_codes {tekst} {
		regsub {\\\\} $tekst "<br>" tekst
		regsub -all {\{\{\{} $tekst "<pre>" tekst
		regsub -all {\}\}\}} $tekst "</pre>" tekst
		
		regsub -all {\{\{} $tekst "<nowiki>" tekst
		regsub -all {\}\}} $tekst "</nowiki>" tekst
		
		regsub -all {__([^_]+)__} $tekst {<u>\1</u>} tekst
		
		return $tekst
		
		if {0} {
	
			if {[regexp {^(.*)\\\\$} $tekst z tks]} {
				return "${tks}<br>"
			} else {
				return $tekst
			}
		}
	}

	public method table_start {} {
		# tag_start table "border=\"1\" width=\"100%\""
		tekst "\{| border=\"1\" cellspacing=\"0\""
	}

	public method table_end {} {
		tekst "|\}"
	}

	public method table_row_start {} {
		tekst "|-"
	}
	
	public method table_row_end {} {
		# niets
	}
	
	public method table_header_cell {value} {
		handle_tekst "!$value"
	}
	
	public method table_cell {value} {
		if {[regexp {^-} $value]} {
			handle_tekst "| $value"
		} else {
			handle_tekst "|$value"
		}
	}

	private method to_mediawiki_url {url} {
		if {[regexp {^http://} $url]} {
			return $url
		} else {
			# lokale url binnen wiki
			# 	regsub -all " " $url "" url
			# return "${page_prefix}$url"
			return [convert_page_name $url]
		}
	}

	# @post page_prefix toegevoegd.
	# @post spaties verwijderd (doet jspwiki automatisch, dus ook maar in MediaWiki)
	private method convert_page_name {page_name} {
		regsub -all " " $page_name "" page_name
		return "${page_prefix}$page_name"
	}


}
