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
	#print "Varying population:"
	#print "pop\tZ\tR\tX\tU"

	think = 0.0
	f = open('wbgsql-calc.tsv', 'w')
	f.write("# N X R Z U\n")
	for pop in [1, 2, 3, 4, 5, 8, 10]: 
		calc_pdq(pop, think, f)
	f.close()

	print "Varying think time (Z):"
	print "pop\tZ\tR\tX\tU"
	pop = 10
	#for think in [0, 0.1]: 
	#	calc_pdq(pop, think, 0)

	# do a what-if analysis to get to the target throughputs of 100 and 300.
	pop = 10
	for targetX in [100.0, 300.0]:
		calc_targetX(pop, targetX)


def calc_pdq(pop, think, f):
	delaytime = 0.000
	bg_think = 1
	bg_d = 0.01
	
	##### Initialize the model giving it a name ##########################
	
	pdq.Init("WBG SQL")
	
	##### Define the workload and circuit type ###########################
	
	pdq.streams = pdq.CreateClosed("wbgsql", pdq.TERM, pop, think)
	# ook een achtergrond proces
	pdq.streams = pdq.CreateClosed("bg", pdq.TERM, 1, bg_think)
	
	##### Define the queueing center #####################################
	
	# nodes
	pdq.nodes  = pdq.CreateNode("CPU", pdq.CEN, pdq.FCFS)
	pdq.nodes  = pdq.CreateNode("Disk0", pdq.CEN, pdq.FCFS)
	pdq.nodes  = pdq.CreateNode("Disk1", pdq.CEN, pdq.FCFS)
	
	# voeg delay centre toe, virtueel om tot de gemeten responstijd te komen.
	pdq.nodes  = pdq.CreateNode("Delay", pdq.DLY, pdq.ISRV)
	
	##### Define service demand ##########################################
	
	# visits and service demands
	pdq.SetDemand("CPU", "wbgsql", 0.0049)
	pdq.SetDemand("Disk0", "wbgsql", 0.0001)
	pdq.SetDemand("Disk1", "wbgsql", 0.0001)

	pdq.SetDemand("Delay", "wbgsql", delaytime)
	
	# background proces demand
	pdq.SetDemand("CPU", "bg", bg_d)
	
	##### Solve the model ################################################
	
	pdq.Solve(pdq.EXACT)
	# pdq.Solve(pdq.APPROX)
	
	pdq.Report()
	
	r = pdq.GetResponse(pdq.TERM, "wbgsql")
	x = pdq.GetThruput(pdq.TERM, "wbgsql")
	u = pdq.GetUtilization("CPU", "wbgsql", pdq.TERM)
	
	# f.print "%5.0lf\t%5.1lf\t%5.5lf\t%5.5lf\t%5.5lf" % (pop, x, r, think, u)
	# f.write "%5.0lf\t%5.1lf\t%5.5lf\t%5.5lf\t%5.5lf" % (pop, x, r, think, u)
	# print "%5.0lf\t%5.1lf\t%5.5lf\t%5.5lf\t%5.5lf" % (pop, x, r, think, u) >> f
	str = "%5.0lf\t%5.1lf\t%5.5lf\t%5.5lf\t%5.5lf\n" % (pop, x, r, think, u)
	f.write(str)
	
	#---------------------------------------------------------------------
	return

def calc_targetX(pop, targetX):
	print "calculating Z for targetX = %5.5f" % targetX
	Z = 0.0
	solve_model(pop, 0)
	x = pdq.GetThruput(pdq.TERM, "wbgsql")
	if x < targetX:
		print "targetX not feasible, maxX = %5.5f" % x
		pdq.Report()
	else:
		print "targetX feasible, maxX = %5.5f" % x
		Z_lowerbound = Z
		X_upperbound = x
		
		# bepaal upper bound voor Z en bijbehorend lower bound voor X
		Z = 1.0
		solve_model(pop, Z)
		x = pdq.GetThruput(pdq.TERM, "wbgsql")
		print "bepalen upper bound"
		while x > targetX:
			Z = Z * 2
			solve_model(pop, Z)
			x = pdq.GetThruput(pdq.TERM, "wbgsql")
			print "bij bepalen upperbound; Z = %5.5f, x = %5.5f" % (Z, x)
		Z_upperbound = Z
		X_lowerbound = x
		
		# nu een aantal keer interpoleren
		for i in range(10):
			print "Interpolatie, i = %5.5f" % (i)
			Z = (Z_upperbound + Z_lowerbound) / 2
			solve_model(pop, Z)
			x = pdq.GetThruput(pdq.TERM, "wbgsql")
			if x < targetX:
				Z_upperbound = Z
				X_lowerbound = x
			else:
				Z_lowerbound = Z
				X_upperbound = x

		print "Z_lowerbound = %5.5f, X_upperbound = %5.5f" % (Z_lowerbound, X_upperbound)
		print "Z_upperbound = %5.5f, X_lowerbound = %5.5f" % (Z_upperbound, X_lowerbound)

		pdq.Report()

def solve_model(pop, think):
	delaytime = 0.000
	bg_think = 1
	bg_d = 0.01
	
	##### Initialize the model giving it a name ##########################
	
	pdq.Init("WBG SQL")
	
	##### Define the workload and circuit type ###########################
	
	pdq.streams = pdq.CreateClosed("wbgsql", pdq.TERM, pop, think)
	# ook een achtergrond proces
	pdq.streams = pdq.CreateClosed("bg", pdq.TERM, 1, bg_think)
	
	##### Define the queueing center #####################################
	
	# nodes
	pdq.nodes  = pdq.CreateNode("CPU", pdq.CEN, pdq.FCFS)
	pdq.nodes  = pdq.CreateNode("Disk0", pdq.CEN, pdq.FCFS)
	pdq.nodes  = pdq.CreateNode("Disk1", pdq.CEN, pdq.FCFS)
	
	# voeg delay centre toe, virtueel om tot de gemeten responstijd te komen.
	pdq.nodes  = pdq.CreateNode("Delay", pdq.DLY, pdq.ISRV)
	
	##### Define service demand ##########################################
	
	# visits and service demands
	pdq.SetDemand("CPU", "wbgsql", 0.0049)
	pdq.SetDemand("Disk0", "wbgsql", 0.0001)
	pdq.SetDemand("Disk1", "wbgsql", 0.0001)

	pdq.SetDemand("Delay", "wbgsql", delaytime)
	
	# background proces demand
	pdq.SetDemand("CPU", "bg", bg_d)
	
	##### Solve the model ################################################
	
	pdq.Solve(pdq.EXACT)
	# pdq.Solve(pdq.APPROX)
	return
	
main()
