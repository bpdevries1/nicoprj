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
	print "Varying population:"
	print "pop\tZ\tR\tX\tU"

	think = 24.0
	for pop in range(1000, 25000, 1000): 
		calc_pdq(pop, think)

	print "Varying think time (Z):"
	print "pop\tZ\tR\tX\tU"
	pop = 10000
	for think in range(1.0, 50.0, 1.0): 
		calc_pdq(pop, think)


def calc_pdq(pop, think):
	delaytime = 0.6
	##### Initialize the model giving it a name ##########################
	
	pdq.Init("PoC PD")
	
	##### Define the workload and circuit type ###########################
	
	pdq.streams = pdq.CreateClosed("wko", pdq.TERM, pop, think)
	
	##### Define the queueing center #####################################
	
	# nodes
	pdq.nodes  = pdq.CreateNode("p1proxy.CPU", pdq.CEN, pdq.FCFS)
	pdq.nodes  = pdq.CreateNode("p1bproxy.CPU", pdq.CEN, pdq.FCFS)
	pdq.nodes  = pdq.CreateNode("p2http.CPU", pdq.CEN, pdq.FCFS)
	pdq.nodes  = pdq.CreateNode("p3portal.CPU", pdq.CEN, pdq.FCFS)
	pdq.nodes  = pdq.CreateNode("p3bportal.CPU", pdq.CEN, pdq.FCFS)
	pdq.nodes  = pdq.CreateNode("p4gateway.CPU", pdq.CEN, pdq.FCFS)
	pdq.nodes  = pdq.CreateNode("p4bgateway.CPU", pdq.CEN, pdq.FCFS)
	pdq.nodes  = pdq.CreateNode("p5integration.CPU", pdq.CEN, pdq.FCFS)
	pdq.nodes  = pdq.CreateNode("p6pddb.CPU", pdq.CEN, pdq.FCFS)
	pdq.nodes  = pdq.CreateNode("p7directory.CPU", pdq.CEN, pdq.FCFS)
	pdq.nodes  = pdq.CreateNode("p8poort.CPU", pdq.CEN, pdq.FCFS)
	pdq.nodes  = pdq.CreateNode("p9ods.CPU", pdq.CEN, pdq.FCFS)
	pdq.nodes  = pdq.CreateNode("p10odsdb.CPU", pdq.CEN, pdq.FCFS)
	pdq.nodes  = pdq.CreateNode("p11digid.CPU", pdq.CEN, pdq.FCFS)
	
	# voeg delay centre toe, virtueel om tot de gemeten responstijd te komen.
	pdq.nodes  = pdq.CreateNode("Delay", pdq.DLY, pdq.ISRV)
	
	##### Define service demand ##########################################
	
	# visits and service demands
	pdq.SetVisits("p1proxy.CPU", "wko", 0.44, 0.001428402)
	pdq.SetVisits("p1bproxy.CPU", "wko", 0.44, 0.001421357)
	pdq.SetVisits("p2http.CPU", "wko", 0.72, 0.000925845)
	pdq.SetVisits("p3portal.CPU", "wko", 0.36, 0.003799901)
	pdq.SetVisits("p3bportal.CPU", "wko", 0.36, 0.004215259)
	pdq.SetVisits("p4gateway.CPU", "wko", 0.06, 0.006546875)
	pdq.SetVisits("p4bgateway.CPU", "wko", 0.06, 0.006450527)
	pdq.SetVisits("p5integration.CPU", "wko", 0.06, 0.005694561)
	pdq.SetVisits("p6pddb.CPU", "wko", 0.22, 0.003287399)
	pdq.SetVisits("p7directory.CPU", "wko", 0.11, 0.004586553)
	pdq.SetVisits("p8poort.CPU", "wko", 0.06, 0.006271791)
	pdq.SetVisits("p9ods.CPU", "wko", 0.06, 0.002032627)
	pdq.SetVisits("p10odsdb.CPU", "wko", 0.06, 0.002769116)
	pdq.SetVisits("p11digid.CPU", "wko", 0.22, 0.002625886)
	
	pdq.SetVisits("Delay", "wko", 1.0, delaytime)
	
	##### Solve the model ################################################
	
	# pdq.Solve(pdq.EXACT)
	pdq.Solve(pdq.APPROX)
	
	# pdq.Report()
	
	r = pdq.GetResponse(pdq.TERM, "wko")
	x = pdq.GetThruput(pdq.TERM, "wko")
	u = pdq.GetUtilization("p3bportal.CPU", "wko", pdq.TERM)
	
	#print "Losse output results:"
	#print "Avg resp time: %5.5lf" % r
	#print "X: %5.5lf" % x
	#print "U(p3bportal.CPU): %5.5lf" % u
	# printf "%5.5lf \t %5.5lf \t %5.5lf" % r x u
	print "%5.0lf\t%5.1lf\t%5.5lf\t%5.5lf\t%5.5lf" % (pop, think, r, x, u)
	
	#---------------------------------------------------------------------
	return

main()
