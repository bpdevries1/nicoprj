# configdata-db.tcl

proc get_config_db {{name "configdata.db"}} {
  set db [dbwrapper new $name]
  $db add_tabledef configdata {id} {configtype value machine} 
  $db add_tabledef agenthost {id} {hostname machine agenttype agentversion osname osversion osarch} 
  $db add_tabledef agentstatus {id} {agenthostname agentmachine agentname namespace agenttype agentversion tags monitoredmachines}
  $db add_tabledef agentstatus_monmachine {id} {agenthostname agentmachine agentname namespace agenttype agentversion tags monitoredmachine monmachtype}

  # andere bronnen: komen deze voor in Foglight?
  $db add_tabledef nagios_machine {id} {machine srcfile}
  $db add_tabledef stefan_machine {id} {machine fullname}
  
  # doel tabel, incl ist/soll, actions en status.
  # $db add_tabledef mediq_machine {id} {machine fullname vmtype ostype machine_function agents}
  $db add_tabledef mediq_machine {id} {machine fullname vmtype ostype machine_function agents \
    {in_scope int} in_scope_notes \
    {ist_credentials int} {soll_credentials int} {ist_this_agenthost int} {soll_this_agenthost int} {ist_agenthost int} \
    {soll_agenthost int} {ist_mon_cpu int} {ist_mon_mem int} {ist_mon_disk int} {ist_mon_network int} {ist_mon_process int} \
    ist_mon_process_status \
    {soll_mon_cpu int} {soll_mon_mem int} {soll_mon_disk int} {soll_mon_network int} {soll_mon_process int} \
    actions status {ping_ok int} source os_visible}
  
  # nagios data version 2
  $db add_tabledef nagios2_host {id} {srcfile host machine os}
  $db add_tabledef nagios2_service {id} {srcfile host machine service}
  
  # check hosts (ping + tcp connect)
  $db add_tabledef host_check {id} {ts_cet machine domain fullname ip {has_ssh int} {has_rdp int} {ping_ok int} notes}
  
  # jmx agent overview
  # agentId=371,agentName=WindowsAgent#Monitor@rupvsxaw01.resource.intra#230fb657-f1e4-49e8-ae89-f5d6676b66d3,namespace=HostAgents  
  $db add_tabledef jmxagent {id} {line {agentid int} agentname namespace agenttype agentdetail machine fullname}
  
  # PRTG export
  $db add_tabledef prtginfo {id} {linenr line infotype infovalue}
  
  $db create_tables 0
  $db prepare_insert_statements
  return $db
}

