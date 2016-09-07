proc Server {startTime channel clientaddr clientport} {
    puts "Connection from $clientaddr registered"
    set now [clock seconds]
    puts $channel [clock format $now]
    puts $channel "[expr {$now - $startTime}] since start"
    close $channel
}

# socket -server [list Server [clock seconds]] 9900
# [2016-09-07 13:04:47] NdV poort 9900 waarsch dicht op firewall op Calypso machine, test poort 80.

socket -server [list Server [clock seconds]] 80
vwait forever
