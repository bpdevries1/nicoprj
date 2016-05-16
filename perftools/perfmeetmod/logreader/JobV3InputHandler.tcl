# handler per type job, dus 12 instances in totaal (ook al worden 1 en 5 niet gebruikt).

package require Itcl
package require ndv

::ndv::source_once [file join [file dirname [info script]] AbstractLogReader.tcl]
::ndv::source_once [file join [file dirname [info script]] TaskLogHelper.tcl]

itcl::class JobV3InputHandler {
  
  private common log
	# set log [::ndv::CLogger::new_logger [file tail [info script]] info]
  set log [::ndv::CLogger::new_logger [file tail [info script]] debug]
	  
  private common instance  ""

  public proc new {reader log_helper} {
 		set instance [uplevel {namespace which [JobV3InputHandler #auto]}]
    $instance init $reader $log_helper
    return $instance  
  }

  protected variable reader ; # to call det_task_name
  protected variable log_helper
  
  protected variable logfile_id
  protected variable threadname
  protected variable threadnr

  protected variable ts_job_first
  protected variable ts_job_last
  protected variable job_current
  
  protected variable ar_job_taskname
  protected variable lst_re_replace
  # protected variable ar_job_names
  
  public method init {a_reader a_helper} {
    $log debug "Init"
    set reader $a_reader 
    set log_helper $a_helper
    array set ar_job_taskname {
      "Geen ok bestanden meer op de conversieserver aanwezig" check
      "Geen ok bestanden meer op de FTP-server aanwezig" check
      "Nog geen Extractie.klaar gevonden." check
      "FTP Download van overzettabellen\uitvoer naar D:\programs\conversie\manueltestdata\Overzettabellen is gereed." work
      "Overzettabellen zijn opgehaald." work
      "Data is opgehaald." work
      "FTP Download  is gereed." work
      " file gecreerd met de volgende " work
      "Fabriek gestart" work
      "Extractie.klaar is gevonden. Ophalen van data is klaar" work
      "Overzettabellen zijn verwijderd" work
      "Overzettabellen zijn opgehaald." work
      "Extractie.klaar is gevonden. Ophalen van data is klaar" work
      "Er wordt geen data meer opgehaald en er is opgeruimd." work
      "Script succesvol is afgerond." check
      
      "Script gestart" check
      "Alle fabrieken zijn gereed" check
      "Siebeltrigger gevonden" check
      "Script succesvol is beeindigd" check
      "Er lopen nog fabrieken." check
      "Geen oplevering verplaatst. Triggerbestand: " check
      "Data opgeleveren aan Siebel." work
      
      "Script gestart" check
      "Script is succesvol afgerond" check
      
      "Script is gestart" check
      "Geen fabriek gereed voor Archieveren" check
      "Script is succesvol beeindigd" check
      "Fabrieksrun is afgelopen en klaar om gearchiveerd te worden " work
      "Files worden verplaatst " work
      "ArchiveerRun (is gestopt):" error
      "Script is NIET succesvol beeindigd" error
      "Script NIET is succesvol afgerond" error
      "Fabrieksrun is afgelopen en klaar om gearchiveerd te worden " work
      "Een lege run wordt opgehaald " work
      "Archiveren is " work
      "Alle fabrieken zijn gereed en de ftp-bron is klaar dus deze ook stoppen." work
      
      "Script gestart" check
      "Script is succesvol gelopen" check
      
      "Script gestart" check
      "Script is succesvol afgerond" check
      
      "START" check
      "EIND" check
      "START FTP-Bron" check
      "EIND FTP-Bron" check
      "FTP Download gestart." work
      "Transactiegroep" work
      "Remote Uitvoerdir" work
      "Remote Verwerktdir" work
      "Doeldir" work
      "Bestaat de siebeltrigger" check
      
      "Start FTP-en convdat" work
      "Map:  opleveren naar Siebel" work
      "Zie log" work
      
      "Geen oplevering verplaatst." check
      "Triggerbestand: " check
      "Er is een resultaat xml aanwezig" work
      "Geen opleveringen meer en geen resultaat gevonden. Voor gaan de stap is klaar." check
      "Geen opleveringen meer en geen resultaat gevonden. Voorgaande stap is klaar." check
      "Er is een xml-file aanwezig op locatie" work
      "Stuurtabel is aangemaakt" work
      "BCP met volgende " work
      "Resultaat stuurbestand" check
      "Resultaat bestand" check
      "TCT is bijgewerkt" work
      "Fout in stuurlaagscript" error
      "Archiveer directory" work
      "File gevonden voor transactiegroep " work
      "Zie" work
      "Geen verwijder bestanden meer verwacht dus stoppen met draaien." work
      "Alle onderdelen zijn klaar. Conversie klaar." work
      "klaar.nu weg zetten op de ftp zodat copy en verwijderen kan worden gestopt." work
      "Transitiedashboard schrijven." work
      "Start Aanleveren Logs. Voor convdat" work
      "Geen foutgelopen runs gevonden voor convdat " work
      "Algemene log verplaatsen naar" work
      
      "Resultaat stuurbestand van de run is geladen" work
      "Resultaat bestand is gemaakt." work
      "Map opleveren naar Siebel" work
      "Archiveer directory naar" work
      "Starttijd  Einddtijd ConvDat in het Batchwindow gevuld`" work
      "Stacktrace" error
      "ExceptioMessage " error
      "ExceptionMessage " error
      "Method throwing the " error
      "START conversie" work
      "scheduler gestart" work
      "Fabrieksrun is afgelopen en klaar om gearchiveerd te worden" work
      "" work
      "Start archiveren" work
      "Opleveringfiles voor " work
      "Het " work
      "Delete van " work
      "Move resultaten naar archief." work
    }

    # onderstaande niet opnemen, wordt unknown, zijn errors.
    #26-3-2010 10:56:01	AV2ACO09	Archiveren en schonen	Error	20100326_1	ExceptioMessage: Access to the path 'D:\programs\conversie\straat1\' is denied.
    #26-3-2010 10:56:01	AV2ACO09	Archiveren en schonen	Error	20100326_1	Method throwing the exception: Void Move(System.String, System.String)
    #26-3-2010 10:56:01	AV2ACO09	Archiveren en schonen	Error	20100326_1	Stacktrace:    at System.IO.Directory.Move(String sourceDirName, String destDirName)    at ArchiveerRun.FileFunctions.DirectoryMove(String sourcePath, String targetPath)    at ArchiveerRun.Program.Main(String[] args)
    
    set lst_re_replace [list \
      {van [^ ]+ naar [^ ]+} \
      {^.+Scheduler.exe.bat} \
      {argumenten: .*$} \
      {argementen: .*$} \
      {[^ ]+ niet gevonden.} \
      {Directory: [^ ]+$} \
      {gereed: .*$} \
      {\? [^ ]+$} \
      {: [^ ]+} \
      {: [^ ]+ naar$} \
      {\d{8}_\d+} \
      {\d{8}} \
      { [^ ]+.log$} \
      {\d?\d:\d\d:\d\d} \
      {invocation failed.*$} \
      {exception.*$} \
      {:    at.*} \
      {transactiegroep:.*$} \
      {bestand:.*$} \
      {Van: [^ ]+$} \
      {Naar: [^ ]+$} \
    ]

  }
  
  public method file_start {a_filename a_logfile_id a_threadname a_threadnr} {
    $log debug "file_start"
    set logfile_id $a_logfile_id
    set threadname $a_threadname
    set threadnr $a_threadnr

    set ts_job_first ""
    set ts_job_last ""
    set job_current ""
  }
  
  public method handle_input {line {timestamp ""}} {
    $log debug "handle_input: $line *** $timestamp" 
    # 12-1-2010 15:37:02	AV2ACO03 - Opleveren data uit buffer en result.xml verplaatsten		Information		START
    # line: {13-1-2010 12:00:18} {AV2ACO02 - Ophalen data van FTP-server en Fabriek starten} {} Information {} {FTP Download gestart.}

    set lst [split $line "\t"]
    if {[llength $lst] == 6} {
      foreach {dt job_new z soort z beschrijving} $lst break
      set job_taskname [det_job_taskname $job_new $beschrijving]
      set job_thread_nr [det_threadnr_from_job $job_new]
      $log debug "about to insert task: thread_nr = $job_thread_nr"
      $log_helper insert_task $logfile_id $threadname $job_thread_nr $job_taskname $timestamp $timestamp $beschrijving
    } else {
      # uit deze logline geen job naam te achterhalen.
      $log debug "Geen 6 items in line: $lst"
    }
  }

  # result: integer
  private method det_threadnr_from_job {job} {
    $log debug "det_threadnr_from_job: $job" 
    # haal eerste 'woord' uit job.
    if {[regexp {^([^ ]+) } $job z job2]} {
      set job $job2 
    }
    set res [scan [string range $job end-1 end] "%0d"]
    if {$res == "{}"} {
      return 0
    } else {
      return $res
    }
  }

  # determine check, work or unknown
  private method det_job_taskname {job beschrijving} {
    # evt eerst variabele dingen uit beschrijving verwijderen.
    foreach re $lst_re_replace {
      regsub -all -- $re $beschrijving "" beschrijving 
    }
    if {[array get ar_job_taskname $beschrijving] != {}} {
      return $ar_job_taskname($beschrijving)
    } else {
      $log debug "Cannot determine taskname from job-desc: $job---$beschrijving"
      return "unknown"
    } 
  }
  
  public method handle_input_old {line {timestamp ""}} {
    $log debug "handle_input: $line *** $timestamp" 
    # 12-1-2010 15:37:02	AV2ACO03 - Opleveren data uit buffer en result.xml verplaatsten		Information		START
    # line: {13-1-2010 12:00:18} {AV2ACO02 - Ophalen data van FTP-server en Fabriek starten} {} Information {} {FTP Download gestart.}

    set lst [split $line "\t"]
    if {[llength $lst] == 6} {
      foreach {dt job_new z soort z beschrijving} $lst break
      if {$job_new == $job_current} {
        set ts_job_last $timestamp
      } else {
        # een nieuwe job, vorige afhandelen als er een is.
        if {$job_current != ""} {
          $log_helper insert_task $logfile_id $threadname $threadnr "[det_task_name $job_current]" $ts_job_first $ts_job_last
          # ook de tijd tussen de vorige en de huidige job
          $log_helper insert_task $logfile_id $threadname $threadnr "[det_task_name $job_current $job_new]" $ts_job_last $timestamp
        } else {
          # dit is de eerste job, nog niets loggen. 
        }
        set job_current $job_new
        set ts_job_first $timestamp
        set ts_job_last $timestamp
      }
    } else {
      # uit deze logline geen job naam te achterhalen.
      $log debug "Geen 4 items in line: $lst"
    }
  }
  
  public method file_finished {} {
    # laatste job nog loggen
    if {$job_current != ""} {
      $log_helper insert_task $logfile_id $threadname $threadnr "[det_task_name $job_current]" $ts_job_first $ts_job_last 
    }
  }

  # @param jobs: ofwel enkele job als AV2ACO04
  # @param jobs: ofwel 2 jobs (tijd hier tussen) als AV2ACO04 AV2ACO03
  # @note de jobs bevatten genoemde tekst, maar kunnen nog extra tekst bevatten, bv "AV2ACO09 - Archiveren en schonen"
  private method det_task_name {job1 {job2 ""}} {
    $log debug "det_task_name: $job1, $job2"
    if {[regexp {(CO[0-9]+)} $job1 z job1c]} {
      if {$job2 == ""} {
        set result $job1c 
      } else {
        if {[regexp {(CO[0-9]+)} $job2 z job2c]} {
          set result "$job1c-$job2c"
        } else {
          set result "X-$job1-$job2"
        }
      }
    } else {
      set result "W-$job1-$job2" 
    }
    $log debug "result: $result"
    return "$result"
  }
  
}
