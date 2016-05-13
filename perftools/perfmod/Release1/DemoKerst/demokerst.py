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

# delaytime = 0.000
# delaytime = 0.017
# 0.015 geeft goede resultaten bij Z=1.0
# delaytime = 0.015
delaytime = 0.015

# d_cpu =  0.01593 (uit Xmax de Dmax berekend, maar te hoge waarde)
# d_cpu =  0.0147 ; # goede waarde voor R bij N=6 en delay=0.
# d_cpu =  0.0159 ; # goede waarde voor X bij N=6 en delay=0.
# d_cpu =  0.014 ; # goede waarde voor R bij N=6 en delay=0.01.
# d_cpu =  0.013 ; # goede waarde voor R bij N=6 en delay=0.02.

# d_cpu =  0.0155 ; # goede waarde voor X bij N=6 en delay=0.01.
d_cpu =  0.0115 ; # goede waarde voor X bij N=6 en delay=0.015.

def main():
	#print "Varying population:"
	#print "pop\tZ\tR\tX\tU"

	think = 0.0
	f = open('generated/demokerst-calc-Z0.tsv', 'w')
	f.write("# N X R Z U\n")
	for pop in [1, 2, 3, 4, 5, 6, 8, 10]: 
		calc_pdq(pop, think, f)
	f.close()

	think = 1.0
	f = open('generated/demokerst-calc-Z1.tsv', 'w')
	f.write("# N X R Z U\n")
	# for pop in [1, 2, 3, 4, 5, 6, 8, 10, 20, 50, 100, 200]: 
	for pop in [1, 2, 3, 4, 5, 8, 10]: 
		calc_pdq(pop, think, f)
	f.close()


	#print "Varying think time (Z):"
	#print "pop\tZ\tR\tX\tU"
	#pop = 10
	#for think in [0, 0.1]: 
	#	calc_pdq(pop, think, 0)

	# do a what-if analysis to get to the target throughputs of 100 and 300.
	#pop = 10
	#for targetX in [100.0, 300.0]:
	#	calc_targetX(pop, targetX)


def calc_pdq(pop, think, f):
	bg_think = 1
	# bg_d = 0.01
	bg_d = 0.00001
	
	##### Initialize the model giving it a name ##########################
	
	pdq.Init("Demo Kerst")
	
	##### Define the workload and circuit type ###########################
	
	pdq.streams = pdq.CreateClosed("demokerst", pdq.TERM, pop, think)
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
	pdq.SetDemand("CPU", "demokerst", d_cpu)
	pdq.SetDemand("Disk0", "demokerst", 0.000001)
	pdq.SetDemand("Disk1", "demokerst", 0.000001)

	pdq.SetDemand("Delay", "demokerst", delaytime)
	
	# background proces demand
	pdq.SetDemand("CPU", "bg", bg_d)
	
	##### Solve the model ################################################
	
	pdq.Solve(pdq.EXACT)
	# pdq.Solve(pdq.APPROX)
	
	# pdq.Report()
	
	r = pdq.GetResponse(pdq.TERM, "demokerst")
	x = pdq.GetThruput(pdq.TERM, "demokerst")
	u = pdq.GetUtilization("CPU", "demokerst", pdq.TERM)
	
	# f.print "%5.0lf\t%5.1lf\t%5.5lf\t%5.5lf\t%5.5lf" % (pop, x, r, think, u)
	# f.write "%5.0lf\t%5.1lf\t%5.5lf\t%5.5lf\t%5.5lf" % (pop, x, r, think, u)
	# print "%5.0lf\t%5.1lf\t%5.5lf\t%5.5lf\t%5.5lf" % (pop, x, r, think, u) >> f
	str = "%5.0lf\t%5.1lf\t%5.5lf\t%5.5lf\t%5.5lf\n" % (pop, x, r, think, u)
	f.write(str)
	
	#---------------------------------------------------------------------
	return
	
main()
