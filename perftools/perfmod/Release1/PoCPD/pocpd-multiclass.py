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

def main():
	print "wrkld\tpop\tZ\tR\tX\tU"

	# think = 24.0
	think = 1.0
	pop = 10000
	calc_pdq(pop, think)

def calc_pdq(pop, think):
	# delaytime = 0.6
	delaytime = 0.0
	##### Initialize the model giving it a name ##########################
	
	pdq.Init("PoC PD")
	
	##### Define the workload and circuit type ###########################
	
	pdq.streams = pdq.CreateClosed("wko", pdq.TERM, pop, think)
	pdq.streams = pdq.CreateClosed("wko2", pdq.TERM, pop, think)
	
	##### Define the queueing center #####################################
	
	# nodes
	pdq.nodes  = pdq.CreateNode("p3bportal.CPU", pdq.CEN, pdq.FCFS)
	
	# voeg delay centre toe, virtueel om tot de gemeten responstijd te komen.
	pdq.nodes  = pdq.CreateNode("Delay", pdq.DLY, pdq.ISRV)
	
	##### Define service demand ##########################################
	
	# visits and service demands
	pdq.SetVisits("p3bportal.CPU", "wko", 0.36, 0.0031)
	pdq.SetVisits("p3bportal.CPU", "wko2", 0.36, 0.0011)
	
	pdq.SetVisits("Delay", "wko", 1.0, delaytime)
	pdq.SetVisits("Delay", "wko2", 1.0, delaytime)
	
	##### Solve the model ################################################
	
	# pdq.Solve(pdq.EXACT)
	pdq.Solve(pdq.APPROX)
	
	print_workload("wko", pop, think)
	print_workload("wko2", pop, think)

	pdq.Report()
	
	#---------------------------------------------------------------------
	return

def print_workload(workload, pop, think):
	r = pdq.GetResponse(pdq.TERM, workload)
	x = pdq.GetThruput(pdq.TERM, workload)
	u = pdq.GetUtilization("p3bportal.CPU", workload, pdq.TERM)
	
	print "%s\t%5.0lf\t%5.1lf\t%5.5lf\t%5.5lf\t%5.5lf" % (workload, pop, think, r, x, u)


main()
