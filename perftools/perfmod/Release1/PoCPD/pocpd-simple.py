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

# pop   = 10000.0
# population of 10.000 is too big, max 1000. Adapt servt (*10) (and also think time?)
pop   = 10000.0
think = 24.0
servt = 0.0015

##### Initialize the model giving it a name ##########################

pdq.Init("PoC PD")

##### Define the workload and circuit type ###########################

pdq.streams = pdq.CreateClosed("wko", pdq.TERM, pop, think)

##### Define the queueing center #####################################

pdq.nodes  = pdq.CreateNode("P3Bportal.CPU", pdq.CEN, pdq.FCFS)

##### Define service demand ##########################################

pdq.SetDemand("P3Bportal.CPU", "wko", servt)

##### Solve the model ################################################

# pdq.Solve(pdq.EXACT)
pdq.Solve(pdq.APPROX)

pdq.Report()

#---------------------------------------------------------------------

