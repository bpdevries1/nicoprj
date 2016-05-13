#!/usr/bin/env python
""" bank11: Simulate customers arriving
    at random, using a Source, requesting service
    from two counters each with their own queue
    random servicetime.
    Uses a Monitor object to record waiting times

"""
from __future__ import generators   #(not needed in Python 2.3+)
from SimPy.Simulation  import *
from random import Random

class Source(Process):
    """ Source generates customers randomly"""
    def __init__(self,seed=333):
        Process.__init__(self)
        self.SEED = seed

    def generate(self,number,interval):       
        rv = Random(self.SEED)
        for i in range(number):
            c = Customer(name = "Customer%02d"%(i,))
            activate(c,c.visit(timeInBank=12.0))
            t = rv.expovariate(1.0/interval)
            yield hold,self,t

def NoInSystem(R):
    """ The number of customers in the resource R
    in waitQ and active Q"""
    return (len(R.waitQ)+len(R.activeQ))

class Customer(Process):
    """ Customer arrives, is served and leaves """
    def __init__(self,name):
        Process.__init__(self)
        self.name = name
        
    def visit(self,timeInBank=0):       
        arrive=now()
        Qlength = [NoInSystem(counter[i]) for i in range(Nc)]
        for i in range(Nc):
            if Qlength[i] ==0 or Qlength[i]==min(Qlength): join =i ; break
        yield request,self,counter[join]
        wait=now()-arrive
        waitMonitor.observe(wait)                                 
        tib = counterRV.expovariate(1.0/timeInBank)
        yield hold,self,tib
        yield release,self,counter[join]

def model(counterseed=393939):
    global Nc,counter,counterRV,waitMonitor                      
    Nc = 2
    counter = [Resource(name="Clerk0"),Resource(name="Clerk1")]
    counterRV = Random(counterseed)
    waitMonitor = Monitor()                                      
    initialize()
    sourceseed = 99999
    source = Source(seed = sourceseed)
    activate(source,source.generate(50,10.0),0.0)                
    simulate(until=2000.0)                                       
    return (waitMonitor.count(),waitMonitor.mean())              

result = model(393939)                                           
print "Average wait for %4d was %6.2f"% result

