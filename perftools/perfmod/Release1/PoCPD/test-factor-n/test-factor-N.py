#!/usr/bin/env python
#
#  $Id: closed1.py,v 1.2 2004/10/30 11:13:53 zyx Exp $
#
#---------------------------------------------------------------------

import pdq

#
# Based on time_share.c
#
# Illustrates PDQ solver for closed uni-server queue.  Compare with repair.c
#

##### Model specific variables #######################################

# pop is max 1000: wat testen uit te voeren om met minder 'pop' op dezelfde avg resptime, X en U uit te komen.
#pop   = 200.0
#pop   = 10.0
pop   = 10000.0
# think = 10.0
think = 15.0
servt = 0.01
# method = pdq.EXACT
method = pdq.APPROX
# method = pdq.CANON ; # kan niet met closed QN.

##### Initialize the model giving it a name ##########################

pdq.Init("PoC PD")

##### Define the workload and circuit type ###########################

pdq.streams = pdq.CreateClosed("wko", pdq.TERM, pop, think)

##### Define the queueing center #####################################

pdq.nodes  = pdq.CreateNode("P3Bportal.CPU", pdq.CEN, pdq.FCFS)

##### Define service demand ##########################################

pdq.SetDemand("P3Bportal.CPU", "wko", servt)

##### Solve the model ################################################

pdq.Solve(method)

pdq.Report()

#---------------------------------------------------------------------

